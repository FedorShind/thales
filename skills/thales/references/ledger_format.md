# Thales Ledger Format — Schemas and Examples

This reference is loaded on Thales session init and stays in context for the duration of the run. The ledger is written to every cycle, so schema detail pays for itself.

## `task.md` — the task definition

Rewritten only on REDIRECT or phase transition. Not append-only.

```
# Task

<verbatim user task>

# Acceptance criteria

- <criterion 1>
- <criterion 2>
- <criterion 3>

# Phase

explore | exploit

# Phase history

- 2026-04-18 14:23 | init | explore
- 2026-04-18 15:47 | cycle-6 | explore to exploit | Judge named branch-2 leader

# Notes

<free-form orchestrator notes, rare, used for tracking user context about the task>
```

## `ledger.md` — the narrative spine

Append-only. One entry per cycle.

```
## Cycle N — YYYY-MM-DD HH:MM — Phase: explore

**Plan:** <why these spawns, what we expect to learn>

**Spawned:**
- thales-prober -> branch-1 (sub-question: "...")
- thales-bridger -> new angle (no target branch)
- thales-judge (cycle mod 3)

**Outputs summary:**
- branch-1: confidence med to high, Prober staked claim X
- bridger: produced branch-3 via mapping to domain Y
- judge: status = converging, leader = branch-1

**Stall signals:** none (or list active signals)

**Next planned action:** exploit phase transition; spawn Prober + Challenger on branch-1 next cycle
```

## `ruled_out.md` — strict append-only list of eliminated claims

**Format (one line per entry):**

```
[YYYY-MM-DD HH:MM | iter-N | confidence: high|med|low] <one-line claim> — <one-line reason>
```

**Good examples:**

```
[2026-04-18 14:45 | iter-2 | confidence: high] Hardware-efficient ansatzes are competitive with chemistry-inspired on small molecules — autoresearch-qc data: 4 orders of magnitude gap across 8 molecules
[2026-04-18 15:12 | iter-4 | confidence: med] Using Qiskit's built-in TrotterizedEvolutionGate bypasses the bug — it uses the same _recursive_qfunc internally per PennyLane source line 844
[2026-04-18 15:30 | iter-5 | confidence: low] Classical optimization replaces VQE entirely — ruled out for scope, not feasibility; revisit if scope expands
```

**Bad examples and why:**

```
Hardware-efficient ansatzes don't work
# no timestamp, no cycle, no confidence, claim too vague, no reason

[2026-04-18] X is ruled out
# missing time, iter, confidence, no separator before reason

[2026-04-18 14:45 | iter-2 | confidence: high] This approach seems suboptimal — various issues
# claim and reason are vague
```

**Format rules:**
- Timestamp always ISO-like with time
- Iter references the cycle number when the ruling was made
- Confidence is one of three exact strings
- Claim is one line, factual, specific
- Reason is one line, evidence-anchored
- Separator between claim and reason is ` — ` (em-dash surrounded by spaces)
- No multi-line entries. If it needs more, put in a branch file and reference.

## `dead_ends.md` — strict append-only list of abandoned branches

Same format as `ruled_out.md`, but the "claim" is a branch direction rather than a factual claim:

```
[2026-04-18 16:00 | iter-7 | confidence: high] branch-3 (equivariant NN analog) — disanalogy in symmetry group structure made transfers untestable; Bridger's mitigations didn't hold
```

## `open_questions.md` — strict append-only list

Same format; entries are unresolved questions:

```
[2026-04-18 14:45 | iter-2 | confidence: med] Does the SingleExcitation gate generalize to fermionic lattice problems beyond chemistry? — blocks full answer to task; needs Prober follow-up
[2026-04-18 15:30 | iter-5 | confidence: low] Is there a QAOA analog of the 5-step recipe? — adjacent, non-blocking, file for future
```

Include a blocking marker in the reason field when relevant. Judge uses these to gate convergence.

## `branches/branch-N.md` — per-branch state

One file per branch. Initialized when branch is created. Appended every cycle the branch is touched.

```
# Branch N — <short name>

**Created:** YYYY-MM-DD HH:MM | cycle-K
**Creator:** thales-<agent> (or user-initiated)
**Current confidence:** high | med | low
**Status:** active | leading | archived

## Original hypothesis

<one paragraph, from the creating agent's output>

## Evidence log

### Cycle K (initial)
- Creator: <agent>
- Findings: <paste verbatim from agent's findings section>

### Cycle K+1
- Prober on this branch: <paste verbatim>
- Critic flagged: <if relevant>

### Cycle K+2
- Challenger attacked: <paste verbatim>
- Verdict: weakened | unchanged | strengthened-through-attack

## Confidence trajectory

- cycle-K: initial = med (Bridger output)
- cycle-K+2: to high (survived Challenger, Synthesizer raised)
- cycle-K+3: to med (Critic flagged overclaim in cycle K+1 evidence)

## Open sub-questions for this branch

- <pulled from latest Explorer output>
```

**Who can write what:**
- Explorers (Prober, Challenger, Bridger, Reviver): may NOT write to branch files directly. Orchestrator appends their output to the evidence log.
- Critic: may NOT write to branch files. Output goes to `ledger.md`.
- Synthesizer: may update confidence trajectory and status via orchestrator.
- Judge: may update status to `leading` or `archived` via orchestrator.
- Orchestrator: is the only writer to the file; everyone else provides content that the orchestrator appends.

## `verdicts/judge-<timestamp>.md` — audit trail

Never overwritten. One file per Judge invocation. Filename format: `judge-YYYYMMDD-HHMM-cycleN.md`.

Contents: paste the Judge subagent's output verbatim, prefixed with orchestrator metadata:

```
# Judge verdict — cycle N

**Invoked:** YYYY-MM-DD HH:MM
**Trigger:** scheduled (cycle mod 3) | stall-signal-N | user-initiated
**Phase at invocation:** explore | exploit

---

<verbatim Judge output — status, confidence, reasoning, recommended_action>
```

## File lifecycle rules

**Append-only (never edit existing lines):**
- `ledger.md`
- `ruled_out.md`
- `dead_ends.md`
- `open_questions.md`
- `verdicts/*`

**Rewrite-allowed (edit whole file in controlled ways):**
- `task.md` — only on REDIRECT or phase transition; previous content preserved in the "Phase history" section
- `branches/branch-N.md` — append to evidence log, update confidence trajectory and status only

**Archive-rename:**
- When a branch is pruned or deemed dead, rename `branches/branch-N.md` to `branches/archived_branch-N.md`. Never delete.

## Invariants

After every cycle, these must hold:

1. Every branch referenced in `ledger.md` has a corresponding `branches/*.md` file (active or archived)
2. Every `branches/*.md` file is referenced in at least one `ledger.md` entry
3. Every Judge verdict referenced in `ledger.md` has a corresponding `verdicts/*.md` file
4. No claim in `ruled_out.md` contradicts current state of the leading branch without a cross-reference resolving the contradiction
5. If phase = exploit, exactly one branch has status = `leading`
6. If phase = explore, zero branches have status = `leading`
7. Archived branches never reappear in `ledger.md` spawn entries unless revived by Reviver with a FLIP verdict

Invariant violations = stop, log, escalate to user. Do not silently repair.
