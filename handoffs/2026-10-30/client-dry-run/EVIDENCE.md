# Evidence — 30 October 2026 (Australia/Perth)

## Fresh local verification

- `ADAPTER_TESTS.txt`: `flutter test --no-pub test/client_demo --reporter expanded`, ten tests passed, exit 0. A preceding restricted attempt produced no output and was stopped; it is not counted as a result.
- `ANALYSIS.txt`: `flutter analyze --no-pub lib/client_demo.dart lib/client_demo test/client_demo`, no issues, exit 0.
- Release build of `lib/client_demo.dart` succeeded in this source chat, 32.8 seconds, exit 0. Build output is `.cache/client-dry-run/web`; packaging consumes this entrypoint only. The build console receipt remains in the original chat, not a newly fabricated log.
- Definitive browser report: [eight passing groups](browser-2026-10-29T20-44-31-105Z/BROWSER_TEST.json). Chrome headless, desktop 1440×1000 and independent mobile viewport 390×844. Zero JavaScript page errors; zero external HTTP(S) origins attempted. The route guard aborts unexpected origins and the test fails if any occur.
- Screenshots in that same folder: welcome-desktop, admin-desktop, staff-desktop, staff-reopened, welcome-mobile, admin-mobile and staff-mobile. Welcome/admin/mobile staff images visually inspected in the source chat; forms and labels fit the tested widths and scroll vertically.
- `INHERITED_SOURCE_CHECK.json`: all 46 Chapter09 files match their preserved SHA256 values.
- `SOURCE_MANIFEST.json`: hashes of new preview source, tests and tools at this checkpoint.
- `RELEASE_MANIFEST.json`: 39 static files, 34,076,975 bytes. Includes local renderer/fonts, no source maps, service worker, environment file, repository or database backup. An old generated `.last_build_id` was removed before final packaging.
- `ZIP_CHECK.json`: checks every non-directory ZIP entry against the release SHA256 manifest. ZIP has 39 file entries plus 3 directory entries. All file hashes match.
- ZIP SHA256: `F0CBB9D1B03A8CF8C362CC1B02328B712B3D9464BCB5A493AED3B2F76604333C`.

Earlier browser folders/root report are retained exploratory evidence, not final acceptance. They include stopped-server failure and test-harness failures: synthetic fill events raced Flutter focus, saved-menu selection used text instead of menuitem semantics, and immediate value assertions raced field rendering. Final helper waits for focus, types through keyboard events, asserts field value, and waits for displayed saved values. No production screen was altered to make these tests pass. The earlier four-group report did not assert reopened field values; only the eight-group report above is definitive.

## Hosting observations

Vercel authenticated identity cmzoilot@gmail.com; workspace consent initially still returned 403, then the fresh user-approved consent succeeded. Team ID `team_nmy3g1G2kMxj1H8QjRWEUPLC`, name CM's projects, slug cms-projects-29ee8cba. Searching ShelfLife projects returned none. The human confirmed Hobby; the team's billing plan is not exposed by the connector response. [Vercel Hobby documentation](https://vercel.com/docs/plans/hobby) restricts non-commercial personal usage. [Netlify's Free announcement](https://www.netlify.com/blog/introducing-netlify-free-plan/) explicitly allows commercial projects; historical limits on that page are not treated as current quotas.

No remote upload/deployment/access change was made. Netlify plugin search returned no matching plugin; browser entry point reported local browser use disabled in Work settings. A local preview panel open was queued, not confirmed visible. Local server owner record reports PID 10488, loopback port 8137; no backend server was inspected or changed.

## Limits

Local Chrome only; mobile viewport is not physical-device testing. No remote availability, client-network, Safari, Android, accessibility certification, shared-data/authentication or full business-workflow acceptance. Public practice PINs are simulation, with local role partitioning only. Production database restoration remains pending from the older sequence and was not retried.
