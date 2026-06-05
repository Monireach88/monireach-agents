# CLAUDE.md — Smart Chatbot

## Project Type
`coding`

---

## Design Philosophy

This project is built for three simultaneous goals: **running a CaaS business, finding AI Engineering jobs, and gaining production-grade experience.** Learning and career ROI are first-class goals — not side effects.

| Type | Rule |
|---|---|
| Pure optionality (config value, abstraction, named constant) | Do it now — always |
| Runtime dependency (Redis, Celery, message broker, sidecar) | Do it IF: adds learning/career value AND cost is bounded (days not weeks) AND complexity is recoverable |
| Large rewrites, multi-week integrations | Defer until the trigger condition actually hits |

Never say "NO" when you mean "Not now — when X happens, do Y." State the condition explicitly.

---

## Session Initialization

Follow `session-management.md §9.1`. Also read on demand:
- `current_state/milestone.md` — full details on completed tasks
- `docs/security_architecture.md` — auth, API keys, tenant isolation
- `docs/frontend_architecture.md` — widget or frontend decisions
- `docs/khmer_llm_strategy.md` — LLM provider or Khmer language
- `DOCKER_SETUP.md` — Docker, env vars, deployment

Rule: verify in `project_status.md` before assuming something is built.

---

## End Session

Follow `logging-workflow.md §2.5`. Additionally:
- Update `current_state/project_status.md` (symbol rule, milestone.md, grep for task name)
- Update `PROJECT.md` only if structure/stack/architecture changed
- Sync affected `current_state/` files per Doc Sync Rule below

## Doc Sync Rule

| Changed in `project_status.md` | Sync target |
|---|---|
| Task completed | `current_state/milestone.md` |
| Features, API, tech stack, roadmap | `README.md` |
| Frontend approach | `docs/frontend_architecture.md` |
| Auth, LLM, tenant isolation | `docs/security_architecture.md` |
| Admin console scope | `~/projects/smart_chatbot_admin_console/current_state/project_status.md` |
| LLM/Khmer strategy | `docs/khmer_llm_strategy.md` |
| Deployment, env vars | `DOCKER_SETUP.md` |

---

## Testing

Always run the full test suite inside the Docker container — never on the host:

```bash
docker exec chatbot_backend_dev uv run pytest tests -rAq --tb=no
```

Running `uv run pytest` on the host produces 5 false failures because those tests connect to `qdrant:6333`, which only resolves inside the Docker network. The official test count must always come from the container run. Never log a partial count like "259/264".

---

## Admin Console Sub-project

When backend APIs change, update `current_state/project_status.md`.
Admin console source of truth: `~/projects/smart_chatbot_admin_console/PROJECT.md`

