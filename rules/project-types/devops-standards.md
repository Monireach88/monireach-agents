---
name: DevOps Engineering Standards
description: Mandatory DevOps standards for this project — covers Git/CI-CD, Docker, environment strategy, deployment, secrets management, observability, and Kubernetes.
type: project
---

# DevOps Engineering Standards

**ALL RULES BELOW ARE MANDATORY. Apply during implementation — do not defer to post-review.**

**If a section does not apply to this project, output one line: `SKIPPED §N — reason`.** A section skipped with no line is a violation. Without this, a rule that genuinely does not apply and a rule you forgot look identical.

---

## §1. Git & CI/CD

- Trunk-based development for web services; Gitflow only for versioned or batch-release products
- Feature branches must be < 1 day old; squash merge for features; merge commit for release branches
- CI stage order: lint → unit test → build → integration test → security scan → push artifact
- Pipeline must complete in < 10 minutes; fail-fast (lint before tests, tests before build)
- Use dependency cache and Docker layer cache in CI — can cut 50–70% of pipeline time
- Flaky tests: quarantine immediately; fix or delete within 1 sprint

---

## §2. Docker & Container Best Practices

- Dockerfile layer order: system deps → app deps → app code (stable layers first, frequently changing last)
- Always run as non-root user — use `USER` instruction in Dockerfile
- `.dockerignore` must exclude `.git`, `.env`, tests, `__pycache__`, and any secrets files
- Set CPU and memory requests AND limits (requests for scheduling, limits for protection)
- Use exec-form CMD (`["command", "arg"]`) so signals reach the app, enabling graceful shutdown
- Multi-stage builds (separate build stage from runtime stage) — reduces image size 60–80%
- Base image: use `-slim` variant; `distroless` for maximum attack surface reduction
- Image tags: git SHA for traceability; semver for releases — never tag `latest` for production
- Generate SBOM (SPDX or CycloneDX) in CI and attach as a build attestation
- Run vulnerability scan in CI (Trivy or Grype); fail the pipeline on any unfixed CRITICAL or HIGH CVEs

---

## §3. Environment Strategy

- Standard tiers: local → dev → staging → production
- Staging must mirror production in infrastructure, config, and integrations
- All environment-specific config in environment variables (12-Factor App) — nothing hardcoded
- Feature flags must be removed within 1–2 sprints of full rollout

---

## §4. Deployment

- Rolling deployment: default for Kubernetes; requires API backward compatibility
- Blue/green: instant rollback; 2× infra cost; DB migrations must be backward compatible
- Canary: automate promotion based on error rate and P99 latency; limits blast radius
- Expand/contract for DB migrations: never `DROP COLUMN` until old code is fully retired
- Zero-downtime checklist: health checks, readiness probes, graceful shutdown, `maxUnavailable: 0`

---

## §5. Secrets Management

- Any secret committed to git → assume compromised → rotate immediately
- Two prevention layers: pre-commit hooks (detect-secrets) + CI scanning (TruffleHog)
- Prefer mounted secret files over environment variables (env vars visible in `/proc/*/environ`)
- Zero-downtime rotation: support two valid versions simultaneously; revoke old after all services updated

---

## §6. Observability

- Structured JSON logging with required fields: `timestamp`, `level`, `service`, `trace_id`, `request_id`
- Correlation IDs propagated through all HTTP calls, queue messages, and job payloads
- RED method for services (Rate, Errors, Duration — P99/P95); USE method for resources (Utilization, Saturation, Errors)
- Alerts on symptoms (high error rate), not causes (high CPU); every alert must have a runbook
- OpenTelemetry architecture: SDK → Collector → backend

---

## §7. Kubernetes

- Readiness probe removes pod from load balancer rotation; liveness probe triggers restart; startup probe protects slow-starting containers
- `minReplicas: 2` for every production Deployment; HPA configured on CPU, memory, or custom metrics
- `PodDisruptionBudget` with `minAvailable: 2` on every multi-replica production Deployment
- RBAC: dedicated `ServiceAccount` per application; least-privilege `Role`; never use the `default` ServiceAccount

---

## §8. Infrastructure as Code

- Store Terraform state remotely with locking (S3 + DynamoDB for AWS) — never commit state to git
- One module per logical component; all values parameterized via variables
- Run `terraform plan` in CI on a schedule and alert on unexpected drift
- Run `checkov` for misconfiguration scanning and `tflint` for linting; block PRs on violations

---

## §10. DevSecOps

- SAST and SCA run in CI on every PR (shift-left security)
- SLSA Level 2 minimum: hosted build platform + signed provenance
- Sign container images with Cosign on push; verify signature on deploy
- Use OIDC for CI/CD cloud authentication — no long-lived static credentials stored in CI
- Kubernetes runtime constraints: non-root, no privilege escalation, read-only root filesystem, `seccompProfile: RuntimeDefault`, default-deny NetworkPolicy
