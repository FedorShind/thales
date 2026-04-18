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
