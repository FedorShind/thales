# Thales

A Claude Code skill for problems a single pass cannot solve.

Thales turns your session into a disciplined investigation. Specialist subagents with fresh contexts propose claims, attack them, find analogs, merge findings, and render verdicts. A structured markdown ledger holds the state. Nothing converges until the evidence forces it.

Built for deep research, cross-domain ideation, vulnerability analysis, and hard engineering problems where the first answer is rarely the right one.

## Why Thales exists

A single context drifts. It commits to an early framing, accumulates sunk-cost reasoning, and produces an answer that sounds confident because it was never attacked. Thales breaks this by separating roles.

The orchestrator does not reason about the problem. It routes. Substantive work happens in subagents with fresh contexts, each bound to a narrow role: stake a claim, attack it, find an analog, render a verdict. Outputs are structured, not conversational. The ledger on disk is the source of truth, not anyone's context window.

Every third cycle, the Judge reads the full ledger and commits to one of six verdicts. Convergence is artifact-gated: the orchestrator cannot declare "done" without a verdict file on disk, written from a real Judge return. Phase transitions, likewise. The architecture removes degrees of freedom for drift.

## What Thales is good at

**Deep research with adversarial validation.** Questions where the obvious answer is usually wrong, or where the right answer requires testing many angles against each other. Thales stakes claims early and spends most of its cycles attacking them. What survives is what reached the Deliverer.

**Cross-domain synthesis.** The Bridger subagent exists to find structural analogs in unrelated fields. Its brief prohibits generic framings. A quantum chemistry question might map to an optimal-stopping problem from optimization theory, with explicit disanalogies enumerated. Most runs surface at least one non-obvious analog.

**Vulnerability and audit-style analysis.** When you need to enumerate what could break something and cannot afford to miss an angle. Dead ends are logged with reasoning. The investigation is traceable. Reviver reopens them when context shifts.

**Engineering problems where prior attempts have already failed.** Three rounds of the same bug typically share a framing. Thales spawns a Challenger whose sole job is to find the load-bearing assumption in that framing.

## What Thales is not for

One-shot tasks. Lookups. Single-file edits. Simple refactors. Anything a normal session handles. Thales spawns five to fifteen subagents per run, takes minutes to hours, and requires human checkpoints. The orchestration cost dominates for small work.

It is also not autonomous. Every fifteen cycles, or whenever the Judge returns `stalled`, `diverging`, or `needs_human`, Thales pauses and waits for your call: approve, redirect, prune, escalate, or abort. The human stays in the loop by design.

## Architecture

```
                           ┌─────────────────────┐
    user ──── "Use Thales"─│  main session       │
                           │  (orchestrator)     │
                           │  routes, curates,   │
                           │  never reasons      │
                           │  about the task     │
                           └──────────┬──────────┘
                                      │ spawns (max 3 per evidence cycle)
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                 ▼
              ┌──────────┐     ┌──────────┐     ┌──────────┐
              │ explorer │     │ explorer │     │  critic  │
              │  (fresh  │     │  (fresh  │     │  (fresh  │
              │ context) │     │ context) │     │ context) │
              └────┬─────┘     └────┬─────┘     └────┬─────┘
                   │                │                │
                   └────────────────┼────────────────┘
                                    │ structured outputs
                                    ▼
                           ┌─────────────────────┐
                           │   _scratch/thales/  │
                           │   (the ledger)      │
                           │                     │
                           │   task.md           │
                           │   ledger.md         │
                           │   ruled_out.md      │
                           │   dead_ends.md      │
                           │   open_questions.md │
                           │   branches/         │
                           │   verdicts/         │
                           └──────────┬──────────┘
                                      │ every 3rd cycle, sole spawn
                                      ▼
                               ┌────────────┐
                               │   judge    │  writes verdict file
                               │  (fresh)   │  exploring | converging
                               └─────┬──────┘  stalled | diverging
                                     │         converged | needs_human
                        ┌────────────┼────────────┐
                        ▼            ▼            ▼
                   exploring     converging    converged
                        │            │            │
                   continue      phase to     ┌───▼──────┐
                                 exploit      │ deliverer│
                                              │  (fresh) │
                                              └────┬─────┘
                                                   │
                                                   ▼
                                            verbatim to user
```

## Design principles

**State lives on disk.** `_scratch/thales/` holds the full investigation: the task, cycle narrative, ruled-out claims, dead ends, open questions, per-branch evidence, verdict files. Contexts are ephemeral; the ledger persists. `/thales-resume` rehydrates in a fresh session.

**The ledger is append-only where it matters.** `ruled_out.md`, `dead_ends.md`, and `open_questions.md` use a strict one-line format that can be grepped. Explorers receive these files verbatim in their briefs. The system cannot quietly re-derive something it already killed.

**Fresh contexts everywhere.** Every subagent spawn starts clean. No inherited framing, no sunk-cost bias from prior cycles. The only channel in is the brief; the only channel out is a structured return.

**Convergence is earned.** Four cycles on the leading branch. At least one Challenger attack survived. A second branch for contrast. A confidence gap between leader and runner-up. If any precondition fails, the Judge returns `exploring` and names what needs to happen next.

**Delivery is its own agent.** `thales-deliverer` reads the entire ledger and produces the final answer in the shape the task asked for. The orchestrator presents this verbatim, with only a brief covering header. No summarization, no paraphrasing.

## Subagents

| Agent | Role |
|---|---|
| **thales-prober** | Deep-dives a branch; stakes one specific, falsifiable claim. |
| **thales-challenger** | Attacks the leading direction; finds the assumption whose failure kills it. |
| **thales-bridger** | Finds structural analogs in unrelated fields, with explicit disanalogies. |
| **thales-reviver** | Re-examines ruled-out directions when new context may change the verdict. |
| **thales-critic** | Audits the ledger itself for overclaims, handwaving, missing alternatives. |
| **thales-judge** | Commits to one of six structured verdicts every third cycle or on stall. |
| **thales-synthesizer** | Merges ripe branches into a unified direction. |
| **thales-deliverer** | Produces the final user-facing artifact from the full ledger. |

## Install

Per-project:

```bash
./install.sh /path/to/target-project
```

Global, available in every Claude Code session:

```bash
# bash / zsh
mkdir -p ~/.claude/skills ~/.claude/agents
cp -R skills/thales* ~/.claude/skills/
cp agents/*.md ~/.claude/agents/
```

```powershell
# PowerShell
New-Item -ItemType Directory -Force -Path $HOME\.claude\skills, $HOME\.claude\agents | Out-Null
Copy-Item -Recurse skills\thales $HOME\.claude\skills\
Copy-Item -Recurse skills\thales-start $HOME\.claude\skills\
Copy-Item -Recurse skills\thales-status $HOME\.claude\skills\
Copy-Item -Recurse skills\thales-checkpoint $HOME\.claude\skills\
Copy-Item -Recurse skills\thales-resume $HOME\.claude\skills\
Copy-Item -Recurse skills\thales-prune $HOME\.claude\skills\
Copy-Item agents\*.md $HOME\.claude\agents\
```

## Invocation

In any Claude Code session:

```
Use Thales: <your task>
```

The trigger is explicit. "Use Thales," "run Thales," "kick off Thales" -- all valid. Anything without the word leaves Thales dormant.

## Commands

- `/thales-start` -- begin a new run
- `/thales-status` -- current state, read-only
- `/thales-checkpoint` -- manual pause to intervene
- `/thales-resume` -- rehydrate after a context reset
- `/thales-prune branch-N` -- kill a branch with a logged reason

## How a run progresses

Cycle 1 is an evidence cycle. A Prober stakes a claim on the stated problem; a Bridger finds a cross-domain angle. Structured outputs land in `branches/branch-1.md` and `branches/branch-2.md`.

Cycle 2 is an evidence cycle. Prober deepens branch-2; Challenger attacks branch-1. The Challenger's verdict -- `weakened`, `unchanged`, or `strengthened-through-attack` -- enters the evidence log.

Cycle 3 is a Judge cycle. Judge alone. Judge reads the full ledger and commits to a verdict, written verbatim to `verdicts/judge-cycle-3.md`. Most cycle-3 verdicts are `exploring`. Convergence preconditions are strict enough that three cycles rarely qualify.

Cycles 4 and 5 continue evidence. Cycle 6 is the next Judge cycle. Phase transitions to exploit only if the Judge file says so.

On `converged`: the Deliverer reads the full ledger and produces the final answer. You see it verbatim.

On `stalled`, `diverging`, or `needs_human`: checkpoint. You decide the next move. Thales does not continue until you answer.

Cycle 15, 30, 45: hard-ceiling checkpoints regardless of Judge state. You will never lose track of a long run.

## License

MIT. See LICENSE.