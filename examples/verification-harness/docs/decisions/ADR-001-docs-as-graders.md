---
title: "ADR-001: Conventions docs are executed by the harness, not read by humans at review time"
summary: "Turn severity-tagged convention docs into machine-run graders (skill + hook + golden set) instead of relying on reviewers to apply them from memory."
status: accepted
updated: "02-07-2026"
---

# ADR-001: Conventions docs are executed by the harness, not read by humans at review time

## Context

Projects that document well end up in a specific failure mode: the verification knowledge is written down (conventions, severity rules, failure taxonomies), but the checks are executed by a human head at review time. The substrate exists; the executor is a person. Symptoms: a large share of human message traffic is "look at this / check that / can I merge?", agents read the docs as context but never grade their own output against them, and the same violations keep reaching review.

## Decision

Every convention doc that contains `[BLOCKER]`/`[WARNING]` rules is treated as **executable**:

1. A **grader skill** (`/review`) grades changes against the doc and reports findings in the severity format. Zero blockers → it writes a grade marker.
2. A **PreToolUse hook** gates `git push` on a fresh marker when protected paths changed. Enforcement lives in the hook, not in prose — an instruction can be skipped, a hook cannot.
3. A **golden set** (`tests/golden/`) pins the grader's catch-rate: each historical violation is a replayable fixture. The replay runs on rubric edits and model upgrades.
4. A **write-back step** (`/checkpoint`) turns session failures into new rules or WIP entries, so the rubric compounds instead of rotting.

## Consequences

- Human review attention shifts to the semantic residue: business intent, stakeholder confirmation, irreversible operations.
- The rubric doc becomes load-bearing: editing it changes gate behavior, so edits get reviewed like code. The golden set is the regression suite for such edits.
- The grade marker is a soft artifact (a file); the harness trusts the skill to write it honestly. If that ever proves insufficient, the escalation path is running the replay script itself as the gate.
- LLM-as-judge is used without any judge infrastructure: a headless `claude -p` call with the rubric inline is the whole judge.
