# Recovery and authority — October 26

Source: **ShelfLife — Admin Setup Backend and Application Validation**, ID `01a13ce2-a8fe-7063-8867-260412dd096a`, [original chat](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a). The desktop thread tool currently displays the shortened title “ShelfLife — Admin Setup Backend and…”. The full title above is the source chapter opening and human-approved scope.

The human first approved one administrator-mode Docker startup. That launch was canceled by Windows before startup; the [original result](../ch06-docker-elevated-start/RESULT.md) remains unchanged. The human then said **“Retry once”**. Before launching, a read-only preflight found Docker already running and responding with engine version 29.9.2. No second RunAs invocation was needed or performed. The cause of recovery is unknown; this is not evidence that the canceled launch repaired Docker. No credentials, ACLs or service permissions were changed.

The five existing validation services were running. Actual bindings remained 127.0.0.1:55321 (API), :55322 (database) and :55324 (mail). Three binding-backup containers remained stopped. The application server used 127.0.0.1:8136. Existing product Supabase, Onyx and other shared Docker workloads were observed and excluded from changes.

Existing authority was resumed, not expanded: the named chapter start, R03/R06, the corrected restore retry and R05 local Chrome request were explicitly approved earlier. “approving both” covers the [restore and R05 receipt](../../2026-10-16/ch06-restore-retry/APPROVAL_RECEIPT.md). R05 authorizes the installed Chrome, isolated actual Flutter build, synthetic identities, browser checks, test backup and target-only cleanup. The later “please continue from where you left off” resumes this same connected sequence. It is not authority for a new chapter to start.

The original chapter request authorizes closeout and exactly ONE fresh continuation at the verified checkpoint. The current standing instructions require human start approval in that new chat. No R04 hosted change, R07 commit/push/merge, R08 publication/access change, R09 rollout, global Docker reset/prune, new credential or permission change is authorized. No source chat may be archived without human direction.

The separate report/GHL request authorizes local report packaging. It does not authorize publishing to GHL. The embedded-evidence edition is a local deliverable; GHL hosting remains unexecuted.
