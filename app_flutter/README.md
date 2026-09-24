# ShelfLife — Flutter app

The current client deliverable. Ships to **Android (Play Store)**, **iOS (App
Store)**, and **web** from one Dart codebase.

Talks to the Supabase backend at [`../product/supabase/`](../product/supabase/)
— that's stack-agnostic and shared. If you touch the schema, do it there.

## Why Flutter (not the vanilla-JS PWA in `../product/js/`)

- Staff scan barcodes on mid-range Android in a stockroom with bad wifi. The
  browser `BarcodeDetector` API is Chrome-only and iOS Safari fails often.
  `mobile_scanner` uses native ML Kit — far more reliable.
- iOS PWA push notifications are weak/restricted; native has full support.
- App-store presence gives the client credibility and one-tap install.
- Same codebase still produces a web build for admin/rev-ops on desktop.

See `../RESUME.md` for the full pivot history — do not relitigate.

## Prereqs

- Flutter SDK at `D:\dev\flutter` (installed 2026-09-24)
- PATH already includes `D:\dev\flutter\bin` at User scope
- `PUB_CACHE=D:\dev\pub-cache` (User env var) — keeps package cache off C:
- Node (for the static preview server the desktop app uses)

Optional for building APKs:
- Android Studio + Android SDK — **not yet installed.** Install to D: when
  needed; see `../RESUME.md` for the redirect approach that keeps C: clean.

## First-time setup

```bash
cd shelflife/app_flutter
D:\dev\flutter\bin\flutter.bat pub get
```

## Point at Supabase

Two options:

**A. Edit `lib/config.dart`** — replace the placeholder anon key with the
value from `npx supabase status` (local) or Project Settings → API (hosted).

**B. Pass at build time** (safer for hosted, keeps secrets out of git):

```bash
D:\dev\flutter\bin\flutter.bat build web --release ^
  --dart-define=SUPABASE_URL=https://<project>.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

## Run

**Web (works today, no Android SDK needed):**

```bash
cd shelflife/app_flutter
D:\dev\flutter\bin\flutter.bat build web --release
```

Then serve `build/web/`. The desktop app has a launch entry for this — in the
Browser pane, use `preview_start` with `name: "shelflife-flutter"` (serves on
http://localhost:8131 via `.claude/launch.json`).

**Android (blocked on Android Studio install):**

```bash
D:\dev\flutter\bin\flutter.bat run -d <deviceId>
```

`flutter devices` lists connected phones/emulators. Won't work until Android
SDK is present — `flutter doctor` will confirm.

**iOS (blocked on macOS — Windows can't build for iOS).**

## What's built

- [lib/config.dart](lib/config.dart) — Supabase URL + anon key (env-overridable)
- [lib/supa.dart](lib/supa.dart) — `supa` client accessor; `SessionProfile`
  sealed type (`KioskSession` / `UserSession` / `UnknownSession`) mirroring the
  vanilla-JS `currentProfile()`; `signOut()`
- [lib/screens/login.dart](lib/screens/login.dart) — email/password login,
  ported 1:1 from `../product/js/screens/login.js`
- [lib/main.dart](lib/main.dart) — Supabase initialization, Material 3 theme,
  auth-gated root, signed-in stub

## What's not built (in rough order)

1. Role-aware shell — 4 read-only tabs (Overview / Stock / Shipments / Rev ops
   / Admin). Port from `../product/js/screens/shell.js`.
2. Kiosk PIN pad — new UI, wires to `kiosk_verify_pin` RPC that already exists
   in `../product/supabase/migrations/`.
3. Barcode scanner — `mobile_scanner` widget wrapping ML Kit. Read
   `../app/js/scanner.js` for the flow to port (format list is EAN-13, UPC-A,
   EAN-8, UPC-E, Code 128 per `../PLAN.md` §2).
4. Alert resolution — PIN gate + resolution picker → `kiosk_resolve_alert`.
5. Admin user-mgmt writes — invite by email, assign role/branch, rotate PIN
   (RPC `set_staff_pin` exists).
6. Rounds flow — pair-audit start, mark items, close.
7. Offline queue (IndexedDB on web / sqflite on mobile) + service worker
   equivalent. Per `../PLAN.md` §5.1 this is a Phase 1 requirement, not a
   later enhancement.

## Architecture notes

Following the Dart coding-style rules loaded from
`D:\LLM-Data\dot-claude\rules\ecc\dart\`:

- `final` for locals, `const` where possible
- No `!` operator unless "null here is a bug and crashing is correct"
- Sealed classes for state hierarchies (see `SessionProfile` in `supa.dart`)
- No relative cross-feature imports; `package:` imports throughout
- Widgets favor composition over inheritance
- Domain / data / presentation split will emerge as the app grows — the
  current file layout is intentionally shallow while there's little to organize

## Commands

```bash
# One-off analysis
D:\dev\flutter\bin\flutter.bat analyze

# Format everything
D:\dev\flutter\bin\dart.bat format .

# Add a package
D:\dev\flutter\bin\flutter.bat pub add <package>

# Web build
D:\dev\flutter\bin\flutter.bat build web --release

# List detected devices (browsers, emulators, physical phones)
D:\dev\flutter\bin\flutter.bat devices

# Full toolchain check
D:\dev\flutter\bin\flutter.bat doctor
```
