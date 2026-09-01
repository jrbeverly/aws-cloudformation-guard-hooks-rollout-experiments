# CloudFormation Guard Hooks Rollout Experiments

> [!WARNING]
> **AI-authored:** This change was autonomously planned and implemented by an AI software factory from a human-authored specification, with possible subsequent human review or modification.

Tests whether one unchanged Guard rule set (S3 buckets need default encryption and a 7-day incomplete multipart abort) can be rolled out through four stages purely by changing the GuardHook configuration: warn everywhere, fail for an allow list, fail with an exclusion list, fail everywhere. Tags `guard:component` (list membership) and `guard:exempt` (always skipped) do the targeting.

```sh
./evaluate.sh
./live.sh
```

With logs such as:

```text
stage 1 bucket-compliant: CREATE_COMPLETE Hook succeeded with message: Successful validation
stage 1 bucket-missing-encryption: CREATE_COMPLETE Hook failed with message: Template failed validation, the following rule(s) failed: REQUIRE_S3_ENCRYPTION. Full output was written to s3://g
stage 1 bucket-data: CREATE_COMPLETE Hook failed with message: Template failed validation, the following rule(s) failed: REQUIRE_MULTIPART_EXPIRY, REQUIRE_S3_ENCRYPTION. Full ou
stage 2 bucket-missing-encryption: ROLLBACK_COMPLETE Hook failed with message: Template failed validation, the following rule(s) failed: REQUIRE_S3_ENCRYPTION. Full output was written to s3://g
stage 2 bucket-data: CREATE_COMPLETE Hook succeeded with message: Successful validation
stage 3 bucket-legacy: CREATE_COMPLETE Hook succeeded with message: Successful validation
stage 3 bucket-missing-encryption: ROLLBACK_COMPLETE Hook failed with message: Template failed validation, the following rule(s) failed: REQUIRE_S3_ENCRYPTION. Full output was written to s3://g
...
```

## Notes

- This is promising, as it offers an option of instead of pushing wrappers or opinionated patterns for "good practice", it can be codified within AWS
- Tags for exceptions, or special opt-in behaviours is a good approach
- Local development flows are solid, making it easier to catch difficult scenarios
