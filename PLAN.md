# ShelfLife — Implementation Plan

Expiration tracking for an operating grocery store. Replaces manual shelf-walking
with scheduled, category-aware alerts and daily rounds.

> **⚠ Superseded in part.** This plan was written before the client's existing
> build was disclosed. Al Safa Market OS turned out to be substantially complete —
> PWA shell, role-based access, four dashboards, purchase orders, audit log.
> **The rebuild recommendation in §11 is withdrawn.** See
> [ASSESSMENT.md](ASSESSMENT.md) for the revised position: extend their build,
> and treat this document as the specification for the pieces it's missing —
> the batch model (§5), category-aware expiry (§3–4), FSMA 204 (§4.4), and
> barcode scanning (§2).

---

## 1. Problem

Staff currently walk aisles reading expiry labels by eye. It takes time and still
misses product. Expired stock reaches customers.

The store owner built a prototype (via Codex) but phone barcode scanning does not
work when the site is opened on a phone.

**Goal:** a phone-based system that logs stock when it arrives and reliably tells
staff what to check, when — so the shelf walk happens on schedule instead of from
memory.

---

## 2. Why the prototype's scanning almost certainly failed

Diagnose before the meeting. In likely order:

1. **Served over `http://` instead of `https://`** — the browser camera API
   (`getUserMedia`) is blocked on insecure origins. The single exception is
   `localhost`. If the prototype was opened on the phone via a LAN address like
   `http://192.168.1.50:8000`, the camera fails silently or throws a permission
   error. **This is the most common cause and matches the symptom exactly:
   works on the dev machine, dead on the phone.**
2. **Missing `playsinline` on the `<video>` element** — iOS Safari refuses to
   play inline video without it and forces fullscreen, breaking the scanner.
3. **No `facingMode: 'environment'`** — opens the selfie camera instead of the rear.
4. **Permission requested outside a user gesture** — must be triggered by a tap.
5. **Library choice** — some barcode libs bundle a WASM/worker path that 404s
   under a subdirectory deploy.

### Fix: native first, library fallback

```js
// Chrome on Android — native, fast, zero bundle cost
if ('BarcodeDetector' in window) { /* use it */ }
// iOS Safari + older Android — fall back to ZXing
else { /* @zxing/browser */ }
```

Target formats: `ean_13`, `upc_a`, `ean_8`, `upc_e`, `code_128`.

---

## 3. Domain model — three classes of expiry

The core design decision. Not all expiry is the same kind of expiry.

| Class | Date source | Risk if missed | Action when close |
|---|---|---|---|
| **Packaged** (dry, canned, frozen, dairy) | Printed on package — *recorded* | Quality | Markdown / move |
| **Fresh** (meat, produce, bakery) | *Computed* from date received | Health hazard | Freeze / convert / discard |
| **Regulated** (medicine, supplements) | Printed on package — *recorded* | **Legal** | Return to supplier for credit |

### Implications

- **Two entry flows.** Packaged goods: scan → type printed date. Fresh goods:
  scan or pick → system computes expiry from category shelf-life rule. Nobody
  prints an expiry on a tray of pork belly.
- **Two output modes.** Packaged/regulated → **Alerts** (30d/7d). Fresh → **Daily
  Rounds** (a worklist, because a 3-day shelf life makes a 30-day alert useless).
- **Medicine alerts early.** Most pharma distributors accept returns for credit
  3–6 months before expiry. Alerting at 30 days is too late to recover the money.
  Alert at **120 days**.

---

## 4. Category profiles (seeded at onboarding)

| Category | Mode | Default shelf life | Alerts | Notes |
|---|---|---|---|---|
| Dry / canned goods | Printed | — | 30d, 7d | Markdown permitted |
| Frozen | Printed | — | 30d, 7d | Never refreeze after thaw |
| Dairy | Printed | — | 7d, 2d | Cold chain |
| Beverages | Printed | — | 30d, 7d | |
| Fresh meat (chilled) | Computed | 3 days | Daily round | Freeze / convert / markdown / discard |
| Fresh fish | Computed | 1–2 days | Daily round | Shortest window |
| Produce | Computed | 3–7 days (per item) | Daily round | Visual check still required |
| Bakery (in-store) | Computed | 1–2 days | Daily round | End-of-day markdown |
| Deli / prepared | Computed | 2–3 days | Daily round | **FTL** — RTE deli salads |
| Store-packed / repacked | Computed | Per item | Daily round | **No UPC** — see §4.2 |
| **Pharmacy / OTC** | Printed | — | **120d, 30d, 7d** | See §4.3 |

**FTL** = on the FDA Food Traceability List. These carry a legal recordkeeping
obligation on top of the store's own quality concerns — see §4.4.

All values are defaults the store can override during onboarding. Confirm the
actual mix with the client.

### 4.1 Building the product catalog

US packaged goods have good public UPC coverage, so Open Food Facts is a genuine
time-saver here — worth wiring up as a lookup on first scan.

But it won't cover everything: store-packed meat, deli items, bakery, private
label, and anything repacked in-house. So the catalog still needs to build itself:

```
Scan UPC
  ├── Known to this store?  → name auto-fills. One tap.
  ├── Unknown, in OFF?      → name pre-fills, staff confirms
  └── Unknown entirely?     → staff types it once
                              → saved permanently, auto-fills forever after
```

The store's own catalog is the source of truth; OFF is a convenience layer on
first encounter.

### 4.2 Products without a UPC

Store-packed meat, deli, bakery, and bulk items have no manufacturer barcode.
Most US grocers already print their own scale labels for these — often with a
Code 128 or GS1 barcode encoding PLU, weight, and sometimes a pack date.

**Ask to see an actual scale label at the meeting.** If it encodes a pack date,
that's the received-date input captured automatically, which removes a manual
step from the highest-volume category. If it doesn't, fall back to
pick-from-list — and that path has to be fast, or staff will resent it.

### 4.3 Pharmacy — check which kind

Two very different situations:

- **OTC only** (analgesics, vitamins, first aid on open shelf) → behaves like
  packaged goods with a long alert window. In scope.
- **A real pharmacy counter** with a pharmacist and Rx dispensing → regulated by
  DEA and the state board of pharmacy, and almost certainly already running
  dedicated pharmacy management software with its own lot and expiry tracking.
  **Out of scope.** Don't touch it.

The 120-day supplier-return window applies to OTC. Confirm which they have before
promising anything here.

### 4.4 FSMA 204 — the Food Traceability Rule

This is the most commercially significant thing in this document.

**What it requires:** businesses that manufacture, process, pack, or hold foods on
the FDA **Food Traceability List (FTL)** must keep records of Key Data Elements at
Critical Tracking Events, maintain a written traceability plan, and produce
records to FDA **within 24 hours** of request. For a retail grocer, the relevant
event is **receiving** — which means logging the traceability lot code when stock
arrives.

**Compliance date: July 20, 2028.** Extended 30 months from the original January
2026 date, and codified by Congress in the Continuing Appropriations Act of 2026.

**Exemption:** very small businesses, defined as ≤$1M average annual food sales
over the prior three years. An operating grocery store will clear this easily —
assume they are covered until proven otherwise.

**FTL foods likely on their shelves:**

soft and semi-soft cheeses (hard cheeses excluded) · shell eggs · tomatoes ·
peppers · cucumbers · melons · leafy greens incl. fresh-cut · fresh-cut fruits and
vegetables · fresh herbs · sprouts · tropical tree fruits · nut butters ·
crustaceans · bivalve mollusks · ready-to-eat deli salads

**Why this matters for the build:** the receiving flow already being designed —
scan, log quantity, record date, capture supplier reference — *is* the FSMA 204
receiving record, provided it also captures the **traceability lot code** from the
supplier and can export records on demand.

Two additions turn a shelf-life tool into a compliance tool:

1. A `traceability_lot_code` field on Batch, captured at receiving
2. An export that produces a sortable electronic record within the 24-hour window

That is a small amount of extra work against a hard federal deadline. It is
almost certainly the strongest commercial argument for building this properly
rather than patching the prototype.

**Verify current status before quoting.** Compliance dates for this rule have
moved more than once, and enforcement guidance may have been issued since.

### Fresh-goods state transitions

A fresh batch doesn't simply expire — it transitions, and some transitions
**spawn a new batch with a new clock**:

```
Chilled pork — Day 0 received
  └── Day 2 — decision point
        ├── [Freeze]   → new batch, ~90d clock, parent_batch_id set,
        │                 flagged "previously frozen" for relabeling
        ├── [Convert]  → new product (marinated), fresh 2–3d clock
        ├── [Markdown] → same batch, discounted flag
        └── [Discard]  → batch closed, logged as loss
```

This is the "active labeling" step made into a system action, with an audit trail.

---

## 5. Data model

```
Store
├── StaffMember          role: owner | manager | arranger
├── Category             expiry_mode, shelf_life_days, alert_thresholds[],
│                        allows_markdown, requires_relabel
├── Product              upc, sku, name, category_id, default_location
├── Batch
│     ├── product_id, quantity_received, quantity_remaining
│     ├── expiry_date            (entered OR computed)
│     ├── received_date, supplier_ref, location
│     ├── traceability_lot_code  (FSMA 204 — required for FTL foods, §4.4)
│     ├── state                  active | flagged | pulled | sold_out
│     │                          | relabeled | frozen | discarded
│     └── parent_batch_id        (set when spawned by a transition)
├── Alert                batch_id, threshold_days, fired_at, status,
│                        resolution: pulled | already_sold | relabeled
│                                  | frozen | discounted | donated | discarded
└── AuditLog             actor, action, entity, timestamp
```

**On `donated` as a resolution:** the Bill Emerson Good Samaritan Food Donation
Act, expanded by the Food Donation Improvement Act of 2023, gives liability
protection for donating food in good faith, and IRC §170(e)(3) offers an enhanced
deduction. Worth surfacing as a first-class action rather than burying it under
"discarded."

> **⚠ But the protection is conditional, and this is not as simple as it first
> appears.** Emerson protects "apparently wholesome food," defined as food that
> **meets all quality and labeling standards imposed by Federal, State and local
> laws.** If state law prohibits donating a past-date item, federal protection
> may not attach — and the §170(e)(3) deduction carries the same precondition, so
> a state violation can forfeit both at once.
>
> In every East Coast state checked, **reduced-oxygen-packaged (ROP) and
> time/temperature-control-for-safety (TCS) foods cannot be sold *or* donated past
> date.** Massachusetts and Pennsylvania are materially more restrictive than New
> York or Connecticut.
>
> **Product requirement:** category profiles must carry `allowsDonationPastDate`
> and `allowsMarkdownPastDate` flags, set per state, and the resolution UI must
> not offer actions the state prohibits. See [MARKET.md §8](MARKET.md).
>
> **Which state this store operates in is a blocking question** — the profiles
> can't be finalised without it. Not legal advice; confirm with counsel.

**Note on quantities:** without POS integration, `quantity_remaining` is an
estimate. This is accepted by design — the staff shelf walk *is* the verification
step. Alerts prompt a check; they don't assert stock is present.

**Note on roles:** "Arranger" is the client's own word for the shelf-facing staff
member. Using their vocabulary rather than imposing ours.

### 5.1 Offline-first

Store wifi is unreliable, and stockrooms are usually the worst-covered part of the
building. Scanning must not fail when the connection drops.

- Batch entries queue locally (IndexedDB) and sync when the connection returns
- The product catalog is cached on-device, so scan → name resolution works offline
- Alerts and Daily Rounds render from last sync, with a visible "last updated" stamp
- Conflict rule: entries are append-only, so offline queues merge without conflict

This is a Phase 1 requirement, not a later enhancement — retrofitting offline
support into a sync-assumed data layer is expensive.

---

## 6. Onboarding

New stores get a guided setup, not a blank inventory screen.

1. **Store profile** — name, branch(es), timezone
2. **Category selection** — "Which of these do you carry?" Pre-seeded profiles
   from §4. *Not skippable* — the entire alert model depends on it.
3. **Alert tuning** — show defaults per selected category, allow override
4. **Staff + roles** — invite by phone/email; owner / auditor / stocker
5. **First scan walkthrough** — scan any product on hand, log a batch end-to-end,
   see the resulting alert preview. Teaches the batch concept by doing it.
6. **Optional bulk import** — CSV of existing products (UPC, name, category)

---

## 7. UI direction

**Clinical white with urgency-coded status.** The base is calm and near-white;
colour appears *only* to signal expiry urgency. Read as a lab or hospital chart,
not a consumer app.

Constraints driving this: used under fluorescent store lighting, on mid-range
Android phones, one-handed, by staff in a hurry.

```css
--surface:        oklch(99% 0.002 250);   /* near-white, faintly cool */
--surface-raised: oklch(100% 0 0);
--border:         oklch(91% 0.004 250);
--text:           oklch(22% 0.01 250);
--text-muted:     oklch(52% 0.008 250);

/* semantic urgency — the only saturated colour in the system */
--ok:       oklch(62% 0.13 155);
--warn:     oklch(76% 0.15 78);
--urgent:   oklch(64% 0.20 38);
--expired:  oklch(54% 0.22 25);
```

- **Days-remaining is the hero element** — large numeral, everything else subdued
- Touch targets ≥ 56px; primary actions reachable by thumb
- Type: one family, wide weight range. Tabular figures for dates and counts
- No decorative colour. If it's coloured, it means something

---

## 8. Build phases

### Phase 0 — Scanning spike *(pre-meeting)*
Single page, HTTPS-served, proves barcode scanning works on their actual phone.
Scan → show UPC → resolve product name via Open Food Facts. No backend.

**Purpose:** walk into the meeting and demonstrate the exact thing their
prototype couldn't do. Small build, high credibility.

### Phase 1 — Core capture
Auth, store/category setup, product registry, batch logging (both entry modes),
batch list with filters.

### Phase 2 — Alerts engine
Scheduled job evaluates batches against category thresholds. Alert inbox,
acknowledge + resolve with reason. Delivery channel TBC with client (§10).

### Phase 3 — Daily Rounds
Fresh-goods worklist. State transitions incl. batch spawning on freeze/convert.
Print or display relabel instructions.

### Phase 4 — Onboarding
Guided setup flow per §6. Category seeding, CSV import.

### Phase 5 — Reporting
Loss tracking (what expired and its cost), alert response times, supplier-return
worklist for pharmacy.

---

## 9. Stack

| Layer | Choice | Why |
|---|---|---|
| Frontend | Vite + Preact, PWA | Small bundle for store wifi; installable, no app store |
| Scanning | `BarcodeDetector` → `@zxing/browser` fallback | Native where available, works on iOS |
| Offline | IndexedDB queue + service worker | Stockrooms have poor wifi; scanning must not fail |
| Backend | Supabase | Postgres + auth + scheduled functions on free tier |
| Alerts | Supabase cron → chosen channel | Decided with client |
| Product lookup | Store catalog + Open Food Facts pre-fill | Good US packaged coverage — see §4.1 |
| Hosting | Netlify / Vercel | **HTTPS by default — the prototype's likely bug** |

Dates display as MM/DD/YYYY; temperatures in °F.

### Running cost

A single store should sit inside free tiers for hosting and database. The line
item that reliably costs money is **SMS** (Twilio or similar, per message). Web
push and email are effectively free — worth steering there unless staff genuinely
won't install the PWA.

Verify current free-tier limits before quoting anything.

### Possible add-on: cold-holding temperature logs

The FDA Food Code requires cold holding at 41°F or below, and health inspectors
look for temperature logs. Most stores still keep these on a clipboard.

Since staff are already opening the app for Daily Rounds, capturing a chiller and
freezer temp reading at the same time is nearly free to build and replaces a paper
process that's an inspection item. Mention it; don't build it in Phase 1.

---

## 10. Open questions for the client

1. **Alert delivery** — in-app only, SMS, Viber, or email? (Viber is common for
   PH store staff and free.)
2. **Who receives alerts** — owner only, or per-category staff assignment?
3. **Categories carried** — is there a pharmacy counter? Fresh meat? Bakery?
4. **Delivery paperwork** — do supplier deliveries come with batch/lot refs that
   can be recorded?
5. **Existing POS** — brand, and does it export per-product sales?
6. **Staff count and devices** — how many phones, Android or iOS?
7. **Budget and target date** — not yet specified.
8. **Branches** — one store or several?

---

## 11. Recommendation — WITHDRAWN

> This section originally recommended rebuilding from scratch. That was based on
> the assumption of a thin prototype. Al Safa Market OS is not thin.
>
> **Current recommendation: extend their build.** The batch-model problem is
> real and remains the first priority — but it's a schema change to an otherwise
> substantial application, not grounds to discard months of working code.
>
> See [ASSESSMENT.md §6](ASSESSMENT.md) for the full reasoning and work order.

The one thing that survives unchanged from the original argument: **treating all
expiry as one kind of expiry is a schema problem, not a feature gap.** That was
right. It just turned out to be fixable in place.
