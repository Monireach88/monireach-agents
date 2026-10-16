---
name: queue-context
description: Use this skill when the user invokes "/queue-context" or wants to quickly log a context for an agent skill to consume it later.
version: 1.0.0
---

# Queue Context

Writes context to `skill_queue.md` for execution in a dedicated skill session.
**The invoking agent (main session) prepares and passes the context. Sub-agents handle file operations only — they never extract context from the conversation.**
**Always uses a sub-agent for all file operations.**

---

## Fixed File

```
/Users/monireach/Google Drive/My Drive/monireach/resources/agent_core/skill_queue.md
```

---

## Steps

### Step 1: Check file via sub-agent

Spawn a sub-agent with this instruction:

```
Read the file at:
/Users/monireach/Google Drive/My Drive/monireach/resources/agent_core/skill_queue.md

Return exactly one of:
- "EMPTY" if the file has no content
- "HAS_CONTENT" followed by the full file contents
```

### Step 2: Handle existing content

- If sub-agent returns `EMPTY` → proceed to Step 3
- If sub-agent returns `HAS_CONTENT` → ask:

```
skill_queue.md has unprocessed content. Has it been processed in your skill session? Safe to clear? (yes / no)
```

**WAIT for response.**

- `yes` → proceed to Step 3
- `no` → stop. State: "Come back when the current context has been processed."

### Step 3: Write context via sub-agent

Spawn a sub-agent with this instruction:

```
Write the following content to this file (overwrite completely):
/Users/monireach/Google Drive/My Drive/monireach/resources/agent_core/skill_queue.md

[skill name and context prepared by main session]

Confirm with: "Written."
```

### Step 4: Confirm

State: "Context queued in skill_queue.md — ready for your skill session. Clear the file manually when done, or I will ask next time."

---

## File Format

```
Skill: [skill-name]
Context:
[free-form plain text — what happened, what was learned, enough detail for the skill session to work with]
```

---

## Rules

- ALWAYS spawn a sub-agent for file reads and writes — never read or write the file directly in main context
- Never proceed past Step 2 without user confirmation if file has content
- Context is free-form plain text — no formatting required; the skill session applies its own format
