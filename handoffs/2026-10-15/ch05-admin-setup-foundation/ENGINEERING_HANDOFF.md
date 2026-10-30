# Engineering handoff — Admin Setup Foundation

Checkpoint: **2026-10-15 Australia/Perth — R01 source + R02 local checks complete**.
Source: **[ShelfLife — Admin Setup Foundation](codex://threads/01a12f57-0cf7-7fa0-8e2a-542b48d3985d)**, exact ID `01a12f57-0cf7-7fa0-8e2a-542b48d3985d`.
Workspace: `D:/LLM-Data/Claude-Desktop/claude-code/shelflife`. Original chat is the authoritative input/output audit, preserved unarchived.

## Authority

Human explicitly said “approve to begin **ShelfLife — Admin Setup Foundation**” and “then continue the chapter cycle.” Human separately answered **“Approve R02 local checks”**, whose requested scope was installed-dependency offline static/unit/widget/preview tests, excluding backend creation, hosted calls, device tests, installation and publication. Subsequent “continue” messages resumed this same approved scope.

R01 authoring and R02 checks are consumed only for this chapter. One fresh continuation is authorized at this checkpoint. New-chat creation is not start approval; its mandatory gate remains. No R03–R09 action was granted. Do not infer authority from this handoff, plan, reviewer or earlier demo publication. Do not archive the source chat or create another continuation after the next chapter without human approval.

## Implementation and architecture

- `app_flutter/lib/main.dart`: replaces signed-in stub with Supabase admin setup gate. Existing publishable public key configuration retained; no new secrets.
- `lib/screens/login.dart`: provisioned-account entry, generic errors, duplicate-submit guard, scrollable layout and honest admin-only availability text.
- `lib/setup/setup_models.dart`: immutable typed config/reference/preset objects; strict keys/types/enums/size/precision; domain error paths including nested/list failures. Omitted policy fields inherit; explicit unknown overrides remain unknown.
- `setup_validation.dart`: effective category-version policy + product overrides, origins, per-product receiving/action readiness, structural reference errors and server-readiness wire DTO. Optional incomplete actions do not block ready receiving. Fixed past-date restrictions remain enforced. Ready always means configuration only.
- `setup_repository.dart` and `supabase_setup_repository.dart`: immutable requests, strict responses, six explicit RPC mappings, generic domain errors. Malformed/lost replies stay unconfirmed because a mutation may have committed.
- `setup_controller.dart`: server-confirmed revision/time, preserved unsaved edits, immutable pending-operation retries, conflict discard/reload, stale async result rejection, online identity/context unlock, expiry and five-minute idle lock. No durable offline storage. Library mutations preserve edits and invalidate saved readiness until save/reload. Accepted loads increment formVersion; concealment increments sessionViewVersion.
- `admin_setup_gate.dart`: auth identity events, foreground guard, background concealment and nested Navigator keyed by concealment generation. Same-person refresh does not unlock/discard. Different identity clears state. All protected dialogs use `useRootNavigator:false`; keep this invariant for future UI.
- `setup_screen.dart`, `setup_steps.dart`, `setup_forms.dart`, `preset_editor.dart`, `setup_review.dart`: six responsive steps; existing branch/category/product prerequisites; unit/pack settings; locations/preset lifecycle with reasons; exact version assignments; product overrides; real policy/date/quantity inputs; origins/missing reasons/history/explicit activation review. Existing preset descriptions are omitted on edit/duplicate unless user explicitly chooses replacement, avoiding silent erasure.
- `app_flutter/test/setup/`: typed/adapter/controller/lifecycle/widget/visual/accessibility tests and explicitly synthetic fakes. Fake server replies are not backend evidence.
- `app_flutter/demo-data/validate_catalog.dart`: minor CLI import/output lint cleanup only. Earlier 20-product preview/CSV preserved; no hosted release change.

## Database source (not executed)

Files `product/supabase/migrations/20261013000000_store_setup.sql` and `20261013000001_store_setup_api.sql` retain the October 13 planned names (no collision; later authorship/reviews October 14–15). Existing migrations unchanged.

New tables cover drafts, immutable versions, active pointer, presets/version history, locations, operation outcomes and append-only setup audit. Every public endpoint derives active admin/org from auth.uid and unexpired JWT exp, denies active supplier/device conflicts, validates scope, and exposes only safe reference fields. Fixed `pg_catalog,pg_temp` search paths, qualified objects, RLS and explicit revokes protect new tables/helpers. No legacy inventory grants are broadened by source.

Mutations take the org lock first, reauthorize after waiting and compare expected revision. Operation identity is org + actor + UUID, with the entire action/request JSONB fingerprint. Identical retries return recorded outcomes after authorization; changed payload/key combinations reject. Activation atomically snapshots configuration, effective values/reference names/readiness, advances pointer and records audit/outcome. Pointer/version reads now use one query to avoid mismatched GET responses. Preset/location deactivation preserves history. No setup RPC writes inventory, receiving, rounds, alerts or operational audit.

Endpoints: `get_admin_setup_context()`, `get_store_setup(p_branch_id)`, `save_store_setup(p_branch_id,p_operation_id,p_expected_revision,p_configuration)`, `activate_store_setup(p_branch_id,p_operation_id,p_draft_id,p_expected_draft_revision,p_expected_active_revision,p_reason)`, `mutate_setup_preset(p_request)`, `mutate_setup_location(p_request)`. Error codes 42501/PT409/PT422/PT401 map to denied/conflict/invalid/expired. p_request matches Dart snake-case DTO JSON. BranchSetupState includes optional authoritative readiness; real source endpoint returns it.

Names 120 UTF-16 units; reasons/descriptions/policy references 2,000; config 256 KiB compact UTF-8; schema1; precision0–3/each0. Source checks finite numbers and Dart-compatible whitespace. JSONB normalizes numeric spelling, so original `1` vs `1.0` spelling is not recoverable server-side. Baseline branches/categories/products have no active/revision fields: catalog maps them to true/1. History response is latest100 scoped events, old stored history retained. Existing cross-org product/category corruption fails closed.

Transaction assertion source: `product/supabase/tests/store_setup.sql`. Exact unexecuted authorization, retry, revocation, immutable-history, rollback/count and two-connection procedures: [admin-setup-acceptance.md](../../../docs/testing/admin-setup-acceptance.md). These procedures have not established PostgreSQL compilation or runtime acceptance.

## Verification and unresolved issues

[EVIDENCE.md](EVIDENCE.md) and raw logs record 73 combined passing cases +1 accessibility case, clean whole-app analysis and valid20UPC data. Phone/desktop widget fixtures were visually inspected after loading bundled text/icon fonts. Independent source reviews resolved domain paths/readiness/whole quantities, atomic active reads, visible discard reset, description preservation, misleading readiness wording, offscreen unlock and same-frame person-switch dialog reuse. No known consequential source-review defect remains.

Still unknown: actual SQL compile/grants/RLS behavior; live unique identity and JWT behavior; RPC response compatibility against a real Supabase target; persistence through app/browser restart; real lost-response and concurrency races; device lifecycle/screen reader; backup/recovery execution; build/hosted deployment. No S1-01–12 criterion that requires a connected layer is fully accepted based only on these local tests. Full four-tier access and S2–S4 workflows remain incomplete. Real operating rules/catalog values are onboarding inputs, not defaults to invent.

## Checkout and preservation

Branch main, HEAD `f56d5068e94cf80819f55be952a95769ad508c97`. No commit/stage/branch/push/merge. Source is uncommitted/untracked in the inherited dirty checkout by approved scope. [SOURCE_HASHES.json](SOURCE_HASHES.json) identifies exact candidate; [GIT_STATUS_AFTER.txt](GIT_STATUS_AFTER.txt) includes inherited dirt. Baseline preserved in `handoffs/2026-10-13/ch05-admin-setup-foundation/`; comparison confirms pubspec/lock/supa/preview catalog/cockpit/inherited preview tests unchanged since that baseline. PLAN/addendum/RESUME/AndroidManifest inherited modifications remain untouched. Earlier dated chapter records are not overwritten.

## Rollback (instructions, not executed)

No deployed/database change exists to roll back. Preserve the complete dirty checkout before any source rollback. Reverse only [OWNED_TRACKED_DIFF.patch](OWNED_TRACKED_DIFF.patch) for main/login after checking no later edits; archive rather than indiscriminately deleting newly authored setup/test/SQL files. Preserve prior demo data, inherited changes and all audit handoffs. Do not use repository-wide reset/clean.

Before any future DB application, approve a disposable target and backup/reset boundary. Runtime rollback must preserve production version/audit history; disable setup entry/RPC execution under separate approval rather than deleting historical records. Resetting the disposable acceptance target is appropriate only within explicitly approved cleanup. See the acceptance document for full DB rollback procedure; no rollback/grant command is authorized here.

## Exact next steps

1. Create exactly one fresh **ShelfLife — Admin Setup Backend and Application Validation** chat under the already granted transition; record its actual ID/receipt and wait for acknowledgement. Opening contains the mandatory start gate. Do not fork or send a start instruction.
2. Human in that new chat explicitly approves the named step. Until then, zero tools/files/planning/background work there.
3. Once that gate is satisfied, inspect installed local tooling/read-only target options and propose the precise disposable backend (runtime, paths, ports, accounts, data), backup/reset boundary and migration/grant list. No target is selected or approved yet. Ask for R03 specifying creation/start, all retained/new migration application, synthetic fixtures, SQL/API/concurrency tests and scoped cleanup. Installation requires a distinct R06 approval if needed.
4. Only after exact-target approval, perform the connected sequence in that owning chat: baseline identity/version/migrations, SQL compile/apply, transaction suite, two-connection cases, actual DTO/RPC auth/persistence verification and no-inventory-change checks. Fix scoped defects and record results/hashes. Do not substitute mocks for backend proof.
5. Separately obtain R05 approval for named Android/browser targets and backend, then verify session/background/restart/offline/conflict/accessibility flows. Record unavailable platforms as gaps. Camera/staff PIN inventory operations remain outside S1.
6. Any hosted target (R04), commit/push/merge (R07), build/publication/access change (R08) or rollout/rollback (R09) requires its own action approval. Earlier five-product publication does not authorize updating the site or publishing20UPC data.
7. At the next bounded checkpoint repeat summary/engineering/evidence/plan/status/index updates, retain both audit chats, then wait for new transition approval before another continuation.
