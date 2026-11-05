#!/usr/bin/env bash
# PreToolUse guard: restrict Edit/Write/NotebookEdit to one directory prefix.
# Usage in agent frontmatter: write-scope.sh docs   or   write-scope.sh docs/handoffs
set -u
allowed="${1:-docs}"
input=$(cat)
root="${CLAUDE_PROJECT_DIR:-$PWD}"
p=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // ""')
rel="${p#"$root"/}"
case "$rel" in
  "$allowed"/*) exit 0 ;;
esac
jq -n --arg r "This agent may only write under $allowed/. Refused: $rel" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}'
exit 0
