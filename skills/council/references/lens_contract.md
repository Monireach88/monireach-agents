# Lens prompt and output contract — /council

## Lens prompt (fill the `<...>`; add nothing else)

```text
You have one job. Do it using only the inputs listed below.

YOUR LENS: <lens name>
TASK: <Task, verbatim from the brief>
PASS WHEN: <Pass when, verbatim>

INPUTS (read-only): <paths from the brief>
CONFIRMED FACTS: <from the brief>
USER DECISIONS — DO NOT ARGUE: <from the brief>
YOU MUST NOT READ: <run folder path>, <any other excluded path>

Do not edit or create any file. Return your report as your final message.

<Output contract below, verbatim>
```

## Output contract (paste verbatim into the brief and every lens prompt)

```text
Write in plain English: one idea per sentence, 25 words or fewer, no idioms, no slang.
Return at most 40 lines, in exactly these sections:

1. DIAGNOSIS — the 3 most important truths from your lens. Each has evidence:
   a quote with file:line, a command and its output, or a cited source.
2. WORK DONE — what you built, traced or counted, and the size of the set
   you checked (e.g. "traced 14 of 14 claims"). Zero findings is fine
   when the checked set is stated.
3. DISAGREEMENTS — where the user's own belief or the artifact is wrong,
   with evidence. Skip anything listed under "User decisions — do not argue".
4. RECOMMENDATIONS — at most 5, ranked. Each one is concrete:
   what, when, how much time or effort, and how to measure it ("done when").
5. FIRST ACTION — the single thing to do in the next 24 hours.
6. PASS-WHEN RESULT — MET or NOT MET, with the count that decides it.
7. FILES READ — every file you opened, one per line.

Cite sources for every claim you rely on. Mark every claim you could not
verify as "(unverified)". Never present an unverified claim as fact.
Give one recommendation per problem, not a menu of options.
```
