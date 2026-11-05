#!/usr/bin/env bash
# PreToolUse guard for the blind reviewer. It may read the spec, the codebase, the
# phase brief and the diff patch. It may never read other agents' handoffs, the
# handoff index, or any agent memory, and must always scope Grep/Glob to a path.
set -u
input=$(cat)
root="${CLAUDE_PROJECT_DIR:-$PWD}"

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}'
  exit 0
}

tool=$(printf '%s' "$input" | jq -r '.tool_name // ""')
p=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""')
rel="${p#"$root"/}"

case "$rel" in
  *agent-memory*) deny "Blind reviewer: agent memory is off limits." ;;
esac

case "$tool" in
  Read)
    case "$rel" in
      docs/handoffs/phase-*/brief.md|docs/handoffs/phase-*/diff.patch) ;;
      docs/handoffs/*|*/docs/handoffs/*) deny "Blind reviewer: only brief.md and diff.patch under docs/handoffs/ may be read. Judge from the spec and the diff." ;;
    esac
    ;;
  Grep|Glob)
    [ -z "$rel" ] && deny "Blind reviewer: scope $tool to a path (src/, sanity/, docs/spec/, or a file) so handoff files are never searched."
    case "$rel" in
      docs/handoffs*|*/docs/handoffs*|docs|docs/|.) deny "Blind reviewer: $tool may not cover docs/handoffs/. Use src/, sanity/, or docs/spec/." ;;
    esac
    ;;
esac
exit 0
