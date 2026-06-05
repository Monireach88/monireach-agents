# §5. Git Workflow

## §5.1 Branch Strategy

- Create feature branches for new work
- Merge to development/main branch before deployment
- Never commit directly on production/staging servers
- Test locally first, then staging, then production

---

## §5.3 Atomic Task Branch Check

When the user confirms which task to continue (triggered from `initialize` task selection — see §9.1), run this check before starting any work:

1. **Read current branch:** `git branch --show-current`
2. **Semantic match check:** Does the current branch conceptually belong to the selected task?
   - `feat/entries` + entries task → match ✅
   - `development` + entries task → no match ❌ (protected/generic branch)
   - `feat/entries` + profile-image task → no match ❌ (wrong feature)
   - `main` + any task → no match ❌ (protected branch)
3. **If no semantic match:**
   - Check `git status` — are there uncommitted changes?
   - If yes → assess the changes: if 1–2 files with obvious, single-concern changes, stage and commit them directly; if multi-file, multi-concern, or unclear groupings, invoke `/git-commit-workflow` first
   - Once clean → create new feature branch from `development`: `git switch -c feat/<task-name> development`
4. **If match:** proceed with the task on the current branch

**Base branch rule:** Always create new feature branches from `development`, never from `main` or `staging`.

---

## §5.2 Commit Message Rules

- NEVER add AI assistant credits to commit messages unless explicitly requested by user

---

## §5.4 Fresh Machine Check

After every atomic task, ask: **"Would this work on a fresh machine with only the committed files?"**

If no → close the loop immediately before closing the task. If it genuinely cannot be done now, create a 🔲 task in `project_status.md` so it is not forgotten.

**What to check** (anything changed by the task that must be committed to work elsewhere):

| Changed locally | What to commit |
|---|---|
| New env var added | Add to `.env.example` |
| `.env.example` key added/removed/renamed | Sync all `.env*` files (`.env`, `.env.staging`, `.env.production`) |
| Dockerfile modified | Rebuild and verify image builds cleanly |
| `docker-compose*.yml` modified (new volume, new service, port change) | Verify `docker-compose.prod.yml` stays consistent |
| nginx / PHP-FPM / OS-level config tweaked on host | Encode in `nginx.conf`, `php.ini`, or Dockerfile — never leave as a manual step |
| New named Docker volume required | Add to `docker-compose.yml` volumes section AND document in `DOCKER_SETUP.md` |
| New system dependency (apt package, OS tool) | Add `RUN apt-get install ...` to Dockerfile |

**Env var sync check command:**
```bash
for f in .env .env.staging .env.production; do
  [ -f "$f" ] || continue
  missing=$(comm -23 <(grep -E '^[A-Z_]+=' .env.example | sed 's/=.*//' | sort) <(grep -E '^[A-Z_]+=' "$f" | sed 's/=.*//' | sort))
  [ -n "$missing" ] && echo "$f MISSING: $missing"
done
```

**When adding a missing key to non-dev env files:** if the key is dev-only (pgAdmin, local virtual hosts, dev container names), add it with an empty value and a comment: `# Dev-only — not used in this environment; defined here to keep .env files in sync with .env.example`
