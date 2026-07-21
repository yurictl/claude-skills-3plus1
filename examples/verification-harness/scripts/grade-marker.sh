#!/usr/bin/env bash
# Grade marker management. The marker (.claude/grade-ok) is not a timestamp —
# it holds a fingerprint of app/k8s/ at grade time. A marker whose fingerprint
# no longer matches the working tree is no grade at all: `touch` can't forge it,
# and any edit (or revert) after grading invalidates it automatically.
#
#   hash   — print the current fingerprint of app/k8s/
#   stamp  — write the fingerprint to .claude/grade-ok
#            (only /review calls this, after a grade with zero blockers)
#   check  — exit 0 if the marker matches the current state;
#            exit 1 if missing, exit 2 if stale (fingerprint mismatch)
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}" || exit 1
MARKER=".claude/grade-ok"

fingerprint() {
  python3 - <<'EOF'
import hashlib, os
h = hashlib.sha256()
for dirpath, dirs, files in os.walk("app/k8s"):
    dirs.sort()
    for f in sorted(files):
        p = os.path.join(dirpath, f)
        h.update(p.encode())
        with open(p, "rb") as fh:
            h.update(fh.read())
print(h.hexdigest())
EOF
}

case "${1:-}" in
  hash)
    fingerprint
    ;;
  stamp)
    mkdir -p .claude
    fingerprint > "$MARKER"
    echo "stamped $MARKER ($(cat "$MARKER" | cut -c1-12)…)"
    ;;
  check)
    [ -f "$MARKER" ] || exit 1
    [ "$(fingerprint)" = "$(cat "$MARKER")" ] || exit 2
    ;;
  *)
    echo "usage: grade-marker.sh hash|stamp|check" >&2
    exit 64
    ;;
esac
