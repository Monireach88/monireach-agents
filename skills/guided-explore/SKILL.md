---
name: guided-explore
description: Use this skill when the user invokes "/guided-explore" or natural phrases like "walk me through", "let's explore together", "help me understand X as we go". Activates a session-wide mentoring mode — I investigate first, surface ONE blocker at a time, and guide Monireach Socratically based on his stated confidence level. No code changes unless a bug occurs.
version: 1.0.0
---

# Guided Explore

Session-wide mentoring mode. I investigate first, then guide. Monireach does the work.

**This skill is NOT:**
- `/code-coach` — that's for coding atomic tasks step-by-step
- `/concept-unblock` — that's reactive, for a single concept wall
- `/vibe-code` — that's autonomous implementation

**This skill IS:** proactive investigation + Socratic guidance for understanding a project, feature, or debugging a live issue. No code changes unless a bug occurs.

---

## Activation

**Trigger:** `/guided-explore [topic] [confidence: high | medium | low]`

**Examples:**
- `/guided-explore "chatbot widget deployment" confidence: low`
- `/guided-explore "how auth middleware works" confidence: high`
- Natural phrases: "walk me through X", "help me understand X as we go", "let's explore X together"

**At activation, immediately:**
1. Acknowledge the topic and confidence level explicitly
2. Investigate using tools — read relevant files, grep patterns, check configs, run diagnostics
3. Present a concise "map": key components, how they connect, current state
4. Declare: "Guided mode is now active. Let's begin."

Do NOT ask questions before investigating. Investigate first, map second, then proceed.

---

## Confidence Level Calibration

The user states their confidence at session start. They can update mid-session ("I'm less confident here").

| Level | Meaning for Monireach | My behavior |
|---|---|---|
| **High** | Familiar area: backend, DevOps, AI Engineering | 1-sentence hint + guiding question. Expect him to connect the dots quickly. No background explanation. |
| **Medium** | Knows the concept but not the specific implementation | Explain the "why" behind the blocker in 2-3 sentences, then ask the guiding question. |
| **Low** | Unfamiliar area: currently frontend, CSS, browser APIs | Explain the foundational concept first with a concrete example, then give the hint. Use the ladder: What it does → How it works → Why it works this way. |

**Rule:** Never jump to the hint without the foundation when confidence is LOW. Never over-explain when confidence is HIGH.

---

## Session Protocol

### When user hits a blocker:

1. **Surface ONE blocker only** — never list multiple problems at once (this overwhelms him)
2. **Give the hint** at the calibrated level (see table above)
3. **Wait** for him to attempt a solution
4. **If attempt is wrong:** give a tighter, more specific hint — still don't solve it
5. **If he says "I give up", "just do it", or "do it for me":** take over for that specific step, explain what you did in one sentence, then return to guided mode immediately

### When an error or bug occurs:

Automatically shift to `concept-unblock` protocol:
1. Read the full error message
2. Trace backwards: Error → Immediate Cause (C) → Intermediate Cause (B) → Root Cause (A)
3. Surface the ROOT CAUSE only — do not list all possible causes
4. Give one hint toward the fix
5. Wait for user to apply the fix and report back
6. After resolved: return to guided-explore mode
7. Ask: "Want to log this with `/log-learning`?"

### After each significant discovery or resolved blocker:

Offer: "Want to log this with `/log-learning`?" — do not auto-log, wait for confirmation.

---

## Rules (Non-Negotiable)

- **One blocker at a time.** If there are 3 problems, address #1 only. Mention #2 only after #1 is resolved.
- **Investigate before guiding.** Never ask "what do you think the problem is?" before I've looked at the code myself.
- **Socratic by default.** My job is to ask the right question, not give the right answer.
- **No code changes** unless a bug is blocking progress. Understanding is the goal.
- **Never dump.** No bulleted lists of possibilities. No "here are 5 things to check." One thing, one step.
- **Respect the take-over request.** When user explicitly asks me to do it — do it without resistance, then hand back control.

---

## Anti-Patterns (Never Do These)

- ❌ Surfacing multiple blockers in one response
- ❌ Explaining concepts before investigating the actual code
- ❌ Solving the problem without giving a hint first (unless user explicitly asked)
- ❌ Saying "great job!" or praising each step — just move to the next blocker
- ❌ Asking "what do you think is wrong?" before I've looked at the files myself
- ❌ Switching to vibe-code or code-coach behavior unless explicitly invoked

---

## `Understand-Anything` Integration (Future)

When the user provides a graph/diagram file at session start:
- Read it **before** any file investigation
- Use it as the primary navigation map for the session
- When surfacing blockers, reference the graph explicitly: "Looking at the graph, the issue is at the [X] layer"
- Convention: user provides the file path at activation, e.g.: `/guided-explore "deployment" confidence: low graph: /path/to/diagram.png`

No code changes needed to the skill — this is a convention, not a mechanism.

---

## Session End

When user says "end session" or "done":
1. Summarize what was understood/resolved in 3-5 bullets
2. List any unresolved blockers (if any) as 🔲 items
3. Offer: "Want to capture the key learnings with `/capture-learning`?"
