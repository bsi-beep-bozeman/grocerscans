# R03/R06 execution attempt 01 — 2026-10-15

Owner: [ShelfLife — Admin Setup Backend and Application Validation](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a). [Human approval](APPROVAL_RECEIPT.md). This is an interim execution record, not a completed validation chapter.

## Completed work

- Created the previously absent, ignored `.cache/ch06-validation/` work directory with tools/private/supabase subdirectories. No database or Docker resources were created by validation commands.
- Captured seven migration SHA-256 hashes in `SOURCE_HASHES_BEFORE.json` before execution.
- Downloaded the official Supabase v2.118.0 Windows amd64 ZIP and published checksums. Archive SHA-256 matches the published checksum: `E8EB5871B2A9E9B496D19F3FCA4851D0C2A1BB8059613692D8906B5DC5FC2AAD`.
- Extracted locally without global installation or PATH changes. Executable reports `2.118.0`. Primary executable SHA-256: `2EA6E55E4856A5AF7F7CCF226551573B51D65B024646235A2A7B753EE68944D9`; bundled Go executable: `9EC9E65782D397E5EB547CF068423221C5A0B3B0AF28FD235C8FFD3A5FE67602`. See `TOOL_MANIFEST.json` for retained machine-readable evidence.
- Read pinned help and selected official pinned-source networking implementation. No `supabase start`, init, login, link, migrations, seed, test or status command was run. The source's published ports lack an explicit IP in their generated mappings; loopback-only binding still needs confirmation before any backend creation. An isolated Docker network with a loopback default may be an option, but is not verified or created.
- Launched installed Docker Desktop in the background under approved R03. Desktop/backend processes started but the engine exited during initialization. Engine probes failed with missing `dockerDesktopLinuxEngine` named pipe. Container/image/volume inventory therefore remains unknown; no runtime images were pulled by validation commands.

## Fresh failure evidence

Docker backend log at `2026-10-15T10:29:00.383986900Z` (18:29 Perth) reports:

> backend cancelling with error: starting services: initializing Ingest server: listening on unix://<HOME>/AppData/Local/Docker/run/sailor-ingest.sock: rename <HOME>/AppData/Local/Docker/run/sailor-ingest.sock <HOME>/AppData/Local/Docker/run/sailor-ingest.sock.stale: The file cannot be accessed by the system. (listener: The file cannot be accessed by the system.)

At `10:29:04.287535400Z` it records backend crash with the same reason. Subsequent engine probes remain unavailable. This directly establishes the startup failure, not its underlying filesystem cause. There is no evidence connecting it to the changed Codex account.

Read-only metadata: `C:/Users/CMs_Automation/AppData/Local/Docker/run/sailor-ingest.sock` exists, length 0, attributes 1056, creation/write time 18:22:59 Perth; `.stale` counterpart is absent. No socket was renamed/deleted and no Docker settings/credentials were changed by us. Desktop's own startup handling logged termination of lingering WSL processes; we issued no process-kill or WSL shutdown commands. Some Desktop logs show engine activity earlier at 18:23; this is historical log evidence, not proof of a currently reachable engine.

Existing PostgreSQL service remains Running. It has not been connected to or modified.

## Stop boundary and remaining work

The approved request explicitly requires stopping if Docker startup needs configuration/privilege changes or repair of unrelated resources. The failing socket lies in Docker's shared runtime directory outside the disposable target. [Scoped repair request](DOCKER_REPAIR_REQUEST.md) is prepared; repair has not run. This is a scope gate, not an automatic approval-review rejection.

R03 remains approved but unable to proceed until the engine works. R06 is partially complete: CLI acquired and verified; runtime images not obtained. All SQL/API/auth/concurrency/persistence/DTO checks remain NOT RUN. R05 application/browser/device testing remains separately unapproved. No source corrections, commits, deployment or continuation chat.

## Preservation and exact next steps

Keep tool artifacts in the ignored work directory; no cleanup required now. Preserve original migration source and inherited checkout changes. After repair approval: perform only the bounded repair, verify Docker identity/inventory and project-name absence, verify isolated loopback networking, prepare the isolated config, and resume the originally approved R03/R06 sequence. Do not broaden permissions or reset existing Docker/PostgreSQL state to make progress.

If repair is declined or fails within scope, retain this chapter and report the specific blocker. Do not claim a backend checkpoint or consume the eventual continuation authorization.
