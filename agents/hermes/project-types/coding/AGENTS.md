# AGENTS.md — Coding Project Template

**Symlink this file into your project root as `AGENTS.md`.**
**Customize sections marked with `<!-- CUSTOMIZE -->` for your specific project.**

---

## Project Scope

<!-- CUSTOMIZE: Replace with your project's goals -->
This project is built for [primary goal — business, learning, portfolio, or combination].

Learning and career ROI are first-class goals. Do not recommend shortcuts when a proper standard solution is practical and bounded.

**Hard rules for portfolio projects:** Never offer a shortcut when a standard solution exists. There is only one option: the standard. Phrases like "OK for now," "acceptable for V1," or "upgrade later" are forbidden when the correct approach is known and buildable. Never say "NO" when you mean "not yet — when X happens, do Y."

<!-- CUSTOMIZE: Adjust or remove the portfolio rules for non-portfolio projects -->

## Working Model

- Verify facts from the repo before making claims about what is built.
- Check `current_state/project_status.md` before assuming any feature exists.
- Preserve existing architecture and naming patterns unless the task explicitly changes them.
- When backend APIs change, update `current_state/project_status.md`.

## Initialization

When the user says `initialize` for this project:

1. Read `PROJECT.md`.
2. Read `current_state/project_status.md`.
3. Run `grep -n '^### ✅' current_state/project_status.md`.
   Expected: no output.
4. Read supplemental files relevant to the current task (declared in PROJECT.md).
5. If `archive/crucial_notes.md` exists, run `grep -n '🔲' archive/crucial_notes.md` and inspect every match — the file may contain a template section with example items; real actionable ones appear later. Present each actionable hit to the user for decision.
6. Present the next available tasks.

## End Session

When the user says `end session`: update `current_state/project_status.md` and `current_state/milestone.md` to reflect completed work. Follow the project's documentation sync rules.

## Documentation Sync

When `project_status.md` changes, sync the matching docs (README.md, architecture docs, deployment docs, etc. — as defined by your project's conventions).

Update `PROJECT.md` only if structure, stack, or architecture changed.

## Git Workflow

- Feature branches from `development`. Never commit directly to `development` or `main`.
- Atomic task branch check: before starting work, verify current branch semantically matches the task. If not, stash uncommitted changes, create `feat/<name>` from `development`, pop stash.
- Commit format: `type: concise subject` — types are `fix:`, `feat:`, `refactor:`, `docs:`, `chore:`.
- Never add AI assistant credits to commit messages or PR descriptions.
- After PR merge: `git switch development`, `git pull`, `git branch -d feat/<name>`.
- After every task, ask: "Would this work on a fresh machine with only committed files?" If no → close the loop before marking the task done.

## User Confirmation

- **Never commit without user confirmation** — wait for "OK", "yes", "commit it", etc. Exception: `/vibe-code` sessions pre-approve all commits.
- Never push to any remote without confirmation.
- Never run destructive commands (`rm`, `sudo`, database drops, production deploys) without approval.
- Never delete files or directories without confirmation.

## Testing

<!-- CUSTOMIZE: Replace with your project's test command -->
```bash
docker exec <service_name> uv run pytest tests -rAq --tb=no
```

For single test files: add `--tb=short`. For failing tests: re-run the specific test with `--tb=short` to get the traceback.

## Python Dependencies

Always use `uv add` / `uv remove` — never edit `pyproject.toml` by hand:
- `uv add "pkg>=version"` — adds to pyproject.toml, updates uv.lock, installs
- `uv remove pkg` — removes from pyproject.toml, updates uv.lock, uninstalls
- Never use `uv pip install` as a substitute for `uv add`

## Cross-Project Issues

When a bug originates in a different repo: **never edit, create, or delete files in the other repo** — not even a one-line fix. Append a note to that repo's `archive/crucial_notes.md` with the bug, root cause, and fix. Use `🔲 (PRIORITY) description` markers for actionable items. Only make changes when the user explicitly asks to switch repos.

## Project-Type Standards

When working on backend tasks, read `.claude/rules/backend-standards.md`.
When working on frontend tasks, read `.claude/rules/frontend-standards.md`.
When working on DevOps tasks, read `.claude/rules/devops-standards.md`.

Read these on-demand in their respective domains — not all at session start.

## Directory-Specific Rules

If your project has subdirectory AGENTS.md files (`app/AGENTS.md`, `nginx/AGENTS.md`, etc.), Hermes loads them lazily when entering those directories. Use them for domain-specific rules that don't belong in the root AGENTS.md.
