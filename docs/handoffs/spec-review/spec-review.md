# Spec review — 2026-11-04

## Status
complete

Sam answered all three open questions on 2026-11-04. The answers are folded into the spec
(see "Follow-up edits after Sam's answers" and Decisions). No open questions remain.

## Change log

### 00-overview.md
- Routes: `/regions` and `/regions/[slug]` marked "revalidated by tag" (and `generateStaticParams` on the latter), because 03 and 05 tag and prerender them.
- Routes: added `/regions/[slug]/opengraph-image`, `/sitemap.xml`, `/robots.txt`, which phase 3 delivers but the table did not list.
- Env: the read-token sentence now matches 03's `browserToken`: server-read, sent to the browser by `defineLive` only in draft mode. Before, it said "used only inside server code", which contradicted 03.
- Folder layout: added `app/(site)`, `app/studio`, `app/api`, `components/sketch`, `lib/sanity/write-client.ts`, `lib/trail-filters.ts`, `sanity/presentation/`. Phase files use all of these, but the layout did not show them.
- Phase summary: each phase delivers its row of the 08 Implementation plan and passes the 08 checks that apply to it. Before, nothing tied the 08 plan to the phase files.

### 01-content-model.md
- `trail.heroImage` typed as `imageWithMeta`. It was "image with hotspot" with a partial field list, unlike `region` and `siteSettings`.
- `region.slug` gets `source: name`, the same as `trail`.
- `season.from`/`to` use an options list of the twelve month names. Before, free text with no rule.
- Added site display labels for the `difficulty` and `routeType` enums.
- `tripReport.photos` noted as plain images with no `alt`; the site derives the alt text. 08 says alt is never empty.
- `siteSettings` gets a Rules column: `title`, `tagline`, `heroImage` required. The footer omits the closing statement when `footerNote` is empty.
- `imageWithMeta` said "plus two fields" but lists three. Fixed, and noted the trip report exception.
- `trailLink` renders the inline `Difficulty` symbol (08 Portable Text), not "a small difficulty badge".
- Seed: rules for trail slugs and IDs; a region slug column; per-region trail counts.
- Seed: per-trail content requirements (callout, gallery of 2 or more images, trailLink, related, highlights, season). The phase 2 acceptance check depends on this content, and nothing required it before.
- Seed: the `siteSettings` fields to fill, four `featuredTrails` from at least three regions, and the same four with `featured: true`.

### 02-phase-1-foundation.md
- Deliverables and Scaffold: `shadcn init`, then replace `:root` with the 08 mapping and delete the generated `.dark` block (08 conflict 2; light only).
- Deliverables: added the 08 phase 1 design row. 02 did not mention it at all.
- Added the human step: CORS origin `http://localhost:3000` with credentials for the embedded Studio.
- `sanity.config.ts`: `basePath: "/studio"` and env-sourced project ID and dataset.
- Schemas: also filter `siteSettings` out of `document.newDocumentOptions`, as 01 requires.
- Schemas: added `Rule.min()`, `Rule.precision(1)`, a custom future-date rule on `hikedOn`, and `initialValue` defaults. These were needed to meet 01's rules and defaults.
- `tripReport.status` wording: before, it said both "is readOnly: true" and "allow it to be edited". Now: editable in phase 1, read-only from phase 5.
- `DifficultyInput`: colours from `@sanity/ui`, no raw hex (CLAUDE.md rule).
- Seed: points to the slug rules and content requirements in 01; every array item needs `_key`.
- New "Placeholder home" section: a static statement plus a primary button to `/studio`. The 08 phase 1 row asks for this, and no Sanity client exists yet.
- Acceptance: added `pnpm build`.
- Acceptance: document counts checked with `pnpm sanity documents query`.
- Acceptance: the validation check now gives exact steps.
- Acceptance: added the "New document" singleton check and the 08 greps.
- Acceptance: Vision query aliased as `"region": region->name`, so its key cannot clash with `name`.
- Scripts: confirmed `dev`, `build`, `typegen`, `seed` are all defined. No change.

### 03-phase-2-core-pages.md
- `urlFor` / `image.ts` moved into phase 2 deliverables. Phase 2 renders `<img>` from Sanity image refs, but `urlFor` was only created in phase 3 (ordering gap).
- Added the 08 phase 2 row to deliverables.
- `SANITY_API_READ_TOKEN` may be unset until phase 4, so phase 2 has no token human step.
- `stegaClean` applies from phase 2 onwards, as CLAUDE.md requires. Before, it was introduced only as a phase 4 audit.
- Queries: `...trailCard` and `{ trailCard }` now use the one `${trailCardFragment}` notation.
- Queries: added `layoutQuery`. The header and footer need `title` and `footerNote`, which no query fetched.
- Queries: added `featuredTrailsQuery`. The home fallback had no query.
- Queries: wrote out full projections for `trailBySlugQuery` and `regionBySlugQuery`, and spelled out `regionSlugsQuery`.
- Queries: `regionsQuery` no longer uses `...`. The same section bans returning `...`.
- Pages: where each `not-found.tsx` lives (the `(site)` one for `notFound()`, the root one for unmatched URLs).
- The tag matrix moved here from phase 4, so it is set where fetches are first written.
- Tag matrix: added the layout row, `region` on `/trails` (cards show the region name, and the phase 3 FilterBar lists regions), `generateStaticParams`, metadata and OG, the report page, and the later-phase additions.
- Portable Text: `DifficultyBadge` is the symbol plus a text label, not a Badge variant (08 conflict 3).
- Portable Text: `trailLink` uses the symbol with a hidden label.
- Portable Text: `link` uses `target="_blank" rel="noopener noreferrer"`; treatments point to the 08 table.
- Layout: "logo" changed to the site title; footer contents point to 08. 08 has no logo and adds a nav group.
- Acceptance: every check is now exact. Added commands for the build, the `any` grep, and the 404 status codes.
- Acceptance: added the region counts from the seed and the featured trail order.

### 04-phase-3-images-seo-filters.md
- Goal: "every page has... a generated share image" narrowed to trail and region pages, which are the only OG images the deliverables define.
- Deliverables: added `PhotoMount` and the 08 phase 3 row.
- Images: `urlFor` already exists from phase 2.
- Images: `SanityImage` gets an `alt` override prop for trip report photos.
- Images: attribution rendering moved to `PhotoMount`, as 08 has it, and the "small caption" wording dropped (21px rule).
- Images: wrote out the image projection, including `hotspot` and `crop`, and listed every query to update.
- Metadata: the title template uses `siteSettings.title`. It was hard-coded "Trailhead".
- Metadata: added titles and descriptions per page.
- Metadata: `og:image` comes from the file convention, with no manual `openGraph.images`.
- Metadata: sitemap lists the static routes `/`, `/trails`, `/regions`, uses absolute URLs, adds `sitemapQuery`, and leaves out report pages.
- OG: rewritten to the 08 Images treatment. The old version had a photo background and a dark gradient, and 08 bans gradients.
- OG: the font is named as Permanent Marker (08 conflict 4).
- OG: set the photo crop size and added the region OG path.
- OG: the hex-colour problem is flagged as an open question (Q1).
- Filters: `trailsQuery` built at runtime is replaced by three static `defineQuery` sort variants with optional `null` params. TypeGen cannot type a query built at runtime, and 03 forbids `any`.
- Filters: added `pnpm add zod`, rules for dropping invalid values, and the default sort.
- Filters: region options come from `regionsQuery` and go through `stegaClean`; difficulty toggles are `button[aria-pressed]` per 08; the distance Select gets "Any".
- Acceptance: the social preview debugger check is replaced by a curl check of `og:image` plus a content-type check. The debugger needs a public deploy, which does not exist until phase 4.
- Acceptance: "hard in Peter Lougheed returns the expected set" is replaced by exact sets. The seed has no hard trails in Peter Lougheed.
- Acceptance: the sitemap `<loc>` count must be 20. Added a sort check and an ignored-params check.
- Acceptance: the hotspot check clears `.next` first, so the fetch cache cannot hide the change.

### 05-phase-4-editorial-workflow.md
- Deliverables: first Vercel deployment. The webhook and the deployed-site checks need a public URL, and no phase created one.
- Draft disable now uses `(await draftMode()).disable()`, matching the file's own awaited `draftMode()`. The enable helper does the enabling.
- `stegaClean` is framed as an audit of phases 2 and 3.
- Webhook: for `trailCondition` and `tripReport`, the projected `slug` is the trail's slug, so `${_type}:${slug}` was meaningless for them. Clarified.
- Webhook: response codes are now 401, 400, and 200.
- New "Deployment" subsection listing the human steps: Vercel project, env vars, CORS for the deployed origin, Viewer token, webhook secret.
- Tags audit now points to the 03 matrix instead of keeping a second copy that could drift.
- Acceptance: every check is now exact. Stega checks use a perl/curl zero-width scan and a DevTools one-liner; the revalidate window is 10 seconds; the 401 check is a curl command.

### 06-phase-5-trip-reports.md
- Deliverables: added the 08 phase 5 row and `shadcn add sonner form`. 08 uses `ui/sonner.tsx` and 06 uses `Form`, and phase 1 installed neither.
- Write client: `pnpm add server-only`; creating the token is a human step.
- Report page: added `trailForReportQuery` with tags, `notFound()`, `stegaClean` on props, and `generateStaticParams`. 00 calls it a "static shell", and nothing prerendered it.
- Form: the action returns the typed values so the form can re-fill them as `defaultValue`. File inputs cannot be restored, so the form also checks photos in the browser.
- Thank-you toast: read with `useSearchParams()` in `<Suspense>`. Reading `searchParams` on the server would make the static trail page dynamic. `<Toaster />` goes in the site layout.
- Action: the honeypot takes the same redirect as a real success. Before, a fake `{ok:true}` contradicted the redirect-on-success flow.
- Action: `await headers()` and the first XFF address; only valid submissions count toward the rate limit.
- Action: step 6 defines the success redirect and the failure shape.
- Moderation: reject is disabled when the report is already rejected, mirroring approve.
- Display: points to 08; the date format is set; photo alt text is derived.
- Acceptance: "4 MB×4 photos" replaced. 16 MB plus form overhead exceeds `bodySizeLimit`, so the action would never run and no field errors could show.
- Acceptance: added checks for the read-only status and the action menu, and for the pending badge or a recorded fallback.
- Acceptance: added the rate-limit setup (freshly restarted server) and an exact token grep.

### 07-phase-6-live-conditions-maps.md
- Maps always use the `liberty` style; the dark style and the OS-theme acceptance check are removed (08 conflict 1).
- Deliverables: added the 08 phase 6 row.
- Banner: the treatment now follows the 08 table. The old green/amber/red wording clashed with 08's highlight band.
- Relative time: added hydration-safe rendering and a one-minute tick.
- Tags: `trailCondition` added to every fetch that projects a condition. Without it the webhook never refreshed the list dots.
- Maps: `dynamic(..., { ssr: false })` moved into client wrapper components. It was "at the call sites", which are Server Components, where `ssr: false` is not allowed.
- Maps: added `NavigationControl` and a compact attribution control. 08 styles the nav controls, its tab check reaches "map controls", and attribution text must be at least 21px.
- Maps: paint colours come from the CSS variables, so map code holds no hex.
- Maps: Google Maps URL format specified.
- Maps: `trailhead` added to `regionBySlugQuery`. `RegionMap` needs it, and `trailCardFragment` lacks it.
- Maps: single points use `Difficulty` icon images, since 08 lists map points as a use of `Difficulty`.
- Maps: `fitBounds` uses `maxZoom: 12`, because three regions have a single trail. Added the zero-trail case and a 3:2 aspect ratio.
- Acceptance: every check is now exact. The cluster check uses Canmore & Spray Valley (5 trails), and the server-bundle check uses a grep that excludes manifests.

### 08-design-system.md
- The "Conflicts with earlier phases" section now records all four as resolved.
- 21px rule: the banned classes now include `text-base`, `text-lg`, and `text-xl` (16, 18, 20px). It was only "`text-sm` or smaller". The rule now also covers `src/components/`, including the shadcn files.
- Home statement: the last word of the tagline is underlined. "One word" was unspecified, and `tagline` is free text.
- Facts: `dogsAllowed` labels set to "On leash" / "Not allowed".
- Highlights and related trails are omitted when empty; the trip reports empty state reads "No trip reports yet."
- `DifficultyBadge` "used on" listed `trailLink`, while the Portable Text table gave `trailLink` the bare symbol. Resolved in favour of the PT table, plus a visually hidden label for the accessibility rule.
- Condition dot: no dot when the trail has no condition document.
- `strong`: removed "2px", which contradicted "thickness 6px".
- Maps: 3:2 aspect ratio, paint colours via `getComputedStyle`, compact attribution at 21px.
- Implementation plan: added the sentence on which checks apply in each phase.
- Acceptance: the hex grep is now case-insensitive, also covers `sanity/`, and is limited to ts/tsx/css files.
- Acceptance: added a small-text grep.
- Acceptance: "badges" in the tab order became "the region link". `DifficultyBadge` is not focusable.

### Follow-up edits after Sam's answers (2026-11-04)

- **08 Images:** new `src/lib/og-tokens.ts` paragraph. It mirrors the `--dp-color-*` hex values the OG cards use (pencil-green only if a card uses it). It is the only exempt file, is imported only by `opengraph-image.tsx`, and must be kept in sync with `globals.css`.
- **08 Acceptance:** the hex grep now pipes through `grep -v '^src/lib/og-tokens\.ts:'`, exempting exactly that path, and adds a sync check. The phase files 02, 03, 05, 06 and 07 point at this grep rather than copying it, so they pick up the change without edits.
- **04 OG:** the open-decision note is replaced. Both OG files import their colours from `og-tokens.ts`, created in phase 3, and contain no hex themselves.
- **04 Acceptance:** the hex check names the exemption and checks that `og-tokens.ts` matches `globals.css`.
- **00 Folder layout:** added `src/lib/og-tokens.ts`.
- **06 Display:** each trip report photo is wrapped in a plain `<a>` to `urlFor(photo).width(1600).auto("format").url()`. Same tab, no `target`, no lightbox. Any query string that feeds the href goes through `stegaClean`.
- **06 Acceptance:** new photo-link check (Tab focus, Enter opens the CDN image in the same tab, no `target`, `w=1600` in the href).
- **08 Trip reports and keyboard check:** photos are plain `<a>` to the full-size image, and the tab-order check names the `<a>`.
- **08 `/regions/[slug]`:** `heroImage` sits below the header with the trail hero frame (full-width `PhotoMount`, 3:2, tape top centre, 0.5° tilt at `desk`, attribution).
- **03 Pages:** the region detail page renders `heroImage` below the header, as a plain `<img>` in phase 2 that moves into `PhotoMount` in phase 3. Its section order is listed.
- **03 Acceptance:** the region detail check asserts the hero image with a non-empty `alt`. No query change was needed, since `regionBySlugQuery` already projects `heroImage`.

## Decisions

- **OG colours (Sam, 2026-11-04):** `src/lib/og-tokens.ts` mirrors the `--dp-color-*` hex values and is the single file exempt from the hex rule. It is used only by `opengraph-image.tsx` files and kept in sync with `globals.css`. The main session adds the exemption to CLAUDE.md; this review did not touch it.
- **Trip report photo links (Sam, 2026-11-04):** a plain `<a>` to the full-size Sanity CDN image (`urlFor(...).width(1600)`), same tab, no lightbox. `dialog` stays installed from phase 1 but has no planned use.
- **Region hero (Sam, 2026-11-04):** `region.heroImage` renders below the region header with the same frame as the trail page hero.

- Rule for all 08 conflicts: 08 wins. Where 08 contradicted itself (trailLink, `strong`), I kept the more specific statement and made it meet the 08 accessibility checklist.
- Queries stay static `defineQuery` strings with null-able params, never built at runtime, so TypeGen covers every result. This applies to all later phases.
- One tag matrix, in 03. Phase 4 audits it; phases 5 and 6 add `tripReport` and `trailCondition`.
- `urlFor` belongs to phase 2. `SanityImage`, `PhotoMount`, and LQIP belong to phase 3.
- Map colours are read from CSS custom properties at runtime, so map code needs no hex.
- The webhook stays alongside `SanityLive`. It covers visitors with no open live connection, so the `trailCondition` and `tripReport` tags matter.
- The first Vercel deploy is part of phase 4, not phase 3. Phase 3 checks OG output locally.
- The trip report action redirects on both real and honeypot success; failures return `{ ok: false, errors, values }`.
- Only valid submissions count toward the rate limit.
- Small copy and labels chosen where the spec implied but did not state them: "On leash"/"Not allowed", "No trip reports yet.", difficulty and route type labels, per-page metadata titles, the phase 1 placeholder "Trailhead" / "Open the Studio", the trip report photo alt pattern, and the `en-CA` long date. Sam can override any of these without affecting structure.
- The thresholds now written into checks ("within 10 seconds", the OG photo at 520×390, `fitBounds` `maxZoom: 12`, a one-minute tick) are measurable restatements of the specs' own "within seconds", "photo on the right", and "fits bounds".

## Flag for researcher

Not changed in the spec; verify against current docs.

1. **create-next-app**: current flags and prompts (Turbopack, React Compiler, linter choice in place of `--eslint`). Does Next 16 still have `next lint`?
2. **Sanity CLI**: `sanity init --env` and its prompts ("clean project", declining the Studio scaffold). Does `sanity documents query` exist as written?
3. **Sanity TypeGen**: is `sanity-typegen.json` still the config file, or has it moved to a `typegen` key in `sanity.cli.ts`? Is `sanity schema extract && sanity typegen generate` still the recommended `typegen` script?
4. **next-sanity `defineLive`**:
   - Semantics of `serverToken` and `browserToken`.
   - Can `sanityFetch` be called in `generateStaticParams`, or does it need `perspective: "published", stega: false` or plain `client.fetch`? 03 says `sanityFetch` is the only read path.
   - Is the `tags` option honoured alongside the automatic sync tags?
   - Does the webhook duplicate `SanityLive`'s automatic revalidation?
5. **Root layout and the Studio**: `<SanityLive />` and `<VisualEditing />` sit in the root layout, which also wraps `/studio`. Should they move to `(site)/layout.tsx`? Does `globals.css` (Tailwind preflight, body grain) need to be kept out of the Studio?
6. **Draft mode and visual editing**:
   - `previewDrafts` vs `drafts` perspective name.
   - Import path for `VisualEditing`.
   - `stegaClean` from `next-sanity` vs `@sanity/client/stega`.
   - `defineEnableDraftMode` signature.
   - `presentationTool` `previewUrl.previewMode` and `defineLocations` shapes.
7. **Next.js 16**:
   - `revalidateTag` signature: is the second profile argument now required, and does `updateTag` replace it?
   - Where `serverActions.bodySizeLimit` lives in `next.config.ts`.
   - `cacheComponents` and its interaction with next-sanity.
   - Async `params` in `opengraph-image` and its `generateStaticParams`.
   - Precedence of file-based OG metadata.
8. **Tailwind v4**: `@theme inline`, `@utility`, and custom breakpoints (`--breakpoint-sheet`, `--breakpoint-desk`).
9. **shadcn**:
   - What `init` currently emits for Tailwind v4 (oklch vars, `.dark`, `@custom-variant dark`).
   - Is `form` still current, or has `field` replaced it? Does the react-hook-form-based `Form` work with server-returned `useActionState` errors?
   - Is `lucide-react` still installed by `init`?
10. **MapLibre GL**: current API for clustered GeoJSON sources, `addImage` from SVG, and the `NavigationControl` / `AttributionControl({ compact })` options. Check the OpenFreeMap `liberty` URL.
11. **next/og `ImageResponse`**: fetching a Google font TTF at build vs bundling the file. Which image formats does Satori accept (does a Sanity URL need `.format("jpg")`)? Size limits.
12. **`sanity dataset import`**: does `_sanityAsset` work inside a custom image type (`imageWithMeta`) and inside gallery arrays?
13. **@sanity/ui**: tones for the four `DifficultyInput` pills, especially black, without hex. Is `@sanity/color` a usable direct import?
14. **Zod**: the major version installed (v4 API differences) for `trail-filters.ts` and the action schema.
15. **Phase 1 content research (not an API)**:
    - Verify the 12 trails' stats and trailhead coordinates against Alberta Parks.
    - Find CC BY / CC BY-SA Wikimedia Commons photos with author, licence, and URL: at least 3 per trail (hero plus 2 gallery), plus 5 region heroes and 1 site hero.
    - If a difficulty changes, the phase 3 filter check's expected sets change with it.

## Open questions for Sam

None. All three were answered on 2026-11-04 and are recorded under Decisions.
