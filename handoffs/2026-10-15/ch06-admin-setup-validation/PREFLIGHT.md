# Chapter 06 read-only preflight — 2026-10-15

Owner: **ShelfLife — Admin Setup Backend and Application Validation**, [chat](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a), ID `01a13ce2-a8fe-7063-8867-260412dd096a`.

This is an interim approval checkpoint, not completion of backend/application validation. Exact command outputs and human input remain in the owning chat.

## Authorization

Human explicitly approved beginning this named chapter and requested its connected sequence remain here through a verified checkpoint. Read-only preflight and a concrete action request are authorized. The same message authorizes closeout and ONE fresh continuation at the eventual checkpoint, not immediately. R03/R05/R06 execution remains pending. Preserve this chat; no archive requested. Any future continuation retains the explicit in-chat start gate.

## Fresh observations

- Root checkout: `main`, HEAD `f56d5068e94cf80819f55be952a95769ad508c97`; inherited modified/untracked files remain. No staging, commits or application edits.
- Docker client 29.8.1 is installed at `C:/Program Files/Docker/Docker/resources/bin/docker.exe`; Docker Desktop launcher exists. Both default and desktop-linux engine probes failed with missing named pipes. Elevated read-only inspection confirmed those failures; no engine was started. Docker service reports Stopped. Container/image inventory is UNKNOWN while the engine is unavailable.
- PostgreSQL service `postgresql-x64-17` reports Running; installed pg_ctl reports 17.0. No connection was made to it, and no service changes occurred. Its databases and purpose are unknown and excluded.
- No Supabase executable was found on PATH or in the specifically checked standard npm/cache binary locations. This is not an exhaustive disk inventory. Repository `.temp/cli-latest` contains `v2.118.0`; it is a cached marker, not installed-binary evidence. Official release existence was independently checked.
- Node/npm and Flutter/Dart launchers are on PATH; no application tests, dependency installs or builds were run in this chapter.
- Initial sandbox Docker configuration and network-listener inspection were denied. Scoped elevated read-only probes succeeded for context/port inspection. Listener query returned zero entries in proposed TCP range 55320–55329. Recheck before use; availability can change.
- Repository Supabase config identifies project `product`, PostgreSQL major 17, default local ports and automatic seed loading. It also enables unrelated services. Reusing that target/config directly is not proposed. No secret/start-secret files or credentials were read.
- Seven migration filenames are present. Supplier enum addition and its dependent migration must remain separate transactions. Source depends on Supabase auth schema/functions and role grants; vanilla PostgreSQL alone would not establish real auth/API correctness.

## Evidence limits

No database created, started, migrated, seeded, reset or tested. No API request, auth account provisioning, browser/device test, production/hosted inspection or deployment occurred. SQL remains UNEXECUTED. Chapter 05's 74 local cases and clean analysis are historical evidence, not rerun results here. Port inspection proves only current listener absence, not successful binding or future isolation.

## References

- [Incoming engineering handoff](../ch05-admin-setup-foundation/ENGINEERING_HANDOFF.md)
- [Acceptance procedures](../../../docs/testing/admin-setup-acceptance.md)
- [Concrete action request](R03_R06_APPROVAL_REQUEST.md)
- [Official CLI v2.118.0 release](https://github.com/supabase/cli/releases/tag/v2.118.0)
- [Official local development documentation](https://supabase.com/docs/guides/local-development/cli/getting-started)

Context7 also supplied current CLI documentation. Current develop documentation is not proof of the pinned binary's behavior; check its help/config support after approved acquisition, before any start.
