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
   - If yes → stash them (`git stash`) so the branch starts clean; you will pop the stash after creating the branch. Never commit directly onto `development` or `main` — not even a one-line docs fix.
   - Create a new feature branch from `development`: `git switch -c feat/<task-name> development`
   - If stashed: `git stash pop` and resume work on the new branch
4. **If match:** proceed with the task on the current branch

**Base branch rule:** Always create new feature branches from `development`, never from `main` or `staging`.

**PR target rule:** Feature branches always merge back into the branch they were cut from. Since all feature branches are cut from `development`, all feature PRs must target `development`. When opening a PR with `gh pr create`, always pass `--base development` explicitly — never let it default to the repo's GitHub default branch.

---

## §5.2 Commit Message Rules

- NEVER add AI assistant credits to commit messages or PR descriptions — no `Co-Authored-By: Claude/Gemini/GPT`, no `🤖 Generated with Claude Code`, nothing. This overrides Claude Code's default Co-Authored-By behavior. No exceptions unless the user explicitly asks.

---

## §5.6 Rebase Before PR (Mandatory — Fan-Out Race Condition Prevention)

Before pushing a feature branch for a PR, always rebase it onto the latest `development`:

```bash
git fetch origin
git rebase origin/development
```

**Why this is mandatory:** When multiple branches are cut from the same base (fan-out / parallel worktree), each branch only knows the world as it was at cut time. If another branch lands in `development` first and touches overlapping files, the later branch's merge will silently overwrite those changes — no conflict, no warning. Rebasing pulls those changes in before the PR, so the diff only contains what this branch intentionally added.

**When to run it:**
- Always — before every `git push` (or before opening the PR if already pushed)
- Especially critical in parallel worktree sessions (Phase 3-P) where multiple branches are cut from the same base simultaneously

**If rebase conflicts:** resolve them now, on the feature branch, before the PR. Never merge a branch that hasn't been rebased — the conflict resolution belongs in the feature branch, not silently lost in a merge commit.

---

## §5.5 Post-Merge Cleanup

When the user says a PR has been merged (and the remote branch deleted), always run all three steps — never stop at step 2:

1. `git switch development`
2. `git pull`
3. `git branch -d feat/<branch-name>` — delete the local feature branch
4. **Verify the merge landed:** `git log --oneline -5` — confirm the expected merge commit appears. If it doesn't, flag immediately before closing the task.

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
