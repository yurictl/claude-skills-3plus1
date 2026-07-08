# Agent Telemetry — a lightweight, local observability example

Session analytics for Claude Code in the spirit of [agentsview](https://github.com/kenn-io/agentsview), rebuilt at 1% of the weight: **no server, no database, no dependencies** — two hook scripts, two Python-stdlib files, JSONL on disk, a static HTML dashboard. Everything stays on your machine.

Two problems it solves:

1. **Transcripts expire.** Claude Code session transcripts under `~/.claude/projects/` are rotated after ~30 days — and with them go your usage history, token counts, and tool statistics. A SessionEnd hook distills every session into one durable JSONL line before that happens.
2. **Work-loop events are invisible.** How often do you actually checkpoint? How often does a push happen? Which skills fire? A zero-LLM hook collector logs these as they occur — the agent is not involved and cannot forget.

## The two layers

| Store | Written by | When | Content |
|---|---|---|---|
| `.claude/telemetry/events.jsonl` | `scripts/hooks/telemetry-log.sh` | UserPromptSubmit / PreToolUse hooks, live | work-loop trigger events (append-only) |
| `.claude/telemetry/sessions.jsonl` | `scripts/telemetry_harvest.py` | SessionEnd hook + `make backfill` | one aggregate line per session: tokens, tools, models, prompts, active time |

Viewer: `scripts/telemetry_report.py` — console summary or a self-contained static HTML dashboard (light + dark, no JS libraries): KPI tiles, daily-activity bars, tool/event/skill/model breakdowns, recent-sessions table.

## Quickstart

Requirements: `python3`, `bash`. Run from this directory:

```bash
cd examples/agent-telemetry
make seed      # deterministic demo data — no real sessions needed
make report    # console summary
make html      # .claude/telemetry/report.html — open it in a browser
make reset     # wipe the stores
```

Live mode: start `claude` with this directory as the project root and just work. Prompts matching the work-loop vocabulary, `git push`, and skill invocations land in `events.jsonl` as they happen; when the session ends, its aggregate lands in `sessions.jsonl`. `make backfill` picks up sessions that never fired SessionEnd (crashes, force-kills) and any pre-existing transcripts.

## Transparency and control

Collection is automatic but auditable at four points:

- **Single source of truth: `.claude/settings.json`.** Every collector is wired there; no entry — no collection. Delete the `SessionEnd` block to stop harvesting, the `telemetry-log.sh` blocks to stop event logging.
- **Fail-open by design.** Collectors always exit 0 and write-and-forget; telemetry can never block, slow, or alter the agent's behavior. There is no LLM in the collection path.
- **Local and disposable.** Plain JSONL under `.claude/telemetry/` (gitignored); nothing is transmitted anywhere; `make reset` erases everything.
- **Bounded content.** Metadata and counters only — plus the first 200 characters of *trigger* prompts and 300 of push/MR commands. Non-trigger prompts, file contents, diffs, and agent replies are never logged.

## Mechanics worth knowing

- **Token counts dedupe by API message id** — streamed assistant chunks repeat the same `usage` object; summing per line overcounts several-fold.
- **`active_min` vs `duration_min`** — duration is wall-clock span (a resumed session inflates it grotesquely); active time sums inter-message gaps capped at 5 minutes.
- **Idempotent harvest** — `--all` skips transcripts unchanged by mtime and upserts by session id with an atomic rewrite; run it as often as you like.
- **No cost estimation, deliberately** — token counts only. Pricing tables drift; rate lookups are exactly the weight this version avoids.
- **Per-project scope** — hooks, stores, and the harvested transcript directory are all derived from the project root. Other projects are untouched; port by copying this example's `scripts/` + the hooks block.

## Layout

```
.claude/settings.json                hook wiring (the on/off switch)
scripts/
  hooks/telemetry-log.sh             layer 1: work-loop event collector
  telemetry_harvest.py               layer 2: transcript -> session aggregate
  telemetry_report.py                viewer: console + static HTML
  seed_demo.py                       deterministic demo data
Makefile                             seed / report / html / backfill / reset
```

## Relation to the verification harness

[`examples/verification-harness/`](../verification-harness/) makes docs *executable* (graders, gates, golden sets); this example makes the loop *measurable* — checkpoint cadence, grader usage, push/MR frequency, token spend. Together they close the ownership question: the harness does the checking, the telemetry proves it is actually being used.
