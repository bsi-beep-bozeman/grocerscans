# Cockpit concept 01

Published on Sites on 2026-09-29:
https://shelflife-cockpit-preview.ppdpainting-4984.chatgpt.site

Access is currently owner-only (sign in with the publishing account). The
hosting checkout is `../site-preview/`, with its identity saved in
`.openai/hosting.json`. Reuse that Site for future demo updates. The hosted
copy is a static snapshot; rebuild Flutter and update the hosting checkout
before republishing changes.

An isolated Flutter design preview. The existing production entry point and
authentication are unchanged. No Supabase initialization, external writes, or
real inventory changes occur in this preview.

## Open locally

```powershell
flutter build web --release --no-web-resources-cdn --target lib/preview.dart
node serve-preview.mjs
```

Open http://127.0.0.1:8132. Desktop gets a sidebar and two-column cockpit;
phones get bottom navigation and a scan-first layout.

## Phone build

After installing/configuring the Android SDK:

```powershell
flutter run --target lib/preview.dart -d <android-device-id>
flutter build apk --release --target lib/preview.dart
```

Android SDK is not present in the recorded project setup. An APK has not been
verified. iOS remains deferred and requires a Mac plus an iOS project target.
The web output can be deployed to HTTPS hosting for phone-browser use; localhost
on this computer is not a phone-accessible deployment.

## What works

- Responsive cockpit, inventory search, and a session-only freshness checklist.
- Camera via the existing mobile_scanner package; permission/error fallback.
- Local source: exact lookup against twenty sample catalog records. UPC-A is normalized to its
  zero-prefixed EAN-13 form. Internal SKUs are manually entered or barcode encoded.
- Review a catalog match, select expiry, validate quantity, and add a session-only
  activity entry. Reloading resets the preview; this is not persistent inventory.
- See [twenty-product CSV](demo-data/catalog-20.csv) and [data notes](demo-data/README.md).
  Primary UPCs are synthetic, checksum-valid demo identifiers, not verified
  retail assignments. The original five codes remain compatibility aliases.
  Quantities and days remaining are fictional scenarios, not store policies.
- The hosted September snapshot still has five products. The twenty-product
  local source has not been rebuilt or republished.

## Design system

Near-white surfaces, dark slate typography, 22 px card radii, generous spacing,
large expiry numerals and 56 px primary controls. Amber means attention, green
means outside the alert window. Dark camera surfaces distinguish capture from
inventory review. Product icons are illustrative category markers.

## Deliberate boundaries

The scanner decodes barcode values; it does not visually infer arbitrary printed
SKUs or read printed expiration dates. Unknown codes remain unknown. Production
catalog integration, OCR, persistent offline queue, PIN attribution, stock writes,
and publication remain separate work. Camera access on phone browsers requires
HTTPS and permission; real-device recognition must be tested on a phone.
