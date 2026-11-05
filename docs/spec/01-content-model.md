# Content Model

All types live in `sanity/schemaTypes/` as one file per type and are registered in
`sanity/schemaTypes/index.ts`. Use `defineType`, `defineField`, and `defineArrayMember`
throughout so TypeGen and the Studio get full type information.

## Document types

### `trail`

The core content type. One document per hike.

| Field | Type | Rules | Notes |
| --- | --- | --- | --- |
| `name` | string | required | |
| `slug` | slug | required, source `name`, unique | |
| `region` | reference → `region` | required | |
| `difficulty` | string | required, options: `easy`, `moderate`, `hard`, `scramble` | Rendered with the custom `DifficultyInput` (phase 1) |
| `distanceKm` | number | required, positive, one decimal | Round trip or loop distance |
| `elevationGainM` | number | required, non-negative integer | |
| `routeType` | string | required, options: `out-and-back`, `loop`, `point-to-point` | |
| `estimatedHours` | number | optional, positive | |
| `trailhead` | geopoint | required | Lat/lng of the parking area |
| `heroImage` | image with hotspot | required, with `alt` and `attribution` fields | See `imageWithMeta` object |
| `summary` | text | required, max 240 chars | Used on cards and as meta description |
| `body` | array of `block`, `callout`, `gallery` | required | See Portable Text section |
| `highlights` | array of string | optional, max 5 | Short bullet points, e.g. "Larches in late September" |
| `season` | object `{ from: string, to: string }` | optional | Month names, e.g. June to October |
| `dogsAllowed` | boolean | default true | On-leash is the rule in Kananaskis parks |
| `featured` | boolean | default false | Shown on the home page |
| `related` | array of reference → `trail` | optional, max 3, no self-reference | |

Preview: title `name`, subtitle `difficulty · distanceKm km`, media `heroImage`.

Orderings: by name, by distance, by elevation gain.

### `region`

A sub-area of Kananaskis Country. Trails reference a region; regions do not list trails.

| Field | Type | Rules | Notes |
| --- | --- | --- | --- |
| `name` | string | required | |
| `slug` | slug | required, unique | |
| `description` | text | required | Two or three sentences |
| `heroImage` | `imageWithMeta` | required | |
| `center` | geopoint | required | Initial map center for the region page |
| `accessNotes` | array of `block` | optional | Permits, road closures, the Kananaskis Conservation Pass |

Preview: title `name`, media `heroImage`.

### `trailCondition`

A status report about a trail. A new document is created for each update so there is a
history. The site shows only the most recent one per trail. Updated through the Studio.
Phase 6 delivers these updates to open pages in real time.

| Field | Type | Rules | Notes |
| --- | --- | --- | --- |
| `trail` | reference → `trail` | required | |
| `status` | string | required, options: `open`, `caution`, `closed` | |
| `headline` | string | required, max 80 chars | "Closed above the lake due to bear activity" |
| `details` | text | optional | |
| `reportedAt` | datetime | required, default now | Used for ordering |

Preview: title `headline`, subtitle `status`, media from referenced trail's hero image.

### `tripReport`

Visitor-submitted content created by the phase 5 server action. Editors never create
these by hand, but can edit them.

| Field | Type | Rules | Notes |
| --- | --- | --- | --- |
| `trail` | reference → `trail` | required | |
| `authorName` | string | required, max 60 | |
| `hikedOn` | date | required, not in the future | |
| `rating` | number | required, integer 1–5 | |
| `body` | text | required, 20–1000 chars | Plain text, not Portable Text |
| `photos` | array of image | optional, max 3 | Uploaded by the server action |
| `status` | string | required, options: `pending`, `approved`, `rejected`, default `pending` | Read-only in the Studio; changed via document actions |
| `submittedAt` | datetime | required, set by the server | |
| `moderatedAt` | datetime | optional | Set by the approve/reject action |

Preview: title `authorName`, subtitle `status · trail name`, media first photo.

### `siteSettings`

Singleton. Exactly one document with `_id: "siteSettings"`.

| Field | Type | Notes |
| --- | --- | --- |
| `title` | string | Site name, used in metadata |
| `tagline` | string | Hero subtitle |
| `heroImage` | `imageWithMeta` | Home page hero |
| `intro` | array of `block` | Short paragraph under the hero |
| `featuredTrails` | array of reference → `trail`, max 4 | Overrides the `featured` flag if set |
| `footerNote` | text | Disclaimer about checking Alberta Parks before heading out |

## Object types

### `imageWithMeta`

An image with hotspot enabled plus two fields. Used wherever an image appears.

| Field | Type | Rules |
| --- | --- | --- |
| `alt` | string | required |
| `attribution` | string | optional, e.g. "Photo: Jane Doe, CC BY-SA 4.0, Wikimedia Commons" |
| `attributionUrl` | url | optional |

### `callout`

Portable Text block for warnings and tips.

| Field | Type | Rules |
| --- | --- | --- |
| `tone` | string | required, options: `info`, `warning`, `danger` |
| `title` | string | optional |
| `text` | text | required |

Preview: title `title` or first 40 chars of `text`, subtitle `tone`.

### `gallery`

Portable Text block for a row of photos.

| Field | Type | Rules |
| --- | --- | --- |
| `images` | array of `imageWithMeta` | required, 2–6 items |
| `caption` | string | optional |

## Portable Text configuration

The `body` field on `trail` and `accessNotes` on `region` use this configuration:

- Styles: normal, h2, h3, blockquote.
- Lists: bullet, number.
- Decorators: strong, em.
- Annotations:
  - `link` — `href` (url, required), `openInNewTab` (boolean).
  - `trailLink` — `trail` (reference → `trail`, required). Rendered as an internal link
    with a small difficulty badge.
- Block members: `callout`, `gallery`.

`siteSettings.intro` uses a reduced configuration: normal style, strong, em, and `link` only.

## Reference graph

```
siteSettings ──featuredTrails──▶ trail ◀──trail── trailCondition
                                   │  ▲
                                   │  └──trail── tripReport
                                   ├──region──▶ region
                                   └──related──▶ trail
```

Regions are never deleted while trails reference them. The Studio's default reference
validation prevents this already.

## Studio structure

Defined in `sanity/structure.ts` using Structure Builder:

```
Trailhead
├── Site settings            (singleton, opens the one document directly)
├── Trails
│   ├── All trails
│   ├── By region            (one list per region document)
│   └── Featured
├── Regions
├── Trail conditions         (ordered by reportedAt desc)
├── Trip reports
│   ├── Pending              (status == "pending", badge count)
│   ├── Approved
│   └── Rejected
└── (divider, then the remaining types if any are added later)
```

`siteSettings` is removed from the "new document" menu and from the default type list.

## Seed content

Twelve trails across five regions. Stats below are approximate and must be checked
against Alberta Parks or a current guidebook before seeding. Coordinates are the trailhead
parking area, not the summit. Photos come from Wikimedia Commons; record the author,
licence, and source URL in `attribution` and `attributionUrl`.

| Trail | Region | Difficulty | Dist km | Gain m | Route | Approx. trailhead |
| --- | --- | --- | --- | --- | --- | --- |
| Grassi Lakes | Canmore & Spray Valley | easy | 4.0 | 200 | loop | 51.08, -115.40 |
| Ha Ling Peak | Canmore & Spray Valley | hard | 7.4 | 800 | out-and-back | 50.93, -115.40 |
| Tent Ridge Horseshoe | Canmore & Spray Valley | scramble | 10.5 | 700 | loop | 50.85, -115.35 |
| Chester Lake | Canmore & Spray Valley | moderate | 9.6 | 310 | out-and-back | 50.80, -115.27 |
| Burstall Pass | Canmore & Spray Valley | moderate | 15.0 | 470 | out-and-back | 50.78, -115.34 |
| Troll Falls | Kananaskis Valley | easy | 3.4 | 60 | out-and-back | 50.95, -115.15 |
| Rawson Lake | Peter Lougheed | moderate | 7.8 | 300 | out-and-back | 50.62, -115.14 |
| Upper Kananaskis Lake Circuit | Peter Lougheed | moderate | 16.0 | 150 | loop | 50.62, -115.14 |
| Ptarmigan Cirque | Peter Lougheed | moderate | 4.5 | 230 | loop | 50.60, -114.98 |
| Elbow Lake | Peter Lougheed | easy | 2.6 | 130 | out-and-back | 50.63, -115.02 |
| Prairie Mountain | Elbow Valley | hard | 7.0 | 700 | out-and-back | 50.90, -114.90 |
| Heart Mountain | Bow Valley | scramble | 10.0 | 900 | loop | 51.05, -115.14 |

Regions:

| Region | Center | Access note |
| --- | --- | --- |
| Canmore & Spray Valley | 50.90, -115.35 | Spray Lakes Road (Smith-Dorrien) is gravel; Kananaskis Conservation Pass required |
| Kananaskis Valley | 50.95, -115.15 | Highway 40, Kananaskis Village area |
| Peter Lougheed | 50.65, -115.10 | Highway 40 south of Kananaskis Lakes Trail; Highwood Pass closed Dec 1 to Jun 14 |
| Elbow Valley | 50.90, -114.90 | Highway 66; winter gate closes beyond Elbow Falls Dec 1 to May 14 |
| Bow Valley | 51.05, -115.10 | Trans-Canada Highway corridor near Exshaw and Lac des Arcs |

Seed also includes: one `trailCondition` per trail (most `open`, one `caution`, one `closed`),
three approved and two pending `tripReport` documents, and the `siteSettings` singleton.
