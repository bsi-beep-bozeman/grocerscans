# Resume prompt

Paste the block below into a fresh Claude Code session after a context reset.
Everything else in this repo — plus **`product/`** and its own README — is the
context it needs.

---

## Copy this

```text
I'm resuming the Al Safa Market OS engagement. The working repo is:

D:\LLM-Data\Claude-Desktop\claude-code\shelflife

The engagement has PIVOTED. The current deliverable is a Supabase-backed PWA
built from scratch under product/, NOT a set of patches to the client's
existing Al Safa Market OS build. Read these first, in this order:

1. product/README.md   — status matrix, seed credentials, local setup
2. product/supabase/migrations/*.sql
                       — full schema + RLS + RPCs (org → branches → users,
                         batch model, POs, alerts, rounds, temp logs,
                         audit log, rev ops views)
3. product/supabase/seed.sql
                       — 1 org, 2 branches, 4 kiosks, 1 admin, 1 viewer,
                         12 staff with PINs, categories, demo products
4. ASSESSMENT.md       — assessment of the client's original build; still
                         accurate as context on WHY these choices were made
5. MARKET.md §8        — state date-label rules (still unresolved — which
                         US state the store is in gates category legality)

The pre-pivot documents (this RESUME.md prior version, PLAN.md, MEETING.md)
were built around "extend their build." That option was on the table until
the client meeting, after which the direction changed to building a fresh
Supabase-backed product with proper multi-branch tenancy, role-based access,
and kiosk PIN auth. Treat those documents as historical context, not the
current plan.

DECIDED — don't relitigate
- Supabase-hosted (local Supabase for dev via `npx supabase start`).
- Same PWA URL serves mobile and desktop.
- 1 org (Al Safa Market), 2 branches, 4 tiers:
    admin  — email/password, all branches, rev ops + user mgmt
    manager — email/password, one branch (nullable — see is_shift_lead)
    staff  — 4-6 digit PIN on kiosk device only (never per-user email)
    viewer — email/password, read-only rev ops
- Kiosk devices are their own Supabase auth accounts. Staff writes go
  through SECURITY DEFINER RPCs (`kiosk_log_batch`, `kiosk_resolve_alert`,
  `kiosk_start_round`, `kiosk_add_round_item`, `kiosk_complete_round`,
  `kiosk_log_temp`) that re-verify the PIN and stamp the audit log.
- Manager tier is not seeded — the shift-lead concept is expressed as
  `is_shift_lead` on staff_profiles. Promote to a real tier if the client
  needs a separate operational role.

BLOCKED ON — needed before a client demo
- Which US state the store operates in. Category flags
  `allows_markdown_past_date` and `allows_donation_past_date` are seeded
  `false` (conservative) and can't be finalised without it.
- Confirmation from the client that the seeded tier structure and
  branch/staff counts match their operation.

STATUS WHEN LAST TOUCHED (see product/README.md status matrix for detail)
- ✅ Schema, RLS, RPCs, rev ops views written and committed
- ✅ Seed script written and committed
- ✅ PWA login + role-aware shell + 4 read-only tabs (dashboard, stock,
     shipments, rev ops) + admin/alerts read-only + scan/rounds stubs
- ⏳ Local Supabase (`supabase start`) had to finish downloading Docker
     images — verify with `npx supabase status` and `npx supabase db reset`
     before assuming migrations are applied
- ⏳ Not yet built: kiosk PIN pad UI, barcode scanner wire-up, alert
     resolve action, admin user-mgmt writes, offline IndexedDB queue,
     service worker

Give me a short summary of where things stand and what you'd do next. Don't
restate the documents back to me.
```

---

## If you only have one line

```text
Read D:\LLM-Data\Claude-Desktop\claude-code\shelflife\RESUME.md and follow it.
```

---

## State at last commit

Check current state with `git -C "D:\LLM-Data\Claude-Desktop\claude-code\shelflife" log --oneline`.

Remote: `github.com/bsi-beep-bozeman/grocerscans` (branch `main`).

| | |
|---|---|
| Product repo path | `product/` |
| Dev server | `node product/_serve.mjs 8128` → http://localhost:8128 |
| Local Supabase | `cd product && npx supabase start` (Docker required) |
| Studio (schema/auth UI) | http://127.0.0.1:54323 after start |
| Reference-only twin | `app/` — the old scrappy demo, NOT the deliverable |
| Client docs | `reference/AL_SAFA_MARKET_OS.md` |

**Reset the database (applies migrations + seed):**

```bash
cd product && npx supabase db reset
```

**First-time only** — after `supabase start`, copy the anon key from
`npx supabase status` into `product/js/config.js`.

## Order of next work

1. Verify migrations apply cleanly against local Supabase; fix any errors
2. Wire kiosk PIN pad UI + barcode scanner (port from `app/js/scanner.js`)
3. Wire alert resolution (PIN gate + resolution picker → `kiosk_resolve_alert`)
4. Admin user-mgmt writes: invite by email, assign role/branch, rotate PIN
5. Rounds flow: pair-audit start, mark items, close
6. Offline queue (IndexedDB) + service worker
7. Deploy target (hosted Supabase + static host — Netlify/Vercel/Cloudflare Pages)

## Two open decisions worth flagging every session

- **State the store operates in.** Drives donation/markdown legality per
  category. See [MARKET.md §8](MARKET.md).
- **Manager tier vs `is_shift_lead` flag.** Current seed has no Manager users;
  staff-lead is a flag. Confirm with client before adding.
