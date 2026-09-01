#!/usr/bin/env bash
# Local simulation with cfn-guard 3.2.1: inputs file merged ahead of the template, as the hook does.
set -eu
cd "$(dirname "$0")"
GUARD="${CFN_GUARD:-cfn-guard}"

# stage|mode|input params|sample
CASES='1|WARN||bucket-compliant
1|WARN||bucket-missing-encryption
1|WARN||bucket-data
2|FAIL|hooks/stage-2-allow.yaml|bucket-missing-encryption
2|FAIL|hooks/stage-2-allow.yaml|bucket-data
3|FAIL|hooks/stage-3-exclude.yaml|bucket-legacy
3|FAIL|hooks/stage-3-exclude.yaml|bucket-missing-encryption
3|FAIL|hooks/stage-3-exclude.yaml|bucket-data
4|FAIL||bucket-compliant
4|FAIL||bucket-missing-encryption
4|FAIL||bucket-data
4|FAIL||bucket-exempt'

while IFS='|' read -r stage mode params sample; do
  args=(-r rules/s3-baseline.guard -d "samples/$sample.yaml")
  [[ -n "$params" ]] && args+=(-i "$params")
  status=$("$GUARD" validate "${args[@]}" -S all 2>&1 | awk '/Status =/ {print $NF; exit}')
  echo "stage $stage $mode ${params:-no-lists} $sample: $status"
done <<< "$CASES"
