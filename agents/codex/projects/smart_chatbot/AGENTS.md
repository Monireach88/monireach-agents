# AGENTS.md — Smart Chatbot

These instructions are for Codex. They mirror the project-specific behavior that Claude and Gemini already get from `CLAUDE.md` and `.claude/rules/`.

Hermes also reads this file as project context. When running Hermes in this repo, treat these instructions as startup context and use `.claude/rules/` only as an on-demand reference library for deeper Claude-era standards.

## Project Scope

This project is built for three simultaneous goals:
- running a CaaS business
- building production-grade AI engineering experience
- serving as strong portfolio evidence for AI engineering roles

Learning and career ROI are first-class goals. Do not recommend shortcuts when a proper standard solution is practical and bounded.

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

## Claude Rule Bridge For Hermes

Hermes should not ingest every Claude rule file into memory or every prompt. When a task is affected by Claude-specific standards, inspect the relevant files in `.claude/rules/` or the shared rule mount before acting.

Use this bridge especially for:

- session initialization and end-session workflows
- documentation and logging workflows
- testing command selection
- backend, frontend, UX, DevOps, or migration standards
- user confirmation rules for commits, pushes, destructive actions, and deployments
