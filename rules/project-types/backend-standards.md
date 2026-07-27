---
name: Backend Engineering Standards
description: Mandatory backend coding standards for this project — covers code quality, REST API design, error responses, authentication, authorization, rate limiting, caching, database design, background jobs, security (OWASP API Top 10), observability, and testing.
type: project
---

# Backend Engineering Standards

**ALL RULES BELOW ARE MANDATORY. Apply during implementation — do not defer to post-review.**

**If a section does not apply to this project, output one line: `SKIPPED §N — reason`.** A section skipped with no line is a violation. Without this, a rule that genuinely does not apply and a rule you forgot look identical.

---

## §1. Code Quality (All Layers)

### At Design / Scaffold Time

- Cover edge cases and concurrent access in the test plan — not just the happy path
- All credentials and API keys in environment variables — never hardcoded; no secrets in source files
- Irreversible operations (delete, bulk update, migration) must have rollback path or confirmation guard before implementation
- Design loading state, error state, and empty state for every async operation before writing the implementation
- Wrap every external API call in error handling; partial failure must leave the system in a recoverable state
- All config values in env vars (12-Factor App); nothing environment-specific hardcoded in application code; migrations must be reversible; service must be zero-downtime deployable
- No N+1 queries; no `SELECT *`; no synchronous blocking operations > 100ms on the main thread
- No shared mutable state; stateless service design; all queries use indexed columns at scale
- Dependencies injected — no hardwired external service calls inside business logic; all units testable without real external services
- Minimize API call count per action; identify caching opportunities before implementation

### At Refactor Time

- Errors logged with context (tenant_id, request_id) — no PII in logs; structured format
- Extract all magic values to named constants; single responsibility per function; names are self-documenting
- Functions must be usable from their signature alone; related things co-located; no leaky abstractions
- All inputs validated; error messages shown to clients must not expose stack traces or internal details

### ML-Specific (when applicable)

- Random seeds fixed; model versions pinned (never `latest`); data versioned alongside the model
- Training data must be representative of all expected user groups and languages
- Retrieval context logged; source traceable; uncertainty expressed where appropriate (applies to RAG pipelines)

---

## §2. REST API Design

- URLs use nouns, plural collections, hyphens not underscores (e.g., `/knowledge-entries`, not `/knowledgeEntries`)
- Use correct HTTP methods with correct idempotency: GET (safe + idempotent), PUT/DELETE (idempotent), POST (neither)
- Use cursor pagination for large or live datasets; offset pagination only for small or static datasets
- Announce deprecated endpoints with `Sunset` header (RFC 8594) before removal

---

## §3. Error Responses (RFC 9457)

- All error responses use `application/problem+json` format with fields: `type`, `title`, `status`, `detail`, `instance`
- Validation errors include an `errors` array; all errors include `request_id` for support triage
- Error codes must be machine-readable — clients must never need to parse error message strings

---

## §4. Authentication

- Access tokens: 5–30 minute expiry, stored in memory (not localStorage); refresh tokens: 7–30 days, HttpOnly cookie
- Signing algorithm: EdDSA > ES256 > RS256; never HS256 for distributed systems
- Refresh token rotation: every use issues a new token; token reuse triggers full session revocation
- API keys: stored hashed; scoped to permissions; rotation must be supported

---

## §5. Authorization

- Perform object-level ownership check on every resource access — not just an auth check (BOLA prevention, OWASP API1)
- Enforce Row-Level Security at the database layer for all multi-tenant data isolation
- Default deny — auth middleware applied to every endpoint; no endpoint is unauthenticated by default

---

## §6. Rate Limiting

- Use sliding window algorithm (no boundary exploit vulnerabilities)
- Layered limits: per-IP + per-API-key + per-tenant + per-endpoint
- Always return rate limit headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`, `Retry-After`

---

## §7. Caching

- Use cache-aside (lazy loading) pattern for read-heavy workloads
- Prevent cache stampede: use distributed lock or add jitter to TTL expiry
- Implement HTTP caching with `Cache-Control` and `ETag` + `If-None-Match`

---

## §8. Database Design

- New projects use UUIDv7 (time-sortable) as primary keys; auto-increment only for internal-only tables
- Index every foreign key; use partial indexes for soft-deleted tables
- Never lazy-load in loops — use eager loading or batch queries to prevent N+1
- Soft deletes: `deleted_at` column; audit trail: `created_at`, `updated_at`, `created_by`, `updated_by`
- Use PgBouncer connection pooling for PostgreSQL in production

### §8.1 Alembic Migrations (mandatory workflow)

- **ABSOLUTE RULE — never create or write a file inside `alembic/versions/` yourself, under any circumstances.** This includes schema migrations, data-only migrations, seed migrations, and empty revisions. No exceptions. Not even when Docker is not running, not even when the DB is unreachable, not even for "simple" INSERT statements.
- Always use `alembic revision --autogenerate -m "<message>"` — it inspects the live DB schema vs. SQLAlchemy models and generates exactly what's needed. For data-only migrations (no schema changes), autogenerate produces an empty `upgrade()`/`downgrade()` — that is the correct starting point.
- **You never run this command yourself.** Always provide the exact commands for the user to run, including the accurate `-m` message. Wait for the user to run them and share the generated filename before touching the file.
- After the user runs the command and provides the generated file path, you may edit the file to add data operations (`op.execute()`) — editing an existing generated file is allowed; creating one from scratch is not.

---

## §9. Background Jobs

- All job handlers must be idempotent — at-least-once delivery + idempotency key = effectively exactly-once
- Retry strategy: exponential backoff with jitter; dead letter queue after max retries exhausted
- Use outbox pattern for jobs that must execute atomically with a database write

---

## §10. Security (OWASP API Top 10, 2023)

- **API1 BOLA** — ownership check at object level on every resource, not just at auth layer
- **API2 Broken Auth** — rate-limit login attempts; always reject `alg: none` JWT
- **API3 Mass Assignment** — explicit allow-list schemas; never pass unfiltered `**kwargs` to model constructors
- **API4 Resource Consumption** — enforce body size limits; all list endpoints paginated
- **API5 Broken Function Level Authorization** — admin and privileged endpoints enforce role check, not just auth check
- **API6 Sensitive Business Flows** — rate-limit OTP, checkout, account creation, and similar flows
- **API7 SSRF** — validate and whitelist URLs before any server-side fetch
- **API8 CORS** — never `*` with credentials; use explicit origin allow-list
- **API9 Inventory Management** — all API versions documented; deprecated versions have sunset dates
- **API10 Third-Party APIs** — validate and sanitize all data received from external APIs
- Secrets: use a secrets manager (Vault / AWS SSM); never commit secrets to git; rotate immediately on compromise

---

## §11. Observability

- Structured JSON logs with required fields: `timestamp`, `level`, `service`, `request_id`, `message`
- Correlation ID generated at the entry point; propagated through all downstream calls and job payloads
- Track RED metrics: Rate, Errors, Duration (P95/P99 — never averages)
- Health endpoints: `/health`, `/ready`, `/live`
- Use OpenTelemetry SDK → Collector → backend

---

## §12. Testing

- Integration tests use a real database in Docker — never mock the database
- Use transaction rollback between tests to ensure no shared state
- No shared state between tests; use test factories with overridable defaults
- Contract testing (Pact) for microservice interfaces — both consumer and provider sides
