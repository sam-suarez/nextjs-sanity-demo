# Phase 2 — Core Pages

## Goal

The home page, trail list, trail detail, region list, and region detail all render from
Sanity with generated types. Portable Text renders with every custom block and annotation.
No images beyond basic `<img>` tags yet; no filters; no maps.

## Deliverables

- `src/lib/sanity/client.ts` exporting `client`, and `sanityFetch` plus `SanityLive`
  from `defineLive`.
- `src/lib/sanity/image.ts` exporting `urlFor(source)` from `@sanity/image-url`, used for
  the plain `<img>` `src` values in this phase.
- `src/lib/sanity/queries.ts` with every query wrapped in `defineQuery`.
- `sanity-typegen.json` and a generated `src/lib/sanity/types.ts`.
- Pages: `/`, `/trails`, `/trails/[slug]`, `/regions`, `/regions/[slug]`.
- `generateStaticParams` on both dynamic routes.
- Portable Text component set under `src/components/portable-text/`.
- Shared site layout with header, footer, and a `not-found.tsx`.
- `loading.tsx` for `/trails` and `/trails/[slug]`.
- The phase 2 row of the Implementation plan in `08-design-system.md`. Page compositions
  follow its Page compositions section, minus the parts it marks for later phases.

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

`SANITY_API_READ_TOKEN` may be unset until phase 4; published content and `<SanityLive />`
work without it.

Stega is configured here, so from this phase on every value used in logic, `className`, or
`href` (slugs, `difficulty`, `routeType`) passes through `stegaClean` when it is written.
Phase 4 audits this; it does not introduce it.

### Queries

Every query is a `defineQuery` export so TypeGen can infer the result type. Keep
projections explicit; never return `...` from a document.

`${trailCardFragment}` below means the fragment string interpolated into the query.

| Query | Shape |
| --- | --- |
| `layoutQuery` | `*[_id == "siteSettings"][0]{ title, footerNote }`. Fetched by the site layout for header and footer |
| `siteSettingsQuery` | `*[_id == "siteSettings"][0]{ title, tagline, heroImage, intro, featuredTrails[]->{ ${trailCardFragment} } }` |
| `featuredTrailsQuery` | `*[_type == "trail" && featured == true] \| order(name asc)[0...4]{ ${trailCardFragment} }`. Home page fallback |
| `trailCardFragment` | `_id, name, "slug": slug.current, difficulty, distanceKm, elevationGainM, routeType, summary, heroImage, region->{ name, "slug": slug.current }` (a string constant interpolated into other queries) |
| `trailsQuery` | `*[_type == "trail"] \| order(name asc){ ${trailCardFragment} }`. Phase 3 adds filter params. |
| `trailSlugsQuery` | `*[_type == "trail" && defined(slug.current)].slug.current` |
| `trailBySlugQuery` | `*[_type == "trail" && slug.current == $slug][0]{ _id, name, "slug": slug.current, difficulty, distanceKm, elevationGainM, routeType, estimatedHours, trailhead, heroImage, summary, highlights, season, dogsAllowed, region->{ name, "slug": slug.current }, related[]->{ ${trailCardFragment} }, body[]{ ..., markDefs[]{ ..., _type == "trailLink" => { "trail": trail->{ name, "slug": slug.current, difficulty } } } } }` |
| `regionsQuery` | `*[_type == "region"] \| order(name asc){ _id, name, "slug": slug.current, description, heroImage, "trailCount": count(*[_type == "trail" && references(^._id)]) }` |
| `regionSlugsQuery` | `*[_type == "region" && defined(slug.current)].slug.current` |
| `regionBySlugQuery` | `*[_type == "region" && slug.current == $slug][0]{ _id, name, "slug": slug.current, description, heroImage, center, accessNotes, "trails": *[_type == "trail" && region._ref == ^._id] \| order(name asc){ ${trailCardFragment} } }` |

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
  featured trail cards (falling back to `featuredTrailsQuery` if the settings list is
  empty), and a region grid.
- `/trails` — fetches `trailsQuery`. Renders a `TrailCard` grid. The grid lives in its own
  async server component wrapped in `<Suspense>` so phase 3 can stream it under filters.
- `/trails/[slug]` — `generateStaticParams` from `trailSlugsQuery`. Calls `notFound()`
  when the query returns null. Sections: header with stats row, body, highlights,
  related trails. Placeholders for map, conditions, and trip reports with a comment
  naming the phase that fills them.
- `/regions` and `/regions/[slug]` — same pattern. The region detail page renders
  `heroImage` below the header with the same frame as the trail page hero (see
  `/regions/[slug]` in `08-design-system.md`); a plain `<img>` with its `alt` in this phase,
  moved into `PhotoMount` in phase 3. Sections: header, hero, access notes, trail grid, and
  a placeholder for the phase 6 map.
- `src/app/(site)/not-found.tsx` renders the 08 not-found composition inside the site
  layout for `notFound()` calls. `src/app/not-found.tsx` renders the same content (without
  header and footer, which live in the `(site)` layout) for URLs that match no route.

Each `sanityFetch` call passes `tags` so phase 4 can revalidate precisely. This matrix is
the contract; phase 4 audits it and later phases add to it:

| Fetch | Tags |
| --- | --- |
| Site layout (`layoutQuery`, every `(site)` page) | `siteSettings` |
| `/` | `siteSettings`, `trail`, `region` |
| `/trails` | `trail`, `region` |
| `/trails/[slug]` | `trail`, `trail:<slug>`, `region` |
| `/regions` | `region`, `trail` |
| `/regions/[slug]` | `region`, `region:<slug>`, `trail` |
| `generateStaticParams` | `trail` for trail routes, `region` for region routes |
| `generateMetadata`, `opengraph-image` (phase 3) | same as their page |
| `/trails/[slug]/report` (phase 5) | `trail`, `trail:<slug>` |
| sitemap (phase 3) | `trail`, `region` |

Phase 5 adds `tripReport` to the trail page's trip report fetch. Phase 6 adds
`trailCondition` to every fetch that projects a condition.

### Portable Text

`src/components/portable-text/index.tsx` exports `<PortableText value={...} />` built on
`@portabletext/react` with a `components` map:

Treatments for every block, list, decorator, and annotation are in the Portable Text table
of `08-design-system.md`.

- `block.h2`, `block.h3`, `block.blockquote` — styled headings and quote.
- `types.callout` — a note styled by tone, with an icon from `lucide-react`.
- `types.gallery` — a responsive grid of images; plain `<img>` until phase 3.
- `marks.link` — external anchor; `target="_blank" rel="noopener noreferrer"` when
  `openInNewTab`.
- `marks.trailLink` — `next/link` to the trail with the `Difficulty` symbol inline and the
  difficulty label as visually hidden text.

`DifficultyBadge` is a small shared component that renders the `Difficulty` symbol plus a
text label, as specified under Components in `08-design-system.md`. It is not a shadcn
`Badge` variant. It is reused on cards, the trail header, and the filter UI.

### Layout

`src/app/(site)/layout.tsx` fetches `layoutQuery` and has the header (site title, Trails,
Regions) and footer (navigation, Studio link, and the `footerNote` closing statement), as
specified under Header and Footer in `08-design-system.md`. The root `src/app/layout.tsx`
holds fonts, `<SanityLive />`, and global CSS only.

## Acceptance checks

- `pnpm typegen` exits 0, then `pnpm build` exits 0.
- `grep -rnE "as any|: any\b" src/app src/components src/lib --include='*.ts' --include='*.tsx' | grep -v "src/lib/sanity/types.ts"`
  returns nothing.
- In the `pnpm build` route table, `/trails/[slug]` and `/regions/[slug]` are marked as
  prerendered (SSG), with 12 and 5 paths respectively (counting any "+N more paths" line).
- Visiting each of the 12 `/trails/<slug>` pages shows: the facts, a body with a callout
  and a gallery, a `trailLink` that navigates to another trail page, and related trail cards.
- `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/trails/not-a-trail` prints
  `404`; the same for `/regions/not-a-region` and `/not-a-page`. The first two show the
  not-found page inside the header and footer.
- `/regions` shows the counts Canmore & Spray Valley 5, Kananaskis Valley 1,
  Peter Lougheed 4, Elbow Valley 1, Bow Valley 1. Each `/regions/<slug>` lists exactly the
  trails with that region in the seed table, and shows the region's hero image below the
  header with a non-empty `alt` (the mount and attribution caption arrive in phase 3).
- `/` shows the four trails in `siteSettings.featuredTrails`, in that order.
- The hex and small-text greps in the `08-design-system.md` acceptance checks pass.
- The checks under Testing in `00-overview.md` pass. Phase 2 adds no required unit tests.
