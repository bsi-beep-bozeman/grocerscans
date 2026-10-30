# ShelfLife — current implementation plan

**Active 2026-10-13:** Human approved **Admin Setup Foundation** and then R02 existing-dependency local checks in [Chapter 05](codex://threads/01a12f57-0cf7-7fa0-8e2a-542b48d3985d). R01/R02 are now granted for S1; older waiting notes below are historical. [Executable plan](docs/superpowers/plans/2026-10-13-admin-setup-implementation.md). R03–R09 remain separately gated. ONE continuation authorized only at the verified checkpoint; authority not yet consumed. No application completion claim yet.

Latest bounded checkpoint, 2026-10-13: user-requested twenty-product local demo catalog completed and data-validated; [packet](handoffs/2026-10-13/ch05-demo-catalog-20/ENGINEERING_HANDOFF.md). Hosted snapshot unchanged at five products. Four-tier access source review confirms incomplete end-to-end implementation. This request does not start S1 or approve app build/publication.

Latest limited checkpoint: 2026-10-13 — user-requested existing demo walkthrough completed in Chapter 05. Hosted sample cockpit, inventory lookup, checklist progress and sample batch save were observed across October 12–13; [evidence and limits](handoffs/2026-10-13/ch05-existing-demo-review/ENGINEERING_HANDOFF.md). This supersedes the earlier lack of fresh demo availability evidence only. S1 implementation and other execution lanes remain unapproved.

Checkpoint: 2026-10-12 (Australia/Perth). Current roadmap, not execution approval.
Retain [PLAN.md](PLAN.md) and [September addendum](PLAN_ADDENDUM_2026-09-25.md) as historical domain/decision sources; newer accepted design controls where explicitly superseded.

## Current position

| Package | Evidence/status | Remaining gate |
|---|---|---|
| Flutter/Supabase foundation | Source exists; root main HEAD f56d5068e94cf80819f55be952a95769ad508c97. Fresh source read: main.dart signed-in stub; existing tests cover preview | No applied backend or production behavior verified |
| Supplier role | Supplier-tier migrations exist; historical source implementation | Live migration and UI status unknown |
| Sample cockpit/publication | September demo build/tests/screenshots and one publication are historical | No fresh hosted health/access evidence or later release approval |
| Accepted staff design | [Version 1](docs/superpowers/specs/2026-10-10-staff-workflow-design.md) plus [admin/decision addendum](docs/superpowers/specs/2026-10-10-staff-workflow-decisions-addendum.md) accepted in Chapter 03 | AC01–AC34 are future acceptance criteria, not passed tests |
| Chapter 04 scope and acceptance | [Plan](docs/superpowers/plans/2026-10-12-staff-workflow-scope-acceptance.md) prepared under explicit start approval; documentation verification/transition recorded in dated packet | S1 proposal not implementation approval |
| S1 Admin Setup Foundation | Proposed first slice: admin entry, six-step saved setup, versioned presets/locations, immutable activation/readiness/audit; twelve acceptance cases | Accept scope/contracts/precision/limits; R01 source and R02 local tests unapproved; R03–R09 separate |
| S2 Receiving/identity/queue | Known and unknown receiving, admin catalog approval, explicit receipt confirmation, durable staff drafts, PIN/session/permission enforcement | S1 plus scoped source/backend/dependency/test approvals |
| S3 Stock containment/actions | Holds, lead confirmation, corrections/removals/transformations, concurrency/audit | S2 and real configured policies plus separate approvals |
| S4 Paired rounds | Worklists, checks, two participants, accountable open exceptions, confirmed uploads | S2/S3 and scoped acceptance checks |
| Later features | OCR, purchase orders/PDF, dashboards, reports, supplier UI | Separate bounded scope; iOS deferred |

## Retained constraints

Flutter in app_flutter/ is the Android/web target; product/supabase/ holds backend source. The preview entry is isolated sample data; do not extend deprecated product/js/ as the deliverable. Four intended roles; is_shift_lead, no manager UX. Staff receive/check/pull aside; lead/admin confirms specified actions without overriding policy. Admin catalog approval never creates stock automatically.

Accepted D02: active verified-session offline staff drafts; lock/restart/person switch requires online verification. D07: five-minute inactivity/background/switch lock and five-failure/five-minute device cooldown. D05: two distinct same-branch participants, all checks accounted for, uploads confirmed and exceptions owned; no solo completion. These are fixed, not discretionary presets.

D04/D06 real jurisdiction, units/packs, label formats, locations, supplier/lot and handling rules remain onboarding inputs. No guessed food rules; past-date markdown/donation flags false. S1 proposes measured precision 0–3 to match current storage; this requires review. Configuration readiness must not imply receiving is implemented. S1 admin persistence is online-only; accepted future staff offline behavior remains unchanged.

## Authorization and checkpoint

Human approved Chapter 04 on 2026-10-12 with “Approved to start **ShelfLife — Staff Workflow Implementation Scope and Acceptance Plan**” and “then continue the chapter cycle.” Authorized: documentation plan, document verification/closeout and ONE fresh continuation. No application execution was authorized or performed.

[Action register R00–R10](docs/superpowers/plans/2026-10-12-staff-workflow-scope-acceptance.md) separates local source, offline tests, local database/migration/grant/integration work, hosted tests, devices, installation, Git delivery, publication/access and rollout/rollback. D08/D09 remain unapproved. No approved application/deployment/testing sequence is open.

Next bounded step: **ShelfLife — Admin Setup Foundation**, subject to explicit human start and scoped implementation/test approval IN THAT CHAT. The [creation receipt](handoffs/2026-10-12/ch04-scope-acceptance/CONTINUATION_RECEIPT.md) records actual outcome; do not duplicate a creation. After that chapter closes, another transition requires new approval. Preserve original chats unarchived.

Owner: **[ShelfLife — Staff Workflow Implementation Scope and Acceptance Plan](codex://threads/01a12796-7acf-70b2-94f9-8d0efc7a2e87)**.
Latest [executive summary](handoffs/2026-10-12/ch04-scope-acceptance/EXECUTIVE_SUMMARY.md), [engineering handoff](handoffs/2026-10-12/ch04-scope-acceptance/ENGINEERING_HANDOFF.md), [evidence](handoffs/2026-10-12/ch04-scope-acceptance/EVIDENCE.md). Standing mandatory gate: [AGENTS.md](AGENTS.md).

Transition completed: ONE fresh **[ShelfLife — Admin Setup Foundation](codex://threads/01a12f57-0cf7-7fa0-8e2a-542b48d3985d)**, `01a12f57-0cf7-7fa0-8e2a-542b48d3985d`, created; waiting acknowledgement and idle status verified. Creation authority consumed. No work starts there until explicit human approval; no further continuation approved.
