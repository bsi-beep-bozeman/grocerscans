# Chapter 06 — interrupted application validation

2026-10-19 Australia/Perth. Owner: **[ShelfLife — Admin Setup Backend and Application Validation](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a)**, ID `01a13ce2-a8fe-7063-8867-260412dd096a`. Chapter remains OPEN; no continuation created.

The human approved both the restore retry and R05 local Chrome validation. The restore retry succeeded: five original migrations, zero organisations/users and no setup table were verified, then both setup migrations reapplied and the transaction suite passed with ROLLBACK. This supersedes the October 16 interim failed-restore state; the original failure record remains unchanged.

The actual Flutter web application built successfully using installed dependencies, local renderer assets and explicit disposable-backend settings. Five Chrome groups passed October 16: real Auth/SDK admin sign-in; draft save/reload and unsaved cancel/discard; units/product packs; location create/rename/deactivate; preset duplicate/version/edit/deactivate. All six setup pages were inspected; an explicit unused action was saved, but activation was not executed. Earlier backend SQL, 19 concurrency groups, 23 API groups, 61 DTO decodes and restart evidence remains valid historical evidence.

On October 19 Docker startup failed again at `sailor-ingest.sock`. Its processes exited. The previously approved single-endpoint rename failed with Windows error “The file cannot be accessed by the system”; no backup rename occurred. The repair packet explicitly requires stopping after a denied rename. No deletion, ACL change, factory reset or reinstall was attempted. This is a local runtime-endpoint failure; the evidence does not implicate the user's changed Codex account.

Fresh independent Chrome checks verified the 390px login layout, required fields, and that backend-unavailable sign-in stays at login with a generic failure message. Connected activation/conflict/recovery/locking and narrow authenticated layouts remain incomplete. No application source change was made. Test browser and localhost application server were closed; the backend engine remains unavailable. Both saved dump hashes were rechecked successfully.

[Engineering handoff](ENGINEERING_HANDOFF.md) · [Evidence](EVIDENCE.md) · [Specific next action request](DOCKER_ELEVATED_START_REQUEST.md).
