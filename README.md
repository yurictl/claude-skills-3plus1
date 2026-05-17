# claude-skills-3plus1

Personal [Claude Code](https://claude.com/claude-code) skills built around the **3+1 documentation framework**.

The premise: most engineering knowledge is never published, because the act of writing it up is too expensive. If documentation lives in a shape that *both* humans and agents can read, write, and keep current, that cost collapses. These four skills are the operational loop I use to make that real.

Framework reference: [LinkedIn — "Most engineering knowledge is never published"](https://www.linkedin.com/feed/update/urn:li:share:7431585543827668992).

---

## The 3+1 framework, in one screen

| Bucket | Lives in | Holds |
|---|---|---|
| **Orientation** (persistent) | `CLAUDE.md` + optional `LEXICON.md` + optional `CONTRACT.md` at project root | Scope, status, project map; canonical vocabulary; behavioural agreement with the agent |
| **Operations** (persistent) | `docs/operations/` | Runnable procedures with the reference data they need, one topic per file |
| **Decisions** (persistent) | `docs/decisions/` | ADRs / design docs / post-mortems; why a choice was made; append-only or supersede |
| **WIP** (transient) | task tracker (ergo / bd / GitHub Issues / `docs/wip/`) | Hypotheses, investigations, deferred questions — graduate or drop when resolved |

`LEXICON.md` and `CONTRACT.md` are **lazy** — they appear when there is something to write, not before.

---

## The four skills and how they compose

```
                    ┌────────────────────────────────────────┐
                    │             3+1 docs                   │
                    │  Orientation · Operations · Decisions  │
                    └──────────┬──────────────┬──────────────┘
                               │              │
                  grill-me ────┘              └──── graduate
                  (write into docs)                 (move WIP → docs)
                               │              │
                               ▼              ▲
                          start-work ────────►│
                          (work the WIP layer)│
                                              │
                          transcript-mine ────┘
                          (close the correction loop — feed rules back into Orientation)
```

### `grill-me` — interview, then route

Adapted from Matt Pocock's [`grill-with-docs`](https://github.com/mattpocock). Interviews you one question at a time about a plan or design, and routes every resolution into the right bucket: glossary terms into `LEXICON.md`, agent-behaviour rules into `CONTRACT.md`, procedures into Operations, costly-to-reverse choices into Decisions, deferred questions into WIP. The added layer over `grill-with-docs` is **`CONTRACT.md`** — the working agreement with the agent itself (proactivity radius, batch protocol, ask-first gates, skill auto-trigger policy).

### `start-work` — work the WIP layer

Four phases on whichever tracker the project uses (ergo, beads, GitHub Issues, plain WIP files, ad-hoc):

- **start work / kick off** — gather context, plan, set up the tracking artifact
- **continue / resume** — recall the in-flight task after a clean session
- **proceed / let's go** — execute the existing plan autonomously until a fork or blocker
- **checkpoint / snapshot** — persist progress before session context is lost

Detects the tracker convention from `CLAUDE.md`; does not invent one.

### `graduate` — promote WIP into permanent docs

When a tracked task is verifiably done, move the durable knowledge into Operations / Decisions and close the tracking artifact **cleanly** — no stub, no cross-reference. Prefers updating an existing doc over creating a new one. Strips WIP-flavoured language ("we investigated whether…") and rewrites in fact mode.

This is the bridge from the transient bucket to the persistent ones. Without `graduate`, the WIP layer accretes and the docs surface stays empty.

### `transcript-mine` — close the correction loop

Eugene Yan's *compounding-loop* practice for Claude Code. Scans recent transcripts for recurring user-correction patterns ("stop doing X", "you forgot Y", "still wrong"), surfaces the top clusters with hit counts, and proposes config updates. Operates locally on `~/.claude/projects/*/*.jsonl`; nothing leaves the machine.

Without this, every correction is forgotten next session. With it, corrections compound — usually into a new `CONTRACT.md` clause or a `CLAUDE.md` line, which means the loop closes inside the 3+1 framework rather than outside it.

---

## The loop

```
plan → grill-me → docs (Orientation + Decisions seeded)
                    │
                    ▼
              start-work → WIP tracker → execute
                    │
                    ▼
              graduate → Operations / Decisions updated, WIP closed
                    │
                    ▼
              transcript-mine (periodic) → CONTRACT / CLAUDE.md hardened
                    │
                    └─► next plan starts with a sharper agent
```

Each skill writes to a layer the next one reads. Skip any of them and the loop leaks: skip `grill-me` and docs stay tacit; skip `graduate` and WIP rots; skip `transcript-mine` and the same correction repeats every session.

---

## Install

Symlink the skills into your Claude Code skills directory:

```bash
git clone git@github.com:<you>/claude-skills-3plus1.git
cd claude-skills-3plus1

ln -s "$(pwd)/skills/grill-me"        ~/.claude/skills/grill-me
ln -s "$(pwd)/skills/start-work"      ~/.claude/skills/start-work
ln -s "$(pwd)/skills/graduate"        ~/.claude/skills/graduate
ln -s "$(pwd)/skills/transcript-mine" ~/.claude/skills/transcript-mine
```

Or copy if you prefer to detach from upstream.

Each skill is self-contained: a `SKILL.md` (the contract Claude Code reads) plus, where relevant, a `references/` sub-tree for longer protocols and a `scripts/` tree for executables.

---

## Project layout

```
claude-skills-3plus1/
├── README.md                    — this file
├── LICENSE
└── skills/
    ├── grill-me/
    │   └── SKILL.md
    ├── start-work/
    │   ├── SKILL.md
    │   └── references/          — per-phase protocols
    ├── graduate/
    │   └── SKILL.md
    └── transcript-mine/
        ├── SKILL.md
        ├── references/          — pattern interpretation, rule placement
        └── scripts/             — mine_transcripts.py + default patterns
```

---

## Status

Personal. Lightly polished for sharing, not productised. Conventions evolve in lockstep with my own use; expect breaking changes in `CONTRACT.md` shape and tracker detection as the framework matures.

Origin credits:
- `grill-me` — adapted from Matt Pocock's `grill-with-docs`.
- `transcript-mine` — implements Eugene Yan's *closing-the-loop* step from *How to Work and Compound with AI* (2026-05).
- 3+1 framework — mine, written up at the LinkedIn link above.
