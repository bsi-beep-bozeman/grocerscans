# Client dry-run preview

Approved design, 2026-10-30 Australia/Perth. Source: ShelfLife — Receiving Foundation Connected… (`01a18027-683a-7043-b764-5939d2330ee2`). The human accepted an interactive sample-data preview and requires remote client access and repeatable dry runs. This is a user-directed pivot; connected backend validation remains paused, with final disposable-database restoration outstanding.

## Experience

A separate Flutter web entry point opens a welcome page with Admin setup, Staff receiving, sample catalog, a practical walkthrough, and Reset practice data. Reuse the existing SetupScreen, PinScreen, DraftWorkspace, controllers, validators and encrypted draft storage. Local demo adapters replace network repositories. This exposes current working UI, not a new replacement product. Clear practice-mode framing explains simulated identity and local persistence. No real credentials are requested.

One fictional store with twenty existing synthetic catalog products is preconfigured. Admin can edit, save and activate setup and manage practice locations/presets. Staff use disclosed practice PINs, find an item, enter quantities and notes, save, lock and reopen drafts. The current staff screen has no dedicated expiry-entry or stock-confirmation controls: the guide calls this out and uses Notes for a practice date/reference. No claim that stock is received. Activated admin configuration feeds the staff policy adapter on the same browser.

## Persistence and access

Each browser owns its practice data. Refresh and role switches retain confirmed saves; different browsers/devices are independent. Separate storage names isolate this preview from the product and prior test storage. Reset requires explicit confirmation and removes only demo data. Storage failures must not falsely acknowledge a save. Fixed practice PINs are a demonstration, not authentication. No backend endpoints, Supabase initialization, credentials, email, production data or database operations are included.

## Hosting

Prepare a self-contained static release for Vercel or Netlify, with same-origin assets, no external fonts and no backend connection. Vercel connection has been suggested; no confirmed account/site yet. Build/test/package locally before requesting the concrete publication target/access approval required by AGENTS rule 9. Client access must be verified from an anonymous browser after publication. No paid service, custom domain, repository push, merge or production deployment is included.

## Acceptance

Validate demo setup persistence/activation, validation failures and location edits; wrong and correct practice PINs; product lookup; staff draft save/reopen across page reload; role switching; reset and browser isolation; narrow/mobile and desktop layouts; no backend/network dependency. Preserve existing production source/migrations. Deliver a tested build, remote link once publication is possible, client walkthrough and explicit limitations. Keep the original backend pause and restoration evidence intact.
