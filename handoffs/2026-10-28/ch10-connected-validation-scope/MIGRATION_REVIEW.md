# Source migration and consumer review

Fresh source review, 2026-10-28; no PostgreSQL compile/apply or runtime probe. All ten files reviewed for their role in the proposed sequence; hashes in MIGRATION_MANIFEST.json. The 46-entry Chapter09 source manifest matches exactly.

| Migration | Review relevance |
|---|---|
| 20260924030000_init | Tenancy/Auth FKs, staff/kiosk constraints, catalog, finance and inventory. Device subject UNIQUE prevents inserting duplicate kiosk subjects normally. audit_log uses bigserial, unlike most UUID tables. |
| 20260924030001_rls | Broad authenticated-era RLS helpers/policies; table privileges are an additional boundary. Supplier override follows. |
| 20260924030002_rpcs | Legacy PIN, stock, round, temperature and alert APIs plus five views and grants; closed by the last migration. |
| 20260925000000_supplier_tier | Enum extension retained in its own migration transaction. |
| 20260925000001_supplier_tier | Supplier identity/helper/read policies; conflict identities need tests. |
| 20261013000000_store_setup | Eight private-to-clients public setup tables; immutable history triggers; _setup_actor/_setup_lock and validators. Receiving depends on _setup_length/_setup_trim/_setup_immutable. |
| 20261013000001_store_setup_api | Six public S1 APIs, SECURITY DEFINER with fixed search_path and own scope checks; org-row serialization and retry/audit. Receiving policy uses _setup_date_complete and setup tables. |
| 20261027000000_receiving_identity | Five private tables, digest-only session secret, key bytes, durable attempt row, scope locks and helpers; eight-hour session constraint and single live-session index. |
| 20261027000001_receiving_foundation_api | Six public receiving endpoints, end-of-read rechecks, denial envelopes, recovery audit atomicity, safe DTO projection. No stock submission. |
| 20261027000002_receiving_access_boundary | Breaking closure below; explicit retained S1 grants. |

Exact closed tables: orgs, branches, staff_profiles, kiosk_devices, categories, suppliers, products, batches, purchase_orders, po_lines, receiving_events, alerts, rounds, round_items, temp_logs, audit_log, supplier_profiles. Views: v_upcoming_shipments, v_stock_by_product, v_supplier_scorecard, v_waste_recovery, v_alert_response_times. ALL privileges revoked from PUBLIC, anon, authenticated on these objects and their owned sequences.

All overloads of these 19 public function names are closed: current_staff, current_app_role, current_org_id, current_branch_scope, is_admin, is_manager_or_admin, is_kiosk_device, is_supplier, current_supplier_id, set_staff_pin, kiosk_verify_pin, _assert_kiosk_actor, kiosk_log_batch, kiosk_resolve_alert, kiosk_start_round, kiosk_add_round_item, kiosk_complete_round, kiosk_log_temp, refresh_alerts. Catalog the exact resolved signatures before apply; unexpected overloads stop for review rather than silently widening the approved delta.

Retained authenticated EXECUTE: get_admin_setup_context(), get_store_setup(uuid), save_store_setup(uuid,uuid,integer,jsonb), activate_store_setup(uuid,uuid,uuid,integer,integer,text), mutate_setup_preset(jsonb), mutate_setup_location(jsonb).

New authenticated EXECUTE: get_receiving_context_v1(), begin_staff_session_v1(text), end_staff_session_v1(uuid,text), recover_receiving_partition_v1(uuid,text,uuid,text), get_receiving_catalog_v1(uuid,text,jsonb,uuid,integer), get_receiving_policy_v1(uuid,text,uuid). All other new receiving helpers are in private with explicit execute revocations. No client table/policy grant is added.

## Consumer impact observed in source

`product/js/supa.js` reads kiosk_devices/staff_profiles; product/js/screens/tabs/{admin,alerts,dashboard,stock,shipments,revops}.js depend on closed tables/views and refresh_alerts. Their old flows are expected to fail on the disposable migrated target. They are not modified or certified by this proposal. `app_flutter/lib/supa.dart` retains legacy direct context helpers; `lib/main.dart` currently composes SupabaseWorkspaceGate, which uses the receiving context RPC and routes admins into AdminSetupGate. Trace the actual signed-in app during R05 to ensure no fallback invokes the legacy helpers. `lib/setup/supabase_setup_repository.dart` uses the six retained S1 RPCs. Source routing supports a test hypothesis; no connected success is inferred.

## Open findings / test implications

1. The access-boundary comment says the retained schema uses UUIDs, but audit_log.id is bigserial. The loop should include its owned sequence; assert effective privileges on audit_log_id_seq. No source comment was edited in this chapter.
2. The receiving migration explicitly revokes current object access but does **not** issue ALTER DEFAULT PRIVILEGES. The accepted contract mentions private default-privilege denial. Inspect actual defaults/owner and report the discrepancy. Do not silently add a blanket default ACL change or call that contract criterion complete.
3. Table revokes alone are not evidence that pre-existing column grants or inherited roles are closed. Inspect actual effective grants and test access as anon/authenticated, never only as the database owner.
4. The existing SQL harness calls RPCs as its SQL connection identity with synthetic JWT settings; that exercises function logic but does not prove real API role grants/Auth. Its users are id-only, passwordless transaction-local rows. Its scope is one org/branch and two actors. Real password-enabled Auth fixtures and cross-tenant/role cases are required.
5. Existing Python HTTP errors become a generic exception. Negative tests need an additive test-only runner that records status/error code safely without printing keys/proofs or masking expected denials. Its five-attempt race does not cover post-wait revocation or exact cooldown boundary.
6. No Realtime service exists in the five-service allowlist. Inspect publication/role/gateway exposure, but mark real Realtime transport acceptance NOT RUN unless a separate service proposal is approved. A dead route is not proof of future deployed Realtime security.
7. Native storage harness currently tests write/close/reopen and a stale-revision race only. Faults, quota, version blocking, real process lifecycle and Auth must remain separately evidenced. No previous migration or production code is modified to conceal these limits.
