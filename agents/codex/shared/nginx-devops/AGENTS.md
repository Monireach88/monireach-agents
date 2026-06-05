# AGENTS.md — Nginx And Infra

These rules apply to `nginx/` and related deployment-facing configuration.

## DevOps Standards

- Prefer production-safe defaults over local convenience.
- Keep environment-specific behavior in config, not hardcoded application logic.
- Preserve clear separation between dev and prod concerns.
- Any networking, proxy, or header change must consider auth, CORS, rate limiting, and upstream health behavior.

## Deployment Safety

- Test changes in the project’s Dockerized or otherwise authoritative deployment-like environment before treating them as complete.
- Avoid configuration drift between compose files, proxy config, and documented setup.
- When ports, env vars, origins, or routing change, sync the project’s deployment docs.
- Preserve least-privilege and explicit allow-lists where applicable.

## Observability

- Prefer configurations that keep health checks, request tracing, and failure diagnosis possible.
- Do not silently swallow upstream failures without an intentional reason.
