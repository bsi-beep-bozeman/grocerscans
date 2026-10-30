# ShelfLife — current implementation plan

Updated 2026-10-28 Australia/Perth. Chapter09 [ShelfLife — Receiving Foundation Implementation…](codex://threads/01a17a46-3ec8-7893-adca-9d41ab4e1960), full named step **Receiving Foundation Implementation and Local Checks**, reached its approved local verification checkpoint. [Summary](handoffs/2026-10-28/ch09-receiving-foundation-implementation/EXECUTIVE_SUMMARY.md) · [Engineering handoff](handoffs/2026-10-28/ch09-receiving-foundation-implementation/ENGINEERING_HANDOFF.md).

## Current implementation position

| Package | Completed / supported | Unresolved / next boundary |
|---|---|---|
| S1 Admin Setup | Existing Flutter/SQL foundation; bounded backend/Chrome checkpoint human-accepted2026-10-26. All74 existing offline setup/preview tests passed again in Chapter09. | Explicit lead fixture, injected audit failure/actual UI revocation, native/device/accessibility gaps remain. Not full S1 acceptance. |
| S2-A receiving foundation | Approved local identity/session/draft/crypto/storage adapter/recovery source; three additive SQL migrations; pinned dependencies;47 new offline cases pass; analyzer clean. | SQL unapplied/uncompiled by PostgreSQL; real Auth/grants/native durability/lifecycle/backup behavior unverified. 85.27% of instrumented foundation lines covered, not whole-feature coverage. |
| Local runtime | No Chapter09 activation or probing. | Chapter06 empty five-migration disposable baseline and stopped services are historical only; restore/new fixture authority required before reuse. Never start binding backups or default54321. |
| S2-B known receiving | Retained scoped design for manual known-product receipt and retry/config contracts. | No receiving transaction/stock confirmation implementation approval. A only saves drafts locally. |
| S2-C catalog/capture | Retained request/approve-or-link and explicit later receipt design. | Separate implementation/device approval. Catalog approval never creates stock; OCR/external lookup excluded. |
| S3 stock / S4 paired rounds | Accepted design and acceptance ownership retained. | Implementation and validation unapproved/incomplete. |
| Demo/report | Historical synthetic demo and October4–17 local report/GHL edition retained. | No new publication or hosted validation. |

## Action-specific authority

| Action | Current status |
|---|---|
| Chapter09 contract adoption | GRANTED by human “I accept” in this owning chat: eight-hour sessions, server-held keys, lead-only full-partition recovery, proposed legacy access closure. |
| S2A-R01 source / R06 dependencies / R02 offline checks | GRANTED and completed to local checkpoint. Four exact direct pins plus necessary transitives;80 existing package versions/archive hashes preserved.121 total tests pass;33 Dart files format-clean; analysis clean. |
| S2A-R03 backend/migration/grant/connected tests | NOT GRANTED. Requires concrete reviewed target, fixtures, ACL delta, backup/restore and cleanup plan. Source harnesses are not test results. |
| S2A-R05-WEB / R05-ANDROID | NOT GRANTED. Browser profile/build/server scope and exact device/build/install/transport targets require approval. |
| R04 hosted / R07 stage,commit,push,merge / R08 publication,access / R09 rollout | NOT GRANTED. No deployment or live permission change occurred. |
| Chapter09 transition | ONE fresh continuation authorized. Actual creation and gate state recorded in [receipt](handoffs/2026-10-28/ch09-receiving-foundation-implementation/CONTINUATION_RECEIPT.md). No new-chat start or later transition authority. |

## Next bounded step

**Receiving Foundation Connected Validation Scope and Approval**. After human start approval in that chat, prepare the exact documentation/action packet in [next steps](handoffs/2026-10-28/ch09-receiving-foundation-implementation/ROLLBACK_AND_NEXT_STEPS.md), then obtain separate R03/R05 execution approvals. Keep any approved connected implementation/apply/test/restore/stop sequence there through its verified checkpoint. At closeout wait for a new transition approval before another chat.

Root branch main HEAD `f56d5068e94cf80819f55be952a95769ad508c97`; inherited and new work remains uncommitted. Seven pre-existing migrations and unrelated source preserved. Proposed legacy access closure is breaking and unapplied. The entire diff against HEAD includes prior chapters and must not be treated as Chapter09 alone.

## Retained constraints and history

Flutter app_flutter and product/supabase are the operational source. Online PIN verification after lock/restart/person switch; active-session-only offline drafts; five-minute idle/five-failure cooldown; lead confirmation for accepted stock actions; fixed past-date restrictions; two-person rounds; no fabricated store policies. See [accepted design](docs/superpowers/specs/2026-10-10-staff-workflow-design.md), [decisions](docs/superpowers/specs/2026-10-10-staff-workflow-decisions-addendum.md), [foundation contract](docs/superpowers/specs/2026-10-27-receiving-foundation-contract.md) and [action amendment](docs/superpowers/plans/2026-10-27-receiving-foundation-approval-amendment.md).

The previous implementation-plan snapshot is preserved in the Chapter09 baseline folder. Chapter08's stale pre-creation receipt is reconciled by [new dated addendum](handoffs/2026-10-28/ch09-receiving-foundation-implementation/C08_CREATION_RECORD_ADDENDUM.md); its creation authority was consumed by this chat. [Ledger](STATUS_LEDGER.md) preserves all previous events. [Session index](SESSION_INDEX.md) links exact chat inputs/outputs. [Stable pointer](NEXT_CONVERSATION_HANDOFF.md) identifies the latest handoff. No source chat archived.

## Chapter09 continuation dispatched

Created ONE fresh [ShelfLife — Receiving Foundation Connected…](codex://threads/01a18027-683a-7043-b764-5939d2330ee2), ID01a18027-683a-7043-b764-5939d2330ee2; full named step **Receiving Foundation Connected Validation Scope and Approval**. Initial waiting acknowledgement, completed turn/idle state and no latest tool marker verified. Chapter09 transition authority is CONSUMED. Human start approval required in that chat; source retained unarchived. [Receipt](handoffs/2026-10-28/ch09-receiving-foundation-implementation/CONTINUATION_RECEIPT.md).
