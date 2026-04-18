---
name: thales-checkpoint
description: Manually trigger a Thales checkpoint mid-cycle. Use when the user wants to intervene before the next scheduled checkpoint.
---

# /thales-checkpoint

Pause current cycle. Produce the checkpoint block per `skills/thales/SKILL.md` "Checkpoint protocol" section. Wait for user input (APPROVE / REDIRECT / PRUNE / ESCALATE / ABORT) before resuming.
