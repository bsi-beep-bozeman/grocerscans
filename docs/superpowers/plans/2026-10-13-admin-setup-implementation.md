# Admin Setup Foundation Implementation Plan

> For agentic workers: use subagent-driven-development for the bounded tasks below; preserve inherited work and do not commit. User-approved source scope and R02 local checks supersede older pending-source/test notes. No database or release execution is approved.

**Goal:** Implement the existing-admin six-step configuration foundation with online saved drafts, immutable activation, scoped presets/locations and honest capability readiness.

**Architecture:** Typed Dart configuration and repository boundary, a Flutter admin shell and six-step form, and additive PostgreSQL RPC migrations. Server owns authorization, revision checks, operation reconciliation and readiness. Local UI validation is guidance, never permission.

**Tech Stack:** Existing installed Flutter/Dart, supabase_flutter and flutter_test; existing PostgreSQL/Supabase schema. No new dependencies.

## Checkpoint status — 2026-10-15

Tasks 1–4 and local evidence/records are complete. Checked SQL items mean authored and statically reviewed, never executed. Test sequencing and reproduced failures are recorded in the [evidence](../../../handoffs/2026-10-15/ch05-admin-setup-foundation/EVIDENCE.md); some UI coverage was expanded after implementation/review. Actual persistence locking uses consistent organization-first locking and reauthorization, as detailed in the handoff. R03/R05 are deferred for separate exact-target approval. Transition checkbox changes only after an actual creation receipt.

## Authority and working context

2026-10-13, Australia/Perth. Owner [ShelfLife — Admin Setup Foundation](codex://threads/01a12f57-0cf7-7fa0-8e2a-542b48d3985d). Human approved the named S1 step and one chapter transition; separately answered “Approve R02 local checks”. S1 proposal, online contract, precision 0–3 and input limits are adopted within that named scope. Existing approved design remains fixed. Work in the existing dirty checkout as the incoming scope specifies; preserve inherited files and capture a baseline. No branch/commit/push, installation, backend application, device/browser validation or publication. R03–R09 retain exact-target gates.

## Contract decisions

- UUIDs identify existing org/branch/category/product and new location/preset/version/draft entities. Server derives org/admin from auth.uid(), denying supplier/kiosk/conflicting identities.
- Names: 1–120 characters when supplied; descriptions/reasons: at most 2,000; configuration JSON <=256 KiB; schema_version = 1. Partial drafts use empty/unknown fields. Reject unknown keys, unsupported enum values, bad types or references rather than coercing them.
- Configuration envelope: store, units, receiving, bindings, products, fixed restrictions. Store contains display_name/country/region/timezone/confirmed. Units contain code and precision. Receiving contains location_ids, hold_location_id, exception_role (unknown/lead/admin).
- A category binding names category_id and an exact preset_version_id. A product setting names product_id, stock_unit, pack_name, pack_count, and an explicit override map for allowed preset fields. Unset override keys inherit; a named unknown value remains unknown. Reject duplicate bindings/products/units.
- Preset policy: supplier_requirement/reference_requirement/lot_requirement (unknown/required/optional), entry_modes (manual/sku/barcode), label_profile (unknown/manual_only/standard_upc_ean), expiry_mode (unknown/printed/calculated), expiry_rule (value/unit/policy_reference), and actions.
- Actions: markdown, relabel, donation, discard, freeze, conversion. State unknown/not_used/configured; policy_reference; prerequisites; source/destination location IDs; quantity_relationship; resulting_date_rule; label_required. Freeze/conversion need all transformation information, and source/destination must belong to the selected branch. No guessed yields/durations/eligibility. Past-date markdown/donation remain false and lead/admin confirmation is fixed.
- Readiness is per configured product and capability. Unknown/unavailable references yield reasons; deactivated preset/location blocks new readiness. Printed receiving needs confirmed store/timezone, enabled unit/precision, pack definition, active locations and hold, explicit metadata choices and exception role, and a supported manual/label path. Calculated mode additionally needs a supplied positive rule/value/unit/reference.
- Structural/reference errors reject save. Incomplete valid drafts save. Activation requires at least one ready capability, records all readiness reasons for others, and never marks staff operations implemented. Configured but incomplete optional actions stay unavailable.
- Server get context returns safe org/admin/branches/categories/products (no cost/PIN fields). Get setup returns saved draft, active version/pointer revision, preset/version catalog, locations, readiness, and bounded recent audit/history. Mutation response includes authoritative entity/revision/time.
- save_store_setup(p_branch_id,p_operation_id,p_expected_revision,p_configuration); activate_store_setup(p_branch_id,p_operation_id,p_draft_id,p_expected_draft_revision,p_expected_active_revision,p_reason). Preset and location mutations use explicit IDs, expected revisions, operation UUID and change reason. New entities use expected revision 0. Duplicate preset creates a new stable ID. No hard delete.
- Operation identity: org + admin + UUID; fingerprint includes action and entire submitted payload. Same retry returns prior response after reauthorization; different payload/action rejects. Client retains the identical request after an ambiguous transport failure; editing requires reconcile/reload before a new request. Concurrent taps disabled. Serialization must be stable.
- Lock after five minutes inactive, any background/inactive event, person switch/sign-out. Conceal protected state and invalidate in-flight responses. Same-user unlock requires online auth and admin-context revalidation; different user clears drafts. No new durable offline storage. Token refresh alone must not discard unsaved edits.

## Task 1 — typed configuration and validation

Files: lib/setup/setup_models.dart, setup_validation.dart, setup_repository.dart; test/setup/setup_validation_test.dart and reusable fixture helpers.

- [x] Write tests for blank draft readiness, complete printed receiving, partial optional actions, effective inherited/override fields, deactivated/cross-branch refs, precision, flags, size/unknown fields, round-trip and immutability.
- [x] Run targeted offline tests, capturing missing-behavior failure; implement typed schema parsing and immutable models plus readiness and repository contracts; rerun to green.
- [x] Self-review, independent spec review then quality review. Resolve defects before dependent implementation.

Representative assertion: `expect(validateSetup(blank, references).capabilities.every((c) => !c.ready), isTrue)`. Complete fixtures must report “Configuration ready — workflow implementation pending”, never operational readiness. Invalid JSON must throw a domain validation exception with field paths.

## Task 2 — server persistence and authorization source

Files: product/supabase/migrations/20261013000000_store_setup.sql, 20261013000001_store_setup_api.sql; product/supabase/tests/store_setup.sql; docs/testing/admin-setup-acceptance.md.

- [x] Author transaction-based SQL assertions before endpoint source: denied role matrix, cross-tenant refs, duplicate retry, changed-payload conflict, concurrent revision scenario, immutable history and inventory counts.
- [x] Add draft/version/active, preset/version, location, operation and append-only audit records; RLS/revoke direct writes and fixed-search-path definer APIs with explicit identity/tenant checks.
- [x] Mirror typed JSON validation/readiness and exact client wire contract. Lock branch for configuration/activation and entity rows for library edits; one transaction commits snapshot/pointer/audit/operation result. Use deterministic lock ordering.
- [x] Static review SQL and tests; do not run them without R03/R04. Record SQL runtime acceptance outstanding. Independent spec/security quality reviews.

SQL checks must assert exceptions rather than merely print queries. Concurrency instructions name two disposable connections and expected one-winner outcome. Direct mutations must fail for authenticated role even when an admin JWT is present.

## Task 3 — authenticated client and persistence controller

Files: lib/setup/supabase_setup_repository.dart, setup_controller.dart, admin_setup_gate.dart; lib/main.dart and screens/login.dart; test/setup/setup_repository_test.dart and setup_controller_test.dart.

- [x] Write failing tests for RPC arguments/response parsing, request reuse after lost response, edit/retry reconciliation, revision conflict, latest-request ownership, denial, sign-out/person switch and timed lock.
- [x] Implement explicit RPC adapter and observable controller; server-confirmed saved status only. Preserve visible in-session edits on transport failure; no raw server details/secrets in UI.
- [x] Replace signed-in stub with reactive auth entry using online user validation plus server-resolved context. Cancel auth subscriptions/timers; discard stale completions; never fall back to preview or staff identity.
- [x] Run targeted tests and review; existing login remains for provisioned accounts, no account creation.

## Task 4 — six-step setup and reusable presets

Files: lib/setup/setup_screen.dart, setup_steps.dart, preset_editor.dart, setup_review.dart, optional narrowly scoped form helpers; test/setup/setup_screen_test.dart.

- [x] Write failing widget cases: six named steps, server draft resume, required-unknown choices, named preset duplicate/edit/deactivate, location lifecycle, category assignment, product unit/pack/explicit override, review origins/reasons, save/activation/conflicts, lock concealment.
- [x] Implement labelled dropdowns/text fields/chips with no raw JSON editing. Show existing catalog prerequisites clearly when none exist. Confirmation review includes affected branch/products/categories, reason and unchanged active version on failure.
- [x] Test phone 390 and desktop 1440 widths, 200% text scale, keyboard and semantic labels. Scroll every form; 56px primary controls. Use fixed policy explanatory text.
- [x] Run all setup tests, existing preview regression, and offline static analysis; fix issues within scope. No dependency downloads.

## Task 5 — checkpoint and transition

- [x] Produce evidence by actual layer, file hashes, commands/results, preserved inherited source, limitations, rollback and exact next steps. Never call SQL source locally verified backend behavior.
- [x] Update IMPLEMENTATION_PLAN.md, STATUS_LEDGER.md, SESSION_INDEX.md, NEXT_CONVERSATION_HANDOFF.md and dated executive/engineering packet.
- [x] If R03/R05 are not granted, next bounded step is Admin Setup Backend and Application Validation; obtain approval before any connected execution. Keep any later approved connected sequence here until its checkpoint.
- [x] At verified approved-scope checkpoint create exactly ONE fresh continuation as authorized, record receipt and source link, include verbatim mandatory start gate; await in-chat human approval there. Keep this source unarchived. No unattended chain.

## Local commands and evidence

Existing Flutter launcher may stall; use installed cached flutter_tools.snapshot through the existing Dart executable if needed, with --no-pub and no version check. No downloads/upgrade. Run targeted `flutter test --no-pub test/setup`, then `flutter test --no-pub test/widget_test.dart`, and `flutter analyze --no-pub`. If an existing unrelated analyzer issue exists, record it separately and verify touched files. SQL/hosted/device suites are explicitly not substitutes for these local tests.


