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

## Implementation notes

### Draft mode

- `src/app/api/draft-mode/enable/route.ts` uses `defineEnableDraftMode` from
  `next-sanity/draft-mode` with a client that carries `SANITY_API_READ_TOKEN`. It
  validates the secret the Presentation tool sends and calls `draftMode().enable()`.
- `src/app/api/draft-mode/disable/route.ts` calls `draftMode().disable()` and redirects
  to the referrer or `/`.
- `sanityFetch` already switches to `previewDrafts` perspective and disables the CDN
  when draft mode is on. No page changes needed.

### Visual editing

- In the root layout, after `<SanityLive />`, render
  `{(await draftMode()).isEnabled && <VisualEditing />}` from `next-sanity/visual-editing`.
- Stega encoding is already on in the client config from phase 2. Values that must not
  carry stega characters (anything used in logic, `href`, `className`, dates) go through
  `stegaClean` from `@sanity/client/stega`. Audit: `difficulty`, `routeType`, `status`,
  slugs, geopoints, and the filter builder.
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
  - `revalidateTag(_type)` always.
  - `revalidateTag(`${_type}:${slug}`)` when a slug is present.
  - For `trailCondition` and `tripReport`, it reads the referenced trail slug from the
    projection and revalidates `trail:<slug>` as well.
  - For `siteSettings`, `revalidateTag("siteSettings")`.
- Create the webhook in the Sanity project management UI (or with the CLI) with:
  - URL `https://<site>/api/revalidate`
  - Trigger on create, update, delete
  - Filter `_type in ["trail", "region", "trailCondition", "tripReport", "siteSettings"]`
  - Projection `{ _type, "slug": coalesce(slug.current, trail->slug.current) }`
  - Secret equal to `SANITY_REVALIDATE_SECRET`
- Document the webhook config in the README so it can be recreated.

### Tags audit

Every `sanityFetch` call from phase 2 and 3 already passes tags. Confirm the matrix:

| Page | Tags |
| --- | --- |
| `/` | `siteSettings`, `trail`, `region` |
| `/trails` | `trail` |
| `/trails/[slug]` | `trail`, `trail:<slug>`, `region` |
| `/regions` | `region`, `trail` |
| `/regions/[slug]` | `region`, `region:<slug>`, `trail` |
| sitemap | `trail`, `region` |

## Acceptance checks

- Opening a trail in the Presentation tool shows the live site in the right pane; clicking
  a heading on the site focuses the matching field in the editor.
- Editing the summary in the Studio updates the preview within a second without publishing.
- Visiting the public site in a normal browser shows no draft content and no stega
  characters in `href` attributes or data attributes.
- Publishing a change to a trail updates its page on the deployed site within a few
  seconds, visible in the Vercel function logs as a revalidate call.
- A request to `/api/revalidate` with a bad signature returns 401.
- The draft banner appears only in draft mode and its exit link works.
