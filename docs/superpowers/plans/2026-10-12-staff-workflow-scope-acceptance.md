# Staff Workflow Scope and Acceptance Implementation Plan

> **For agentic workers:** Use the executing-plans skill for later authorized task-by-task execution. This is a scope and acceptance proposal, not executable authorization or a complete code recipe. Do not dispatch agents or execute any task merely because it appears here.

**Goal:** Establish a bounded admin setup foundation before staff inventory workflows are implemented.

**Architecture:** Retain Flutter in `app_flutter/` and the Supabase migration source in `product/supabase/`. Add an admin-only, online configuration workflow with immutable activated versions, explicit readiness reasons and server authorization. Keep inventory mutations, staff PIN sessions and durable offline capture behind subsequent implementation gates.

**Tech stack:** Existing Flutter/Dart, `supabase_flutter`, PostgreSQL/Supabase; existing `flutter_test` for proposed local tests. No new package or toolchain is selected for installation.

2026-10-12, Australia/Perth. **Documentation complete for review. D08/D09 execution approvals remain pending.**

Owner: **[ShelfLife — Staff Workflow Implementation Scope and Acceptance Plan](codex://threads/01a12796-7acf-70b2-94f9-8d0efc7a2e87)**, `01a12796-7acf-70b2-94f9-8d0efc7a2e87`.

Source: **[ShelfLife — Staff Workflow Design Decisions Review](codex://threads/01a125ee-a20b-7663-a7f7-f5fe694580d4)**. [Accepted specification](../specs/2026-10-10-staff-workflow-design.md) and [accepted addendum](../specs/2026-10-10-staff-workflow-decisions-addendum.md) remain authoritative for product behavior. Their historical pending-decision wording is superseded by the addendum, not silently edited.

## 1. Authority and first slice

The human approved this named documentation chapter and one fresh continuation on 2026-10-12. The request to finish verification covers this chapter's documentation verification. No application test, dependency installation, migration execution or connected application check is authorized by it. Transition approval does not satisfy the next chat's mandatory in-chat start gate.

**Recommended first slice S1: Admin Setup Foundation.** An existing, active organization admin can sign in, select an existing branch, save/resume the six-step setup, duplicate/edit presets, review missing requirements, and activate a configuration version for explicitly ready capabilities. Other identities receive a restricted entry state; no staff operational workspace is enabled in S1.

This produces a usable configuration prerequisite with a bounded acceptance boundary. Choosing known-product receiving first would also require staff identity, durable drafts, new receipt contracts, idempotency and policy persistence before its first honest stock confirmation. S1 reduces those dependencies without changing the accepted end-state design.

S1 includes:

- Auth-state-aware routing for an unambiguous active admin; explicit sign-out, expired-session, inaccessible-profile and non-admin states. Existing admin accounts/orgs/branches are prerequisites; no account/device provisioning UI.
- Six setup steps from the addendum, with saved server draft, a review page and versioned activation. The detailed configuration fields below are in scope; executing the configured stock actions is not.
- Organization-owned named presets, branch bindings, product/category applicability, explicit product overrides, confirmed locations, deactivation and preserved history.
- Server validation, optimistic concurrency, retry reconciliation, tenant isolation and append-only configuration audit records.
- A capability summary distinguishing **Not configured**, **Configuration ready — workflow implementation pending**, and **Not used**. No “receiving works” claim until S2 is accepted.

S1 excludes staff PIN verification/cooldown, staff draft queues, scanner/camera, catalog approval, inventory receiving or action writes, rounds, external lookup, OCR, legal verification, dashboards, suppliers' operational UI, account provisioning and bulk import. No deprecated `product/js/` or preview/hosting changes. Accepted D01/D02/D03/D05/D07 rules remain fixed, displayed where relevant and unavailable as editable policy switches.

## 2. Fresh local evidence and its limits

These observations were made by reading local source on 2026-10-12. No app or database was executed. Chapter 02's other G01–G10 findings and September demo results remain historical unless explicitly identified here.

| Source | Fresh observation | Consequence for the proposal |
|---|---|---|
| `app_flutter/lib/main.dart` | Authenticated entry returns `_SignedInStub` | S1 needs production entry routing; preview success does not establish it |
| `app_flutter/lib/supa.dart` | Kiosk-first resolution; staff selection lacks an active filter; no supplier-profile query | Add a narrow server-resolved admin setup context; ambiguous identity denies access rather than choosing the first row |
| `app_flutter/pubspec.yaml` | Declares Dart `^3.13.4`, Supabase Flutter `^2.17.2`, mobile scanner `^7.4.2`, Flutter tests/lints | These are manifest declarations, not installed-version or compatibility verification |
| `app_flutter/test/widget_test.dart` | Tests import the preview/catalog | Preserve preview tests; author separate setup tests only after approval |
| Initial migration | Branch timezone exists with a historical default; product lacks explicit stock-unit/config-version fields; batches use `numeric(10,3)` and have supplier/lot fields | Do not treat defaults as confirmed store input or invent unrestricted precision |
| RPC migration | PIN-bearing staff writes, no receipt operation ID; alert resolution updates alert/audit; round completion sets a timestamp without the accepted completion checks | Existing staff RPCs are not the future operational contract; S1 must not route to them |
| Base RLS and supplier migrations | Broad row read policies and legacy manager policies coexist with supplier-specific rules; helpers can resolve via `limit 1` | Do not infer complete field privacy or identity uniqueness; explicitly guard every new setup endpoint |

Root branch `main`, HEAD `f56d5068e94cf80819f55be952a95769ad508c97`; source/prototype changes are inherited and uncommitted. `app_flutter/pubspec.lock` exists, but installed tooling was not probed. Hosted database identity/state, live health, actual admin profiles, devices and real store values remain unknown. No credential/config values were copied into this plan. This is not a comprehensive security audit of the old backend.

## 3. Setup prerequisites and configuration contract

S1 depends on an explicitly provisioned active admin, organization and branch. For future isolated tests, use synthetic fixtures: two organizations, two branches in the first and one in the second, active/inactive admin, staff/lead/viewer/supplier/kiosk identities, and an identity with conflicting profile memberships. These are fixtures only, never real store configuration.

| Step | Data to collect or confirm | Activation condition |
|---|---|---|
| 1 Store/branch | Existing organization/branch references, display name, country/region, branch timezone | Explicit confirmation; no inference from device timezone or old database default |
| 2 Units/packs | Enabled units from each/kg/g/lb/oz/L/mL; decimal precision; product stock unit; descriptive pack name/count | Each is integer; measured precision proposed 0–3 to match current numeric storage; positive whole item counts for each-based packs; no automatic conversion |
| 3 Locations/receiving | Actual active locations and receiving-hold location; supplier, delivery-reference and lot requirements per category/product; exception owner role | Requirement choices use unknown/required/optional, not a false default; missing required metadata prevents later receipt confirmation |
| 4 Labels/expiry | Barcode/SKU/manual modes, supported named label profile, printed/calculated mode, supplied rule value/unit/applicability/policy reference | Unsupported labels retain manual entry; calculated mode is unready without a supplied rule; printed expiry is entered separately for each later receipt |
| 5 Allowed actions | Per-category actions with not-configured/not-used/configured state; prerequisites; source/destination, quantity relationship, resulting date rule and label requirement for transformation policies | Incomplete action rules stay unavailable; past-date markdown/donation flags fixed false; no guessed duration, yield or eligibility |
| 6 Review/activate | Effective preset and product overrides, affected branches/products/categories, missing reasons, change reason | Explicit admin activation of a valid revision; readiness computed by server per capability and applicability |

Precision 0–3 is a new implementation proposal for D08 review, not a reopened D04 store-value question. Requirements beyond three decimals need a separately scoped numeric-storage change before activation. Display inputs that are not supported as unavailable rather than silently rounding them.

Configuration-ready printed receiving requires confirmed branch/jurisdiction/timezone, product unit and precision, printed mode, active real location and hold location, explicit supplier/reference/lot choices and exception routing. Calculated receiving additionally requires its supplied rule. Optional transformation setup can remain unfinished. Readiness means metadata is complete, not that its policy is legally validated or its workflow implemented.

Preset precedence: branch/category binding selects a named versioned preset; an explicitly recorded product override replaces only named fields; unset fields inherit. Two bindings for the same branch/category at the same active revision are invalid. Review shows both origin and effective value. Unknown required values block the affected capability. Product/branch/category/supplier/location references must belong to the same organization, and locations to the selected branch.

S1 is online-only for admin persistence. Show server-confirmed save separately from unsaved input. On network failure retain input while the screen remains open, show unsaved status, and allow retry. Do not promise admin drafts survive a crash before server confirmation. This does not change D02's accepted future staff offline behavior. Lock/conceal setup on five-minute inactivity, backgrounding or sign-out; require online session revalidation before revealing it again.

## 4. Proposed backend target and persistence boundaries

**First validation target:** an explicitly approved disposable, loopback-only Supabase development instance, populated with synthetic data and all five retained migrations in their existing order. This target has not been created or inspected. No linked hosted project, production database, real account or external catalog is implicitly selected. Installation/container startup/reset and migration application need R03; a hosted test environment needs R04 with its exact project identity.

**Source target:** new additive migration files under `product/supabase/migrations/`. Do not rewrite already dated migrations or their manager enum. Old functions remain out of this slice; the presence of S1 does not certify their safety for real staff operations.

Proposed records (final SQL authoring occurs only after R01):

| Record | Ownership and key fields | Persistence/invariant |
|---|---|---|
| `store_setup_drafts` | org, branch, draft ID, revision, schema version, structured configuration, editor, updated time | Mutable only through authorized save; compare expected revision; saved across admin sessions |
| `store_setup_versions` | org, branch, version ID, source draft/revision, immutable configuration snapshot, activator, time, reason | Append-only; no ordinary update/delete; snapshot includes effective presets and overrides |
| `store_setup_active` | org, branch, active version ID, pointer revision | One active version per branch; switch atomically with activation/audit |
| `store_presets` and `store_preset_versions` | org, stable ID/name, immutable version content, deactivated time | Duplicate creates distinct identity; bindings reference an exact version; deactivation preserves references |
| `store_locations` | org, branch, stable ID, name, active flag | Names may change prospectively; snapshots preserve historical name/meaning; referenced rows not deleted |
| `setup_operations` | org, authenticated admin ID, operation ID, payload fingerprint, result ID/status | One recorded outcome per retry key; changed payload with same key is a conflict |
| `setup_audit_events` | org/branch, authenticated admin, action, before/after revision IDs, reason, server timestamp | Append-only and committed in the same transaction as mutation; no PIN or token fields |

Use constrained typed envelope fields plus schema-versioned structured configuration. Server validation must reject unknown fields, invalid enum values, invalid reference scope and oversize input; propose name length 1–120 characters, notes/reason at most 2,000, and configuration payload at most 256 KiB for review. These limits are implementation proposals, not existing constraints. Credentials never belong in the payload or logs.

Proposed endpoint contract:

- `get_admin_setup_context()`: resolve exactly one active admin membership from the authenticated subject; reject conflicting active staff/supplier/kiosk identity, unknown/legacy roles and disabled profiles. Return only allowed org/branch identities; no PIN hashes or financial fields.
- `get_store_setup(branch_id)`: return authorized saved draft, active version and readiness reasons. Server derives org; caller cannot choose a different tenant.
- `save_store_setup(branch_id, operation_id, expected_revision, configuration)`: authorize again, validate structure/references, lock draft revision, atomically save and audit; return revision and saved time. Retrying the same payload/operation returns the recorded result.
- `activate_store_setup(branch_id, operation_id, draft_id, expected_draft_revision, expected_active_revision, reason)`: revalidate membership, scope, configuration and referenced active records; lock branch activation; write immutable version, active pointer, operation outcome and audit in one transaction. Any failure leaves previous active version untouched.
- Preset save/duplicate/deactivate and location create/rename/deactivate use the same authorization, operation and revision conventions; any deactivation that invalidates a draft produces explicit readiness reasons. An active snapshot remains historical; future confirmations will revalidate current availability.

RLS and explicit grants must deny direct table mutation and endpoint execution to anonymous/non-admin callers. Definer endpoints use a fixed search path and explicit current identity/scope checks. Do not reuse a `limit 1` helper as proof of unique membership. Test both direct database access and RPCs; UI hiding alone is insufficient. New policies must not broaden existing inventory permissions. Any required change to legacy grants is reviewed as a separate scoped migration/permission action before application.

Local Flutter state contains form edits and last confirmed revision only. Server is the S1 persistence authority. No local PIN material, background uploads, service-role keys, cross-tenant cached setup, or new offline package. Inventory quantities/expiry/audit history are unchanged by setup activation. Later receipts record the active configuration version and revalidate drafts before confirmation; S1 does not implement that consumer.

## 5. File ownership and proposed task order

All paths below are relative to the repository root. They are proposed files, not existing deliverables. Stay on the existing dirty checkout unless a later explicit workflow decision authorizes isolation; preserve inherited work. No automatic commit or push.

| Task | Proposed files | Responsibility and completion evidence |
|---|---|---|
| T1 Contract/model | Create `app_flutter/lib/setup/setup_models.dart`, `setup_validation.dart`, `setup_repository.dart`; create `app_flutter/test/setup/setup_validation_test.dart` | Typed config/unknown states, effective preset calculation, readiness and abstract persistence interface; fixture assertions for every validation boundary |
| T2 Persistence source | Create `product/supabase/migrations/20261012000000_store_setup.sql`, `20261012000001_store_setup_api.sql`; create `product/supabase/tests/store_setup.sql` | Versioned records, grants/RLS, atomic authorized operations; plain transaction-based SQL assertions without requiring a new test extension |
| T3 Entry/repository | Modify `app_flutter/lib/main.dart`, `supa.dart`, `screens/login.dart`; create `app_flutter/lib/setup/supabase_setup_repository.dart`, `app_flutter/test/setup/setup_repository_test.dart` | Admin context endpoint, auth state transitions, denied/expired states; no staff fallback or preview routing |
| T4 Setup flow | Create `app_flutter/lib/setup/setup_screen.dart`, `setup_steps.dart`, `preset_editor.dart`, `setup_review.dart`; create `app_flutter/test/setup/setup_screen_test.dart` | Six steps, save/resume, effective values, missing reasons, errors, revision conflict, explicit activation and non-operational readiness label |
| T5 Acceptance harness | Create `app_flutter/integration_test/setup_flow_test.dart`, `docs/testing/admin-setup-acceptance.md` | Local/connected procedure and evidence capture; integration-test SDK dependency only if explicitly authorized; do not install it under ordinary source approval |
| T6 Checkpoint | Update current plan/status/index/pointer and add a new dated handoff | Record actual tested revision/target, failures, limits, rollback and next approval boundary |

Suggested sequence after approvals:

- [ ] Confirm S1 and R01 scope, actual source state and versioned migration filenames before authoring; if timestamps collide, choose new monotonically ordered names and record them.
- [ ] Author T1 acceptance cases for unknown fields, partial readiness, explicit overrides and fixed restrictions, then minimal model/validator code. Execute only under R02.
- [ ] Author T2 isolated authorization/concurrency/rollback assertions, then SQL source. Apply/run only under R03/R04 for the named target.
- [ ] Author T3 entry/repository behavior tests, then routing and adapter code. Retain session input on save failure, reconcile operations before retry, and clear protected state on session change.
- [ ] Author T4 widget cases before the UI; check six steps, keyboard/large-text behavior and draft/activation messages.
- [ ] Under R02 run targeted tests/static analysis, then the existing preview tests for regressions. Under R03 run database assertions and end-to-end setup persistence against the isolated target. Do not infer backend acceptance from fake-repository tests.
- [ ] Under R05 run the specified Android/web lifecycle and layout cases; retain one owning chat for the approved connected sequence until a verified checkpoint.
- [ ] Close only the evidence level actually achieved; no production-ready claim from source-only or fake tests. Stop for any later action approval not already granted.

This scope plan intentionally supplies contracts and observable outcomes rather than pre-writing the application in Markdown. Once S1 is approved, the implementation owner turns these tasks into exact code/test steps using the verified tooling and endpoint contract; no new product decisions or packages may be slipped into that refinement.

## 6. Acceptance matrix and exact future evidence

All tests below are **NOT RUN**. A passed documentation check does not satisfy them.

| S1 ID | Scenario | Required observable evidence | Layer |
|---|---|---|---|
| S1-01 | Active admin vs inactive/conflicting/non-admin identity | Only one active admin context enters setup; generic denial otherwise; no protected form after logout/session change | Unit/widget + DB/auth integration |
| S1-02 | Save halfway; close; sign in and resume | Same server draft/revision/choices; incomplete banner; failed save never says saved | Widget + connected restart |
| S1-03 | Activate complete printed-date configuration with actions unfinished | Immutable version and readiness only for configured capability; inventory actions remain unimplemented/unavailable; no batch created | Validator + DB + integration |
| S1-04 | Missing timezone/unit/lot choice/location or malformed precision/rule | Field-specific reasons; activation rejects affected readiness; unknown never coerced to optional; fixed flags cannot become true | Validator + DB |
| S1-05 | Edit/deactivate preset/location used by active configuration | Prior version unchanged; draft shows invalid references; new activation requires review; no inventory history rewritten | DB + widget |
| S1-06 | Two admins save/activate the same base revision | One valid winner; other gets conflict with current revision; no last-write-wins or partial audit | Concurrent DB sessions |
| S1-07 | Double tap or response lost after commit | Retry with same operation returns same version; one activation/audit effect; changed payload with same key rejects | DB + adapter fault injection |
| S1-08 | Wrong organization/branch references; direct table/API calls as viewer/supplier/staff/lead/kiosk/anonymous | Denied without cross-tenant data; admin cannot set caller identity; no sensitive fields in response | DB role matrix + authenticated API |
| S1-09 | Role revoked after loading review; audit write failure | Save/activation rejects; previous pointer unchanged; no unaudited configuration; form has actionable error | DB fault injection + UI |
| S1-10 | Browser back/reload, background, five-minute inactivity, offline save | Server-confirmed draft retained; working data concealed on lock; online verification required; unsaved offline input never falsely marked durable | Web + Android device |
| S1-11 | Phone width 390, desktop width 1440, 200% text, keyboard and screen reader | All required controls reachable, labels/errors announced, touch targets at least 56 logical pixels, no colour-only or horizontal form dependency | Widget + device/manual accessibility |
| S1-12 | Activate or restore configuration | Counts/values in batches, alerts and rounds unchanged; no legacy staff RPC invoked; prior history retained | DB snapshots + application trace |

Proposed local commands, only after R02 and available-tooling verification: from `app_flutter/`, `flutter analyze --no-pub`, `flutter test --no-pub test/setup`, then `flutter test --no-pub test/widget_test.dart`. Expected: no analysis errors and all selected assertions pass. Missing dependencies stop this lane; no implicit network fetch. T5 integration-test dependency or new tooling belongs in a specific R06 amendment.

Proposed R03 database command: from `product/`, `psql` against the explicitly approved loopback target with `ON_ERROR_STOP=1`, executing `supabase/tests/store_setup.sql`; expected every assertion passes and fixtures are rolled back. Verify local connection identity before running. Applying retained/new migrations and creating test users is separately listed in R03; do not use a linked remote reset. Concurrent tests need two explicitly isolated test connections and assertions on pointer/audit counts. Write no credentials in output/evidence.

Connected evidence packet must include exact source revision or changed-file hashes, approved target identifier, tool/runtime versions, migration list, fixture identities (non-secret), command/results, role matrix, before/after counts, conflict and dropped-reply traces, screenshots and unresolved defects. Inspect actual API/table shapes for sensitive fields. Package resolution, mocks and screenshots are not database authorization evidence.

R05 device scope: one named Android phone/tablet with OS/app version recorded and one named desktop browser/version, synthetic admin fixtures and the same approved test backend. Check S1-02/10/11 across save/restart/background and sign-out. Camera testing is deliberately deferred to S2; iOS and Cowork are excluded. If either platform is unavailable, record that acceptance gap instead of substituting the old demo evidence.

## 7. Whole-design coverage and later slices

No accepted criterion is dropped. Partial coverage is explicit; AC numbers refer to the accepted documents.

| Slice | Criteria and remaining responsibility | Dependency |
|---|---|---|
| S1 Admin setup | AC29 full save/resume; AC30 configuration portion only; AC31 policy-authoring portion; AC33 configuration history; AC34 setup missing-rule portion. S1-01/08/10/11 contribute to AC02/03/26/27 but do not pass those whole staff criteria | Approved S1/source and validation actions |
| S2 Known/unknown receiving, secure staff identity and durable queue | AC01–03, AC06–12, AC21–28, AC30 receiving end-to-end, AC31, AC32 and AC34 manual receiving. Includes catalog request/admin approval and explicit receipt confirmation | S1 persistence + unique staff identity, five-failure/five-minute cooldown, server sessions, safe read shapes, local storage selection and receipt/idempotency schema approved |
| S3 Stock containment/actions | AC04–05, AC13–17, action portions of AC12/21–24/32 | S2 attribution/queue, quantity/hold ledger, approvals, atomic parent/child effects and real configured policies |
| S4 Paired rounds | AC18–20 and rounds portions of AC21–27 | S2 identity/queue, S3 owned exceptions, same-branch pair confirmation, immutable worklist and completion rules |

S2 must revalidate active policies and actor on replay, preserve original/recovering/approving actors separately, and seal durable drafts after lock/restart/person switch until online verification. S3 must keep holds distinct from loss, prevent negative stock, and preserve historical dates/lineage. S4 must never complete with unvisited checks, missing partner or pending uploads. All slices retain fixed past-date flags and accepted permission/timing rules. Acceptance of S1 is not acceptance of the complete staff workflow.

## 8. Action-specific approval register

Approval must record human wording, source chat, date, action, exact target and evidence scope. Empty target or a plan row is not approval. The current authorization covers R00 and one R10 transition only.

| ID | Action and target | Status / required detail |
|---|---|---|
| R00 | Chapter 04 local scope plan, documentation verification, records/handoff | GRANTED 2026-10-12 in owning chat; no application execution |
| R01 | Author S1 Flutter, SQL migration source and tests in the listed local paths | NOT GRANTED; accept S1, precision/limits and source boundaries; no database application/install/commit |
| R02 | Offline local analysis/unit/widget/preview regression tests on that source using existing dependencies | NOT GRANTED; exact commands above; no network/package fetch or backend calls |
| R03 | Create/start isolated local backend, apply retained/new migrations, synthetic accounts/fixtures, SQL/API/integration tests and fixture cleanup | NOT GRANTED; name loopback target/data directory, runtime/container tooling, ports and disposable data; approve migration/grant changes on that target explicitly; installation separate |
| R04 | Hosted backend inspection/application/connected validation | NOT GRANTED; exact project/environment, allowed reads/writes, migration/grant scope, synthetic accounts, isolation, backup and recovery target required |
| R05 | Android and browser device/application validation | NOT GRANTED; exact devices/browsers/backend and S1 cases; no camera, iOS, Cowork, distribution or client sessions |
| R06 | Package/toolchain installation or update | NOT GRANTED; exact package/tool/version/source and purpose must be presented first; S1 proposes no new package; integration_test SDK addition needs explicit scope |
| R07 | Commit, push, PR/merge | NOT GRANTED; exact selected diff/repository/branch and each remote action; preserve inherited changes; audit requirements apply before any later commit |
| R08 | Deploy/publish/share/access changes | NOT GRANTED; release artifact hash, target, audience, access model, migration order and rollback target separately identified; old demo permission cannot be reused |
| R09 | Rollout and hosted rollback execution | NOT GRANTED; named environment/cohort/window/owner, trigger and exact artifact/database recovery action; rollback plan is not rollback permission |
| R10 | Chapter 04 closeout and exactly one fresh gated continuation | GRANTED by latest user message; record actual creation receipt; no work before explicit human start approval in new chat; no further creation authority |

Recommended next bounded chat: **ShelfLife — Admin Setup Foundation**. Its opening presents S1 and R01/R02 as the proposed local implementation lane, with R03–R09 still separate. Human start approval must unambiguously accept the named local scope and intended test lane; if only documentation review is approved, remain in that review. Do not request production release approval before a reviewable candidate exists.

## 9. Exit criteria, limitations and rollback

Chapter 04 exit: scope/contract, requirements coverage, future test targets, approval register and navigation/handoff saved; preserved-file hashes, ledger history, links and gate verified. This chapter has no application test pass/fail results.

Future S1 source checkpoint may be labelled **implemented locally; backend/device acceptance outstanding** when R01/R02 alone are granted and passed. Full S1 acceptance additionally requires S1-01–12 evidence at their required layers. Missing R03/R05 is a recorded gate, not a reason to run them without approval. No release while authorization/persistence evidence is incomplete.

Local documentation rollback: compare this chapter's `prior-current-docs/` copies, correct current summaries and append a dated correction. Preserve completed records and actual chat receipts. No reset/clean, credential edits or archive.

Future local implementation rollback: revert only the named S1 diff after preserving inherited files. An approved disposable backend may be recreated only within its explicit R03 data boundary. Future hosted recovery prefers disabling the new entry path and restoring a previously validated app artifact; do not drop version/audit tables or erase real drafts. Configuration reversal creates a new audited activation from a prior version after current validation; it does not mutate history. Backup restore/data reconciliation, downtime and target ownership must be defined under R09 before release. No such recovery has been executed here.

Remaining decisions: accept or revise S1, precision/input limits and proposed persistence contract; approve R01/R02 if desired; identify R03 runtime/target before backend tests; identify R05 devices; separately decide D09 release/sharing/rollback. Real store values remain deferred to admin onboarding and are not requested again in this scope chapter.
