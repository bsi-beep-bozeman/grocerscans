# Market Research — published apps and commercial tools

Researched September 2026. Every statistic below traces to a source; vendor
claims are labelled as such because **no independent verification of any vendor
ROI figure exists in this category.**

---

## 1. The category has one incumbent, and it ate the competition

Three products that look like alternatives are now the same company:

- **Date Check Pro** (Applied Data Corp) → rebranded **Upshop Expiration Date Management**
- **Whywaste** (Sweden) → acquired by Invafresh, Oct 2023
- **Invafresh** → merged with Upshop, [July 2024](https://upshop.com/upshop-and-invafresh-merge-to-transform-global-food-retail-technology)

Combined: 400+ retailers, 35 countries, 50,000+ stores. Customers include ASDA,
Tesco One Stop, SPAR, Coop Sweden, ICA, Cub Foods, Piggly Wiggly.

**Shelf Engine** exited separately — [acquired by Crisp, March 2025](https://www.geekwire.com/2025/seattle-startup-shelf-engine-acquired-by-retail-data-company-crisp/).
It was never a date-checking tool anyway; it's demand forecasting, which reduces
the *volume* of near-expiry stock rather than managing it. Same category as
**Afresh**. Both are upstream of this problem, not competitors to it.

Worth knowing: **grocery POS suites do not do this.** A read of the full
[ECRS CATAPULT feature list](https://www.ecrs.com/retail-pos/feature-list/)
turns up no expiration, shelf-life, lot, batch, or traceability features. Same
for LOC Software, IT Retail, Toshiba, NCR. Date checking is consistently a
bolt-on from a specialist. That's why this project exists at all.

---

## 2. Build vs buy — answer this before he asks

He will ask, or his accountant will. Have the answer ready.

**The case for buying Upshop:** proven at 50,000 stores; includes an FSMA 204
module and [ReposiTrak partnership](https://www.businesswire.com/news/home/20250114222704/en/);
donation tax-deduction tracking is built in; Cub Foods (55 stores) expected
$1.5M annual shrink savings after a four-week rollout.

**The case against, for a single independent store:**

| Signal | Source |
|---|---|
| **$2,700 per user per year** listed | [Capterra](https://www.capterra.com/p/134931/Date-Check-Pro/), [SourceForge](https://sourceforge.net/software/product/Date-Check-Pro/) — third-party directories, not the vendor. Treat as indicative only. |
| "Clearly built for multi-store chains, making it a difficult investment for smaller independent grocers" | [appintent analysis](https://www.appintent.com/software/grocery/operations/) |
| iOS app last updated **February 2023** — over three years stale | [App Store](https://apps.apple.com/us/app/date-check-pro-2/id1317947591) |
| **3.3★ from 6 ratings.** One review on sync: *"It should absolutely not take 30 minutes to hours for it to update."* | ibid. |
| Onboarding "requires significant buy-in and training for store-level employees" | appintent |
| Upshop publishes no pricing — enterprise quote only | — |

**Honest framing to give him:** the incumbent is priced and built for chains. For
one store you're likely over-buying. But quote the build honestly — *if the
development cost exceeds a few years of subscription, buying wins*, and you
should say so rather than sell him a build.

The genuine argument for building: he already owns a half-finished app with
dashboards shaped around how his store actually runs, and the missing pieces are
narrow and well-understood.

---

## 3. The real problem statement — the 70% nobody captures

The single most useful statistic found, from
[Scandit's analysis](https://www.scandit.com/blog/the-expiry-date-problem/):

> Only **~30% of perishable items have expiry dates captured in store systems.
> 70% of perishables are effectively invisible.**

Because expiry dates are **printed text, not encoded in 1D barcodes**. Staff must
scan the barcode, then separately read and type the date. That friction is why
coverage stalls at 30%.

This also quietly undercuts every vendor ROI claim in the category — they're
measured on the covered minority.

Use this as the framing in the meeting. His problem isn't that staff miss items
on the shelf walk. It's that most of his perishable stock was never in a system
to be walked.

---

## 4. Scandit — the answer to their stalled OCR feature

Their `VISION_ENDPOINT` was never built. Rather than building vision from
scratch, there's a product for exactly this:

**[Scandit Smart Label Capture](https://www.scandit.com/products/smart-label-capture/)**
reads the **barcode and the printed expiry date in a single capture**.

- Claims 60% reduction in per-item capture time; **4 seconds → 1 second per SKU**
- 2,100+ customers; Walmart deployed since 2022 across 1.3M associates
- SDKs for iOS, Android, web, React Native, Flutter, .NET
- No published pricing — enterprise quote

This is the technically correct shape: barcode for identity (reliable), OCR for
the date (assisted, human-confirmed). Worth raising as a licensing option instead
of building — it de-risks the one feature that stalled their project.

---

## 5. What consumer apps teach — nine documented ways this fails

Research across NoWaste (4.2★/751), Pantry Check (4.5★/1.6K), KitchenPal
(4.5★/635), BEEP (4.1★/238) and others. The 1–3★ reviews are more valuable than
any feature list.

| # | Documented complaint | Design rule | Our build |
|---|---|---|---|
| 1 | **Per-item step count** is the top abandonment driver — not scan speed. Edit → quantity → amount → type → next. | Minimise taps after a scan. Known product should be near one-tap. | ✅ name + category prefill |
| 2 | **Bulk-add crash loses the whole session.** 20+ items entered, all gone, user never returns. | Persist every item immediately, never at the end. | ✅ writes per batch |
| 3 | **Barcode hit rate as low as ~20%** in practice. Produce, deli, bulk and store-brand have no usable barcode. | Manual path must be first-class, not a fallback. | ⚠️ present, needs work — [PLAN §4.2](PLAN.md) |
| 4 | **Wrong auto-estimates erode trust faster than no estimate.** Items defaulting to "expires today." | If you compute a date, show the rule that produced it. | ✅ "3-day shelf life. Expiry is calculated, not typed." |
| 5 | **Notifications that fire inside the app but not to the OS** (NoWaste) — defeats the entire product. | Alerts must leave the app. | ❌ not built |
| 6 | **Date pickers that forbid past dates.** Verbatim review: *"Forgot to enter that one milk you bought 2 days ago? Then this app will help you drink it 2 days after expiration."* | Never set `min` on an expiry or received-date input. | ✅ verified — no `min` set |
| 7 | **Receipt OCR consistently unreliable** — "gibberish" across NoWaste and Fridgely. | Don't build it. | ✅ avoided |
| 8 | **Data loss during migration** produces the angriest reviews. | Export before any schema change. | ⚠️ relevant to the batch retrofit |
| 9 | **Subscription fatigue** — repeated demand for one-time purchase. | N/A — he owns the software. | ✅ |

Rule 6 is worth dwelling on: a naive `minimumDate = today` on a date picker
produces a **food-safety harm**, not a UX annoyance. It's one line of code and
every developer's instinct gets it wrong.

### On OCR specifically

[fridgiary's own documentation](https://www.fridgiary.com/guides/scan-expiration-date-from-photo)
is unusually candid about failure modes: glare on glossy packaging, curved
surfaces, embossed ink, unusual fonts, and **misreading lot codes, production
dates and prices as expiry dates**. It cannot distinguish a safety date from a
quality date from a manufacturing code.

Every serious implementation therefore treats OCR as a *suggestion requiring
human confirmation* — which is exactly what Al Safa Market OS already specifies.
**That design judgement was correct** and is worth telling him.

But note: **no app with meaningful review volume actually ships expiry OCR.**
Those that do have 1–3 ratings. So there is no evidence either way on whether it
works at scale. It's an unvalidated bet, not a proven win.

---

## 6. Nobody models batches — confirmed differentiator

Across every consumer app researched, **only one** (ExpiresBy, 3 ratings)
mentions lot/batch extraction at all. None properly model "three yogurts, two
expiring Friday and one next Tuesday" as distinct instances. Quantity is a scalar
attached to a single date — **exactly the flaw in Al Safa Market OS**.

On the commercial side, only **[Shelflife.ai](https://shelflife.ai)** explicitly
offers markdowns per expiration-date batch rather than per SKU, with stock counts
broken out by expiry. No named customers, no pricing — small player.

Also worth confirming: **Open Food Facts has an `expiration_date` field, but it's
crowd-sourced and typically empty** (`en:expiration-date-to-be-completed`). It
cannot serve as a per-package expiry source. Our design — OFF for identity only,
never for dates — is correct.

**So the batch model is a genuine differentiator, not table stakes.** That's
unusual and worth saying plainly in the meeting.

---

## 7. Markdown recovery — Flashfood retreated from the East Coast

**This correction matters, because most secondary sources are stale.**

- **Stop & Shop ended** its Flashfood partnership — final day **June 22, 2025**
- **The GIANT Company ended** its five-year partnership late June 2025, citing
  **low customer engagement**, and reverted to its in-house **yellow-tag
  markdown programme**
  ([abc27](https://www.abc27.com/local-news/giant-company-discontinues-flashfood-partnership/),
  [LevittownNow](https://levittownnow.com/2025/07/28/low-usage-cited-as-giant-food-stores-discontinues-flashfood-app/))

Ahold Delhaize's affected Northeast banners total 500+ stores across eight
states. Flashfood's [current partner list](https://flashfood.com/en/locations)
retains Tops, Martin's, Giant Eagle and Kroger Mid-Atlantic — but **Stop & Shop,
Giant and Food Lion are gone.**

**Too Good To Go is going the other way** — Whole Foods expanding to
[all 536 US stores](https://www.cnbc.com/2025/11/12/too-good-to-go-whole-foods-grocery-surprise-bags.html),
seven new categories added November 2025. Roughly $1.79 per bag plus ~$89/year
(secondary sources — verify directly).

**Read for this client:** a third-party markdown marketplace is not obviously the
answer on the East Coast right now. Giant — a sophisticated operator with scale —
concluded in-house markdown was cheaper per unit recovered. For a single
independent store with less app-user density nearby, that conclusion probably
holds harder.

**Markdown belongs inside his own app.** Which is where it already is.

---

## 8. Donation — and the legal trap I got wrong

> **Not legal or tax advice.** Statutory summary only. Date-labeling rules are
> state and often local, change frequently, and interact with health-department
> enforcement practice. Confirm every point with counsel and a CPA.

[PLAN.md](PLAN.md) presents donation as a clean alternative to write-off under
Good Samaritan protection. That was **too simple**, and the correction is
important.

**The Bill Emerson Good Samaritan Food Donation Act** ([42 U.S.C. § 1791](https://www.law.cornell.edu/uscode/text/42/1791))
protects donation of "apparently wholesome food" — but that term is defined as
food that **"meets all quality and labeling standards imposed by Federal, State,
and local laws."**

**So if state law prohibits donating a past-date item, federal protection may not
attach.** The shield is conditioned on state compliance, not a substitute for it.
Immunity also excludes gross negligence and intentional misconduct.

The **Food Donation Improvement Act of 2023** ([PL 117-362](https://www.govinfo.gov/app/details/PLAW-117publ362))
did expand things usefully — a grocer can now donate **directly to needy
individuals** without routing through a 501(c)(3). But it did not touch the
"meets all standards" precondition.

**The enhanced deduction under [IRC §170(e)(3)](https://policyfinder.refed.org/federal-policy/federal-tax-incentives)**
— lesser of (basis + ½ appreciation) or (2 × basis), capped at 15% of taxable
income, five-year carryforward — carries **the same "apparently wholesome"
precondition.**

> **A state date-label violation can forfeit the liability shield and the tax
> deduction simultaneously.** This is the highest-value item to put in front of
> his counsel.

### East Coast state restrictions

There is **no federal date-labeling law** except for infant formula. Everything
is state law, and East Coast states differ sharply. Harvard FLPC / ReFED classify
23 states as "negative policy."

| State | Rating | Restricted for sale | Restricted for donation |
|---|---|---|---|
| **MA** | Negative | dairy, eggs, shellfish, meat, sandwiches, infant formula, bakery, perishables, ROP, TCS | ROP, TCS |
| **PA** | Negative | dairy (**milk cannot be sold past sell-by/best-by**), ROP, TCS | ROP, TCS |
| **NJ** | Negative | dairy, ROP, TCS | ROP, TCS |
| **MD** | Negative | dairy, hazardous foods, ROP, TCS | hazardous bakery, ROP, TCS |
| **NY** | Moderate | ROP, TCS | ROP, TCS |
| **CT** | Moderate | ROP, TCS only — past-date dairy may still be sold | ROP, TCS |

*ROP = reduced oxygen packaging. TCS = time/temperature control for safety.*
Source: ReFED Policy Finder / Harvard FLPC. **Verify against primary state
regulation.** ME, NH, VT, RI, DE, VA, NC not yet researched.

**Three operational consequences:**

1. **ROP and TCS foods cannot be sold *or* donated past date in every East Coast
   state checked.** Vacuum-packed and refrigerated ready-to-eat are the hard stop
   everywhere. The app must know this and must not offer Donate or Markdown on
   those categories past date.
2. **Massachusetts provides a blueprint.** Past-date food may be sold if it (a)
   remains wholesome with sensory qualities not significantly diminished, (b) is
   **segregated** from other food, and (c) is **clearly marked as past date.**
   That's a compliant markdown-zone design, spelled out in statute.
3. **New Jersey contains an apparent conflict** — its liability statute permits
   donating past-date food "regardless of compliance with regulations on quality
   or labeling," while its food-safety regulation restricts ROP/TCS donation.
   Flag to counsel.

### ⚠️ We need to know which state

"East Coast" is not specific enough to build against. **MA and NY differ
enormously.** This is now a blocking question for the category profiles — add it
to the top of the meeting list.

---

## 9. What this changes

| Finding | Action |
|---|---|
| Category consolidated; incumbent priced for chains | Have the build-vs-buy answer ready (§2) |
| 70% of perishables never captured | Use as the framing of the problem, not "staff miss things" |
| Scandit reads barcode + date in one capture | Offer as a licensing option for their stalled OCR (§4) |
| Nine documented UX failure modes | Applied — see the table in §5 |
| Date pickers forbidding past dates cause harm | Verified absent from our build |
| Nobody models batches properly | Confirmed differentiator — lead with it |
| Flashfood left Stop & Shop and Giant in 2025 | Don't recommend a marketplace; keep markdown in-house |
| Emerson protection is conditioned on state law | **Categories must gate Donate/Markdown by state rule** |
| State date rules vary sharply across the East Coast | **Ask which state before finalising category profiles** |
