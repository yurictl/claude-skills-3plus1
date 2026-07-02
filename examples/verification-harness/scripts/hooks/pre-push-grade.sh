#!/usr/bin/env bash
# PreToolUse hook: gate `git push` behind a fresh /review grade when app/k8s/ changed.
#
# Contract (Claude Code hooks):
#   stdin  — JSON: {"tool_name": "...", "tool_input": {"command": "..."}, ...}
#   exit 0 — allow the tool call
#   exit 2 — block it; stderr is shown to the agent as the reason
set -uo pipefail

payload=$(cat)
command=$(printf '%s' "$payload" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || true)

# Only gate pushes.
case "$command" in
  *"git push"*) ;;
  *) exit 0 ;;
esac

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# Did anything under app/k8s change (committed ahead of origin/main, staged, unstaged, or untracked)?
changed=$(
  {
    git diff --name-only HEAD -- app/k8s 2>/dev/null
    git diff --name-only --cached -- app/k8s 2>/dev/null
    git log --name-only --pretty=format: origin/main..HEAD -- app/k8s 2>/dev/null
    git ls-files --others --exclude-standard app/k8s 2>/dev/null
  } | sed '/^$/d' | sort -u
)
[ -z "$changed" ] && exit 0

marker=".claude/grade-ok"

if [ ! -f "$marker" ]; then
  {
    echo "PUSH BLOCKED: manifest changes under app/k8s/ are not graded."
    echo "Changed: $(echo "$changed" | tr '\n' ' ')"
    echo "Run /review — it writes $marker only on zero [BLOCKER] findings."
  } >&2
  exit 2
fi

# Marker must be newer than every changed manifest (stale grade = no grade).
stale=$(find app/k8s -type f -newer "$marker" 2>/dev/null | head -1)
if [ -n "$stale" ]; then
  {
    echo "PUSH BLOCKED: $stale changed after the last grade."
    echo "Re-run /review to refresh $marker."
  } >&2
  exit 2
fi

exit 0
