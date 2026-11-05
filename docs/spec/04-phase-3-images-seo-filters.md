# Phase 3 — Images, SEO, Filters

## Goal

The site looks finished. Images use Sanity's pipeline with hotspots and placeholders,
every page has correct metadata and a generated share image, and the trail list can be
filtered by region, difficulty, and distance.

## Deliverables

- `SanityImage` component wrapping `next/image` with a Sanity loader.
- Low-quality image placeholders from asset metadata.
- `generateMetadata` on every page; `sitemap.ts` and `robots.ts`.
- `opengraph-image.tsx` for trails and regions.
- Filter bar on `/trails` driven by search params, with streaming results.
- Empty state and result count.

## Implementation notes

### Images

- `src/lib/sanity/image.ts` exports `urlFor(source)` from `@sanity/image-url`.
- `src/components/sanity-image.tsx` takes an `imageWithMeta` value plus `width`,
  `height` or `aspectRatio`, and `sizes`. It builds a loader that calls
  `urlFor(image).width(w).auto("format").fit("crop")` so hotspot and crop apply at
  every breakpoint. Alt comes from the image's `alt` field; attribution renders as a
  small caption when `showAttribution` is set.
- Queries that return images add `asset->{ _id, metadata { lqip, dimensions } }` to
  the projection so `placeholder="blur"` and `blurDataURL={lqip}` work without an
  extra request. Update `trailCardFragment` and the detail queries, then rerun TypeGen.
- Replace every `<img>` from phase 2, including the gallery block.
- Add `cdn.sanity.io` to `images.remotePatterns` in `next.config.ts`.

### Metadata

- Root layout: `metadataBase` from `NEXT_PUBLIC_SITE_URL`, default title template
  `"%s · Trailhead"`, site name from `siteSettings`.
- Trail page: title `name`, description `summary`, `openGraph.images` pointing at the
  route's generated image. Same for region.
- `src/app/sitemap.ts` lists static routes plus every trail and region URL with
  `_updatedAt` as `lastModified`.
- `src/app/robots.ts` allows everything except `/studio` and `/api`.

### OG images

`src/app/(site)/trails/[slug]/opengraph-image.tsx` uses `ImageResponse` from `next/og`:

- 1200×630. Hero image as background via a direct `urlFor(...).width(1200).height(630).url()`
  string, dark gradient overlay, trail name, region, and a stats row (distance, gain,
  difficulty).
- Fonts: load one weight of a Google font at build time with `fetch` and pass it to
  `ImageResponse`. Keep it to one font file to stay under the size limit.
- Export `generateStaticParams` identical to the page so images prerender.
- Regions get a simpler variant: hero, name, trail count.

### Filters

Search params on `/trails`:

| Param | Values | GROQ |
| --- | --- | --- |
| `region` | region slug | `region->slug.current == $region` |
| `difficulty` | one or more, comma separated | `difficulty in $difficulties` |
| `maxKm` | number | `distanceKm <= $maxKm` |
| `sort` | `name`, `distance`, `gain` | `order(...)` chosen in code from an allowlist |

`trailsQuery` becomes a function that builds the filter string from validated params.
Only the four known params are read; everything else is ignored. Parse with a small
Zod schema in `src/lib/trail-filters.ts` that also exports `toSearchParams` for the UI.

UI:

- `FilterBar` is a client component. Region `Select`, difficulty toggle group, distance
  `Select` with preset steps (5, 10, 15, 20 km), sort `Select`. Each change calls
  `router.replace` with new search params and `scroll: false`.
- The page reads `searchParams` (await it; it is a promise in current Next.js), passes
  them to `<TrailResults>` which is an async server component inside `<Suspense>` keyed
  on the serialised params so a new filter shows the skeleton while streaming.
- Skeleton grid matches the card dimensions to avoid layout shift.
- Result count and a "Clear filters" link when any filter is active.
- Empty state card with a link back to all trails.

Because the page depends on search params it is rendered on demand. The `sanityFetch`
cache still applies per unique query, so repeated filters are cheap.

## Acceptance checks

- Lighthouse on a trail page scores 90+ on performance with no CLS from images.
- Changing a hotspot in the Studio changes the crop on cards after revalidation
  (manual rebuild for now; automatic in phase 4).
- Pasting a trail URL into a social preview debugger shows the generated card.
- `/sitemap.xml` lists every trail and region.
- Filtering by `hard` in Peter Lougheed returns the expected set; an impossible
  combination shows the empty state. The URL is shareable and reproduces the filters.
- Navigating between filters shows the skeleton, not a blank page.
