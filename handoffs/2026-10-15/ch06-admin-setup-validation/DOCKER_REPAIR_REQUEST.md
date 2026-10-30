# Scoped Docker startup repair — approval request

Status: REQUESTED, NOT APPROVED. Date: 2026-10-15 Australia/Perth.
Owner: [ShelfLife — Admin Setup Backend and Application Validation](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a).

## Problem

The approved Docker launch failed because the backend could not rename its local `sailor-ingest.sock` runtime socket. [Execution evidence](EXECUTION_01.md). Docker's engine is unavailable; no validation database exists. A stale or inaccessible socket is the immediate symptom; its underlying cause is not yet proven.

## Requested action

Approve **“Scoped Docker startup repair”** to authorize:

1. Gracefully stop Docker Desktop with its supported `docker desktop stop --timeout 30` command. This is a Docker-wide Desktop operation and could interrupt any other Docker workloads if the engine has recovered; inspect engine/container state first and stop for confirmation if unrelated running workloads are discovered. Do not force-kill or globally stop WSL.
2. Confirm Desktop/backend processes have exited. Inspect only the failed endpoint and its direct parent directory. If processes remain or ownership is unclear, stop and report instead of escalating to force termination.
3. If the socket remains, attempt to rename ONLY `C:/Users/CMs_Automation/AppData/Local/Docker/run/sailor-ingest.sock` to a unique sibling `sailor-ingest.sock.ch06-20261015-backup`. Confirm exact absolute paths, ensure destination is absent, and act on the endpoint itself without traversing its reparse target. Do not recursively move/remove the directory. This is a transient runtime socket, not a container volume or credential file. If safe endpoint-only handling cannot be established or the rename is denied, stop and report; deletion, ACL edits and reset are not included.
4. Launch the existing Docker Desktop again in the background. Check engine health and immediately inspect resource inventory. If it starts, resume already-approved R03/R06 validation within its original target boundaries. If the same failure persists or a different repair is needed, stop and report.

No Docker reinstall/upgrade, factory reset, disk/volume/image deletion, WSL shutdown/reinstall, reboot, credential changes, host-network changes or permissions changes are authorized by this request. Existing PostgreSQL remains untouched. No browser/device test is included.

## Preservation and rollback

Keep any renamed socket endpoint until the engine result is known; do not replace a new active socket with the old one. Record exact actions and results. If restoration is needed, stop Desktop gracefully and restore the original filename only when no replacement endpoint exists and ownership is clear. Do not restore over a live socket. No application/database rollback is needed: nothing has been applied.

## Why this needs approval

The [approved R03/R06 packet](R03_R06_APPROVAL_REQUEST.md) says: “If startup needs installation, configuration changes, privilege changes or repairing unrelated resources, stop and request the specific action.” This repair touches Docker's shared runtime state outside the isolated validation directory. Human approval is required by that bounded request; no automatic approval-review rejection occurred.
