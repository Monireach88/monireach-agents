---
name: capture-learning
description: Use this skill when the user invokes "/capture-learning". Documents concepts learned in the current conversation into the deliverables knowledge base. Uses parallel sub-agents to keep the main context lean.
version: 3.1.0
---

# Capture Learning

Document only what actually blocked Monireach — not what he already knew.

Uses sub-agents for all heavy work. Main context stays lean throughout.

---

## Step 0: Extract Conversation Summary (Main Context)

Before spawning anything, extract a compact summary from the current conversation. Cap at **300 words**.

Extract:
- What was Monireach trying to build or understand?
- Which specific questions/statements showed a blocker? (use exact quotes)
- What was the broken assumption behind each blocker?
- What resolved each blocker?
- Any careless mistakes made (wrong API, wrong type, wrong mental model)?

This summary is the only context passed to sub-agents. Do NOT pass the raw conversation.

---

## Step 1: Spawn Sub-Agents A and B in Parallel

Launch both in a single message.

---

### Sub-Agent A — Analyze + Propose (no writes)

**Type:** general-purpose

**Pass in prompt:**
- The conversation summary from Step 0
- This skill's file path (so it can read format specs): `[agent_core]/skills/capture-learning/SKILL.md`
- Deliverables directory: `/Users/monireach/Library/CloudStorage/GoogleDrive-sebastian.tang168@gmail.com/My Drive/monireach/deliverables`

**Instructions to include in prompt:**

```
You are analyzing a learning session. Do NOT write anything to disk.

1. Run: find "[deliverables_dir]" -name "*.md" | sort
2. Identify candidate files by filename match to the topics in the summary.
3. For each candidate: read only the first 30 lines (ToC). If a heading matches → read that section only (offset/limit). Never read a full file.
4. Break the summary into atomic concepts. One concept = one standalone idea.
   - Atomic: single clear topic, self-contained, could have its own heading
   - Not atomic: "how X and Y work together"
5. For each concept, read the format decision rules in the capture-learning SKILL.md (Format Decision Rules section) and select: 2-Section, Question-Chain, or Both.
6. Return a numbered proposal list only. Format:
   1. "Concept title"
      → FILE: path/to/file.md — NEW SECTION / UPDATE EXISTING (§ heading name if updating)
      → FORMAT: 2-Section / Question-Chain / Both
      → REASON: one line from conversation signals

If no qualifying learnings found → return exactly: "No qualifying learnings found."
```

**Expected return:** numbered proposal list only. No file writes.

---

### Sub-Agent B — Log Mistakes (writes immediately)

**Type:** general-purpose

**Pass in prompt:**
- The conversation summary from Step 0
- Log-mistake skill path: `[agent_core]/skills/log-mistake/SKILL.md`
- Target file: `/Users/monireach/Library/CloudStorage/GoogleDrive-sebastian.tang168@gmail.com/My Drive/monireach/deliverables/my_mistakes.md`

**Instructions to include in prompt:**

```
Read the log-mistake SKILL.md and follow Steps 1–4 only.
SKIP Step 5 (do not run log-learning — confirmation is not possible inside a sub-agent).
Use the conversation summary as your source — do not ask for the full conversation.
Return: each sentence logged (or "No qualifying mistakes found").
```

**Expected return:** list of logged sentences, or "No qualifying mistakes found."

---

## Step 2: Present + Confirm (Main Context)

After both sub-agents complete, apply the following guard first:

**Empty result handling:**
- Both A and B empty → state "Nothing to capture from this session." and exit
- A empty, B logged mistakes → show B's result only, state "No concepts to document." and exit
- A has concepts, B empty → proceed normally (show "No qualifying mistakes found." inline)

**Concept cap — if Sub-Agent A proposed > 4 concepts:**

Present the full list but ask Monireach to select:

```
Mistakes logged:
[Sub-Agent B's output]

Proposed concepts (6 found — select up to 4 to document now):
[Sub-Agent A's numbered list]

Which to document? (e.g. "1 3 4" or "all")
Remaining concepts will be listed at the end — run /capture-learning again for them.
```

**If ≤ 4 concepts**, present normally:

```
Mistakes logged:
[Sub-Agent B's output]

Proposed concepts:
[Sub-Agent A's numbered list]

Proceed?
  → Yes
  → No
  → Chat About This
```

**WAIT for response. Do not proceed until confirmed.**

**If Monireach says "Chat About This":**
Discuss freely. When the conversation reaches a resolution, apply any agreed changes to the proposal inline (add/remove/move concepts, change format, change target file). Then re-present the updated proposal and ask:
```
Updated proposal:
[revised numbered list]

Proceed?
  → Yes
  → No
```
Do NOT re-spawn Sub-Agents A or B. Reuse their existing outputs.

---

## Step 3: Spawn Sub-Agent C — Write Documentation

**Type:** general-purpose

**Pass in prompt:**
- The conversation summary from Step 0
- Sub-Agent A's full proposal (file paths, formats, concept titles, reasons)
- This skill's file path for format specs: `[agent_core]/skills/capture-learning/SKILL.md`

**Instructions to include in prompt:**

```
Read the documentation formats from the capture-learning SKILL.md (Format A, Format B, Format C, Universal Rules).

For each concept in the proposal:
1. Read the target file's ToC (first 30 lines). If the section exists → read it before writing. If not → plan to append + update ToC.
2. Write the concept using the selected format.
3. Update the file's ToC after each write.
4. State "Written: [file path]" after each file. One file at a time.

After all docs written, draft the log-learning entries:
- For each concept documented, produce a draft entry using the log-learning format.
- Read the log-learning SKILL.md at: [agent_core]/skills/log-learning/SKILL.md for the exact format.
- Populate the **Ref:** field with the exact file path (relative to deliverables/) and section heading just written (e.g. `software_ai_engineering/python_notes.md` § Python Context Managers).
- Do NOT write to daily_learnings.md — return the draft entries only.

After all writes, verify each concept:
- Re-read the section just written in each file
- Check: correct format? ToC updated? "What blocked me" present and quoted? Section 2 mirrors Section 1?
- If any issue found → fix it before returning
- Do NOT report issues back — just fix silently and confirm clean

Return:
1. One-line confirmation per concept: "✓ [Concept title] — [format] — appended to [filename]"
2. Draft log-learning entries (formatted, ready to paste)
```

**Expected return:** files written + draft log-learning entries.

---

## Step 4: Log-Learning Confirmation (Main Context)

Present Sub-Agent C's draft entries:

```
Add to daily_learnings.md?
1. [Category] — [Short title]: [one-line What]
2. [Category] — [Short title]: [one-line What]
→ yes / skip
```

**WAIT for response.**

- `yes` → append confirmed entries to `daily_learnings.md` directly (main context — it's a simple append)
- `skip` → discard silently

When appending:
1. Read last 50 lines of `daily_learnings.md` to find today's date section
2. If exists → append under it
3. If not → create `## YYYY-MM-DD` header first, then append

---

## Path Reference

```
agent_core:   /Users/monireach/Library/CloudStorage/GoogleDrive-sebastian.tang168@gmail.com/My Drive/monireach/resources/agent_core
deliverables: /Users/monireach/Library/CloudStorage/GoogleDrive-sebastian.tang168@gmail.com/My Drive/monireach/deliverables
```

---

## Format Decision Rules

| Signal in the conversation | Format to use |
|---|---|
| Blocker was "what is X" or "how does X work" | **2-Section Format** |
| Blocker was "where do I start" or "how do I approach" | **Question-Chain Format** |
| Both blockers present | **Both formats** in the same concept entry |

Do NOT ask Monireach which format to use. Read the signals, decide, then propose.

---

### Format A: The 2-Section Format

Use when: the blocker was **what X is** or **how X works** — a concept/API/pattern.

```markdown
## [Concept Title]

> **What blocked me:**
> - "exact quote or question that caused the blocker"

---

### Section 1: Quick Reference

[Short. Formula only. No explanations. Linked to prior knowledge.]

- A: `code example`           # link to known concept (e.g., SQL equivalent)
  - A.1: `code variant`
  - A.2: `code variant`
- B: `code example`
- C: `code example`

---

### Section 2: Comprehensive Explanation

[Same exact structure as Section 1. Same order. Same subsections. Never skip.]

#### A: [label]
Full explanation. Cause-chain if multi-step. Analogy if helpful.

##### A.1: [label]
...

##### A.2: [label]
...

#### B: [label]
...

#### C: [label]
...
```

**Rules for 2-Section Format:**
- "What blocked me" goes first — always above Section 1
- Section 1 = formula only (no explanations, just the pattern/code)
- Section 2 must mirror Section 1 exactly — same items, same order, same subsections
- Use cause-chains for multi-step processes in Section 2: `Step 1 → Step 2 because of Step 1 → Step 3`

---

### Format B: The Question-Chain Format

Use when: the blocker was **where to start** or **how to approach** something unfamiliar.

```markdown
## [Concept Title]

> **What blocked me:**
> - "exact quote showing the approach blocker — e.g. 'I always struggle, I don't know what to do'"

---

### Section 1: Quick Reference

Decision chain — ask these questions in order:

- **A: [First question — the goal]** → [answer]
- **B: [Next question — first constraint]** → [answer]
- **C: [Next question — what does X require?]** → [answer]
  ```python
  # code example if needed
  ```
- **D: [Next question — how to satisfy the constraint?]** → [answer]
  ```python
  # code example if needed
  ```
- **E: [Final question — how to use it?]** → [answer]
  ```python
  # code example
  ```

---

### Section 2: Comprehensive Explanation

#### A: [First question restated as a heading]
Full explanation of why this question matters and what the answer reveals.

#### B: [Second question restated as a heading]
...

#### C: [Third question restated as a heading]
...

[Continue mirroring Section 1 exactly — same questions, same order]
```

**Rules for Question-Chain Format:**
- Each question in Section 1 must be answerable without reading the next question
- Questions follow a discovery chain — each answer triggers the next question
- Section 2 mirrors Section 1 exactly — same questions as headings, same order
- "What blocked me" goes first — always above Section 1
- Common mistakes (wrong turns in the chain) go at the END of the last Section 2 entry

---

### Format C: Both Formats

Use when: the concept is high-complexity and Monireach had both a "what is X" blocker AND a "where do I start" blocker.

Write the Question-Chain Format first (the approach), then the 2-Section Format (the concept detail) as a sub-section within the same concept entry.

---

### Universal Rules (apply to all formats)

- **Rule: One file write at a time.** After writing each file, state: "Written: [file path]". Then move to the next.
- **Rule: "What blocked me" always first.** Use exact quotes from the conversation.
- **Rule: Never document what Monireach already knew.** Only blockers.
- **Rule: Never pad with background** that wasn't a blocker.
- **Rule: Never merge two distinct blockers** into one section.
- **Rule: All knowledge files must have a Table of Contents.** If the target file has no ToC, create one before writing the new section. Always update the ToC after adding a section.
- **Rule: Never read a full knowledge file.** Read ToC first, then only the relevant sections.

---

## Anti-Patterns to Avoid

- Never write without proposing placement, format, and getting confirmation first
- Never create a new file if the concept fits cleanly into an existing one
- Never omit "What blocked me" — it's the reason the doc exists
- Never put explanations in Section 1 of either format — it must stay formula/chain only
- Never let Section 2 diverge in structure from Section 1 — mirror it exactly
- Never reorder concepts between sections
- Never decide the format without reading the conversation signals — don't guess or ask; read and decide, then confirm
- Never document what Monireach already understood before the session
- Never read a full knowledge file — always ToC first, then targeted sections only
- Never pass the raw conversation to a sub-agent — always summarize first (Step 0)
- Never spawn Sub-Agent C before confirmation (Step 2)
- Never let Sub-Agent B run log-learning — that step belongs to main context (Step 4)
