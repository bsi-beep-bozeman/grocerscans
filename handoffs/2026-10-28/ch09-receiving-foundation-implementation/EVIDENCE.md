# Chapter09 evidence and limitations

2026-10-28 Australia/Perth. Original tool output remains in [source chat](codex://threads/01a17a46-3ec8-7893-adca-9d41ab4e1960). This file summarizes evidence, not a substitute transcript.

## Fresh checks

| Check | Result / evidence |
|---|---|
| Offline tests | `flutter test --no-pub --coverage test/identity test/sync test/receiving test/setup test/widget_test.dart`: **121 passed**, exit 0. `FINAL_LOCAL_TESTS.txt`. 47 foundation + 74 pre-existing setup/preview cases; no connected backend/browser/device. |
| Static analysis | `flutter analyze --no-pub`: **No issues found**, exit 0. `FINAL_ANALYSIS.txt`. This analyzes source, including conditional platform files; it does not build or run their platform behavior. |
| Formatting | `dart format --output=none --set-exit-if-changed` on the three new lib/test groups, main and synthetic storage harness: **33 files, 0 changed**, exit 0. `FINAL_FORMAT.txt`. |
| Coverage | `FINAL_COVERAGE.json`: 1,071 hit / 1,256 instrumented foundation lines =85.27%. Controller 62/62; crypto101/104; policy225/230; workspace287/335; recovery54/59. Android adapter0/79. Web adapters/lifecycle, Supabase routing and RPC wrappers not represented by this loaded-test report. Not whole-feature or SQL coverage. |
| Dependency resolution | `PUB_GET.txt`, `DEPENDENCY_REVIEW.json`, `check-dependencies.ps1`: exact requested direct pins resolved, nine packages added; 80 existing versions/archive hashes unchanged. Public registry hash and cached license checks recorded. Ten public OSV package/version results returned empty advisory matches; no assertion of zero vulnerabilities. |
| Preservation | `PRESERVATION_BASELINE.json` records66 pre-work hashes. `BASELINE_CHANGES.json` captures five expected source/generated changes before doc updates. `FINAL_PRESERVATION.json` captures final approved differences and57 unaffected hashes, including seven unchanged pre-existing migrations. |
| Source hygiene | Git diff whitespace check passed; final manifest and status record source state. No stage/commit/push/merge. The ignored generated Android plugin registrant includes the new SqflitePlugin; no manual SDK upgrade. |

Flutter commands used the existing `D:/dev/flutter/bin/cache/dart-sdk/bin/dart.exe` and `D:/dev/flutter/bin/cache/flutter_tools.snapshot`, from app_flutter, with approved cache access. SDK metadata identifies Flutter3.47.5/Dart3.13.4; no separate fresh version-command claim. The launcher initially waited on a cache lock and was cancelled; direct installed snapshot dependency resolution then succeeded. No SDK update was executed.

## Development findings and fixes

Test-first missing-implementation failures were recorded in RED logs. Development tests caught key destruction aliasing (fixed by copying temporary key material), root dialogs surviving nested navigation disposal (fixed by removing protected root modal routes), and catalog freshness being overwritten by save status (split independent statuses). Late lookup/policy results now require current input/edit generation. Final offline runs include these fixes. Intermediate analyzer diagnostics were resolved before the final clean analysis. Some GREEN log names were reused after a failing iteration; do not treat their final contents as preserved evidence of every earlier failure. Exact original outputs remain in the source chat.

`BOUNDARY_TESTS.txt` covers 28 identity/policy cases, `WORKSPACE_EXPANDED_GREEN.txt` seven workspace cases, and `RECOVERY_LOCAL.txt` four recovery cases; final combined output is authoritative. Saved state waits for fake commit completion; failure/corruption retains data and avoids a false success. Widget sizes390x844 and1440x1100 at200% text are synthetic layout tests, not browser/device accessibility certification.

## Not executed / no inference

No SQL harness, Python API concurrency runner, actual Auth call, migration application, effective ACL probe, backend startup, restore, Chrome run, web build, Android build/install/force-stop or native-storage harness was executed. SQL syntax and real platform durability are unknown. The four new package licenses/advisories were inspected, but no whole dependency-source security audit was performed. No production key-management decision, public deployment or release exists.

Documentation validation and the continuation receipt are recorded separately after the local source checkpoint. Previous dated packets remain immutable; Chapter08's pre-creation receipt is corrected only by the new addendum in this folder.
