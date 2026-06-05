# §10. Documentation Structure

## §10.1 Multi-File Pattern for Long Documents

When writing long reference documents (frameworks, guides, specifications) that would exceed ~500 lines:

1. **Split content into part files** — divide by topic area: `doc_p1.md`, `doc_p2.md`, `doc_p3.md`, etc.
2. **Write one index file** at the canonical document name (e.g., `backend_development_framework.md`) containing:
   - A summary of each part's contents
   - A quick navigation/decision guide
   - Key standards or concepts referenced
3. **The index is the entry point.** Part files hold the full detail.

**Why:** Long single files are hard to navigate. An index + parts keeps the entry point scannable while preserving full depth in each part.

**When to apply:** Any framework, reference guide, or specification document — not regular code files, README files, or task notes.

---

## §10.2 README.md vs PROJECT.md

Every coding project has two root-level documents that serve opposite audiences. Never merge them.

|                       | README.md                                      | PROJECT.md                                          |
| --------------------- | ---------------------------------------------- | --------------------------------------------------- |
| **Audience**          | External (recruiters, collaborators, users)    | Internal (Claude + the developer)                   |
| **Question answered** | "What is this and how do I use it?"            | "Where is everything and what's the current state?" |
| **Updated**           | Rarely — only when public-facing story changes | Frequently — as architecture and status evolve      |

**README.md must contain:**

- One-paragraph description of what the project does
- Tech stack table
- Setup / quick start instructions
- Key environment variables (names only, not values)
- API usage example
- Roadmap (optional but useful for portfolio projects)
- Developer contact (for portfolio projects)

**README.md must NOT contain:**

- Internal file navigation (e.g. "see `current_state/`")
- Architecture decisions with reasoning
- Current sprint status or task lists
- Personal names in code examples — use generic placeholders

**PROJECT.md must contain:**

- One-line "What it is" summary (business framing, not technical)
- **Current Focus** — the active task in one line, linked to full spec; always at the top after the summary
- Tech stack table (can overlap README — serves different purpose here: quick Claude reference)
- Project structure (directory map with purpose of each folder)
- Key architecture decisions — the _why_, not just the _what_
- "Where to Find Things" table — maps topics to files

**PROJECT.md must NOT contain:**

- Setup or installation instructions
- API usage examples
- Anything written for an external reader

---

## §10.3 project_status.md — Mandatory Format

`project_status.md` is the single source of truth for what has been built and what remains. Every coding project must have one at `current_state/project_status.md`. Future Claude sessions resume from this file — it must be unambiguous.

### Required sections (in order)

**1. Current State** — 3–6 bullet points: what is working right now, known bugs, how to run locally, what's next.

**2. Completed Milestones** — a table: `| Milestone | Completed | Tests |`. One row per major deliverable. Link to `current_state/milestone.md` for full details.

**3. Vx — [Version goal]** (one section per active version)

- One-line goal statement ("Goal: a gifted tenant can fully onboard…")
- Short checklist of task names grouped by phase — just names + 🔲/🔄 symbol, no detail here
- Followed immediately by `## Vx Task Details` — one subsection per task:

```
### 🔲 Task Name

[1–3 sentences: what this is and why it matters]

- Bullet: specific implementation detail
- Bullet: file(s) to change
- Bullet: non-obvious constraint or decision
```

Use 🔲 for not started, 🔄 for in progress. When a task completes: move it to `current_state/milestone.md` and add a one-line row to the Completed Milestones table.

**4. Post-Vx Backlog** — short bullet list of future task names with 🔲, followed by `## Post-Vx Task Details` using the same `### 🔲 Task Name` + detail pattern.

### Rules

- **Checklist first, details below** — the task list must be scannable in seconds; details live in named subsections underneath
- **Every task has a detail section** — a task with no details is ambiguous; a future Claude session cannot act on it
- **No floating prose** — decisions, constraints, and notes belong inside a task's detail section, not as standalone paragraphs between tasks
- **No orphan sections** — do not leave standalone sections like "Key Decisions" or "Auth Flow" floating at the bottom; fold their content into the relevant task detail sections
- **Symbol on every task** — 🔲 (not started), 🔄 (in progress), ✅ (done, then moved to milestone.md), 🔲 (post-version backlog)
- **When V2 exists** — add a `## V2 — [goal]` section and `## V2 Task Details` block in the same format; never collapse past versions
- **Project scope** — `project_status.md` only contains tasks that belong to this repository. Cross-repo dependencies (e.g. a backend endpoint a frontend needs) must not appear here at all — not even as one-line checklist items. Track them in the repo where the work lives.
