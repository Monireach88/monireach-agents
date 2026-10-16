# §6. User Confirmation Requirements

## §6.1 Git Commits (Mandatory Workflow)

**This is the #1 rule violation. Follow this EXACT workflow:**

1. Make changes to files
2. `git add <files>` to stage
3. Prepare to run git commit
4. **WAIT for user response** - "OK", "yes", "approved", "commit it"

**DO NOT COMMIT ANY CODE WITHOUT THE USER's CONFIRMATION**

**Valid approval phrases (this list is EXHAUSTIVE, case-insensitive):**
- "OK" / "ok" / "okay"
- "yes" / "Yes"
- "approved" / "approve it"
- "commit it" / "go ahead"
- "looks good"

**Anything not on that list is NOT approval.** This explicitly includes: "nice", "thanks", "cool", "got it", "I see", "sure", "whatever you think", silence, and any new unrelated instruction. Praise for the work is not permission to commit the work.

If the reply is ambiguous, ask exactly once: **"Commit? yes/no"**. Never infer approval.

**Exception (skip approval):**
- User says one of the two literal forms: "commit and push without asking me" / "you have permission to commit freely". **"Semantically similar" is not sufficient** — if you believe blanket permission was granted in different words, confirm once in writing: "Confirming: commit freely for this session? yes/no".
- **`/vibe-code` is active** — when the user invokes `/vibe-code` or `$vibe-code`, git commits are automatically pre-approved for the entire session. This is fully autonomous mode. Do NOT pause or ask before committing.
- This exception lasts ONLY for that specific session/task, not forever

---

## §6.2 Other Critical Confirmations

- NEVER push code to any remote repository without user confirmation
- NEVER remove any files or directories without user confirmation
- NEVER run risky or sensitive commands (sudo, rm, database drops, production deployments) without user approval

---

## §6.3 Background Tasks — No Re-Run Rule

**Once a command is running in the background, NEVER run it again until it finishes.**

- If you start a command with `run_in_background: true`, wait for the completion notification before issuing the same or equivalent command again
- Do NOT poll, monitor, or retry the same command while it is still running
- If the output file is missing or empty, that does NOT mean the task failed — it may still be running
- Violating this rule spawns duplicate processes that consume RAM and produce conflicting results

---

## §6.4 Housekeeping Is Mine — Never Hand It to the User (CRITICAL)

**TRIGGER:** before any message that asks the user to check, approve, choose or do something.

```
HOUSEKEEPING = mandatory, done well, and done BY ME, without asking:
  status files, logs, milestone archiving, doc sync, stale docs,
  branch tidying, test runs, format fixes, checklists, cleanup.

THE USER'S TIME IS FOR:
  direction, priorities, product and business decisions,
  native-Khmer judgement, money, and anything only he can know.

Every message that asks him for something leads with the
BIG PICTURE: the goal, where we are, and the next step
that moves the goal. Housekeeping done goes in one line at the end,
or is not mentioned at all.

What to leave out of every report: plain-language.md §1.
```

**This does NOT override §6.1–§6.3.** A commit, a push, a PR, a merge or a deletion still needs his command. "Do as you think is right" is not that command. Housekeeping means local, reversible work. Report it after it is done; never ask about it before.

**TEST:** for each item in the draft that asks him something, ask: could I decide or do this myself from the code, the docs and sensible defaults? If yes, do it and delete the item.

**ON FAIL:** he had to ask "what's the big picture?" to get out of the small tasks. That counts as the violation. Repair it under `core-principles.md` §3.6.
