# Assessment — Al Safa Market OS

Analysis of the client's existing build, from their own documentation
([reference/AL_SAFA_MARKET_OS.md](reference/AL_SAFA_MARKET_OS.md)).

**Headline: this is far more built than the brief suggested, and the earlier
recommendation to rebuild was wrong. Extend it.**

---

## 1. Correcting the scanning diagnosis

The pre-meeting assumption was that phone scanning failed because the page was
served over `http://`, which blocks camera access. That was a reasonable guess
from the symptom. **It is probably not the main cause.**

Their documentation says the feature is **"Scan Product by Photo"** — camera
capture followed by OCR / AI vision to extract product name, brand, expiration
date, and size. It is not barcode scanning.

And the operative line:

> Production OCR or AI vision requires a secure backend endpoint configured
> through `VISION_ENDPOINT` in `app.js`.

**So the scan doesn't work because the vision backend was never built.** The
capture, review, confidence and storage workflow all exist; the extraction step
is a stub pointing at an endpoint that doesn't exist. That's an architectural
gap, not a bug.

The HTTPS issue may still be a *second*, independent problem — camera capture
itself needs a secure context, so if he opens it at a LAN address the photo step
fails before OCR ever matters. Worth checking both. But lead with the endpoint.

### Still worth testing live

1. What URL does he open on the phone? (`http://<ip>` → camera blocked too)
2. Does the camera *open* at all? If yes, the capture layer is fine and it's
   purely the missing endpoint. If no, there are two problems stacked.
3. Is `VISION_ENDPOINT` set to anything in `app.js`?

---

## 2. Photo OCR was the hard bet; barcode was the easy one

Their build went after the difficult half of the problem and skipped the
reliable half.

**Reading expiry dates by OCR is genuinely hard on grocery packaging:**
inkjet-printed low-contrast characters, curved and reflective surfaces, dates on
bag crimps and can bottoms, and no consistent format — `MAR 15 26`,
`03/15/26`, `15MAR2026`, `BEST BY 031526`, plus Julian and lot codes that look
like dates but aren't. Accuracy will be mediocre and variable by product.

Their design already concedes this, correctly: results are never auto-saved, and
low-confidence fields are left blank. That's good judgment. But it creates an
economics problem — if staff must review every field anyway, and OCR only gets
the date right some of the time, the labour saved over typing is thin.

**Barcode scanning of the UPC, by contrast, is essentially solved.** Near-100%
reliable, instant, works offline once the catalog is cached, and it resolves
product identity — the field most tedious to type.

The right architecture uses both:

| Field | Best source | Reliability |
|---|---|---|
| Product identity | **Barcode (UPC)** | Very high |
| Expiry date | Typed, OCR-assisted | Moderate — always human-confirmed |
| Quantity | Typed | — |
| Lot code | Typed or case-label scan | High if GS1 |

Barcode is the cheap win they left on the table. It is also roughly 100 lines of
code — see [app/js/scanner.js](app/js/scanner.js).

---

## 3. The critical flaw: no batch model

From their spec:

> Product name used as the primary inventory identifier

> A matching product name adds quantity to the existing product.

**This means two deliveries of the same product with different expiry dates are
merged into a single record with a single expiration date.**

That breaks the core premise of the entire application. A store receives Del
Monte corn in March and again in August; those are two batches with two
different clocks. Merging them means one of the two dates is simply lost — and
the system will either raise a false alarm or, worse, stay silent on stock that
has actually expired.

Everything downstream inherits the error: the expiration dashboard, the waste
figures, the supplier shelf-life averages, and any FSMA 204 record.

**This is a schema problem, not a feature gap.** Products must have many batches:

```
Product (UPC / name)
 ├── Batch A  50 units  exp 2027-03-01  lot 8841  received 2026-09-02
 ├── Batch B  30 units  exp 2026-08-15  lot 9120  received 2026-06-11
 └── Batch C  20 units  exp 2028-01-20  lot 3355  received 2026-09-20
```

It is fixable without a rebuild, but it touches intake, receiving, markdown, and
every dashboard. It should be the first work item, before any new features.

See [app/js/store.js](app/js/store.js) for a working batch model, and
[PLAN.md §5](PLAN.md) for the full schema.

---

## 4. Gap matrix

| Capability | Al Safa Market OS | ShelfLife reference | Action |
|---|---|---|---|
| PWA: manifest, service worker, offline cache, icons, install | ✅ Complete | ➖ Not built | **Keep theirs** |
| Role-based access (Owner / Manager / Employee) | ✅ Complete | ➖ | **Keep theirs** |
| Product CRUD, search, filter | ✅ Complete | Partial | **Keep theirs** |
| Owner / Executive / Supplier dashboards | ✅ Complete | ➖ | **Keep theirs** |
| Purchase orders | ✅ Complete | ➖ | **Keep theirs** |
| Activity log / audit trail | ✅ Complete | ➖ | **Keep theirs** — needed for FSMA anyway |
| Markdown tracking, waste-avoided | ✅ Complete | ➖ | **Keep theirs** |
| Receiving log, auto shelf-life calc | ✅ Complete | Partial | **Keep theirs** |
| Rules-based insights | ✅ Complete | ➖ | **Keep theirs** |
| CSV export | ✅ Complete | ➖ | **Keep theirs** |
| **Batch / lot model** | ❌ Merges by name | ✅ Working | **Port in — first priority** |
| **Barcode scanning** | ❌ Optional field only | ✅ Working | **Port in — cheap** |
| **Shared database** | ❌ localStorage only | ❌ localStorage only | **Build — Supabase** |
| Photo OCR extraction | ⚠️ Stub, no endpoint | ➖ | Decide: build, defer, or drop |
| Printed vs computed expiry | ❌ One model for all | ✅ Working | Port in |
| Fresh-goods daily rounds | ❌ | ✅ Working | Port in if they carry fresh |
| Freeze / convert batch spawning | ❌ | ✅ Working | Port in if they carry fresh |
| FSMA 204 traceability lot code | ❌ | ✅ Working | Port in — see [PLAN.md §4.4](PLAN.md) |
| Server-side auth | ❌ Browser PINs | ❌ | Build before production |
| Scheduled email / push delivery | ⚠️ Drafts only | ❌ | Build |

They have acknowledged most of the production gaps themselves in their
"Production Requirements" section. That's a good sign about who built it.

---

## 5. Their supplier dashboard is the sharpest thing in the build

Worth saying out loud in the meeting, because it's genuinely good and it signals
you actually read their work:

- Average shelf life received, per supplier
- Products received already expired or near expiry
- Inventory losses attributed by supplier

That reframes expiry from a store problem into a **supplier accountability**
problem. If one distributor consistently delivers product with 40% of its shelf
life already burned, that's a negotiating position — or grounds to switch.

Most inventory tools never make that connection. Praise it, then note that it
only produces trustworthy numbers **once batches exist** — right now the averages
are computed over merged records.

---

## 6. Revised recommendation

**Extend their build. Do not rebuild.**

The earlier rebuild recommendation assumed a thin prototype whose data model
wasn't worth saving. That assumption was wrong: the dashboards, roles, PWA
shell, purchase orders, and audit log represent real work that would take months
to reproduce and would come back no better.

Suggested order of work:

1. **Batch / lot model** — schema change. Everything else depends on it, and
   every day it waits, more inaccurate data accumulates.
2. **Barcode scanning** — small, high-visibility, and directly answers the
   complaint that started this engagement.
3. **Shared database** — Supabase. Without it, each staff phone holds a separate
   inventory, which makes the whole tool unusable with more than one person.
4. **FSMA 204 lot code + export** — small once batches exist, and it's the
   commercial argument ([PLAN.md §4.4](PLAN.md)).
5. **Category profiles / fresh rounds** — only if they carry fresh departments.
6. **Photo OCR** — decide deliberately. It carries ongoing API cost and
   uncertain accuracy. Barcode plus typed dates may be enough.
7. **Server-side auth, scheduled delivery** — before production.

### How to position the ShelfLife build

Not as a replacement. As a **working reference implementation** of the three
things theirs is missing: barcode scanning, the batch model, and the two-mode
expiry split. Demonstrate it, then offer to port those pieces into their
codebase.

That is a much easier conversation than "throw yours away," and it's also the
honest answer.

---

## 7. What to ask for

To scope the port properly, request:

1. **The source code**, not just this document — particularly `app.js` and
   whatever holds the inventory schema
2. Whether it's in version control anywhere
3. Who built it, and whether they're still available
4. Whether any real inventory has been entered yet (migration work if so)
5. How many staff, and whether they've tried to use it simultaneously
   *(this is where the localStorage limitation will have bitten already)*
