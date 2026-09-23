# ShelfLife — product build

Supabase-backed PWA. Works in mobile browsers and desktop browsers off the same
URL. Multi-branch under one org, role-based access with row-level security in the
database.

**Reference-only twin lives in `../app/`.** That's the port-source. This is the
real product.

---

## Roles

| Role | Auth | Devices | Sees | Does |
|---|---|---|---|---|
| **Admin** | email + password | any | everything + rev ops + user mgmt | all writes |
| **Manager** | email + password | any | one branch: stock, POs, alerts | edit within branch |
| **Staff** | 4–6 digit PIN on a kiosk | store kiosks only | today's worklist | log batches, resolve alerts, run shift audits |
| **Viewer** | email + password | any | rev ops, read-only | nothing writable |

`is_shift_lead` is a flag on staff, not a separate tier — cheap to promote later.

## Data model

- `orgs` → `branches` → `staff_profiles`, `kiosk_devices`, `categories`,
  `products`, `batches`, `purchase_orders` (+ lines), `receiving_events`,
  `alerts`, `rounds` (+ items), `temp_logs`, `audit_log`.
- RLS scopes every read/write by `org_id` and, for branch-scoped roles, by
  `branch_id`.
- Staff writes never touch tables directly — every kiosk action goes through a
  `SECURITY DEFINER` RPC that re-verifies the PIN and stamps the audit log.

## Local dev

Prereqs: Docker Desktop running, Node 18+.

```bash
cd shelflife/product
npx supabase start          # first run pulls ~2GB of images
npx supabase status         # prints API URL + anon key
# copy anon key into js/config.js
npx supabase db reset       # applies migrations + seed.sql
node _serve.mjs 8128        # dev server (localhost is a secure context — camera works)
# open http://localhost:8128
```

Studio (schema browser, SQL editor, auth panel) runs at `http://127.0.0.1:54323`.

## Seeded accounts (dev only — rotate before production)

| Purpose | Email | Password | PIN |
|---|---|---|---|
| Admin | `admin@alsafa.local` | `shelflife-admin` | — |
| Viewer | `viewer@alsafa.local` | `shelflife-view` | — |
| Kiosk (Branch A, Device 1) | `kiosk-a1@alsafa.local` | `shelflife-kiosk` | staff PIN below |
| Kiosk (Branch A, Device 2) | `kiosk-a2@alsafa.local` | `shelflife-kiosk` | staff PIN below |
| Kiosk (Branch B, Device 1) | `kiosk-b1@alsafa.local` | `shelflife-kiosk` | staff PIN below |
| Kiosk (Branch B, Device 2) | `kiosk-b2@alsafa.local` | `shelflife-kiosk` | staff PIN below |
| Staff (Branch A, #1..#6) | — | — | `1111` … `6666` |
| Staff (Branch B, #1..#6) | — | — | `1111` … `6666` |

Staff #1 in each branch is flagged `is_shift_lead = true`.

## Status right now

| Piece | State |
|---|---|
| Schema + RLS + RPCs | ✅ written |
| Seed | ✅ written (org, branches, 13 users, 4 kiosks, categories, demo products) |
| Login (email/password) | ✅ working |
| Post-login shell + role-aware tabs | ✅ working |
| Read tabs: Overview / Stock / Shipments / Rev ops / Admin | ✅ working |
| Alerts tab | ⚠ read-only for now |
| Scan, Rounds, Alert-resolve (kiosk writes) | ⏳ next iteration — RPCs exist, PIN pad UI + scanner not wired yet |
| Admin user-mgmt writes (invite, PIN rotate) | ⏳ next iteration — `set_staff_pin` RPC exists |
| Offline queue (IndexedDB) | ⏳ next iteration |
| Service worker | ⏳ next iteration |

## Open decisions (not blocking dev, but need answers before demo)

1. **State the store operates in.** Drives `allows_markdown_past_date` and
   `allows_donation_past_date` on categories. Seed defaults them to `false`
   (conservative) — flip per state.
2. **Manager tier.** Do the actual staff include an operational lead who
   receives POs and edits batches, or is `is_shift_lead` enough? Seed currently
   has no Manager users.
3. **Rev ops line items.** The scorecard fields are a first pass —
   waste $ by supplier, avg shelf life received, alert response times, markdown
   $ recovered. Add / drop before we call it done.
