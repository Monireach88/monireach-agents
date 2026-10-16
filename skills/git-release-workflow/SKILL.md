---
name: git-release-workflow
description: Safely release development to main with a mandatory pre-flight checklist.
version: 1.1.0
---

# Git Release Workflow

**Trigger:** User invokes `/git-release-workflow`

**Purpose:** Safely release `development → main` with a mandatory pre-flight checklist. Merging to main is a production deployment decision — not just a git operation. This skill enforces a go/no-go gate before any code touches main. The release is performed via a PR (`development → main`) merged on GitHub — never a local push to `main` (the `pre-push` hook blocks that anyway).

**Rules enforced natively:**

- NEVER merge or push without user confirmation (§6.1, §6.2)
- Pre-flight checklist MUST be completed before merge — no skipping

---

## Project discovery

The **9 checklist categories are universal**. The commands, files, environments, and deployment surfaces are not.

Before running the release workflow in any repo, first discover the project-specific release contract from the local codebase. Read only the files needed to answer these questions:

1. What is the authoritative test command?
2. What branch flow is used for releases?
3. What deploy mechanism is triggered by merging to the production branch?
4. What migration tool and production migration command are used?
5. Where do production secrets/config live?
6. What is the real production URL and, if applicable, staging URL?
7. What is the real rollback path for code, database, and infra?

Primary sources to inspect when present:

- `AGENTS.md`, `CLAUDE.md`, `PROJECT.md`
- `README.md`, `DOCKER_SETUP.md`
- `Makefile`, `package.json`, `pyproject.toml`
- `.github/workflows/*`
- deploy manifests such as `docker-compose*.yml`, `Dockerfile*`, `render.yaml`, `fly.toml`, `helm/`, `k8s/`, `terraform/`

**Project-specific deployment references:** Some projects have deployment patterns that differ
significantly from the generic workflow (e.g., bare-metal vs Docker, no CI/CD, manual config edits).
Check `references/` for project-specific files before running the checklist; if one exists,
apply its project-specific rules in place of the generic assumptions.

- `references/deploy-verification.md` — Smart Chatbot: how to verify a deploy took effect, debug 502 errors, and diagnose truncated responses on the production server.

Do not hardcode project commands into the core workflow. Use repo-discovered values at runtime.

## Project adaptation examples

The table below is illustrative only. These are examples of the kinds of values that must be discovered per project:

| Item to discover        | Example A                             | Example B                                                         |
| ----------------------- | ------------------------------------- | ----------------------------------------------------------------- |
| Test command            | `docker exec app uv run pytest tests` | `npm test`, `go test ./...`, `cargo test`                         |
| DB migration tool       | Alembic                               | Flyway, Liquibase, Prisma migrate, Rails migrations               |
| Secrets location        | `.env.production` on server           | AWS Secrets Manager, Vercel env vars, Railway, GCP Secret Manager |
| Compose/deploy file     | `docker-compose.prod.yml`             | `helm values.yaml`, `fly.toml`, `render.yaml`                     |
| CDN/proxy               | Cloudflare                            | AWS CloudFront, Fastly, Nginx                                     |
| Infra tool              | Terraform                             | Pulumi, CDK, Ansible                                              |
| Container orchestration | Docker Compose                        | Kubernetes, Nomad, ECS                                            |

Mark items as `N/A` if they genuinely do not apply.

---

## Phase 0: Investigate (Sub-agent)

Launch a **general-purpose sub-agent** to run all git queries in parallel.

Queries:

- `git branch --show-current`
- `git log origin/main..development --oneline` (commits not yet in main)
- `git status`
- `git diff origin/main..origin/development --name-only` (files changed — used for risk classification in Phase 3)

---

## Phase 1: Safety Check

**If on `main`:** Stop. Report: "Switch to your feature branch or `development` first."

**If `development` has no commits ahead of `main`:** Stop. Report: "Nothing to release — `development` is already up to date with `main`."

**Otherwise:** continue.

---

## Phase 2: Show What Will Be Released

Display commits clearly:

```
The following commits in `development` will be merged into `main`:

  <hash> <message>
  <hash> <message>
  ...

⚠️  ALL of these commits go to main — not just your latest feature.
```

Use **AskUserQuestion** (Yes/No):

- **Yes** — I understand what will be released, proceed to checklist
- **No** — abort

---

## Phase 3: Pre-Flight Checklist (Risk-Classified)

**CRITICAL: Do not skip this phase. Every applicable section must be verified before merging.**

**Escape hatch:** If the user types "full checklist" at any point in this phase, show all 9 sections in full regardless of classification.

### Step 3a — Classify the release

Using the file list from Phase 0 (`git diff --name-only`), set these flags (default false):

| Flag | True when the diff contains... |
|---|---|
| `HAS_MIGRATIONS` | any file under `alembic/versions/` |
| `HAS_ENV_CHANGES` | `.env.example` |
| `HAS_INFRA_CHANGES` | `docker-compose*.yml`, `Dockerfile*`, `nginx.conf`, `nginx/`, `terraform/`, `k8s/` |
| `HAS_NEW_DEPS` | `package.json`, `pyproject.toml`, `requirements*.txt`, `uv.lock` |
| `HAS_BACKEND_CHANGES` | any `.py` file outside `tests/` and outside `alembic/` |

**Conservative rule:** When uncertain whether a file matches a pattern, set the flag to **true**. A false positive shows an extra section (harmless friction). A false negative hides a relevant section (dangerous). Never collapse a section on a guess.

### Step 3b — Announce classification (one line, before the checklist)

- All flags false → `Frontend-only release — showing abbreviated checklist (sections 3, 4, 6, 7 auto-skipped). Type "full checklist" to see everything.`
- Otherwise → `Detected: [list each true flag by name]. Showing full sections for flagged categories.`

### Step 3c — Present the checklist

**Always show:** sections 1, 2, 5, 8, 9 — no exceptions.

**Conditional sections** — show the full section when the flag is true; replace with a single skip line when false:
- Section 3 (Configuration): `HAS_ENV_CHANGES` OR `HAS_INFRA_CHANGES` → else: `✓ 3. CONFIGURATION — auto-skipped (no .env or infra file changes detected)`
- Section 4 (Database): `HAS_MIGRATIONS` → else: `✓ 4. DATABASE — auto-skipped (no migration files detected)`
- Section 6 (Infrastructure): `HAS_INFRA_CHANGES` → else: `✓ 6. INFRASTRUCTURE — auto-skipped (no infra file changes detected)`
- Section 7 (External Tools): `HAS_BACKEND_CHANGES` OR `HAS_NEW_DEPS` → else: `✓ 7. EXTERNAL TOOLS & SERVICES — auto-skipped (no backend or dependency changes detected)`

---

```
╔══════════════════════════════════════════════════════════════════╗
║                 PRE-FLIGHT RELEASE CHECKLIST                     ║
║      Every item must be verified before merging to main.         ║
║      Mark N/A only if the item genuinely does not apply.         ║
╚══════════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. TESTS & CI                                        [UNIVERSAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 □ Full test suite passes locally
     [use the authoritative test command discovered from the repo]
 □ No tests skipped or suppressed to force a pass
 □ CI pipeline is green on development branch
     [use the repo's actual release branch name]
 □ Dependency audit clean — no new critical vulnerabilities
     [check the project's actual dependency/security scanning surface]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2. STAGING PARITY                                    [UNIVERSAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 □ Feature was tested on a staging environment, not just local
     [if there is no staging environment, explicitly call that out as risk]
 □ Staging config matches production config
     (no dev-only flags, no hardcoded localhost URLs)
 □ All team members' features in development have been
   integration-tested together — not just in isolation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3. CONFIGURATION                                     [UNIVERSAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 □ All new env vars added to production secrets store
     [use the project's actual secrets/config store]
 □ Production values are correct — verify each new var:
     - Debug mode OFF  (API_DEBUG=false)
     - Log level INFO or WARNING  (not DEBUG)
     - CORS origins = current intended production domains only
     - API URLs = production URLs  (not smart-chatbot.local)
 □ Deploy config file updated
     [use the repo's actual deploy manifest]
 □ Reverse proxy / web server config updated for new routes
     [Nginx / ingress / gateway / platform routing if applicable]
 □ Feature flags set correctly for production
     (new features intentionally on or off?)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
4. DATABASE                                          [UNIVERSAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 □ Production DB backup taken BEFORE this release
     [use the real backup procedure for the project]
 □ All migration files reviewed:
     - upgrade() contains ONLY additive ops
       (CREATE TABLE, ADD COLUMN, CREATE INDEX)
     - upgrade() has ZERO DROP TABLE / DROP COLUMN
     - downgrade() correctly reverses the upgrade
     [inspect the real migration directory/tool output]
 □ Migration plan confirmed — know exactly when and how to run
     [use the real production migration command]
 □ Data migrations accounted for
     (existing rows needing backfilling? transformation scripts ready?)
 □ New seed data handled
     (new required rows? seed script updated? idempotent?)
     [verify project-specific seed/bootstrap behavior]
 □ Vector DB backed up if applicable
     [or search index / blob store / queue state backed up if applicable]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
5. SECURITY                                          [UNIVERSAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 □ No secrets, API keys, or passwords committed to git
     (check: git log -p | grep -iE "api_key|secret|password|token")
 □ New endpoints protected by auth middleware
     (no accidental public exposure of authenticated routes)
 □ Rate limiting covers new endpoints
 □ CORS policy matches the current production design
 □ No debug routes or test endpoints exposed in prod
 □ Input validation in place for all new user-facing fields
 □ Breaking API changes versioned correctly
     (removed/renamed endpoints will break embedded clients —
      check: portfolio widget at monireach.com still works?)
 □ Dependabot / known CVEs reviewed and consciously accepted or fixed
     [this project: review current GitHub Dependabot / code scanning alerts before release]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 6. INFRASTRUCTURE                                    [UNIVERSAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 □ New ports: firewall / security group rules updated?
 □ SSL/TLS certificate valid and not expiring within 30 days?
 □ DNS records updated for new subdomains or routing?

 Terraform (infra-as-code):
 □ → N/A until migrating to Hetzner
     (when active: run terraform plan, review output, apply only after approval)

 Kubernetes / K3s (container orchestration):
 □ → N/A until scaling past single-server Docker Compose
     (when active, verify before every release:)
     (  - kubectl rollout status deployment/<name>)
     (  - Helm chart values updated for new env vars / config)
     (  - Pod resource limits (CPU/memory) reviewed for new services)
     (  - HPA autoscaling config covers new deployments)
     (  - Rolling update strategy set — ensures zero-downtime deploy)
     (  - PodDisruptionBudget in place for critical services)
     (  - New ConfigMaps / Secrets created in the correct namespace)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
7. EXTERNAL TOOLS & SERVICES                         [UNIVERSAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 □ Third-party API keys valid and have sufficient quota
     [check the real providers used by the project]
 □ Webhooks or integrations pointing to correct prod URLs
 □ CDN / proxy cache: purge needed for updated static assets?
     [use the actual CDN/proxy/cache layer if one exists]

 Monitoring stack:
 □ Grafana dashboards updated for new metrics / endpoints
     → N/A until Prometheus is set up
 □ Prometheus alert rules cover new endpoints
     → N/A until Prometheus is set up
 □ Loki log aggregation capturing new log events correctly
     → N/A until Prometheus is set up

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
8. ROLLBACK PLAN                                     [UNIVERSAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 □ You know exactly how to roll back every layer if prod breaks:

     Code:        git revert <merge-commit> → push → redeploy
     DB schema:   alembic downgrade -1
     DB data:     restore pg_dump backup taken in step 4
     Vectors:     restore ChromaDB data dir backup (when RAG is live)
     K8s:         kubectl rollout undo deployment/<name>  [N/A for now]
     Infra:       terraform apply previous state  [N/A for now]
     App deploy:  use the project's actual redeploy trigger

 □ Previous working state tagged (optional but recommended)
     (git tag v0.x before merging — makes rollback target explicit)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
9. COMMUNICATION                                     [UNIVERSAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 □ Safe deploy window — is this a low-traffic time?
     (consider restart time, migration time, cache warmup, and user traffic)
 □ Breaking changes communicated to affected clients
     → N/A until external tenants embed the widget
 □ Team notified (if multi-developer)
     → N/A while solo developer
 □ On-call person aware a deploy is happening
     → N/A until monitoring stack is live
```

---

**Reminder before asking for confirmation:** Apply the conditional display rules from Step 3c above. Sections 3, 4, 6, 7 are replaced with their auto-skip line when their flag is false. If the user types "full checklist", re-display with all 9 sections in full before asking for confirmation.

After displaying the checklist, use **AskUserQuestion** with 3 options:

- **All clear — proceed** — every applicable item verified, ready to merge
- **Found an issue — abort** — something needs fixing first
- **Need to discuss** — unsure about an item, want to talk it through

**If "Found an issue" or "Need to discuss":** Stop. Do not merge. Help the user resolve the issue, then re-run `/git-release-workflow` from the beginning.

**If "All clear":** proceed to Phase 4.

---

## Phase 4: Execute Release (via PR)

The release goes through a PR into `main` — CI re-runs on it, and merging it is the push to `main` that triggers `deploy-prod.yml`.

1. Open the release PR:
   ```
   gh pr create --base main --head development --title "release: <summary>" --body "<what is shipping>"
   ```
2. **CI gate:** `gh pr checks <pr> --watch` — `ci.yml` runs on the PR into `main`. If any check fails, STOP and report; never merge a red release.
3. Use **AskUserQuestion** (Yes/No): "CI is green. Merge the release PR into `main` now? (triggers production deploy)"
4. **If Yes** — merge with a **merge commit** (NOT squash — preserves the shared `development`↔`main` history; `development` is permanent):
   ```
   gh pr merge <pr> --merge
   ```
   Do NOT pass `--delete-branch` — `development` is a permanent branch. Merging into `main` triggers `deploy-prod.yml`.
5. **If No:** leave the PR open; done.
6. Sync local branches:
   ```
   git switch main && git pull
   git switch development && git pull
   ```
   Both pulls should be clean fast-forwards — `main` just received the merge commit, and local `development` should never have commits that aren't already on `origin/development` (vibe-code branches from `origin/development` directly and pushes via PR, never merging into local `development`). If `git pull development` reports divergence here, it means a prior session violated that rule — fix it with `git reset --hard origin/development`.

**Pitfall — CI/CD handles the build and deploy, not you:** Once the release PR
merges into `main`, the CI/CD pipeline (this project: `deploy-prod.yml`) builds the
Docker image, pushes it to GHCR, and the self-hosted runner pulls and recreates
containers. **Never** manually `docker build`, `docker save`, `scp`, or `docker
compose up` to deploy — the pipeline is the single source of truth. If you think
the deploy didn't run, check GitHub Actions for the workflow run triggered by the
push to `main`. If the container isn't picking up changes after a successful
deploy, the issue is likely that `docker compose up` didn't detect the image
change — use `docker compose up -d --force-recreate` on the affected service,
or verify with `docker inspect <container> --format '{{.Config.Cmd}}'`.

After push, display post-release steps:

```
Release pushed. Post-release checklist:

□ Run DB migrations on production
    [use the real production migration command]
□ Verify deployment rebuilt successfully
    [check the actual deploy pipeline, platform logs, or runner output]
□ Smoke test — manually verify the critical path works end-to-end
    [test the project's highest-value production workflow]
□ Watch logs for the first 10 minutes
    [use the actual runtime logs/observability surface]
□ Confirm rollback target is known in case issues appear in the next 24h
```

---

## Merge Strategy

Release PRs merge with a **merge commit** (`gh pr merge --merge`), never squash. A merge commit marks the exact release point and preserves the shared history between the two permanent branches (`development`↔`main`) — squashing would fork their histories and break future `development → main` diffs. (Contrast: feature → `development` PRs squash, because a feature branch is short-lived.)

---

## Summary

| Phase | Action                              | Confirmation required                  |
| ----- | ----------------------------------- | -------------------------------------- |
| 0     | Investigate (sub-agent)             | None                                   |
| 1     | Safety check                        | None (auto-stop if nothing to release) |
| 2     | Show commits to be released         | Yes / No (abort)                       |
| 3     | Pre-flight checklist (up to 9 categories, risk-classified) | All clear / Found issue / Discuss      |
| 4     | Open release PR → CI gate → merge   | Yes / No (merge after green)           |

> **When to use:** Only when consciously deciding to ship everything in `development` to production.
> **For routine feature commits:** use `/git-commit-workflow` instead.
