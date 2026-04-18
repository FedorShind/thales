---
name: thales-prune
description: Manually kill a Thales branch with a logged reason. Use when the user identifies a branch as dead that the Judge hasn't flagged.
---

# /thales-prune

Argument: `branch-N` and a reason from the user.

Append the branch's summary to `dead_ends.md` with the user's reason and timestamp. Mark `branches/branch-N.md` as archived (rename to `branches/archived_branch-N.md`). Add an entry to `ledger.md` noting user-initiated prune. Do not spawn — just record.
