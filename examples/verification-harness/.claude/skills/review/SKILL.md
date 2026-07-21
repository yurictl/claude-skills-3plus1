---
name: review
description: Grade Kubernetes manifest changes under app/k8s/ against docs/operations/k8s-conventions.md and report [BLOCKER]/[WARNING]/[CAVEAT] findings. Use when the user asks to review or grade manifests, before any push or MR touching app/k8s/, or when the pre-push hook reports an ungraded change.
---

# review — the rubric grader

Grade manifest changes against the conventions doc. The doc is the single source of rules — do not invent rules that are not in it, and do not skip rules that are.

## Steps

1. Read `docs/operations/k8s-conventions.md` in full.
2. Collect the material to grade, in this order of preference:
   - changed files: `git diff --name-only HEAD -- app/k8s` plus `git diff --name-only --cached -- app/k8s` plus commits ahead of `origin/main` if it exists;
   - if nothing changed, grade **all** files under `app/k8s/` (full audit).
3. Grade every rule in the doc against every collected file. Findings come in three bands:
   - **violation** → `[SEVERITY] <rule name> — <file>:<line> — <what is wrong> — <the correct form>`
   - **justified exception** (violation carrying an inline `# reason:`) → `[CAVEAT] <rule name> — <file>:<line> — <the stated reason>`. A caveat passed the structural check but rests on a semantic assumption the machine cannot verify — it is surfaced for human sign-off, never silently accepted. A `[BLOCKER]`-level exception additionally requires the justification in the MR/commit description; if that is missing, say so in the caveat line.
   - **pass** → not listed.
4. Summarize: count of blockers / warnings / caveats. If there are caveats, state explicitly that they route to a human for sign-off.
5. **Gate marker:**
   - zero `[BLOCKER]` findings → run `bash scripts/grade-marker.sh stamp` and state that the push gate is open (caveats do not block the gate — they block silent acceptance);
   - any `[BLOCKER]` → do NOT stamp; propose concrete fixes and offer to apply them.

## Hard rule

Never stamp the marker without having actually executed steps 1–4 in this session. The marker holds a fingerprint of `app/k8s/` (see `scripts/grade-marker.sh`), so a stale or hand-touched marker fails the hook deterministically — but the fingerprint cannot prove the grade *happened*. That last step is this rule.
