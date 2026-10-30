# Camera scan / batch / stock register / team access / unit-rate — checkpoint

Paused mid-session at human request 2026-10-30, Perth time, so either Codex or a
fresh Claude session can continue. This is additive to, and does not revise,
the Chapter10 / 2026-10-30 client-preview history already in STATUS_LEDGER.md
and NEXT_CONVERSATION_HANDOFF.md. Backend remains PAUSED per the standing
human instruction; nothing here touches Supabase, migrations, or hosting.

## What the human asked for (verbatim intent, kept for continuity)

While clicking through the admin/staff "client dry run" demo
(`app_flutter/lib/client_demo.dart`), the human asked why the camera barcode
scanner was missing (it existed only in the older, separate "Cockpit" preview,
`app_flutter/lib/preview/cockpit.dart`, never ported into the newer admin/staff
receiving workspace). Asked what "as good as the shipped product" should look
like, the human described four workflows — these are the spec for any
continuation:

1. **Capture**: open camera, capture a UPC/SKU barcode or manual entry (for
   unlabeled items like raw meat) → app registers the product → asks for the
   expiration → writes the expiration into the right batch. A batch is just a
   label, e.g. `UPC-001-1030-2026`.
2. **Shared ledger**: every entry lives in one place — title, description,
   UPC, SKU, batch number, expiration, days remaining, stock count — and
   admin, staff, and a connected vendor can all pull it up.
3. **Team & permissions**: admin assigns staff, vendor, or supervisor, and
   controls what each can view/edit.
4. **Unit/rate**: an authorized role can update the unit/rate used in the
   system or for a given stock item.
   "...and the rest of other workflows" — i.e. keep extending this toward
   full parity with the ~80%-finished shipped product, not just these four.

A plan for this was written and approved via EnterPlanMode this session; the
full approved plan text is reproduced in full further down in this document
(it also lives at `C:\Users\CMs_Automation\.claude\plans\zippy-fluttering-turing.md`
on the machine this session ran on, but that path is outside the repo and
likely not visible to a different environment or to Codex — treat the copy
below as canonical).

## What is implemented (this session)

All of it lives inside the existing `app_flutter/lib/client_demo/` browser-local
demo (IndexedDB-backed, no network calls) plus shared `lib/receiving/` and
`lib/setup/` code that the real Supabase-backed app will also benefit from
later. Role names (`staff` / `supervisor` / `vendor`) were deliberately chosen
to mirror the backend's existing `app_role` enum (`admin` / `manager` /
`staff` / `supplier` / `viewer` — see
`product/supabase/migrations/20260924030001_rls.sql` and
`20260925000001_supplier_tier.sql`) so this maps onto real RLS later instead
of needing a redesign.

**New files**
- `app_flutter/lib/receiving/stock_register.dart` — `StockRegisterEntry` model
  + `StockRegisterRepository` interface.
- `app_flutter/lib/receiving/stock_register_screen.dart` — read-only
  `DataTable` UI (title, description, UPC, SKU, batch, expiration, days left,
  quantity, captured-by).
- `app_flutter/lib/client_demo/demo_stock_register_repository.dart` — demo
  implementation: iterates every roster member's encrypted vault, decrypts
  with their derived key, joins against the preview catalog.
- `app_flutter/lib/identity/team_models.dart` — `TeamRole` (staff / supervisor
  / vendor), `ModuleAccess` (view/edit per module: receiving / register /
  setup), `TeamMember`, `TeamRepository` interface.
- `app_flutter/lib/identity/team_screen.dart` — admin-only roster UI: add/remove
  members, toggle per-module view/edit checkboxes.
- `app_flutter/lib/client_demo/demo_team_repository.dart` — demo roster
  persistence (new `team` key inside the existing single-blob `DemoState`
  JSON), seeded with Alex (staff, PIN 2468) and Sam (staff, PIN 1357) exactly
  as before — no behavior change for the two pre-existing staff logins.
- `app_flutter/lib/client_demo/demo_keys.dart` — `demoDerivedKey(base, index)`:
  shared, index-based vault-key derivation so register aggregation and login
  agree. Index 0 = unmodified key (Alex), index 1 = `v ^ 0x55` (Sam, bit-for-bit
  identical to the old hardcoded formula — old saved drafts still decrypt).

**Modified files**
- `app_flutter/lib/receiving/draft_workspace.dart` — ported the camera pattern
  from `cockpit.dart` (`MobileScanner` + `onDetect` + `errorBuilder`, same
  "Camera unavailable..." copy); added a "Look up this identifier" manual
  fallback (submits the Identifier field through the same lookup path as a
  scan — needed for items with no visible barcode); added a Batch field
  (auto-filled via `generateBatchLabel`, still editable) and an expiry-date
  picker; added an optional `openStockRegister` callback that shows a
  "View stock register" button when non-null.
- `app_flutter/lib/receiving/receiving_draft.dart` — added
  `batchCodeForSku(sku)` (leading letters of the SKU, else `'UPC'`) and
  `generateBatchLabel({code, sequence, date})` →
  `"$code-${seq.padLeft(3,'0')}-$mm$dd-$year"`, e.g. `UPC-001-1030-2026`.
  Sequence is derived from how many of the signed-in actor's own drafts
  already reference that product — no new counter storage.
- `app_flutter/lib/client_demo/demo_identity_repository.dart` — `begin(pin)`
  now authenticates against the team roster instead of two hardcoded PINs, so
  admin-added staff/supervisor members can sign in. Vendor PINs are checked
  separately (see below) since vendors never open the receiving/staff session.
- `app_flutter/lib/client_demo/demo_app.dart` — added a third "03 / VENDOR"
  home-screen card (PIN dialog → read-only `StockRegisterScreen`, no vault of
  its own); admin top-bar gained "Stock register" and "Team & access" buttons;
  staff's `DraftWorkspace` now gets `openStockRegister` wired in only when the
  signed-in roster member has `register.view` permission; updated stale
  in-app copy that claimed camera/shared-stock were out of scope.
- `app_flutter/lib/setup/setup_models.dart` — `UnitSetup` gained an optional
  `rate` (num, cost/price per unit); backward compatible (existing configs
  without the key still validate).
- `app_flutter/lib/setup/setup_steps.dart` — the units step gained a rate text
  field per enabled unit, wired through the same `update('units', ...)` path
  as precision.

## Verification done

- `flutter analyze` — clean, whole project.
- `flutter test` — **130/130 pass**. One real regression was caught and fixed
  along the way: a new expiry-date `ListTile` with a trailing button failed
  Flutter's "trailing widget consumes the entire tile width" assertion at
  390px width + 200% text scale (`test/receiving/workspace_test.dart`); fixed
  by replacing it with a `Wrap`. Re-ran the full suite after the fix — clean.
- `dart format` run on every touched file.
- Rebuilt `flutter build web --release --no-web-resources-cdn --target
  lib/client_demo.dart` twice (once after the initial implementation, once
  after the ListTile fix + the manual-identifier-lookup addition) and served
  it locally (`node serve-preview.mjs`, `http://127.0.0.1:8132`).
- Manual browser walkthrough, confirmed working:
  - Home screen shows all three role cards including the new vendor one.
  - Alex (2468) and Sam (1357) still sign in correctly via the new
    roster-based `begin()`.
  - "Scan barcode" opens the camera view and correctly shows the
    "Camera unavailable... Mobile web camera requires HTTPS" fallback text in
    this sandboxed, non-HTTPS, camera-less browser context — this is the
    *expected* degraded-path behavior (same text as the original cockpit
    build), not a bug. The actual live-decode path (`onDetect` →
    `_lookupByCode`) could not be exercised without a real camera + HTTPS
    origin; it has not been tested with a live camera.
  - The new "Look up this identifier" manual-entry path was reached (typed a
    UPC-A code for "Ground beef" as Sam) — **this was interrupted mid-check,
    before confirming the catalog match actually resolved and populated the
    Item name field.** Resume by re-running this exact step.

## NOT yet verified / explicitly open

Resolved in the 2026-10-30 continuation below: manual-identifier lookup,
stock register (admin + staff), Team & Access (add vendor/supervisor,
permission-toggle reactivity), vendor PIN flow, unit-rate field, the
Supervisor routing gap, and live camera decode (confirmed working on real
hardware — see addendum). Still open:

- `DemoGuide`'s step-by-step copy on the home screen was only partially
  updated (steps 3 is updated; the register/team/vendor/rate workflows are
  not yet described there for a first-time clicker).
- Hosting (Vercel/Netlify) was the original ask before this pivot and remains
  untouched this session, per the human's own "forget Vercel, show me the
  prototype" redirect — see NEXT_CONVERSATION_HANDOFF.md for that thread's
  standing state. The prepared release ZIP from the client-dry-run checkpoint
  predates camera/stock-register/team-access/rate and would need a fresh
  build + bundle before publishing.

## Addendum — continuation, 2026-10-30 (Claude, grocerscans checkout)

Picked up this checkpoint from a separate local checkout
(`D:\LLM-Data\Claude-Desktop\claude-code\grocerscans`, same git remote) after
the human pointed to this handoff. Worked against the actual
`D:\...\shelflife\app_flutter` tree described above (not the grocerscans
copy, which is stale).

**Verified live in the browser** (rebuilt `client_demo.dart`, served via
`serve-preview.mjs` on `http://127.0.0.1:8132`):
- Manual-identifier lookup: UPC `990000000028` → resolved to "Ground beef",
  batch auto-filled `MEA-001-1030-2026`.
- Stock register: opens correctly from both staff and admin, shows the saved
  entry with computed days-remaining.
- Team & Access: added a vendor ("Riverside Produce") and a supervisor
  ("Priya"); vendor PIN flow worked end to end into a correctly-scoped
  read-only register view; toggling Sam's `register.view` off immediately
  removed her "View stock register" button (confirmed reactive).
- Unit-rate field: entered a rate, saved, draft revision incremented and
  persisted correctly.
- Live camera scan: inside Claude Code's own sandboxed Browser pane,
  re-tested and got the same degraded-path result as above — confirmed this
  is an **environment limit, not an app bug**: the pane itself blocks
  `getUserMedia` requests outright (its own tooling reports "the page... 
  requested camera access, which is blocked in the Browser pane"),
  regardless of origin. Asked the human to instead open
  `http://127.0.0.1:8132` in their own real desktop browser on this machine
  (not the sandboxed pane) — `localhost` is a secure context, so camera
  permission can actually be granted there. **The human confirmed it worked**:
  the camera opened and the live `onDetect` → `_lookupByCode` scan path
  functioned on real hardware, not just the fallback. This is the first
  confirmation in any session that the actual decode path works, not only
  its degraded-path handling.

**Fixed: the Supervisor routing gap.** Rather than adding a parallel
"Supervisor" login card, gated a "Setup (units & rate)" button into the
existing staff/supervisor top bar (`app_flutter/lib/client_demo/demo_app.dart`),
visible whenever the signed-in roster member's `permissions['setup'].edit` is
true — this works for anyone granted the permission, not just a hardcoded
`supervisor` role string, matching how `register.view` was already gated.
Clicking it unlocks the same `SetupController`/`SetupScreen` the admin
persona uses. New Supervisors added via Team & Access
(`app_flutter/lib/identity/team_screen.dart`) now default to `setup`
view+edit so the capability is discoverable out of the box; admin can still
revoke it. The "02 / STAFF" home-card copy was updated to mention supervisors
sign in through the same PIN gate. Verified end to end: added supervisor
"Priya" (PIN 9081), signed in via the staff PIN screen, confirmed the
"Setup (units & rate)" button appeared and opened a working Setup screen.

`flutter analyze` clean; `flutter test` **131/131 pass**.

## How to resume

```bash
cd app_flutter
flutter build web --release --no-web-resources-cdn --target lib/client_demo.dart
node serve-preview.mjs
# open http://127.0.0.1:8132
```

Pick up the verification checklist above in order; each item is small and
independent. The approved plan (below) is the source of truth for scope if
anything is ambiguous.

## Git state

Everything described above, plus all other pending work (receiving-foundation
migrations, docs, prior handoffs/reports), was committed in this continuation
at the human's explicit request — see `git log` on `main` for the commit(s).
`site-preview/` was deliberately excluded: it is its own nested git
repository (has a `.git` with no remote configured) and was left untouched
rather than risk git turning it into a broken gitlink. Nothing was pushed to
`origin` this session.

## Full approved plan (reproduced verbatim for portability)

> ### Camera scan, batches, stock register, team access & unit/rate — client demo
>
> See the human's four workflows at the top of this document for the Context
> section; phases below are as approved and were followed in file-naming and
> structure exactly as written.
>
> **Phase 1 — Camera scan → product → expiry → batch**: port
> `lib/preview/cockpit.dart:980-1046`'s `MobileScanner` pattern into
> `lib/receiving/draft_workspace.dart`; on decode/manual entry, query
> `CatalogQuery('upc'|'sku', value)` and feed a single match into the
> existing `_choose(item)`; add a `showDatePicker` for `expiry_date`; add
> `generateBatchLabel` in `lib/receiving/receiving_draft.dart` writing into
> the existing `lot` field, pre-filled but editable.
>
> **Phase 2 — Stock register**: `lib/receiving/stock_register.dart`
> (`StockRegisterEntry` + `StockRegisterRepository`),
> `lib/client_demo/demo_stock_register_repository.dart` (iterates every
> roster member's vault, decrypts with `DraftCrypto`, joins the preview
> catalog), `lib/receiving/stock_register_screen.dart` (read-only table).
> Wire in from admin's demo home, staff's `DraftWorkspace`, and a new
> read-only vendor persona on `DemoHome` (own PIN, opens straight to the
> register).
>
> **Phase 3 — Team & access**: `lib/identity/team_models.dart`
> (`TeamMember`, `TeamRole` staff/supervisor/vendor matching the backend's
> admin/manager/staff/supplier/viewer vocabulary, `TeamRepository`),
> `lib/client_demo/demo_team_repository.dart` (persists roster inside
> `DemoState`'s JSON blob, seeds Alex+Sam unchanged),
> `lib/identity/team_screen.dart` (admin-only: list/add/remove, per-module
> view/edit checkboxes). Phase 2's vendor card and Phase 4's edit gate both
> read permissions from this roster.
>
> **Phase 4 — Unit & rate**: extend `UnitSetup` in
> `lib/setup/setup_models.dart` with optional `num? rate`; extend the unit
> step in `lib/setup/setup_steps.dart` with a rate field; gate editability by
> `TeamMember.permissions['setup']?.edit` (admin always; supervisor when
> granted).
>
> **Verification**: `flutter analyze` + `flutter test`; rebuild
> `lib/client_demo.dart` for web, serve via `node serve-preview.mjs`; manual
> walkthrough of scan→batch→save, register visibility from all three roles,
> Team & Access add/remove/permission-toggle, vendor PIN flow, unit-rate edit
> gated correctly. Flag to the client afterward that this is still
> browser-local — real multi-device/vendor sync needs the existing
> `receiving_identity` / `receiving_foundation_api` / `supplier_tier`
> migrations reconnected, which is separate follow-up work.
