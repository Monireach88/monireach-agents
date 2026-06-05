# CLAUDE.md — Rermork.org AI Search (WordPress)

## Project Type
`coding`

> Universal rules are auto-loaded from `~/.claude/rules/`. Work-area standards
> (backend / devops / frontend) are symlinked under `.claude/rules/`. This file
> holds ONLY project-specific routing and the WordPress/production rules that are
> not covered by the universal set.

---

## What This Is

WordPress AI-powered search for Khmer educational content (rermork.org, ~6,000
teachers, 1,333 Activity posts). Three-component hybrid search: OpenAI embeddings
(Pinecone) + WordPress/Relevanssi keyword search + Khmer word segmentation
(khmernltk microservice). Phases 1–3 live in production.

---

## Session Initialization

Follow `session-management.md §9.1` (standard layout, including the `### ✅` integrity grep).

- `current_state/project_status.md` — single source of truth; read first.
- `current_state/milestone.md` — full detail archive of completed tasks (read on demand).
- Legacy `current_state/` domain files (kept for reference, read on demand):
  - `implementation_status.md` — pre-migration status snapshot (being superseded by `project_status.md`)
  - `next_steps.md` — roadmap (Phases 4–5)
  - `technical_architecture.md` — WordPress, AI Engine config, Pinecone settings
  - `search_system.md` — hybrid search architecture, Relevanssi integration
  - `known_issues.md` — active limitations and workarounds
  - `environment_guide.md` — local vs staging vs production, deployment
  - `functions_php_custom_code.md` — annotated functions.php code map
- `archive/daily_log.md` is large — read only recent entries with `tail`/offset, never in full.

Rule: verify in `project_status.md` before assuming anything is built.

---

## End Session

Follow `logging-workflow.md §2.5`:
- Append today's events to `archive/daily_log.md` (read `tail -50` first to find today's date).
- Update `current_state/project_status.md` (symbol rule; grep for completed task name).
- Archive completed `### ✅` detail sections to `current_state/milestone.md` per §2.6.
- Update `PROJECT.md` only if structure/stack/architecture changed.

## Doc Sync Rule

| Changed in `project_status.md` | Sync target |
|---|---|
| Task completed | `current_state/milestone.md` |
| Features, API, tech stack, roadmap | `README.md` / `current_state/next_steps.md` |
| New / resolved limitation | `current_state/known_issues.md` |
| WordPress / AI / Pinecone config | `current_state/technical_architecture.md` |
| Search architecture | `current_state/search_system.md` |
| Deployment, env vars, environments | `current_state/environment_guide.md` |
| Project structure or navigation | `PROJECT.md` |

---

# Project-Specific Rules

## WordPress Development Constraints

- ONLY edit `wp-content/themes/rermork2021/functions.php` — never edit plugin files directly.
- ALWAYS use WordPress hooks and filters; never patch plugin internals.

## Khmer Content Handling (CRITICAL)

- Content Rewrite must stay **DISABLED** (AI Engine Pro → Settings → Embeddings).
  When enabled it translates Khmer → English before embedding, which breaks search
  completely (Oct 5 2025 discovery).
- Verify Khmer content in the database — never assume it is correct:
  `SELECT content FROM <prefix>mwai_vectors WHERE subType = 'activity' LIMIT 3;` → must show Khmer.
- Embedding model: `text-embedding-3-large` (1024 dims). Similarity threshold: **20–25** for Khmer (not 80).
- Post type is auto-detected via `RERMORK_ACTIVITY_POST_TYPE` (local `activities`, staging/prod `activity`).

## Testing & Deployment Order

- Test locally in Docker BEFORE staging. Deployment order: **Local → Staging → Production**.
- Never deploy untested code to staging.

## Production Server Safety Rules (CRITICAL)

These rules exist to prevent production outages. A production incident on 2026-01-19
informed these constraints. All files must be tracked in git and deployed via `git pull`.

**NEVER do these without EXPLICIT user approval:**

1. **NEVER create/edit files manually on the production server.** Manual files become
   "ghost files" that git can delete when switching branches.
2. **NEVER switch git branches on production.** Git removes tracked files absent from the
   target branch — this can delete `index.php` and cause an immediate outage.
3. **NEVER restart shared services** (PHP-FPM, nginx, MySQL) — they affect ALL sites on the
   server. Always warn: "This restarts PHP for ALL sites on this server. Approve?"
4. **NEVER make ANY change on production** without first: verifying state
   (`git branch --show-current`, `git log -1`), understanding what files change, and getting approval.

**Production branch policy:** production MUST run on `main` only. Never checkout feature or
`development` branches on production. If production is on the wrong branch, STOP and ask.

**When production is down:** STOP → DIAGNOSE (logs) → REPORT → PROPOSE → act only after approval.

## Server Access (commands, not secrets)

- Production: `ssh rermork-monireach`, dir `/home/runcloud/webapps/rermork`, branch `main` only.
  Prefix git/PHP with `sudo -u runcloud` for write/SSH operations (`git status` is read-only and works without it).
- Local: `http://rermork-staging.local`, `docker-compose up -d`, DB prefix `wp_`.
