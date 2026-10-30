# Engineering handoff — Chapter 06 local validation checkpoint

2026-10-26 Australia/Perth. Workspace `D:/LLM-Data/Claude-Desktop/claude-code/shelflife`. Source chapter **ShelfLife — Admin Setup Backend and Application Validation**, exact ID `01a13ce2-a8fe-7063-8867-260412dd096a`, [source chat](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a). The desktop tool displays the shortened title “ShelfLife — Admin Setup Backend and…”. This handoff supplements, and does not replace, the source's exact input/output audit. Keep all original chats unarchived.

## Position and decisions

The approved R03/R06 and R05 connected sequence reached a local verification and cleanup checkpoint. Six-step Flutter setup and its SQL contract are implemented and exercised against actual disposable Supabase. No application/domain/migration correction was required in this chapter. S1 is locally verified within the named browser scope; full product acceptance and release readiness are not claimed. Staff receiving, identity/PIN rules, offline durable drafts, stock actions and paired rounds remain later slices. Real jurisdiction/store/handling values remain onboarding inputs; synthetic test values are not production policy.

See [executive summary](EXECUTIVE_SUMMARY.md), [evidence](EVIDENCE.md), [authority](RECOVERY_AND_AUTHORITY.md), [test notes](TEST_NOTES.md), [current roadmap](../../../IMPLEMENTATION_PLAN.md) and [acceptance procedure](../../../docs/testing/admin-setup-acceptance.md). Earlier October16 and October19 handoffs remain intact. Their blocked/pending state is superseded only by this dated record.

## Authorization and transition

Human explicitly started this named chapter; approved R03/R06, scoped Docker repair, then the corrected restore and R05 through “approving both”. The approved connected sequence remained in this chat. One administrator-mode launch was later approved but Windows canceled it. On “Retry once”, preflight found engine29.9.2 healthy; no second RunAs was made, and no cause of recovery is asserted. Subsequent “please continue from where you left off” resumes the same work.

The original chapter request authorizes closeout and exactly ONE fresh continuation. Current standing instructions require explicit human start approval IN THAT NEW CHAT before any reads/tools/planning. New proposed step: **Admin Setup Acceptance Review and Receiving Scope**, documentation only. Its creation is not implementation, connected-test or delivery authority. R04 hosted, R07 commit/push/merge, R08 publication/access and R09 rollout remain unapproved. No additional chapter may be created after that next checkpoint without fresh transition approval. No archive authorization exists.

## Source and uncommitted files

Root branch `main`, HEAD `f56d5068e94cf80819f55be952a95769ad508c97`. No stage/commit/push/merge or new branch was performed. [GIT_STATUS.txt](GIT_STATUS.txt) preserves the observed working tree. Inherited tracked edits: PLAN.md, PLAN_ADDENDUM_2026-09-25.md, RESUME.md, app_flutter AndroidManifest.xml, main.dart, screens/login.dart, pubspec.yaml and test/widget_test.dart. Existing untracked setup/preview/assets/docs/handoffs/migrations remain. Do not reset/clean them. Git reported unavailable global ignore-file access and CRLF conversion warnings; commands completed. Tracked diff whitespace check passed.

26 implementation-source hashes match the Chapter05 source manifest; seven migration hashes match pre-execution. No app source changed in this chapter. Validation harnesses live under `product/supabase/tests/backend-validation/`: common, apply-setup, concurrency, api, restart, decode-responses, restore-baseline, rebind-local, browser-fixtures and serve-web. October26 adds `browser-checkpoint.mjs`, a read-only assertion harness for the preserved R05 fixture, hardcoded lost-response operation and migration baseline. It is fixture-specific, not a general application test; after baseline cleanup its fixture assertions must not be rerun blindly.

Harness changes earlier corrected duplicate supplier fixtures, a destructive-filter safeguard, directory-copy handling, and restore execution account. Restore uses existing supabase_admin because limited postgres could not restore original schema ownership. It changes no role grants. `apply-setup.mjs` is not idempotent; `rebind-local.mjs` is a one-time operation and rejects existing backups. Do not rerun either without checking state.

Documentation/report outputs are uncommitted too. Report base HTML was renamed by the time of packaging to `reports/2026-10-04-to-17/Oct 4-17 26 Shelflife progress report.html`; preserve it. New `package-ghl.mjs`, `ghl-standalone.html`, package/verification JSON and two reader screenshots implement the separately requested portable evidence edition. It embeds13 primary records as escaped text and four original images. Nested document references are plain text; Codex links need access. No GHL service mutation/publication or hosted rendering check occurred.

## Verified runtime and final state

Disposable project/network `shelflife-ch06-validation`. Owned services: `supabase_db_shelflife-ch06-validation`, `supabase_auth_shelflife-ch06-validation`, `supabase_rest_shelflife-ch06-validation`, `supabase_inbucket_shelflife-ch06-validation`, `supabase_kong_shelflife-ch06-validation`. Target database volume has the same name as its db container. Explicit host mappings were127.0.0.1:55322 DB, :55321 API, :55324 mail. Temporary actual app server127.0.0.1:8136 is now stopped. Default54321 belongs to another project and must never be used as an accidental fallback.

Final approved cleanup: restored `before-setup.dump`, verified five retained migration records, zero users/organisations and absence of setup tables; stopped all five services. Three original `_binding_backup` containers are also stopped. They retain unsafe wildcard definitions; **NEVER start them**, especially the old db sharing the target volume. Do not use a fresh CLI start that may replace explicit loopback bindings. The initial wildcard exposure is a historical limitation; acceptance tests ran after containment.

All four owned listeners are absent. Shared Docker remains running. Before/after inventory shows no change to unrelated container states/port mappings. Shared product Supabase, Onyx, scout and Windows PostgreSQL are outside ownership. Product vector was already restarting and remains so; no broader repair was attempted. No Docker/WSL reset, prune, volume deletion, ACL change, credential change or upgrade occurred.

Installed pinned CLI2.118.0 and earlier runtime/image identities are recorded in the October15/16 packets. October26 engine29.9.2 and installed Chrome156.0.8078.47 differ from earlier observed versions; this chapter did not upgrade them. Actual release web bundle remains private in `.cache/ch06-validation/web/`, built October16 with installed Flutter/Dart, explicit disposable backend configuration and locally cached renderer. Build invocation/errors are in the October16 PREPARATION/BUILD records. No package upgrades/downloads were needed for R05.

## Results and limits

Historical: Chapter05 local74 cases/clean analysis; SQL transaction suite passed/rolled back;19 concurrency groups;23 real Auth/API groups;61 DTO decodes; backend restart preserved eight setup and six inventory fingerprints; successful corrected restore/reapply; October16 five connected UI groups. Counts represent different measures and must not be summed.

October26 actual UI: activation1; two-admin stale409 and explicit discard/reload; dropped-response identical retry; offline verification denial/online recovery; reload and fresh-process session restoration; viewer/staff denial; other-org identity isolation; six narrow pages, labels, keyboard focus and reachable lower controls; protected-dialog concealment via injected signal and real headed-browser focus loss; inactivity concealment observed at309.309 seconds.17 recorded groups include historical-observation limitations within that day's record. The interrupted first idle observation is not exact timing evidence. Installed Playwright forced focus until disabled for the headed check; events still reported visible but focus=false. OS minimization/lock, native hidden-window semantics and physical devices remain unverified. No OS screen-reader certification, camera, real staff flow or full four-role app acceptance.

Database checkpoint: six nonempty sentinel inventory tables unchanged by count+row MD5; lost-response operation `a27c5c56-f0c4-4aef-b97b-ce8e8e8914d4` has one setup_operations and one setup_audit entry, revision6. Draft store “Recovered response loss”; active version1 store “Chrome verified store”, reason “October26 verified UI activation”; one active version. No inventory write by setup. Main instrumented browser recorded no page errors or attempted external requests. Instrumentation scope and harness errors are in TEST_NOTES, not hidden or counted as app defects.

Generic network-failure login wording is a usability limitation. Larger text has historical local test evidence, not a new physical-device check. Formal S1 acceptance/remaining manual targets should be decided in the next review. Full S2–S4 implementation and hosted rollout remain separate.

## Backups and rollback

Private ignored `.cache/ch06-validation/private/` contains auth/account/status/renderer defines/storage-state files and backups. Never print, embed, commit or publish their contents. All three dumps retained and hashed:

| File | SHA-256 | Contents |
|---|---|---|
| before-setup.dump | 587CE15FBBD00FA7FDA99C953E691F1926C628283A285D2073E7ECABC0D73B83 | Five retained migrations, empty pre-setup baseline; restore demonstrated twice. |
| tested-20261016.dump | DB70BC336DDF52C677D76B360A0DCE1FE07E9D3688B1BC2B6DA7B25012D3A915 | Backend test schema/data before earlier cleanup. |
| browser-tested-20261026.dump | CAA7976E943FB63F39A6D8D4815667B55D78DC0218ED79E979A2C9CE79F9E999 | Final actual-browser test state, draft6/active1 plus synthetic auth data. Archive list verified; this new dump was not itself restore-tested. |

Final database is clean baseline, NOT the browser-tested state. Current build/fixture private files refer to deleted synthetic accounts and will not sign in until a separately approved setup/restore. To reproduce after approval: verify exact target/mount/network/loopback bindings and all three hashes, start only target db, restore the chosen private dump using existing supabase_admin into the isolated target, verify state, then start auth/rest/inbucket/kong and localhost8136. Never restore into product or the Windows PostgreSQL service. Starting/reapplying/connected tests in a new chapter needs named authority; this procedure is not permission.

No hosted rollback exists because no hosted migration was applied. Disposable baseline restoration was the only destructive cleanup, explicitly approved. If a future production rollback is proposed, retain immutable histories and separately approve access/UI containment; do not delete production audit/version rows. To undo only report/harness work, preserve its evidence first and remove only those chapter-owned files after user direction, never reset inherited application changes.

## Exact next steps

1. Finish documentation verification and the already-authorized ONE fresh chat creation; record its returned ID/title in CONTINUATION_RECEIPT, SESSION_INDEX, current plan/ledger and stable pointer. Verify only its initial waiting acknowledgement. Keep this source unarchived.
2. In that new chat, wait for the human's explicit approval of **Admin Setup Acceptance Review and Receiving Scope**. Before it arrives: no tools, file reads, planning, searches or background work.
3. After that start approval, read this packet and reconcile S1-01–12 and AC coverage against executed evidence. Clearly separate browser verification, native/physical gaps and formal acceptance. Ask only for a concrete unresolved decision; do not silently start connected checks.
4. Draft the next S2 receiving/identity/queue scope and acceptance checks from accepted design, with exact files, data/permission boundaries and action-specific gates. Carry forward no automatic stock from catalog approval, approved PIN/offline rules, lead confirmation, fixed past-date restrictions and paired-round requirements. No implementation/deployment is included in the review step.
5. For GHL, the local standalone file is ready. Any hosted page edit/publication and actual GHL validation needs the exact target and action approval. No source files or credentials need uploading with this package.
6. At the next chapter's checkpoint repeat closeout, then wait for new transition approval. Do not create an unattended chain of chats.


## Continuation dispatched

Created exactly one fresh [ShelfLife — Admin Setup Acceptance Review…](codex://threads/01a17543-b4ed-7153-97e3-2658f0ddf88d), ID01a17543-b4ed-7153-97e3-2658f0ddf88d. Full named step: Admin Setup Acceptance Review and Receiving Scope. Initial waiting acknowledgement and idle state verified, with no tool marker. Creation authorization is consumed; human start approval remains required there. [Receipt](CONTINUATION_RECEIPT.md), [opening](CONTINUATION_OPENING.md). Source chat remains unarchived.
