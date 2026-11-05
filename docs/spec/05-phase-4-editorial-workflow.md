# Phase 4 — Editorial Workflow

## Goal

Editors see draft content on the real site, click any text to jump to the field that
produced it, and publishing updates the static site within seconds without a rebuild.

## Deliverables

- Draft mode enable and disable route handlers.
- Presentation tool in the Studio, configured with document locations.
- `VisualEditing` overlays rendered when draft mode is on.
- `/api/revalidate` webhook handler and a configured Sanity webhook.
- Tag-based revalidation wired through every `sanityFetch` call.
- A draft-mode banner on the site with an exit link.
- The site deployed to Vercel (first deployment; the webhook needs a public URL).

## Implementation notes

### Draft mode

- `src/app/api/draft-mode/enable/route.ts` uses `defineEnableDraftMode` from
  `next-sanity/draft-mode` with a client that carries `SANITY_API_READ_TOKEN`. The helper
  validates the secret the Presentation tool sends and enables draft mode.
- `src/app/api/draft-mode/disable/route.ts` calls `(await draftMode()).disable()` and
  redirects to the referrer or `/`.
- `sanityFetch` already switches to `previewDrafts` perspective and disables the CDN
  when draft mode is on. No page changes needed.

### Visual editing

- In the root layout, after `<SanityLive />`, render
  `{(await draftMode()).isEnabled && <VisualEditing />}` from `next-sanity/visual-editing`.
- Stega encoding is already on in the client config from phase 2, and phases 2 and 3
  already pass logic values through `stegaClean`. Values that must not carry stega
  characters (anything used in logic, `href`, `className`, dates) go through `stegaClean`
  from `@sanity/client/stega`. Audit and fix any misses: `difficulty`, `routeType`,
  `status`, slugs, geopoints, and the filter builder's region options.
- `DraftModeBanner` client component: fixed bar reading "Viewing drafts" with a link to
  `/api/draft-mode/disable`. Rendered from the site layout when draft mode is on.

### Presentation tool

In `sanity.config.ts` add:

```ts
presentationTool({
  previewUrl: {
    origin: process.env.NEXT_PUBLIC_SITE_URL,
    previewMode: { enable: "/api/draft-mode/enable" },
  },
  resolve: { locations, mainDocuments },
})
```

`sanity/presentation/resolve.ts` defines:

- `locations` — for `trail`: the trail page, the trail list, and its region page.
  For `region`: the region page and region list. For `siteSettings`: the home page.
  For `trailCondition`: the referenced trail page (resolved with a GROQ `select`).
- `mainDocuments` — route `/trails/:slug` maps to the trail with that slug, and
  `/regions/:slug` to the region, so opening a URL in Presentation selects the document.

Move the Presentation tool first in the plugin list so it is the default Studio tab.

### Webhook revalidation

- `src/app/api/revalidate/route.ts` uses `parseBody` from `next-sanity/webhook` to
  verify the signature against `SANITY_REVALIDATE_SECRET`. It expects a body of
  `{ _type, slug }` and calls:
  - `revalidateTag(_type)` always (for `siteSettings` this is `"siteSettings"`).
  - For `trail` and `region`, `revalidateTag(`${_type}:${slug}`)` when a slug is present.
  - For `trailCondition` and `tripReport`, `slug` is the referenced trail's slug (see the
    projection below), so it revalidates `trail:<slug>`.
  - Responds 401 when the signature is invalid, 400 when `_type` is missing, and 200 with
    the list of revalidated tags otherwise.
- Create the webhook in the Sanity project management UI (or with the CLI) with:
  - URL `https://<site>/api/revalidate`
  - Trigger on create, update, delete
  - Filter `_type in ["trail", "region", "trailCondition", "tripReport", "siteSettings"]`
  - Projection `{ _type, "slug": coalesce(slug.current, trail->slug.current) }`
  - Secret equal to `SANITY_REVALIDATE_SECRET`
- Document the webhook config in the README so it can be recreated.

### Deployment

These are human steps; agents never push or touch dashboards.

- Create a Vercel project linked to the repository and deploy `main`.
- Set every variable from the overview in Vercel, with `NEXT_PUBLIC_SITE_URL` set to the
  deployed origin.
- Add the deployed origin as a CORS origin with credentials in the Sanity project settings,
  so the embedded Studio works there.
- Create the Viewer read token and the webhook secret, then the webhook above.

### Tags audit

Every `sanityFetch` call from phase 2 and 3 already passes tags. Confirm each call matches
the tag matrix in `03-phase-2-core-pages.md` (Pages section) and fix any that do not.

## Acceptance checks

- Opening the Grassi Lakes trail in the Presentation tool shows the site in the preview
  pane; clicking the trail name `h1` in the preview focuses the `name` field in the editor.
- Editing the summary in the Studio updates the preview within two seconds without publishing.
- `curl -s https://<site>/trails/grassi-lakes | perl -CS -ne 'print if /[\x{200B}-\x{200D}\x{FEFF}]/' | wc -l`
  prints `0`, and the page shows no draft-only edits.
- In the Presentation preview (draft mode on), running
  `[...document.querySelectorAll('a[href]')].filter(a => /[​-‍﻿]/.test(a.getAttribute('href'))).length`
  in the DevTools console of the preview frame returns `0`.
- Publishing a change to a trail's summary updates its page on the deployed site within
  10 seconds on reload, and the Vercel function logs show a 200 `POST /api/revalidate`.
- `curl -s -o /dev/null -w "%{http_code}" -X POST -H "sanity-webhook-signature: bad" -d '{"_type":"trail"}' https://<site>/api/revalidate`
  prints `401`.
- The draft banner is absent on the public site, present in the Presentation preview, and
  its "Exit" link returns to the page with draft mode off (banner gone).
- The hex and small-text greps in the `08-design-system.md` acceptance checks pass.
