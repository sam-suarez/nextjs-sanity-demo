---
name: build-phase
description: Orchestrates one Trailhead phase end to end - research, brief, implementation on branch phase-N, blind review plus QA in parallel, fix loop, handoff index update, merge to main. Usage - /build-phase 3
argument-hint: "<phase number 1-6>"
disable-model-invocation: true
---

You are the orchestrator for phase `$ARGUMENTS` (call it N). You dispatch agents, move files between them, and gate on results. You do not write code and you do not write handoffs on an agent's behalf, except `diff.patch` and `review*.md` which are mechanical.

## Context hygiene (read first)

- Agents are given **paths**, never pasted file contents, unless this skill says otherwise.
- The blind reviewer is given only: spec paths, `brief.md`, `diff.patch`. Never mention `implementation.md`, `research.md`, `qa.md`, or anything the implementer said. Never summarise the implementation to it.
- `diff.patch` is generated with `docs/handoffs` excluded so handoffs cannot leak through the diff.
- Every reviewer round uses a **new** `blind-reviewer` agent. The implementer is **resumed** across fix rounds with SendMessage so it keeps its context.

## 0. Preconditions

1. Read `docs/handoffs/HANDOFF.md`. Require: phase N-1 status is `merged` (for N=1, the spec review row must be `complete`). Otherwise stop and tell the user what is missing.
2. `git status --porcelain` must be empty and the branch must be `main`. Otherwise stop and tell the user.
3. `mkdir -p docs/handoffs/phase-N`. If `brief.md` already exists, ask the user whether to reuse it or regenerate; reuse skips steps 1 and 2.

## 1. Research

Dispatch `researcher`:

> Phase N. Read docs/spec/<phase file for N> and docs/spec/00-overview.md. Verify every library API, CLI command, and config option this phase depends on. If package.json exists, use installed versions. Write docs/handoffs/phase-N/research.md.

## 2. Brief

When research returns, dispatch `architect`:

> Phase brief mode for phase N. Read docs/handoffs/phase-N/research.md, docs/handoffs/HANDOFF.md, docs/handoffs/phase-(N-1)/implementation.md if it exists, and the spec. Write docs/handoffs/phase-N/brief.md following the template. Automated checks must be exact commands with expected results.

Read the brief. If "Human steps before build" is non-empty, present those steps to the user and stop. Resume at step 3 when the user says they are done.

## 3. Implement

Dispatch `implementer`. For phases **4 and 6** pass the Agent tool's `model: opus` override (these phases involve stega cleaning, Presentation document locations, and the Live Content API, which are subtle). All other phases use the agent's default Sonnet.

> Build phase N. Create branch phase-N from main. Read docs/handoffs/phase-N/brief.md, docs/handoffs/phase-N/research.md, the spec files the brief cites, and docs/handoffs/HANDOFF.md. Implement the brief in its stated order, run pnpm typegen and pnpm build, commit as you go, and write docs/handoffs/phase-N/implementation.md.

If it returns with status `needs-human`, relay the exact steps to the user and stop; resume the same agent with SendMessage when the user is done.

## 4. Patch

```
git fetch -q 2>/dev/null; git diff main...phase-N -- . ':!docs/handoffs' ':!pnpm-lock.yaml' > docs/handoffs/phase-N/diff.patch
```

If the patch is empty, the implementer did not commit. Resume it and ask it to commit.

## 5. Review and QA, in parallel

Dispatch both in the same message.

`blind-reviewer`:

> Review phase N. Brief: docs/handoffs/phase-N/brief.md. Diff: docs/handoffs/phase-N/diff.patch. Spec: docs/spec/00-overview.md, docs/spec/01-content-model.md, docs/spec/08-design-system.md, and docs/spec/<phase file>. Return your verdict in the required format.

`qa-runner`:

> Phase N. Run every command in the Automated checks table of docs/handoffs/phase-N/brief.md on branch phase-N and write docs/handoffs/phase-N/qa.md.

Save the reviewer's final message verbatim to `docs/handoffs/phase-N/review.md` (round 2: `review-r2.md`) using a quoted heredoc.

## 6. Gate

APPROVED means the review verdict is `APPROVE` and every automated check in `qa.md` is PASS.

If not approved and this is fix round 1 or 2: resume the implementer with SendMessage:

> Fix round K for phase N. Read docs/handoffs/phase-N/review.md (or review-r2.md) and docs/handoffs/phase-N/qa.md. Fix every Blocking finding and every FAIL. Commit. Append a "## Fix round K" section to implementation.md.

Then repeat steps 4 and 5 with a **new** reviewer. After round 2 without approval, stop and give the user the open findings.

## 7. Index and merge

1. Dispatch `scribe`: "Phase N is approved on branch phase-N. Update HANDOFF.md: phase N status `approved`, list outstanding human steps from implementation.md and manual checks from qa.md."
2. `git checkout main && git merge --no-ff phase-N -m "feat: phase N - <brief title>"`. Do not push.
3. Dispatch `scribe` again: "Phase N merged at <commit>. Set status `merged`, next action `/build-phase N+1`."
4. Report to the user: what was built, the review verdict, QA results, the manual checks they should run, and any human steps outstanding.
