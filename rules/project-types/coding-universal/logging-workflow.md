# §2. Real-Time Logging Workflow

Append key events to `archive/daily_log.md` as they happen. At session end, use today's entries to update `current_state/`. **Never read the whole log file** — it can be tens of thousands of lines.

## §2.1 How to Append

Use the `tail -N` escalation ladder in `token-efficiency.md` §11.3 to find today's date header. If the last date found is older than today, create a new header:

```markdown
## YYYY-MM-DD

- Your entry here
```

---

## §2.2 What to Log

**LOG** — anything a future reader could not reconstruct from the code or git history:

| Category | Example |
|---|---|
| Decision with a rejected alternative | chose Qdrant over pgvector because … |
| Root cause found after real digging | the 500 was a stale Alembic head, not the router |
| Failed attempt | tried X, failed because Y |
| Mental model shift | we thought it was X, it is actually Y |
| Blocker / waiting state | blocked on owner running the setup script |
| Security or risk tradeoff | enabled exec() site-wide for ffmpeg only |
| Third occurrence of the same issue | recurring — needs a systemic fix |

**DO NOT LOG:** command executions, file reads, routine debugging steps, or anything already visible in `git log`.

---

## §2.3 Entry Format

**One line is the default.** Escalate only when the extra lines carry information the one-liner cannot.

```markdown
- Fixed exec() disabled → edited php83rc pool config, restarted PHP-FPM
```

Add a `**Blocker:**` or `**Decision:**` header with 2–3 sub-bullets **only** when there is a rejected alternative or an unresolved dependency to record. **Hard cap: 6 lines per entry.** If an entry needs more than 6 lines, it is an `error_log.md` investigation, not a daily-log line.

> **Numbering note:** there is no §2.4. The old §2.1–§2.4 collapsed into §2.1–§2.3. §2.5 and §2.6 keep their numbers on purpose — six other files and skills cite them by number.

---

## §2.5 End of Session Workflow

When user says "end session":

1. **Read TODAY'S log entries ONLY:**
   - Read ONLY the last 50 lines of `archive/daily_log.md`
   - Find today's date (YYYY-MM-DD)
   - If no entries for today → Skip to step 4 (nothing to update)
   - If entries exist → Read from today's date to end of file

2. **Update current_state/ files:**
   - Use today's log entries to update status files in `current_state/` directory
   - Only update files relevant to today's work
   - **After updating any status file:** grep for the completed task name (case-insensitive, shortest distinctive keyword) across the **entire file** — every `🔲` next to that name must become `✅`, regardless of which section it appears in. Do not limit the grep to "active task" or "backlog" sections only. Symbols alone (🔲, 🔄, ✅) are not enough; a task can appear in plain text with no symbol.
   - **Symbol rule:** every task entry in `project_status.md` must carry a symbol (✅, 🔄, or 🔲). Never leave a task name without a symbol — a symbolless task is invisible to search and will be missed.
   - **Orphan-detail rule:** whenever you add a `### 🔲/🔄 Task Name` detail section, add its matching one-line `- 🔲/🔄 Task Name` entry to the checklist above in the SAME edit (`documentation-structure.md` §10.3, bidirectional invariant). Before finishing, run the §10.3 `comm -13` orphan-detail check — any output is a detail section with no checklist line; fix it now.
   - **Completed tasks → milestone.md:** at end-session, any `### ✅` detail section still in `project_status.md` must be archived using the atomic sequence in **§2.6**. This should be rare — §2.6 fires mid-session when a task completes, so end-session is just a safety net.

3. **Update PROJECT.md (if applicable):**
   - ONLY if project structure changed (new directories, major refactoring, new components)
   - Do NOT update for routine work

4. **Final check:**
   - Ensure next session can resume from daily_log alone
   - All important context is captured
   - Run `grep -n '^### ✅' current_state/project_status.md`; expected result is no output, EXCEPT sections marked `*(awaiting phase-end archival)*` (sanctioned by the §2.6 phase-end AC archival rule until their phase completes). If any OTHER completed detail section remains in `project_status.md`, run the §2.6 atomic sequence now before closing the session. If the phase itself completed this session, the deferred sections archive now, together.

**NEVER read the entire daily_log.md file at end of session - only today's entries!**

---

## §2.6 On-Task-Complete Archival (fires mid-session, immediately when a task is fully done)

**Trigger:** A task is marked `✅` and is entirely complete — all sub-tasks done, verified, no open items.

**Do NOT fire this for:**
- Tasks partially done (some sub-tasks still 🔲)
- Tasks marked 🔄 (in progress)
- Tasks that "look done" but haven't been verified
- Completed child subtasks whose parent task is still in progress. In that case, keep the child detail in `project_status.md` as a completed subtask entry (for example `#### ✅ ...`) until the parent task itself is fully complete.
- **Tasks carrying an `**Acceptance:**` Gherkin block while their phase still has open (🔲/🔄) tasks — PHASE-END AC ARCHIVAL RULE.** AC blocks chain per journey (an upstream task's `Then` is a downstream task's `Given` — see `documentation-structure.md` §10.3); archiving task N's AC mid-phase would split the chain source across two files while task N+1 still chains from it. The completed task keeps its `### ✅` detail section (AC included) in `project_status.md` until the WHOLE PHASE completes, then ALL the phase's completed tasks archive together via the atomic sequence. This is the one sanctioned case where a `### ✅` section legitimately remains in `project_status.md` — mark it `### ✅ Task Name *(awaiting phase-end archival)*` so integrity checks can classify it.

**Atomic sequence — run in order, do not skip steps:**

1. **Copy** the full `### ✅ Task Name` detail section from `project_status.md` into `current_state/milestone.md` using the format below.
2. **Delete** that detail section from `project_status.md` — remove the `### ✅ Task Name` heading and every line up to, but not including, the next `###` heading or horizontal rule.
3. **Add** the one-line row to the "Completed Milestones" table in `project_status.md`.
4. **Verify** the cleanup:
   ```bash
   grep -n '^### ✅' current_state/project_status.md
   ```
   Expected result: no output, EXCEPT sections marked `*(awaiting phase-end archival)*` under the phase-end AC archival rule above — those are sanctioned until their phase completes. Any other remaining `### ✅` section is a violation — remove it before continuing.

**Nested-task clarification:**

- The `### ✅` cleanup rule applies only to fully completed top-level task detail sections being archived out of `project_status.md`
- If a parent task remains `🔄`, completed child subtasks must stay in `project_status.md` with their detail sections so the task tree remains unambiguous
- In nested structures, archive only when the parent task is fully complete or when the project has an explicit parent/child archival rule that says otherwise

**milestone.md entry format (mandatory — never deviate):**

Step 1 — Add a row to the Quick Reference table at the top:
```
| [Milestone Name] | YYYY-MM-DD (– YYYY-MM-DD if multi-day) | X/X (or — if no tests) |
```

Step 2 — Append a full section at the bottom of the file:
```markdown
## ✅ [Milestone Name] (YYYY-MM-DD – YYYY-MM-DD)

**Why this task existed:** [business situation in plain English — why a user or operator could not do
something they needed to do, or what was silently broken. No variable names, no code jargon without
explanation at first use.]

**Non-obvious decision — [descriptive name]:** [situation → tricky part → decision and why. Include
only when a developer could reasonably have chosen differently and regretted it. Skip if any developer
would make the same choice without hesitation.]

**Non-obvious problem — [descriptive name]:** [symptom → root cause → resolution. Include only when
the problem was non-obvious to diagnose — masked by a mock, caused by a renamed field, a missing
mount, etc. Skip for trivially obvious fixes.]

- ✅ [file or component]: [what changed — in plain English; no function names, TypeScript syntax, or framework terms without explanation]
- ✅ [file or component]: [what changed — in plain English; no function names, TypeScript syntax, or framework terms without explanation]
- Deferred to Post-Vx: [what and why — in plain English]

**Acceptance:** [if the task detail carried an `**Acceptance:**` Gherkin block, copy it here VERBATIM — see Rules]

**Final state:** X/X tests passing (YYYY-MM-DD)
```

Rules:
- Section heading always starts with `## ✅`
- Every sub-task line starts with `✅`
- `**Why this task existed:**` is mandatory on every entry
- `**Non-obvious decision:**` and `**Non-obvious problem:**` are optional — include only when genuinely non-obvious; omit when the answer is self-evident to any developer
- Each narrative section starts with context (situation) before any technical term — never open with a variable name, function name, or framework term
- Bullet lines follow the same plain-English rule — no function names, TypeScript syntax, or framework terms without explanation. If you catch yourself writing a function name or type annotation in a bullet, rewrite it as what it does, not what it is called
- Self-check before finalizing covers ALL lines, not just the narrative sections: "If I lost all code ownership tomorrow and came back in 6 months, would I understand why this task existed, what each file change accomplished, and what to watch out for if I touch this area again?"
- `**Final state:**` always present when there are tests; omit only if no tests apply
- **Acceptance blocks are copied VERBATIM** — if the archived task detail carries an `**Acceptance:**` Gherkin block, it transfers into the milestone entry unchanged, placed after the bullets and before `**Final state:**`. The rewrite-to-plain-English rule applies to bullets, NEVER to the Gherkin block — the Given/When/Then text is a precision artifact; rewriting it destroys its value as the record of what "done" meant. Omit the slot when the task had no AC block.
- `project_status.md` must never contain `### ✅` detail sections — with ONE exception: sections marked `*(awaiting phase-end archival)*` under the phase-end AC archival rule (see "Do NOT fire this for"), which remain only until their phase completes. All other completed details belong only in `current_state/milestone.md`; `project_status.md` keeps only the Completed Milestones table row plus active/backlog detail sections.
