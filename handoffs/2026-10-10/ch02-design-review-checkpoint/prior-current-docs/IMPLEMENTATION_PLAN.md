# ShelfLife — current implementation plan

Checkpoint: 2026-10-09 (Australia/Perth). This is the current execution/status map.
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
| Chapter workflow | Documentation checkpoint complete; one fresh continuation created, ID `01a12123-430e-7ab1-9ab1-06e648f8535f`; waiting acknowledgement verified. | Transition authorization consumed. No connected application sequence remains open in this setup scope; no additional chat may be created without new transition approval. |
| Staff Workflow Design Specification | Selected next bounded step: role/PIN entry, receiving, product/batch details, alert actions, rounds, offline/sync states. | Transition approved; execution awaits explicit human start approval in the new chat. Deliver a written specification, not code. |
| Staff workflow implementation | Production auth integration, real catalog, batch writes, PIN attribution, alert resolution, rounds, offline persistence. | NOT APPROVED. Scope and acceptance checks must be approved before implementation. |
| Android device delivery | SDK absent in earlier setup; APK/camera on real device not verified. | Toolchain setup, device work and rollout require scoped approval. |
| Later feature groups | Photo OCR + review; purchase orders/PDF; owner/executive/supplier dashboards; CSV; rules-based insights and weekly reports. | Planned only; define and approve bounded chapters individually. |

## Selected next design deliverable — start approval pending

1. Specify role-aware entry and staff kiosk PIN flow (admin/staff/viewer/supplier).
2. Specify known and unknown UPC/SKU receiving, sensible defaults and review.
3. Specify separate batches of the same product with quantity, date, supplier and location.
4. Specify alert review and permitted resolution actions with attribution.
5. Specify guided rounds, exceptions and completion.
6. Specify local-save, pending-sync, failure and retry states; do not portray a
   session-only mock as durable offline inventory.

Checkpoint: a reviewable specification with screen inventory, permissions,
happy/error/empty/offline states, acceptance criteria and unresolved decisions.
No code, new dependencies, migration execution, application testing or deployment
is included in this documentation-only step. The user's transition approval does
not independently start its execution in a new chat.

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

Current position: documentation closeout completed and ONE fresh continuation
created for the selected documentation-only step; it is idle and waiting. In-chat start approval and each
applicable external/connected action remain distinct gates. Record the
human wording, owning chat and exact target in the ledger. At an approved connected
sequence's checkpoint, update this plan, append evidence to the ledger, write new
dated handoffs and stop. See [AGENTS.md](AGENTS.md).
