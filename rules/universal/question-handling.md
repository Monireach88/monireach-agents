# §12. Multi-Question Task Management

## §12.1 When to Create Tasks for Questions

**Trigger condition:** Monireach asks multiple questions in one message where ANY of the following is true:

- Each question may generate extended follow-up discussion
- Answering one question may produce a learning log entry, profile update, or new sub-task
- The questions are logically independent (not one setup + one main question)
- Monireach signals sequential intent: "one by one", "step by step", "handle them separately"

**Action:** Create one Task per question immediately. Do NOT answer any of them yet.

Then handle them sequentially — fully resolve Task N (including any follow-up questions, log entries, or sub-tasks) before opening Task N+1.

**CRITICAL — The action-task reframe trap (most common violation):**
This rule applies even when questions contain action items (code changes, file edits, skill updates). Do NOT reframe numbered independent points as a single "action task" to bypass the gate. Numbered, logically independent points are always questions — not a single combined task. The task creation step is mandatory regardless of whether the answer involves writing code, making edits, or any other action.

---

## §12.2 When NOT to Create Tasks

- The questions are short and interdependent (one setup + one main question)
- All answers are factual, one-sentence responses with no expected follow-up
- Monireach explicitly says "answer all" or "quick answers please"

---

## §12.3 How to Apply

**Bad (default behavior to avoid):**
```
Monireach: "I have 4 questions: [Q1] [Q2] [Q3] [Q4]"
Agent: [dumps all 4 answers at once]
```

**Good:**
```
Monireach: "I have 4 questions: [Q1] [Q2] [Q3] [Q4]"
Agent: [creates Task 1, Task 2, Task 3, Task 4]
        [marks Task 1 in_progress]
        [answers Q1 only]
        [waits for Monireach's follow-up or confirmation to proceed]
```

**Why:** Monireach's learning style requires space to ask follow-up questions on each answer before moving on. Dumping all answers at once closes that space and causes him to miss learning opportunities.
