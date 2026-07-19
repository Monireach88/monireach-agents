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

**1. Current State vs Completed Milestones - critical distinction (read this before writing either section):**

|                                | Current State                                                                                                 | Completed Milestones                                        |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| **Purpose**                    | Tell a stranger what they need to know to work on this project TODAY.                                         | Historical record of every deliverable ever shipped.        |
| **Audience question answered** | "If I sit down at this project right now, what's live, what's blocked, what's next?"                          | "What has been delivered to date?"                          |
| **Time frame**                 | Now only.                                                                                                     | PAST only.                                                  |
| **Content**                    | Operational facts, active version/phase, current blockers, how to run, next action.                           | One row per shipped deliverable, oldest first.              |
| **Size**                       | Target 3-6 bullets; exceed only for genuinely critical operational-NOW facts that a fresh reader needs today. | Grows monotonically; never trimmed.                         |
| **If work is shipped**         | It leaves this section.                                                                                       | It arrives in this table (+ narrative into `milestone.md`). |

**A shipped deliverable NEVER belongs in Current State. Move it to Completed Milestones the moment it ships.** Historical narrative about the shipping event (`"Consolidation 2026-07-13..."`, `"Direction pivot 2026-06-30..."`) belongs in `daily_log.md` under that date - not in Current State, not in Completed Milestones.

---

**1. Current State** - **Target: 3-6 bullet points** describing the operational NOW. Bullet-count discipline:

- The 6-bullet target is a strong default, not a hard ceiling. Aim to stay ≤ 6.
- Before writing a 7th (or 8th) bullet, run this challenge on it: is this a genuinely critical operational-NOW fact that would leave a fresh reader unable to work on the project TODAY if omitted? If YES → keep it, exceed 6. If NO → drop it or move it (`daily_log.md` for historical narrative, Completed Milestones table for shipped work, V1 Task Details for task specifics, `milestone.md` for setup detail).
- Same challenge applies in reverse: every existing bullet must also survive the "would a fresh reader be stuck without this?" test - dead bullets get trimmed regardless of total count.
- Never omit a genuinely critical operational fact just to hit the 6-cap. Better a 7-bullet Current State with all-critical content than a 6-bullet one that hides a live blocker.

Required content (each is 1 bullet):

- **What's happening right now** (active version/phase, what's live vs broken as a system-state fact - NOT task progress; task progress belongs in the 🔄 V1 detail section).
- Known ugs / blockers (be honest: distinguish "current blockers" from "future handoffs / async pings" - the latter are NOT blockers).
- How to run locally (one-line pointer to the setup entry in `milestone.md`).
- Source-repo pins if this project depends on external code repositories.
- Bug tracker pointer (`bugs.md` / `resolved_bugs.md`) if that pair exists.
- **`Next:` as the FINAL bullet** - one sentence naming the immediate next action + a short sequenced roadmap of what follows it. This bullet is mandatory whenever V1 has at lease one open (🔲/🔄) task. It bridges Current State (NOW) → V1 checklist (upcoming). Do NOT split it into a separate `Progress:` bullet unless the project has a live system whose state is genuinely distinct from "next task" (e.g. a running SaaS with `billing endpoint down since ...`).

Anti-patterns to avoid:

- Historical narrative (`Consolidation 2026-07-13...`, `Direction pivot 2026-06-30...`) - that belongs in `daily_logs.md` under the correct date, not here.
- `Progress right now: X of Y done` as a bullet on its own - fold the progress number into `Next:` instead. `Progress:` as a separate bullet is only justified when it reports true system-state (see above), not task tick-count.
- Framing future handoffs as current blockers. If Task X is blocked by a ping but Task X hasn't started yet, that's not blocking any current work - say so explicitly.

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

### Acceptance blocks (Gherkin AC) — backward-compatible addition

A task detail section MAY carry an `**Acceptance:**` block in Given/When/Then form as the **LAST element of the detail section** — added inside it, never replacing the prose/bullets. Division of labor: prose + bullets = how to build; the AC block = how to verify done.

````
### 🔲 Task Name

[1–3 sentences: what this is and why it matters]

- Bullet: specific implementation detail

**Acceptance:**
```gherkin
Given a stranger with a Google account not in the system
When they log in via Google
Then a tenant exists with balance_usd=0 and they receive a JWT

Given a Google login with an invalid or revoked token
When the callback is processed
Then no tenant is created and the response is 401
```
````

Rules:

- **SHOULD for behavior-changing tasks; refactor/docs tasks may omit.** No migration of existing files — the addition is backward-compatible.
- **Timing:** AC is written at **PHASE PLANNING** — all tasks of the phase together, here in `project_status.md` — never one-at-a-time during implementation, and never in dev notes. Reason 1: the cross-task picture — along a journey, an upstream task's `Then` must produce the downstream task's `Given` (fan-out/fan-in allowed; the chain applies per journey, never phase-wide across unordered tasks) — inter-task contradictions surface before implementation. Reason 2: speed — AC→failing-test becomes mechanical translation downstream.
- **Quality checklist:** declarative style (what, not how); `Then` = an observable, checkable state or output — never "system works"; one behavior per scenario; no UI selectors/URLs in backend AC; `Given` = a persisted or establishable state. **Each behavior AC gets a negative or boundary counter-scenario at phase planning.**
- **Dual generation:** the owner drafts AC from intent, AI drafts independently from PRODUCT_SPEC.md, then diff — solo development collapses the Three Amigos into one head; without the diff, AC inherits its author's blind spots and "verifies" them.
- **Lifecycle:** AC blocks archive to `current_state/milestone.md` with their tasks at PHASE END (see `logging-workflow.md` §2.6) — copied VERBATIM, never rewritten. The AC's permanent living form is the converted test suite; `project_status.md` size tracks active workload only (§10.1 multi-file pattern is the escape valve if ever needed).

**4. Post-Vx Backlog** — short bullet list of future task names with 🔲, followed by `## Post-Vx Task Details` using the same `### 🔲 Task Name` + detail pattern.

### Rules

- **Checklist first, details below** — the task list must be scannable in seconds; details live in named subsections underneath
- **Every task has a detail section** — a substantive task with no details is ambiguous; a future Claude session cannot act on it. (Trivial one-liner backlog items — a single self-explanatory sentence — may live as a checklist entry alone.)

> **platform note - Windows agent hosts:** the VS Code Copilot file-write tool corrupts non-BMP emoji (🔲, 🔄, ✅) into the U+FFFD replacement character (`�`). On Windows agent sessions, use the BMP-safe equivalents when creating or editing status markers: **⬜️** (not started, replaces 🔲), **⏳** (in progress, replaces 🔄), **❌** (superseded, replaces ❎). ✅ (done) is BMP and unchanged. Both symbol sets are semantically identical - the orphan-detail check and other integrity greps below accept either set. When editing a file that already uses macOS-origin markers on a Windows session, either follow the existing set (with verify-and-fix on every write) or convert that specific file to the BMP-safe set.

- **Checklist ↔ details are bidirectional — no orphan detail sections** — every `### 🔲/🔄 Task Name` detail section MUST have a matching one-line `- 🔲/🔄 Task Name` entry in the checklist above it. Adding a detail section without first adding its checklist line is a violation (this is the most common failure: writing the detail and forgetting the list entry above). The checklist is the index; a detail with no index entry is invisible when scanning the task list. When you add any detail section, add its checklist line in the SAME edit. Verify both directions with:
  ```bash
  # Run inside current_state/ — lists any detail section with no checklist entry anywhere above (must be empty).
  # NOTE: emoji symbols are matched with grep -E alternation (🔲|⬜️|🔄|⏳|✅|❎|❌), NEVER an awk bracket class
  # like [🔲|🔄] — awk splits multibyte emoji into bytes and silently matches nothing.
  # Whole-file scan (not one section): V1/V2 checklists live under `### Phase N` headings, not a "Backlog" header.
  grep -E '^- (🔲|⬜️|🔄|⏳|✅|❎|❌) '   project_status.md | sed -E 's/^- (🔲|⬜️|🔄|⏳|✅|❎|❌) //; s/ \(.*//'                 | sort -u > /tmp/cl.txt
  grep -E '^#{3,4} (🔲|⬜️|🔄|⏳|✅|❎|❌) ' project_status.md | sed -E 's/^#{3,4} (🔲|⬜️|🔄|⏳|✅|❎|❌) //; s/ \(.*//; s/ \*\(.*//' | sort -u > /tmp/dt.txt
  comm -13 /tmp/cl.txt /tmp/dt.txt   # any output = orphan detail section → add its checklist line
  ```
- **No floating prose** — decisions, constraints, and notes belong inside a task's detail section, not as standalone paragraphs between tasks
- **No orphan sections** — do not leave standalone sections like "Key Decisions" or "Auth Flow" floating at the bottom; fold their content into the relevant task detail sections
- **Symbol on every task** — 🔲 (not started), 🔄 (in progress), ✅ (done, then moved to milestone.md), 🔲 (post-version backlog)
- **When V2 exists** — add a `## V2 — [goal]` section and `## V2 Task Details` block in the same format; never collapse past versions
- **Project scope** — `project_status.md` only contains tasks that belong to this repository. Cross-repo dependencies (e.g. a backend endpoint a frontend needs) must not appear here at all — not even as one-line checklist items. Track them in the repo where the work lives.

---

## $10.4 bugs.md / resolved_bugs.md - Optional Bug Tracker Pair

Some projects benefit from tracking observed runtime/UX bugs separately from feature tasks - typically when the agent is exploring an existing system, doing UAT-style testing, or maintaining a legacy product where bugs accumulate independently of the feature roadmap. When a project chooses to do this, it MUST follow this exact pair in `current_state/`:

| File                  | Mirrors                                    | Purpose                                                                                                                                                                                                 |
| --------------------- | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| current_state/bugs.md | project_status.md (S10.3) - same structure | Single source of truth for open + in-progress bugs. Has a `## Current State` header, a `## Bug List` table (one row per bug), and a `## Bug Details` section with `### 🔲 BUG-NNN - title` subsections. |

current_state/resolved_bugs.md | milestone.md (S2.6 archival format) - same structure | History of fixed bugs. Quick Reference table at the top, full narrative sections (`## ✅ BUG-NNN - title (YYYY-MM-DD)` below).

### Rules

- **Both files are OPTIONAL.** A project either has both or neither. If the pair exists, treat `bugs.md` as authoritative for bug state alongside `project_status.md`.
- **project_status.md` carries a one-line pointer** under `## Current State`, e.g. `Bug tracker: see [current_state/bugs.md](bugs.md); resolved entries in [current_state/resolved_bugs.md](resolved_bugs.md).` - do NOT duplicate bug entries into `project_status.md`.
- **Bug archival mirrors task archival** (S2.6 atomic sequence): when a bug is fixed, remove its `###` detail section + table row from `bugs.md`, add the row + narrative section to `resolved_bugs.md`, and bump the open/resolved counts in `bugs.md`'s `## Current State` header.
- **Bugs are NOT milestones.** Fixed bugs go to `resolved_bugs.md`, never to `milestone.md` - milestones are for shipped features/deliverables only. Mixing dilutes both signals.
- **Optional module-split escape value** - if `bugs.md` grows past ~50 entries OR becomes hard to scan, split by lifecycle module under `current_state/bugs/` (one child file per module), keep `bugs.md` as the index, and apply the same shape to each child.

---

## §10.5 project_status.md Write Discipline - Mandatory Incremental (Windows agent hosts)

Because `current_state/project_status.md` (a) grows past 150 lines routinely, (b) is gitignored in every project by convention, (c) is often the single most valuable working-memory file in the repo, and (d) has been demonstrably lost during single-shot rewrites in the past - writes to this file are governed by a HARD rule that overrides any general "batch writes" preference:

**Rule:** every write to `current_state/project_status.md` MUST be done section-by-section using successive `cat >> file << 'EOF'` heredocs, one top-level section per turn, with `wc -l` after each append. Section order matches the §10.3 required structure: Current State → Completed Milestones → V1 (+ Task Details) → Post-V1 (+ Task Details).

**Never:**

- Write the entire file in a single `create_file` call.
- Delete the existing file (`rm`) before rewriting. Rename with `mv project_status.md project_status.md.bak` first.
- Always. The old file is deleted ONLY after the new file passes all §10.3 integrity checks.
- Skip the between-section `wc -l` sanity check.

**Full-file restructures follow this exact sequence:**

1. `mv current_state/project_status.md current_state/project_status_expired.md`
2. `touch current_state/project_status.md` (blank file)
3. Append Section 1 (Header + Current State) via `cat >> ... << 'EOF'`, then `wc -l`
4. Append Section 2 (Completed Milestones), then `wc -l`
5. Append Section 3a (V1 checklist), then `wc -l`
6. Append Section 3b (V1 Task Details, one detail section per heredoc), then `wc -l`
7. Append Section 4a (Post-V1 Backlog), then `wc -l`
8. Append Section 4b (Post-V1 Task Details, one per heredoc), then `wc -l`
9. Run all four integrity checks (no `### ✅` in file; bidirectional orphan-detail check; zero mojibake; zero legacy 🔲|🔄|❎ on Windows hosts)
10. Only after all checks pass: `rm current_state/project_status_expired.md`

If any integrity check fails, do NOT delete the expired file - investigate and fix first. The expired file IS your recovery source.
