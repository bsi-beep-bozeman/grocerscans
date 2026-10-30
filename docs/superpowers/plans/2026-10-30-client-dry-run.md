# Client Dry-run Implementation Plan

> Execute inline in the owning chat. User approval of the proposed sample-data walkthrough is already present; no new design approval is required. Preserve inherited work, do not commit or create another chat during this pivot.

**Goal:** Give the client a remotely accessible, repeatable admin/staff dry run of the existing Flutter screens.

**Architecture:** A separate `lib/client_demo.dart` entry point uses existing product widgets/controllers with new local demo adapters. Browser storage and synthetic identity are isolated from product data; backend work stays paused.

**Tech stack:** Existing Flutter/Dart dependencies, browser localStorage and IndexedDB, installed Chrome and Playwright, static Vercel/Netlify bundle.

## Tasks

- [x] Inspect current screens, repository contracts, previous preview and hosting capabilities; record approved design.
- [ ] Add `lib/client_demo/seed.dart` with twenty synthetic products and a valid initial setup.
- [ ] Add browser persistence abstraction and demo state with save-before-success, version checking, reset and isolated storage names.
- [ ] Add setup, identity and receiving adapters using current validators/contracts; do not initialize Supabase.
- [ ] Add welcome/role navigation, walkthrough and sample catalog around existing admin/staff screens; make simulation, local persistence and current limitations visible.
- [ ] Add meaningful adapter tests for activation, persisted reload, invalid PIN, policy propagation, conflict and failed persistence. Run focused tests and analysis.
- [ ] Build the isolated entry point using the installed cached Flutter toolchain and package only release assets with static hosting configuration.
- [ ] Run desktop/mobile browser dry runs, reload/reset/isolation and network checks. Save screenshots/results and fix findings.
- [ ] Prepare concrete publication packet and client guide. Obtain/confirm hosting connection, exact target and access approval, then publish and verify remote client access if authorized and available.
- [ ] Update current navigation/status with an additive dated evidence packet; preserve backend restoration as pending and the source chat for audit.

## Verification and rollback

Run `flutter test --no-pub test/client_demo` and analysis of added files; run existing setup/receiving/identity tests if integration changes justify it. Build `--target lib/client_demo.dart --no-pub --no-web-resources-cdn` to `.cache/client-dry-run/web`. Browser checks must cover persisted setup and staff drafts across reload, invalid PIN, reset confirmation, mobile layout and no unexpected network origins. Record actual results, not inferred pass states.

All new source is under `app_flutter/lib/client_demo*`, tests under `app_flutter/test/client_demo`, tooling under `app_flutter/tools/client_demo`, and docs under the dated dry-run packet. Do not alter original migrations, current production entry point, existing repository adapters, database/container state or credentials. Rollback is removal/unpublication of this isolated preview; it cannot restore the paused Chapter10 backend. Remote rollback is target-specific and must be documented after target selection.
