---
name: review
description: Grade Kubernetes manifest changes under app/k8s/ against docs/operations/k8s-conventions.md and report [BLOCKER]/[WARNING] findings. Use when the user asks to review or grade manifests, before any push or MR touching app/k8s/, or when the pre-push hook reports an ungraded change.
---

# review — the rubric grader

Grade manifest changes against the conventions doc. The doc is the single source of rules — do not invent rules that are not in it, and do not skip rules that are.

## Steps

1. Read `docs/operations/k8s-conventions.md` in full.
2. Collect the material to grade, in this order of preference:
   - changed files: `git diff --name-only HEAD -- app/k8s` plus `git diff --name-only --cached -- app/k8s` plus commits ahead of `origin/main` if it exists;
   - if nothing changed, grade **all** files under `app/k8s/` (full audit).
3. Grade every rule in the doc against every collected file. For each violation report one finding:
   `[SEVERITY] <rule name> — <file>:<line> — <what is wrong> — <the correct form>`
   Do not list passing rules. Honor inline `# reason:` comments per the doc's exception mechanism (a justified `[WARNING]` is reported as accepted-exception, not as a finding; a `[BLOCKER]` with inline reason still requires the commit/MR description to carry the justification — say so).
4. Summarize: count of blockers / warnings / accepted exceptions.
5. **Gate marker:**
   - zero `[BLOCKER]` findings → `touch .claude/grade-ok` and state that the push gate is open;
   - any `[BLOCKER]` → do NOT touch the marker; propose concrete fixes and offer to apply them.

## Hard rule

Never write `.claude/grade-ok` without having actually executed steps 1–4 in this session. The marker is the harness's trust anchor.
