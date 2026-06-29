# Coding Project Rules

## Shared coding rules (load every coding session)

At the start of every coding session, explicitly read all files in:
`agent_core/rules/project-types/coding-universal/`

These files apply to all coding projects regardless of work area:
- `documentation-structure.md` — README vs PROJECT.md, project_status.md format
- `git-workflow.md` — branch strategy, commit rules, atomic task check
- `logging-workflow.md` — daily log, session end workflow
- `session-management.md` — initialize and end-session procedures
- `testing-commands.md` — pytest flags and project prefix conventions
- `project-navigation.md` — read PROJECT.md first rule

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
