# Phase 6 — Live Conditions and Maps

## Goal

A trail's condition banner updates on every open browser when an editor publishes a new
condition, without a reload. Every trail page has a map of the
trailhead and every region page has a clustered map of its trails.

## Deliverables

- `TrailConditions` component on the trail page, live via the Live Content API.
- Condition status badge on trail cards.
- `TrailheadMap` on the trail page and `RegionMap` on the region page.
- Map mount, marker, cluster, and popup styling per Maps in `08-design-system.md`, on the
  OpenFreeMap `liberty` style always (the site is light only).
- The rest of the phase 6 row of the Implementation plan in `08-design-system.md`.
- Walkthrough section in the README.

## Implementation notes

### Live conditions

- `latestConditionQuery`: `*[_type == "trailCondition" && trail._ref == $trailId] | order(reportedAt desc)[0]{ status, headline, details, reportedAt }`.
- `TrailConditions` is an async server component that calls `sanityFetch` for the query.
  Because `<SanityLive />` is in the root layout and `sanityFetch` registers the query,
  the Live Content API pushes an update and Next.js re-renders the component when a
  matching document changes. No client code is needed.
- Render: directly under the facts, with the per-status treatment in the Condition banner
  table of `08-design-system.md` (pencil-green quiet line for `open`, highlight band for
  `caution`, accent outline for `closed`). Shows the headline, details, and
  "Reported <relative time>". Relative time is a small client component so it ticks
  without a refetch: it renders `<time dateTime={reportedAt}>`, computes the relative text
  with `Intl.RelativeTimeFormat("en")` after mount (avoiding a hydration mismatch), and
  updates once a minute.
- Falls back to "No recent reports" when the query returns null.
- Trail cards get a small dot in the corner coloured by status. Extend `trailCardFragment`
  with `"condition": *[_type == "trailCondition" && trail._ref == ^._id] | order(reportedAt desc)[0].status`.
  Lists therefore also update live.
- Add the `trailCondition` tag to the condition fetch and to every fetch that uses
  `trailCardFragment` (`/`, `/trails`, `/trails/[slug]`, `/regions/[slug]`), so the phase 4
  webhook also refreshes them for visitors without an open live connection.

### Maps

- `pnpm add maplibre-gl` and import its CSS in the map component.
- `src/components/map/map.tsx` is a client component wrapping a `maplibregl.Map` in a
  `useEffect`. `TrailheadMap` and `RegionMap` are themselves client components that load
  it with `dynamic(() => import(...), { ssr: false })`, because `ssr: false` is not allowed
  in Server Components; the pages render these wrappers. Style URL is always
  `https://tiles.openfreemap.org/styles/liberty`.
- Both maps add a `NavigationControl` (zoom buttons) and a `compact` attribution control,
  styled per Maps in `08-design-system.md`. Paint colours are read from the `--dp-color-*`
  custom properties at runtime, not hard-coded.
- `TrailheadMap` takes a geopoint, renders a single marker (the `Pin` DOM marker from 08),
  zoom 12, `interactive` but with scroll zoom disabled until the user clicks the map.
  Includes an "Open in Google Maps" link below to
  `https://www.google.com/maps/search/?api=1&query=<lat>,<lng>`.
- `RegionMap` takes the region center and an array of `{ slug, name, difficulty, trailhead }`.
  Add `trailhead` to the trail projection inside `regionBySlugQuery` for this (not to
  `trailCardFragment`), then rerun TypeGen. Uses a GeoJSON source with `cluster: true`, a
  circle layer for clusters, and a symbol layer for single points whose icons are the
  `Difficulty` shapes in their difficulty colours, registered with `map.addImage` on load.
  Clicking a point opens a popup with the name and a link to the trail. On load it fits
  bounds to all points with `maxZoom: 12`, so a region with one trail does not zoom to the
  maximum; with no trails it stays on `center` at zoom 10.
- Geopoint values must pass through `stegaClean` before use.
- The map container has a fixed 3:2 aspect ratio and a skeleton background so it does not
  shift layout while the library loads.

### Walkthrough

Add a "Walkthrough" section to the README covering each feature in order:

1. Home page, region grid, trail list with filters.
2. Trail page: stats, body with a callout and gallery, related trails, map.
3. Open the Studio Presentation tool for the same trail, edit the summary, watch it update.
4. Publish; show the public page update via webhook.
5. Submit a trip report with a photo; approve it in the Studio; show it on the page.
6. With the trail page open in a second window, create a `closed` condition in the
   Studio and publish. Watch the banner go red in the other window.

## Acceptance checks

- Two browser windows on `/trails/grassi-lakes`: publishing a new `closed` condition for
  Grassi Lakes in the Studio changes the banner in both to the `closed` treatment within
  two seconds, with no reload.
- With `/trails` open, the Grassi Lakes card dot changes to the closed fill within two
  seconds of the same publish, with no reload.
- On `/trails/grassi-lakes` the marker sits at the seeded trailhead coordinates, and the
  "Open in Google Maps" link opens Google Maps centred on those coordinates.
- On `/regions/canmore-spray-valley` the map shows at least one cluster on load; zooming
  in splits it into single difficulty icons; clicking one opens a popup whose link goes to
  that trail's page.
- `pnpm build` exits 0, and
  `grep -rlE "maplibre-gl|maplibregl" .next/server --include='*.js' --exclude='*manifest*' | wc -l`
  prints `0`.
- The hex and small-text greps in the `08-design-system.md` acceptance checks pass.
