# ShelfLife — current implementation plan

Checkpoint: 2026-10-10 (Australia/Perth). This is the current execution/status map.
Retain [PLAN.md](PLAN.md) for domain specifications and
[the September addendum](PLAN_ADDENDUM_2026-09-25.md) for feature decisions.
Older PWA/extend-the-original recommendations and unfinished-work lists are
historical where superseded. Neither this roadmap nor its order grants approval.

## Current position

Flutter in `app_flutter/` is the intended Android + web application; Supabase in
`product/supabase/` is the backend. iOS is deferred. The published cockpit is an
isolated sample-data preview using `lib/preview.dart`, not the authenticated
production entry point `lib/main.dart` and not a live inventory deployment.

| Work package | Evidence/status at checkpoint | Approval / completion gate |
|---|---|---|
| Foundation: schema, auth, RLS, RPCs | Source and migration files exist; main repository HEAD `f56d506`. Deployment to a live backend is unverified here. | Future backend work and connected validation require explicit scope approval. |
| Supplier role | `20260925000000_supplier_tier.sql` and `20260925000001_supplier_tier.sql` exist; commit `f56d506` adds supplier tier. Corrects RESUME.md's obsolete “NOT done.” | Source implementation is not evidence of applied migrations or working supplier UI. |
| Cockpit Concept 01 | Responsive sample cockpit, lookup/review/save, inventory search, session-only rounds. Historical build, three tests, screenshots and targeted analysis passed. | Previously authorized prototype complete at its historical checkpoint; main-repo changes remain uncommitted. |
| Demo publication | Sites reported success on 2026-09-29; hosting source commit `e806215c81926baaaec787030a935d408937bbed`. | Previously approved one demo release; owner-only access last verified then. No blanket future publication approval. |
| Chapter workflow | Chapter 02 written-specification checkpoint complete; latest human request explicitly approves closeout and one fresh continuation. | Created ONE fresh continuation, 01a125ee-a20b-7663-a7f7-f5fe694580d4; idle waiting acknowledgement verified. Creation authority consumed; new-chat start pending. |
| Staff Workflow Design Specification | [Version 1](docs/superpowers/specs/2026-10-10-staff-workflow-design.md) covers six workflow areas, 13 screens and 28 proposed acceptance scenarios. Shift-lead confirmation for stock removal/transformation is human-decided. | Written deliverable complete for review; overall design acceptance, open decisions and implementation approval pending. No application tests run. |
| Staff workflow implementation | Production auth integration, real catalog, batch writes, PIN attribution, alert resolution, rounds, offline persistence. | NOT APPROVED. Scope and acceptance checks must be approved before implementation. |
| Android device delivery | SDK absent in earlier setup; APK/camera on real device not verified. | Toolchain setup, device work and rollout require scoped approval. |
| Later feature groups | Photo OCR + review; purchase orders/PDF; owner/executive/supplier dashboards; CSV; rules-based insights and weekly reports. | Planned only; define and approve bounded chapters individually. |

## Current design deliverable — written; review carried to the next gated chapter

1. Specify role-aware entry and staff kiosk PIN flow (admin/staff/viewer/supplier).
2. Specify known and unknown UPC/SKU receiving, sensible defaults and review.
3. Specify separate batches of the same product with quantity, date, supplier and location.
4. Specify alert review and permitted resolution actions with attribution.
5. Specify guided rounds, exceptions and completion.
6. Specify local-save, pending-sync, failure and retry states; do not portray a
   session-only mock as durable offline inventory.

Checkpoint: [reviewable specification](docs/superpowers/specs/2026-10-10-staff-workflow-design.md)
with screen inventory, permissions, happy/error/empty/offline states, acceptance
criteria and unresolved decisions. Start approval was granted in Chapter 02 by
“Approved to begin **Staff Workflow Design Specification**”. The human selected
shift-lead confirmation for stock-removal and transformation actions.
No code, new dependencies, migration execution, application testing or deployment
is included in this documentation-only step. Offline reauthentication, admin
review of unknown products, pairing/completion policy and timing defaults remain
proposed. Unit/label formats and store policies need input before implementation.
Read-only source gaps G01–G10 are documented; deployment remains unverified.

## Constraints and decisions retained

- Android + web first, native barcode scanning, near-white UI and urgency colour.
- Four intended roles; no manager UX; staff shift lead via `is_shift_lead`.
  Historical SQL retains an unused manager enum value; not permission to remove it.
- Common receiving path should minimize taps; UPC does not encode expiry.
- Claude Vision via backend with mandatory human review; threshold 0.75 is a
  recorded design decision, not an implemented capability of the preview.
- Conservative category markdown/donation defaults until store state is known.
- Resend and Monday 08:00 America/New_York weekly report are recorded choices.
- Do not extend deprecated `product/js/` as the current deliverable.

## Approval gates

The human's latest “continue the chapter cycle.” approves Chapter 02 closeout and
one fresh continuation for **Staff Workflow Design Decisions Review**, documentation
only. This supersedes the earlier preference to finish review in Chapter 02;
unresolved design choices are not accepted by transition. D01 stays human-decided.
D02/D03/D05/D07 need review; D04/D06 need available store input; D08/D09 remain
unapproved implementation/testing and delivery scope.

The new chat must acknowledge waiting and stop until explicit human start approval
there. No application/deployment/testing sequence is open in this documentation
scope. Preserve this chat and earlier dated records; no archive or automatic chain.

Latest [executive summary](handoffs/2026-10-10/ch02-transition-closeout/EXECUTIVE_SUMMARY.md)
and [engineering handoff](handoffs/2026-10-10/ch02-transition-closeout/ENGINEERING_HANDOFF.md).
See [AGENTS.md](AGENTS.md) for the verbatim mandatory start gate.

Continuation: **[ShelfLife — Staff Workflow Design Decisions Review](codex://threads/01a125ee-a20b-7663-a7f7-f5fe694580d4)**,
ID `01a125ee-a20b-7663-a7f7-f5fe694580d4`, WAITING FOR IN-CHAT START APPROVAL.
[Creation receipt](handoffs/2026-10-10/ch02-transition-closeout/CONTINUATION_RECEIPT.md).
