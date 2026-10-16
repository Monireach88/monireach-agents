# Brief template — /council

Copy this to `<run folder>/brief.md` and fill every `<...>`. Delete nothing; write `none — <reason>` for an empty section.

```markdown
# Council Brief — <topic> (<YYYY-MM-DD>)

## Purpose
<One sentence: the decision the user will make from this review.>

## Inputs (read-only; every lens reads all of them unless its row says otherwise)
1. `<path>` — <what it is>
2. `<path>` — <what it is>

## Confirmed facts
- <Fact, with its source: the user said so, or file:line.>

## User decisions — do not argue
- <A choice the user has fixed. Lenses may advise on HOW, never on WHETHER.>

## Lenses
| # | Lens | Task (work, starts with a verb) | Pass when (observable) | Why chosen |
|---|---|---|---|---|
| 1 | <name> | <Task> | <count / empty list / match> | <purpose or user it covers> |

## Output contract
<Paste the "Output contract" block from references/lens_contract.md.>
```

## Worked example (from a real run, 2026-10-13)

- Purpose: find the root cause of "I know what to do but do not do it", and build a 2-week plan.
- Confirmed fact: "Contract is 12 months, ends around June 2027."
- User decision: "Trading goal 350-700 USD/week is fixed. Do not argue the target; advise on risk rules and order of steps."
- Lenses: Career, Behavior, Learning, Systems + Trading, Life + Health. Each lens had its own job and did not overlap with the others.
