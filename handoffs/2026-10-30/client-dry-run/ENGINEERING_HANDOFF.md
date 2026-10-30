# Engineering handoff — client dry run, local readiness checkpoint

Date: 30 October 2026 Australia/Perth. Source chat **ShelfLife — Receiving Foundation Connected…**, ID `01a18027-683a-7043-b764-5939d2330ee2`, [audit record](codex://threads/01a18027-683a-7043-b764-5939d2330ee2). This is still the owning chat; no continuation was created.

## Objective and approved boundaries

Human explicitly paused backend work, requested hosting on Vercel or Netlify to see the tangible app, selected admin/staff evaluation, and confirmed clients must remotely test and dry-run it. The agreed intermediate architecture is an isolated synthetic browser demo using actual existing screens. The user identified Vercel/GitHub/Supabase account email cmzoilot@gmail.com. No Supabase or GitHub operation is needed for this static build.

Vercel connection was restored and new workspace consent now succeeds. The user confirmed Hobby; Netlify Free is proposed because Vercel Hobby is personal/non-commercial. No Netlify account/team or publication is verified/approved yet. See PUBLICATION_PACKET.md. This local checkpoint does not fulfill the remote-access goal or end the chapter. Backend remains paused; do not infer resumption from preview or chapter approvals.

## Implementation

- Separate entry `app_flutter/lib/client_demo.dart`; no Supabase initialization. Original production source preserved.
- `lib/client_demo/seed.dart`: twenty catalog products, valid demo setup, branch/locations/preset, stable synthetic IDs.
- `demo_state.dart`: localStorage JSON with revision, active configuration, audit/idempotency records and a public-practice identity key; save must complete before acknowledging success. Damaged state is retained rather than silently reseeded.
- `demo_setup_repository.dart`: actual SetupRepository contract, existing validation, save/activate/version conflicts, locations/presets, persisted practice state.
- `demo_identity_repository.dart`: public Alex2468/Sam1357 practice identities, separate local encrypted-draft vaults; no real account security claim.
- `demo_receiving_repository.dart`: catalog and activated policy contracts; later draft edits do not replace the activated policy. Stock confirmation stays false.
- `demo_platform_web.dart` and conditional stub/export: isolated localStorage key `shelflife.client-dry-run.v1`; IndexedDB `shelflife_client_dry_run_drafts_v1`; Web Lock `shelflife-client-dry-run-v1` prevents competing tabs. Reset clears this demo's four draft/cache stores, then removes demo settings. No unrelated site data is cleared.
- `demo_app.dart`: welcome, guide, catalog, reset and role navigation around existing SetupScreen/PinScreen/DraftWorkspace/controllers. Demo-specific wrapper auto-selects the sample branch, keeps Back to demo reachable, and observes lifecycle/idle locks. Original production gates were not edited.
- `tools/client_demo/package.mjs`: static packaging, local CanvasKit, no service worker/source maps, noindex/no-store/CSP headers for both providers, standalone client guide.
- `serve.mjs`: release-only loopback server on8137, realpath containment check. Current owner record `.cache/client-dry-run/server-owner.json`, PID10488 at checkpoint. Previous server stopped between turns; restart succeeded. App-panel open was queued, not verified visible.
- `browser-test.mjs`: installed Playwright + Chrome headless, temporary browser contexts, timestamped evidence, eight groups; optional `DEMO_TEST_URL` defaults to loopback.

The released UI intentionally describes simulation and gaps. Public PINs, per-browser state, no shared stock, no dedicated expiry field and no inventory confirmation are material limits. Printed expiry can be recorded in Notes for this evaluation only. Existing screen copy may refer to online verification; the persistent practice banner and guide clarify that verification is simulated here.

## Source and tests

Workspace `D:\LLM-Data\Claude-Desktop\claude-code\shelflife`; main HEAD remains `f56d5068e94cf80819f55be952a95769ad508c97` historically, no commits/push/branch change this work. Extensive inherited dirty work remains. Forty-six preserved Chapter09 file hashes match freshly. New files live only under client_demo entry/directory, test/client_demo, tools/client_demo, new design/plan and this handoff; navigation docs updated in place as allowed.

Ten focused adapter cases and clean targeted analysis; release web build succeeded; eight final browser groups pass with zero page errors/external requests. See EVIDENCE.md and exact reports. Final browser run `browser-2026-10-29T20-44-31-105Z` is UTC-named but occurred October30 Perth. Earlier failures are retained test development history. Reopened field values are asserted in the final run; preliminary four-group report was insufficient.

Artifact `.cache/client-dry-run/release`, zipped in this folder. SHA256 and file hashes in ZIP_CHECK/RELEASE_MANIFEST. Final packaging removed generated `.last_build_id`; compiled app bytes did not change after the passing browser run. No external upload occurred.

## Exact next steps

1. Present CLIENT_GUIDE, screenshots and concrete PUBLICATION_PACKET to the human. Obtain exact Netlify publication/client-access approval and intended account access; browser control currently disabled and no connector found. Do not buy/upgrade a plan.
2. Verify selected Netlify account/team, confirm a free site and name availability. If target differs from approved scope, resolve the difference before creation. Upload only verified release contents, publish, and record IDs/URL/actual headers.
3. Run fresh anonymous remote client browser checks with `DEMO_TEST_URL` set to the actual HTTPS URL. This is separately action-approved connected verification; no backend mutation. Confirm client guide and assets load from hosting origin and no platform sign-in is needed.
4. Add a dated numbered publication addendum instead of replacing this preserved checkpoint. Update implementation plan, ledger, index and stable pointer with actual evidence and limitations.
5. Keep connected publish/test sequence here. Only after the requested checkpoint and explicit transition authority is reconciled should ONE fresh continuation be considered; new-chat mandatory start gate applies. No duplicate, fork, archival or unattended chain.

## Rollback / unresolved backend

Local rollback is stop the owned preview server after verifying its exact owner record, then remove only new demo entry/adapters/tests/tools/generated bundle if requested. Preserve all inherited uncommitted files and prior handoffs. Local Reset is already tested and changes demo browser storage only. If keeping the preview open for the user, report that the local server remains listening on loopback.

Remote rollback is pending actual site/deploy IDs and authorization; do not claim tested unpublication. The prior Chapter10 database state is UNKNOWN, final baseline restore outstanding, approved SQL repair saved/unapplied. Original runbook: `handoffs/2026-10-29/ch10-connected-validation-resume/ROLLBACK_AND_NEXT_STEPS.md`. This preview performed no Docker/DB/Auth inspection, mutation, startup or restoration, and does not waive those pending obligations. No real authentication/stock/shared inventory acceptance follows from these local demo tests.
