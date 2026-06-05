---
name: start-local-dev
description: Use when the user invokes "/start-local-dev" or asks to scaffold a new local development project. Creates all boilerplate files for the selected stack in the current working directory.
version: 1.2.0
---

# Start Local Dev

Scaffold a new local development project. Language-agnostic; currently supports the `python-fastapi` and `node-typescript-express` stacks.

## When This Skill Applies

- User invokes `/start-local-dev`
- User asks to "scaffold a new project", "set up a new local project", "create project boilerplate"

## Integration with `/technical-consultant`

If the user has completed a `/technical-consultant tech-stack` session, a `TECH_STACK.md` file may exist in the working directory. If it does:
1. Read it before asking any questions
2. Pre-fill the stack choice and project details from it
3. Tell the user: "I found `TECH_STACK.md` from your consultant session. I'll use that to scaffold the project. Confirm the details below before I proceed."

## Supported Stacks

| Stack | Status |
|-------|--------|
| `python-fastapi` | ✅ Supported |
| `node-typescript-express` | ✅ Supported |
| `react` | 🔜 Not yet supported |
| `devops` | 🔜 Not yet supported |

If user requests an unsupported stack, say: "That stack is not yet supported. You can add it to `~/.claude/skills/start-local-dev/SKILL.md`."

---

## Instructions for Agent

### Step 1: Check for Consultant Output Files

Before asking anything:
- Check if `TECH_STACK.md` exists → read it, extract: project name, stack, one-line description, and tech decisions
- Check if `PROJECT_BRIEF.md` exists → read it, extract: project description, problem, users, market, scope, differentiator

These are interim documents from `/technical-consultant`. Their content will be absorbed into `PROJECT.md`, `README.md`, and `DOCKER_SETUP.md` during scaffolding. After scaffolding, offer to archive or delete them.

### Step 2: Research Latest Tools (MANDATORY — Before Creating Any Files)

**Spawn exactly ONE `Explore` sub-agent** to research all tool decisions in a single call. Do NOT spawn multiple agents. The Explore agent uses WebSearch and WebFetch — it does not need shell commands like `curl`.

Sub-agent prompt template:
```
Research the latest stable tools for a [stack] project as of today. Return a concise summary covering:
1. Latest stable Python/Node version
2. Best package manager (uv / pnpm / bun — current recommendation)
3. Best test runner (pytest / vitest / jest — current recommendation)
4. Best linter/formatter (ruff / eslint+prettier — current recommendation)
5. Any breaking changes or deprecations in the last 6 months worth knowing
6. Correct PyPI package names for common packages (e.g. is it "py-fsrs" or "fsrs"?)

Return facts only. Under 300 words.
```

Accept the summary and use it to decide the actual tools. Do NOT assume last year's recommendations are still current.

### Step 3: Ask User

Ask these questions (all at once, skipping any already known from consultant files):

1. **Project name** — used for directory names, Docker image tags, `/etc/hosts` entry (e.g., `my-project`)
2. **One-line description** — used in README and PROJECT.md
3. **Stack** — `python-fastapi`, `node-typescript-express` (or other; see Supported Stacks above)
4. **Docker?** — Yes (default) or No. If yes, Docker-related files are included. If no, skip them.
5. **External microservices?** — List any services this project talks to that live in separate Docker projects (e.g., a chatbot, a worker). These are NOT added to this project's `docker-compose.dev.yml` — only their connection URLs go into `.env.example`.

### Step 4: Confirm Working Directory

Tell the user: "I'll create files in the current directory: `<cwd>`. Is that correct?"

Wait for confirmation before creating files.

### Step 5: Create All Files

Create every file in the standard project structure below, then the stack-specific files. Use the project name, description, and latest tools from Step 2.

**Standard project structure (every project, every stack):**
- `CLAUDE.md` — minimal: project type + project-specific rules only
- `PROJECT.md` — navigation hub; absorb `PROJECT_BRIEF.md` + `TECH_STACK.md` content if available
- `README.md` — external docs; absorb summary sections from `PROJECT_BRIEF.md` if available
- `DOCKER_SETUP.md` — Docker/infra guide; absorb infra decisions from `TECH_STACK.md` if available *(skip if user said No Docker)*
- `.claude/settings.local.json` — project-specific Claude settings (empty object `{}` to start)
- `current_state/project_status.md` — task summary and roadmap
- `current_state/milestone.md` — completed task archive
- `archive/daily_log.md` — session log
- `docs/error_log.md` — debugging investigations
- `.env.example` — all required env vars with placeholder values; always committed; never contains real values

### Step 5b: Create .claude/rules/ Symlinks (Run Autonomously)

After creating the standard files, ask the user which standards apply to this project:

- Backend APIs, database, auth, background jobs → `backend-standards.md`
- Docker, CI/CD, Kubernetes, deployment → `devops-standards.md`
- Frontend components, state, UI → `frontend-standards.md`

For each selected standard, **run the symlink command directly using the Bash tool** — do NOT print these for the user to run manually.

```bash
# Run from the project root using absolute paths:
ln -sf "/Users/monireach/Library/CloudStorage/GoogleDrive-sebastian.tang168@gmail.com/My Drive/monireach/resources/agent_core/rules/project-types/backend-standards.md" ".claude/rules/backend-standards.md"
```

Verify each symlink was created with `ls -la .claude/rules/`.

### Step 6: Execute Post-Setup Steps Autonomously

After all files are created, execute every setup step using tools. Do NOT print a manual checklist. Ask for permission as you normally would for each tool call. Steps:

1. **`git init`** — run via Bash if no `.git` directory exists

2. **Generate secret keys** — if the project uses JWT, create `scripts/gen_keys.sh` first, then run it:
   ```bash
   #!/usr/bin/env bash
   # Generate EdDSA (Ed25519) key pair for JWT signing
   PRIVATE_KEY=$(openssl genpkey -algorithm ed25519 2>/dev/null | base64 | tr -d '\n')
   PUBLIC_KEY=$(openssl genpkey -algorithm ed25519 2>/dev/null | openssl pkey -pubout 2>/dev/null | base64 | tr -d '\n')
   echo "JWT_PRIVATE_KEY=${PRIVATE_KEY}"
   echo "JWT_PUBLIC_KEY=${PUBLIC_KEY}"
   ```
   Run it: `bash scripts/gen_keys.sh` and capture the output into `.env`.
   If the project does NOT use JWT (nothing in `.env.example` mentions JWT), skip this step.

3. **Copy `.env.example` → `.env`** — copy the example file, then substitute real generated values (e.g., JWT keys) into the `.env` copy.

4. **[python-fastapi only] Initialize Alembic** — if the stack is `python-fastapi` and `alembic/` does not yet exist, initialize it BEFORE building the Docker image (the Dockerfile COPYs it):
   ```bash
   uv run alembic init alembic
   ```
   This creates `alembic/` and `alembic.ini` at the project root. Skip entirely for non-Python stacks.

5. **`make rebuild`** — now that the Makefile exists, use it: `make rebuild` (equivalent to `docker compose up -d --build --force-recreate`)

6. **Verify containers** — run `make dev` then `docker compose --env-file .env -f docker-compose.dev.yml ps` and confirm all are healthy

7. **[python-fastapi only] Run migrations** — after containers are healthy: `make migrate`. Skip for non-Python stacks (each stack has its own migration approach).

8. **Create any required resources** — e.g., MinIO bucket: `docker exec <project>-minio-1 mc alias set local http://localhost:9000 admin admin && docker exec <project>-minio-1 mc mb local/<project> --ignore-existing`

9. **`/etc/hosts` entries** — you CANNOT run `sudo` commands. Print the exact command for the user to run:
   ```bash
   sudo sh -c 'echo "127.0.0.1 <project>.local api.<project>.local mail.<project>.local" >> /etc/hosts'
   ```

---

## Docker Rules (MANDATORY — Applies to All Compose Files)

**These rules are absolute. Never deviate.**

### Rule 1: Never expose ports
Never use `ports:` in any `docker-compose.*.yml` file, for any environment (dev, staging, prod).
All port access is through the pre-existing `nginx-proxy` container on `proxy-network`.

✅ Correct:
```yaml
expose:
  - "8000"
```
❌ Wrong:
```yaml
ports:
  - "8000:8000"
```

### Rule 2: HTTP services always join proxy-network
Every service that receives HTTP traffic must:
1. Declare `VIRTUAL_HOST` and `VIRTUAL_PORT` environment variables
2. Join both the project-internal network AND `proxy-network`

```yaml
environment:
  VIRTUAL_HOST: api.<project>.local
  VIRTUAL_PORT: "8000"
networks:
  - <project>-net
  - proxy-network
```

Infrastructure services (postgres, redis) that receive NO direct HTTP traffic stay on the internal network only.

### Rule 3: proxy-network is always external
```yaml
networks:
  <project>-net:
    driver: bridge
  proxy-network:
    external: true   # pre-existing nginx-proxy network
```

### Rule 4: Never define external microservices inside this project's compose
If this project communicates with a service that lives in a separate Docker project (e.g., a chatbot microservice), do NOT add it to this compose file. Only add its URL to `.env.example` as a connection variable. The connection works because both containers share `proxy-network`.

```env
# .env.example — external microservice connection
CHATBOT_INTERNAL_URL=http://<chatbot-container-name>:8000
```

### Rule 5: Profiling tools use Docker profiles
Optional dev tools (pgAdmin, Redis Commander, Flower) go under `profiles: [tools]` so they don't start by default.

```yaml
pgadmin:
  profiles: [tools]
  ...
```

Start with tools: `make dev` (uses `--profile tools`)
Start without tools: `make dev-no-tools`

---

## Environment File Conventions

| File | Purpose | Committed? |
|------|---------|-----------|
| `.env.example` | Documents all vars with placeholder values | ✅ Yes — always |
| `.env` | Local dev actual values (generated from example) | ❌ No — gitignored |
| `.env.staging` | Staging values | ❌ No — gitignored |
| `.env.prod` | Production values | ❌ No — gitignored |

**Never use `.env.local`, `.env.development`, `.env.test`** — these names add confusion. The convention is `.env` for local dev, period.

---

## File Purpose Quick Reference

Before creating any file, understand what each one is for. Full rules in `documentation-structure.md §10.2`.

| File | Audience | Question it answers | Must NOT contain |
|---|---|---|---|
| `PROJECT.md` | Internal (Claude + developer) | "Where is everything and what's the current state?" | Setup instructions, API examples, anything for external readers |
| `README.md` | External (recruiters, collaborators) | "What is this and how do I use it?" | Internal file navigation, task lists, architecture reasoning |
| `DOCKER_SETUP.md` | Internal (developer / ops) | "How do I run and configure this with Docker?" | Business logic, feature descriptions |
| `CLAUDE.md` | Claude only | "What type of project is this and what rules apply?" | Universal rules verbatim, personal names, absolute paths with personal info |
| `current_state/project_status.md` | Internal | "What's done, what's active, what's next?" | Completed task details (those go in milestone.md) |
| `current_state/milestone.md` | Internal | "What exactly was built in each completed task?" | Active tasks or backlog |
| `archive/daily_log.md` | Internal | "What happened in each session?" | Routine commands or minor steps |
| `docs/error_log.md` | Internal | "What bugs required deep investigation?" | Simple one-line fixes |

---

## Stack Spec: python-fastapi

### Files to Create

#### Project Meta

**`CLAUDE.md`**
```markdown
# CLAUDE.md — <Project Name>

## Project Type
`coding`

---

## Session Initialization

At session start (`initialize`), read in order:
1. `PROJECT.md` — navigation hub
2. `current_state/project_status.md` — current progress, next steps

Also read as work demands:
- `current_state/milestone.md` — full details on completed tasks
- `DOCKER_SETUP.md` — Docker, env vars, deployment

Rule: verify in `project_status.md` before assuming something is built.

---

## End Session

Follow `logging-workflow.md §2.5`. Additionally:
- Update `current_state/project_status.md` (symbol rule, milestone.md, grep for task name)
- Update `PROJECT.md` only if structure/stack/architecture changed

## Doc Sync Rule

| Changed in `project_status.md` | Sync target |
|---|---|
| Task completed | `current_state/milestone.md` |
| Features, API, tech stack, roadmap | `README.md` |
| Deployment, env vars | `DOCKER_SETUP.md` |
```

**`PROJECT.md`**
```markdown
# PROJECT.md — <Project Name>

Navigation hub. Read this first every session.

## What This Project Is

<One-line description from PROJECT_BRIEF.md if available, otherwise from user>

## Current Focus

🔄 [Active task — link to spec or project_status.md]

## Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| Language | Python 3.x | |
| Framework | FastAPI | |
| Package manager | uv | |
| Database | PostgreSQL | |
| Cache | — | |
| Infra | Docker + nginx-proxy | |
| CI/CD | GitHub Actions | |

[Expand this table from TECH_STACK.md if available]

## Directory Structure

```
<project-name>/
├── .claude/
│   ├── rules/           # Project-specific standards (symlinks)
│   └── settings.local.json
├── .github/
│   └── workflows/
│       └── ci.yml
├── alembic/             # Created by `uv run alembic init alembic` in Step 6
│   ├── env.py
│   └── versions/
├── app/
│   ├── main.py          # FastAPI app entry point
│   ├── middleware/
│   ├── models/
│   ├── routers/
│   ├── schemas/
│   ├── services/
│   └── utils/
│       └── config.py
├── tests/
├── scripts/
│   └── gen_keys.sh      # JWT key generation (created by Step 6 if JWT is used)
├── current_state/
│   ├── project_status.md
│   └── milestone.md
├── archive/
│   └── daily_log.md
├── docs/
│   └── error_log.md
├── alembic.ini          # Created by `uv run alembic init alembic` in Step 6
├── CLAUDE.md
├── DOCKER_SETUP.md
├── Dockerfile
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── Makefile
├── pyproject.toml
├── .python-version
├── .env.example
└── README.md
```

## Context Loading Guide

| Situation | Read |
|-----------|------|
| Resuming work | `archive/daily_log.md` (last 50 lines) |
| Checking task status | `current_state/project_status.md` |
| Completed task details | `current_state/milestone.md` |
| Architecture questions | This file + `app/main.py` |
| Docker/env vars | `DOCKER_SETUP.md` |

## Key Commands

```bash
make dev           # Start dev environment (with profiling tools)
make dev-no-tools  # Start without tools
make down          # Stop
make logs          # Follow backend logs
make test          # Run tests
make shell         # Shell into backend container
```

## Where to Find Things

| Topic | File |
|---|---|
| Active tasks | `current_state/project_status.md` |
| Completed tasks | `current_state/milestone.md` |
| Session history | `archive/daily_log.md` |
| Debug investigations | `docs/error_log.md` |
| Docker setup | `DOCKER_SETUP.md` |
```

---

#### Logs & State

**`archive/daily_log.md`**
```markdown
# Daily Log

## <YYYY-MM-DD>

- Project initialized with /start-local-dev skill (python-fastapi stack)
```

**`current_state/project_status.md`**
```markdown
# Project Status

**Last Updated:** <YYYY-MM-DD>

---

## Completed Milestones

| Milestone | Date | Tests |
|-----------|------|-------|
| Project scaffold | <YYYY-MM-DD> | — |

---

## 🔄 Active Tasks

_None yet — add tasks here as work begins_

## 🔲 Backlog

- Implement first feature
- Set up database models
- Add authentication (if needed)
```

**`current_state/milestone.md`**
```markdown
# Completed Milestones

**Last Updated:** <YYYY-MM-DD>

> Full details of every completed task. For active tasks and roadmap, see `current_state/project_status.md`.

---

## Quick Reference

| Milestone | Completed | Tests |
|-----------|-----------|-------|
| Project scaffold | <YYYY-MM-DD> | — |

---

## ✅ Project Scaffold (<YYYY-MM-DD>)

- ✅ Boilerplate created with `/start-local-dev` (python-fastapi stack)
- ✅ Docker multi-stage build (development + production)
- ✅ GitHub Actions CI (test on push/PR)

**Final state:** No tests yet — scaffold only
```

**`docs/error_log.md`**
```markdown
# Error Log

> Debugging investigations — errors that required diagnosis, multiple attempts, and a non-obvious fix.
> Use `/log-error` skill to add entries.

---

## Index

| Date | Error | Root Cause | File |
|------|-------|------------|------|
```

**`.claude/settings.local.json`**
```json
{}
```

---

#### Environment Files

**`.env.example`**
```env
# Application
APP_NAME=<project-name>
APP_ENV=development
DEBUG=true

# Server
HOST=0.0.0.0
PORT=8000

# Database
# Uses <project-name>-postgres alias (not "postgres") to avoid DNS conflicts
# when multiple compose projects share proxy-network
DATABASE_URL=postgresql+asyncpg://postgres:postgres@<project-name>-postgres:5432/<project_name>_dev

# CORS — must be a JSON array (pydantic-settings v2 decodes list[str] as JSON)
CORS_ORIGINS=["http://<project-name>.local"]

# Add project-specific variables below
```

**`.env`** *(generated from `.env.example` during setup — not committed)*
```env
APP_NAME=<project-name>
APP_ENV=development
DEBUG=true
HOST=0.0.0.0
PORT=8000
DATABASE_URL=postgresql+asyncpg://postgres:postgres@<project-name>-postgres:5432/<project_name>_dev
CORS_ORIGINS=["http://<project-name>.local"]
```

**`.env.staging`** *(not committed)*
```env
APP_NAME=<project-name>
APP_ENV=staging
DEBUG=false
HOST=0.0.0.0
PORT=8000
DATABASE_URL=postgresql+asyncpg://postgres:CHANGE_ME@<project-name>-postgres:5432/<project_name>_staging
CORS_ORIGINS=["https://<project-name>-staging.example.com"]
```

**`.env.prod`** *(not committed)*
```env
APP_NAME=<project-name>
APP_ENV=production
DEBUG=false
HOST=0.0.0.0
PORT=8000
DATABASE_URL=
CORS_ORIGINS=[]
```

---

#### Python Config

**`.python-version`**
```
3.13
```

**`pyproject.toml`**
```toml
[project]
name = "<project-name>"
version = "0.1.0"
description = "<One-line description>"
requires-python = ">=3.13"
dependencies = [
    "fastapi>=0.115.0",
    "uvicorn[standard]>=0.30.0",
    "sqlalchemy[asyncio]>=2.0.0",
    "asyncpg>=0.29.0",
    "alembic>=1.13.0",
    "pydantic>=2.0.0",
    "pydantic-settings>=2.0.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["app"]

[dependency-groups]
dev = [
    "pytest>=8.0.0",
    "httpx>=0.27.0",
    "pytest-asyncio>=0.23.0",
    "ruff>=0.4.0",
    "mypy>=1.10.0",
]

[tool.ruff]
line-length = 100
target-version = "py313"

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM"]
ignore = ["E501"]

[tool.mypy]
python_version = "3.13"
strict = true

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

**Key pyproject.toml rules:**
- Always use `[dependency-groups] dev` — NOT `[tool.uv] dev-dependencies` (deprecated)
- Always add `[tool.hatch.build.targets.wheel] packages = ["app"]` — hatchling cannot auto-detect the package when the directory is named `app` instead of the project name
- Verify PyPI package names with the research sub-agent — GitHub repo names and PyPI names differ (e.g., GitHub `py-fsrs` → PyPI `fsrs`)

---

#### Application Code

**`app/__init__.py`**
```python
```

**`app/main.py`**
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.utils.config import settings

app = FastAPI(title="<Project Name>")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok"}
```

**`app/utils/__init__.py`**
```python
```

**`app/utils/config.py`**
```python
import json
import os
from pydantic import field_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "<project-name>"
    app_env: str = "development"
    debug: bool = True
    host: str = "0.0.0.0"
    port: int = 8000
    database_url: str = ""
    cors_origins: list[str] = ["http://localhost:3000"]

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, v: object) -> list[str] | object:
        """Accept both JSON arrays and comma-separated strings.
        Required because pydantic-settings v2 tries json.loads() on list[str]
        fields before calling validators — use JSON array format in env files.
        """
        if isinstance(v, str):
            stripped = v.strip()
            if stripped.startswith("["):
                return json.loads(stripped)
            return [o.strip() for o in stripped.split(",") if o.strip()]
        return v

    model_config = {
        "env_file": ".env" if os.getenv("APP_ENV", "development") == "development"
                    else f".env.{os.getenv('APP_ENV')}",
        "env_file_encoding": "utf-8",
        "case_sensitive": False,
    }


settings = Settings()
```

---

#### Tests

**`tests/__init__.py`**
```python
```

---

#### Docker & Infrastructure

**`Dockerfile`**
```dockerfile
# ── Base ──────────────────────────────────────────────────────────────────────
FROM python:3.13-slim AS base

WORKDIR /app

RUN pip install uv

# Install production dependencies first (cached layer)
COPY pyproject.toml .
RUN uv sync --no-dev

# Copy application code
COPY app/ app/

# Copy Alembic migrations (needed for `make migrate` inside container)
# If this project does not use Alembic, remove these two lines
COPY alembic/ alembic/
COPY alembic.ini .

# ── Development ───────────────────────────────────────────────────────────────
FROM base AS development

# Install dev dependencies
RUN uv sync

EXPOSE 8000
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# ── Production ────────────────────────────────────────────────────────────────
FROM base AS production

# Non-root user (devops-standards §2)
RUN addgroup --system --gid 1001 appgroup && adduser --system --uid 1001 appuser
USER appuser

COPY scripts/start.sh /start.sh
EXPOSE 8000
# Use a startup script — exec replaces sh so SIGTERM reaches uvicorn directly
CMD ["/start.sh"]
```

**`scripts/start.sh`**
```bash
#!/usr/bin/env sh
# Production startup: run migrations then start server.
# Using exec so SIGTERM reaches uvicorn directly (not trapped by sh -c).
set -e
uv run alembic upgrade head
exec uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 2
```

**Dockerfile rules:**
- Only `COPY` files that are guaranteed to exist — never use shell tricks like `COPY file . 2>/dev/null || true` (Docker COPY is not a shell command; that syntax doesn't work)
- Alembic is in the default dependencies — always copy `alembic/` and `alembic.ini`; note that `alembic.ini` lives at the project root (next to `pyproject.toml`), NOT inside `alembic/`
- `COPY alembic/ alembic/` copies the migrations directory; `COPY alembic.ini .` copies the config file separately — both are required; do NOT try to get `alembic.ini` from a second `COPY alembic/ alembic/` call

**`docker-compose.dev.yml`**
```yaml
name: <project-name>

services:

  # ── Application ─────────────────────────────────────────────────────────────

  backend:
    build:
      context: .
      target: development
    env_file: .env
    environment:
      VIRTUAL_HOST: api.<project-name>.local
      VIRTUAL_PORT: "8000"
    volumes:
      - ./app:/app/app
    expose:
      - "8000"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - <project-name>-net
      - proxy-network
    restart: unless-stopped

  # ── Infrastructure ───────────────────────────────────────────────────────────

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: <project_name>_dev
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      <project-name>-net:
        aliases:
          - <project-name>-postgres  # unique alias prevents DNS conflicts when multiple projects share proxy-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d <project_name>_dev"]
      interval: 5s
      timeout: 5s
      retries: 10

  # ── Profiling Tools (make dev — --profile tools) ─────────────────────────────

  pgadmin:
    image: dpage/pgadmin4:latest
    profiles: [tools]
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@<project-name>.local
      PGADMIN_DEFAULT_PASSWORD: admin
      VIRTUAL_HOST: pgadmin.<project-name>.local
      VIRTUAL_PORT: "80"
    expose:
      - "80"
    networks:
      - <project-name>-net
      - proxy-network

volumes:
  postgres-data:

networks:
  <project-name>-net:
    driver: bridge
  proxy-network:
    external: true   # pre-existing nginx-proxy network
```

**`docker-compose.prod.yml`**
```yaml
name: <project-name>

services:

  backend:
    build:
      context: .
      target: production
    env_file: .env.prod
    environment:
      VIRTUAL_HOST: api.<project-name>.com
      VIRTUAL_PORT: "8000"
    expose:
      - "8000"
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - <project-name>-net
      - proxy-network

  postgres:
    image: postgres:16-alpine
    env_file: .env.prod
    volumes:
      - postgres-data:/var/lib/postgresql/data
    restart: unless-stopped
    networks:
      - <project-name>-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-postgres}"]
      interval: 5s
      timeout: 5s
      retries: 10

volumes:
  postgres-data:

networks:
  <project-name>-net:
    driver: bridge
  proxy-network:
    external: true
```

**`DOCKER_SETUP.md`**
```markdown
# Docker Setup — <Project Name>

---

## Table of Contents

1. [Local Dev Services](#local-dev-services)
2. [Quick Start](#quick-start)
3. [Makefile Reference](#makefile-reference)
4. [Environment Variables](#environment-variables)
5. [Migrations](#migrations)
6. [Troubleshooting](#troubleshooting)

---

## Local Dev Services

`make dev` starts the following services:

| Service | Image | Purpose |
|---|---|---|
| `backend` | `./Dockerfile` (dev target) | FastAPI app |
| `postgres` | `postgres:16-alpine` | PostgreSQL 16 |
| `pgadmin` | `dpage/pgadmin4` | DB admin UI (tools profile) |

**No ports are exposed to the host.** All HTTP traffic is routed through the pre-existing `nginx-proxy` container on `proxy-network`. Each service declares `VIRTUAL_HOST` + `VIRTUAL_PORT`.

---

## Quick Start

```bash
# First time
cp .env.example .env
# Fill in required values (API keys, secrets)
make dev

# Daily
make dev              # start with profiling tools
make dev-no-tools     # start without tools
make down             # stop
make clean            # stop + wipe volumes (fresh database)
```

Add to `/etc/hosts` (one time):
```bash
sudo sh -c 'echo "127.0.0.1 <project-name>.local api.<project-name>.local pgadmin.<project-name>.local" >> /etc/hosts'
```

---

## Makefile Reference

| Command | Description |
|---|---|
| `make dev` | Start dev environment with profiling tools |
| `make dev-no-tools` | Start without tools |
| `make down` | Stop all services |
| `make restart` | Restart all services |
| `make rebuild` | Rebuild images + recreate containers |
| `make logs` | Follow backend logs (real-time) |
| `make logs-all` | Follow all logs (real-time) |
| `make migrate` | Apply pending Alembic migrations |
| `make migration name=desc` | Create new Alembic migration |
| `make shell` | Shell into backend container |
| `make test` | Run pytest |
| `make lint` | Run ruff |
| `make clean` | Stop + wipe volumes |

---

## Environment Variables

Copy `.env.example` to `.env` for local dev.

| File | Environment | Committed |
|---|---|---|
| `.env.example` | Template | ✅ Yes |
| `.env` | Local dev | ❌ No |
| `.env.staging` | Staging | ❌ No |
| `.env.prod` | Production | ❌ No |

---

## Migrations

```bash
make migrate                    # Apply all pending migrations
make migration name=add_users   # Create a new migration
docker compose exec backend uv run alembic downgrade -1  # Rollback one step
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Backend can't connect to postgres | Postgres takes a few seconds; backend has `depends_on` with health check |
| nginx-proxy not routing | Verify `proxy-network` exists: `docker network ls \| grep proxy` |
| Container exits immediately | Check logs: `make logs` |
```

**`Makefile`**
```makefile
# ============================================================================
# MAKEFILE — <Project Name>
# ============================================================================
# Usage:
#   make dev            - Start dev environment with profiling tools
#   make dev-no-tools   - Start dev environment without tools
#   make down           - Stop all services
#   make restart        - Restart all services
#   make rebuild        - Rebuild images and recreate containers
#   make logs           - Follow backend logs (real-time)
#   make logs-all       - Follow all service logs (real-time)
#   make logs-be        - Backend logs (last 50 lines)
#   make logs-db        - PostgreSQL logs (last 50 lines)
#   make migrate        - Apply pending Alembic migrations
#   make migration      - Create new migration (usage: make migration name=desc)
#   make shell          - Shell into backend container
#   make test           - Run tests
#   make lint           - Run ruff linter
#   make clean          - Stop and remove volumes (fresh database)
# ============================================================================

ENV_FILE  := .env
COMPOSE_FILE := docker-compose.dev.yml

# ============================================================================
# DEVELOPMENT ENVIRONMENT
# ============================================================================

dev:
	@echo "Starting development environment with tools..."
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) --profile tools up -d

dev-no-tools:
	@echo "Starting development environment..."
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) up -d

down:
	@echo "Stopping all services..."
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) --profile tools down

restart:
	@echo "Restarting all services..."
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) --profile tools restart

rebuild:
	@echo "Rebuilding images and recreating containers..."
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) --profile tools up -d --build --force-recreate

# ============================================================================
# LOGS
# ============================================================================

logs:
	@echo "Following backend logs (Ctrl+C to stop)..."
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) logs -f backend

logs-all:
	@echo "Following all service logs (Ctrl+C to stop)..."
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) --profile tools logs -f

logs-be:
	@echo "Backend logs (last 50 lines):"
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) logs --tail 50 backend

logs-db:
	@echo "PostgreSQL logs (last 50 lines):"
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) logs --tail 50 postgres

# ============================================================================
# DATABASE
# ============================================================================

migrate:
	@echo "Applying database migrations..."
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) exec backend uv run alembic upgrade head

migration:
	@echo "Creating migration: $(name)"
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) exec backend uv run alembic revision --autogenerate -m "$(name)"

clean:
	@echo "Stopping services and removing volumes..."
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) --profile tools down -v

# ============================================================================
# DEVELOPMENT TOOLS
# ============================================================================

shell:
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) exec backend bash

test:
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) exec backend uv run pytest tests/ -v

lint:
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) exec backend uv run ruff check app/

# ============================================================================
# HELP
# ============================================================================

help:
	@echo "Available commands:"
	@echo ""
	@echo "Development:"
	@echo "  make dev            - Start dev environment with tools"
	@echo "  make dev-no-tools   - Start dev without tools"
	@echo "  make down           - Stop all services"
	@echo "  make restart        - Restart all services"
	@echo "  make rebuild        - Rebuild images and recreate containers"
	@echo ""
	@echo "Logs:"
	@echo "  make logs           - Follow backend logs (real-time)"
	@echo "  make logs-all       - Follow all service logs (real-time)"
	@echo "  make logs-be        - Backend logs (last 50 lines)"
	@echo "  make logs-db        - PostgreSQL logs (last 50 lines)"
	@echo ""
	@echo "Database:"
	@echo "  make migrate        - Apply pending migrations"
	@echo "  make migration name=<desc>  - Create new migration"
	@echo "  make clean          - Stop and remove all volumes"
	@echo ""
	@echo "Tools:"
	@echo "  make shell          - Shell into backend container"
	@echo "  make test           - Run pytest"
	@echo "  make lint           - Run ruff linter"

.PHONY: dev dev-no-tools down restart rebuild logs logs-all logs-be logs-db migrate migration clean shell test lint help
```

**`.dockerignore`**
```
.git
.gitignore
.env
.env.*
!.env.example
.venv
venv
__pycache__
*.pyc
*.pyo
.pytest_cache
.coverage
htmlcov/
*.egg-info/
dist/
build/
.idea/
.vscode/
*.swp
.DS_Store
*.log
README.md
docs/
tests/
archive/
current_state/
CLAUDE.md
PROJECT.md
DOCKER_SETUP.md
Makefile
```

**`.gitignore`**
```
# ── Environment files ──────────────────────────────────────────────────────────
.env
.env.staging
.env.prod
# Keep .env.example (safe to commit — no real values)

# ── Python ─────────────────────────────────────────────────────────────────────
__pycache__/
*.py[cod]
.Python
*.egg-info/
dist/
build/
.eggs/
.venv/
venv/
env/
.uv/
.ruff_cache/
.mypy_cache/

# ── Node / Next.js ─────────────────────────────────────────────────────────────
node_modules/
.next/
out/
.vercel/
npm-debug.log*
pnpm-debug.log*
*.tsbuildinfo

# ── Testing ────────────────────────────────────────────────────────────────────
.pytest_cache/
.coverage
.coverage.*
htmlcov/
coverage/
*.xml
.jest-cache/

# ── IDE ─────────────────────────────────────────────────────────────────────────
.idea/
.vscode/
.claude/
*.swp
*.swo
*.swn

# ── macOS ──────────────────────────────────────────────────────────────────────
.DS_Store
.AppleDouble

# ── Security / Secrets ─────────────────────────────────────────────────────────
*.pem
*.key
*.crt
services/credentials/*.json
!services/credentials/.gitkeep

# ── SSL and reverse proxy ───────────────────────────────────────────────────────
nginx/ssl/
nginx/logs/

# ── Database backups ───────────────────────────────────────────────────────────
*.sql
!scripts/init-db.sql

# ── Backup files ───────────────────────────────────────────────────────────────
*_bk.*
*_backup.*
*.bak

# ── Logs ───────────────────────────────────────────────────────────────────────
*.log
logs/

# ── Archive (keep daily_log.md only) ───────────────────────────────────────────
archive/*
!archive/daily_log.md

# ── Example / learning files (not production code) ─────────────────────────────
*_examples.py
```

---

#### CI

**`.github/workflows/ci.yml`**
```yaml
name: CI

on:
  push:
    branches: [main, development]
  pull_request:
    branches: [main, development]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.13"

      - name: Install uv
        run: pip install uv

      - name: Install dependencies
        run: uv sync

      - name: Run linter
        run: uv run ruff check app/

      - name: Run tests
        run: uv run pytest tests/ -v
```

---

#### README

**`README.md`**
```markdown
# <Project Name>

<One-line description from PROJECT_BRIEF.md if available>

## Stack

- Python 3.13 + FastAPI
- PostgreSQL 16
- Docker multi-stage build (development / production)
- GitHub Actions CI

## Local Development

### Prerequisites

- Docker + Docker Compose v2
- `make`

### Setup

```bash
cp .env.example .env
# Fill in required values
make dev
```

Add to `/etc/hosts`:
```bash
sudo sh -c 'echo "127.0.0.1 <project-name>.local api.<project-name>.local" >> /etc/hosts'
```

### Common Commands

```bash
make dev       # Start
make down      # Stop
make logs      # Follow backend logs
make test      # Run tests
make migrate   # Apply DB migrations
```

## API

- Health check: `GET http://api.<project-name>.local/health`

## Roadmap

- [ ] First feature
```
