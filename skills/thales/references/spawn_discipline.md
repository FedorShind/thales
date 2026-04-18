# Thales Spawn Discipline — Edge Cases

This reference is loaded on demand when brief construction is non-trivial or a spawn decision is ambiguous. SKILL.md's four-component brief rule handles standard cases.

## Brief construction — hard cases

### Target branch file is huge

When a target `branches/branch-N.md` has grown past ~3000 words, including it verbatim drowns the subagent's focus. Do NOT summarize — summarization is the blandness enabler.

**Protocol:**
1. Identify the specific cycles and sections relevant to the sub-question
2. In the brief, say: "Read `branches/branch-N.md` sections `Cycle K+2` through `Cycle K+5` and the `Current confidence` field verbatim. Ignore earlier cycles unless a specific term from your sub-question appears in them."
3. Name the specific terms to grep for if the subagent needs to pull earlier context
4. Never instruct the subagent to "read the summary" — there shouldn't be one, and if there is, it's an artifact the subagent should ignore

### Reviver brief when original ruling reasoning is gone

When spawning Reviver for an entry in `dead_ends.md` or `ruled_out.md` whose original detailed reasoning was in a branch that has been archived and you can't quickly locate the full reasoning trail:

**Protocol:**
1. Do NOT attempt to reconstruct the original reasoning
2. In the brief, quote the dead_ends/ruled_out entry verbatim
3. Explicitly say: "The original full reasoning for this ruling is not retrievable. Work from the entry as-stated. If the entry is too terse to evaluate, return REAFFIRM_WITH_CAVEAT and explain what information would be needed to properly revisit."
4. This is a legitimate Reviver outcome — don't force a FLIP or REAFFIRM when the input is insufficient

### Parallel briefs with overlap

Two briefs for same-cycle parallel spawns share significant scope. Example: Prober on branch-1 and Challenger on branch-1 in the same cycle.

**Test:** would the two subagents produce meaningfully different outputs if given the same brief minus their role directive? If no, they're redundant — serialize across cycles.

**Protocol when genuinely non-redundant but overlapping:**
1. Brief each with a sharply divergent sub-question (Prober: "Stake a claim about X"; Challenger: "Find what kills the existing claim about X")
2. Do NOT tell either about the other's spawn. Parallel spawns must not anticipate each other's output — that's Synthesizer's job next cycle
3. After collect, Synthesizer gets both outputs as input

### No new material to brief

When planning a cycle, you find that every candidate spawn has no new ledger content to consume beyond what was available last cycle. This means the investigation is not generating new questions.

**Protocol:**
1. Do NOT spawn redundant Explorers
2. Skip to Judge invocation regardless of cycle mod 3 — this is a genuine stall signal
3. Judge verdict will likely be `stalled` or `needs_human` — follow the checkpoint protocol

## Parallel vs. serial decisions

### Orthogonality test

Before scheduling two Explorers in the same cycle, ask: if Explorer A discovers X mid-run, does that change what Explorer B should investigate? If yes, they must be serial.

**Orthogonal (parallel OK):**
- Prober on branch-1 + Bridger seeking cross-domain analog (Bridger doesn't read branches; can't collide)
- Prober on branch-1 + Prober on branch-2 (different targets)
- Critic on recent ledger + Explorer on a specific branch (Critic reads ledger; Explorer reads branch; different scope)

**Not orthogonal (must be serial):**
- Two Probers on the same branch
- Challenger on branch-1 + Synthesizer merging branch-1 with branch-2 (Synthesizer should not synthesize before Challenger attacks)
- Bridger + Reviver on related dead-end (Bridger's output might obviate Reviver; run Bridger first, decide next cycle)

### Max parallelism

Hard ceiling: 3 subagents per cycle. This is not a soft limit. Reasons:
1. Context management — 3 parallel subagent outputs plus orchestrator ledger reads approaches context limits
2. Synthesis difficulty — merging 4+ outputs reliably is beyond Synthesizer's clean operating range
3. Diminishing returns — marginal fourth Explorer rarely changes the cycle verdict; cost > value

If the decision tree selects 4+ spawns, drop lowest-priority. Priority order in explore: Bridger > Prober > Challenger > Reviver > Critic > Synthesizer > Judge. Priority order in exploit: Prober > Challenger > Critic > Judge > Synthesizer > Reviver > Bridger.

## When NOT to spawn — negative rules

### Don't spawn Bridger when:
- Phase = exploit and leading direction is stable (Bridger introduces noise that pulls out of exploit prematurely)
- Task is a specific coding bug with a verifiable fix (analogy is rarely load-bearing for bug fixes)
- Last 2 cycles had Bridgers return `disanalogies` strong enough to invalidate the bridge (domain space is saturated)
- Time pressure is high (Bridger is the most exploratory, least productive-per-cycle)

### Don't spawn Reviver when:
- The dead_end was ruled out for structural reasons (e.g., "this violates conservation of X") — new context won't change physics
- The entry was just added in the last 2 cycles (give it time)
- The user has explicitly abandoned this thread via PRUNE

### Don't spawn Critic when:
- Ledger has fewer than 2 cycles of substantive content (nothing to critique)
- Last Critic returned "no significant flaws" (diminishing returns)
- The current cycle's findings aren't even stable yet (wait until Synthesizer or Judge has processed)

### Don't spawn Judge when (violating the mod-3 rule):
- User explicitly asked for a checkpoint next (`/thales-checkpoint`) — checkpoint uses a different mechanism
- Previous Judge verdict was less than 1 cycle ago (early Judge already happened)
- You're in state `rehydrate` or `terminal_*`

## The "would this spawn change the ledger meaningfully?" test

Before every spawn, articulate to yourself (in the ledger plan):

1. What specific ledger mutation do I expect from this spawn?
2. If the subagent returns exactly what I expect, what would I do differently next cycle?
3. If the subagent returns the opposite of what I expect, what would I do differently next cycle?

If answers to 2 and 3 are the same, the spawn is wasted — you're not learning. Restructure the brief until (2) and (3) diverge. If you can't, skip the spawn and use the cycle for Judge or checkpoint.
