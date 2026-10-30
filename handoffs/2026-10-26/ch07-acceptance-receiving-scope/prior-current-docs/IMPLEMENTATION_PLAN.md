# ShelfLife — current implementation plan

Updated 2026-10-26 (Australia/Perth). Chapter06 **ShelfLife — Admin Setup Backend and Application Validation**, ID 01a13ce2-a8fe-7063-8867-260412dd096a, has reached a verified local backend/Chrome checkpoint. [Summary](handoffs/2026-10-26/ch06-browser-completion/EXECUTIVE_SUMMARY.md) · [Engineering handoff](handoffs/2026-10-26/ch06-browser-completion/ENGINEERING_HANDOFF.md) · [Evidence](handoffs/2026-10-26/ch06-browser-completion/EVIDENCE.md) · [Original chat](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a).

Docker was already responding when the approved Retry once preflight ran; no second administrator launch was needed. Cause of recovery is unknown. The approved connected sequence resumed in its owning chat and completed test-state preservation plus target-only cleanup. Native/physical-device limits remain explicit; this is not production release approval.

## Current position

| Package | Completed / verified | Unresolved / remaining |
|---|---|---|
| S1 Admin Setup Foundation | Six-step Flutter application and two SQL migrations implemented. Real local Auth/setup/ref editing/activation, conflicts, exact retry, identity isolation, reload/restart, locking and narrow layout exercised. | Formal S1-01–12 acceptance review; native OS minimization/hidden-window and physical platforms remain unverified. Real store policy values remain onboarding inputs. |
| Backend | SQL assertions;19 concurrency groups;23 Auth/API groups;61 DTO decodes; restart persistence; corrected restore/reapply, all historical passed. Fresh SQL confirms inventory unchanged, retry audit uniqueness and immutable active version. | No hosted verification. Initial wildcard binding exposure retained as historical limitation; tests ran after loopback correction. |
| Local/browser | Historical74 cases and clean analysis; five connected UI groups October16;17 recorded groups October26 with individual limits.26 implementation-source hashes and seven migrations unchanged. | Browser focus-loss verified; exact internal idle firing unmeasured (locked at309.309 seconds). OS screen-reader/device certification not performed. |
| Recovery / cleanup | Three private backups retained. Final disposable baseline restored: five migrations, zero orgs/users, no setup tables. Five services plus three backup containers stopped; four listeners absent; unrelated inventory unchanged. | Final browser dump archive list verified, but that new dump itself was not restore-tested. Do not start binding-backup containers. |
| Report | October4–17 six-tab36-slide report; local GHL edition embeds13 evidence records and four images;108 viewport checks passed. | Actual GHL hosting/rendering and publication not executed. |
| Demo catalog |20 synthetic UPCs in local preview/CSV; historical checks passed. | Hosted demo remains earlier five-product release at last observation; not freshly published or rechecked. |
| Four-tier application access | Setup admin RPC gate and viewer/staff denial/other-org UI isolation tested. | Full application role routing and staff/supplier workflows are incomplete. |
| S2 Receiving / identity / queue | Accepted design and acceptance plan exist. | Exact implementation slice, receiving/catalog approval/receipt confirmation, PIN/session rules and durable staff drafts need bounded approval. |
| S3 Stock actions | Accepted constraints retained. | Holds, lead confirmation, corrections/removals/transformations, concurrency and audit need implementation approval. |
| S4 Paired rounds | Accepted design requires distinct participants, accounted checks and owned exceptions. | Worklists/checks/uploads/completion enforcement remain unimplemented. |
| Later work | OCR, purchasing/PDF, dashboards/reports, supplier UI recorded. | Separate scope; iOS deferred. |

## Approval register

| Lane | Current authority / disposition |
|---|---|
| R01 local S1 source; R02 installed-dependency checks | Approved/completed Chapter05; historical. No new feature work implied. |
| R03 disposable backend; R06 pinned installation | Approved exact isolated target; executed and cleaned up. No authority to adopt other resources. |
| R05 local Chrome | Approved by “approving both”; completed to bounded local checkpoint with recorded native/device limits. New-target testing requires its own scope. |
| Scoped Docker repair / one elevated startup | Endpoint rename failed historically; first approved elevation canceled. Retry approval prompted preflight only because Docker was already healthy. No new host repair needed or performed. |
| R04 hosted backend | NOT approved. |
| R07 commit/push/merge; R08 publication/access; R09 rollout | NOT approved. Includes new report publication. |
| Chapter06 start | Explicitly approved and completed within bounded local scope. |
| Chapter transition | CONSUMED: one fresh continuation created, ID01a17543-b4ed-7153-97e3-2658f0ddf88d. Initial waiting acknowledgement/idle verified. Human start approval remains required there; no further creation authorized. |

## Exact next step

Created ONE fresh [ShelfLife — Admin Setup Acceptance Review…](codex://threads/01a17543-b4ed-7153-97e3-2658f0ddf88d), full chapter opening **Admin Setup Acceptance Review and Receiving Scope**. Its waiting acknowledgement and idle state are verified; [receipt](handoffs/2026-10-26/ch06-browser-completion/CONTINUATION_RECEIPT.md). Its bounded step is documentation-only reconciliation of S1 evidence/limits and preparation of the next S2 scope/action-approval packet. It must initially acknowledge waiting and stop without tools. No implementation, connected testing, deployment or publication is approved for that new chat. After its checkpoint, require fresh transition approval.

Local cleanup is complete. Keep private snapshots and prior dated evidence. No further R03/R05 action is needed merely to close this chapter. If the human wants native/device checks or GHL hosting, prepare the exact target/action request before execution.

## Retained decisions and source

Flutter in app_flutter is the application target; product/supabase holds backend source. The sample preview remains isolated; deprecated product/js is not the deliverable. Do not invent food rules or production jurisdiction defaults. Admin persistence is online-only; accepted staff offline/PIN rules, lead/admin confirmation, no automatic stock creation from catalog approval, fixed past-date restrictions and paired rounds remain in the [design](docs/superpowers/specs/2026-10-10-staff-workflow-design.md) and [addendum](docs/superpowers/specs/2026-10-10-staff-workflow-decisions-addendum.md). Configuration readiness does not enable staff workflows.

Root main HEAD f56d5068e94cf80819f55be952a95769ad508c97 remains unchanged. Work is uncommitted; inherited edits are preserved. [Local implementation plan](docs/superpowers/plans/2026-10-13-admin-setup-implementation.md), [acceptance procedure](docs/testing/admin-setup-acceptance.md), [scope register](docs/superpowers/plans/2026-10-12-staff-workflow-scope-acceptance.md), [ledger](STATUS_LEDGER.md), [session index](SESSION_INDEX.md). PLAN.md and PLAN_ADDENDUM_2026-09-25.md retain original domain decisions.
