---
name: log-mistake
description: Use this skill when the user invokes "/log-mistake" or calls out a mistake they made. Logs one or more careless mistakes to my_mistakes.md immediately, one sentence per mistake.
version: 1.0.0
---

# Log Mistake

Immediately log one or more careless mistakes to my_mistakes.md.

---

## File

```
/Users/monireach/Google Drive/My Drive/monireach/deliverables/my_mistakes.md
```

---

## Steps

### Step 1: Identify the mistakes

Read the current conversation to find all mistakes that were just made or called out.

**Filter — only log mistakes that meet ALL of these:**
- Reveal a **knowledge gap** (wrong API, wrong type, wrong concept, wrong mental model)
- Are **AI Engineering / software business relevant** (would matter on a real project, in a code review, or in a job interview)
- Were made by **Monireach**, not Agent

**DO NOT log:**
- Pure typos with no conceptual error behind them (e.g. `vi` instead of `v1` once)
- Naming/style slips that don't reveal a misunderstanding
- Mistakes already logged under today's date in `my_mistakes.md`
- Trivial copy-paste errors

For each qualifying mistake, extract:
- What was wrong (the specific error)
- What the correct behavior is

### Step 2: Write one sentence per mistake

Format: `- [What was wrong] — [correct behavior].`

Rules:
- One sentence only
- Concrete and specific — no vague generalities
- Past tense for the mistake, present tense for the correction
- The correction must be phrased as natural spoken English — something Monireach could say out loud to explain what he learned, not just a technical note
- Match the style of existing entries in the file

Examples of good entries:
- `- Used wrong HTTP status code 201 for GET endpoints — 201 means Created, so a successful GET should return 200.`
- `- Passed a list to db.refresh() — it takes a single ORM object, not a list; call it once per object in a loop.`

### Step 3: Append to the file

1. Read the file to find today's date section (YYYY-MM-DD)
2. If today's date section exists → append the new entry under it
3. If today's date section does not exist → create it first, then append

Never rewrite existing entries. Append only.

### Step 4: Confirm

State each sentence added, one per line. No other output.

### Step 5: Offer daily learning log

Run `/log-learning` — it will extract the reusable rule behind the mistake, propose a draft entry, and wait for "yes" / "skip".
