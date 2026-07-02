# Verification Harness Example — Orientation

Demo project: Kubernetes manifests under `app/k8s/` guarded by a docs-driven verification harness. You are working inside a worked example of "docs as graders" — treat the conventions doc as executable, not decorative.

## Map

| What | Where |
|---|---|
| The product | `app/k8s/` — Kubernetes manifests |
| The rubric | `docs/operations/k8s-conventions.md` — severity-tagged authoring rules |
| Why graders | `docs/decisions/ADR-001-docs-as-graders.md` |
| Open loops | `docs/wip/` |
| The grader | `/review` skill (`.claude/skills/review/`) |
| The write-back | `/checkpoint` skill (`.claude/skills/checkpoint/`) |
| The gate | `scripts/hooks/pre-push-grade.sh` via PreToolUse hook |
| Calibration | `tests/golden/` + `scripts/replay.sh` (`make replay`) |

## Severity model

Findings are classified at exactly two levels:

- `[BLOCKER]` — must not merge in this state; fix before proceeding.
- `[WARNING]` — should be corrected; does not block if a justification is documented.

State the severity, the rule, the file/line, and the correct form. Do not list passing rules.

Intentional exceptions are marked inline with `# reason: <short justification>` at the point of violation; a `[BLOCKER]` exception additionally requires the justification in the MR/commit description.

## Verifiable success criteria

Before a non-trivial change, name the check that will tell you it's done. For manifest changes the check is always the same: `/review` reports zero `[BLOCKER]` findings. A goal without a check is a guess.

## Gate behavior

`git push` is gated by a PreToolUse hook: if `app/k8s/` changed and the grade marker (`.claude/grade-ok`) is missing or stale, the push is blocked with instructions. Run `/review`; it writes the marker only on a clean grade. Do not touch the marker by hand — that defeats the harness this example exists to demonstrate.

## Write-back rule

At session end (or when the user says "checkpoint"), run `/checkpoint`: if this session hit a failure the rubric would not have caught, propose a new rule for `docs/operations/k8s-conventions.md` or a WIP entry in `docs/wip/`. Failures are curation signals, not noise.
