# Coding Project Rules

## Shared coding rules (load every coding session)

**TRIGGER:** start of any coding session.

```
1. Check:  ls .claude/rules/coding-universal
2. If it is MISSING -> STOP. Tell the user in one line:
   "coding-universal rules not found at .claude/rules/coding-universal —
    symlink it before I start."
   Never proceed with these rules unloaded, and never silently skip them.
3. If it EXISTS -> the symlink proves the files are REACHABLE.
   It does NOT prove they were loaded into context.
   Before acting on any rule from these 5 files, run the LOADED TEST below.
```

### LOADED TEST (CRITICAL — this rule exists because the old one was wrong)

**TRIGGER:** you are about to write, restructure, or reformat any file these 5
files govern — `project_status.md`, `milestone.md`, `PROJECT.md`, `README.md`,
`daily_log.md`, a commit message, or a test command.

The old rule said "symlink exists → already auto-loaded → do not read them
again." **That inference is unverified and has been observed to be false.** A
project symlink does not control what the harness injects. When it is false you
act on a rule you have never read, and you will not notice, because nothing in
your context contradicts you.

```
ASK: can I quote the specific clause I am about to obey, from THIS session's
     context — not from memory, not from a past session, not from the gist?

NO  -> Read the one file that governs it, right now, before writing.
        Reading a file you did not need costs a few thousand tokens.
        Reformatting a tracked file against a rule you never read costs
        the user's trust and a full rewrite.
YES -> proceed.
```

**"I know the format" is not evidence. A quoted clause is evidence.**
Never infer a rule's content from the shape of the file already on disk — that
file may itself be the product of an earlier drift.

The five files, for reference:
- `documentation-structure.md` — README vs PROJECT.md, project_status.md format
- `git-workflow.md` — branch strategy, commit rules, atomic task check
- `logging-workflow.md` — daily log, session end workflow
- `session-management.md` — initialize and end-session procedures (includes the read-PROJECT.md-first rule)
- `testing-commands.md` — pytest flags and project prefix conventions

## `project_status.md` — FOUR SECTIONS. CLOSED SET. (CRITICAL)

**TRIGGER:** you are about to add, rename, move, or reorder any `##` heading in
`current_state/project_status.md`.

The full format is `documentation-structure.md` §10.3. That file is **not
guaranteed to be in your context**, so the one constraint that gets violated
most is duplicated here, where it is always loaded.

```
project_status.md contains EXACTLY these four top-level (##) sections,
in this order, and NOTHING ELSE:

  ## Current State        <- 3-6 bullets. Hard maximum 6. Count them.
  ## Completed Milestones <- the table
  ## Vx Task List         <- one line per task, symbol + name only
  ## Vx Task Details      <- one ### per task, matching the list above

(Multiple versions are allowed: V1 Task List / V1 Task Details,
 then V2 Task List / V2 Task Details. Nothing else joins the set.)
```

**This is a CLOSED SET, not a minimum.** "Required sections" never meant "at
least these". A fifth `##` heading is a violation no matter how useful, how
current, or how well written it is.

**The section you want to add is always one of these instead:**

| You were about to add | It goes here |
| --- | --- |
| `## Active Work`, `## This Session`, `## In Progress` | a `### 🔄` detail section + its checklist line |
| `## Plan`, `## Approach`, `## Strategy`, `## Roadmap` | the `### 🔲/🔄` detail section of the task it plans |
| `## Blockers`, `## Open Questions`, `## Risks` | bullets inside the blocked task's detail section |
| `## Key Decisions`, `## Notes`, `## Findings` | bullets inside the relevant task's detail section |
| Anything dated (`## Work 2026-09-06`) | `archive/daily_log.md`, never here |

Deeper headings (`####`) **inside** a `###` detail section are fine. The
constraint is on `##` only.

**BEFORE you finish the edit, run this. Output must be exactly four lines
(or six, with a V2):**

```bash
grep -n '^## ' current_state/project_status.md
sed -n '/^## Current State/,/^## /p' current_state/project_status.md | grep -c '^- '   # must be <= 6
```

**ON FAIL:** do not report the work as done. Fold the extra section into a task
detail section, add its checklist line in the SAME edit, and re-run the check.
Then run the bidirectional orphan check in `documentation-structure.md` §10.3.

**Why this is stressed this hard:** the failure is invisible from inside. Each
new section looks individually justified, the file still reads well, and the
next session inherits the drift as if it were the format. The user has had to
correct this more than once. Do not make it more than once again.

---

## Work-area standards (load selectively)

The relevant standards files are auto-loaded via the project's `.claude/rules/` directory (symlinks to `agent_core/rules/project-types/`). Apply only the standards relevant to the current task.

| Work area | Standards file (in `.claude/rules/`) |
|---|---|
| Backend (APIs, DB, auth, workers) | `backend-standards.md` |
| DevOps (Docker, CI/CD, deployment) | `devops-standards.md` |
| Frontend (components, state, UI) | `frontend-standards.md`, `ux-standards.md` |

Each project symlinks only what it needs — do not apply all three blindly.

## Cross-Project Issues

When investigating a bug or issue that originates in a **different repository** (not the current working project):

- **NEVER edit, create, or delete files in the other repo** — not even a one-line fix
- Instead, append a note to the other repo's `archive/crucial_notes.md` describing the bug, root cause, and the fix that should be applied
- Then continue working in the current project (e.g. adjust the UI error message, add a workaround) if applicable
- Only make changes to the other repo when the user **explicitly asks** you to switch to it

**Format requirement when appending to `crucial_notes.md`:**

1. Read the first ~20 lines of `crucial_notes.md` before writing — the format is documented there
2. Every actionable item (something that must be fixed or done) **must** use a `🔲 (PRIORITY) description` marker — no exceptions
3. Resolved items use `✅ (PRIORITY) description` with `→ follow-up detail` lines beneath
4. Free-form prose (root cause, context, code snippets) is fine in the section body, but the triage-visible action line must be the `🔲` bullet — that is what `grep -n '🔲'` surfaces at session init

## Python Dependency Management

**ALWAYS use `uv add` / `uv remove` to manage dependencies — never edit `pyproject.toml` manually.**

- `uv add "pkg>=version"` — adds to pyproject.toml, updates uv.lock, installs in one shot
- `uv remove pkg` — removes from pyproject.toml, updates uv.lock, uninstalls in one shot
- **Never** hand-edit the `[project.dependencies]` section in pyproject.toml
- **Never** use `uv pip install` as a substitute for `uv add` when adding a new project dependency
