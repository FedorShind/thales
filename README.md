# Thales

A multi-agent reasoning harness for Claude Code. Orchestrates specialist subagents through a ledger-backed iteration loop with judge-triggered checkpoints and human-in-loop supervision.

Designed for deep research, non-linear ideation, cross-domain synthesis, and hard coding problems where vanilla Claude Code has failed.

## What Thales is not

- Not an autonomous AFK agent. Thales requires human checkpoints.
- Not a token optimizer. Redundancy is accepted cost.
- Not a replacement for vanilla Claude Code. Invoked explicitly, for hard tasks only.
- Not a Ralph fork. Different architecture — structured ledger, specialist subagents, judge protocol.

## Architecture

The main Claude Code session runs the `thales` skill as an orchestrator. The orchestrator never performs substantive work itself — it delegates to seven specialist subagents (four Explorer personas, Critic, Judge, Synthesizer), maintains a structured markdown ledger in `_scratch/thales/`, and steers the investigation through explore/exploit phase transitions.

See `skills/thales/SKILL.md` for the full design.

## Install

```
./install.sh /path/to/target-project
```

This copies the skills and agents into the target project's `.claude/` directory and scaffolds `_scratch/thales/` from the ledger template.

## Invocation

In the target project's Claude Code session:

```
Use Thales: <your task>
```

Thales only activates on explicit invocation. It will not auto-trigger on difficult questions.

## Commands

- `/thales-start` — begin a new run
- `/thales-status` — read-only current state
- `/thales-checkpoint` — manual pause for intervention
- `/thales-resume` — rehydrate after context reset
- `/thales-prune branch-N` — kill a branch manually

## License

MIT. See LICENSE.

## Changelog

### 0.1.1 (2026-04-19)

Two fixes based on the first dogfood run.

**Judge enforcement.** In v0.1.0 Judge was defined as mandatory at every 3rd cycle but had no structural gate — the orchestrator could silently skip Judge and fabricate inline reasoning. In v0.1.1:
- Judge cycles are dedicated single-spawn cycles (no parallel Explorers)
- Phase transition from explore to exploit requires a real verdict file on disk (`verdicts/judge-*.md`) with `status: converging` or `converged`
- `converging` preconditions tightened: 4 cycles on the leading branch, at least one Challenger survival, multi-branch contrast, confidence gap

**Deliverer subagent.** In v0.1.0 the final user-facing output was produced by the orchestrator summarizing the ledger — which collapsed rich multi-cycle investigation into flat text. In v0.1.1 a new `thales-deliverer` subagent is spawned at convergence, user ABORT, or explicit delivery request. It reads the full ledger and produces the deliverable in the task's requested shape, with required sections for evidence anchors, dead ends, unresolved items, and calibrated confidence. The orchestrator presents Deliverer's output verbatim with only a brief covering header.

### 0.1.0 (2026-04-18)

Initial release.
