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
- Key architecture decisions — the _why_, not just the _what_ (one line each; the full reasoning lives in `docs/adr/`, see §10.4)
- "Where to Find Things" table — maps topics to files

**PROJECT.md must NOT contain:**

- Setup or installation instructions
- API usage examples
- Anything written for an external reader

---

## §10.3 project_status.md — Mandatory Format

`project_status.md` is the single source of truth for what has been built and what remains. Every coding project must have one at `current_state/project_status.md`. Future Claude sessions resume from this file — it must be unambiguous.

### Required sections (in order) — a CLOSED SET, not a minimum

**Read this before the list below.** The four headings that follow are the
**only** `##` sections `project_status.md` may contain. "Required" has been
misread as "at least these" and the file has drifted to five and six top-level
sections more than once. It is a closed set:

```
## Current State        <- 3-6 bullets. Hard maximum 6.
## Completed Milestones
## Vx Task List
## Vx Task Details
```

A fifth `##` heading is a violation regardless of how useful or current its
content is. `## Active Work`, `## Plan`, `## Blockers`, `## Key Decisions`,
`## Notes` and anything dated all belong **inside a task's `###` detail
section** (or in `archive/daily_log.md`), never as a peer of the four.
`####` headings nested inside a `###` detail section are fine — the constraint
applies to `##` only.

Verify before calling the edit done — four lines out (six with a V2):

```bash
grep -n '^## ' current_state/project_status.md
sed -n '/^## Current State/,/^## /p' current_state/project_status.md | grep -c '^- '   # must be <= 6
```



**1. Current State** — 3–6 bullet points: what is working right now, known bugs, how to run locally, what's next.

**2. Completed Milestones** — a table: `| Milestone | Completed | Tests |`. One row per major deliverable. Link to `current_state/milestone.md` for full details.

**3. Vx Task List** (one per active version; V2 only when the user says so)

- One-line goal statement ("Goal: a gifted tenant can fully onboard…")
- Short checklist of task names grouped by phase — just names + 🔲/🔄 symbol, no detail here
- **4.** Followed immediately by `## Vx Task Details` — one subsection per task:

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
- **Dual generation:** the owner drafts AC from intent, AI drafts independently from `docs/prd.md` (legacy: root `PRODUCT_SPEC.md`), then diff — solo development collapses the Three Amigos into one head; without the diff, AC inherits its author's blind spots and "verifies" them.
- **Lifecycle:** AC blocks archive to `current_state/milestone.md` with their tasks at PHASE END (see `logging-workflow.md` §2.6) — copied VERBATIM, never rewritten. The AC's permanent living form is the converted test suite; `project_status.md` size tracks active workload only (§10.1 multi-file pattern is the escape valve if ever needed).

**Backlog** — future tasks are 🔲 entries in the `Vx Task List`, each with its `### 🔲` detail. There is no separate backlog `##` section (closed set above).

### Rules

- **Checklist first, details below** — the task list must be scannable in seconds; details live in named subsections underneath
- **Every task has a detail section** — a substantive task with no details is ambiguous; a future Claude session cannot act on it. (Trivial one-liner backlog items — a single self-explanatory sentence — may live as a checklist entry alone.)
- **Checklist ↔ details are bidirectional — no orphan detail sections** — every `### 🔲/🔄 Task Name` detail section MUST have a matching one-line `- 🔲/🔄 Task Name` entry in the checklist above it. Adding a detail section without first adding its checklist line is a violation (this is the most common failure: writing the detail and forgetting the list entry above). The checklist is the index; a detail with no index entry is invisible when scanning the task list. When you add any detail section, add its checklist line in the SAME edit. Verify both directions with:
  ```bash
  # Run inside current_state/ — lists any detail section with no checklist entry anywhere above (must be empty).
  # NOTE: emoji symbols are matched with grep -E alternation (🔲|🔄|✅), NEVER an awk bracket class
  # like [🔲🔄] — awk splits multibyte emoji into bytes and silently matches nothing.
  # Whole-file scan (not one section): V1/V2 checklists live under `### Phase N` headings, not a "Backlog" header.
  grep -E '^- (🔲|🔄|✅) '   project_status.md | sed -E 's/^- (🔲|🔄|✅) //; s/ \(.*//'                 | sort -u > /tmp/cl.txt
  grep -E '^#{3,4} (🔲|🔄|✅) ' project_status.md | sed -E 's/^#{3,4} (🔲|🔄|✅) //; s/ \(.*//; s/ \*\(.*//' | sort -u > /tmp/dt.txt
  comm -13 /tmp/cl.txt /tmp/dt.txt   # any output = orphan detail section → add its checklist line
  ```
- **No floating prose** — decisions, constraints, and notes belong inside a task's detail section, not as standalone paragraphs between tasks
- **No orphan sections** — do not leave standalone sections like "Key Decisions" or "Auth Flow" floating at the bottom; fold their content into the relevant task detail sections
- **Symbol on every task** — 🔲 (not started), 🔄 (in progress), ✅ (done, then moved to milestone.md), 🔲 (post-version backlog)
- **When V2 exists** — add a `## V2 — [goal]` section and `## V2 Task Details` block in the same format; never collapse past versions
- **Project scope** — `project_status.md` only contains tasks that belong to this repository. Cross-repo dependencies (e.g. a backend endpoint a frontend needs) must not appear here at all — not even as one-line checklist items. Track them in the repo where the work lives.

---

## §10.4 `docs/` — SDLC Documents (Tracked in Git)

The SDLC skills write their outputs to `docs/`, never to the repo root. The root holds only README.md, LICENSE, CHANGELOG.md, CONTRIBUTING.md and config files.

| File | Content | Written by |
| --- | --- | --- |
| `docs/product-brief.md` | The business case: problem, persona, market, MVP scope | `/ideation` |
| `docs/prd.md` | Product requirements: actors, entities, CRUD matrix, journeys, NFRs, non-goals | `/product-spec` |
| `docs/architecture.md` | What the system is now: components, stack per layer, schema, infrastructure. Links each choice to its ADR. Edited freely. | `/technical-consultant` |
| `docs/adr/NNNN-<title>.md` | One file per decision: context, alternatives, decision, consequences | `/technical-consultant` |

Rules:

- **All filenames under `docs/` are kebab-case.** ADR numbers are 4 digits, start at `0001`, and are never reused.
- **Tracked in git, public.** These files are NOT Drive symlinks — a teammate who clones the repo needs them.
- **ADRs are immutable once `Accepted`.** A changed decision is a new ADR that supersedes the old one. The only edit allowed to the old ADR is its Status line: `Superseded by [MMMM](MMMM-title.md)`.
- **Legacy root files** (`PROJECT_BRIEF.md`, `PRODUCT_SPEC.md`, `TECH_STACK.md`) are migrated by re-running the producer skill. Never keep both the old and the new file.

How `docs/` relates to the two root documents (§10.2):

- **README.md** is the public overview. It may link to `docs/` for depth, but does not copy it.
- **PROJECT.md** is the private navigation hub. Its "Where to Find Things" table links to the `docs/` files. Its "Key architecture decisions" entry points to `docs/adr/` instead of repeating the reasoning.
