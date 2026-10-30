# R05 preparation observations

Approved by the human's “approving both” in Chapter 06; see [receipt](../ch06-restore-retry/APPROVAL_RECEIPT.md).

Restore retry passed with the existing supabase_admin account, clean five-migration/zero-users/zero-organisations baseline verified; setup migrations reapplied and transaction suite passed with ROLLBACK. Target stopped, then five explicit services restarted for R05. Published ports 55321/55322/55324 verified at 127.0.0.1.

Browser fixture attempt 01 failed because the staff profile lacked the existing required PIN-hash field. This was a harness error; the existing backend constraint correctly rejected it. Added the same non-login synthetic placeholder used by the earlier API fixture. Partial synthetic fixtures are retained until final target cleanup. No application/schema change.

The first build invocation did not compile because the failed fixture preparation had not written the private build defines. BUILD_ATTEMPT_01.log is preserved; build rerun follows successful preparation. The installed Flutter tool displayed an update notice; no upgrade or dependency installation was requested.

Build attempt 02 compiled Dart but failed shader asset packaging: impellerc could not write the supplied relative output path. The next attempt uses the same isolated directory as an absolute path. BUILD_ATTEMPT_02.log retains the failure; no application code change was made for it.

The bundled Playwright module's ESM entry failed to import; the existing npm-cache Playwright 1.64.0-alpha-1790635538000 CommonJS module launched installed Chrome 155.0.8059.79 successfully. No installation occurred. Chrome is headless with isolated contexts; browser-visible layout and interaction checks do not establish physical-device or OS screen-reader behavior. Browser requests are restricted to localhost by the test harness, and only sanitized paths/statuses are retained from API traffic.
