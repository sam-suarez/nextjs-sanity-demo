# Handoffs

The handoff files are the source of truth for build state across sessions. Chat history
is not. If it is not written here, it did not happen.

```
docs/handoffs/
├── HANDOFF.md            index: current phase, next action, open human steps (≤100 lines)
├── _templates/           one template per handoff type; agents follow them exactly
└── phase-N/
    ├── research.md       researcher  → verified APIs for this phase
    ├── brief.md          architect   → the contract the implementer builds to
    ├── implementation.md implementer → what was built, deviations, open items
    ├── diff.patch        orchestrator → git diff main...phase-N (handoffs excluded)
    ├── review.md         blind-reviewer verdict, saved verbatim (review-r2.md on round 2)
    └── qa.md             qa-runner   → automated check results
```

Who reads what:

| Agent | Reads | Writes |
| --- | --- | --- |
| researcher | spec, package.json | research.md |
| architect | spec, research.md, HANDOFF.md, previous implementation.md | brief.md, spec edits (spec review) |
| implementer | brief.md, research.md, spec, HANDOFF.md | code on branch phase-N, implementation.md |
| blind-reviewer | brief.md, diff.patch, spec, code | nothing (verdict is its final message) |
| qa-runner | brief.md | qa.md |
| scribe | all phase files | HANDOFF.md |

The blind reviewer is blocked by a hook from reading anything else under this directory.
