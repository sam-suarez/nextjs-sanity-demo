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

## Implementation notes

### Write client

`src/lib/sanity/write-client.ts` creates a client with `SANITY_API_WRITE_TOKEN`,
`useCdn: false`, and the `server-only` import guard so it can never be bundled for the
browser. The token's role is Editor, scoped to the single dataset.

### Form

- `src/app/(site)/trails/[slug]/report/page.tsx` is a server component that fetches the
  trail name for the heading and renders `<TripReportForm trailId trailSlug />`.
- `TripReportForm` is a client component using `useActionState` with the server action.
  Fields: name, date hiked (`<input type="date">` max today), rating (five-star radio
  group), body textarea with a live character count, photos file input
  (`accept="image/*"`, `multiple`), and a visually hidden honeypot field named `website`.
- shadcn `Form` components with field-level errors returned from the action.
- On success the action redirects to the trail page with `?reported=1`; the trail page
  shows a thank-you toast reading that param.

### Server action

`src/actions/submit-trip-report.ts`, marked `"use server"`:

1. Parse `FormData` with a Zod schema matching the `tripReport` validation rules.
   Reject if the honeypot is filled, returning a fake success so bots learn nothing.
2. Rate limit by IP using a tiny in-memory token bucket keyed on
   `headers().get("x-forwarded-for")`. Five submissions per hour. On Vercel this is
   per-instance, which is acceptable here; note the limitation in a comment.
3. Verify the trail ID exists with a one-line GROQ query.
4. Upload each photo with `writeClient.assets.upload("image", file)`. Enforce max three
   files, 5 MB each, and image MIME types. Server action body limit is raised to 16 MB
   in `next.config.ts` under `experimental.serverActions.bodySizeLimit`.
5. Create the document with `writeClient.create({...})` and `status: "pending"`,
   `submittedAt: new Date().toISOString()`.
6. Return `{ ok: true }` or `{ ok: false, errors }`. Never throw user-facing errors.

### Studio moderation

- `sanity/actions/approveTripReport.ts` and `rejectTripReport.ts` are document actions
  shown only for `tripReport`. Each patches `status` and `moderatedAt` via
  `useDocumentOperation().patch` and then publishes. The approve action is disabled when
  the document is already approved.
- Register them in `document.actions` in `sanity.config.ts`, filtering the default
  actions for `tripReport` down to the custom pair plus delete.
- Flip `tripReport.status` to `readOnly: true` now that the actions exist.
- Structure: the Pending list from the content model gets a badge showing the count
  via a `useQuery`-style live count in a custom list item component. If that proves
  fiddly, a static title is acceptable.

### Display

- `tripReportsByTrailQuery`: `*[_type == "tripReport" && trail._ref == $trailId && status == "approved"] | order(hikedOn desc)[0...10]{ _id, authorName, hikedOn, rating, body, photos[]{ ..., asset->{ _id, metadata { lqip } } } }`.
- `TripReports` server component on the trail page renders cards with a star row and a
  photo strip, and a "Write a report" button linking to the form. Tagged
  `tripReport` and `trail:<slug>` so the phase 4 webhook revalidates it on approval.

## Acceptance checks

- Submitting a valid report with two photos creates a pending document with both images
  in the Studio within seconds.
- Submitting with the honeypot filled returns success but creates nothing.
- A sixth submission from the same IP within an hour is rejected with a clear message.
- Invalid input (future date, empty body, 4 MB×4 photos) shows field errors without
  losing the other field values.
- Approving in the Studio makes the report appear on the trail page after the webhook
  fires; rejecting leaves it hidden.
- The write token does not appear in any client bundle (`grep` the `.next/static` output).
