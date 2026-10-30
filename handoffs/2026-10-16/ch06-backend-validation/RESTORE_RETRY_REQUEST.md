# R03 addendum — retry disposable restore with its existing owner account

Status: REQUESTED, NOT EXECUTED. Owner: [Chapter06](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a).

Approve **“Restore retry”** to authorize resuming the failed baseline-restore step on the same disposable target:

- Container: `supabase_db_shelflife-ch06-validation`; database: `postgres`; volume of the same container name; network: `shelflife-ch06-validation`; host endpoint127.0.0.1:55322.
- Start only that database container. Keep the other four target services stopped during restore. Revalidate identities, mounts and both backup hashes.
- Recreate only this partial disposable database and restore `.cache/ch06-validation/private/before-setup.dump` using its **existing `supabase_admin` account**, preserving original schema ownership. No role, grant, credential or host permission changes. The account's local login and superuser capability have already been verified read-only.
- Corrected reviewable harness: [restore-baseline.mjs](../../../product/supabase/tests/backend-validation/restore-baseline.mjs). Save the retry outputs in a new attempt directory; preserve `RESTORE.json` as the failed first attempt.
- Verify exactly the five retained migration records, zero synthetic users/organisations and no setup tables. Reapply the two already-approved setup migrations and rerun transaction assertions to verify the restored target is usable. Then stop the target containers and retain backups/evidence. Do not repopulate browser fixtures until R05 is also approved.

Private baseline SHA-256: `587CE15FBBD00FA7FDA99C953E691F1926C628283A285D2073E7ECABC0D73B83`.
Private tested snapshot SHA-256: `DB70BC336DDF52C677D76B360A0DCE1FE07E9D3688B1BC2B6DA7B25012D3A915`.
Both are preserved; do not overwrite them. If the corrected restore fails or ownership changes, stop and report again. Do not bypass ownership with `--no-owner`, invent grants or modify other databases.

Why additional approval: the [original approved packet](../../2026-10-15/ch06-admin-setup-validation/R03_R06_APPROVAL_REQUEST.md) explicitly states **“A failed restore or uncertainty about target ownership is a stop condition.”** The first condition occurred. The correction is prepared, but executing it requires release of that gate.
