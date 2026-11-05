# Phase 5 — Trip Reports

## Goal

Visitors submit a trip report with up to three photos from the trail page. The report is
held as pending, an editor approves or rejects it with one click in the Studio, and
approved reports appear on the trail page.

## Deliverables

- `/trails/[slug]/report` page with the submission form.
- `submitTripReport` server action with validation, spam checks, photo upload, and a
  Sanity mutation.
- Approve and reject document actions in the Studio, plus a pending-count badge.
- `TripReports` section on the trail page showing approved reports.
- Rate limiting for the action.
- The phase 5 row of the Implementation plan in `08-design-system.md`. Install the extra
  shadcn components it needs with `pnpm dlx shadcn@latest add sonner form`, then theme and
  edit them per 08 like the phase 1 set.

## Implementation notes

### Write client

`src/lib/sanity/write-client.ts` creates a client with `SANITY_API_WRITE_TOKEN`,
`useCdn: false`, and the `server-only` import guard (`pnpm add server-only`) so it can
never be bundled for the browser. The token's role is Editor, scoped to the single dataset.
Creating it in the Sanity project settings and adding it to `.env.local` and Vercel is a
human step.

### Form

- `src/app/(site)/trails/[slug]/report/page.tsx` is a server component that fetches
  `trailForReportQuery` (`*[_type == "trail" && slug.current == $slug][0]{ _id, name, "slug": slug.current }`,
  tags `trail` and `trail:<slug>`), calls `notFound()` when it returns null, and renders
  `<TripReportForm trailId trailSlug />` with both values through `stegaClean`. It exports
  `generateStaticParams` from `trailSlugsQuery` so the shell is static.
- `TripReportForm` is a client component using `useActionState` with the server action.
  Fields: name, date hiked (`<input type="date">` max today), rating (five-star radio
  group), body textarea with a live character count, photos file input
  (`accept="image/*"`, `multiple`), and a visually hidden honeypot field named `website`.
- shadcn `Form` components with field-level errors returned from the action.
- The action returns the submitted text values with its errors, and the form renders them
  as `defaultValue` so a failed submission keeps what was typed. Browsers cannot restore a
  file input, so photos must be reselected after a failed submission; to make that rare,
  the form checks photo count, size, and type on change in the browser and shows the same
  errors before submitting.
- On success the action redirects to the trail page with `?reported=1`. The trail page stays
  static: a small client component reads the param with `useSearchParams()` inside
  `<Suspense>` and fires the thank-you toast. `<Toaster />` is rendered once in the site layout.

### Server action

`src/actions/submit-trip-report.ts`, marked `"use server"`:

1. If the honeypot is filled, take the success path (the same redirect as step 6) without
   writing anything, so bots learn nothing. Otherwise parse `FormData` with a Zod schema
   matching the `tripReport` validation rules.
2. Rate limit by IP using a tiny in-memory token bucket keyed on the first address in
   `(await headers()).get("x-forwarded-for")` (falling back to `"unknown"`). Five
   submissions per hour; only submissions that pass validation count. On Vercel this is
   per-instance, which is acceptable here; note the limitation in a comment.
3. Verify the trail ID exists with a one-line GROQ query.
4. Upload each photo with `writeClient.assets.upload("image", file)`. Enforce max three
   files, 5 MB each, and image MIME types. Server action body limit is raised to 16 MB
   in `next.config.ts` under `experimental.serverActions.bodySizeLimit`.
5. Create the document with `writeClient.create({...})` and `status: "pending"`,
   `submittedAt: new Date().toISOString()`.
6. On success call `redirect(`/trails/${slug}?reported=1`)`. On failure return
   `{ ok: false, errors, values }`, where `errors` is keyed by field name plus an optional
   form-level message (used for the rate limit). Never throw user-facing errors.

### Studio moderation

- `sanity/actions/approveTripReport.ts` and `rejectTripReport.ts` are document actions
  shown only for `tripReport`. Each patches `status` and `moderatedAt` via
  `useDocumentOperation().patch` and then publishes. The approve action is disabled when
  the document is already approved, and the reject action when it is already rejected.
- Register them in `document.actions` in `sanity.config.ts`, filtering the default
  actions for `tripReport` down to the custom pair plus delete.
- Flip `tripReport.status` to `readOnly: true` now that the actions exist.
- Structure: the Pending list from the content model gets a badge showing the count
  via a `useQuery`-style live count in a custom list item component. If that proves
  fiddly, a static title is acceptable.

### Display

- `tripReportsByTrailQuery`: `*[_type == "tripReport" && trail._ref == $trailId && status == "approved"] | order(hikedOn desc)[0...10]{ _id, authorName, hikedOn, rating, body, photos[]{ ..., asset->{ _id, metadata { lqip } } } }`.
- `TripReports` server component on the trail page renders cards with a star row and a
  photo strip, and a "Write a report" button linking to the form, as specified under Trip
  reports in `08-design-system.md`. Tagged `tripReport` and `trail:<slug>` so the phase 4
  webhook revalidates it on approval.
- "Hiked on {date}" formats `hikedOn` with `Intl.DateTimeFormat("en-CA", { dateStyle: "long", timeZone: "UTC" })`
  (a date-only value, so UTC avoids an off-by-one day).
- Photos have no `alt` field; pass `alt="Photo {n} of {count} from {authorName}'s trip report"`
  to `SanityImage`.
- Each photo is wrapped in a plain `<a>` to the full-size Sanity CDN image, built with
  `urlFor(photo).width(1600).auto("format").url()`, opening in the same tab. No lightbox,
  no `target` attribute. The `href` is built by `urlFor` from the asset reference; any
  query string that feeds it passes through `stegaClean` first.

## Acceptance checks

- Submitting a valid report with two photos on `/trails/grassi-lakes/report` lands on
  `/trails/grassi-lakes?reported=1` with the thank-you toast, and within 10 seconds the
  Studio's Pending list shows a new document with both images.
- With the DevTools console, set `document.querySelector('[name=website]').value = "x"` and
  submit a valid report: the browser lands on the thank-you toast, and
  `pnpm sanity documents query 'count(*[_type == "tripReport"])'` is unchanged.
- Against a freshly restarted local `pnpm start` (empty in-memory bucket), six valid
  submissions from the same browser within an hour: the first five create pending
  documents; the sixth shows a form-level error and creates nothing.
- The Studio's Pending list title shows the current pending count, or `implementation.md`
  records that the static-title fallback was used and why.
- A future date and an empty body each show a field error next to their field, and the
  name, date, rating, and body keep their typed values. Selecting four photos, or one
  photo over 5 MB, shows a photo error before submitting.
- On the deployed site, approving a pending report in the Studio makes it appear on its
  trail page within 10 seconds on reload; rejecting another leaves it hidden.
- On a trail with an approved report that has photos, each photo is focusable with Tab
  (dashed outline), and pressing Enter opens the full-size `cdn.sanity.io` image in the same
  tab. In DevTools, no `<a>` wrapping a trip report photo has a `target` attribute, and each
  `href` contains `w=1600`.
- In the Studio, a `tripReport`'s `status` field is read-only and only Approve, Reject, and
  Delete appear in its action menu.
- `pnpm build && grep -rlF "$SANITY_API_WRITE_TOKEN" .next/static | wc -l` (with
  `.env.local` loaded into the shell) prints `0`.
- The hex and small-text greps in the `08-design-system.md` acceptance checks pass.
