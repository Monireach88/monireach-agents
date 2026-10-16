---
name: log-learning
description: Use this skill when the user invokes "/log-learning", or when auto-triggered after /log-mistake, /log-error, /capture-learning, or /concept-unblock. Proposes a draft entry for daily_learnings.md based on what was just learned, then waits for confirmation before writing.
version: 1.0.0
---

# Log Learning

Propose one entry for `daily_learnings.md` based on what was just learned or done. **Wait for "yes" before writing anything.**

---

## File

```
/Users/monireach/Google Drive/My Drive/monireach/deliverables/daily_learnings.md
```

---

## Entry Format

```markdown
### [Category] — [Short title]
- **What:** one sentence — the rule or concept
- **Why:** when to apply it / why it matters
- **Example:** [simple concept → one line | abstract or code-related → short code block or 2–3 lines, no ambiguous info]
- **Say it:** one natural English sentence — how you'd describe this concept out loud to a colleague or interviewer
- **Defend it:** "I did X because Y" — the justification you give when someone asks why you made this choice
- **Ref:** (optional) `path/to/file.md` § Section Heading — omit if no knowledge file was written for this entry
```

**Categories** (use existing; add new if needed):
`SQLAlchemy` `FastAPI` `Python` `Docker` `Alembic` `Testing` `Git` `Frontend` `ML` `DevOps` `Workflow` `Security`

**Special category — `Pattern`:**
- Use ONLY for coding/programming patterns (not English, communication, or other domains)
- Has its own entry format and writes to a different file — see "Pattern Category" section below
- Still proposes and waits for confirmation before writing anything

---

## Steps

### Step 1: Extract the learning

Based on what triggered this skill:

| Triggered by | What to extract |
|---|---|
| `/log-mistake` | The underlying rule/concept that *prevents* the mistake — not the mistake itself |
| `/log-error` | The `**Learned:**` field from the entry just logged |
| `/capture-learning` | Distill the atomic concept(s) just documented into the short format |
| `/concept-unblock` | The compressed one-sentence rule produced in Phase 2 Rule 7 |
| Standalone | Read the current conversation — extract what was explained or figured out |

---

### Step 2: Draft the entry

Write a draft using the Entry Format above. Pick the most fitting category.

**Example field rules:**
- Simple concept (e.g. a flag, a method name) → one line
- Abstract or code-related → short code block or 2–3 lines; no ambiguous info that would require a follow-up question

**Say it field rules:**
- Write as natural spoken English — the sentence Monireach can say out loud in a conversation or interview
- Not a technical note. Model the cadence of a real explanation: "X means that...", "X is the idea that...", "When you see X, it means..."
- If concept-unblock already produced a "describe it" phrase, use it here directly

**Defend it field rules:**
- Must follow the pattern: "I did/used/added X because Y" or "Without X, Y would happen"
- Y must be a concrete consequence — not "it's good practice" or "it's important"
- If concept-unblock already produced a "defend it" phrase, use it here directly

---

### Step 3: Propose and wait

Present a compact summary and ask:

```
Log to daily_learnings.md?
- [Category] — [Short title]: [one-line What]
→ yes / skip
```

For multiple entries, list them all before asking:

```
Log to daily_learnings.md?
1. [Category] — [Short title]: [one-line What]
2. [Category] — [Short title]: [one-line What]
→ yes / skip
```

**WAIT for response. Do not write until confirmed.**

---

### Step 4: Write or discard

- `yes` (or any affirmation) → write (see routing rules below)
- `skip` (or any rejection) → discard silently, no output

**Routing rules by category:**

**Standard categories** (everything except `Pattern`):
1. Read the last 50 lines of `daily_learnings.md` to find today's date (YYYY-MM-DD)
2. If today's section exists → append the entry under it
3. If today's section does not exist → create `## YYYY-MM-DD` first, then append
4. Never rewrite existing entries. Append only.

**`Pattern` category:**
1. Write the full pattern entry to `coding_patterns.md` (see "Pattern Category" section)
2. Write a brief cross-reference line to `daily_learnings.md` under today's date:
   ```
   ### Pattern — [Pattern Name]
   → New pattern logged in `coding_patterns.md`: [one-line what it is]
   ```
3. Update the Table of Contents in `coding_patterns.md` with the new entry

---

### Step 5: Confirm (only if written)

State the entry title added. One line. No other output.

---

---

## Pattern Category

**Only use this for coding/programming patterns. Never for English, communication, workflow, or other domains.**

### Files

```
/Users/monireach/Google Drive/My Drive/monireach/deliverables/software_ai_engineering/coding_patterns.md
```

### Entry Format (written to coding_patterns.md)

```markdown
### [Pattern Name]
- **What it is:** one sentence — what problem this pattern solves
- **Standard structure:** the 3–5 functions/components every implementation has
- **Real example:** which file/task in your projects used this pattern
- **Recognize it when:** the requirement says ___ or the system needs to ___
- **Say it:** one natural sentence — how you'd name this pattern in an interview
```

### Appending rules for coding_patterns.md

1. Read the ToC at the top to check if this pattern is already logged
2. If already logged → skip (do not duplicate)
3. If new → append the full entry at the end of the file
4. Update the Table of Contents: add `- [Pattern Name](#anchor) — one-line description`

### Cross-reference line for daily_learnings.md

```markdown
### Pattern — [Pattern Name]
→ New pattern logged in `coding_patterns.md`: [one-line what it is]
```

---

## Anti-Patterns to Avoid

- Never write without waiting for "yes" — propose first, always
- Never copy the mistake or error verbatim — extract the reusable rule behind it
- Never skip the **Example** field — it is the memory anchor
- Never skip the **Say it** field — it is the speaking anchor; knowledge without words is silent
- Never skip the **Defend it** field — it is the critical thinking anchor; being able to justify a choice is what separates a learner from an engineer
- Never write "Say it" as a technical note — it must be speakable natural English
- Never write "Defend it" as "it's best practice" or "it's important" — always name a concrete consequence
- Never merge two distinct learnings into one entry
- Never log something already captured under today's section
