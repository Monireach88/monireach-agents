# Coding Rules

## Shared coding rules
At the start of a coding session, `.claude/rules/coding-universal` must exist (a symlink to `$AGENT_CORE_DIR/rules/project-types/coding-universal`). If it is missing, tell him in one line and do not start. A symlink proves the 5 files are reachable, not that you read them: before obeying one of their rules, make sure you can quote the clause from this session's context, or read the file first.
Work-area standards (`backend-standards.md`, `devops-standards.md`, `frontend-standards.md`, `ux-standards.md`) apply only to work in that area.

## project_status.md has exactly four `##` sections
`## Current State` (3 to 6 bullets), `## Completed Milestones`, `## Vx Task List`, `## Vx Task Details`, in that order. A V2 List/Details pair may follow. Nothing else at `##` level.
Plans, blockers, decisions and active work go inside the task's `###` detail section. Dated notes go to `archive/daily_log.md`.
Check after every edit: `grep -n '^## ' current_state/project_status.md` lists only those headings.

## Other repositories
Never write to another repository's files (including its `archive/crucial_notes.md`) without his yes in this conversation. Tell him in one line which repo, which file and what is wrong, and offer to log it. Before logging, read the file's first 20 lines for its format; an action item uses `🔲 (PRIORITY) description`.

## Python
- Manage dependencies only with `uv add` / `uv remove`. Never hand-edit `[project.dependencies]`, and never use `uv pip install` instead of `uv add`.
- Keep Python projects in `~/projects`, never inside Google Drive.

## Environment failures: never diagnose from one error message
1. Retry once. File locks, antivirus scans and half-finished downloads cause errors that vanish on a second run.
2. Find a control: something of the same kind that works on this machine. No control means you have a guess, so say "I don't know why yet".
3. Change one variable between the failing case and the control. That variable is the cause.
4. State the cause by citing the test you ran, never the error text.
Never replace the project's standard tool (for example uv) before step 3. Reason: on 2026-09-22 one transient "Access is denied" made an agent abandon uv for pip on false grounds.
