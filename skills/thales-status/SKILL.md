---
name: thales-status
description: Report current Thales run state without spawning or advancing. Use when the user wants a status update mid-run.
---

# /thales-status

Read-only. No spawning.

Read `_scratch/thales/` tree. Produce a status block: current phase, cycle count, active branches with confidence, last judge verdict, next planned action per last `ledger.md` entry. Do not produce analysis or recommendations — that's Judge's job.
