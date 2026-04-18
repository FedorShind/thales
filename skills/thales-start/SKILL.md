---
name: thales-start
description: Entry point for a new Thales investigation. Initializes the ledger and runs the first orchestration cycle. Use when the user says "use Thales" or similar explicit invocation with a task.
---

# /thales-start

Initialize a fresh Thales run on the user's stated task.

## Steps

1. **Confirm invocation is explicit.** User must have said "use Thales", "thales this", "run Thales" or similar. If not, do not run — explain Thales and ask if they want to invoke.

2. **Verify scaffold.** Check `_scratch/thales/` exists. If not, copy from the Thales skill's `assets/ledger_template/`. If it exists and is non-empty, confirm with user whether to overwrite or resume.

3. **Write `task.md`.** Record: the task verbatim from user; acceptance criteria (ask user if not given); starting phase = `explore`.

4. **Load the thales skill.** Read `skills/thales/SKILL.md` fully before the first cycle plan. Also load `skills/thales/references/ledger_format.md` for the session.

5. **Run plan_cycle state.** Per the state machine in the thales skill. Cycle 1 spawn is typically Bridger + Prober for research tasks, Prober + Challenger for coding tasks — but follow the spawn decision tree, not this note.

6. **Brief, spawn, collect, write to ledger.** Standard cycle.

7. **Report cycle 1 result to user** in plain prose. Do not present a checkpoint yet — checkpoints come at cycle 3 (first Judge) or stall.

## Guardrails

- Do not spawn more than 3 subagents in cycle 1.
- Do not skip writing `task.md` before spawning.
- Do not do substantive work yourself — you are the orchestrator.
