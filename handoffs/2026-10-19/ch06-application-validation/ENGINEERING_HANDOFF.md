# Engineering handoff — Chapter 06 remains open

2026-10-19 Australia/Perth. Source: **ShelfLife — Admin Setup Backend and Application Validation**, ID `01a13ce2-a8fe-7063-8867-260412dd096a`, [original chat](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a). Preserve this chat for exact inputs and outputs. This is an interruption handoff, not a completed chapter or transition.

## Authority and current position

R03/R06, scoped Docker repair, corrected restore retry and R05 local Chrome checks were explicitly approved. [Latest action receipt](../../2026-10-16/ch06-restore-retry/APPROVAL_RECEIPT.md) records “approving both.” The restore succeeded and browser validation began. A new Docker startup failure and failed authorized endpoint rename trigger the repair packet's explicit stop gate. [Administrator-mode startup request](DOCKER_ELEVATED_START_REQUEST.md) is prepared but not approved/executed. R04 hosted, R07 commit/push/merge, R08 publication/access and R09 rollout remain unapproved. One eventual fresh continuation is authorized only after the connected checkpoint; its mandatory human in-chat start gate remains.

The earlier comprehensive [backend handoff](../../2026-10-16/ch06-backend-validation/ENGINEERING_HANDOFF.md) supplies schema, harness and target details. Its partial-restore/pending-R05 statements are historical and superseded by the successful retry and approval here. Do not overwrite that record.

## Runtime and files

Workspace `D:/LLM-Data/Claude-Desktop/claude-code/shelflife`; branch main at `f56d5068e94cf80819f55be952a95769ad508c97` at latest recorded Git inspection. No stage, commit, push, branch or application/migration source edit in this validation chapter. Inherited tracked edits and untracked source remain; do not reset/clean.

Disposable project/network `shelflife-ch06-validation`; db/auth/rest/inbucket/kong containers. Explicit host bindings: API55321, DB55322, mail55324 at 127.0.0.1. Three stopped `_binding_backup` containers retain wildcard definitions; NEVER start them, especially the old db sharing the active target volume. Do not invoke a fresh CLI start that could replace verified bindings. Existing product Supabase, Onyx and Windows PostgreSQL are outside validation ownership.

Current engine API pipe is absent; current individual container states cannot be queried. The target's last known data is the successful restored baseline plus setup migrations and synthetic Chrome fixtures/edits. It is NOT the earlier partial failed restore. No database operation ran October 19 because the engine was unavailable. Existing service restart policies may resume unrelated containers if Desktop starts; inspect inventory without altering them.

Build output `.cache/ch06-validation/web/`, server script `product/supabase/tests/backend-validation/serve-web.mjs` (127.0.0.1:8136 only), new fixture script `browser-fixtures.mjs`. Do not rerun fixtures unnecessarily: first attempt left synthetic accounts/partial fixtures; successful second attempt is saved privately. The build uses actual `app_flutter/lib/main.dart`, not preview. Final build used absolute output/defines paths, `--release --no-pub --no-web-resources-cdn --pwa-strategy=none --no-wasm-dry-run`. First missing-defines and second relative shader-output failures are preserved; no dependency install or application fix.

Installed cached Playwright path: `D:/LLM-Data/npm-cache/_npx/9833c18b2d85bc59/node_modules/playwright` (CommonJS works; bundled ESM import failed). Installed Chrome path `C:/Program Files/Google/Chrome/Application/chrome.exe`. Isolated headless Chrome 155.0.8059.79 on October16, 155.0.8059.80 on October19. Docker startup log now identifies Desktop4.95.0; earlier runtime was4.93.0. No upgrade was performed by this chapter. Test Chrome and dedicated server were closed after interruption.

## Evidence and caveats

[Evidence index](EVIDENCE.md) links successful restore, build and browser groups. Chrome accessibility enabled via the observed `Enable accessibility` placeholder's click event. Flutter semantics inputs can be empty after blur although canvas text remains; use rendered text and actual RPC responses to verify edits. Rapid fill/focus sequences initially missed numeric/first-character input; slower keyboard input after focus rendering succeeded. This is a harness synchronization limitation, not a demonstrated application defect. A transient browser REPL timeout on October19 reset the kernel; the narrow login checks were repeated in a fresh browser.

Five durable October16 groups passed. All six setup pages were visited, and explicit unused markdown policy saved; no durable activation success exists. Library changes correctly invalidated readiness, showing reload/save required before activation. Resume there. Narrow login looked correct; narrow authenticated screens remain unknown. Backend-unavailable Auth produces generic “Sign-in failed. Check your details and try again.” It stays safe at login, but connectivity-specific wording is a UX limitation to assess during resumed recovery testing.

No full S1 end-to-end acceptance, idle-lock acceptance or physical-device claim. Earlier SQL/concurrency/API/DTO/restart results are historical and do not replace GUI completion.

## Private preservation and rollback

Keep `.cache/ch06-validation/private/` ignored. `status.json`, `web-defines.json`, `browser-accounts.json`, `browser-accounts-attempt01.json` and `browser-fixtures.json` contain keys/account data; never print or commit them. Fixture record includes primary/other org IDs and inventory baseline. Access synthetic accounts from this file at execution time; no credentials belong in handoffs.

Both original dumps rehashed October19:

- `before-setup.dump`: `587CE15FBBD00FA7FDA99C953E691F1926C628283A285D2073E7ECABC0D73B83`.
- `tested-20261016.dump`: `DB70BC336DDF52C677D76B360A0DCE1FE07E9D3688B1BC2B6DA7B25012D3A915`.

Baseline restore using existing supabase_admin has been demonstrated. Preserve current browser test state in a new private dump before eventual cleanup; do not overwrite earlier dumps. Browser fixture cleanup is not yet done because Docker is unavailable. No hosted rollback applies. Socket rename failed, so no new renamed endpoint exists to restore. Do not delete sockets, change ACLs, reset/prune Docker/WSL, or restore one socket over another.

## Exact next steps

1. Obtain approval for the concrete administrator-mode Docker launch request. Launch only the installed app with Windows UAC; stop if UAC is declined or startup fails. No automatic further repair. Inspect engine/container inventory and explicit target loopback mappings before testing.
2. Resume the existing five target containers, preserving stopped backups. Start localhost8136 using the existing built bundle and script. Use a fresh isolated Chrome context and private synthetic admin credentials. Select primary org branch A1; verify revision/data from existing browser fixtures.
3. Reload saved draft to refresh readiness after library edits. Review/confirm activation with reason and verify immutable active snapshot/audit. Validate two isolated admin sessions' stale revision conflict, explicit discard/reload, retry after dropped response and offline denial/recovery.
4. Validate viewer/staff rejection, other-org identity isolation, sign-out/switch, page/session restart, background concealment and five-minute idle lock. Check narrow authenticated layouts, keyboard focus/labels/scrolling. Preserve sanitized screenshots and exact evidence; compare all six inventory fingerprints with private fixture baseline. Scoped S1 defects may be fixed under R05, with affected tests and revalidation.
5. Back up final synthetic state, perform approved cleanup with new evidence, stop only dedicated server/containers. At verified checkpoint update final dated summary/handoff and mutable navigation. Create exactly ONE fresh bounded continuation, no fork/transcript copy, with source title/ID, paths, scope/approvals and verbatim mandatory start gate. Do not begin work in that new chat without explicit human approval there. Do not archive this chat.
