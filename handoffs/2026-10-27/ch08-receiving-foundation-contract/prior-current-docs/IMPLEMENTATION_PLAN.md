# ShelfLife — current implementation plan

Updated 2026-10-26 (Australia/Perth). Chapter07 **[ShelfLife — Admin Setup Acceptance Review…](codex://threads/01a17543-b4ed-7153-97e3-2658f0ddf88d)**, full named step **Admin Setup Acceptance Review and Receiving Scope**, has reached its verified documentation checkpoint and transitioned to one fresh waiting chat. [Summary](handoffs/2026-10-26/ch07-acceptance-receiving-scope/EXECUTIVE_SUMMARY.md) · [Engineering handoff](handoffs/2026-10-26/ch07-acceptance-receiving-scope/ENGINEERING_HANDOFF.md) · [Evidence](handoffs/2026-10-26/ch07-acceptance-receiving-scope/EVIDENCE.md).

## Current position

| Package | Completed / supported | Unresolved / approval boundary |
|---|---|---|
| S1 Admin Setup | Six-step Flutter/SQL foundation and historical local backend/Chrome verification. All S1-01–12 reconciled in the new review. | Bounded local backend/Chrome checkpoint human-accepted on2026-10-26; broader acceptance remains incomplete. S1-08 explicit lead fixture; S1-09 injected audit failure/rollback and actual UI revocation; S1-10/11 native/device/accessibility gaps remain. Not all twelve criteria fully accepted. |
| Local evidence | Historical74 local cases, clean analysis, SQL assertions,19 concurrency groups,23 Auth/API groups,61 DTO decodes, restart/restore, five October16 and17 qualified October26 browser groups. | No runtime tests rerun in Chapter07. Focus loss is not OS minimization; lock observed at309.309 seconds is not exact firing. Counts are different measures, not one total. |
| Recovery / runtime | Chapter06 last recorded clean five-migration baseline, zero users/orgs, no setup tables; five services and three binding backups stopped, four listeners absent. Three private dumps retained. | Not re-probed in Chapter07. Final browser dump archive-listed but not restore-tested. Never start binding backups or use default54321. |
| S2-A Identity / durable draft foundation | Concrete proposed scope, paths, session/queue invariants, safe-read boundaries and acceptance/approval packet. | Next documentation decision: exact server-session and platform storage/key contracts. No implementation, install or test approval. |
| S2-B Known receiving | Proposed printed-date manual known-product receipt transaction and retry/config contracts. | Separate source/runtime approval after A. No existing operational receipt implementation acceptance. |
| S2-C Catalog / remaining capture | Proposed requests/admin approve-or-link, explicit later receipt, calculated rules and scanner/manual paths. | Separate implementation/device scope. Catalog approval never creates stock. External lookup/OCR excluded. |
| S3 Stock actions / S4 paired rounds | Accepted design and constraints retained; AC ownership mapped. | Implementation and validation remain unapproved/incomplete. |
| Full role access | Setup admin gate and historical non-admin/tenant tests exist. | Full operational routing and safe legacy table/view/RPC permission surface not certified. |
| Demo/report | Historical20 synthetic UPC local demo; October4–17 report and embedded GHL edition with prior108 viewport checks. | No new publication or hosted verification; GHL remains local-only. |
| Later scope | Supplier UI, OCR, purchasing/PDF, dashboards/reports recorded; iOS deferred. | Separate authorization. |

## Review and action register

[S1 review and limits](docs/testing/2026-10-26-admin-setup-acceptance-review.md) and [S2 scope/action packet](docs/superpowers/plans/2026-10-26-receiving-identity-queue-scope.md) are the current review outputs. Original accepted design and dated plans retain their historical wording.

| Action | Current authority |
|---|---|
| Chapter07 documentation | GRANTED by named approval; evidence reconciliation, S2 scope and local closeout only. |
| Bounded S1 checkpoint acceptance | ACCEPTED by “Accept the bounded local checkpoint” on2026-10-26. Full S1/device acceptance and new testing/release are not approved. [Acceptance addendum](handoffs/2026-10-26/ch07-addendum-01-s1-acceptance/ACCEPTANCE_ADDENDUM.md). |
| Chapter07 transition | CONSUMED by Chapter08,01a17814-e94a-74a1-80fa-d1027c7eff88; waiting state verified. New-chat start remains gated. |
| Next C08-DOC | Proposed **Receiving Foundation Contract and Storage Decision**, documentation only; explicit human approval required IN THAT CHAT. |
| Historical R01/R02 and Chapter06 R03/R05/R06 | Previously approved/executed within their bounded chapters; not reusable permission for new work. |
| S1-GAPS-R03/R05 | Proposed explicit lead/audit-failure/UI revocation checks on named disposable target; NOT GRANTED. Native/device target selection still required. |
| S2-R01/R02 | Local source and installed-dependency tests: NOT GRANTED; finalize A contracts first. |
| S2-R03/R05/R06 | Exact isolated backend/migration/grant, browser/device and package/version actions: NOT GRANTED. Device/storage selections unresolved. |
| R04 hosted; R07 commit/push/merge; R08 publication/access; R09 rollout | NOT GRANTED; no exact release/hosted target selected. |

## Next step and retained constraints

Documentation verification and the authorized one-chat transition are complete; actual creation/status appears in [receipt](handoffs/2026-10-26/ch07-acceptance-receiving-scope/CONTINUATION_RECEIPT.md). The next chapter settles S2-A storage/session/read contracts and exact approval text only after its own human start approval. No app/runtime work is needed for this documentation checkpoint. Keep current/source chats available for audit; no archive permission.

Flutter `app_flutter/` is the application and `product/supabase/` the backend source; preview and deprecated product/js are not the operational target. Real store policies stay onboarding inputs. Retain active-session-only offline drafts and online reverify after lock/restart/person switch; five-minute idle/five-failure cooldown; no automatic stock from catalog approval; lead confirmation for accepted actions; fixed past-date restrictions; two-person rounds. See [design](docs/superpowers/specs/2026-10-10-staff-workflow-design.md), [accepted addendum](docs/superpowers/specs/2026-10-10-staff-workflow-decisions-addendum.md).

Fresh read-only root main HEAD remains `f56d5068e94cf80819f55be952a95769ad508c97`; inherited work is uncommitted.26 source hashes and seven migrations match historical records. No source changes, application tests, backend calls, new dependencies, permission changes or delivery occurred in Chapter07. [Ledger](STATUS_LEDGER.md) · [Session index](SESSION_INDEX.md) · [Stable pointer](NEXT_CONVERSATION_HANDOFF.md).

## Continuation dispatched — Chapter08

Created ONE fresh [ShelfLife — Receiving Foundation Contract…](codex://threads/01a17814-e94a-74a1-80fa-d1027c7eff88), ID `01a17814-e94a-74a1-80fa-d1027c7eff88`; full named step **Receiving Foundation Contract and Storage Decision**, documentation only. Initial waiting acknowledgement, completed turn, idle state and no tool marker verified. [Receipt](handoffs/2026-10-26/ch07-acceptance-receiving-scope/CONTINUATION_RECEIPT.md). Chapter07 transition authority is consumed. Explicit human start approval is required IN THAT CHAT; no work follow-up sent. Source preserved unarchived.
