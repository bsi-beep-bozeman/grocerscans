# PLAN Addendum — 2026-09-25

Rolls up to a future PLAN v2. Design decisions and specs captured here so
they survive context loss between Claude sessions.

Read this alongside:
- [PLAN.md](PLAN.md) — original plan (⚠ superseded in part)
- [ASSESSMENT.md](ASSESSMENT.md) — revised "extend their build" position
- [RESUME.md](RESUME.md) — session state, blocked decisions
- [reference/AL_SAFA_MARKET_OS.md](reference/AL_SAFA_MARKET_OS.md) — client brief

---

## Decisions locked 2026-09-25 (CM)

The client has relinquished all app design and function to the developer
(CM). CM's locked-in positions on the previously-open decisions:

| # | Question | Decision | Rationale |
|---|---|---|---|
| 1 | Merge viewer + supplier, or split? | **Split.** 4 tiers total: `admin / staff / viewer / supplier` | Merged tier leaks other suppliers' pricing and volumes |
| 2 | Manager tier? | **No.** Use `is_shift_lead` flag on `staff_profiles` | Already the design in the current seed |
| 3 | iOS build path | **Defer iOS to Phase 2.** Ship Android + web first | Cheapest path; majority of stockroom devices are Android; iOS after Play Store launch validates the product |
| 4 | US state (donation/markdown legality) | **Conservative defaults** for now — `allows_markdown_past_date = false`, `allows_donation_past_date = false` on all categories. Flip per-state when the operating state is confirmed | Safe posture; data-only flip, no schema change |
| 5 | Vision API vendor for OCR | **Claude Vision** (Anthropic API via Supabase Edge Function) | One vendor relationship; strongest reasoning on packaging layouts |
| 6 | Vision confidence threshold | **0.75** default; fields below stay blank for manual entry | Standard practice |
| 7 | Extract barcode in same vision call? | **Yes.** One round-trip cheaper than two | |
| 8 | Email provider (scheduled reports) | **Resend** | Cheapest at low volume; excellent DX |
| 9 | Weekly report schedule | **Hardcoded Monday 08:00 America/New_York** in Phase 1. Make configurable in Phase 2 | Ship the report first, tune later |
| 10 | Category markdown/donation flags at seed | **All false.** Admin flips them per state after launch | Cannot ship legally-risky defaults |

Anything CM later wants to override, flip in this table and re-seed.
Nothing here is blocking implementation.

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

---

## 3. Scan Product by Photo — OCR / vision

Client brief §"Scan Product by Photo" — biggest AI feature in the brief,
absent from PLAN.md.

### Flow

```
Camera / gallery pick
  → POST photo to backend vision endpoint
  → Backend returns structured JSON:
       { name, brand, size_or_weight, category, expiration_date, confidence }
  → Client renders a REVIEW FORM pre-filled with returned values
       (fields below confidence threshold left blank for manual entry)
  → Staff reviews, edits, taps "Apply"
  → Client saves product + retains the photo + reviewed date
  → NEVER auto-saves without review (client brief is explicit on this)
```

### Vision model choice

Three viable paths, pick one:

| Option | Cost | Strength | Weakness |
|---|---|---|---|
| **Claude Vision** (Anthropic API) | ~$3/M in, $15/M out | Strong reasoning, single-shot structured extraction | Rate limits, one vendor |
| **GPT-4o Vision** (OpenAI) | ~$2.50/M in, $10/M out | Cheapest of the smart models, tools/structured-output first-class | One vendor |
| **Google Cloud Vision + Gemini** | Very cheap OCR, Gemini for reasoning | Free-tier friendly | Two-step (OCR then LLM), weaker on packaging layout |

**Recommendation:** Claude Vision. Client already runs Claude Code, so
Anthropic billing is one relationship not two. Extraction quality on
packaging (which mixes graphics, multiple date formats, unit hints) is
where reasoning matters — pure OCR often misreads MFG dates as EXP dates.

### Backend endpoint

Client brief says **API credentials must not be placed in browser code**.
That's correct. Implement as a Supabase Edge Function:

```
POST /functions/v1/scan-product-photo
  Headers: Authorization: Bearer <supabase_jwt>
  Body:    { photo_base64, target_category? }
  Returns: { name, brand, size, category, expiration_date,
             field_confidences: { name: 0.94, ... } }
```

Edge Function holds the Anthropic API key in env, forwards to Claude Vision
with a structured-output tool call, validates + returns. RLS on the function:
only authenticated users (any tier).

### Schema

```sql
alter table products
  add column photo_url text,             -- Supabase Storage path
  add column photo_reviewed_at timestamptz,
  add column photo_reviewer_id uuid references auth.users(id);

-- Photos go to Supabase Storage bucket `product-photos`,
-- one-year retention, private (signed-URL access).
```

### Priority

Phase 2 — after core capture. Adds real value to the receiving flow
(unfamiliar product? snap it, get pre-filled fields) but not blocking
first demo.

### Open decisions

- Vendor choice above
- Confidence threshold per field (default 0.75)
- Whether to also extract barcode via same call (yes — one round-trip cheaper than two)

---

## 4. Owner Dashboard

Client brief §"Owner Dashboard" — financial snapshot, absent from PLAN.md.

### Metrics

| Metric | Source | Compute |
|---|---|---|
| Total inventory value at cost | `batches.quantity_remaining × products.cost` | Sum, live |
| Total inventory value at retail | `batches.quantity_remaining × products.retail_price` | Sum, live |
| Potential gross profit | (retail total) − (cost total) | Difference |
| Inventory units | Sum of `quantity_remaining` | Live |
| Top 20 highest-value products | Rank by unit × retail | Materialized view, refresh 5min |
| Inventory by category | Group by category, sum retail value | Live |

### Implementation

Postgres views under `product/supabase/migrations/`:

```sql
create view owner_dashboard_totals as
  select
    branch_id,
    sum(b.quantity_remaining * p.cost) as inventory_value_at_cost,
    sum(b.quantity_remaining * p.retail_price) as inventory_value_at_retail,
    sum(b.quantity_remaining * (p.retail_price - p.cost)) as potential_gross_profit,
    sum(b.quantity_remaining) as inventory_units
  from batches b
  join products p on p.id = b.product_id
  where b.state in ('active', 'flagged', 'relabeled', 'frozen')
  group by branch_id;

create materialized view owner_top_20 as
  select p.id, p.name, p.category_id,
         sum(b.quantity_remaining) as units,
         sum(b.quantity_remaining * p.retail_price) as retail_value
  from batches b
  join products p on p.id = b.product_id
  where b.state = 'active'
  group by p.id, p.name, p.category_id
  order by retail_value desc
  limit 20;
```

RLS: `admin` and `viewer` roles only. Suppliers cannot read.

### Flutter widget

`fl_chart` for the by-category pie/bar. Numeric stats as large-typography
cards per PLAN §7 (days-remaining pattern extended to money).

### Priority

Phase 3 — after alerts engine. Owner-facing, expected on day one of admin
web build.

---

## 5. Executive Dashboard

Client brief §"Executive Dashboard" — rolled-up ops metrics.

### Metrics

| Metric | Source | Window |
|---|---|---|
| Inventory value | Reuses `owner_dashboard_totals` | Now |
| Products expiring within 7 days | `count(batches where expiry_date < now + 7d)` | Live |
| Products expiring within 30 days | Same, 30d | Live |
| Low-stock products | `count(products where sum(qty_remaining) < reorder_point)` | Live |
| Highest-value inventory | Reuses `owner_top_20` | Live |
| Weekly waste estimate | Sum of cost of batches transitioned to `discarded` state in last 7d | Rolling 7d |
| Monthly inventory summary | Snapshot of value + units + waste for the calendar month | Materialized nightly |

### New concept — `reorder_point`

Not in current schema. Add:

```sql
alter table products
  add column reorder_point int default 0;   -- 0 = no low-stock alert
```

Client can set per product during onboarding or leave 0 to skip.

### New concept — waste tracking

`batches.state` already includes `discarded`. Add a `discarded_at` timestamp
and a `discard_reason` (expired | damaged | recalled | other):

```sql
alter table batches
  add column discarded_at timestamptz,
  add column discard_reason text
    check (discard_reason in ('expired','damaged','recalled','other'));
```

Weekly waste view sums cost of batches where `discarded_at > now() - '7 days'`.

### Priority

Phase 3 alongside Owner Dashboard. Same audience, same tech, same RLS.

---

## 6. AI Insights — rules-based

Client brief §"AI Insights" — analytics engine. Brief is explicit:
**no external AI service required for the current local insights.** So this
is deterministic analytics dressed with natural-language templating, not LLM.

### Categories of insight

| Category | Rule | Output template |
|---|---|---|
| Expiration patterns | Category with highest % expired-before-sold over last 30d | "{category} is expiring before sale at {pct}% — consider smaller order quantities" |
| Waste trends | Waste this week vs 4-week avg | "Waste is up {pct}% vs 4-week average, driven by {top category}" |
| Slow-moving products | Products with `qty_remaining` unchanged >30d | "{count} products haven't moved in 30 days: {top 5 by value}" |
| Supplier risk | Supplier avg shelf-life-delivered dropping | "{supplier} is delivering {n} fewer days of shelf life than 90-day average" |
| Low-stock exposure | Value of near-out-of-stock items | "{count} items below reorder point, exposing ${amount} of potential lost sales" |
| Recommended actions | Composite | Ordered list of top 3 actions |

### Implementation

Single Postgres function `generate_insights(branch_id uuid)` that runs each
rule and returns a JSONB array. Called on-demand from the admin web build,
cached in a table for 1 hour to avoid re-computation on every visit.

```sql
create table insights_cache (
  branch_id  uuid references branches(id),
  generated_at timestamptz not null default now(),
  insights   jsonb not null,
  primary key (branch_id)
);
```

### Upgrade path

If the client later wants "real" AI insights (natural-language summary of the
whole dashboard, "why did we waste so much lettuce this week"), reuse the
Edge Function pattern from §3 — send the numeric insights to Claude with a
brief prompt, return prose. Not needed for Phase 1.

### Priority

Phase 4 — after dashboards exist. Depends on Owner + Executive metrics being
in place.

---

## 7. Purchase Orders + PDF

Client brief §"Purchase Orders" — pick supplier, choose products, generate
PO, save as PDF. Absent from PLAN.md.

### Schema

```sql
create table purchase_orders (
  id            uuid primary key default gen_random_uuid(),
  po_number     text not null unique,               -- YYYYMMDD-{seq}
  branch_id     uuid not null references branches(id),
  supplier_id   uuid not null references suppliers(id),
  status        text not null default 'draft'
                check (status in ('draft','sent','partially_received','received','closed','cancelled')),
  created_by    uuid not null references auth.users(id),
  created_at    timestamptz not null default now(),
  sent_at       timestamptz,
  expected_at   date,
  notes         text
);

create table purchase_order_lines (
  id            uuid primary key default gen_random_uuid(),
  po_id         uuid not null references purchase_orders(id) on delete cascade,
  product_id    uuid not null references products(id),
  quantity      int not null check (quantity > 0),
  unit_cost     numeric(10,2) not null,
  received_qty  int not null default 0
);
```

### PO number generation

`YYYYMMDD-NNN` where NNN is a per-day sequence per branch. Function:

```sql
create or replace function next_po_number(branch_id uuid) returns text
language plpgsql as $$
declare
  today text := to_char(current_date, 'YYYYMMDD');
  seq int;
begin
  select coalesce(max(substring(po_number from 10)::int), 0) + 1
    into seq
    from purchase_orders
    where po_number like today || '-%'
      and purchase_orders.branch_id = next_po_number.branch_id;
  return today || '-' || lpad(seq::text, 3, '0');
end $$;
```

### State machine

```
draft → sent → partially_received → received → closed
         └──→ cancelled
```

Transition to `received` fires an automatic receiving-log entry per PO line,
which becomes the Batch record — closes the loop between purchasing and
inventory intake per PLAN §5.

### PDF generation

Flutter `pdf` package for layout, `printing` package for share/print/save.
Template: header (store logo, branch, PO number, date), supplier info,
line items table (product, SKU, qty, unit cost, line total), grand total,
signature line, terms.

### Permissions

- `admin` — full CRUD, can cancel
- `staff` — can mark PO as received (via kiosk RPC that takes PO number),
  cannot create/edit
- `viewer` — read
- `supplier` — reads only own POs; future: can acknowledge receipt

### Priority

Phase 3 — before dashboards, actually. Purchasing is a daily flow; dashboards
are consumed weekly.

---

## 8. Weekly Monday 8AM inventory report

Client brief §"Reminders" lists a "Weekly Monday 8:00 AM inventory report".
Absent from PLAN.md.

### Schedule

Supabase `pg_cron` extension:

```sql
select cron.schedule(
  'weekly-inventory-report',
  '0 8 * * 1',                              -- Mon 08:00 branch-local
  $$ select send_weekly_report(); $$
);
```

Branch-local timezone matters — the store is US East Coast per project
memory, so cron server needs to run in `America/New_York` or the function
needs to compute the target time itself.

### Content

Snapshot of Executive Dashboard as of Monday 08:00, delivered as:
- **Email** (default) — via Resend/Postmark, template with the numeric cards
  from §5 rendered inline + a "View live dashboard" link
- **In-app push** — to all `admin` and `viewer` users, summary + tap-to-open
- **PDF attachment** — same template as PO generation, one-pager

### Delivery table

```sql
create table scheduled_reports (
  id            uuid primary key default gen_random_uuid(),
  report_type   text not null,             -- 'weekly_inventory'
  branch_id     uuid not null references branches(id),
  recipients    text[] not null,           -- email addresses
  sent_at       timestamptz not null default now(),
  payload_url   text                       -- signed URL to the PDF in Storage
);
```

### Priority

Phase 4 — after dashboards. Requires the metrics from §4 and §5 to exist.

### Open decisions

- Email provider — Resend is cheapest for low volume; ESP choice is a
  20-minute decision, not a blocker
- Whether to allow admin to configure the schedule (Monday vs Sunday, 8am
  vs custom) or hardcode. Recommend: hardcode Phase 1, make configurable
  Phase 2

---

## 9. CSV export

Client brief §"Core Inventory Features" — CSV export. Trivial but explicit.

### Implementation

- **Inventory export** — button on the products list, generates CSV of
  `products` + `batches` join, current stock snapshot
- **Receiving log export** — button on receiving log
- **Purchase order export** — line-item CSV per PO or bulk over a date range
- **Activity log export** — admin-only, CSV of the `audit_log` table

Flutter `csv` package to generate, `share_plus` to hand off to email/drive/
whatever the user picks. On the web build, triggers a direct download.

Server-side alternative: expose Postgres views as CSV via Supabase's built-in
`format=csv` query param — avoids reimplementing the CSV writer per client.

### Priority

Add alongside each surface that produces one. Not a phase of its own.

---

## Status

None of §3–9 is implemented in code yet — this is captured as a design
addendum so a fresh Claude session (or a new clone) can pick up any one of
them without re-deriving. See [RESUME.md](RESUME.md) "Session 2026-09-25"
for the full pending-decision list.
