# Coding Project Rules

## Shared coding rules (load every coding session)

At the start of every coding session, explicitly read all files in:
`agent_core/rules/project-types/coding-universal/`

These files apply to all coding projects regardless of work area:

- `documentation-structure.md` — README vs PROJECT.md, project_status.md format, optional bugs.md/resolved_bugs.md pair (§10.4)
- `git-workflow.md` — branch strategy, commit rules, atomic task check
- `logging-workflow.md` — daily log, session end workflow
- `session-management.md` — initialize and end-session procedures
- `testing-commands.md` — pytest flags and project prefix conventions
- `project-navigation.md` — read PROJECT.md first rule

Optional companion files in `current_state/` (load if present): `bugs.md` (mirrors project_status.md) and `resolved_bugs.md` (mirrors milestone.md) - see `documentation-structure.md` §10.4.

## Work-area standards (load selectively)

The relevant standards files are auto-loaded via the project's `.claude/rules/` directory (symlinks to `agent_core/rules/project-types/`). Apply only the standards relevant to the current task.

| Work area                          | Standards file (in `.claude/rules/`)       |
| ---------------------------------- | ------------------------------------------ |
| Backend (APIs, DB, auth, workers)  | `backend-standards.md`                     |
| DevOps (Docker, CI/CD, deployment) | `devops-standards.md`                      |
| Frontend (components, state, UI)   | `frontend-standards.md`, `ux-standards.md` |

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

## File Writes Containing Emoji (Windows agent hosts)

File-write tools (`replace_string_in_file`, `create_file`, equivalents) occasionally mangle non-BMP characters (🔲 🔄 ✅ ⚠️ ❎ and similar emoji) into the U+FFFD replacement character (�) on write - a Windows console/encoding artifact in the agent tool layer.

**Rule:** after ANY write whose new content contains emoji, immediately re-read the affected lines and replace any `�` with the intended character before ending the turn. Do not announce the write as successful until the re-read confirms emoji integrity.

Do NOT switch projects to ASCII status markers just to avoid this - verify-and-fix is the correct response.

For **status markers specifically**, prefer BMP-safe alternatives on Windows: ⬜️ (not started), ⏳ (in progress), ❌ (superseded). See `documentation-structure.md` §10.3 Platform note for the full rationale and equivalence rules.

## Large-File Write Preflight (mandatory)

**Trigger - external, mechanical:** before writing any file whose intended content exceeds ~150 lines OR ~4,000 characters, STOP.

**Do not** attempt the write. Instead:

1. Announce the target line count and section structure in chat.
2. State the write strategy explicitly - one of:
   - **Incremental (default for files >150 lines):** write section-by-section via successive `cat >> file << 'EOF'` heredocs, one section per turn, with `wc -l` after each to confirm progress. Never a single `create_file` for the whole document.
   - **One-shot (only when file is genuinely small OR is a stable template):** state why one-shot is safe here.
3. Wait for user acknowledgement of the strategy before the first write.

**Why this rule exists:** `create_file` and single-heredoc writes silently truncate or fail without loud error when content is too large. The failure mode masquerades as success. Recovery is only guaranteed for files tracked in git - gitignored files (like `current_state/project_status.md`) are unrecoverable if the original is deleted or overwritten during a failed retry. `response-style.md` §1.4 tells you to switch strategy _after_ the first failure; this rule fires BEFORE the first attempt so no failure happens at all.

**Never:** retry the same one-shot write after a truncation, silent partial write, or empty-file result. That is the documented failure loop §1.4 was written to prevent.

**Never:** run `rm` on gitignored file to "start clean" before rewriting. Rename it (`mv file file.bak`) so recovery is possible if the rewrite goes wrong. The shell-level `rm → trash` hook is a safety net, not a license to skip this discipline.
