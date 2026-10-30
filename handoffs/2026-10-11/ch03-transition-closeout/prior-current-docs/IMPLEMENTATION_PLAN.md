# ShelfLife — current implementation plan

Checkpoint: 2026-10-11 (Australia/Perth). This is the current execution/status map.
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
| Chapter workflow | Chapter 03 start explicitly approved; Staff Workflow Design Decisions Review completed in its owning chat. | Stop at this documentation checkpoint. Another transition/chat creation is not approved. |
| Staff Workflow Design Specification and Decisions Review | Human accepted [version 1](docs/superpowers/specs/2026-10-10-staff-workflow-design.md) plus [Chapter 03 addendum](docs/superpowers/specs/2026-10-10-staff-workflow-decisions-addendum.md), including admin onboarding and editable presets. | D01 retained; D02/D03/D05/D07 accepted. D04/D06 configuration design accepted; real store values deferred to onboarding. AC01–AC34 are future criteria, not passed tests. |
| Staff workflow implementation | Production auth integration, real catalog, batch writes, PIN attribution, alert resolution, rounds, offline persistence. | NOT APPROVED. Scope and acceptance checks must be approved before implementation. |
| Android device delivery | SDK absent in earlier setup; APK/camera on real device not verified. | Toolchain setup, device work and rollout require scoped approval. |
| Later feature groups | Photo OCR + review; purchase orders/PDF; owner/executive/supplier dashboards; CSV; rules-based insights and weekly reports. | Planned only; define and approve bounded chapters individually. |

## Current design deliverable — accepted at Chapter 03 checkpoint

1. Specify role-aware entry and staff kiosk PIN flow (admin/staff/viewer/supplier).
2. Specify known and unknown UPC/SKU receiving, sensible defaults and review.
3. Specify separate batches of the same product with quantity, date, supplier and location.
4. Specify alert review and permitted resolution actions with attribution.
5. Specify guided rounds, exceptions and completion.
6. Specify local-save, pending-sync, failure and retry states; do not portray a
   session-only mock as durable offline inventory.

The human approved Chapter 03 with “Approved to begin **Staff Workflow Design Decisions Review**” and accepted the combined design with “Accept the design with admin onboarding”. The [dated addendum](docs/superpowers/specs/2026-10-10-staff-workflow-decisions-addendum.md) records each intervening decision. Version 1 is preserved unchanged.

Accepted: active-session offline drafts with online resumption after lock/restart/person switch; five-minute inactivity lock, background/switch lock and five-failure/five-minute cooldown; admin catalog review; additional lead markdown/relabel and branch-specific admin confirmation; paired rounds with owned exceptions. D01 removal/transformation confirmation remains unchanged.

Admin first-run setup and later editable presets cover branch/jurisdiction, units/packs, real locations, supplier/lot requirements, labels/date rules and permitted actions. Store-specific values are collected during onboarding; missing prerequisites keep affected workflows unavailable. Policy changes preserve history and revalidate pending drafts. Past-date markdown/donation restrictions remain false.

No code, dependencies, migrations, application testing or deployment is included. G01–G10 remain historical local source findings from Chapter 02; no fresh application/deployed verification is claimed.

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

Chapter 03 start and design acceptance are granted. D08 implementation/backend/dependency/application-test scope and D09 delivery/sharing/rollback scope are NOT APPROVED. No application/deployment/testing sequence is open. Stop here for new transition approval; no additional chat creation or archive is authorized. A later transition still does not grant start approval in a new chat.

Proposed next bounded step, not authorized: **Staff Workflow Implementation Scope and Acceptance Plan**, documentation only, to select the first implementation slice, configuration/backend boundaries and exact validation scope before execution approval.

Latest [executive summary](handoffs/2026-10-11/ch03-review-closeout/EXECUTIVE_SUMMARY.md)
and [engineering handoff](handoffs/2026-10-11/ch03-review-closeout/ENGINEERING_HANDOFF.md).
See [AGENTS.md](AGENTS.md) for the verbatim mandatory start gate.

Continuation: **[ShelfLife — Staff Workflow Design Decisions Review](codex://threads/01a125ee-a20b-7663-a7f7-f5fe694580d4)**,
ID `01a125ee-a20b-7663-a7f7-f5fe694580d4`, DESIGN ACCEPTED; DOCUMENTATION CHECKPOINT COMPLETE; AWAITING TRANSITION APPROVAL.
[Creation receipt](handoffs/2026-10-10/ch02-transition-closeout/CONTINUATION_RECEIPT.md).
