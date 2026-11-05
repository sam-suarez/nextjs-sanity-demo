# Trailhead — Project Overview

A hiking trail guide for Kananaskis Country, Alberta, built with Next.js and Sanity.
Each phase adds a feature that uses a different part of the stack, and each phase ends in
a working state that can be run on its own.

## Spec files

| File | Contents |
| --- | --- |
| `00-overview.md` | Goals, stack, decisions, routes, environment, folder layout |
| `01-content-model.md` | Every Sanity document and object type, field by field |
| `02-phase-1-foundation.md` | Scaffold, embedded Studio, schemas, seed content |
| `03-phase-2-core-pages.md` | GROQ queries, TypeGen, trail/region pages, Portable Text |
| `04-phase-3-images-seo-filters.md` | Image pipeline, metadata, OG images, filtering |
| `05-phase-4-editorial-workflow.md` | Draft mode, Presentation tool, webhook revalidation |
| `06-phase-5-trip-reports.md` | User submissions via server action, moderation in Studio |
| `07-phase-6-live-conditions-maps.md` | Live Content API for conditions, MapLibre maps |
| `08-design-system.md` | Visual design: "Sketch" working-sheet theme, tokens, components, page compositions |

## Goals

- Use the parts of Sanity that a plain blog does not: references, geopoints,
  image hotspots, custom Portable Text blocks, Structure Builder, document actions,
  visual editing, and the Live Content API.
- Use the parts of Next.js that make a content site fast and correct:
  static generation with on-demand revalidation, draft mode, server actions,
  streaming with Suspense, the Metadata API, and generated OG images.
- Keep the scope small enough that the whole site can be walked through in about
  15 minutes.

## Non-goals

- User accounts or authentication. Trip reports are anonymous and moderated.
- Offline support, GPX downloads, or elevation profiles.
- Multi-language content.
- A production-grade moderation pipeline. One editor approving reports in the Studio is enough.

## Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Framework | Latest stable Next.js, App Router, TypeScript strict | Pin the exact version at scaffold time and record it in phase 1 |
| Package manager | pnpm | Fast, strict by default |
| Styling | Tailwind CSS + shadcn/ui, themed as the "Sketch" working sheet (`08-design-system.md`) | Fast to build, good form and dialog primitives; tokens map onto shadcn variables |
| Sanity project | Fresh project created in phase 1, single `production` dataset | Nothing to migrate |
| Studio | Embedded at `/studio` using `next-sanity/studio` | One deploy, one domain, shares env vars |
| Sanity client | `next-sanity` with `defineLive` | Gives `sanityFetch` and `SanityLive` for both cached and live queries |
| Types | Sanity TypeGen from GROQ queries | No hand-written result types |
| Maps | MapLibre GL + OpenFreeMap tiles | No API key, vector tiles, free |
| Hosting | Vercel | Native Next.js support, simplest webhook target |
| Runtime | Node.js for all routes | Sanity client and image generation are simpler on Node |
| Seed content | ~12 real Kananaskis trails, Wikimedia Commons photos with attribution | Real places with real stats and photos |
| Trip reports | Anonymous, honeypot plus rate limit, held as `pending` until approved | No auth in scope |

## Routes

| Route | Rendering | Notes |
| --- | --- | --- |
| `/` | Static, revalidated by tag | Hero from site settings, featured trails, region grid |
| `/trails` | Dynamic (search params) | Filterable list, results stream in under Suspense |
| `/trails/[slug]` | Static via `generateStaticParams`, revalidated by tag | Trail detail, map, conditions (live), approved trip reports |
| `/trails/[slug]/report` | Static shell, server action | Trip report submission form |
| `/trails/[slug]/opengraph-image` | Static, revalidated with page | Generated OG image |
| `/regions` | Static, revalidated by tag | All regions with trail counts |
| `/regions/[slug]` | Static via `generateStaticParams`, revalidated by tag | Region intro, trail list, cluster map |
| `/regions/[slug]/opengraph-image` | Static, revalidated with page | Generated OG image (phase 3) |
| `/sitemap.xml` | Static, revalidated by tag | From `src/app/sitemap.ts` (phase 3) |
| `/robots.txt` | Static | From `src/app/robots.ts` (phase 3) |
| `/studio/[[...tool]]` | Client | Embedded Sanity Studio |
| `/api/revalidate` | Route handler | Sanity webhook target, POST only |
| `/api/draft-mode/enable` | Route handler | Enables draft mode from Presentation tool |
| `/api/draft-mode/disable` | Route handler | Exits draft mode |

## Environment variables

| Variable | Public | Used by |
| --- | --- | --- |
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | yes | Client, Studio |
| `NEXT_PUBLIC_SANITY_DATASET` | yes | Client, Studio |
| `NEXT_PUBLIC_SANITY_API_VERSION` | yes | Client. Use a fixed date, e.g. the scaffold date |
| `NEXT_PUBLIC_SITE_URL` | yes | Metadata, OG image URLs, Presentation preview origin |
| `SANITY_API_READ_TOKEN` | no | Viewer token for draft mode and live previews |
| `SANITY_API_WRITE_TOKEN` | no | Editor token used only by the trip report server action |
| `SANITY_REVALIDATE_SECRET` | no | Shared secret checked by `/api/revalidate` |

Tokens are created in the Sanity project management UI. The write token must never be
exposed to the client. The read token is read only by server code; `defineLive` passes it
to the browser as `browserToken` only while draft mode is enabled, which is the documented
`next-sanity` pattern for live draft previews.

## Folder layout

```
.
├── docs/spec/                  this spec
├── public/
├── sanity/
│   ├── schemaTypes/            one file per document or object type
│   ├── structure.ts            Structure Builder config
│   ├── actions/                custom document actions (approve/reject)
│   ├── components/             custom Studio inputs and previews
│   ├── presentation/           Presentation tool resolve config (phase 4)
│   └── seed/                   NDJSON seed data and import script
├── sanity.config.ts
├── sanity.cli.ts
├── src/
│   ├── app/                    routes listed above
│   │   ├── (site)/             public pages and their layout
│   │   ├── studio/             embedded Studio, outside the site layout
│   │   └── api/                route handlers
│   ├── components/
│   │   ├── ui/                 shadcn/ui generated components
│   │   ├── sketch/             drawn SVG marks and Tape (08)
│   │   ├── portable-text/      block renderers
│   │   ├── map/                MapLibre wrappers
│   │   └── ...
│   ├── lib/
│   │   ├── sanity/
│   │   │   ├── client.ts       createClient, defineLive exports
│   │   │   ├── write-client.ts server-only client with the write token (phase 5)
│   │   │   ├── queries.ts      every GROQ query, wrapped in defineQuery
│   │   │   ├── image.ts        urlFor helper
│   │   │   └── types.ts        generated by TypeGen, do not edit
│   │   ├── trail-filters.ts    search param schema for /trails (phase 3)
│   │   ├── og-tokens.ts        hex mirror of --dp-color-* for OG images only (phase 3)
│   │   └── utils.ts
│   └── actions/                server actions
├── sanity-typegen.json
└── schema.json                 extracted schema, generated
```

## Phase summary

Each phase has a Goal, Deliverables, Implementation notes, and Acceptance checks.
A phase is done when all acceptance checks pass and the app runs at that point. Each phase
also delivers its row of the Implementation plan in `08-design-system.md` and passes the
08 acceptance checks that apply to what it built.

1. **Foundation** — app runs, Studio runs, schemas exist, seed data is in the dataset.
2. **Core pages** — trails and regions render from real queries with typed results.
3. **Images, SEO, filters** — pages look finished, share cards work, list is filterable.
4. **Editorial workflow** — editors preview drafts in place and publishes update the live site.
5. **Trip reports** — visitors submit, editors approve, approved reports appear.
6. **Live conditions and maps** — closures appear in real time, maps on every trail and region.
