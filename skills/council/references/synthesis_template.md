# Synthesis template — /council

Copy to `<run folder>/0_synthesis.md`. Keep it under about 100 lines. Plain English, answer first.

```markdown
# Synthesis — <topic> (<YYYY-MM-DD>)

<N> blind lenses (files 1-<N> in this folder) read `brief.md`.
This file is the orchestrator's judgment.

## 1. The answer
<2-4 sentences: the one combined recommendation, answering the brief's Purpose.>

## 2. Agreements (≥2 lenses, found independently)
| ID | Finding | Lenses | Evidence |
|---|---|---|---|
| F-01 | <finding> | <lens, lens> | <file:line or source> |

## 3. Conflicts and decisions
| ID | Conflict (claim A vs claim B) | Decision | Why |
|---|---|---|---|
| F-05 | <lens X says ...; lens Y says ...> | <decision> | <stronger evidence / user's own data / user's priority> |

## 4. Dropped claims
| Claim | Lens | Reason (wrong + evidence / unverified / out of scope / argues a user decision) |
|---|---|---|

## 5. The plan
| # | Action | When | Done when |
|---|---|---|---|
| 1 | <action> | <time or date> | <observable measure> |

First action (next 24 h): <one action>

## 6. Open questions (only the user can answer)
1. <question> — Recommended: <your answer>

## 7. Run notes
- Lenses: <N> spawned, <N> re-spawned as hollow, <N> failed.
- Verifier: <run, verdict> or <skipped: low stakes>.
```

## Verifier prompt (Step 5, optional)

```text
Your job is to prove this synthesis WRONG. Start from the position that it is wrong.
A point in the synthesis stands only if you find evidence for it
(a file and line, a command and its output, or a cited source).

BRIEF: <run folder>/brief.md
LENS REPORTS: <run folder>/1_*.md ... <N>_*.md
SYNTHESIS: <run folder>/0_synthesis.md
Do not edit any file. Return your report as your final message, at most 40 lines:

1. WRONG DECISIONS — each conflict decision the evidence does not support, with evidence.
2. UNSUPPORTED PLAN ITEMS — each plan action that rests on an unverified or wrong claim.
3. WRONGLY DROPPED — each dropped claim that the evidence actually supports.
4. MISSED — important points that no lens and no synthesis section names.
5. VERDICT — ACCEPT only if sections 1-3 are empty. Otherwise REJECT, with the reasons.
6. FILES READ — every file you opened, one per line.
```
