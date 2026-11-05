# Phase 2 — Core Pages

## Goal

The home page, trail list, trail detail, region list, and region detail all render from
Sanity with generated types. Portable Text renders with every custom block and annotation.
No images beyond basic `<img>` tags yet; no filters; no maps.

## Deliverables

- `src/lib/sanity/client.ts` exporting `client`, and `sanityFetch` plus `SanityLive`
  from `defineLive`.
- `src/lib/sanity/queries.ts` with every query wrapped in `defineQuery`.
- `sanity-typegen.json` and a generated `src/lib/sanity/types.ts`.
- Pages: `/`, `/trails`, `/trails/[slug]`, `/regions`, `/regions/[slug]`.
- `generateStaticParams` on both dynamic routes.
- Portable Text component set under `src/components/portable-text/`.
- Shared site layout with header, footer, and a `not-found.tsx`.
- `loading.tsx` for `/trails` and `/trails/[slug]`.

## Implementation notes

### Client

```ts
// src/lib/sanity/client.ts
import { createClient } from "next-sanity";
import { defineLive } from "next-sanity/live";

export const client = createClient({
  projectId, dataset, apiVersion,
  useCdn: true,
  stega: { studioUrl: "/studio" },
});

export const { sanityFetch, SanityLive } = defineLive({
  client,
  serverToken: process.env.SANITY_API_READ_TOKEN,
  browserToken: process.env.SANITY_API_READ_TOKEN,
});
```

`sanityFetch` is the only way pages read content. It handles caching, tags, draft mode,
and live updates. Phases 4 and 6 build on it without changing the pages. Render
`<SanityLive />` once in the root layout now even though nothing is live yet.

### Queries

Every query is a `defineQuery` export so TypeGen can infer the result type. Keep
projections explicit; never return `...` from a document.

| Query | Shape |
| --- | --- |
| `siteSettingsQuery` | `*[_id == "siteSettings"][0]{ title, tagline, heroImage, intro, featuredTrails[]->{ ...trailCard } }` |
| `trailCardFragment` | `_id, name, "slug": slug.current, difficulty, distanceKm, elevationGainM, routeType, summary, heroImage, region->{ name, "slug": slug.current }` (a string constant interpolated into other queries) |
| `trailsQuery` | `*[_type == "trail"] \| order(name asc){ trailCard }`. Phase 3 adds filter params. |
| `trailSlugsQuery` | `*[_type == "trail" && defined(slug.current)].slug.current` |
| `trailBySlugQuery` | Full trail with `region->`, `related[]->{ trailCard }`, and `body[]{ ..., markDefs[]{ ..., _type == "trailLink" => { "trail": trail->{ name, "slug": slug.current, difficulty } } } }` |
| `regionsQuery` | `*[_type == "region"] \| order(name asc){ ..., "trailCount": count(*[_type == "trail" && references(^._id)]) }` |
| `regionSlugsQuery` | as above for regions |
| `regionBySlugQuery` | Region with `"trails": *[_type == "trail" && region._ref == ^._id] \| order(name asc){ trailCard }` |

Conditions and trip reports are not queried in this phase.

### TypeGen

```json
// sanity-typegen.json
{ "path": "./src/**/*.{ts,tsx}", "schema": "./schema.json", "generates": "./src/lib/sanity/types.ts" }
```

Run `pnpm typegen` after any schema or query change. Commit the generated file so
the build does not depend on running it. Pages use the generated `*QueryResult` types.

### Pages

- `/` — server component. Fetches `siteSettingsQuery` and `regionsQuery`. Renders hero,
  featured trail cards (falling back to `featured == true` trails if the settings list is
  empty), and a region grid.
- `/trails` — fetches `trailsQuery`. Renders a `TrailCard` grid. The grid lives in its own
  async server component wrapped in `<Suspense>` so phase 3 can stream it under filters.
- `/trails/[slug]` — `generateStaticParams` from `trailSlugsQuery`. Calls `notFound()`
  when the query returns null. Sections: header with stats row, body, highlights,
  related trails. Placeholders for map, conditions, and trip reports with a comment
  naming the phase that fills them.
- `/regions` and `/regions/[slug]` — same pattern.

Each `sanityFetch` call passes `tags` so phase 4 can revalidate precisely:
`["trail"]` on lists, `["trail", "trail:<slug>"]` on detail pages, and similar for regions.

### Portable Text

`src/components/portable-text/index.tsx` exports `<PortableText value={...} />` built on
`@portabletext/react` with a `components` map:

- `block.h2`, `block.h3`, `block.blockquote` — styled headings and quote.
- `types.callout` — a bordered box coloured by tone, with an icon from `lucide-react`.
- `types.gallery` — a responsive grid of images; plain `<img>` until phase 3.
- `marks.link` — external anchor, `rel="noopener"` when `openInNewTab`.
- `marks.trailLink` — `next/link` to the trail with a `DifficultyBadge`.

`DifficultyBadge` is a small shared component mapping difficulty to a shadcn `Badge`
variant. It is reused on cards, the trail header, and the filter UI.

### Layout

`src/app/(site)/layout.tsx` has the header (logo, Trails, Regions) and footer (the
`footerNote` from site settings plus Studio link). The root `src/app/layout.tsx` holds
fonts, `<SanityLive />`, and global CSS only.

## Acceptance checks

- `pnpm typegen` succeeds and `pnpm build` passes type checking with no `any` casts
  around query results.
- `pnpm build` output lists every trail and region slug as a prerendered page.
- Every seeded trail renders: stats, body with at least one callout and one gallery,
  a working `trailLink` to another trail, and related trails.
- An unknown slug returns the 404 page.
- Region pages show the correct trails and the region list shows correct counts.
- Home page shows the featured trails from site settings.
