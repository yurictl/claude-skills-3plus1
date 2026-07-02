---
title: "Kubernetes Manifest Conventions"
summary: "Severity-tagged authoring rules for everything under app/k8s/ — the rubric the /review grader executes and the golden set calibrates."
status: active
updated: "02-07-2026"
---

# Kubernetes Manifest Conventions

Prescriptive rules for authoring manifests under `app/k8s/`. Apply this checklist before merging any change to those paths. This document is **executable**: the `/review` skill grades diffs against it, the pre-push hook enforces a fresh grade, and `tests/golden/` pins its catch-rate.

Severity: `[BLOCKER]` must be fixed before merge; `[WARNING]` should be fixed unless justified with an inline `# reason:` comment.

## Containers

- `[BLOCKER]` **Pinned image tag.** `image:` must carry an explicit version tag. `:latest`, or no tag at all, is never acceptable — deploys become unreproducible and rollbacks meaningless.
- `[BLOCKER]` **Resources declared.** Every container sets both `resources.requests` and `resources.limits`. A container without limits can starve the node; one without requests schedules blind.
- `[BLOCKER]` **Readiness probe.** Every container exposes a `readinessProbe`. Without it the Service routes traffic to pods that are not ready, and rolling updates produce user-visible errors.
- `[BLOCKER]` **Restricted securityContext.** Containers default to: `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]`. Any relaxation needs an inline `# reason:` at the exact line.

## Workloads

- `[WARNING]` `revisionHistoryLimit` set explicitly (default is unlimited and accumulates ReplicaSets).
- `[WARNING]` `replicas: 1` requires an inline `# reason:` — a single replica turns every rollout and node drain into downtime.
- `[WARNING]` `matchLabels` and template labels use the `app` key consistently; do not mix `app` / `app.kubernetes.io/name` within one workload.

## Exceptions

An intentional violation is marked at the point of violation:

```yaml
replicas: 1  # reason: batch job runner, no traffic, restarts acceptable
```

`[WARNING]` exceptions need only the inline comment. `[BLOCKER]` exceptions additionally require the justification in the MR/commit description — inline alone is not sufficient.

## Provenance

Rules in this demo are deliberately generic. In a real project, replace them with rules **earned from your incidents** — each rule should be traceable to a failure that actually happened (see `docs/wip/harvest-failure-modes.md` for the open loop that grows this file).
