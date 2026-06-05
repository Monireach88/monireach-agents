---
name: git-release-workflow
description: Safely release development to main with a mandatory pre-flight checklist.
version: 1.0.0
---

# Git Release Workflow

**Trigger:** User invokes `/git-release-workflow`

**Purpose:** Safely release `development → main` with a mandatory pre-flight checklist. Merging to main is a production deployment decision — not just a git operation. This skill enforces a go/no-go gate before any code touches main.

**Rules enforced natively:**

- NEVER merge or push without user confirmation (§6.1, §6.2)
- Pre-flight checklist MUST be completed before merge — no skipping

---

## How to adapt this skill to a new project

The **8 checklist categories are universal** — they apply to every project, language, and framework.

The **specific items within each category are project-specific.** When starting a new project, update:

| Item to update          | Current project                       | New project (examples)                                            |
| ----------------------- | ------------------------------------- | ----------------------------------------------------------------- |
| Test command            | `uv run pytest tests/`                | `npm test`, `go test ./...`, `cargo test`                         |
| DB migration tool       | Alembic                               | Flyway, Liquibase, Prisma migrate, Rails migrations               |
| Secrets location        | HF Spaces secrets + `.env.production` | AWS Secrets Manager, Vercel env vars, Railway, GCP Secret Manager |
| Compose/deploy file     | `docker-compose.prod.yml`             | `helm values.yaml`, K8s manifests, `fly.toml`, `render.yaml`      |
| CDN/proxy               | Cloudflare                            | AWS CloudFront, Fastly, Nginx                                     |
| Infra tool              | Terraform (planned)                   | Pulumi, CDK, Ansible                                              |
| Container orchestration | Docker Compose → K3s (future)         | Kubernetes, Nomad, ECS                                            |

Mark items as `N/A` if they don't apply yet, but keep them in the list — they become relevant as the project scales.

---

## Phase 0: Investigate (Sub-agent)

Launch a **general-purpose sub-agent** to run all git queries in parallel.

Queries:

- `git branch --show-current`
- `git log origin/main..development --oneline` (commits not yet in main)
- `git status`

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

## Phase 3: Pre-Flight Checklist

**CRITICAL: Do not skip this phase. Present the full checklist, then confirm.**

Display this checklist verbatim:

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
     [this project: uv run pytest tests/]
 □ No tests skipped or suppressed to force a pass
 □ CI pipeline is green on development branch
     [this project: gh run list --branch development]
 □ Dependency audit clean — no new critical vulnerabilities
     [this project: GitHub Dependabot — currently 1 high, 1 moderate flagged]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 2. STAGING PARITY                                    [UNIVERSAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 □ Feature was tested on a staging environment, not just local
     [this project: tested locally + HF Spaces dev preview]
 □ Staging config matches production config
     (no dev-only flags, no hardcoded localhost URLs)
 □ All team members' features in development have been
   integration-tested together — not just in isolation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 3. CONFIGURATION                                     [UNIVERSAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 □ All new env vars added to production secrets store
     [this project: .env.production + HF Spaces Secrets]
 □ Production values are correct — verify each new var:
     - Debug mode OFF  (API_DEBUG=false)
     - Log level INFO or WARNING  (not DEBUG)
     - CORS origins = production domains only  (not localhost, not *)
     - API URLs = production URLs  (not smart-chatbot.local)
 □ Deploy config file updated
     [this project: docker-compose.prod.yml]
 □ Reverse proxy / web server config updated for new routes
     [this project: Nginx config if new endpoints added]
 □ Feature flags set correctly for production
     (new features intentionally on or off?)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 4. DATABASE                                          [UNIVERSAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 □ Production DB backup taken BEFORE this release
     [this project: pg_dump → store safely]
 □ All migration files reviewed:
     - upgrade() contains ONLY additive ops
       (CREATE TABLE, ADD COLUMN, CREATE INDEX)
     - upgrade() has ZERO DROP TABLE / DROP COLUMN
     - downgrade() correctly reverses the upgrade
     [this project: alembic/versions/ — inspect each unapplied file]
 □ Migration plan confirmed — know exactly when and how to run
     [this project: docker exec chatbot_backend_prod uv run alembic upgrade head]
 □ Data migrations accounted for
     (existing rows needing backfilling? transformation scripts ready?)
 □ New seed data handled
     (new required rows? seed script updated? idempotent?)
     [this project: seed_demo_tenant() — verify it runs on startup]
 □ Vector DB backed up if applicable
     [this project: ChromaDB data dir → N/A until Step 4 (RAG)]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 5. SECURITY                                          [UNIVERSAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 □ No secrets, API keys, or passwords committed to git
     (check: git log -p | grep -iE "api_key|secret|password|token")
 □ New endpoints protected by auth middleware
     (no accidental public exposure of authenticated routes)
 □ Rate limiting covers new endpoints
 □ CORS origins locked to production domains only
 □ No debug routes or test endpoints exposed in prod
 □ Input validation in place for all new user-facing fields
 □ Breaking API changes versioned correctly
     (removed/renamed endpoints will break embedded clients —
      check: portfolio widget at monireach.com still works?)
 □ Dependabot / known CVEs reviewed and consciously accepted or fixed
     [this project: 1 high + 1 moderate currently flagged]

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
     [this project: Groq API key — still active? rate limits OK?]
 □ Webhooks or integrations pointing to correct prod URLs
 □ CDN / proxy cache: purge needed for updated static assets?
     [this project: Cloudflare cache — purge if JS/CSS/HTML changed]

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
     HF Spaces:   git push (force previous commit) or revert via UI

 □ Previous working state tagged (optional but recommended)
     (git tag v0.x before merging — makes rollback target explicit)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 9. COMMUNICATION                                     [UNIVERSAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 □ Safe deploy window — is this a low-traffic time?
     (HF Spaces cold-starts during redeploy; avoid peak hours)
 □ Breaking changes communicated to affected clients
     → N/A until external tenants embed the widget
 □ Team notified (if multi-developer)
     → N/A while solo developer
 □ On-call person aware a deploy is happening
     → N/A until monitoring stack is live
```

---

After displaying the checklist, use **AskUserQuestion** with 3 options:

- **All clear — proceed** — every applicable item verified, ready to merge
- **Found an issue — abort** — something needs fixing first
- **Need to discuss** — unsure about an item, want to talk it through

**If "Found an issue" or "Need to discuss":** Stop. Do not merge. Help the user resolve the issue, then re-run `/git-release-workflow` from the beginning.

**If "All clear":** proceed to Phase 4.

---

## Phase 4: Execute Release

1. `git switch main`
2. `git merge --no-ff development`
   - If merge conflict → stop, report conflict details, `git switch development`, tell user to resolve manually
3. Use **AskUserQuestion** (Yes/No): "Push `main` to remote? (`git push -u origin main`)"
4. **If Yes:** `git push -u origin main`
5. **If No:** skip push
6. `git switch development` — return to development after release

After push, display post-release steps:

```
Release pushed. Post-release checklist:

□ Run DB migrations on production
    [this project: docker exec chatbot_backend_prod uv run alembic upgrade head]
□ Verify deployment rebuilt successfully
    [this project: check HF Spaces Actions tab]
□ Smoke test — manually verify the critical path works end-to-end
    [this project: send a message on the live chatbot at monireach.com]
□ Watch logs for the first 10 minutes
    [this project: HF Spaces → Logs tab]
□ Confirm rollback target is known in case issues appear in the next 24h
```

---

## Merge Strategy

Always `--no-ff`. Creates a clear merge commit marking the exact release point — invaluable when debugging production issues.

---

## Summary

| Phase | Action                              | Confirmation required                  |
| ----- | ----------------------------------- | -------------------------------------- |
| 0     | Investigate (sub-agent)             | None                                   |
| 1     | Safety check                        | None (auto-stop if nothing to release) |
| 2     | Show commits to be released         | Yes / No (abort)                       |
| 3     | Pre-flight checklist (9 categories) | All clear / Found issue / Discuss      |
| 4     | Merge development → main + push     | Yes / No (push)                        |

> **When to use:** Only when consciously deciding to ship everything in `development` to production.
> **For routine feature commits:** use `/git-commit-workflow` instead.
