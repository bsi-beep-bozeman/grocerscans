# Evidence — local validation checkpoint

2026-10-26 Australia/Perth. Original source: [ShelfLife — Admin Setup Backend and Application Validation](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a), ID `01a13ce2-a8fe-7063-8867-260412dd096a`.

## Fresh execution

| Evidence | Result / scope |
|---|---|
| [RECOVERY_AND_AUTHORITY.md](RECOVERY_AND_AUTHORITY.md) | Engine already healthy on Retry once preflight; no second elevated launch. Existing R03/R05 authority resumed. |
| [BROWSER_CHECKS.json](BROWSER_CHECKS.json) |17 recorded Chrome groups, with limited/injected/interrupted observations explicitly labeled. |
| [TEST_NOTES.md](TEST_NOTES.md) | Test sequence, actual results, synchronization failures, focus-emulation and idle timing limitations. |
| [IDLE_TIMING.json](IDLE_TIMING.json) | Locked at read-only observation309.309 seconds after last interaction; fields absent. No clock acceleration; exact firing instant not measured. |
| [BROWSER_RUNTIME.json](BROWSER_RUNTIME.json) | Chrome156.0.8078.47; no recorded main-page JavaScript errors or attempted nonlocal requests. |
| [DATABASE_CHECKPOINT.json](DATABASE_CHECKPOINT.json) | Six inventory fingerprints unchanged; one operation/audit for exact retry; draft6/active1; seven migration hashes unchanged. |
| [APPLICATION_SOURCE_HASHES.json](APPLICATION_SOURCE_HASHES.json) |26 implementation files match Chapter05 hashes. |
| [BACKUPS.json](BACKUPS.json) | Three private dumps retained; final browser snapshot new hash; archive list readable. New snapshot not restore-tested. |
| [RESTORE.json](RESTORE.json), [RESTORE.log](RESTORE.log) | Approved final baseline restoration PASS: five retained migrations, zero users/orgs, no setup table. Uses existing supabase_admin. |
| [CLEANUP.json](CLEANUP.json) | Five target services and three backups stopped; four listeners absent; unrelated inventory unchanged; shared Docker running. |
| [Before inventory](CONTAINERS_BEFORE_CLEANUP.txt), [after inventory](CONTAINERS_AFTER_CLEANUP.txt) | Target-only cleanup; no unrelated workload state/port changes. |
| [GIT_STATUS.txt](GIT_STATUS.txt) | main at unchanged HEAD; inherited uncommitted work preserved. Tracked git diff whitespace passed. |

Representative sanitized application screenshots: [stale conflict](two-admin-conflict.png), [narrow review](narrow-step-6.png), [keyboard fields](narrow-focus-final.png), [lower unit controls](narrow-units-lower.png), [category controls](narrow-labels-lower.png), [focus recovery](headed-background-restored.png), [idle lock](idle-lock-timed.png), [fresh browser session](restarted-session.png). The [activation transition](activation-desktop.png) captures dialog-dismissal animation; activation success is established by RPC assertions and SQL state, not that image. Preliminary/transient captures remain but are not final layout evidence.

## Earlier executed evidence, retained unchanged

- [Chapter05 source/local evidence](../../2026-10-15/ch05-admin-setup-foundation/EVIDENCE.md):74 cases, clean analysis; historical.
- [Backend checkpoint](../../2026-10-16/ch06-backend-validation/EVIDENCE.md): transaction/concurrency19/Auth-API23/DTO61/restart. That packet's restore failure and pending-R05 wording describes its original time.
- [Corrected restore](../../2026-10-16/ch06-restore-retry/RESTORE.json), [approval](../../2026-10-16/ch06-restore-retry/APPROVAL_RECEIPT.md): passed before build/R05.
- [Build](../../2026-10-16/ch06-browser-validation/BUILD.log), [five UI groups](../../2026-10-16/ch06-browser-validation/BROWSER_CHECKS.json).
- [October19 interruption](../../2026-10-19/ch06-application-validation/EVIDENCE.md), [canceled elevation](../ch06-docker-elevated-start/RESULT.md): preserved failures, superseded by subsequent health observation, not rewritten as success.

## Supplemental report

[GHL single-file edition](../../../reports/2026-10-04-to-17/ghl-standalone.html), [package hashes](../../../reports/2026-10-04-to-17/GHL_PACKAGE.json), [verification](../../../reports/2026-10-04-to-17/GHL_VERIFICATION.json).13 primary embedded documents matched source text and closed with Escape;108 slide/viewport checks had no horizontal overflow; no report script errors. Four images embedded. JWT-like/private-key scan found no matches; private credential/dump files were not included. October17 remains the report cutoff; source snapshots explicitly dated October26 may contain later context. Hosted GHL rendering/publication is untested/unexecuted.

## Limits and closeout verification

This is the verified bounded local checkpoint, not full production/physical-device acceptance. Native minimized/hidden-window behavior, physical platforms/camera, OS screen readers, full staff role workflows and hosted delivery remain outside proven coverage. A local timed observation is not exact timer instrumentation. No application source correction or new dependency installation was needed.

The original170 dated files were hashed before closeout edits in [HISTORICAL_HASHES_BEFORE.json](HISTORICAL_HASHES_BEFORE.json). Final [documentation verification](DOCUMENTATION_CHECK.json) passed:170 historical files unchanged,62 prior ledger events preserved in order, all checked local links resolved, and the mandatory start gate is verbatim. [Continuation creation](CONTINUATION_RECEIPT.md) and its initial waiting acknowledgement/idle state are verified; no tool marker was present. No source archive, commit, push, merge or publication was performed.
