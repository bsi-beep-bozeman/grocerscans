# Resume prompt

Paste the block below into a fresh Claude Code session after a context reset.
Everything else in this repo is the context it needs — the prompt just points at
it and carries the decisions that aren't obvious from the files.

---

## Copy this

```text
I'm resuming the Al Safa Market OS engagement. The working repo is:

D:\LLM-Data\Claude-Desktop\claude-code\shelflife

Read these first, in this order, before responding:
1. README.md      — orientation and open questions
2. ASSESSMENT.md  — gap analysis of the client's existing build
3. MARKET.md      — competitive research, build-vs-buy, state date-label law
4. MEETING.md     — meeting kit: agenda, diagnostic, questions
5. PLAN.md        — domain model and schema (partly superseded; see banner)

CONTEXT
A US East Coast grocery store owner has an existing app, "Al Safa Market OS" —
a browser PWA with role-based access, four dashboards, purchase orders, receiving
log, markdown tracking and an audit log. He reported that its phone scanning
feature doesn't work, and asked whether to finish it or rebuild. I'm assessing
it and advising. His documentation is at reference/AL_SAFA_MARKET_OS.md. I have
NOT seen his source code.

There's also a small reference build in app/ — zero-dependency PWA demonstrating
the three things his app is missing: barcode scanning, a batch/lot model, and
the printed-vs-computed expiry split. Run it with:
    node app/_serve.mjs 8128
It is a reference implementation to port from, NOT a replacement product.

DECIDED — don't relitigate these
- Extend his build; do not rebuild. His PWA shell, roles, dashboards, POs and
  audit log are real work worth months.
- The missing batch/lot model is the critical flaw and the first work item.
- Position the reference build as something to port from, never as a rival.
- Markdown stays inside his own app — no third-party marketplace.

CORRECTIONS ALREADY MADE — do not reintroduce the earlier versions
- Scanning fails because the OCR/vision backend was never built (VISION_ENDPOINT
  in app.js points nowhere). It is NOT primarily an HTTPS/secure-context problem,
  though that may sit underneath it as a second issue.
- Donation is NOT a clean alternative to write-off. Good Samaritan Act protection
  is conditioned on meeting all state and local labeling standards, and the IRC
  170(e)(3) deduction carries the same precondition — a state violation can
  forfeit both. ROP and TCS foods can't be sold or donated past date in any East
  Coast state checked.
- PLAN.md section 11 originally recommended a rebuild. That is withdrawn and
  marked as such. Don't act on it.

BLOCKED ON — both needed before scope or pricing
- Which US state the store is in. There's no federal date-labeling law except
  infant formula; PA bars selling milk past sell-by, MA is broad, NY is
  permissive. Category profiles can't be finalised without it.
- His source code, particularly app.js and the inventory schema. The batch
  retrofit could be a week or a month depending on how it's structured.

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

| | |
|---|---|
| Repo | `D:\LLM-Data\Claude-Desktop\claude-code\shelflife` (git, branch `main`) |
| Reference build | `node app/_serve.mjs 8128` → http://localhost:8128 |
| Preview config | `shelflife` entry in `../.claude/launch.json` |
| Client docs | `reference/AL_SAFA_MARKET_OS.md` |

**Done:** assessment against their documentation; market research; reference build
working and verified in-browser.

**Not done:** their source code has not been reviewed. No scope, no estimate, no
price. Meeting not yet held.

**Next actions, in order:**

1. Get his source code and read the inventory schema — everything downstream of
   the batch retrofit estimate depends on it
2. Confirm the state, then finalise the category profiles with per-state
   `allowsDonationPastDate` / `allowsMarkdownPastDate` flags
3. Hold the meeting using [MEETING.md](MEETING.md); demo the two-batches-same-UPC
   comparison live
4. Decide with him whether to licence Scandit Smart Label Capture for the stalled
   OCR feature, or drop OCR and rely on barcode plus typed dates

**Unverified assumptions worth re-checking before quoting:**

- Fresh-category shelf lives in `app/js/catalog.js` (meat 3 days, seafood 2, deli
  3) are my defaults, not checked against USDA guidance or his practice
- The $2,700/user/year Upshop figure is from third-party directories, not the
  vendor
- FSMA 204's July 20 2028 date has moved before — reconfirm before it goes in a
  proposal
