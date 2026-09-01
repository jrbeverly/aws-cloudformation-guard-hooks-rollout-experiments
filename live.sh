#!/usr/bin/env bash
# Runs the four stages against a live GuardHook, then removes everything.
# Stage 4 blocks every non-compliant S3 bucket stack in the region while it is active.
set -eu
cd "$(dirname "$0")"
export AWS_REGION="${AWS_REGION:-us-east-2}"
BUCKET="guard-hooks-rollout-$(openssl rand -hex 4)"
HOOK=guard-hooks-rollout-hook

aws s3 mb "s3://$BUCKET" >/dev/null
aws s3 cp rules/s3-baseline.guard "s3://$BUCKET/s3-baseline.guard" >/dev/null
aws s3 cp hooks/ "s3://$BUCKET/hooks/" --recursive >/dev/null

stage() {
  aws cloudformation deploy --stack-name "$HOOK" --template-file hook.yaml --capabilities CAPABILITY_IAM \
    --parameter-overrides RulesBucket="$BUCKET" FailureMode="$1" InputParamsKey="$2" >/dev/null
}

sample() {
  local name="guard-hooks-rollout-s$1-$2"
  aws cloudformation create-stack --stack-name "$name" --template-body "file://samples/$2.yaml" >/dev/null
  aws cloudformation wait stack-create-complete --stack-name "$name" 2>/dev/null || true
  echo "stage $1 $2: $(aws cloudformation describe-stacks --stack-name "$name" --query 'Stacks[0].StackStatus' --output text)" \
    "$(aws cloudformation describe-stack-events --stack-name "$name" \
      --query 'StackEvents[?HookStatus!=`null` && HookStatus!=`HOOK_IN_PROGRESS`]|[0].HookStatusReason' --output text | cut -c1-140)"
  aws cloudformation delete-stack --stack-name "$name"
}

stage WARN ""
for s in bucket-compliant bucket-missing-encryption bucket-data; do sample 1 $s; done
stage FAIL hooks/stage-2-allow.yaml
for s in bucket-missing-encryption bucket-data; do sample 2 $s; done
stage FAIL hooks/stage-3-exclude.yaml
for s in bucket-legacy bucket-missing-encryption bucket-data; do sample 3 $s; done
stage FAIL ""
for s in bucket-compliant bucket-missing-encryption bucket-data bucket-exempt; do sample 4 $s; done

aws cloudformation delete-stack --stack-name "$HOOK"
aws cloudformation wait stack-delete-complete --stack-name "$HOOK"
aws s3 rm "s3://$BUCKET" --recursive >/dev/null
aws s3 rb "s3://$BUCKET"
