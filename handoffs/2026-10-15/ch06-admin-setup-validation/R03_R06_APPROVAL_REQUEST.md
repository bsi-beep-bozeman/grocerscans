# R03 + R06 — proposed disposable backend validation

Status: **REQUESTED, NOT APPROVED OR EXECUTED**. Date: 2026-10-15 Australia/Perth.
Owner: [ShelfLife — Admin Setup Backend and Application Validation](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a).

Approve this packet with **“Approve R03 and R06 as documented.”** This authorizes only the actions and target below. It does not authorize browser/device validation, hosted changes, publication, commits/push/merge or rollout.

## Target and tooling

- Disposable local Supabase project ID: `shelflife-ch06-validation`.
- New isolated work directory: `D:/LLM-Data/Claude-Desktop/claude-code/shelflife/.cache/ch06-validation/`; Supabase files under its `supabase/` directory. Tools/downloads, transient credentials, fixtures and private backups stay under this ignored work directory. Durable sanitized evidence goes under this dated chapter folder. Existing `product/supabase` configuration, link metadata, seed and credentials are not copied.
- R06: obtain official Supabase CLI **v2.118.0 Windows amd64**, verifying its published checksum where supplied; record binary hash/version. Install locally in the isolated tools directory, without global PATH, registry or package-manifest changes. Download only the official local runtime images needed by that pinned CLI for PostgreSQL 17, Auth, PostgREST, API gateway and optional local email capture. Record exact image tags/digests before test execution. No other SDK, Docker upgrade, OS feature enablement or reboot is covered. Downloads may be several GB; exact cache state/size is unknown while Docker is stopped.
- R03: launch the already installed Docker Desktop in the background and use its Linux engine. Starting Docker can also resume unrelated containers with restart policies; inspect inventory immediately and leave unrelated resources untouched. If startup needs installation, configuration changes, privilege changes or repairing unrelated resources, stop and request the specific action.
- Host access must be loopback only. Proposed ports: API 55321, PostgreSQL 55322; reserve 55320 for shadow DB and 55324 for local email capture if necessary. Other ports 55323 and 55325–55329 remain unused. Disable Studio, storage, realtime, analytics, edge functions and pooler. Confirm pinned CLI supports the required isolation before starting. If loopback binding cannot be achieved without broader Docker/host changes, stop and request a revised plan; do not expose on LAN or silently switch ports.
- Before creation verify the project ID, resources, paths and ports do not belong to existing work. An unexpected preexisting target is a stop condition, not permission to adopt/reset it. No hosted project linkage or remote credentials.

## Migration and permissions boundary

Create a fresh empty target, capture baseline identity/version and migration state, then apply these exact source files in order, preserving migration transaction boundaries:

1. `product/supabase/migrations/20260924030000_init.sql`
2. `product/supabase/migrations/20260924030001_rls.sql`
3. `product/supabase/migrations/20260924030002_rpcs.sql`
4. `product/supabase/migrations/20260925000000_supplier_tier.sql`
5. `product/supabase/migrations/20260925000001_supplier_tier.sql`
6. `product/supabase/migrations/20261013000000_store_setup.sql`
7. `product/supabase/migrations/20261013000001_store_setup_api.sql`

Approval includes their grants, revokes, roles/policies and schema mutations **only in this disposable target**. Disable default repository seeding. Capture a restorable baseline after the five retained migrations and before the two setup migrations; keep private backups out of handoff documents. Record hashes and migration outputs. Do not wrap the supplier enum addition and its use in one transaction.

## Fixtures and connected tests

Use synthetic organisations A/B, branches A1/A2/B1, categories/products, locations/presets and disposable test identities only. Roles cover admin, inactive admin, staff, viewer, legacy manager, supplier and kiosk plus conflicting identities. The existing transaction suite's numbered UUID fixtures are scoped to this target. API accounts use reserved `example.invalid` addresses, fresh local-only passwords and locally issued sessions. No real email/SMS/OAuth providers or real stock/customer data. Do not record passwords/tokens in evidence.

Authorize test/harness authoring and execution for:

- SQL compilation/application and `product/supabase/tests/store_setup.sql` with stop-on-error and explicit rollback after failures.
- All seven multi-connection procedures in `docs/testing/admin-setup-acceptance.md`: competing saves/activations, exact retries versus changed requests, reference edits, cross-branch/org lock behavior, revocation/expiry while waiting, and consistent active version/revision reads. Include third connection for revocation, bounded waits and captured lock evidence.
- Actual local Auth sign-in/token and PostgREST calls to all six setup RPCs: permitted/denied roles, direct-table/helper restrictions, cross-org isolation, expired sessions, invalid payloads, returned errors, idempotency, lost-response retries, revisions and immutable history.
- Backend persistence across restart of this project's containers only. Compare inventory/receiving/round/alert/operational-audit row counts and deterministic row checksums before/after setup operations using synthetic sentinel data, not merely empty-table counts.
- Local harness parsing of actual RPC JSON and, where installed dependencies permit without downloading, Dart DTO contract checks. This covers a headless contract harness only. Launching the Flutter application in a browser or device still requires R05.
- Scoped corrections to the two new setup migrations, their SQL tests and validation harness when these tests reveal defects; preserve original hashes/diffs and rerun affected tests in the disposable target. Stop for approval if a fix requires changing retained migrations, unrelated application/domain behavior, new dependencies or a broader permission model.

## Backup, reset and cleanup boundary

Only the newly created project, its recorded Docker resources/volumes and its isolated work directory may be reset/recreated for test repetitions. Never use a global Docker prune, stop-all, repository reset or cleanup of existing PostgreSQL/Supabase resources. Capture test evidence before resetting.

On completion stop this project's containers and retain its private data/baseline backup for separately approved R05 continuation. Cleanup authorization covers removal of temporary fixture data by restoring this disposable baseline and removal of this project's failed disposable resources, after exact identity/path checks; preserve durable evidence and source. Do not stop Docker globally if other workloads use it. Shared downloaded image cache remains; it is not pruned.

Rollback for this test target is restore/recreate from its captured baseline, reapplying the recorded source when needed. No production rollback is involved. No existing database backup is required because existing databases are never opened or mutated. A failed restore or uncertainty about target ownership is a stop condition.

## Following gates

R05 will name the browser/Android target, local application build/serve action and exact backend, then cover actual login/setup, reload/restart, lock/background/identity switching, conflict/offline behavior and accessibility. R04 hosted backend and R07–R09 delivery remain unapproved. Keep this chapter open through approved connected work; the chapter is not complete merely because this request is ready.

Approval is needed because [AGENTS.md](../../../AGENTS.md) rule 9 states: “Deployment, publication, pushing, merging, permission changes, connected testing and rollout retain separate approval requirements.” The [scope register](../../../docs/superpowers/plans/2026-10-12-staff-workflow-scope-acceptance.md) separately gates R03 and R06, and the human's current instruction expressly requests outstanding action-specific approval.
