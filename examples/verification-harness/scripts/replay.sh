#!/usr/bin/env bash
# Golden-set replay: feed each fixture to a headless grader (claude -p) and
# check the expected finding is still caught. Exit non-zero on any miss.
#
# This is the calibration layer: run it after editing the rubric and after
# model upgrades. A grader without a golden set is decorative.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

RUBRIC="docs/operations/k8s-conventions.md"
[ -f "$RUBRIC" ] || { echo "missing $RUBRIC" >&2; exit 1; }

pass=0
miss=0

for dir in tests/golden/*/; do
  name=$(basename "$dir")
  [ -f "$dir/case.yaml" ] && [ -f "$dir/expected.txt" ] || { echo "SKIP  $name (incomplete fixture)"; continue; }

  prompt="You are a Kubernetes manifest reviewer. Grade the manifest below against the following conventions. Report findings only, one per line, in the format: [SEVERITY] rule — detail. Do not list passing rules.

=== CONVENTIONS ===
$(cat "$RUBRIC")

=== MANIFEST (${name}/case.yaml) ===
$(cat "$dir/case.yaml")"

  out=$(claude -p "$prompt" 2>/dev/null)

  if printf '%s' "$out" | grep -qE "$(cat "$dir/expected.txt")"; then
    echo "PASS  $name"
    pass=$((pass + 1))
  else
    echo "MISS  $name — expected /$(cat "$dir/expected.txt")/, got:"
    printf '%s\n' "$out" | sed 's/^/      /'
    miss=$((miss + 1))
  fi
done

total=$((pass + miss))
echo
echo "catch-rate: ${pass}/${total}"
[ "$miss" -eq 0 ]
