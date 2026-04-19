---
name: thales
description: This skill should be used ONLY when the user explicitly invokes Thales by name (e.g., "use Thales", "kick off Thales", "run Thales on this"). Thales orchestrates specialist subagents through a ledger-backed iteration loop for deep research, non-linear ideation, cross-domain synthesis, and hard coding problems where vanilla Claude Code has failed. Not for simple tasks.
---

# Thales — Orchestrated Iterative Reasoning

Thales is a multi-agent harness for hard problems. The main session (holding this skill) is the orchestrator. It never does substantive work itself — it delegates to specialist subagents, maintains a persistent ledger, and steers the investigation through phase transitions under user supervision.

Thales is a generalization of the autoresearch pattern (hypothesis → experiment → update → next hypothesis) with four explorer personas, a judge, a critic, a synthesizer, and a human-in-loop checkpoint protocol.

## When to invoke this skill

**Invoke ONLY when the user explicitly names Thales.** Triggers: "use Thales", "run Thales", "kick off a Thales loop", "thales this problem". Never auto-activate on problem difficulty signals alone — even a hard research question without the word "Thales" gets a normal response.

**When NOT to invoke:**
- User mentions Thales conceptually but is asking about it, not requesting a run ("how does Thales work?" — explain, don't spawn)
- Task is time-sensitive (Thales runs for many minutes to hours)
- Task is AFK-only — Thales requires human checkpoints
- Single-file edit, lookup, simple refactor — orchestration overhead dominates

## Core operating principle

**The orchestrator never does substantive work.** It routes, curates, synthesizes summaries, and spawns. If you find yourself reasoning deeply about the problem in the main session, stop — that reasoning belongs in an Explorer subagent with fresh context. The orchestrator's job is meta: which subagent to spawn next, what brief to give it, when to call the judge, when to escalate to the user.

## State machine

Thales runs in cycles. Cycles are one of two types: **evidence cycles** (plan → brief → spawn → collect → synthesize) or **judge cycles** (Judge alone, no Explorers). Every 3rd cycle is a judge cycle. Stall signals also force the next cycle to be a judge cycle, regardless of position in the mod-3 schedule.

**Evidence cycle states:**
1. **plan_cycle** — Read ledger. Decide: which subagents to spawn, which branches to target, what questions to pose. Write cycle plan to ledger.
2. **brief** — Construct one brief per subagent to spawn. Each brief follows the rules in Section "Brief construction".
3. **spawn** — Invoke subagents in parallel (max 3 per cycle). Wait for all to return.
4. **collect** — Read subagent outputs. Validate structure. Write raw outputs to `_scratch/thales/branches/branch-N.md` (appending).
5. **synthesize** — If multiple branches are ripe for merging, spawn Synthesizer. Update `ledger.md` with cycle summary.

**Judge cycle states:**
1. **plan_judge** — Log to ledger that this is a Judge-only cycle. No other spawns this cycle.
2. **spawn_judge** — Invoke `thales-judge`. Sole action this cycle.
3. **write_verdict** — On return, orchestrator writes verdict verbatim to `_scratch/thales/verdicts/judge-YYYYMMDD-HHMM-cycleN.md`. This file's existence is the proof that Judge fired. Without the file, Judge did not fire — do not proceed.
4. **act_on_verdict** — Per verdict status, next cycle is planned accordingly. `converged` transitions to `terminal_converged`. `stalled`, `diverging`, `needs_human` transition to `checkpoint`. `exploring` or `converging` continue to next cycle.

**Checkpoint state** fires on: judge trigger (stalled / diverging / needs_human), cycle count mod 15 = 0, or user request.

**The cycle-mod-3 rule is non-negotiable.** If cycle_count mod 3 == 0, the orchestrator's ONLY action this cycle is a Judge spawn. Not "Judge appended to spawn list." Not "Judge in parallel with Explorers." Judge alone. This is because Judge must read the completed ledger state, not a snapshot mid-cycle. Parallel-spawning Judge with Explorers is a design violation and produces stale verdicts.

**Stall signals** that force the next cycle to become a judge cycle:
- Two consecutive evidence cycles with zero confidence change on any branch
- Synthesizer returns `MERGE_IMPOSSIBLE`
- All Explorers in the last evidence cycle return `should_branch_further: false`
- Critic has flagged the same logical flaw in 2+ cycles without resolution
- Same ruled-out entry sent to Reviver 2+ times, both returning REAFFIRM

For the full state transition table, load `references/state_machine.md`.

## Phases: explore vs. exploit

Thales runs in one of two phases, tracked in `_scratch/thales/task.md`.

**Explore phase** (default at start):
- Spawn diverse personas — heavy Bridger and Challenger use
- Accept low-confidence branches for further investigation
- Tolerate contradictions in ledger — record both sides

**Exploit phase** (after convergence signal):
- Heavy Prober use on the leading direction
- Challenger still active — the leader must survive attack
- Resolve contradictions — Synthesizer decisions carry weight

**Phase transition is artifact-gated.** The orchestrator may NOT transition from explore to exploit based on inline reasoning. Transition is valid only if ALL hold:

1. A file exists at `_scratch/thales/verdicts/judge-YYYYMMDD-HHMM-cycleN.md` for the current or immediately prior cycle.
2. That file's `status` field is `converging` or `converged`.
3. The verdict file was written from an actual Judge subagent return — not composed by the orchestrator. (If you are tempted to write the verdict file yourself to satisfy this check, you are violating the design. Spawn Judge.)

If no valid verdict file exists, the orchestrator must spawn Judge (on the next judge cycle or immediately if none is scheduled) before transitioning phase. Inline reasoning about "we seem to be converging" is not a valid substitute.

Exploit-to-converged transition requires: phase = exploit, AND latest Judge verdict status = `converged`, AND all acceptance criteria in `task.md` addressed with explicit ledger references.

Phase transitions are logged to `ledger.md` with reasoning AND a reference to the gating verdict file. Full phase transition preconditions in `references/state_machine.md`.

## Subagent taxonomy

Seven specialist types. Orchestrator picks per cycle based on ledger state.

| Agent | Fresh context | When to spawn | Required output sections |
|---|---|---|---|
| `thales-prober` | yes | Explore a branch deeper; commit to a specific testable claim | `findings`, `confidence`, `ruled_out`, `open_sub_questions`, `should_branch_further` |
| `thales-challenger` | yes | Attack current leading direction; find killing assumption | `attack_vectors`, `strongest_objection`, `mitigations_considered`, `verdict` |
| `thales-bridger` | yes | Find cross-domain structural analog | `source_domain`, `structural_mapping`, `testable_transfers`, `disanalogies` |
| `thales-reviver` | yes | Re-examine a specific ruled-out direction | `original_ruling`, `new_evidence`, `revised_verdict`, `reasoning` |
| `thales-critic` | yes | Periodic adversarial pass on reasoning quality (not the claim — that's Challenger) | `logical_flaws`, `missing_alternatives`, `overclaim_risks` |
| `thales-judge` | yes | Every 3rd cycle (dedicated judge cycle) or on stall signal. Sole action that cycle. Writes verdict file to `verdicts/`. | `status`, `confidence`, `reasoning`, `recommended_action` |
| `thales-synthesizer` | yes | When 2+ branches produce mergeable findings | `merged_direction`, `preserved_from_branches`, `discarded_from_branches`, `new_open_questions` |
| `thales-deliverer` | yes | On Judge `converged`, user ABORT, or explicit delivery request. Produces the final user-facing artifact. | task-shape-dependent (top-N, recommendation, report, etc.) + required `evidence_anchors`, `dead_ends_informing_survivors`, `unresolved`, `confidence_statement` |

## Spawn decision tree

Before running the tree, check cycle type:

**If `cycle_count mod 3 == 0` OR a stall signal is active: this is a judge cycle.**
- Sole action: spawn `thales-judge`. No other spawns.
- Skip the rest of the decision tree.
- Proceed to brief construction for Judge, then spawn, then write verdict file.

**Otherwise, this is an evidence cycle.** Run through the tree:

1. **Is this the first cycle?** Spawn Bridger + Prober on the task. Skip to brief construction.
2. **Is phase = exploit and leading direction exists?** Spawn Prober on the leader. If cycle count mod 2, also spawn Challenger on it.
3. **Are there fewer than 2 active branches?** Spawn Bridger for a new cross-domain angle.
4. **Are there 3+ active branches with comparable confidence?** Spawn Challenger on the weakest, not the strongest (prune by attack, not by neglect).
5. **Did last Judge verdict say `stalled`?** Spawn Reviver on the most promising entry in `dead_ends.md`.
6. **Cap total spawns at 3 per cycle.** If step 1–5 selected more, drop lowest-priority first (Reviver < Critic < Synthesizer < Challenger < Prober < Bridger during explore; invert during exploit).

Document the cycle plan with reasoning in `ledger.md` before spawning. For edge cases, load `references/spawn_discipline.md`.

## Brief construction

Every subagent brief has four required components. Missing any = brief rejected, rewrite before spawning.

**(1) Focused sub-question.** One sentence. Specific enough that "answered" has a clear meaning. "Explore MCMC approaches" is bad. "Does a Gibbs sampler outperform HMC on the posterior shape described in `branches/branch-2.md`?" is good.

**(2) Ledger slice, read verbatim.** Tell the subagent which ledger files to read and that it must read them verbatim before starting. Mandatory files per agent type:
- All Explorers: `task.md`, `ruled_out.md`, `dead_ends.md`, `open_questions.md`
- Prober, Challenger: also the target `branches/branch-N.md`
- Bridger: only `task.md` + `ruled_out.md` (keep domain assumptions minimal)
- Reviver: specific entry in `dead_ends.md` (quote the entry in the brief)
- Judge: full ledger tree
- Critic: `ledger.md` recent cycles + current leading branch
- Synthesizer: all branches being merged, verbatim

**(3) Required output structure.** Enumerate the required sections. Subagent output that skips required sections is rejected.

**(4) Anti-blandness directive.** Tailored per agent type:
- Prober: "You must stake one specific testable claim. 'More research needed' is a failure mode."
- Challenger: "Your success condition is making the leading direction look weaker than when you started. If you can't, state why explicitly."
- Bridger: "Name a specific source domain outside the task's field. Generic 'systems thinking' analogies are failures."
- Reviver: "Either flip the verdict with concrete new evidence, or reaffirm with reasoning that references the new ledger context. Neutral 'it's complicated' is a failure."
- Critic: "Point to specific sentences in the ledger that overclaim, handwave, or skip alternatives. Generic skepticism is a failure."
- Judge: "Pick one status verdict and defend it. 'Possibly converging' is a failure — use `converging` or `exploring`."
- Synthesizer: "Produce a single unified direction, not a list of options. If merger is impossible, say so and which branch to keep."

## Ledger discipline

Source of truth. Orchestrator reads before spawning, writes after collecting.

**Files (all under `_scratch/thales/`):**
- `task.md` — the original task, acceptance criteria, current phase. Rewritten only on phase transitions or REDIRECT.
- `ledger.md` — cycle log. Append-only.
- `ruled_out.md` — strict format. Append-only. Grepped by every Explorer brief.
- `dead_ends.md` — same strict format as ruled_out but for abandoned branches.
- `open_questions.md` — same strict format. Append-only.
- `branches/branch-N.md` — one file per branch. Appended per cycle. Confidence updated by Synthesizer or Judge only.
- `verdicts/judge-<timestamp>.md` — never overwritten. Audit trail.

**Discipline rules:**
- Write to ledger BEFORE next spawn cycle. If orchestrator context fails mid-cycle, resume reads latest ledger state.
- Never summarize `ruled_out.md` for a brief. Paste verbatim. Summarization is how redundant exploration happens.
- Synthesizer is the ONLY agent that modifies `branches/branch-N.md` confidence fields. Explorers append raw findings.
- Judge verdicts go to `verdicts/` always, even when `status = exploring` (audit trail matters).

Full schemas with valid and invalid examples: `references/ledger_format.md` (load at session init).

## Checkpoint protocol

Two triggers: Judge says `needs_human`, or cycle count mod 15 = 0.

At a checkpoint, orchestrator produces a single markdown block:

```
## Thales Checkpoint — Cycle N

**Current best direction:** <one paragraph, specific>
**Confidence:** <high/med/low, with one-line reasoning>

**Active branches:**
- branch-1: <one-line status>
- branch-2: <one-line status>

**Recent pivots:** <what changed in last 3 cycles>
**Open questions:** <top 3 from open_questions.md>

**Options:**
- APPROVE: continue current plan for next cycle
- REDIRECT: change direction (specify)
- PRUNE branch-X: kill a branch, log reason
- ESCALATE branch-X: double-down on a branch
- ABORT: stop Thales, write final summary to ledger
```

Wait for user response. Do not spawn until answered.

## Context rehydration

When main session context gets heavy (~70% of limit): proactively write a "resume checkpoint" entry to `ledger.md` containing enough state to rebuild: current phase, active branches, next planned action. Tell user it's time to start a fresh session and run `/thales-resume`.

If the user runs `/thales-resume` in a new session: read entire ledger tree, reconstruct current state, report it, and continue from the last planned action.

## Anti-patterns — orchestrator MUST NOT

- Reason deeply about the problem in main session. If tempted, spawn a Prober instead.
- Spawn a subagent without a brief meeting all four requirements.
- Summarize `ruled_out.md` or `dead_ends.md` in any brief. Always verbatim.
- Skip a scheduled Judge cycle to "save time." Judge cycles are mandatory at mod 3.
- Parallel-spawn Judge with Explorers. Judge cycles are Judge-only.
- Write a verdict file yourself to satisfy the phase-transition gate. Only actual Judge subagent output is a valid verdict.
- Fabricate inline Judge reasoning in `ledger.md` without spawning Judge. Judge's audit trail is the `verdicts/` file, not a ledger mention.
- Declare convergence without a `converging` or `converged` verdict file on disk for the current cycle range.
- Transition phase based on inline reasoning. Phase transition is artifact-gated.
- Accept a subagent output missing required structure. Reject and respawn.
- Write to `branches/*` confidence fields directly. Synthesizer or Judge only.
- Spawn more than 3 subagents in a single cycle.
- Continue past a checkpoint without user input.
- Write the final user-facing deliverable yourself. Spawn `thales-deliverer` and present its output verbatim.
- Paraphrase, summarize, or "helpfully frame" Deliverer's output to the user. Verbatim with a brief header is the only permitted format.

When one of these happens or threatens, load `references/troubleshooting.md`.

## Delivery protocol

The final user-facing output is produced by the `thales-deliverer` subagent, not by the orchestrator. This prevents the orchestrator from paraphrasing a rich ledger into a generic summary at delivery time.

**Spawn Deliverer on these triggers:**
- Judge returns `converged` — terminal convergence, produce the final deliverable
- User invokes ABORT at a checkpoint — user wants whatever we have, Deliverer produces best-available with explicit "unresolved" framing
- User explicitly asks for the final output ("give me the top-5 now", "deliver", "what's the answer")
- User runs `/thales-deliver` (if added to commands)

**Deliverer brief must include:**
1. The task's acceptance criteria from `task.md`, verbatim
2. An enumeration of every file in `_scratch/thales/` — Deliverer reads all of them
3. Anti-blandness directive specific to Deliverer (see `agents/thales-deliverer.md`)

**Orchestrator's job after Deliverer returns:**
- Write a brief covering note (2-3 sentences max) stating: cycle count, branch count, phase at delivery, any salient caveat (e.g., "Delivered on ABORT with 2 branches unresolved")
- Present Deliverer's output verbatim below the covering note
- Do NOT paraphrase, summarize, truncate, or re-format the Deliverer output
- Do NOT add your own analysis or framing around it
- Do NOT ask the user if they want a shorter version unless they ask first

The covering note header format:

```
## Thales delivery — cycle N
<2-3 sentence orchestrator note: cycle count, phase, branches, caveats>

---

<Deliverer output verbatim>
```

## Examples

**Research-style opener.** User: "Use Thales: find out whether chemistry-inspired gates generalize beyond VQE to quantum optimization."

Cycle 1 plan: spawn Prober (deep into existing VQE evidence in the task), spawn Bridger (find cross-domain analog — look outside quantum for "structure-aware parameterization" patterns). Skip Challenger cycle 1 — nothing to challenge yet. Write plan to ledger.

Cycle 1 collect: Prober returns with two sub-hypotheses and confidence: med. Bridger returns with structural mapping to equivariant neural nets. Both written to `branches/branch-1.md` and `branches/branch-2.md`.

Cycle 2: Prober on branch-1, Prober on branch-2. Cycle 3: Judge. Judge says `exploring, no leading direction yet, recommend Challenger on branch-2`. Cycle 4: Challenger on branch-2. Branch-2 survives. Phase stays `explore` until Judge at cycle 6 names a leader.

**Coding-style opener.** User: "Use Thales: I've tried three times to get the PennyLane qml.trotterize fix landing and the test suite won't pass."

Cycle 1: Prober (read failing tests + recent attempts in git log, propose specific root cause hypothesis), Challenger (attack the user's implicit assumption that the bug is in `_recursive_qfunc`). Skip Bridger — coding bug. Cycle 1 returns two candidate root causes; write to branches.

Cycle 2: Prober on the higher-confidence branch, Critic on the lower-confidence branch. Cycle 3: Judge. If Judge says `converging on branch-1`, transition to exploit and start implementing the fix.

Same state machine, different spawn mix. That's the design point.

## See also

- `references/state_machine.md` — detailed transition tables (load on ambiguous transition)
- `references/ledger_format.md` — file schemas with examples (load at session init)
- `references/spawn_discipline.md` — brief construction edge cases (load when brief is non-trivial)
- `references/troubleshooting.md` — known failure modes (load after any rejection or integrity warning)
