# Admin Setup Foundation execution evidence

2026-10-13 (Australia/Perth). Work in progress; this is not a completed checkpoint.

Source: [ShelfLife — Admin Setup Foundation](codex://threads/01a12f57-0cf7-7fa0-8e2a-542b48d3985d). Human approved S1 source and one future chapter transition, then explicitly “Approve R02 local checks”. R03–R09 not granted.

## Baseline

- Root existing dirty checkout preserved; original status in GIT_STATUS_BEFORE.txt, eight selected inherited source hashes in BASELINE.json. Current records copied into prior-current-docs.
- Installed Flutter 3.47.5, Dart 3.13.4. Installed package paths identify supabase_flutter 2.17.2, supabase 2.16.1, gotrue 2.27.2 and postgrest 2.9.1.
- Normal sandbox baseline test could not open installed SDK cache lockfile. The same existing-dependency offline command was allowed via sandbox escalation; no dependency fetch.
- Command from app_flutter: installed dart.exe + existing flutter_tools.snapshot --no-version-check test --no-pub test/widget_test.dart. Result: all 3 existing preview tests passed, including 390x844 and 1440x1100 capture flows.
- This also supplies the previously missing local widget regression evidence for the twenty-product source. Hosted snapshot was not updated.

## API references

Context7 Supabase documentation consulted, then actual installed SDK source checked for version compatibility. Installed AuthState exposes event/session; latest main-branch documentation also describes a future sealed-state migration, which is not applied to this installed version. Supabase RPC uses fn + params, and auth.getUser performs the online user fetch.

Security-definer migration design uses the [PostgreSQL CREATE FUNCTION guidance](https://www.postgresql.org/docs/17/sql-createfunction.html) for fixed trusted search paths and selective execution grants. This is design/reference evidence, not database runtime verification.

## Pending evidence

Implementation tests, analysis, reviews, SQL runtime and device acceptance are not claimed here. Append actual results as they complete. No build/publication, hosted calls, fixture provisioning, migrations/grants application, commit, push or new chat has occurred at this point.
