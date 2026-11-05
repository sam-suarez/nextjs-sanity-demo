# Phase 6 — Live Conditions and Maps

## Goal

A trail's condition banner updates on every open browser when an editor publishes a new
condition, without a reload. Every trail page has a map of the
trailhead and every region page has a clustered map of its trails.

## Deliverables

- `TrailConditions` component on the trail page, live via the Live Content API.
- Condition status badge on trail cards.
- `TrailheadMap` on the trail page and `RegionMap` on the region page.
- Map styling that matches the site theme in light and dark mode.
- Walkthrough section in the README.

## Implementation notes

### Live conditions

- `latestConditionQuery`: `*[_type == "trailCondition" && trail._ref == $trailId] | order(reportedAt desc)[0]{ status, headline, details, reportedAt }`.
- `TrailConditions` is an async server component that calls `sanityFetch` for the query.
  Because `<SanityLive />` is in the root layout and `sanityFetch` registers the query,
  the Live Content API pushes an update and Next.js re-renders the component when a
  matching document changes. No client code is needed.
- Render: a full-width banner under the trail header. Green for `open` with a quiet
  style, amber for `caution`, red for `closed` with a prominent icon. Shows the headline,
  details, and "Reported <relative time>". Relative time is a small client component so
  it ticks without a refetch.
- Falls back to "No recent reports" when the query returns null.
- Trail cards get a small dot in the corner coloured by status. Extend `trailCardFragment`
  with `"condition": *[_type == "trailCondition" && trail._ref == ^._id] | order(reportedAt desc)[0].status`.
  Lists therefore also update live.

### Maps

- `pnpm add maplibre-gl` and import its CSS in the map component.
- `src/components/map/map.tsx` is a client component wrapping a `maplibregl.Map` in a
  `useEffect`, with `dynamic(() => import(...), { ssr: false })` at the call sites so
  it never renders on the server. Style URL `https://tiles.openfreemap.org/styles/liberty`
  for light and `.../styles/dark` for dark, chosen from the `prefers-color-scheme`
  media query.
- `TrailheadMap` takes a geopoint, renders a single marker, zoom 12, `interactive`
  but with scroll zoom disabled until the user clicks the map. Includes a "Open in
  Google Maps" link below using the coordinates.
- `RegionMap` takes the region center and an array of `{ slug, name, difficulty, trailhead }`.
  Uses a GeoJSON source with `cluster: true`, a circle layer for clusters, and a
  symbol layer for single points coloured by difficulty. Clicking a point opens a popup
  with the name and a link to the trail. Fits bounds to all points on load.
- Geopoint values must pass through `stegaClean` before use.
- The map container has a fixed aspect ratio and a skeleton background so it does not
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

- Two browser windows on the same trail page: publishing a new condition in the Studio
  changes the banner in both within two seconds, with no reload.
- The trail list dot changes colour the same way.
- Trail page map shows a marker at the trailhead; the Google Maps link opens the right spot.
- Region page map clusters at low zoom and splits on zoom in; clicking a point opens a
  popup that links to the trail.
- Maps swap styles when the OS theme changes.
- `pnpm build` passes and no map code appears in the server bundle.
