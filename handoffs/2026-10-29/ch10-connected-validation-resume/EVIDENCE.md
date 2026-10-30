# Evidence map — fresh versus historical

Original chat [01a18027-683a-7043-b764-5939d2330ee2](codex://threads/01a18027-683a-7043-b764-5939d2330ee2) retains exact tool inputs/outputs. Paths below are local artifacts, not new authority.

| Evidence | Supported observation |
|---|---|
| [October28 source comparison](../../2026-10-28/ch10-connected-validation-scope/SOURCE_COMPARISON.json) |46 source hashes matched on entry. |
| [Target identity](../../2026-10-28/ch10-connected-validation-scope/IDENTITY_VERIFICATION.json) | All five exact identities/images/bindings matched before activation; backup guard passed. |
| [Baseline capture](../../2026-10-28/ch10-connected-validation-scope/BASELINE_CAPTURE.json), [restore proof](../../2026-10-28/ch10-connected-validation-scope/PRE_RESTORE_PROOF.json) | Fresh empty baseline dump and pre-run restoration with metadata/data equality and effective privileges. This is not final cleanup. |
| [Migration execution](../../2026-10-28/ch10-connected-validation-scope/MIGRATION_EXECUTION.json) | Five reviewed pending migrations committed, each exit0. The new policy fix is absent. |
| [SQL harness](../../2026-10-28/ch10-connected-validation-scope/SQL_HARNESS.json) | Transactional synthetic SQL passed/rolled back. Owner calls with synthetic claims, not Auth proof. |
| [Fixture provisioning](../../2026-10-28/ch10-connected-validation-scope/FIXTURE_PROVISION.json) |29 confirmed synthetic accounts/password logins; two orgs/three branches107 catalog products. No secret values in artifact. |
| [API attempt01](../../2026-10-28/ch10-connected-validation-scope/API_CASES_ATTEMPT_01.json), [effective ACL](../../2026-10-28/ch10-connected-validation-scope/EFFECTIVE_ACL.json) |10 groups passed,2 failed; exact scope/limitations retained. Not rerun after repair. |
| [App build](../../2026-10-28/ch10-connected-validation-scope/BUILD_APP.log), [storage build](BUILD_STORAGE.log) | Both approved no-pub/no-CDN builds passed with existing cached tools. Update notice was informational; no SDK upgrade. |
| [Native storage result](NATIVE_STORAGE_BASIC.json), [screenshot](native-storage-basic.png) | Compiled production native adapter commit/reopen/decrypt and stale-revision race PASS. |
| [Browser process reopen](BROWSER_PROCESS_REOPEN.json) | Fresh Chrome process retained identical ciphertext/store hashes and one draft; plaintext probe absent. |
| [Browser cleanup](BROWSER_CLEANUP.json) | Dedicated browser closed; one named synthetic DB removed; no DBs remained in that dedicated origin. Profile/builds retained. |
| [Local checkpoint](LOCAL_CHECKPOINT.json), [source](SOURCE_PRESERVATION.json), [migrations](MIGRATION_PRESERVATION.json) |46 source and10 migration hashes match; approved new SQL equals proposal; both baseline hashes match; no target/server listener observed. |

Actual installed browser156.0.8078.48; installed Flutter3.47.5/Dart3.13.4 were inspected October28. Node24.14.1; installed Playwright1.64.0-alpha-1790635538000 CJS module used from existing npm cache. No package installation. Initial ordinary Flutter help invocation spun on restricted SDK lock access and was interrupted; cached tool snapshot then supplied version/help and both builds under granted build authority.

Harness correction history: evidence filename suffix check corrected before first database start; original API expiry fixture used two nonidentical clock_timestamp values, changed to current_timestamp but not rerun; ESM Playwright import failed and existing CommonJS entry succeeded; two stale/undefined browser-page references failed before a successful separately recorded fresh-process comparison. No product pass inferred from a failed command.

Automatic review records: administrator launch rejected with reason “single administrator launch is already running” / duplicate risk; no successful tool receipt. Two subsequent read-only inspection requests timed out in permission review and did not execute. Human then chose pending. These are distinct from Docker's normal-launch socket failure and from PostgreSQL/test results.

Final local documentation check results are in DOCUMENTATION_CHECK.json. Git diff --check passed for tracked differences with line-ending/global-ignore-access warnings; it does not validate untracked files. New test scripts are syntax-checked separately. No npm/pip audit or commit performed because no commit is authorized. No fresh121-test rerun; that count remains historical Chapter09 evidence.
