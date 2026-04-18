# Thales Troubleshooting — Known Failure Modes and Recovery

This reference is loaded on demand, specifically after: a subagent rejection, a ledger integrity warning, a phase transition that failed validation, or user report of unexpected behavior. Most runs will not need it.

## Subagent output failures

### Missing required section

Subagent output passes through orchestrator's structural validator. If a required section is missing:

1. Do NOT accept the output. Do NOT try to infer the missing content from surrounding sections.
2. Respawn the same subagent type with an amended brief. The amendment: append a new final section to the brief titled "Output validation" stating: "Your output will be rejected if it does not include ALL of these sections as H2 headers: [list]. Sections with no content must still appear with the header and the literal text 'NO_CONTENT' under them."
3. Second failure: respawn one more time with the "NO_CONTENT" rule AND with the failing output quoted in the new brief as an example of what was rejected and why.
4. Third failure: escalate to user. Present the three rejected outputs. User decides whether to accept degraded output, modify task, or abort.

### Bland or evasive output passing structural checks

Subagent returned all required sections but with content like "more research needed," "this is complex," "several factors matter." Structure passes; substance failed.

This is a BRIEF FAILURE, not a subagent failure. The anti-blandness directive was not strong enough or the sub-question was too broad.

**Recovery:**
1. Respawn with a narrower sub-question. "Is X better than Y" becomes "For molecules in the set {H2, LiH, BeH2}, does SingleExcitation + DoubleExcitation ansatz reach chemical accuracy with fewer iterations than hardware-efficient ansatz?"
2. Strengthen the anti-blandness directive with a concrete rejection example: "Outputs of the form 'it depends on the use case' will be rejected. You must name the specific cases and specific verdict per case."
3. If it fails again with a narrower sub-question, the branch may be genuinely exhausted. Add a stall signal and move to Judge.

### Subagent contradicts ledger

Subagent output re-derives something already in `ruled_out.md`, or proposes a branch already in `dead_ends.md`.

This is a BRIEF FAILURE — the ledger slice was not included verbatim in the brief.

**Recovery:**
1. Accept the subagent's work is wasted, but check for a silver lining: did the subagent find a new angle on the ruled-out claim? If so, that's Reviver territory, not a failure.
2. Respawn with `ruled_out.md` and `dead_ends.md` fully included in the brief. Explicitly say: "The following claims are ruled out. Do not re-derive them. If you believe one of these rulings is wrong, say so explicitly and stop — do not proceed with investigation."
3. Log a brief-protocol-violation note in `ledger.md` so the pattern is visible across cycles.

## Ledger integrity failures

### Write conflicts

Single-session Thales should not produce write conflicts. If one appears (e.g., a file has multiple entries with the same timestamp and conflicting content), treat it as corruption:

1. Quarantine the conflicting entries — move them to `_scratch/thales/_quarantine/` with a note
2. Do not silently pick a winner
3. Escalate to user with the conflicting content

### Branch file missing but referenced

`ledger.md` references `branches/branch-3.md` but the file doesn't exist.

**Recovery:**
1. Reconstruct a minimal `branches/branch-3.md` from all `ledger.md` entries that reference it
2. Add a prominent note at the top: "RECONSTRUCTED FROM LEDGER on YYYY-MM-DD — original file was missing. Evidence may be incomplete."
3. Flag the branch confidence to `low` regardless of prior value until a subsequent cycle validates it
4. Log the reconstruction event to `ledger.md`

### Strict-format violation

An entry in `ruled_out.md`, `dead_ends.md`, or `open_questions.md` doesn't match the required format.

**Recovery:**
1. Do NOT silently fix it. Silent repair hides problems.
2. Append a new entry immediately below it: `[YYYY-MM-DD HH:MM | iter-N | confidence: high] FORMAT_VIOLATION flagged above — <reason>`
3. Do not attempt to parse the malformed entry for semantic content in subsequent grep-based brief construction
4. On next cycle, surface the violation in the cycle plan so user sees it

## Phase transition failures

### Premature convergence

Transitioned to exploit phase. Next cycle's Challenger attack returns `weakened` with a strong unmitigated objection.

**Recovery:**
1. Revert phase to explore
2. Update `task.md` phase history with the revert and reasoning
3. Leading branch's status reverts from `leading` to `active`
4. Next cycle: spawn Challenger again on the formerly-leading branch with a brief referencing the objection; also spawn Bridger for a fresh angle
5. This is not a failure mode to hide from the user — log it prominently in `ledger.md`

### Judge oscillation

Judge returns `converging` cycle N, `exploring` cycle N+3, `converging` cycle N+6. Not converging — oscillating.

**Recovery:**
1. Force an extended explore phase: next 3 cycles, heavy Challenger and Bridger; no exploit transition allowed
2. If oscillation continues past 3 forced-explore cycles, the task may be under-specified or genuinely multi-modal
3. Surface to user at checkpoint: "Judge has oscillated N times. This usually means the task has multiple valid directions or acceptance criteria are ambiguous. Do you want to (a) tighten acceptance criteria, (b) pick one direction and commit, (c) continue exploring with awareness that convergence may not come?"

## Context rehydration failures

### Corrupt ledger on resume

User runs `/thales-resume` in a new session. Ledger files are partially written, contradictory, or missing.

**Recovery:**
1. Report to user exactly which files are intact and which are corrupt
2. Offer two paths: (a) partial-state reconstruction — use what's intact, flag what's missing, resume with degraded ledger; (b) fresh start — archive current `_scratch/thales/` as `_scratch/thales_corrupt_<timestamp>/` and initialize new run
3. Do NOT auto-pick. This is a user decision.

### Proactive rehydration needed but user unaware

Orchestrator detects context approaching ~70% of limit mid-cycle.

**Protocol:**
1. Finish current cycle if in `collect` state or later
2. If in `plan_cycle` or `brief`, finish the brief-writing step without spawning
3. Write a "resume checkpoint" entry to `ledger.md` with exact state: current phase, active branches, next planned action, any pending spawns
4. Surface to user: "Context is getting heavy. I've written a resume checkpoint to the ledger. Start a fresh session and run `/thales-resume` to continue without degradation."
5. Do NOT continue past this point. Forced halt is better than degraded reasoning.

## User-interaction failures

### User abandons at checkpoint

Orchestrator surfaced checkpoint, user did not respond and moved to a different task. Checkpoint is still pending.

**Protocol:**
1. Do NOT spawn. Thales is paused.
2. If user returns and addresses Thales even obliquely, re-surface the checkpoint block with: "Thales is paused at cycle N awaiting your decision on the checkpoint below."
3. If user runs a Thales command other than checkpoint response (e.g., `/thales-status`), answer the command but re-surface the checkpoint block at the end

### User gives contradictory direction

User says both APPROVE and REDIRECT in one turn, or names a branch to PRUNE that's already archived.

**Protocol:**
1. Do NOT pick. Stop and ask for clarification.
2. Specifically quote the contradiction: "You said APPROVE and REDIRECT. Which do you want?"
3. Default to stop (do not spawn) until unambiguous

## Orchestrator drift

### Reasoning trap

Orchestrator catches itself producing substantive analysis in main session — e.g., reasoning about whether a hypothesis holds, analyzing code directly, proposing solutions.

**Immediate recovery:**
1. Stop mid-thought. Do NOT finish the reasoning in main session.
2. Log a "drift noted" entry in `ledger.md`: "Orchestrator drifted into [type of reasoning]; properly delegated to [subagent type] next."
3. Construct a brief for the appropriate Explorer with the topic you were drifting into as the sub-question
4. Spawn fresh. Discard the partial reasoning that was happening in main session — it was happening in the wrong context.

### Incomplete brief

Orchestrator is about to spawn with a brief missing one of the four required components.

**Recovery:**
1. Do NOT spawn. Refuse self-spawn.
2. Rewrite the brief to include all four components
3. If a component genuinely cannot be constructed (e.g., no clear sub-question because the cycle plan is too vague), the cycle plan is flawed — return to `plan_cycle` state and rewrite the plan

### Skipped Judge

Orchestrator planned to skip Judge at cycle mod 3 "because things are going well."

This is a bug. Judge is mandatory at mod 3 regardless of perceived progress — the whole point is detecting false positives. If you're tempted to skip, that's a stronger signal to spawn Judge.

**Recovery:** Spawn Judge. If Judge confirms things are going well, great — the check cost a small amount of time and produced an audit record. If Judge disagrees, the skip would have been a disaster.
