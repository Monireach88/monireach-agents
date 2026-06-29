# AGENTS.md — Smart Chatbot

These instructions are for Codex. They mirror the project-specific behavior that Claude and Gemini already get from `CLAUDE.md` and `.claude/rules/`.

Hermes also reads this file as project context. When running Hermes in this repo, treat these instructions as startup context and use `.claude/rules/` only as an on-demand reference library for deeper Claude-era standards.

## Project Scope

This project is built for three simultaneous goals:
- running a CaaS business
- building production-grade AI engineering experience
- serving as strong portfolio evidence for AI engineering roles

Learning and career ROI are first-class goals. Do not recommend shortcuts when a proper standard solution is practical and bounded.

**Hard rules for portfolio projects:** Never offer a shortcut when a standard solution exists. There is only one option: the standard. Phrases like "OK for now," "acceptable for V1," or "upgrade later" are forbidden when the correct approach is known and buildable. Never say "NO" when you mean "not yet — when X happens, do Y."

## Working Model

- Verify facts from the repo before making claims about what is built.
- Check `current_state/project_status.md` before assuming any feature exists.
- Preserve existing architecture and naming patterns unless the task explicitly changes them.
- When backend APIs change, update `current_state/project_status.md`.

## Startup-Critical Backend Rules

This project is backend-heavy. When Codex starts in the repo root, these backend rules must already be in working context:

- Cover edge cases and concurrent access in the test plan, not just the happy path.
- Keep credentials and API keys in environment variables only.
- Wrap external API calls in error handling so partial failure is recoverable.
- Keep the service stateless and avoid shared mutable state.
- Avoid N+1 queries, `SELECT *`, and blocking work on request paths.
- Use dependency injection so units remain testable without real external services.
- Validate all inputs. Client-facing errors must not expose stack traces or internals.
- Log with useful context such as `tenant_id` and `request_id`, but never log PII.
- Enforce auth by default and perform object-level ownership checks on every resource access.
- Preserve tenant isolation at the data layer.
- Never pass unfiltered `**kwargs` into model constructors.
- Be explicit about units at API and storage boundaries.
- Any change touching balances, usage, billing, auth, API keys, sessions, or admin access is high risk and should be verified carefully.

Deeper file-specific guidance still lives in `app/AGENTS.md`, `alembic/AGENTS.md`, and `nginx/AGENTS.md`.

## Initialization

When the user says `initialize` for this project:

1. Read `PROJECT.md`.
2. Read `current_state/project_status.md`.
3. Run `grep -n '^### ✅' current_state/project_status.md`.
   Expected result: no output.
4. Read only the project-specific supplemental files relevant to the current task:
   - `current_state/milestone.md`
   - `docs/security_architecture.md`
   - `docs/frontend_architecture.md`
   - `docs/khmer_llm_strategy.md`
   - `DOCKER_SETUP.md`
5. If `archive/crucial_notes.md` exists, run `grep -n '🔲' archive/crucial_notes.md` and inspect every match before concluding whether any item is actionable.
6. Present the next available tasks to the user.

## Documentation Sync

When `project_status.md` changes, sync the matching docs:

- completed task -> `current_state/milestone.md`
- features, API, tech stack, roadmap -> `README.md`
- frontend approach -> `docs/frontend_architecture.md`
- auth, LLM, tenant isolation -> `docs/security_architecture.md`
- admin console scope -> `~/projects/smart_chatbot_admin_console/current_state/project_status.md`
- LLM or Khmer strategy -> `docs/khmer_llm_strategy.md`
- deployment and env vars -> `DOCKER_SETUP.md`

Update `PROJECT.md` only if structure, stack, or architecture changed.

## Testing

- Always run the full test suite inside Docker, never on the host.
- Official command:

```bash
docker exec chatbot_backend_dev uv run pytest tests -rAq --tb=no
```

- Host `uv run pytest` is not authoritative for this repo because some tests require Docker-network service names such as `qdrant:6333`.

## Directory-Specific Rules

- `app/AGENTS.md` contains shared Python backend rules.
- `alembic/AGENTS.md` contains shared migration workflow rules.
- `nginx/AGENTS.md` contains shared deployment and infra rules.

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
