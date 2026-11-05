# Phase 1 — Foundation

## Goal

A running Next.js app with an embedded Sanity Studio, every schema from the content model,
and the seed dataset imported. Nothing on the public site yet beyond a placeholder home page.

## Deliverables

- Next.js app scaffolded with TypeScript, App Router, Tailwind, ESLint, `src/` directory,
  and the `@/*` import alias.
- shadcn/ui initialised with the default theme. Install `button`, `badge`, `card`, `input`,
  `textarea`, `label`, `select`, `dialog`, `skeleton` now. Add others per phase.
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

### Sanity project

`pnpm dlx sanity@latest init --env` inside the project creates the project, dataset, and
writes the two public env vars. Choose "clean project with no predefined schemas" and
decline the Studio scaffold when prompted, since the Studio is embedded by hand.

`sanity.cli.ts` reads project ID and dataset from env so `sanity` CLI commands work.

### Embedded Studio

- `sanity.config.ts` at the project root. Plugins: `structureTool({ structure })`,
  `visionTool()`. The Presentation tool is added in phase 4.
- `src/app/studio/[[...tool]]/page.tsx` renders `NextStudio` from `next-sanity/studio`
  with `export const dynamic = "force-static"` and the metadata/viewport exports that
  `next-sanity/studio` provides.
- The Studio route must not be wrapped by the site's layout header and footer. Use a
  route group: `src/app/(site)/` for public pages and `src/app/studio/` outside it, each
  with its own layout.

### Schemas

- One file per type in `sanity/schemaTypes/`, exported from `index.ts` as an array.
- `siteSettings` is a singleton: filter it out of `templates` in `schema` config, and
  the structure opens it by fixed `_id`.
- Validation rules as written in the content model. Use `Rule.required()`,
  `Rule.max()`, `Rule.positive()`, `Rule.integer()`, and a custom rule on `related`
  to reject a self-reference.
- `tripReport.status` is `readOnly: true` so editors must use the document actions
  added in phase 5. Until then, allow it to be edited for seeding convenience and flip it
  in phase 5.

### Custom input

`sanity/components/DifficultyInput.tsx` renders four coloured pills (green, blue, black,
red) using `@sanity/ui`. It receives the standard `StringInputProps` and calls
`onChange(set(value))`. This is the only custom input in the project.

### Seed data

- `sanity/seed/data.ndjson` with one document per line. Use readable `_id` values like
  `trail-grassi-lakes`, `region-peter-lougheed`, so references are easy to write by hand.
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

## Acceptance checks

- `pnpm dev` starts, `/` shows a placeholder, `/studio` loads the Studio and prompts login.
- Every type in the content model appears in the Studio structure under the right heading.
- Creating a trail enforces all validation rules; the difficulty field shows the pill input.
- `pnpm seed` completes without errors and the Studio shows 12 trails, 5 regions,
  12 conditions, 5 trip reports, and the site settings document.
- Images in seeded documents show their hotspot editor and the attribution field is filled.
- Vision tool returns results for `*[_type == "trail"]{name, region->name}`.
