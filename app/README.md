# ShelfLife — demo build

Phase 0 + core of Phase 1 from [../PLAN.md](../PLAN.md). Zero dependencies, no
build step, ES modules. Data persists to `localStorage`.

```
app/
├── index.html
├── _serve.mjs        local static server
├── css/tokens.css    design tokens
├── css/app.css       components
└── js/
    ├── catalog.js    category profiles, transitions, Open Food Facts lookup
    ├── store.js      data layer + urgency calculation
    ├── scanner.js    BarcodeDetector → ZXing fallback, secure-context diagnostic
    ├── ui.js         rendering
    └── main.js       wiring
```

## Run locally

```bash
node shelflife/app/_serve.mjs 8128
```

Then open `http://localhost:8128`. `localhost` is a secure context, so the camera
works here.

## Demo it on a phone

**It must be served over HTTPS.** A LAN address like `http://192.168.1.50:8128`
will not get camera access — that is the failure the app diagnoses on its own
first screen, and almost certainly what broke the original prototype.

Easiest options:

- Drag the `app/` folder onto [Netlify Drop](https://app.netlify.com/drop)
- `npx vercel --prod` from inside `app/`
- `cloudflared tunnel --url http://localhost:8128` for a throwaway HTTPS URL

## What it demonstrates

| | Where to look |
|---|---|
| Phone scanning actually works | Scan tab → "Scan a barcode" |
| Why the old prototype didn't | Green/red diagnostic banner at the top of Scan |
| Same UPC, different expiry | Scan `0002200000019` twice with different dates |
| Printed vs computed expiry | Switch category in the receiving form — the date field changes |
| FSMA 204 lot capture | Pick any category marked **FTL** — lot code field appears |
| OTC return window | Alerts tab → Ibuprofen flags at 96 days, not 30 |
| Fresh goods as a worklist | Rounds tab |
| Freeze spawns a new batch | Rounds → Freeze → check Stock for "(previously frozen)" |

`Enter a UPC manually` lets you demo without a physical barcode.
`Reset demo data` restores the seeded inventory.

## Not built yet

Auth, multi-device sync, the offline queue, scheduled alert delivery, onboarding,
and reporting. See [../PLAN.md](../PLAN.md) §8 for the phased scope.

The data layer is deliberately isolated in `store.js` so Phase 1 can swap
`localStorage` for Supabase behind the same interface.
