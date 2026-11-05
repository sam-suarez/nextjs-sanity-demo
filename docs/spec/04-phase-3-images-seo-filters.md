# Phase 3 — Images, SEO, Filters

## Goal

The site looks finished. Images use Sanity's pipeline with hotspots and placeholders,
every page has correct metadata, trail and region pages have a generated share image, and
the trail list can be filtered by region, difficulty, and distance.

## Deliverables

- `SanityImage` component wrapping `next/image` with a Sanity loader.
- `PhotoMount` wrapping `SanityImage`, and the rest of the phase 3 row of the
  Implementation plan in `08-design-system.md`.
- Low-quality image placeholders from asset metadata.
- `generateMetadata` on every page; `sitemap.ts` and `robots.ts`.
- `opengraph-image.tsx` for trails and regions.
- Filter bar on `/trails` driven by search params, with streaming results.
- Empty state and result count.

## Implementation notes

### Images

- `urlFor(source)` in `src/lib/sanity/image.ts` exists from phase 2.
- `src/components/sanity-image.tsx` takes an `imageWithMeta` value plus `width`,
  `height` or `aspectRatio`, and `sizes`. It builds a loader that calls
  `urlFor(image).width(w).auto("format").fit("crop")` so hotspot and crop apply at
  every breakpoint. Alt comes from the image's `alt` field; an optional `alt` prop
  overrides it for plain images without one (trip report photos, phase 5). It renders the
  image only.
- `PhotoMount` (see `08-design-system.md`) wraps `SanityImage` and renders the attribution
  caption under the mount at detail size when `showAttribution` is set.
- Queries that return images project them as
  `{ alt, attribution, attributionUrl, hotspot, crop, asset->{ _id, metadata { lqip, dimensions } } }`
  so hotspot and crop reach `urlFor`, and `placeholder="blur"` and `blurDataURL={lqip}` work
  without an extra request. Update `trailCardFragment`, `siteSettingsQuery`, `regionsQuery`,
  and the detail queries (including gallery images in `body`), then rerun TypeGen.
- Replace every `<img>` from phase 2, including the gallery block.
- Add `cdn.sanity.io` to `images.remotePatterns` in `next.config.ts`.

### Metadata

- Root layout: `metadataBase` from `NEXT_PUBLIC_SITE_URL`, title template
  `"%s · <siteSettings.title>"` with `siteSettings.title` as the default title, and
  `openGraph.siteName` from `siteSettings.title`. Description defaults to
  `siteSettings.tagline`.
- Page titles: `/` uses the default title; `/trails` "Trails"; `/regions` "Regions";
  trail pages `name`; region pages `name`; report pages "Report on <trail name>".
- Trail page description `summary`; region page description `description`. Other pages
  use the default description.
- `og:image` on trail and region pages comes from the route's `opengraph-image` file
  (file-based metadata); `generateMetadata` does not set `openGraph.images` itself.
- `src/app/sitemap.ts` lists `/`, `/trails`, `/regions`, plus every trail and region URL
  with `_updatedAt` as `lastModified`, as absolute URLs on `NEXT_PUBLIC_SITE_URL`. Report
  pages are not listed. Add a `sitemapQuery` returning `slug` and `_updatedAt` for both types.
  The entries are built by a pure `sitemapEntries(siteUrl, { trails, regions })` in
  `src/lib/sitemap.ts`; `sitemap.ts` fetches and calls it.
- `src/app/robots.ts` allows everything except `/studio` and `/api`.

### OG images

`src/app/(site)/trails/[slug]/opengraph-image.tsx` uses `ImageResponse` from `next/og`.
The layout follows the OG paragraph in the Images section of `08-design-system.md`:

- 1200×630, ground background (no photo background, no gradient). Trail name in Permanent
  Marker at 72px in ink, region in annotation at 32px, and a stats row in accent
  (distance, gain, difficulty label).
- Hero photo on the right in a scrap mount with a tape rectangle, rotated 2°. The photo is
  a direct `urlFor(heroImage).width(520).height(390).fit("crop").url()` string so the
  hotspot applies.
- Font: load Permanent Marker (its one weight) at build time with `fetch` and pass it to
  `ImageResponse`. One font file only, to stay under the size limit; text that would use
  the reading face is set in Permanent Marker too.
- Export `generateStaticParams` identical to the page so images prerender.
- `src/app/(site)/regions/[slug]/opengraph-image.tsx` is the simpler variant: name, trail
  count, photo.
- `ImageResponse` cannot read CSS custom properties, so both OG files import their colours
  from `src/lib/og-tokens.ts`, created in this phase as described in the Images section of
  `08-design-system.md`. It mirrors the `--dp-color-*` hex values the cards use, is the one
  file exempt from the "no hex outside `globals.css`" rule, and must stay in sync with
  `globals.css`. The OG files themselves contain no hex. Its keys are the camelCase token
  names (`ground`, `ink`, `pencilGreen`), so the unit test below can match each key to
  `--dp-color-<kebab-case key>`.

### Filters

Search params on `/trails`:

| Param | Values | GROQ |
| --- | --- | --- |
| `region` | region slug | `region->slug.current == $region` |
| `difficulty` | one or more, comma separated | `difficulty in $difficulties` |
| `maxKm` | number | `distanceKm <= $maxKm` |
| `sort` | `name` (default), `distance`, `gain` | `order(...)` chosen in code from an allowlist |

Queries stay static strings so TypeGen can type them (a query built at runtime cannot be
typed). The filter is one fragment with optional params, passed as `null` when unset:

```groq
_type == "trail"
  && (!defined($region) || region->slug.current == $region)
  && (!defined($difficulties) || difficulty in $difficulties)
  && (!defined($maxKm) || distanceKm <= $maxKm)
```

`trailsQuery` uses it with `order(name asc)`; `trailsByDistanceQuery` with
`order(distanceKm asc)` and `trailsByGainQuery` with `order(elevationGainM asc)`, each a
`defineQuery` with the same `${trailCardFragment}` projection. The `sort` param picks one
of the three from an allowlist in code.

Only the four known params are read; everything else is ignored. Parse with a small
Zod schema in `src/lib/trail-filters.ts` (`pnpm add zod`) that also exports
`toSearchParams` for the UI. `difficulty` values outside the four enum values and a
non-positive `maxKm` are dropped, not errors.

`parseTrailFilters(searchParams)` returns `{ region, difficulties, maxKm, sort }`, with
`null` for each unset filter and `sort` defaulting to `"name"`; the first three go straight
to the query as `$region`, `$difficulties`, and `$maxKm`. A param given more than once (a
`string[]`) uses its first value. Repeated difficulty values are removed, and a list with
no valid values becomes `null`. `toSearchParams(filters)` omits `null` filters and the
default sort.

UI:

- `FilterBar` is a client component. Region `Select` (options from `regionsQuery`, slugs
  through `stegaClean`), difficulty toggles as `button[aria-pressed]` (see FilterBar in
  `08-design-system.md`), distance `Select` with "Any" plus preset steps (5, 10, 15, 20 km),
  sort `Select`. Each change calls `router.replace` with new search params and `scroll: false`.
- The page reads `searchParams` (await it; it is a promise in current Next.js), passes
  them to `<TrailResults>` which is an async server component inside `<Suspense>` keyed
  on the serialised params so a new filter shows the skeleton while streaming.
- Skeleton grid matches the card dimensions to avoid layout shift.
- Result count and a "Clear filters" link when any filter is active.
- Empty state card with a link back to all trails.

Because the page depends on search params it is rendered on demand. The `sanityFetch`
cache still applies per unique query, so repeated filters are cheap.

### Unit tests

Per Testing in `00-overview.md`. At least:

- `src/lib/trail-filters.test.ts`
  - No params gives every filter `null` and `sort` `"name"`.
  - All four valid params parse; `maxKm=10` becomes the number `10`.
  - Unknown params (`foo=bar`) are ignored.
  - `difficulty=easy,nope,easy,hard` gives `["easy", "hard"]`; `difficulty=nope` gives `null`.
  - `maxKm` of `0`, `-5`, `abc`, and the empty string each give `null`.
  - `sort=elevation` gives `"name"`.
  - `region: ["a", "b"]` gives `"a"`.
  - `toSearchParams` omits `null` filters and `sort=name`, and
    `parseTrailFilters(toSearchParams(f))` equals `f` for an empty and a full filter.
- `src/lib/sitemap.test.ts`
  - Two trails and one region give 6 entries: the 3 static routes, then one per document.
  - Every `url` is absolute on `siteUrl`, with no double slash when `siteUrl` ends in `/`.
  - Document entries take `lastModified` from `_updatedAt`.
- `src/lib/og-tokens.test.ts`: reads `src/app/globals.css` from disk; for each key in
  `og-tokens.ts`, the matching `--dp-color-*` token exists and has the same hex value
  (case-insensitive). This is how the sync rule in 08 is checked.

## Acceptance checks

Run against `pnpm build && pnpm start` unless stated. Expected trail sets assume the seed
table in `01-content-model.md` as verified in phase 1.

- Lighthouse (Chrome DevTools, mobile, navigation mode) on `/trails/grassi-lakes`:
  Performance 90 or higher, and no `img` element listed under "Avoid large layout shifts".
- Move the hotspot on Grassi Lakes' hero image in the Studio and publish, then run
  `rm -rf .next && pnpm build && pnpm start` (clearing the fetch cache): the card on
  `/trails` is cropped around the new hotspot
  (automatic revalidation arrives in phase 4).
- `curl -s http://localhost:3000/trails/grassi-lakes | grep -o '<meta property="og:image"[^>]*>'`
  prints a tag whose `content` contains `/trails/grassi-lakes/opengraph-image`. Requesting
  that URL returns `content-type: image/png`, and the image matches the 08 OG treatment.
  The same holds for `/regions/peter-lougheed`.
- `curl -s http://localhost:3000/sitemap.xml | grep -c "<loc>"` prints `20` (3 static
  routes, 12 trails, 5 regions).
- `/trails?region=peter-lougheed&difficulty=moderate` lists exactly Ptarmigan Cirque,
  Rawson Lake, and Upper Kananaskis Lake Circuit, with the count "3 trails".
  `/trails?region=peter-lougheed&difficulty=hard` shows the empty state. Opening either URL
  in a new tab reproduces the same filters in the `FilterBar` and the same results.
- `/trails?sort=distance` lists Elbow Lake first and Upper Kananaskis Lake Circuit last.
  `/trails?foo=bar&difficulty=nope` lists all 12 trails.
- With DevTools network throttling at "Slow 4G", toggling a difficulty filter shows the
  skeleton grid before the new results appear, never a blank area.
- The hex and small-text greps in the `08-design-system.md` acceptance checks pass (the hex
  grep exempts exactly `src/lib/og-tokens.ts`), and each hex value in `og-tokens.ts` equals
  the matching `--dp-color-*` value in `src/app/globals.css` (checked by `og-tokens.test.ts`).
- The checks under Testing in `00-overview.md` pass, and `pnpm test` runs the three test
  files above plus phase 1's.
