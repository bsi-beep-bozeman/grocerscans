# Evidence — local source checkpoint

Date: 2026-10-15 Australia/Perth. Original command/review/approval output: [owning chat](codex://threads/01a12f57-0cf7-7fa0-8e2a-542b48d3985d). This packet supersedes only current status; all October 12–14 source records remain historical.

## Fresh execution

Working directory for Dart/Flutter commands: `D:/LLM-Data/Claude-Desktop/claude-code/shelflife/app_flutter`.
Installed runner: `D:/dev/flutter/bin/cache/dart-sdk/bin/dart.exe D:/dev/flutter/bin/cache/flutter_tools.snapshot`.
Existing runtime observed during this chapter: Flutter 3.47.5 / Dart 3.13.4. No packages installed or upgraded. Installed Supabase Flutter 2.17.2 API source was checked rather than assuming current online examples.

| Check | Result | Retained output |
|---|---|---|
| `--no-version-check test --no-pub --concurrency=1 --reporter expanded test/setup test/widget_test.dart` | Exit 0, 73/73 before the final additional accessibility test was authored | [FLUTTER_TESTS_FINAL.txt](FLUTTER_TESTS_FINAL.txt) |
| `--no-version-check test --no-pub test/setup/setup_accessibility_test.dart` | Exit 0, 1/1; keyboard Tab from store to country, semantic label, save target >=56px | [ACCESSIBILITY_TEST.txt](ACCESSIBILITY_TEST.txt) |
| `--no-version-check analyze --no-pub` after all source/test changes | Exit 0, no issues | [FLUTTER_ANALYZE.txt](FLUTTER_ANALYZE.txt) |
| Direct Dart `demo-data/validate_catalog.dart` | Exit 0, 20 unique checksum-valid UPCs; CSV parity, SKU/EAN/legacy lookup, totals | [DEMO_DATA_CHECK.txt](DEMO_DATA_CHECK.txt) |
| Combined run with `--dart-define=CAPTURE_SETUP=true` | Exit 0, 73/73; actual fixture image capture | [FLUTTER_TESTS.txt](FLUTTER_TESTS.txt), [390px](setup-390.png), [1440px](setup-1440.png) |
| `git diff --check` | Exit 0; line-ending notices only | Original chat output; [tracked owned diff](OWNED_TRACKED_DIFF.patch) |

The 74 passing cases comprise 30 contract/validator tests, 9 controller tests, 8 adapter tests, 4 review/path regressions, 16 functional/layout screen tests, 1 session-gate test (multiple lifecycle/person-switch cases), 2 visual fixture tests, 1 accessibility case and 3 inherited preview regressions. Widget layout cases include 390/1440 widths at 200% text. No screen-reader/device certification is implied.

## Failures found and repaired

Contract review found missing authoritative readiness response handling, inconsistent nested domain error paths and fractional each-source transformation readiness. Regression tests and source fixes address each. Populated readiness round-trips now cover values/origins/reasons/action states.

Controller and adapter tests were authored before their implementations; first runs failed because those implementations were missing. A focused envelope/path test failed on plain FormatException before its repair. A background sign-in test and a rapid A→B identity replacement test each reproduced a real dialog/session bug before fixes. Final gate test passes both.

SQL review found separate reads of active version and pointer revision could yield a mismatched response during activation. The source now uses one scoped joined SELECT. Static re-review approved; the concurrency procedure is still unexecuted.

UI review found discarded text survived reload, editing presets cleared descriptions, and incomplete setup displayed ready. Accepted-load form generations, explicit description replacement/omission, and readiness-based text fix these. Expanded functional tests cover actual mutation envelopes, revisions/reasons, category versions, override removal, explicit activation, invalid quantities and visible reload restoration. All reviewed consequential findings were resolved in read-only re-review.

Early whole-app analysis reported style issues; the retained [initial final-pass analysis](FLUTTER_ANALYZE_INITIAL.txt) records the last two before cleanup. Additional accessibility test initially had a wrong finder property and late fixture disposal; both harness errors were repaired before the passing result. Earlier interrupted subagents reported exhausted workspace credits; saved work was resumed/reviewed, not presumed complete.

## Integrity and limits

[SOURCE_HASHES.json](SOURCE_HASHES.json) identifies authored source/test files. [BASELINE_COMPARISON.json](BASELINE_COMPARISON.json) compares the October 13 eight-file baseline: only main/login changed; supa, preview catalog/cockpit, inherited preview tests, pubspec and lockfile match. [HEAD.txt](HEAD.txt), [BRANCH.txt](BRANCH.txt), [GIT_STATUS_AFTER.txt](GIT_STATUS_AFTER.txt) retain checkout identity/dirt. No commit/staging/push was performed.

SQL compilation, SQL assertions, actual RPC responses, RLS/authorization, transaction rollback, concurrent writers and real auth/expiry persistence remain **UNEXECUTED**. Existing tests inject local repositories/RPCs and cannot prove backend behavior. No local/hosted backend creation, migration application, networked test, Android/web session, release build or publication occurred. Screenshots contain fixture timestamps and sample names, not real saved records. Hosted preview was not updated.
