# Phase 1 — Foundation

## Goal

A running Next.js app with an embedded Sanity Studio, every schema from the content model,
and the seed dataset imported. Nothing on the public site yet beyond a placeholder home page.

## Deliverables

- Next.js app scaffolded with TypeScript, App Router, Tailwind, ESLint, `src/` directory,
  and the `@/*` import alias.
- shadcn/ui initialised, then re-themed: the generated `:root` variables in `globals.css` are
  replaced with the shadcn mapping from `08-design-system.md` and the generated `.dark` block
  is deleted (the site is light only). Install `button`, `badge`, `card`, `input`,
  `textarea`, `label`, `select`, `dialog`, `skeleton` now. Add others per phase.
- Design system foundation: the phase 1 row of the Implementation plan in
  `08-design-system.md` (fonts, tokens, `@theme`, utilities, paper grain, edited shadcn
  components, `src/components/sketch/` marks and `Tape`).
- Fresh Sanity project and `production` dataset created with `sanity init`.
- Studio embedded at `/studio/[[...tool]]` with the Vision plugin enabled.
- All document and object types from `01-content-model.md`.
- Custom `DifficultyInput` component for the difficulty field.
- Structure Builder config matching the structure in the content model.
- Seed data as NDJSON plus an import script, imported into the dataset.
- `.env.local.example` listing every variable from the overview.
- `README.md` with setup steps.

## Implementation notes

### Scaffold

```
pnpm create next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
pnpm dlx shadcn@latest init
pnpm add next-sanity @sanity/image-url @sanity/client sanity @sanity/vision styled-components
pnpm add -D @sanity/cli
```

Record the exact Next.js and Sanity versions that get installed at the top of the README.

Run `shadcn init` as written, then, before building any page, replace the generated `:root`
variables in `src/app/globals.css` with the `--dp-*` tokens and the shadcn mapping from
`08-design-system.md`, and delete the generated `.dark` block.

### Sanity project

`pnpm dlx sanity@latest init --env` inside the project creates the project, dataset, and
writes the two public env vars. Choose "clean project with no predefined schemas" and
decline the Studio scaffold when prompted, since the Studio is embedded by hand.

`sanity.cli.ts` reads project ID and dataset from env so `sanity` CLI commands work.

The embedded Studio at `http://localhost:3000/studio` needs `http://localhost:3000` added as
a CORS origin with credentials allowed in the Sanity project settings. This is a human step.

### Embedded Studio

- `sanity.config.ts` at the project root with `basePath: "/studio"` and project ID and
  dataset from the `NEXT_PUBLIC_SANITY_*` env vars. Plugins: `structureTool({ structure })`,
  `visionTool()`. The Presentation tool is added in phase 4.
- `src/app/studio/[[...tool]]/page.tsx` renders `NextStudio` from `next-sanity/studio`
  with `export const dynamic = "force-static"` and the metadata/viewport exports that
  `next-sanity/studio` provides.
- The Studio route must not be wrapped by the site's layout header and footer. Use a
  route group: `src/app/(site)/` for public pages and `src/app/studio/` outside it, each
  with its own layout.

### Schemas

- One file per type in `sanity/schemaTypes/`, exported from `index.ts` as an array.
- `siteSettings` is a singleton: filter it out of `templates` in `schema` config and out of
  `document.newDocumentOptions`, and the structure opens it by fixed `_id`.
- Validation rules as written in the content model. Use `Rule.required()`, `Rule.min()`,
  `Rule.max()`, `Rule.positive()`, `Rule.integer()`, `Rule.precision(1)` on `distanceKm`,
  a custom rule on `related` to reject a self-reference, and a custom rule on
  `tripReport.hikedOn` to reject future dates.
- Defaults via `initialValue`: `dogsAllowed: true`, `featured: false`,
  `tripReport.status: "pending"`, `trailCondition.reportedAt` set to the current time.
- `tripReport.status` stays editable in phase 1. Phase 5 sets `readOnly: true` once the
  approve and reject document actions exist.

### Custom input

`sanity/components/DifficultyInput.tsx` renders four coloured pills (green, blue, black,
red) using `@sanity/ui`. It receives the standard `StringInputProps` and calls
`onChange(set(value))`. Colours come from `@sanity/ui` tones or theme values, not raw hex
(project rule: no hex outside `globals.css`). This is the only custom input in the project.

### Seed data

- `sanity/seed/data.ndjson` with one document per line. Use readable `_id` values like
  `trail-grassi-lakes`, `region-peter-lougheed`, so references are easy to write by hand.
  Slugs and IDs follow the rules in the content model's Seed content section, and the
  content meets the per-trail requirements listed there.
- Every array item (Portable Text blocks, spans, `markDefs`, gallery images, `related`,
  `featuredTrails`, `highlights`, `photos`) carries a unique `_key`.
- Images reference remote URLs with the import syntax
  `{"_sanityAsset": "image@https://upload.wikimedia.org/..."}` so `sanity dataset import`
  uploads them. Pick CC BY or CC BY-SA files and fill in `attribution`.
- Import with `pnpm sanity dataset import sanity/seed/data.ndjson production --replace`.
  Add this as a `seed` script in `package.json`.
- Trail stats in `01-content-model.md` are approximate. Check each against Alberta Parks
  before seeding and update the content model table to match.

### Scripts in `package.json`

| Script | Command |
| --- | --- |
| `dev` | `next dev` |
| `build` | `next build` |
| `seed` | `sanity dataset import sanity/seed/data.ndjson production --replace` |
| `typegen` | `sanity schema extract && sanity typegen generate` |

`typegen` is used from phase 2 onwards.

### Placeholder home

`src/app/(site)/page.tsx` has no Sanity fetch yet (the client arrives in phase 2). It shows
the statement "Trailhead" in the display face with an `Underline`, and a primary button
"Open the Studio" linking to `/studio`, so the phase 1 design work can be seen.

## Acceptance checks

- `pnpm build` exits 0.
- `pnpm dev` starts, `/` shows the placeholder statement and primary button in the Sketch
  style (paper background, Permanent Marker statement, accent button with pencil shadow),
  and `/studio` loads the Studio and prompts login.
- Every type in the content model appears in the Studio structure under the heading shown
  in the content model's Studio structure tree, and "New document" does not offer Site settings.
- In a new trail, publishing with every field empty shows required errors on `name`, `slug`,
  `region`, `difficulty`, `distanceKm`, `elevationGainM`, `routeType`, `trailhead`,
  `heroImage`, `summary`, and `body`. Entering `distanceKm` 4.25, a 241-character summary,
  six highlights, or the trail itself in `related` each shows a validation error. The
  difficulty field shows the pill input.
- `pnpm seed` exits 0. Then `pnpm sanity documents query 'count(*[_type == "trail"])'`
  returns 12; the same for `region` returns 5, `trailCondition` 12, `tripReport` 5, and
  `count(*[_id == "siteSettings"])` returns 1.
- Opening a seeded trail's hero image shows the hotspot editor and a filled attribution field.
- Vision returns 12 results for `*[_type == "trail"]{name, "region": region->name}`, every
  one with a non-null `region`.
- The hex and small-text greps in the `08-design-system.md` acceptance checks pass.
