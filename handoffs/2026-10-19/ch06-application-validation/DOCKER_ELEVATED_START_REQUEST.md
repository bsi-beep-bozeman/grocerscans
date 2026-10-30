# Request — one administrator-mode Docker startup

Status: PROPOSED, NOT APPROVED OR EXECUTED. Source: [Chapter 06](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a).

Approve **“One administrator-mode Docker startup”** to permit this bounded diagnostic attempt:

1. Recheck that Docker Desktop/backend processes are absent and the engine is unavailable. If an engine has recovered, inspect inventory instead of launching another instance or stopping workloads.
2. Launch only the existing `C:/Program Files/Docker/Docker/Docker Desktop.exe` once using Windows `RunAs`. Windows will prompt the human for UAC approval. This grants the application an elevated session; it does not change stored credentials or filesystem ACLs. Docker may resume existing containers according to their existing restart policies.
3. Check engine availability and target inventory. If it succeeds, resume already-approved R05 only after validating exact localhost bindings. Do not touch unrelated product/Onyx data or PostgreSQL.
4. If UAC is declined or the same/different startup failure remains, stop and report. No further repair is included.

Exact proposed launch:

```powershell
Start-Process -FilePath 'C:/Program Files/Docker/Docker/Docker Desktop.exe' -Verb RunAs -WindowStyle Hidden
```

This is a diagnostic attempt because the error concerns Windows access to an existing runtime endpoint; it is not a proven fix. No file/socket deletion, ACL/ownership edits, reinstall/upgrade, factory reset, volume/image removal, WSL shutdown or reboot is authorized. It may still require a different repair; that would need its own reviewable request.

Why approval: the human-approved [scoped repair packet](../../2026-10-15/ch06-admin-setup-validation/DOCKER_REPAIR_REQUEST.md) explicitly says **“If safe endpoint-only handling cannot be established or the rename is denied, stop and report; deletion, ACL edits and reset are not included.”** The rename failed, and administrator-mode launch is a new privilege scope. Automatic approval review did not reject the rename; Windows itself returned the error.
