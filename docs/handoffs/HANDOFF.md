# Trailhead build state

Read this first in every session. Keep under 100 lines.

## Current state

Spec review complete and approved by Sam on 2026-11-04 (`docs/handoffs/spec-review/spec-review.md`).
No code exists. Specs live in `docs/spec/`. Nothing is committed yet.

## Next action

Run `/build-phase 1`. The phase 1 researcher must also cover the "Flag for researcher" items in
`docs/handoffs/spec-review/spec-review.md` that touch phase 1 (Next 16 APIs, TypeGen config,
`SanityLive`/`VisualEditing` placement, perspective names, shadcn `form` vs `field`).

## Phase table

| Phase | Status | Branch | Merge commit | Notes |
| --- | --- | --- | --- | --- |
| spec review | complete | main | | architect pass, 3 decisions by Sam; see spec-review/spec-review.md |
| 1 foundation | pending | | | |
| 2 core pages | pending | | | |
| 3 images, SEO, filters | pending | | | |
| 4 editorial workflow | pending | | | |
| 5 trip reports | pending | | | |
| 6 live conditions, maps | pending | | | |

Status values: pending, in-progress, needs-human, approved, merged, blocked (spec review row: complete).

## Open human steps

None yet.

## Standing decisions

- Design system spec (08) overrides earlier phase files where they conflict.
- `src/lib/og-tokens.ts` is the only file besides `globals.css` allowed raw hex (OG images; in CLAUDE.md).
- Each phase merges to `main` before the next begins. Nothing is pushed by agents.
- Orchestrator runs on Opus 5.5 high. Reviewer and architect on Opus 5.5 high. Implementer on Sonnet 5.5 high (Opus for phases 4 and 6). QA and scribe on Haiku 5.5.
