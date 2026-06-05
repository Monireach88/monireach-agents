# AGENTS.md — hermes-ops

## Project Purpose

This project manages the user's containerized Hermes Agent setup on macOS.

Hermes runs in Docker, not directly on the host. The long-running container is `org_agent_hermes`.

## Key Paths

- Project: `/Users/monireach/projects/hermes-ops`
- Compose file: `/Users/monireach/projects/hermes-ops/docker-compose.yml`
- Host persistence: `/Users/monireach/hermes_configs`
- Hermes home inside container: `/opt/data/.hermes`
- Hermes config on host: `/Users/monireach/hermes_configs/.hermes/config.yaml`
- Hermes secrets on host: `/Users/monireach/hermes_configs/.hermes/.env`
- Shared agent core: `/Users/monireach/Library/CloudStorage/GoogleDrive-sebastian.tang168@gmail.com/My Drive/monireach/resources/agent_core`

## Runtime Model

- Default provider: DeepSeek
- Default model: `deepseek-v4-pro`
- Advisor/fallback provider: OpenAI Codex via ChatGPT OAuth
- Advisor/fallback model: `gpt-5.5`

Do not suggest OpenAI API billing for Codex unless the user explicitly asks for API-key based OpenAI access.

## Commands

Start Hermes:

```bash
docker compose up -d
```

Open Hermes CLI:

```bash
./hermes
```

Check status:

```bash
./hermes status
```

Validate Compose:

```bash
docker compose config --quiet
```

## Context And Skills

Hermes should use native context files for startup rules:

- `SOUL.md` for global identity and communication behavior
- `AGENTS.md` for project-specific instructions
- `skills.external_dirs` for on-demand shared skills

Shared rules are mounted read-only:

- `/Users/monireach/.claude/CLAUDE.md`
- `/Users/monireach/.claude/rules`

Shared skills are mounted read-only:

- `/Users/monireach/.agents/skills`

Use these shared rule files selectively when a task needs deeper standards. Do not dump the entire rule library into memory.

## Guardrails

- Keep Hermes state persistent under `/Users/monireach/hermes_configs`.
- Keep CLI, dashboard, gateway, and Telegram using `HERMES_HOME=/opt/data/.hermes`.
- Do not edit real secrets into committed files.
- Preserve the wrapper script `./hermes`; it prevents the CLI from reading the wrong root config.
- For Telegram, keep the gateway container running with `docker compose up -d`.
