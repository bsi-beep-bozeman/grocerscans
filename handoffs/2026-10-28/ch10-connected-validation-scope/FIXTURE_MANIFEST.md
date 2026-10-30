# Complete bounded synthetic fixture proposal

Not provisioned. Only the target in [ACTION_PACKET.md](ACTION_PACKET.md), after explicit R03 approval. Namespace `s2a-c10`; no real people, products or store policies. All generated UUIDs recorded in a private label-to-ID map, with a sanitized ID-only evidence copy. Auth account names below are exact labels; email pattern `s2a-c10-<label>@example.invalid`. Confirm locally through the target's existing Auth admin endpoint with email_confirm=true; never invite or send mail. Generate independent random passwords/PINs privately at execution. Do not copy historical credentials or put secrets in commands, output, Git or handoffs.

## Persistent Auth/identity fixtures

| Label | Profile and expected relationship |
|---|---|
| admin-a, admin-a2 | Separate active admins in org-a; S1 success/conflict/retry and route tests. |
| admin-b | Active admin org-b; cross-org setup denial. |
| inactive-admin | Inactive admin org-a; rejected routing and S1. |
| viewer-a | Active viewer org-a, no kiosk/supplier profile; unsupported receiving and S1. |
| manager-a | Active manager org-a/branch-a1; unsupported receiving and S1. |
| supplier-a | Active supplier_profiles entry linked supplier-a/org-a only. |
| kiosk-a1 | Active device-a1, org-a/branch-a1; principal happy-path kiosk. |
| kiosk-a1b | Different active device, same org/branch; device replay/isolation. |
| kiosk-a2 | Active device, org-a/branch-a2; branch replay/isolation. |
| kiosk-b1 | Active device, org-b/branch-b1; tenant replay/isolation. |
| kiosk-inactive | Inactive device org-a/branch-a1. |
| kiosk-mismatch | Device org-a pointing at branch-b1; individually valid foreign keys but inconsistent tenancy; must fail closed. |
| unlinked | Auth-only subject; no staff/supplier/kiosk row; unavailable. |
| staff-a1 | Active ordinary staff org-a/branch-a1; original draft owner. |
| lead-a1 | Active staff same branch, is_shift_lead=true; deliberate recovery. |
| replacement-a1 | Different ordinary staff same branch; cannot open original partition. |
| disabled-a1 | Inactive staff same branch; recovery of retained original partition. Seed vault while active, then disable under test authority. |
| staff-a2 | Active staff org-a/branch-a2, distinct PIN; wrong branch denial. |
| lead-a2 | Active lead org-a/branch-a2; wrong-branch recovery denial. |
| staff-b1 | Active ordinary staff org-b/branch-b1. |
| lead-b1 | Active lead org-b/branch-b1; cross-tenant recovery denial. |
| duplicate-pin-a1 | Active staff org-a/branch-a1, enabled only for ambiguous-PIN case; deliberately share staff-a1's PIN then disable to restore happy path. |
| conflict-kiosk-staff | Auth subject has both a kiosk and staff row. Test active then inactive staff row; identity must remain unavailable. |
| conflict-kiosk-supplier | Auth subject has both kiosk and supplier rows; repeat with supplier inactive. |
| conflict-admin-kiosk | Admin and kiosk same subject; repeat with inactive kiosk, receiving route must stay unavailable. Record S1's historical active-only conflict rule separately. |
| conflict-admin-supplier | Admin and supplier same subject; repeat with supplier inactive. |
| conflict-actor-supplier | Staff actor plus supplier row, PIN candidate excluded even if supplier inactive. |
| conflict-actor-kiosk | Staff actor also owns a kiosk, PIN candidate excluded even if kiosk inactive. |

Exactly 29 password-enabled local Auth users maximum for this manifest. All staff-role rows satisfy required pin_hash with locally generated bcrypt; non-staff roles use null unless a scenario explicitly needs a synthetic hash. PIN candidates normally have distinct values; ambiguous-PIN overlap is deliberate and isolated. No password value is meaningful outside this disposable environment. Auth IDs returned by provisioning are mapped before inserts, not guessed. Verify one account per label and exact roles/branches before tests. Reject fixture collisions; never overwrite unknown accounts.

No duplicate device subject can normally be inserted because the base schema has a UNIQUE constraint. Test the constraint rejection and record a SQL-only invalid-state simulation as out of scope; do not drop that constraint. Missing branch uses a nonexistent ID in requests; a dangling device FK is not seeded by disabling constraints. A role=staff branch-null insert must fail its CHECK; admin/viewer branch-null is valid. These are explicit constraint tests, not fabricated successful fixture states.

## Data and configuration fixtures

| Object | Bounded contents |
|---|---|
| Organisations / branches | org-a and org-b; branches a1, a2, b1. Display names prefixed `S2A C10 Synthetic`; timezone Australia/Perth for consistent display, not real-store jurisdiction. |
| Devices | One for each kiosk-* and kiosk-conflict label above; no extra users/devices beyond the manifest. Labels map to exact branch/tenant. |
| Categories | category-a-printed, category-a-calculated, category-b-printed. Legacy computed category carries a positive synthetic shelf-life value; setup's calculated policy is distinct. |
| Suppliers | supplier-a and supplier-b; one profile for each supplier/conflict label may link to the same appropriate supplier. Extra 100 org-a suppliers only during the >100 supplier response-bound test (101 total), then remove only those injected rows. |
| Catalog | product-a-zero with UPC `001234`, product-a-sku with leading-zero SKU, product-a-missing-setup, product-a-foreign-category, product-a-foreign-supplier, product-b-zero with the same UPC in org-b. Price/cost sentinels exist solely to prove absence from safe responses. |
| Pagination | 101 additional synthetic org-a products, UUID-order stable, distinct names/UPCs; verify pages 1/50/100 and rejected 0/101 limits, cross-tenant after cursor. Oversized source text bounded to 300 KiB for one response-size fixture; never mass-load disk. |
| Setup | Start with no active setup. Through the six S1 APIs create receiving and hold locations for a1, foreign location b1, one printed preset and a calculated preset with explicit synthetic reference; configure product-a-zero: each precision0, pack count1, manual entry/manual_only label, printed expiry, supplier/reference/lot optional, exception role lead, fixed past-date restrictions false and confirmation required true. Activate via admin-a with reason `Synthetic connected validation`. Unknown/incomplete variants remain drafts or are isolated SQL fixture changes, never claimed to be valid activation. |
| Staleness | admin-a2 changes draft/active revisions and deactivates a bound preset/location in named cases; capture version/pointer/audit before and after. Restore fixture values between cases or use separate rollback transactions. |
| Stock sentinels | One valid batch and related alert, one round and round item, one temp log, one existing operational audit entry in org-a; one purchase order/line and receiving event. Hash all affected stock/operational tables before/after A actions. Their creation is fixture setup, not receiving feature execution. No A call may add stock. |
| Local drafts | Original staff-a1: two drafts with synthetic notes and distinct immutable operation IDs; replacement-a1 and staff-b1: one each in their own context; disabled-a1: one before disabling. Corrupt one copied synthetic envelope and keep the unaffected committed records. Max synthetic storage bounded by application limits plus one attempted over-limit record. |

The foreign-category/supplier product cases intentionally violate tenant consistency while preserving underlying FK constraints. Isolate them from S1 happy-path catalog reads, whose validator correctly rejects inconsistent tenant references. Run each mutation with explicit before/after assertions and reset its synthetic row; do not globally weaken constraints.

## Controlled state changes / failure injection

Only the above synthetic actors/devices can have active, lead, PIN-last-changed, or session revoked state changed. Expiry-specific SQL fixtures may move both issued_at and expires_at together to preserve the eight-hour constraint; label those simulated expiry tests. Local signed short-lived synthetic JWTs may use the existing disposable signer privately for after-lock expiry tests; no signing key printed/rotated. Test real password sign-in/refresh independently.

Use two SQL sessions and an observer to prove an actual wait via pg_blocking_pids; change the synthetic role/PIN/session while its request waits, release, assert denial/no key/no new audit/grant. Test 5-way invalid PIN concurrency; bracket blocked_until at just-before and after with database clock observations. A real 300-second cooldown run is separate from direct timestamp simulation. Grant/expiry recovery waits use the same discipline.

Inject recovery and S1 audit failure with a narrowly named temporary test function/trigger on the disposable relevant audit table, scoped to synthetic action/IDs. Ensure removal in finally/transaction rollback, verify no orphan grant/operation/version, and verify no failure injection survives restore. Session-start audit failure must likewise release no session/key. No long-lived production trigger change.

Transactional original SQL harness retains its separate `97000000-...` fixture namespace and ROLLBACK. The browser native harness retains its `98000000-...` synthetic IDs/database. Persistent fixtures use generated UUIDs rather than either namespace. Failed partial provisioning is retained for diagnostics and removed by the approved baseline restore, not broad cascaded ad-hoc deletes. Auth users, receiving keys, audits and setup histories are cleaned together by restoring the entire named database; local browser state cleanup is limited to the dedicated profile in ACTION_PACKET.md.
