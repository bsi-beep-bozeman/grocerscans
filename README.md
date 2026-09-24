# Al Safa Market OS — Assessment & Reference Build

Working repository for the Al Safa Market grocery expiration-tracking engagement
(US, East Coast).

The client has an existing application — **Al Safa Market OS** — and reported
that its phone scanning feature doesn't work. This repo holds the assessment of
that build, the domain research behind it, and a small working reference app
demonstrating the three capabilities it's missing.

---

## Start here

| Document | What it's for |
|---|---|
| **[RESUME.md](RESUME.md)** | **Paste-able prompt to restore full context after a reset.** |
| **[ASSESSMENT.md](ASSESSMENT.md)** | Gap analysis of their build. Read this first. |
| [MARKET.md](MARKET.md) | Competitive research — incumbents, build-vs-buy, UX lessons, state law |
| [MEETING.md](MEETING.md) | Agenda, diagnostic script, questions, what not to commit to |
| [PLAN.md](PLAN.md) | Domain model, category profiles, FSMA 204, schema, phasing |
| [reference/AL_SAFA_MARKET_OS.md](reference/AL_SAFA_MARKET_OS.md) | Their documentation, as supplied |
| **[app_flutter/](app_flutter/)** | **Current deliverable — Flutter native app (Android + Web)** |
| [product/supabase/](product/supabase/) | Backend — schema, RLS, RPCs, seed (shared, stack-agnostic) |
| [product/js/](product/js/) *(deprecated)* | Vanilla-JS PWA shell — kept as port reference, will be removed |
| [app/](app/) | Original scrappy demo — reference twin, not the deliverable |

---

## The three findings

**1. Scanning fails because the vision backend was never built.** Their feature
is photo OCR, not barcode scanning, and it points at a `VISION_ENDPOINT` that
doesn't exist. An HTTPS/secure-context problem may sit underneath it, but that's
secondary. *Earlier assumption corrected —
[ASSESSMENT.md §1](ASSESSMENT.md).*

**2. There is no batch model, and that's the critical flaw.** Their inventory is
keyed on product name, and a matching name adds quantity to the existing record.
Two deliveries with different expiry dates merge into one, and one date is
silently lost. Everything downstream inherits the error.
*[ASSESSMENT.md §3](ASSESSMENT.md).*

**3. They bet on the hard half of scanning and skipped the easy half.** Reading
expiry dates off packaging by OCR is genuinely difficult. Scanning the UPC is
essentially solved, and it removes the most tedious field to type.
*[ASSESSMENT.md §2](ASSESSMENT.md).*

---

## Recommendation — SUPERSEDED

The original recommendation was *"extend their build"* — that was withdrawn in
a subsequent session after the meeting outcome. The engagement then pivoted
twice:

1. **Pivot 1:** extend → build fresh Supabase-backed PWA (produced
   `product/js/*` and `product/supabase/*`)
2. **Pivot 2:** vanilla-JS PWA → Flutter native (current — `app_flutter/`).
   The scanner-heavy use case on iOS Safari and older Android made native
   ML Kit the objectively better call.

**Current deliverable: [app_flutter/](app_flutter/) (Flutter) + [product/supabase/](product/supabase/) (backend).** See [RESUME.md](RESUME.md) for the authoritative resume prompt and current state.

---

## Boot the Flutter app (web build)

```bash
cd app_flutter
D:\dev\flutter\bin\flutter.bat build web --release
```

Then in the desktop app's Browser pane, use `preview_start` with
`name: "shelflife-flutter"` — serves on http://localhost:8131.

Full instructions in [app_flutter/README.md](app_flutter/README.md).

---

## Open questions blocking scope

**Which state is the store in?** There is no federal date-labeling law except for
infant formula — it's state law, and East Coast states differ sharply. In
Pennsylvania milk cannot be sold past its sell-by date at all; New York is far
more permissive. Which resolution actions are legal — markdown, donate, neither —
is set by state, so the category profiles can't be finalised without it.
*[MARKET.md §8](MARKET.md).*

**Their source code.** Only their documentation has been reviewed. The batch
retrofit could be a week or a month depending on how the inventory code is
structured, and there's no way to tell from a README.

---

## Status

- Assessment complete against their documentation
- Market research complete — see [MARKET.md](MARKET.md)
- Reference build working and verified
- Blocked on the two questions above before scope or pricing
