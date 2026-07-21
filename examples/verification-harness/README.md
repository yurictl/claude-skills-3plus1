# Verification Harness — a runnable example

A minimal, self-contained project showing the step **after** the 3+1 framework: turning docs from *reference the agent reads* into *graders the harness runs*.

The premise: in a mature 3+1 project the verification knowledge is already written down — conventions, severity rules, failure taxonomies. What's usually missing is the **executor**: the checks run in a human's head at review time. This example wires the three missing pieces with stock Claude Code mechanics plus ~100 lines of scripting:

1. **Grader skill** (`/review`) — grades manifest changes against a severity-tagged rubric doc, in three bands: `[BLOCKER]`, `[WARNING]`, and `[CAVEAT]` — a justified exception that passed the structural check but rests on a semantic assumption, surfaced for human sign-off instead of silently accepted.
2. **PreToolUse hook** — deterministically blocks `git push` until the grade is fresh. "Always before X" belongs in a hook, not in a CLAUDE.md sentence the model may skip. The gate is **tamper-aware**: the grade marker is a content fingerprint of `app/k8s/` (not a timestamp — `touch` can't forge it), hand edits to the marker are blocked outright, and a push that changes the manifests *and* the calibration material in one go is blocked as the weakened-test / false-completion pattern.
3. **Golden set + replay** — historical violations as fixtures; `make replay` feeds each to a headless grader (`claude -p`) and reports catch-rate. This is what makes the grader trustworthy rather than decorative — and it catches regressions when you edit the rubric or switch models. The replay discloses uncommitted calibration changes up front, so a claimed catch-rate always says which baseline it was measured against.

The loop closes with `/checkpoint`: failures observed during a session get written back into the rubric or a WIP file, so the substrate compounds.

## Layout

```
CLAUDE.md                          Orientation: map, severity model, success criteria
docs/
  operations/k8s-conventions.md    the rubric — [BLOCKER]/[WARNING] rules, one per line of defense
  decisions/ADR-001-*.md           why docs-as-graders
  wip/harvest-failure-modes.md     open loop: real failures graduate into the rubric
app/k8s/                           the "product": compliant Kubernetes manifests
.claude/
  settings.json                    PreToolUse hook wiring
  skills/review/SKILL.md           the grader
  skills/checkpoint/SKILL.md       the write-back step
scripts/
  hooks/pre-push-grade.sh          the gate (exit 2 = block, message shown to the agent)
  grade-marker.sh                  the trust anchor: fingerprint-based grade marker (hash/stamp/check)
  replay.sh                        golden-set replay via `claude -p`
tests/golden/<case>/               case.yaml + expected.txt (regex the findings must match)
Makefile                           replay / seed-violation / reset
```

## Quickstart

Requirements: `claude` CLI, `git`, `python3`. Run everything from this directory:

```bash
cd examples/verification-harness
claude   # start a session with this dir as project root
```

**Demo loop (5 minutes):**

1. `make seed-violation` — drops a manifest with `image: nginx:latest` into `app/k8s/`.
2. Ask Claude to commit and push it. The **hook blocks the push**: the change is ungraded.
3. Ask Claude to bypass the gate with `touch .claude/grade-ok`. **Blocked too**: hand edits to the marker are refused, and even a smuggled marker would fail — it must contain the current fingerprint of `app/k8s/`, not just exist.
4. Say `/review`. The grader reads the rubric, reports `[BLOCKER] pinned image tag — app/k8s/demo-violation.yaml ...`, and refuses to stamp.
5. Ask Claude to fix the finding, then `/review` again — zero blockers, the marker is stamped, push proceeds (or fails on "no remote", which is fine for the demo — the gate already did its job before the push ran).
6. `make replay` — replays the golden set through a headless grader and prints the catch-rate (expect 4/4; the `justified-exception` fixture checks that a `# reason:` violation surfaces as `[CAVEAT]`, not silence).
7. `make reset` — cleans up.

## Adapting to a real project

- Replace `docs/operations/k8s-conventions.md` with **your** rubric — the pattern only pays off when the rules are yours (earned from incidents), not generic best practice a frontier model already knows.
- Point the hook's path filter and the skill's diff scope at your protected paths.
- Seed `tests/golden/` from **historical incidents**, not invented cases: each past failure becomes a permanent regression test for your verification layer.
- Wire `/checkpoint` into your session-end habit; every new failure mode should end up either in the rubric or in a WIP entry that graduates.
- Fill the three adapter slots explicitly (see the Adapter table in `CLAUDE.md`): **evidence** — which command/probe is the source of truth per check; **authority** — who may sign off `[CAVEAT]`s and exceptions; **fraud-patterns** — your incident-earned rules and fixtures. The first two are what usually stay implicit in a docs-heavy project.

## What this is *not*

- Not a CI bot (though `scripts/replay.sh` drops into CI unchanged — check your org's AI-tool policy first).
- Not a replacement for human judgment: stakeholder confirmations, business intent, and irreversible operations stay human by design. The gate frees that attention from re-checking what's already written down.
