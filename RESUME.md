# Resume prompt

Paste the block below into a fresh Claude Code session after a context reset.
Everything else in this repo — plus **`app_flutter/`** and **`product/supabase/`**
— is the context it needs.

---

## Copy this

```text
I'm resuming the Al Safa Market OS engagement. The working repo is:

D:\LLM-Data\Claude-Desktop\claude-code\shelflife

The engagement has PIVOTED TWICE. The current deliverable is a Flutter native
app under app_flutter/, talking to a Supabase backend under product/supabase/.
Read these first, in this order:

1. app_flutter/README.md       — what's built in Flutter, how to boot, how to
                                  point at Supabase, next steps to port
2. product/supabase/migrations/*.sql
                                — full schema + RLS + RPCs (unchanged and
                                  shared by any client — Flutter, JS, or CLI)
3. product/supabase/seed.sql   — 1 org, 2 branches, 4 kiosks, 1 admin,
                                  1 viewer, 12 staff with PINs
4. ASSESSMENT.md               — assessment of the client's original build;
                                  still accurate as context on WHY these
                                  choices were made
5. MARKET.md §8                — state date-label rules (STILL UNRESOLVED —
                                  which US state the store is in gates
                                  category legality)
6. PLAN.md                     — domain model, batch/lot design, FSMA 204
                                  requirements, category profiles

The pivot history — history only, do not relitigate:

- PIVOT 1 (before 2026-09-24): "extend their build" → "build fresh
  Supabase-backed PWA". Produced product/js/*, product/index.html.
- PIVOT 2 (2026-09-24 session): "vanilla-JS PWA" → "Flutter native".
  Reason: the store's use case is scanner-heavy on mid-range Android in a
  stockroom with bad wifi — the BarcodeDetector API is Chrome-only and
  iOS Safari fails often. Native ML Kit via mobile_scanner is far more
  reliable. Flutter also ships to Play Store + App Store + web/desktop
  from one codebase, so admin/rev-ops still gets a browser build.

Files kept from PIVOT 1 that are STILL LIVE:
- product/supabase/**              — the backend, stack-agnostic
- ASSESSMENT.md, MARKET.md, MEETING.md, PLAN.md, reference/AL_SAFA_MARKET_OS.md
                                    — specs and research, all still current

Files kept from PIVOT 1 that are DEPRECATED (kept for reference during port):
- product/js/*, product/index.html — the vanilla-JS shell. Do NOT extend
                                     these. Port their behavior to Flutter
                                     widgets in app_flutter/lib/, then delete.
- product/_serve.mjs              — dev server for the deprecated JS shell
- product/README.md               — describes the deprecated JS shell

Also kept: app/ — the original "scrappy demo" reference twin from even
earlier. Not the deliverable and never was. Barcode-scanner code in
app/js/scanner.js is worth reading before wiring mobile_scanner.

DECIDED — don't relitigate
- Flutter SDK is at D:\dev\flutter (D drive, C: stays clean).
  PUB_CACHE at D:\dev\pub-cache (User env var already set).
- Supabase-hosted (local Supabase for dev via `npx supabase start`).
- 1 org (Al Safa Market), 2 branches, 4 tiers:
    admin  — email/password, all branches, rev ops + user mgmt
    manager — email/password, one branch (nullable — see is_shift_lead)
    staff  — 4-6 digit PIN on kiosk device only (never per-user email)
    viewer — email/password, read-only rev ops
- Kiosk devices are their own Supabase auth accounts. Staff writes go
  through SECURITY DEFINER RPCs (kiosk_log_batch, kiosk_resolve_alert,
  kiosk_start_round, kiosk_add_round_item, kiosk_complete_round,
  kiosk_log_temp) that re-verify the PIN and stamp the audit log.
- Manager tier is not seeded — the shift-lead concept is expressed as
  is_shift_lead on staff_profiles.

STATUS AT LAST TOUCH (2026-09-24 — see app_flutter/README.md for detail)
- ✅ Schema, RLS, RPCs, rev ops views written and committed
- ✅ Seed script written and committed
- ✅ Flutter SDK 3.47.5 installed to D:\dev\flutter (PATH set, User scope)
- ✅ app_flutter/ scaffolded (Android + Web platforms)
- ✅ supabase_flutter + mobile_scanner packages added
- ✅ Login screen ported from product/js/screens/login.js
- ✅ Session detection ported (sealed classes: KioskSession, UserSession,
     UnknownSession) — see lib/supa.dart
- ✅ Web build compiles cleanly, serves via .claude/launch.json entry
     `shelflife-flutter` on port 8131 — visible in the built-in browser
- ⏳ Not yet ported: role-aware shell (4 read-only tabs), admin/alerts
     read-only, scan flow, rounds flow, alert-resolve action, admin
     user-mgmt writes
- ⏳ Android toolchain: NOT INSTALLED. flutter doctor shows Android SDK
     missing. Need Android Studio (~1 GB — install to D: to keep C: clean)
     before building an APK for a real phone.
- ⏳ Visual Studio toolchain: NOT INSTALLED. Only matters if we ship a
     Windows desktop build; ignore for now.
- ⏳ Real Supabase creds: NOT WIRED. app_flutter/lib/config.dart has
     placeholder anonKey. Choice open: hosted supabase.com vs local
     `npx supabase start` (needs Docker Desktop running).

BLOCKED ON — needed before a client demo
- Which US state the store operates in. Category flags
  allows_markdown_past_date and allows_donation_past_date are seeded
  false (conservative) and can't be finalised without it.
- Confirmation from the client that the seeded tier structure and
  branch/staff counts match their operation.

Give me a short summary of where things stand and what you'd do next. Don't
restate the documents back to me.
```

---

## If you only have one line

```text
Read D:\LLM-Data\Claude-Desktop\claude-code\shelflife\RESUME.md and follow it.
```

---

## State at last commit

Check current state with `git -C "D:\LLM-Data\Claude-Desktop\claude-code\shelflife" log --oneline`.

Remote: `github.com/bsi-beep-bozeman/grocerscans` (branch `main`).

| | |
|---|---|
| **Flutter app (current deliverable)** | `app_flutter/` |
| **Supabase backend (shared)** | `product/supabase/` |
| Deprecated JS shell | `product/js/`, `product/index.html` |
| Old scrappy demo (reference only) | `app/` |
| Flutter SDK location | `D:\dev\flutter` (PATH set at User scope) |
| Flutter web preview | `.claude/launch.json` → `shelflife-flutter` on port 8131 |
| Local Supabase | `cd product && npx supabase start` (Docker required) |
| Studio (schema/auth UI) | http://127.0.0.1:54323 after start |
| Client docs | `reference/AL_SAFA_MARKET_OS.md` |

**Boot the Flutter web preview:**

Use the in-app "Browser" pane's preview_start with `name: "shelflife-flutter"`,
or from a shell:

```bash
cd shelflife/app_flutter
D:\dev\flutter\bin\flutter.bat build web --release
```

Then serve `build/web/` on any static server, or use the launch entry.

**Rebuild the Supabase database (applies migrations + seed):**

```bash
cd product && npx supabase db reset
```

**First-time only** — after `supabase start`, copy the anon key from
`npx supabase status` into `app_flutter/lib/config.dart` (or pass via
`--dart-define=SUPABASE_ANON_KEY=...`).

## Order of next work

1. Wire real Supabase creds into `app_flutter/lib/config.dart` (or via
   `--dart-define`). Prove login end-to-end against seed accounts.
2. Port the role-aware shell (4 read-only tabs) from `product/js/screens/shell.js`
3. Kiosk PIN pad UI + `kiosk_verify_pin` RPC wire-up
4. Barcode scanner via `mobile_scanner` (native ML Kit — the whole point)
5. Alert resolution flow (PIN gate + resolution picker → `kiosk_resolve_alert`)
6. Admin user-mgmt writes: invite by email, assign role/branch, rotate PIN
7. Rounds flow: pair-audit start, mark items, close
8. Install Android Studio → Android SDK (to D:) when ready to build an APK
9. Delete `product/js/*` and `product/index.html` once Flutter has parity
10. Deploy target (hosted Supabase + Play Store + web build to any static host)

## Two open decisions worth flagging every session

- **State the store operates in.** Drives donation/markdown legality per
  category. See [MARKET.md §8](MARKET.md).
- **Manager tier vs `is_shift_lead` flag.** Current seed has no Manager users;
  staff-lead is a flag. Confirm with client before adding.

## Session 2026-09-25 — pending decisions and gap analysis

Captured here so a fresh Claude sees these without re-doing the analysis.

### New pending decisions from this session

1. **Tier structure — viewer AND supplier, or one merged tier?**
   Client (CM) reframed tiers as `admin / staff / viewer-or-supplier`. But
   `viewer` (internal read-only — accountant, exec, consultant) and `supplier`
   (external vendor) have very different data-access needs:
   - Viewer → sees everything, read-only
   - Supplier → must be scoped to their own `supplier_id` (deliveries,
     shelf-life-delivered, return credits) — merging with viewer leaks other
     suppliers' pricing and volumes
   Recommendation: two distinct tiers. Add a `supplier_profiles` table
   linking Supabase auth user → `supplier_id`, with RLS restricting all
   supplier reads to `WHERE supplier_id = auth.jwt() -> supplier_id`.
   **Awaiting client confirmation.**

2. **iOS build path.** Windows cannot build iOS. Options:
   - Mac Mini M4 (~$599 one-time)
   - Cloud CI: Codemagic / Bitrise (~$30–95/mo)
   - Android + web only for now, defer iOS
   **Awaiting client budget input.**

### Gaps between PLAN.md and the client brief (`reference/AL_SAFA_MARKET_OS.md`)

PLAN.md was written **before** the client's existing build was disclosed
(see the ⚠ banner at the top of PLAN.md). It covers the batch model, category
expiry, FSMA 204, and scanning well — but 8 features from the client brief
are not covered and need to be added to PLAN.md as an addendum:

| # | Feature | Status in PLAN.md |
|---|---|---|
| 1 | **Scan Product by Photo** (OCR/vision → extract name/brand/exp/size/category) | Absent — client's biggest AI feature |
| 2 | **Owner Dashboard** — inventory value at cost/retail, potential profit, top-20, by category | Absent |
| 3 | **Executive Dashboard** — weekly waste estimate, monthly summary | Absent |
| 4 | **Supplier Dashboard** — deliveries, avg shelf life received, losses by supplier | Partial (§8 Phase 5 mentions pharmacy-return worklist only) |
| 5 | **AI Insights** — rules-based analytics (patterns, waste trends, slow-moving, supplier risk, low-stock) | Absent |
| 6 | **Purchase Orders + PDF generation** | Absent |
| 7 | **CSV export** | Absent |
| 8 | **Weekly Monday 8AM inventory report** | Absent (Alerts engine §8 Phase 2 doesn't cover scheduled reports) |

Gap #4 (Supplier Dashboard) gets bigger if we accept the "supplier as external
tier" recommendation above — supplier users need their own scoped dashboard,
not just a report.

Also worth stealing UX-wise from **Xpiry (Expiry Notify Product Scanner
by Stavila Radu)** on Play Store, which the client cited as inspiration:
per-product custom reminder cadence, AI recipe generation from expiring
products (waste reduction angle), clean 3-tap scan flow, PDF inventory
export. It's a solo-user app so architecture doesn't transfer, but the
scan-hot-path polish and reminder controls do.

### Priorities this session left unfinished

1. Push `eb26bec` (Flutter pivot) — done
2. Write PLAN.md v2 addendum covering the 8 gaps above — partially done:
   see [PLAN_ADDENDUM_2026-09-25.md](PLAN_ADDENDUM_2026-09-25.md) which
   covers the tier split and Xpiry UX ideas. The other 6 gaps (OCR photo
   scan, Owner Dashboard, Executive Dashboard, AI Insights, Purchase
   Orders/PDF, CSV export, weekly report) still need design notes.
3. Update `product/supabase/migrations/` to split viewer/supplier tiers if
   client confirms — NOT done (blocked on decision; schema sketch in
   the addendum)
4. Then continue port order: role-aware shell → PIN pad → mobile_scanner →
   alert resolution
