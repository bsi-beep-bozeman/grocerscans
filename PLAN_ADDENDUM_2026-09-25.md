# PLAN Addendum — 2026-09-25

Rolls up to a future PLAN v2. Two design notes captured here so they survive
context loss between Claude sessions.

Read this alongside:
- [PLAN.md](PLAN.md) — original plan (⚠ superseded in part)
- [ASSESSMENT.md](ASSESSMENT.md) — revised "extend their build" position
- [RESUME.md](RESUME.md) — session state, blocked decisions
- [reference/AL_SAFA_MARKET_OS.md](reference/AL_SAFA_MARKET_OS.md) — client brief

---

## 1. Access tiers — split viewer from supplier

**Client (2026-09-25):** wants 3 tiers — `admin / staff / viewer-or-supplier`.

**Recommendation:** keep them as 3 tiers, but split the last into two roles
that share the "external-to-operations, mostly-read-only" shape:

| Tier | Auth | Scope | Data access |
|---|---|---|---|
| `admin` | email + password | all branches | full read/write, user + branch mgmt |
| `staff` | 4–6 digit PIN on kiosk | one branch (kiosk-bound) | writes via SECURITY DEFINER RPCs only |
| `viewer` | email + password | all branches (internal) | read-only on everything |
| `supplier` | email + password | scoped to own `supplier_id` (external) | read-only on own deliveries + performance |

Rationale for the split: a viewer is internal (owner's accountant, exec, consultant)
and safe with cross-branch visibility. A supplier is external and must be
scoped — otherwise Supplier A logs in and sees Supplier B's pricing, volumes,
and shelf-life-delivered performance. That's a cross-tenant data leak.

Merging them into one tier forces one of two bad outcomes:
- Suppliers get viewer scope → they see competitors' data
- Viewers get supplier scope → they can only see one supplier's slice, useless

### Schema sketch

```sql
-- New table linking Supabase auth users to a supplier they represent.
-- One user maps to exactly one supplier; a supplier may have multiple users.
create table supplier_profiles (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  supplier_id uuid not null references suppliers(id) on delete cascade,
  created_at  timestamptz not null default now()
);

create index supplier_profiles_supplier_idx on supplier_profiles(supplier_id);

-- Extend the existing user role enum
alter type user_role add value if not exists 'supplier';
```

### RLS approach

For every table a supplier can read (`deliveries`, `batches`,
`supplier_metrics_view`, etc.), gate the SELECT policy on their
`supplier_id`:

```sql
create policy "supplier reads own rows only" on deliveries
  for select
  using (
    -- admins/viewers see everything
    (auth.jwt() ->> 'role') in ('admin', 'viewer')
    -- staff see everything in their kiosk's branch (unchanged)
    or (auth.jwt() ->> 'role') = 'staff'
    -- suppliers see only rows tied to their linked supplier_id
    or (
      (auth.jwt() ->> 'role') = 'supplier'
      and supplier_id = (
        select supplier_id from supplier_profiles
        where user_id = auth.uid()
      )
    )
  );
```

Suppliers get **no writes at all** in Phase 1 — the whole point is that
suppliers see their performance data, not that they update it. If a supplier
needs to acknowledge a return credit or upload a delivery manifest, that comes
in Phase 2 via a small set of scoped SECURITY DEFINER RPCs.

### Supplier dashboard (what they actually see)

Their own row-filtered slice of the existing rev-ops views:
- Deliveries made (count, dates)
- Average shelf life delivered (rolling 30/90d)
- Products received expired or near-expired (with % of total delivered)
- Return credits owed / processed
- Their own product list with days-until-expiry per active batch

This is a functional gap: **Supplier Dashboard is listed in the client brief
but only partially covered in PLAN.md §8 Phase 5** (which mentions "pharmacy
supplier-return worklist" only). Needs to move earlier — probably Phase 4 —
if suppliers get their own login.

### Onboarding a supplier user

Admin flow (part of user-mgmt writes still not built in `app_flutter/`):
1. Admin picks an existing supplier from the catalog
2. Admin enters supplier contact email
3. RPC `invite_supplier_user(supplier_id, email)` — sends Supabase magic-link
   invite, creates the `supplier_profiles` row on first sign-in

### Blocking on

Client confirmation of the split before writing the migration. If client
insists on merging, fall back to viewer-scope-only for both, drop the
supplier login concept entirely, and email supplier reports out from admin.

---

## 2. UX inspiration from Xpiry (Stavila Radu)

Client cited **Expiry Notify Product Scanner** ("Xpiry") on Play Store as
reference. It's a solo-user tracker — architecture doesn't transfer, but 4
UX ideas do:

### 2.1 Per-product custom reminder cadence

Xpiry lets a user override the default warning window on a per-product basis
(e.g. "warn 60 days out on this vitamin, 3 days on this yogurt"). Our
[PLAN.md §4](PLAN.md) already has category-level defaults but no per-product
override.

**Applied to ShelfLife:** add a nullable `alert_thresholds_days int[]` on
the `products` table. When null, use the category's default. When set,
override. Costs one column, saves the admin from creating a new category
every time one product has an unusual shelf life (imported foods,
seasonal, distributor-specific).

### 2.2 AI recipe generation from expiring products

Xpiry's headline AI feature: pick expiring items, generate recipe ideas via
ChatGPT. In a grocery-store context this is genuinely useful — not for the
staff, but for a **customer-facing "today's markdown recipes" endpoint** the
store can print on a shelf card or push to social. Feeds the waste-reduction
angle and gives the app a marketing hook.

**Priority:** low — Phase 5+. But worth capturing as a scope option because
it converts an internal alert into external customer value with maybe one
day of work (Claude API call, product-list-to-recipe prompt, print template).

### 2.3 Clean 3-tap scan-log flow

Xpiry's scan-hot-path is `scan → date → save`, three taps, no navigation.
Ours risks becoming `scan → category → supplier → batch qty → expiry → lot
code → location → save` — seven fields. On mid-range Android in a stockroom
this will get resented.

**Mitigation:** the scan flow must default-fill everything possible from the
UPC lookup (category from Open Food Facts, supplier from most-recent-received,
lot code from a scanned delivery manifest barcode) and only expose fields
where a default couldn't be inferred. Target: 3 taps for the common case,
7 fields available on an "advanced" expander for edge cases. Design this
before building the widget, not after.

### 2.4 PDF export of inventory

Client brief asks for CSV export; Xpiry does PDF. Both should exist:
- **CSV** — for the accountant and the future POS integration
- **PDF** — for what a manager actually prints and hands to a stockroom lead

Costs almost nothing to add both — Flutter has good pdf packages
(`pdf` + `printing`). Do them together.

---

## Status

Neither section here is implemented in code — this is captured for the next
Claude session (or a fresh clone) to pick up. See [RESUME.md](RESUME.md)
"Session 2026-09-25" for the full pending-decision list.
