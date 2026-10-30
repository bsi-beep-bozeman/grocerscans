# Proposed publication — ShelfLife client dry run

Status: LOCAL BUILD VERIFIED; HOSTING AND PUBLICATION PENDING.

## Exact proposed action

Create one new **Netlify Free** site for the synthetic ShelfLife client demo, intended account cmzoilot@gmail.com, proposed site name `shelflife-client-dry-run` (availability unverified). Upload only the prepared release bundle, publish its HTTPS Netlify URL for client evaluation without provider login, and run the same dry-run checks against that URL in fresh browser contexts. Confirm account/team before creating the site. Use a provider-generated name if the proposed name is unavailable only when the human approves that fallback.

Artifact: `shelflife-client-dry-run-2026-10-30.zip`, 39 files, SHA256 `F0CBB9D1B03A8CF8C362CC1B02328B712B3D9464BCB5A493AED3B2F76604333C`. Unpacked folder: `.cache/client-dry-run/release`. The root contains `index.html` and `_headers`; upload this folder's contents, not the source repository or its parent.

The site is publicly reachable by anyone with the URL. It contains fictional products and public practice PINs, no private customer data or server credentials. Search indexing is discouraged, which is not access control. Each browser persists its own practice data. The client guide is `/client-guide.html`.

No paid subscription, auto-recharge, custom domain, DNS change, repository push/link, Supabase creation/change, real user provisioning or operational rollout is included. If the selected hosting account requires payment, stop and report the exact cost/options. The Vercel workspace is Hobby and is not selected for this commercial client evaluation.

## Access / approval still needed

The user's original request authorizes preparation and testing of the admin/staff preview. Workspace consent authorized Vercel connection access only. Under AGENTS.md rule 9, exact site publication and client access retain action-specific approval. No Netlify site exists yet, no exact site/team has been verified, and no publication approval for this packet is recorded.

Netlify connector discovery returned no result. Browser control is disabled in Work settings. To perform the action here, the user must enable browser access and sign in to the intended Netlify account, or provide an available authenticated Netlify connection. Do not request pasted credentials. The release ZIP is also ready for an owner-operated manual upload; manual publication is not assumed to have happened.

## Remote verification and rollback

After approval and publication, record actual account/team/site/deploy IDs and URL, confirm HTTPS and anonymous access without a platform login, check `_headers` processing/CSP/robots/guide/assets, then run the eight browser groups against that exact URL. The test creates synthetic browser-local work only and resets it. No service-worker dependency or external runtime asset host is required.

For a new site, rollback means unpublish the exact new deployment/site through Netlify's supported controls; record concrete IDs and mechanism after creation. Preserve the artifact and evidence. Do not remove unrelated sites or change account-wide access. Any remote rollback must stay within explicit publication/rollback authorization; no remote destructive cleanup is pre-approved here. Local reset affects only the isolated demo stores, never the paused database.
