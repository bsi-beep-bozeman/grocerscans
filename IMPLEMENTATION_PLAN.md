# ShelfLife — current implementation plan

Updated 2026-10-30 Australia/Perth. Chapter10 remains OPEN in [ShelfLife — Receiving Foundation Connected…](codex://threads/01a18027-683a-7043-b764-5939d2330ee2). The human paused backend work and pivoted to a remotely accessible admin/staff client dry run. The isolated preview is locally verified; remote publication is pending. [Current summary](handoffs/2026-10-30/client-dry-run/EXECUTIVE_SUMMARY.md) · [Engineering handoff](handoffs/2026-10-30/client-dry-run/ENGINEERING_HANDOFF.md) · [Publication packet](handoffs/2026-10-30/client-dry-run/PUBLICATION_PACKET.md).

## Active bounded step — client dry-run preview

- COMPLETE locally: separate Flutter entry and demo adapters, 20 sample products, actual admin/staff screens, per-browser persisted setup/drafts, public practice identities, guide and isolated reset. Ten adapter tests, clean analysis and eight Chrome browser groups pass. All46 inherited source hashes match. Release ZIP and per-file manifest saved in the current handoff.
- PENDING: remote hosting and anonymous client access verification. Vercel access works under cmzoilot@gmail.com / CM's projects, but human confirms Hobby. Netlify Free is proposed; user reports “Connected netlify”, but no Netlify tool is exposed in this chat yet. Exact account/site and publication approval remain unresolved; no remote upload/deploy occurred.
- PAUSED: all backend work, including prior Chapter10 restoration (still outstanding). No Docker, database, Auth, Supabase or migration operation is part of this demo.
- NEXT: resolve usable Netlify access, review/approve exact publication packet, publish verified bundle, run remote client checks here, then add a publication checkpoint and reconcile chapter transition. No new chat or archive now.

The tables below retain the previous backend position and approvals. They are historical/paused context, not instructions to resume that work during the preview.

## Current implementation position

| Package | Completed / supported | Unresolved / next boundary |
|---|---|---|
| S1 Admin Setup | Historical bounded backend/Chrome checkpoint accepted2026-10-26; Chapter09's74 offline cases passed; Chapter10 actual six-endpoint positive/negative/retry/conflict regression groups passed. | Current actual UI revocation, injected audit rollback and native/device/assistive gaps remain. Not full S1 acceptance. |
| S2-A local source | Chapter09 identity/session/crypto/draft/storage/recovery source and47 new offline cases; historical121 total and clean analyzer.46 source hashes still match. | No new whole-suite rerun; native whole-feature durability/lifecycle/recovery UI incomplete. |
| S2-A disposable backend | Fresh pre-run baseline restore proved; five pending migrations applied; original SQL harness passed;29 real password sign-ins;10 API groups pass. |2 groups failed: activated-policy SQL ambiguity and expiry test fixture. Approved additive repair saved but unapplied; fixture correction saved but not rerun. Additional A01–A12 tests remain. |
| Web | App and native-storage harness builds pass. Chrome156 native IndexedDB commit/reopen/revision race and fresh-process ciphertext preservation pass. Dedicated browser/server closed and synthetic storage cleared. | Actual app Auth/PIN/draft/policy/recovery/idle/second-tab/failure/layout tests remain. Quota/corruption/newer-schema and8h actual expiry not certified. |
| Runtime / restore | Fresh private before-run dump restore-tested; both baseline hashes verified again. | Docker unavailable then process-only observations; read-only target inspection timed out twice in approval review. Actual container/database state UNKNOWN. FINAL RESTORE NOT DONE; last verified DB had ten migrations and synthetic fixtures. |
| S2-B/C, S3/S4 | Accepted domain design retained. | Receiving stock confirmation/catalog/capture/round implementation unapproved. A saves local drafts only. |

## Action-specific authority

| Action | Current status |
|---|---|
| Chapter09 contract/source/dependencies/offline checks | Accepted/granted and locally checkpointed; historical records preserved. |
| Chapter10 documentation/start | GRANTED in this chat. Exact target/migration/fixture/acceptance/restore packet prepared. |
| S2A-R03 and S2A-R05-WEB | Explicitly GRANTED for [action packet](handoffs/2026-10-28/ch10-connected-validation-scope/ACTION_PACKET.md), including test-only harness work, disposable grants, synthetic fixtures, builds/profile, restore and cleanup. Latest human decision: **Leave connected work pending**. Resume only in this owning chat after human resumption. |
| Policy repair | GRANTED by “Approve this scoped fix and rerun”: additive20261028000000 migration only. Saved, unapplied, untested. All10 existing migrations unchanged. |
| Engine launches | October28 normal launch succeeded. October29 single normal launch failed on socket access. Single administrator launch requested; tool rejected duplicate risk, later processes observed, exact target not revalidated. No repeated launch/repair/reset/ACL change authorized. |
| R05-ANDROID / new dependencies / further production fixes / Realtime service addition | NOT GRANTED. Exact future scopes required. |
| R04 hosted / R07 stage,commit,push,merge / R08 publication,access / R09 rollout | NOT GRANTED. No delivery action occurred. |
| Chapter10 transition | ONE eventual fresh continuation authorized but UNCONSUMED. Do not split unfinished connected apply/test/restore/stop. No next chat created; source unarchived. New-chat start gate remains mandatory. |

## Exact continuation within this chat

After human resumption: verify engine/target and actual migration/fixture state, refresh private synthetic Auth sessions, apply approved repair exactly once, rerun focused failed cases and remaining bounded tests, save evidence/tested snapshot, perform the still-unattempted final baseline restore, and verify owned shutdown. [Resume runbook](handoffs/2026-10-29/ch10-connected-validation-resume/ROLLBACK_AND_NEXT_STEPS.md) contains failure gates. Permission-review timeouts are not a completed inspection or cleanup proof. A restore retry or another engine launch needs a concrete amendment.

Root main HEAD `f56d5068e94cf80819f55be952a95769ad508c97`; all work uncommitted. No prior migration/source history rewritten. Source rollback must preserve inherited dirty work. Private backup paths/hashes are documented without contents or credentials. Historical records and original chats remain preserved for audit.

## Retained constraints

Online PIN after lock/restart/person switch; active-session-only offline drafts;8h session,5-minute idle/cooldown; lead partition recovery; admin recovery unavailable; local saved never means stock received. Accepted [design](docs/superpowers/specs/2026-10-10-staff-workflow-design.md), [foundation contract](docs/superpowers/specs/2026-10-27-receiving-foundation-contract.md), [action amendment](docs/superpowers/plans/2026-10-27-receiving-foundation-approval-amendment.md). Private default-privilege contract discrepancy and hosted key custody remain explicit unresolved gates. No real-store policy fabricated.

[Ledger](STATUS_LEDGER.md) preserves prior events; [index](SESSION_INDEX.md) links original chats; [stable pointer](NEXT_CONVERSATION_HANDOFF.md) points to this interim handoff. Previous current-plan snapshot preserved in Chapter10's October28 baseline directory.
