---
name: log-error
description: Use this skill when the user invokes "/log-error". Logs a debugging investigation — errors that required diagnosis, multiple attempts, and a non-obvious fix — into the project's docs/error_log.md AND adds a one-liner row to the global error_log_index.md. Different from /log-mistake (one-liners for careless errors). This is for investigations worth remembering.
version: 2.0.0
---

# Log Error

Log one or more debugging investigations into the project-specific error log and the global index.

**This is NOT `/log-mistake`.** Use this skill when:
- The error required investigation (docker logs, route inspection, devtools, etc.)
- Multiple approaches were tried before finding the fix
- The root cause was non-obvious

Use `/log-mistake` for careless one-liners (typos, wrong parameter, wrong method).

---

## Files

**Project error log** (entries go here):
```
{project_root}/docs/error_log.md
```

**Global index** (one-liner row goes here):
```
/Users/monireach/Library/CloudStorage/GoogleDrive-sebastian.tang168@gmail.com/My Drive/monireach/deliverables/software_ai_engineering/error_log_index.md
```

---

## Entry Format (project error log)

```markdown
### [Short error title]

**Date:** YYYY-MM-DD
**Context:** [file, component, or task where the error occurred]
**Tags:** `keyword1` `keyword2` `keyword3`

**Error:** [what was observed — error message, status code, or behavior]

**Tried & Failed:**
- [approach 1] — [why it didn't work]
- [approach 2] — [why it didn't work]

**Solution:** [what actually fixed it]

**Learned:** [root cause — the rule or mental model that prevents this next time]
```

---

## Index Row Format (global index)

```markdown
| YYYY-MM-DD | [one-line error description] | [project name] | `[project]/docs/error_log.md` → [Category] |
```

---

## Categories (top-level sections in project error log)

```
## FastAPI Routing
## FastAPI Testing
## Docker & Environment
## Database (SQLAlchemy)
## Frontend Build
## Python General
```

If an error doesn't fit any category, add a new `## [Category]` section.

---

## Entry Paths

### Path A — Explicit invoke with a pasted error (low bar)

When the user invokes `/log-error` and pastes a specific error directly, **skip the worthiness gate** and log it immediately. No assessment needed.

- `Tried & Failed` → use `(could not solve independently — solved with AI assistance)` if no failed attempts were made
- Still fill in all other fields: Context, Tags, Solution, Learned
- This path exists because errors the user couldn't solve alone have value for future reference, even if they didn't require many attempts

### Path B — End-of-session scan (strict gate)

When the skill is invoked without a pasted error (e.g., at end of session to scan the conversation), apply the full worthiness criteria:
- Had a non-obvious root cause
- Required multiple steps to diagnose
- Are worth an AI agent or future-Monireach knowing about

Skip careless one-liners in both paths — those go in `/log-mistake`.

---

## Steps

### Step 1: Determine the entry path

- If the user pasted a specific error with the invocation → **Path A** (log it, no gate)
- If the user invoked without a specific error → **Path B** (scan conversation, apply strict criteria)

### Step 2: Identify errors to log

**Path A:** Use the pasted error directly.

**Path B:** Read the current conversation and find all debugging investigations — errors that:
- Had a non-obvious root cause
- Required multiple steps to diagnose
- Are worth an AI agent or future-Monireach knowing about

Skip careless one-liners — those go in `/log-mistake`.

### Step 3: Categorize each error

Assign each error to one of the existing categories. If none fits, create a new one.

### Step 4: Write to the project error log

1. Read `{project_root}/docs/error_log.md` to find the correct category section
2. Append the new entry under the matching `## [Category]` heading
3. If the category doesn't exist yet, add it as a new `## [Category]` section at the end (before the final `---`)

Never rewrite existing entries. Append only.

### Step 5: Add row to the global index

1. Read the last few lines of `error_log_index.md` to find the table
2. Append a new row to the table for each entry added

### Step 6: Confirm

State each entry title added, one per line. No other output.

### Step 7: Offer daily learning log

Run `/log-learning` — it will extract the `**Learned:**` field from the entry just logged, propose a draft entry, and wait for "yes" / "skip".

---

## Anti-Patterns to Avoid

- Never log careless one-liners here — use `/log-mistake`
- Never invent "Tried & Failed" steps that didn't happen in the conversation
- Never merge two separate errors into one entry
- Never omit the **Learned** field — it's the most valuable part for future lookup
- Never skip **Tags** — they enable keyword search across categories
- Never forget to update the global index after writing to the project log
