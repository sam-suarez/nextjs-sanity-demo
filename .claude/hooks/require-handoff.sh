#!/usr/bin/env bash
# SubagentStop gate: an agent may not finish until it has written its handoff file
# and named it on the last line of its final message as `HANDOFF: docs/handoffs/...`.
set -u
input=$(cat)
root="${CLAUDE_PROJECT_DIR:-$PWD}"

block() {
  jq -n --arg r "$1" '{decision:"block", reason:$r}'
  exit 0
}

active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')
[ "$active" = "true" ] && exit 0

msg=$(printf '%s' "$input" | jq -r '.last_assistant_message // ""')
path=$(printf '%s' "$msg" | grep -oE 'HANDOFF: *[^ `]+' | tail -1 | sed -E 's/HANDOFF: *//')

[ -z "$path" ] && block "Your final message must end with a line 'HANDOFF: <path>' naming the handoff file you wrote under docs/handoffs/. Write the file (it needs a '## Status' section), then finish with that line."

case "$path" in
  docs/handoffs/*) ;;
  *) block "Handoff path '$path' must be under docs/handoffs/." ;;
esac

f="$root/$path"
[ -s "$f" ] || block "Handoff file '$path' does not exist or is empty. Write it, then finish with the HANDOFF line."
grep -q '^## Status' "$f" || block "Handoff file '$path' has no '## Status' section. Add one (complete | blocked | needs-human), then finish."
exit 0
