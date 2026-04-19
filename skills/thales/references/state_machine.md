# Thales State Machine — Full Transition Table

This reference is loaded on demand when the orchestrator encounters an ambiguous transition. SKILL.md's Core Loop section covers the normal path; this file covers everything else.

## Formal state list

- `init` — pre-cycle 1, scaffold and task.md being written
- `plan_cycle` — reading ledger, deciding cycle plan
- `brief` — constructing subagent briefs
- `spawn` — subagents running, orchestrator waiting
- `collect` — reading subagent outputs, validating structure
- `synthesize` — Synthesizer running (conditional)
- `judge` — Judge running (cycle mod 3 or stall signal)
- `checkpoint` — waiting for user
- `rehydrate` — context offload sequence
- `terminal_converged` — Judge confirmed convergence AND acceptance criteria met
- `terminal_aborted` — user aborted

## Full transition table

| Current state | Trigger | Next state | Notes |
|---|---|---|---|
| `init` | `task.md` written, scaffold verified | `plan_cycle` | Cycle count = 1 |
| `plan_cycle` | Plan written to `ledger.md` | `brief` | Plan must enumerate: spawns, target branches, cycle rationale |
| `plan_cycle` | Plan would have 0 spawns | `judge` | Nothing to brief — check for convergence/stall |
| `brief` | All briefs pass four-component check | `spawn` | |
| `brief` | A brief fails check | `brief` (rewrite) | Max 2 rewrites; third attempt — escalate to user |
| `spawn` | All subagents returned | `collect` | Timeout is orchestrator judgment; subagent work has no hard limit |
| `spawn` | A subagent returned malformed | `brief` (respawn that one) | See `troubleshooting.md` respawn protocol |
| `collect` | 2+ branches appear mergeable | `synthesize` | See phase transition rules below |
| `collect` | No merge candidates + cycle mod 3 = 0 | `judge` | |
| `collect` | No merge candidates + cycle mod 3 != 0 + no stall signal | `plan_cycle` (cycle++) | |
| `collect` | Stall signal detected | `judge` | Even if cycle mod 3 != 0 |
| `synthesize` | Synthesizer returned | `judge` or `plan_cycle` | Judge if cycle mod 3 = 0 OR synthesis verdict = MERGE_IMPOSSIBLE |
| `judge` | Status = `exploring` or `converging` + cycle mod 15 != 0 | `plan_cycle` (cycle++) | |
| `judge` | Status = `converged` | `terminal_converged` | Write final summary to `ledger.md` |
| `judge` | Status = `stalled` or `diverging` or `needs_human` | `checkpoint` | |
| `judge` | Cycle mod 15 = 0, regardless of status | `checkpoint` | Hard ceiling |
| `checkpoint` | User = APPROVE | `plan_cycle` (cycle++) | |
| `checkpoint` | User = REDIRECT | `plan_cycle` (cycle++, task.md amended) | Write redirect reasoning to ledger |
| `checkpoint` | User = PRUNE branch-X | `plan_cycle` (cycle++, branch-X archived) | See prune protocol in `ledger_format.md` |
| `checkpoint` | User = ESCALATE branch-X | `plan_cycle` (cycle++, phase locked to branch-X) | Effectively forces exploit phase on branch-X |
| `checkpoint` | User = ABORT | `terminal_aborted` | |
| any | Context approaching ~70% limit | `rehydrate` | Proactive signal, not hard fail |
| `rehydrate` | Resume checkpoint written + user starts fresh session | `plan_cycle` (state reconstructed) | |

## Stall signal definitions — formalized

The orchestrator invokes Judge early (off the mod-3 schedule) on any of these:

**Signal 1 — Flat confidence.** Two consecutive cycles where no branch's confidence field changed AND no new branch was created AND no existing branch was archived. Evidence check: `branches/*.md` modification timestamps across last 2 cycles.

**Signal 2 — Synthesizer refusal.** Synthesizer returned `MERGE_IMPOSSIBLE` — a signal that the branches are genuinely in conflict and need external adjudication.

**Signal 3 — Universal branch exhaustion.** All active Explorers in the last cycle returned `should_branch_further: false`. No one sees further to probe.

**Signal 4 — Repeated Critic hits on the same reasoning.** Critic has flagged the same logical flaw in 2+ cycles without resolution.

**Signal 5 — Reviver thrash.** Same ruled-out entry has been sent to Reviver 2+ times, both returning REAFFIRM. Stop considering it.

## Phase transitions — preconditions in detail

### Explore to Exploit

All must hold:
1. Judge verdict `converging` in current cycle
2. Leading direction named by Judge with specific branch ID
3. Leading direction has survived at least 1 Challenger attack (`verdict: weakened` does NOT count — must be `unchanged` or `strengthened-through-attack`)
4. Leading direction's branch file has at least 3 cycles of accumulated evidence
5. At least one other branch exists for contrast (a single-branch "convergence" is a red flag for premature lock-in)

If any condition fails, stay in explore regardless of Judge. Log the gap to `ledger.md`.

### Exploit to Explore (reversal)

Rare but real. All must hold for reversal:
1. Judge verdict `diverging` in exploit phase
2. Leading direction's confidence has dropped to `med` or `low`
3. A Challenger attack in the current cycle returned `weakened` with a strong objection that wasn't mitigated

Reversal is logged prominently and prior exploit-phase branches are NOT archived — they may become active again.

## Converging preconditions — full checklist

Judge may only return `converging` if ALL hold:
1. At least 4 cycles of evidence have accumulated on the candidate leading branch (cycles ON THAT BRANCH, not total cycles)
2. Leading branch has survived at least 1 Challenger attack with verdict `unchanged` or `strengthened-through-attack` (verdict = `weakened` does NOT count)
3. At least one other branch exists with active status — single-branch "convergence" is a red flag for premature lock-in
4. Confidence gap of at least one level between leader (typically `high`) and second-best (typically `med` or `low`)

If any condition fails, Judge returns `exploring` with a recommended action that would satisfy the missing condition (e.g., "Spawn Challenger on branch-N to test survival") — never `converging`.

## Convergence criteria — full checklist

Judge may only return `converged` if ALL hold:
1. Current phase = `exploit` (which requires a prior `converging` verdict file, per phase transition rules in SKILL.md)
2. Leading direction's branch confidence = `high`
3. Leading direction has survived at least 2 Challenger attacks across different cycles
4. Acceptance criteria in `task.md` are addressed, each with an explicit ledger reference
5. No unresolved entries in `open_questions.md` that are marked as blocking for the task
6. No active contradictions between the leading direction and any entry in `ruled_out.md`

If any item fails, Judge returns `converging` at best, never `converged`. This is intentionally strict — false convergence is worse than an extra cycle.

## Artifact-gated phase transition

The orchestrator must NOT transition explore → exploit based on inline reasoning. Transition requires a file at `_scratch/thales/verdicts/judge-YYYYMMDD-HHMM-cycleN.md` with `status: converging` or `status: converged`, written from an actual Judge subagent return.

If the orchestrator is tempted to write this file itself to unblock a transition, that is a design violation. The correct response is to spawn Judge (on the next scheduled judge cycle or immediately) and wait for the real verdict.

## User intervention semantics

**REDIRECT** edits `task.md` (specifically the task statement or acceptance criteria) per user input. Orchestrator may spawn a fresh Bridger next cycle because the problem framing has shifted.

**PRUNE branch-X** runs the prune protocol: archive the branch file, append entry to `dead_ends.md` with user's reason, log to `ledger.md`. Do NOT update `ruled_out.md` — that file is for claims, not branches.

**ESCALATE branch-X** locks phase to exploit and marks branch-X as the leading direction regardless of prior Judge verdict. User override is explicit and final for at least 3 cycles.

**ABORT** triggers terminal state. Orchestrator writes a final summary to `ledger.md` covering: what was tried, what converged or didn't, what the current best guess is, what the user would want to resume later.

## Fail-safe transitions

**Subagent malformed output.** Transition brief-to-spawn repeats up to twice with tightened brief. Third failure escalates to user with the malformed output included for inspection. Do not silently accept malformed output — it corrupts the ledger.

**Context rehydration triggered mid-cycle.** Complete the current cycle if in `collect` or later. If in `plan_cycle` or `brief`, finish the brief write but do not spawn. Write resume checkpoint covering exactly where in the cycle the rehydration occurred.

**User silent at checkpoint.** Do not spawn. If user returns, re-surface the checkpoint block — do not assume prior context. If user runs a different command entirely, follow that command; the Thales state persists until explicit ABORT or REDIRECT.
