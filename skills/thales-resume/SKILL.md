---
name: thales-resume
description: Resume a Thales run after a context reset or fresh session. Use at the start of a new session to rehydrate from the ledger.
---

# /thales-resume

Read full `_scratch/thales/` tree. Reconstruct state: phase, cycle count, active branches, last action, last judge verdict. Report the reconstructed state to user. Ask: continue from last planned action, or take a checkpoint first? Then proceed per the thales skill state machine.
