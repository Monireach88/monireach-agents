# AGENTS.md — Python Backend

These rules apply to backend work in Python services, including APIs, schemas, services, auth, billing, workers, and DB-facing business logic.

## Core Backend Standards

- Cover edge cases and concurrent access in the test plan, not just the happy path.
- Keep credentials and API keys in environment variables only.
- Design rollback or confirmation guards for irreversible operations.
- Wrap external API calls in error handling so partial failure is recoverable.
- Keep the service stateless. Avoid shared mutable state.
- Avoid N+1 queries, `SELECT *`, and blocking work on request paths.
- Use dependency injection so units remain testable without real external services.
- Validate all inputs. Client-facing errors must not expose stack traces or internals.
- Log with useful context such as domain IDs and request IDs, but never log PII.

## API Design

- Use noun-based URLs, plural collections, and hyphens instead of underscores.
- Use correct HTTP method semantics and idempotency.
- Paginate large or live datasets.
- Deprecations should be explicit and documented.

## Error Contract

- Error responses should use `application/problem+json`.
- Include machine-readable error structure.
- Include `request_id` or equivalent tracing context for support and debugging.

## Auth and Authorization

- Enforce auth by default.
- Perform object-level ownership checks on every resource access.
- Preserve tenant or account isolation at the data layer.
- Do not treat authentication alone as sufficient authorization.

## Security

- Never pass unfiltered `**kwargs` into model constructors.
- Paginate list endpoints and enforce request size limits.
- Validate any server-side fetched URL and never allow permissive credentialed CORS.
- Never commit secrets. Rotation and revocation must remain possible.

## Observability

- Prefer structured logs.
- Preserve correlation and request IDs through downstream calls and jobs.
- Health surfaces should remain available and accurate.

## Testing

- Use the project’s authoritative integration environment rather than host-only shortcuts.
- Avoid shared state between tests.
- Prefer factories and explicit setup over hidden cross-test coupling.

## High-Risk Areas

- Be explicit about units at API and storage boundaries.
- Any change touching balances, usage, billing, auth, API keys, sessions, or admin access is high risk and should be verified carefully.
