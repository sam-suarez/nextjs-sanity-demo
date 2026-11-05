# Design System — "Sketch" Working Sheet

The public site looks like a hiker's trip-planning sheet: warm paper, handwritten notes,
pencil drawings, blue annotations, red actions and corrections, yellow highlighter, and
photos taped on as references. Consistent spacing and a strict token set keep it legible.

This spec applies to everything under `src/app/(site)/` and to the generated OG images.
The embedded Studio at `/studio` keeps Sanity's own UI and is out of scope.

The base brief is the "Sketch" design system; its tokens are reproduced verbatim in the
Authoritative tokens section. Everything else here maps that brief onto Trailhead's
actual routes, content model, and the Tailwind + shadcn/ui stack chosen in `00-overview.md`.

## Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Theme | Light only, always paper | The brief defines one surface. A dark variant would be a different identity. See "Conflicts with earlier phases" |
| Display font | Permanent Marker (Google Fonts) via `next/font/google` | Heavy marker stroke, one weight, one file. Stands in for "Sketch Working Marker" |
| Reading font | Patrick Hand (Google Fonts) via `next/font/google` | Upright print handwriting, most legible of the handwritten families at paragraph length. Stands in for "Sketch Working Hand" |
| Token layer | `--dp-*` custom properties in `globals.css`, then mapped onto shadcn's semantic variables and Tailwind's `@theme` | Generated shadcn components pick up paper, ink, and accent without rewriting their markup |
| Breakpoints | Custom `sheet` (680px) and `desk` (1050px) in addition to Tailwind defaults | The brief's layout rules are written against these widths |
| Difficulty | Ski-run symbols: green circle, blue square, black diamond, red double diamond | Matches the four pill colours in the Studio `DifficultyInput`; drawn shapes fit the sketch idiom and read without colour |
| Extra colour | One: pencil green `#46703f` for "open" and "easy" | The brief has no green; condition status needs one. Caution reuses the yellow highlight, closed reuses accent red |
| Drawn marks | Static inline SVG components under `src/components/sketch/` | No stroke animation, no SVG filters on live elements, hidden from assistive tech |
| Irregular edges | `border-radius` tokens plus 1.5px strokes and hard offset shadows | Cheap, consistent, works on every shadcn primitive. No displacement filters |
| Primary button | Filled accent red with paper text and a pencil offset shadow | "Red marks actions". Secondary buttons are ink-outlined on paper |

## Conflicts with earlier phases

All resolved in the spec review of 2026-11-04 by editing the phase files in place. Listed
here so the history is visible; the phase files are now consistent with this spec.

- **Resolved.** `07-phase-6-live-conditions-maps.md` asked for light and dark map styles that
  follow `prefers-color-scheme`. It now always uses the OpenFreeMap `liberty` style, and the
  "Maps swap styles when the OS theme changes" acceptance check is removed.
- **Resolved.** `02-phase-1-foundation.md` installed shadcn "with the default theme". It now
  runs `shadcn init`, then replaces the generated `:root` variables in `globals.css` with the
  mapping in this spec (and deletes the generated `.dark` block) before building any page.
- **Resolved.** `03-phase-2-core-pages.md` said `DifficultyBadge` maps difficulty to "a shadcn
  `Badge` variant". It now renders the difficulty symbol plus a text label (see Components).
- **Resolved.** `04-phase-3-images-seo-filters.md` loaded "one weight of a Google font" for OG
  images. That font is now named as Permanent Marker, and its OG layout follows the Images
  section of this spec (paper background, no dark gradient).

## Authoritative tokens

Reproduced from the brief. These values are not to be tuned.

| CSS variable | Value |
| --- | --- |
| `--dp-color-ground` | `#f7f2e7` |
| `--dp-color-ink` | `#38352f` |
| `--dp-color-ink-muted` | `#514d44` |
| `--dp-color-line` | `#b3ac9d` |
| `--dp-color-accent` | `#9e3a2e` |
| `--dp-color-annotation` | `#344c69` |
| `--dp-color-highlight` | `#f0dfa0` |
| `--dp-color-scrap` | `#fcf8ef` |
| `--dp-typography-reading-face` | `"Sketch Working Hand", cursive` |
| `--dp-typography-display-face` | `"Sketch Working Marker", cursive` |
| `--dp-typography-body` | `24px` |
| `--dp-typography-reading` | `23px` |
| `--dp-typography-detail` | `21px` |
| `--dp-spacing-item-gap` | `16px` |
| `--dp-radius-control` | `9px 4px 17px 5px / 4px 12px 5px 9px` |
| `--dp-border-fine-stroke` | `1.5px` |
| `--dp-motion-control` | `100ms` |

### Extension tokens

Added for this project. Prefixed the same way so they are easy to find.

| CSS variable | Value | Use |
| --- | --- | --- |
| `--dp-color-pencil-green` | `#46703f` | Condition `open`, difficulty `easy`. 5.2:1 on ground |
| `--dp-radius-note` | `14px 6px 18px 8px / 6px 16px 7px 12px` | Cards, notes, photo mounts, map mount |
| `--dp-radius-control-alt` | `5px 17px 4px 9px / 9px 5px 12px 4px` | Second button in a pair, so neighbours do not share an outline |
| `--dp-shadow-pencil` | `2px 2px 0 var(--dp-color-ink)` | Resting offset shadow on buttons and inputs |
| `--dp-shadow-accent` | `2px 2px 0 var(--dp-color-accent)` | Offset shadow on the primary action in a group |
| `--dp-stroke-mark` | `2px` | Stroke width for drawn SVG marks |
| `--dp-spacing-section` | `clamp(56px, 8vw, 112px)` | Vertical gap between page sections |
| `--dp-measure-reading` | `34em` | Max width of continuous reading text |
| `--dp-tilt-note` | `-1.2deg` | Default rotation for a selected note or heading at `desk` and up |

The font-face tokens stay as written. The real families are supplied through fallbacks:

```css
--font-display-stack: "Sketch Working Marker", var(--font-display), cursive;
--font-reading-stack: "Sketch Working Hand", var(--font-reading), cursive;
```

where `--font-display` and `--font-reading` are the `variable` names given to the
`next/font/google` loaders in the root layout. If the original drawn fonts are ever added
as local files, they take over with no other change.

### shadcn mapping

In `globals.css`, after the `--dp-*` block, assign shadcn's semantic variables from the tokens.
Nothing in `src/components/ui/` references a raw hex value.

| shadcn variable | Token |
| --- | --- |
| `--background` | ground |
| `--foreground` | ink |
| `--card`, `--popover` | scrap |
| `--card-foreground`, `--popover-foreground` | ink |
| `--primary` | accent |
| `--primary-foreground` | ground |
| `--secondary` | scrap |
| `--secondary-foreground` | ink |
| `--muted` | scrap |
| `--muted-foreground` | ink-muted |
| `--accent` | highlight |
| `--accent-foreground` | ink |
| `--destructive` | accent |
| `--border`, `--input` | line |
| `--ring` | annotation |
| `--radius` | unused; components apply `--dp-radius-control` or `--dp-radius-note` directly |

### Tailwind theme

Tailwind v4 `@theme inline` block exposing the tokens as utilities:

- Colours: `ground`, `ink`, `ink-muted`, `line`, `accent`, `annotation`, `highlight`,
  `scrap`, `pencil-green` (so `bg-scrap`, `text-annotation`, `border-line` work).
- Fonts: `font-display`, `font-reading`.
- Text sizes: `text-body` (24px / 1.5), `text-reading` (23px / 1.55), `text-detail` (21px / 1.45).
- Breakpoints: `sheet` = 680px, `desk` = 1050px.
- Custom utilities via `@utility`: `sketch-edge` (control radius, fine stroke, ink border),
  `sketch-edge-alt`, `sketch-note` (note radius, line-colour border, scrap background),
  `sketch-shadow`, `sketch-shadow-accent`, `sketch-focus` (dashed annotation outline).

## Typography

| Role | Face | Size | Line height | Notes |
| --- | --- | --- | --- | --- |
| Statement (home opening) | display | `clamp(44px, 7vw, 84px)` | 1.05 | One per site. Irregular red underline under one word |
| Page title (`h1`) | display | `clamp(36px, 5vw, 60px)` | 1.1 | Rotated `--dp-tilt-note` at `desk` only |
| Section heading (`h2`) | display | 36px desk, 30px below | 1.15 | Never rotated; may carry an underline |
| Sub heading (`h3`) | display | 28px | 1.2 | |
| Stat value | display | 32px | 1 | Under the facts bracket |
| Body / UI | reading | 24px (body token) | 1.5 | Nav, buttons, cards, labels, inputs |
| Reading | reading | 23px (reading token) | 1.55 | Portable Text paragraphs, descriptions, trip report bodies |
| Detail | reading | 21px (detail token) | 1.45 | Captions, attribution, counts, form hints, timestamps |

Rules:

- Nothing below 21px. The hand face needs its size; do not use Tailwind `text-xs`, `text-sm`,
  `text-base`, `text-lg`, or `text-xl` (all under 21px) anywhere in `(site)` or in the
  `src/components/` files it renders. Strip them from generated shadcn components when
  editing them. Use `text-detail`, `text-reading`, `text-body`, or a display size.
- Paragraphs are never rotated. Rotation is reserved for a single heading, selected notes, photo mounts, and tape.
- Headings get `text-wrap: balance`; reading text gets `text-wrap: pretty`.
- Letter spacing stays at the font's default. Do not tighten.
- Numbers in facts use the display face so they read as marker-written stats; their units and labels use the reading face at detail size.
- `next/font` loaders set `display: "swap"` and `adjustFontFallback` so layout does not jump when the handwriting loads.

## Colour

What each colour means on this site. Keep to these meanings so the page stays readable.

| Token | Meaning | Where |
| --- | --- | --- |
| ground | The sheet | `body` background with faint grain |
| ink | Primary text and drawn strokes | Headings, body, symbols, outlines |
| ink-muted | Secondary text | Captions, meta, labels, disabled text |
| line | Quiet rules and erased edges | Dividers, note borders, skeletons. Never text |
| accent | Actions, emphasis, closures, errors | Primary buttons, active underline, `closed` condition, `danger` callout, form errors, closing statement, star ratings |
| annotation | Editorial notes and cross references | Region labels, result counts, `info` callouts, access notes, Studio link, draft banner, focus outline |
| highlight | Marked for attention | `caution` condition, `warning` callout, selected filter, selected comparison |
| scrap | A lighter piece of paper | Cards, notes, photo mounts, inputs, popups, toasts |
| pencil-green | All clear | `open` condition, `easy` difficulty |

Contrast (WCAG, computed):

| Pair | Ratio |
| --- | --- |
| ink on ground | 10.9 |
| ink-muted on ground | 7.5 |
| accent on ground | 6.1 |
| annotation on ground | 7.9 |
| ink on highlight | 9.2 |
| accent on highlight | 5.1 |
| ground on accent (primary button) | 6.1 |
| ground on annotation (draft banner) | 7.9 |
| pencil-green on ground | 5.2 |
| line on ground | 2.0 (decorative only) |

## Surfaces and marks

### Paper

- `body`: ground colour plus a grain layer: an inline SVG `feTurbulence` noise as a
  `background-image` data URI at roughly 4% opacity, tiled. One asset, no JS.
- Sections sit directly on the sheet. Cards and notes use scrap. Never stack scrap on scrap.
- Rules between sections are drawn: `<Rule />` renders a slightly uneven horizontal SVG path
  in line colour. Used under the header, above the footer, between footer groups.

### Scrap notes

`sketch-note`: scrap background, 1.5px line-colour border, `--dp-radius-note`, 16px padding
(24px at `sheet`). Optional `tilt` prop applies a rotation of -1.5° to 1.5° at `desk` only.
Optional `<Tape />` child.

### Tape

`<Tape position="top" | "top-left" | "top-right" | "corner" />`: absolutely positioned
strip, 88×26px, highlight colour at 55% opacity over a 30% white, torn ends via
`clip-path: polygon(...)`, rotated -4° to 6° by position. `aria-hidden`, `pointer-events: none`.

### Drawn marks (`src/components/sketch/`)

All are static SVG, `aria-hidden="true" focusable="false"`, `vector-effect: non-scaling-stroke`,
`stroke-linecap: round`, stroke `--dp-stroke-mark`, `currentColor` so the parent sets the colour.

| Component | Draws | Used by |
| --- | --- | --- |
| `Underline` | Irregular single stroke, slightly thicker in the middle | Hero statement word, active nav link, page titles |
| `Arrow` | Curved hand-drawn arrow with an open head; `direction` prop | Home opening pointing at the primary action; report page pointing at submit (`desk` only) |
| `Bracket` | Horizontal brace | Above the facts row on trail pages |
| `Check` | Single tick | Highlights list, `open` condition |
| `Circled` | Rough circle around a child (number or icon) | Process steps on the report page, `caution` and `closed` icons |
| `Star` | Five-point star, `filled` prop | Ratings |
| `Difficulty` | Circle, square, diamond, double diamond by value | Badges, filter toggles, map points |
| `Rule` | Uneven horizontal rule | Header, footer, section dividers |
| `Pin` | Map marker outline | Trailhead marker |
| `MountainDoodle` | Three-line ridge sketch | Home opening, 404 page |

Marks direct attention or group content. They never sit over text, never change reading
order, and never animate.

## Layout

- Container: `max-width: 1180px`, side gutter 16px, 24px at `sheet`, 40px at `desk`.
- Reading column: `--dp-measure-reading` (34em of the reading face, about 780px).
- Section spacing: `--dp-spacing-section` between sections; `--dp-spacing-item-gap` inside groups.
- Grid gaps are `--dp-spacing-item-gap` or double it. No other gap values.

### Header

Site title from `siteSettings.title` in the display face at 28px, linking home. Nav: "Trails",
"Regions" in the reading face at body size. The current section gets an accent `Underline`;
hover shows an ink one. A drawn `Rule` closes the header. Fits one row at 360px; no menu button.

### Footer

A `Rule`, then two groups side by side even on mobile: navigation (Trails, Regions) and
a Studio link in annotation blue. Below them, the closing statement: `siteSettings.footerNote`
in the display face at `h2` size, accent red. If the note exceeds 120 characters, render it
in the reading face instead so it stays a sentence and not a wall of marker.

### Page compositions

**`/` Home**

1. Opening split at `desk`: left, the tagline as the statement with its last word underlined,
   `siteSettings.intro` beneath it as a cluster of reading-size notes, then the primary
   button "Browse trails" with an `Arrow` curving toward it and a secondary "Regions" button.
   Right, `siteSettings.heroImage` in a `PhotoMount` tilted 1.5° with a `MountainDoodle`
   beside it. Below `desk`: statement, notes, buttons, then the photo, full width.
2. "Featured trails": four `TrailCard`s. Single column, two at `sheet`, four at `desk`
   with every second card offset 16px down (the staggered reference row).
3. "Regions": five `RegionCard`s. Single column, two at `sheet`, three at `desk`.
4. Footer with the closing statement.

**`/trails`**

1. `h1` "Trails" and the `FilterBar` on a slightly darker paper strip: a full-bleed band
   with background `color-mix(in oklab, var(--dp-color-ground), var(--dp-color-line) 18%)`
   and an irregular top and bottom edge drawn with `Rule`.
2. Result line: count as an annotation note ("12 trails") and, when any filter is active,
   a "Clear filters" link in accent.
3. `TrailCard` grid: one, two at `sheet`, three at `desk`. Skeleton grid matches.
4. Empty state: one scrap note, display-face line, reading-face sentence, a link back to `/trails`.

**`/trails/[slug]`**

1. Header: region name as an annotation-blue link, `h1` name with an `Underline`,
   `DifficultyBadge` and route type on one line, then `summary` at reading size.
2. Facts under a `Bracket`: distance, elevation gain, route type, estimated hours, season,
   dogs ("On leash" when `dogsAllowed` is true, "Not allowed" when false). Two columns, one
   row at `sheet`. Values in the display face, labels at detail size.
   Omit facts whose field is empty; never show a dash.
3. Condition banner (phase 6) directly under the facts. See Components.
4. `heroImage` in a full-width `PhotoMount`, 3:2, tape at top centre, 0.5° tilt at `desk`,
   attribution caption at detail size.
5. Body: Portable Text in the reading column. Galleries and callouts can break out to the
   container width.
6. Highlights: `h3` and a list with `Check` marks. Omitted when `highlights` is empty.
7. Map (phase 6) in a mount, then the "Open in Google Maps" link.
8. Trip reports (phase 5): `h2`, "Write a report" primary button, then speech notes. With no
   approved reports, the button is followed by "No trip reports yet." at reading size.
9. Related trails: `h2` and up to three `TrailCard`s. Omitted when `related` is empty.

**`/trails/[slug]/report`**

1. `h1` "Report on {trail name}" and a back link to the trail.
2. A three-step process strip on the darker paper band with `Circled` numbers and connecting
   `Arrow`s: write it, an editor reads it, it appears on the trail page. Horizontal at `desk`,
   stacked below. This is the one place the brief's process layout is used; its copy tells
   visitors why their report does not appear immediately.
3. The form on one large scrap note (see `TripReportForm`).

**`/regions`**

`h1` "Regions", then `RegionCard`s with the photo mount on the left and name, description,
and trail count on the right. One column, two at `sheet`.

**`/regions/[slug]`**

Header like a trail page (name, description, no facts). Then `heroImage` with the same frame
as the trail page hero: full-width `PhotoMount`, 3:2, tape at top centre, 0.5° tilt at
`desk`, attribution caption at detail size. Then `accessNotes` rendered as one
annotation note: scrap, annotation border, "Access" label in annotation blue. Then the
cluster map in a mount, then the trail grid.

**`not-found.tsx`**

A `MountainDoodle`, the line "Not on this map." in the display face, accent red, a
reading-size sentence, and a primary button to `/trails`.

## Components

Every component keeps its real semantics (`button`, `a`, `fieldset`, `details`) under the
drawn appearance. Generated shadcn files in `src/components/ui/` are edited in place; do not
wrap them.

### Buttons (`ui/button.tsx`)

| Variant | Resting | Hover | Active | Disabled |
| --- | --- | --- | --- | --- |
| `default` | accent fill, ground text, `sketch-edge`, pencil shadow, rotated -0.5° | rotation 0°, shadow 1px 1px, translate 1px | translate 2px, no shadow | ink-muted fill at 60%, no shadow, no tilt |
| `secondary` | scrap fill, ink text, ink outline, pencil shadow | same | same | same |
| `outline` | transparent, ink outline, no shadow | pencil shadow appears | pressed | same |
| `ghost` | text only | highlight background | pressed | same |
| `link` | reading face, ink, `Underline` on hover | | | |

Adjacent buttons alternate `sketch-edge` and `sketch-edge-alt`. Focus: 2px dashed annotation
outline, offset 3px, on every variant. Transitions on `transform` and `box-shadow` only, at
`--dp-motion-control`. Minimum hit area 44×44px.

### Badges (`ui/badge.tsx`) and `DifficultyBadge`

`DifficultyBadge` renders `<Difficulty value>` at 18px beside a text label ("Easy",
"Moderate", "Hard", "Scramble") in the reading face at detail size. Colours: easy
pencil-green, moderate annotation, hard ink, scramble accent. The label is always visible;
colour and shape are reinforcement, not the only cue. Used on cards, trail headers, and filter
toggles. `trailLink` marks use the bare `Difficulty` symbol inline (see Portable Text) with the
label as visually hidden text, so the difficulty is still not conveyed by shape alone.

Other badges (`routeType`, counts) are plain text with a thin ink outline and the control radius.

### Cards (`ui/card.tsx`), `TrailCard`, `RegionCard`

A card is a scrap note. `TrailCard`:

- Whole card is one link (`next/link` wrapping the note; no nested interactive elements).
- `PhotoMount` of `heroImage` at 3:2 with tape at the top, inside the note.
- Name in the display face at `h3` size.
- Region in annotation blue at detail size.
- Stats line in the reading face: distance, gain, route type, with the `DifficultyBadge`.
- Condition dot (phase 6): 12px circle, ink outline, fill by status, top-right of the
  note, with visually hidden text "Trail open" / "Caution" / "Closed". No dot when the trail
  has no condition document.
- Hover at `desk`: rotate 0.6°, shadow compresses. Reduced motion: outline darkens instead.

`RegionCard` is the same note with the photo on the left at `sheet` and the trail count as
an annotation ("7 trails").

### Inputs (`ui/input.tsx`, `ui/textarea.tsx`, `ui/select.tsx`, `ui/label.tsx`)

- Scrap background, ink outline, `sketch-edge`, pencil shadow, reading face at body size,
  12px 14px padding. Focus swaps the shadow for the dashed annotation outline.
- Labels: reading face, ink, above the field. Hints and character counts: detail size, ink-muted.
- Errors: detail size, accent, prefixed by a small `Arrow` pointing at the field, with
  `aria-describedby` on the input and `aria-invalid="true"`.
- Select content: scrap popover with `sketch-note`, items highlight on hover.

### FilterBar

Client component on the darker paper band. Region `Select`, difficulty toggle group,
distance `Select`, sort `Select`. Difficulty toggles are `button[aria-pressed]` showing the
symbol and label; the pressed state gets a highlight background behind the label (the
brief's "yellow behind the featured choice"). "Clear filters" is a `link` button in accent.

### Portable Text (`src/components/portable-text/`)

| Block | Treatment |
| --- | --- |
| `normal` | Reading size, margin `--dp-spacing-item-gap` |
| `h2`, `h3` | Display face sizes above, extra top margin |
| `blockquote` | Outlined speech note: scrap, ink outline, note radius, a small drawn tail at bottom-left, reading size |
| bullet list | Hand-drawn dash markers via `::marker` content "– " in ink |
| number list | Default numerals in the reading face |
| `strong` | The reading face has one weight; render as ink with a highlight underline (`text-decoration-color: highlight`, thickness 6px, offset -4px) so emphasis reads as a highlighter stroke |
| `em` | Italic is synthesized; use annotation colour instead |
| `link` | Ink, underlined, accent on hover, external icon when `openInNewTab` |
| `trailLink` | Same as link plus the `Difficulty` symbol inline before the text and the difficulty label as visually hidden text |
| `callout` `info` | Annotation note: scrap, annotation border, `Info` icon from `lucide-react` in annotation |
| `callout` `warning` | Highlight band: highlight background, no border, ink text, `TriangleAlert` icon |
| `callout` `danger` | Accent outline 2px, note radius, title in display face accent, `OctagonAlert` icon |
| `gallery` | Row of `PhotoMount`s, two per row at `sheet`, three at `desk`, alternating tilts of -1.5° and 1°, caption centred at detail size |

### `PhotoMount` and `SanityImage`

`PhotoMount` wraps `SanityImage` (phase 3). Props: `tilt`, `tape`, `aspect`, `caption`,
`showAttribution`. Scrap mount, 10px padding, line-colour border, note radius, tape by
default. Rotation applies to the mount only and only at `desk`; the image keeps its
`sizes` and reserved aspect ratio so there is no layout shift. Photos stay natural colour:
no sepia, no sketch filters. Attribution renders under the mount at detail size, ink-muted,
with the `attributionUrl` link.

### Condition banner (`TrailConditions`, phase 6)

| Status | Treatment |
| --- | --- |
| `open` | One line, no box: `Check` in pencil-green, headline in ink, "Reported 3 hours ago" at detail size |
| `caution` | Highlight band full width of the reading column, `Circled` "!" in ink, headline in display face ink, details at reading size |
| `closed` | Accent outline 2px, note radius, `Circled` "×" in accent, headline in display face accent, details in ink |
| none | "No recent reports" at detail size, ink-muted |

Content swaps in place when the Live Content API pushes an update. No animation.

### Trip reports (`TripReports`, `TripReportForm`, phase 5)

- Each report is an outlined speech note: author name in the display face at `h3` size,
  "Hiked on {date}" at detail size, a row of five `Star`s with the filled count in accent
  and a visually hidden "4 out of 5", the body at reading size, then a strip of up to three
  `PhotoMount`s at 1:1, tilted alternately. Each photo is wrapped in a plain `<a>` to the
  full-size image (same tab, no lightbox), with the dashed focus outline.
- `TripReportForm`: one large scrap note holding the fields. Rating is a `fieldset` of five
  radio inputs; each label draws a `Star`, filled through the checked one, with the visible
  legend "Rating". Photos use a styled label around the file input: dashed ink outline,
  "Add up to 3 photos" in the reading face, selected file names listed beneath. Submit is
  the primary button with an `Arrow` pointing at it at `desk`. The honeypot field is
  visually hidden with no sketch styling.
- Thank-you toast (`ui/sonner.tsx`): scrap note with tape, reading face, no slide transform
  under reduced motion.

### Draft mode banner (phase 4)

Fixed to the bottom edge, annotation background, ground text, reading face at detail size:
"Viewing drafts" and an "Exit" link underlined in ground. Not tilted, no tape. `z-index`
above the map.

### Skeletons (`ui/skeleton.tsx`)

Line-colour blocks on scrap at the same dimensions as the content. No shimmer: the pulse
animation is removed, not just disabled under reduced motion.

### Maps (phase 6)

- The map container sits in a `PhotoMount` with `tilt={0}`, no tape, and `aspect="3/2"`;
  interactive surfaces are never rotated.
- Style: `liberty` always. The canvas is left in natural colour, like a photo.
- Map paint colours (cluster fill and stroke, difficulty icons) are read at runtime from the
  `--dp-color-*` custom properties with `getComputedStyle(document.documentElement)`, so map
  code holds no hex values.
- The attribution control is `compact` and its text is restyled to detail size (21px).
- Trailhead marker: a DOM marker rendering `Pin` in accent at 36px.
- Region map: cluster circles with scrap fill and ink stroke; single points use the
  difficulty colours. Popups are restyled through `.maplibregl-popup-content`: scrap,
  `sketch-note`, reading face, name as a link.
- Navigation control buttons get the ink outline and dashed focus.

## Images

Natural-colour photographs from Wikimedia Commons, always inside a `PhotoMount`. Crop scenes
around the subject using the Sanity hotspot; contain artwork if any is ever added. Reserve
dimensions on every image. `alt` comes from `imageWithMeta.alt` and is never empty; tape,
arrows, and doodles are `aria-hidden`.

OG images (`opengraph-image.tsx`): ground background, trail name in Permanent Marker 72px
ink, region in annotation at 32px, stats row in accent, and the hero photo on the right in a
scrap mount with a tape rectangle, rotated 2°. Regions: name, trail count, photo. One font
file, loaded at build.

`ImageResponse` cannot read CSS custom properties, so OG files take their colours from
`src/lib/og-tokens.ts`: a plain object mirroring the `--dp-color-*` hex values the cards use
(ground, ink, annotation, accent, scrap, line, highlight; add pencil-green only if a card
starts using it). It is the only file outside `globals.css` allowed to hold hex values, it
is imported only by `opengraph-image.tsx` files, and it must be kept in sync with
`globals.css`: change a token in both places or neither. A header comment in the file says so.

## Motion

- Only buttons, cards, and inputs transition, on `transform` and `box-shadow`, for
  `--dp-motion-control`.
- Handwriting, arrows, paper, tape, and sketches are still. No stroke drawing, no shimmer,
  no parallax.
- `@media (prefers-reduced-motion: reduce)`: remove interactive transforms and transitions.
  Static tilts stay, since they never change. Hover and press still show through outline
  and background changes.

## Responsive behaviour

| Width | Behaviour |
| --- | --- |
| Below `sheet` | Single column. Facts in two columns. Footer groups in two columns. Rotations and offset stagger off. Tape stays. Reading text keeps its full size |
| `sheet` (680px) | Trail and region cards in two columns. Facts expand to one row. Gallery two per row. Region card photo moves to the left |
| `desk` (1050px) | Home opening split. Featured row staggers. Trail grid three columns. Process strip horizontal. Tilts on. `h1` rotated |

Verify every state at 360px, 680px, and 1050px, not only at a desktop width.

## Accessibility checklist

- Every interactive element shows the dashed annotation focus outline.
- Difficulty and condition are never conveyed by colour or shape alone.
- Drawn marks, tape, and doodles carry `aria-hidden` and `pointer-events: none`.
- Reading order matches visual order; the opening split is source-ordered text then image.
- No text under 21px; no text in line colour.
- Rotation never applies to a block of body text or to an interactive map.
- Form errors are associated with fields through `aria-describedby`.
- Values used in logic, `href`, or `className` pass through `stegaClean` (phase 4).

## Design limits

- No cursive or script faces, no second display face.
- No crumpled or heavy paper textures, no coffee stains, no dense doodle borders.
- No polished geometric cards, no drop blur, no gradients.
- No invented content: no fake comments, prices, team doodles, or comparison ledgers.
- At most one tilted heading and one arrow per view. Marks must earn their place.
- Scrap never on scrap; highlight never as a large background.

## Implementation plan

| Phase | Design work |
| --- | --- |
| 1 | Fonts in the root layout. `globals.css` with tokens, shadcn mapping, `@theme`, utilities, paper grain. Edit `button`, `badge`, `card`, `input`, `textarea`, `label`, `select`, `skeleton`. Build `src/components/sketch/` marks and `Tape`. Placeholder home shows the statement and a primary button |
| 2 | Header, footer, `Rule`, `TrailCard`, `RegionCard`, `DifficultyBadge`, Portable Text set, `not-found` |
| 3 | `PhotoMount` around `SanityImage`, gallery mounts, OG image treatment, `FilterBar` on the paper band, skeleton grid, empty state |
| 4 | `DraftModeBanner` |
| 5 | `TripReportForm`, star rating, speech notes, process strip, toast |
| 6 | Condition banner, card dot, map mount, `Pin`, popup styles |

Each phase's acceptance includes the checks below that apply to what exists at the end of
that phase.

## Acceptance checks

- Every colour in `src/` resolves to a `--dp-*` token; `grep -rniE "#[0-9a-f]{6}\b" src/ sanity/ --include='*.ts' --include='*.tsx' --include='*.css' | grep -v '^src/lib/og-tokens\.ts:'` returns only lines in `src/app/globals.css`. `src/lib/og-tokens.ts` is the single exempt file (see Images), and every hex value in it equals the matching `--dp-color-*` value in `globals.css`.
- `grep -rnE "\btext-(xs|sm|base|lg|xl)\b" "src/app/(site)" src/components` returns nothing.
- Both fonts load through `next/font`; no `@import` of Google Fonts CSS at runtime.
- Keyboard tab order on the trail page reaches header, the region link, map controls, "Write a report", every trip report photo link (the plain `<a>` around each photo), related cards, and footer, with a visible dashed outline at each stop.
- With `prefers-reduced-motion: reduce`, hovering a button changes outline and shadow but nothing moves.
- At 360px no horizontal scroll on any route, and no text smaller than 21px (check with the device toolbar).
- Difficulty is readable with colour removed (grayscale emulation) via its symbol and label.
- Lighthouse accessibility on the trail page scores 100; performance stays at 90+ with the grain and fonts in place.
- Screen reader reads no tape, arrow, or doodle.
