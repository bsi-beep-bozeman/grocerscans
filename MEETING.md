# Client Meeting — Prep Kit

Companion to [ASSESSMENT.md](ASSESSMENT.md) and [PLAN.md](PLAN.md). Goal of the
meeting: confirm the gap analysis against the live app, agree the work order, and
leave with the source code and enough detail to quote.

**Read [ASSESSMENT.md](ASSESSMENT.md) first.** Their build is much further along
than the brief suggested, and the position has changed from *rebuild* to *extend*.

---

## Agenda (~50 min)

| Time | Segment |
|---|---|
| 10 min | **He demos.** Let him drive. Watch where he hesitates. |
| 10 min | **Scanning** — confirm why it fails (script below) |
| 15 min | **The batch problem** — the central finding, demo it live |
| 10 min | **Gap walkthrough** — shared data, FSMA, fresh goods |
| 5 min  | **Work order + next steps.** Ask for the source. |

Ask early: permission to record, and a copy of the source — particularly
`app.js` and whatever holds the inventory schema.

---

## Scanning — the corrected diagnosis

Their doc describes **"Scan Product by Photo"** — camera capture plus OCR/vision
to read product name, brand and expiry. Not barcode scanning. And:

> Production OCR or AI vision requires a secure backend endpoint configured
> through `VISION_ENDPOINT` in `app.js`.

**So it doesn't work because the vision backend was never built.** It's a stub,
not a bug. Lead with that; don't walk in claiming it's an HTTPS problem.

### Confirm in three questions

1. **"Is `VISION_ENDPOINT` set to anything in `app.js`?"** — if it's blank or
   placeholder, that's the answer, and it confirms you read their work properly.
2. **"When you tap scan on your phone, does the camera actually open?"**
   - Opens, photo captured, nothing extracted → purely the missing endpoint.
   - Doesn't open at all → a *second* problem stacked underneath. Go to 3.
3. **"What address do you open on the phone?"** — `http://<ip>` blocks camera
   access outright. Secure context is required for capture, independent of OCR.

### Then make the strategic point

They bet on the hard half and skipped the easy half.

> Reading expiry dates off packaging by OCR is genuinely difficult — inkjet on
> curved foil, and no consistent format. You were right to make it review-only.
> But scanning the *barcode* is a solved problem, and it gets you the product
> identity instantly. That's the piece worth adding first.

Then show barcode scanning working on your phone. See
[ASSESSMENT.md §2](ASSESSMENT.md).

---

## Questions to ask

### A0. Ask this before anything else

0. **Which state is the store in?**

   Not a formality. There is no federal date-labeling law except for infant
   formula — it's all state law, and East Coast states differ sharply. In
   Pennsylvania, milk cannot be sold past its sell-by date at all. Massachusetts
   restricts a long list of categories. New York is far more permissive.

   In **every** East Coast state checked, reduced-oxygen-packaged and
   refrigerated ready-to-eat (TCS) foods cannot be sold *or* donated past date.

   **The category profiles cannot be finalised without this answer**, because
   which resolution actions are legal — markdown, donate, or neither — is set by
   state. See [MARKET.md §8](MARKET.md).

### A. Categories — ask these next, they drive everything else

1. **Do you carry any of these?** — deli salads, soft cheeses, shell eggs,
   leafy greens, tomatoes, peppers, cucumbers, melons, fresh-cut produce, fresh
   herbs, sprouts, seafood. ← **highest-value question, see FSMA 204 below**
2. Fresh meat or seafood counter? How long do items sit in the case?
3. In-store bakery, deli, or prepared foods?
4. Store-packed items — do you print your own scale labels? **Ask to see one.**
5. Pharmacy: OTC on the shelf only, or a real Rx counter with a pharmacist?
6. Roughly how many distinct SKUs?

### B. Operations

7. How do deliveries arrive — is there a lot code or batch reference on the
   paperwork or case labels?
8. Who currently does the expiry walk, and how often?
9. How many staff would use this, Android or iPhone?
10. What POS and back-office system are you running?
11. Do you already donate near-expiry product to a food bank?

### C. Alerts

12. Who receives alerts — owner only, or staff per department?
13. Delivery: in-app push, email, or SMS? *(Push and email are free; SMS costs
    per message. Steer to push unless staff won't install the app.)*
14. What warning window feels right for packaged goods — 30 days, or longer?

### D. Commercial

15. Annual food sales above or below $1M? *(Determines FSMA 204 exemption — ask
    carefully, or infer from store size rather than asking directly.)*
16. Target date — is anything driving the timing?
17. Budget range?
18. One store or several, now or later?

---

## FSMA 204 — lead with this

The strongest thing you can say in this meeting, and it has a federal deadline
attached.

> The FDA Food Traceability Rule requires lot-level receiving records for a
> specific list of foods — deli salads, soft cheeses, shell eggs, leafy greens,
> tomatoes, peppers, melons, fresh-cut produce, seafood. If FDA asks, you have to
> produce those records within 24 hours. The compliance date is **July 20, 2028**.
>
> The system you're describing already captures most of that — you're scanning
> product and logging it on arrival. Add the supplier's lot code at receiving and
> an export, and the same tool that stops expired stock reaching your shelves also
> covers you for the traceability rule.

**Why this reframes the project:** he's currently buying a convenience tool to
save staff time. This makes it a compliance investment with a deadline. Different
budget conversation entirely.

**Be straight about the caveats:**
- Very small businesses — ≤$1M average annual food sales over three years — are
  exempt. Most operating grocers clear that easily, but confirm.
- This rule's compliance date has moved more than once. Verify current status
  before you put it in a proposal.
- You are not selling a certified compliance product. You're building a tool that
  captures the right records. Their own counsel confirms sufficiency.

### Secondary: OTC returns

If they have OTC shelf stock, the 120-day alert still applies — distributors
often take returns for credit months ahead of expiry, and a 30-day warning misses
that window. Smaller than the FSMA angle, but easy money.

*(If they have a real pharmacy counter, leave it alone — it's already running
regulated dispensing software.)*

---

## The batch problem — the most important thing you will say

Their spec states the inventory key plainly:

> Product name used as the primary inventory identifier
>
> A matching product name adds quantity to the existing product.

Two deliveries of the same product with different expiry dates get **merged into
one record with one date**. One of those dates is silently lost.

### Demo it live rather than describing it

In the ShelfLife build, scan `0002200000019` (ground beef) and log a batch. The
stock list then shows **two batches of the same UPC with different expiry dates**,
side by side. Then ask him to do the same in his app and watch what happens.

That comparison makes the argument in about fifteen seconds, and it does it
without you having to criticise the build.

### Then explain the blast radius

Everything downstream inherits it — the expiration dashboard, the waste numbers,
the supplier shelf-life averages, and any FSMA 204 record. It's the first thing
to fix, and every day it waits, more inaccurate data accumulates.

**Lead with the praise.** Their supplier dashboard — average shelf life received,
losses attributed by supplier — is genuinely sharp, and most inventory tools
never make that connection. Say so. Then note that those numbers only become
trustworthy once batches exist.

---

## "Why not just buy something off the shelf?"

He or his accountant will ask. Full detail in [MARKET.md §2](MARKET.md).

**The incumbent is Upshop** — formerly Date Check Pro, which also absorbed
Whywaste and Invafresh. 50,000+ stores, and it includes an FSMA 204 module.
Take it seriously rather than dismissing it.

**Why it probably doesn't fit one independent store:**

- Third-party directories list **$2,700 per user per year**. Vendor publishes
  nothing — enterprise quote only.
- Independent analysis: *"clearly built for multi-store chains, making it a
  difficult investment for smaller independent grocers."*
- Their iOS app was **last updated February 2023** — over three years stale.
  3.3★ from 6 ratings.
- Onboarding "requires significant buy-in and training for store-level employees."

**Say this plainly:** *if the build costs more than a few years of a subscription,
buying wins — and I'll tell you if that's where the numbers land.* Offering that
up front buys more credibility than any feature list.

The real argument for building: he already owns an app shaped around how his
store actually runs, and the gaps are narrow.

---

## The framing to use for the problem itself

Don't describe this as "staff miss items on the shelf walk." Use the industry
number — [Scandit](https://www.scandit.com/blog/the-expiry-date-problem/):

> Only about **30% of perishable items ever get their expiry date captured into a
> store system. The other 70% are invisible.**

Because expiry dates are printed text, not encoded in the barcode — so someone
has to read and type every one. That friction is why coverage stalls.

His problem isn't the walk. It's that most of his perishable stock was never in a
system to walk in the first place.

---

## If he wants to salvage the OCR work

Point him at **[Scandit Smart Label Capture](https://www.scandit.com/products/smart-label-capture/)**
rather than building a vision backend: it reads the barcode and the printed date
**in one capture**. Claims 4 seconds → 1 second per item. Walmart has run it
since 2022.

That de-risks the exact feature that stalled his project, and it's a licence
rather than a build.

Also worth telling him: **his instinct to make OCR review-only was right.** Every
credible implementation treats OCR as a suggestion needing confirmation — glare,
curved packaging and lot codes that look like dates make it unreliable. He got
that call correct.

---

## Depth signals — what to raise unprompted

These demonstrate you understand the domain better than the prototype does:

- **Same UPC, different expiry.** Batches, not products. The prototype almost
  certainly doesn't model this.
- **Fresh goods can't be alerted, they must be rounded.** A 2–3 day case life
  makes a 30-day warning meaningless.
- **Freezing creates a new batch.** Case-aged product moved to the freezer gets a
  new clock and a "previously frozen" label — USDA-regulated, and tracked rather
  than lost.
- **Donation is a resolution, not a write-off.** Good Samaritan Act protection
  makes it a first-class action alongside markdown and discard.
- **The catalog builds itself.** Unknown UPC gets typed once, never again.
- **Offline.** Back rooms and walk-ins have bad wifi. Scanning has to work anyway.
- **Temp logs.** Staff are already in the app for rounds — capturing chiller temps
  replaces a clipboard that inspectors ask for.
- **Nobody models batches properly.** Across every consumer app researched, only
  one even mentions lot codes. It's a real differentiator, not table stakes.
- **Don't bother with a markdown marketplace.** Stop & Shop and Giant both ended
  Flashfood in June 2025 — Giant cited low customer engagement and went back to
  in-house yellow-tag markdowns. Keep markdown inside his own app.

---

## Do not commit to

- **A price**, before you have seen the source. The batch retrofit could be a
  week or a month depending entirely on how the inventory code is structured.
- **A delivery date**, before the alert channel is decided — SMS integration is a
  different amount of work to push-only
- **An opinion on the OCR feature**, before you know what it cost them to build.
  Recommending they drop it may well be right, but find out what's sunk first.
- **FSMA 204 compliance as a guarantee.** You're building a tool that captures the
  required records. Whether their overall program satisfies FDA is between them
  and their counsel. Say it plainly in the room — it costs nothing and protects
  you later.

Say instead: *"Let me look through the source and I'll come back with scope and
timing."*

---

## Recommendation to land

**Extend their build. Don't rebuild.**

Reason to give:

> You've got real work here — the PWA shell, the roles, the dashboards, purchase
> orders, the audit log. Rebuilding that would take months and wouldn't come back
> better. What's missing is concentrated in two places: how batches are stored,
> and the fact that every phone holds its own separate copy of the inventory.
> Fix those two, add barcode scanning, and you have a product.

Work order to propose — full reasoning in [ASSESSMENT.md §6](ASSESSMENT.md):

1. Batch / lot model *(schema — everything depends on it)*
2. Barcode scanning *(small, visible, answers the original complaint)*
3. Shared database *(without it, more than one user is impossible)*
4. FSMA 204 lot code + export
5. Category profiles and fresh rounds *(only if they carry fresh departments)*
6. Photo OCR — a deliberate decision, not a default
7. Server-side auth and scheduled delivery, before production

### Position the ShelfLife build carefully

It is **not** a replacement and shouldn't be shown as one. It's a working
reference implementation of the three things theirs is missing. Demo it, then
offer to port those pieces across.

That's an easier conversation than "throw yours away" — and it happens to be the
honest answer.
