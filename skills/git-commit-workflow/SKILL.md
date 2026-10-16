---
name: git-commit-workflow
description: Stage, commit, push a feature branch, and open a PR into development — with explicit user confirmation at each step.
version: 1.0.0
---

# Git Commit Workflow

**Trigger:** User invokes `/git-commit-workflow` or `/git-commit-workflow --auto`

**Purpose:** Stage, commit, push a feature branch, and open a PR into `development` — with explicit user confirmation at each step. Feature branches reach `development` ONLY via a merged PR; this skill never merges into a protected branch locally. (A local `pre-push` hook also blocks direct pushes to `development`/`main`.)

**Flags:**

- _(no flag)_ — default mode: confirmation required at each step (Phase 3, each commit, push, open PR, merge PR)
- `--auto` — autonomous mode: skip ALL confirmations; execute end-to-end (commits → push feature → open PR → wait for CI green → merge PR → sync `development`)

**Rules enforced natively (no hooks needed):**

- NEVER add AI assistant credits to commit messages (§5.2)
- In default mode: NEVER commit or push without user confirmation (§6.1, §6.2)
- In `--auto` mode: confirmation is pre-granted by the flag; proceed without pausing

---

## `--auto` Mode: Full Autonomous Execution

When invoked as `/git-commit-workflow --auto`:

1. Run **Phase 0** (investigate via sub-agent) — same as default
2. Run **Phase 1** (safety check) — same as default; still hard-stop on protected branches
3. Run **Phase 2** (generate commit plan) — same as default
4. **Phase 3**: Display the commit plan in chat (so the user can see what ran), then **proceed immediately without asking**
5. **Phase 4**: Execute all commits in order without per-commit confirmation; push feature branch automatically
6. **Phase 5**: Open the PR automatically (`gh pr create --base development --fill`)
7. **Phase 6**: Wait for CI on the PR (`gh pr checks <pr> --watch`); when all checks pass, merge (`gh pr merge <pr> --squash --delete-branch`) and sync `development`
8. Print a final summary: commits made, push status, PR URL, merge status

If **CI fails** in Phase 6: stop, report the failing checks, leave the PR open — `--auto` NEVER merges a red PR. If a **merge conflict** is reported by GitHub: stop and report — conflict resolution always requires a human regardless of flag.

---

## Phase 0: Investigate (Sub-agent)

Launch a **general-purpose sub-agent** to run all git queries in parallel and return a consolidated report. Do NOT run these yourself — delegate to the sub-agent.

Queries to run in parallel:

- `git status`
- `git diff` (unstaged changes)
- `git diff --staged` (already staged)
- `git branch --show-current`
- `git log --oneline -10` (for commit message style reference)
- `git log origin/development..HEAD --oneline` (commits ahead of development)

Sub-agent returns: consolidated state report with all 6 outputs.

---

## Phase 1: Safety Check

Read the current branch from the sub-agent report.

**If current branch is `main`, `development`, or `staging`:**

- Stop immediately
- Report: "You are on a protected branch (`<branch>`). Switch to a feature branch before committing."
- Do not proceed

**If current branch is a feature branch:** continue.

---

## Phase 2: Generate Commit Plan

Use the sub-agent's `git diff`, `git status`, and `git log` output to group changes into logical commits.

**If invoked mid-session (Agent has context of what was done):**

- Use conversation history to determine logical groupings
- Order commits chronologically (earliest work first)

**If invoked fresh (no session context):**

- Infer groupings from diff output
- Common groups: model changes, migration files, config/env, docs, chore/cleanup

**Commit message rules:**

- NEVER include AI assistant credits from any agent ("Co-Authored-By: Claude...", "Co-Authored-By: Gemini...", "Co-Authored-By: GitHub Copilot...", "🤖 Generated with...", etc.)
- Follow conventional commits style: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`
- Match the style of recent commits from `git log --oneline -10`
- One message per logical unit of work
- Subject line: imperative mood, ≤72 chars, no trailing period
- **Message length must match commit density:**
  - Simple/single-concern change → one-liner subject only
  - Dense commit (multiple files, non-obvious reasoning, or significant scope) → subject + blank line + bullet-point body explaining what and why
  - Never compress a dense commit into a vague one-liner just to keep it short

---

## Phase 3: Present Commit Plan

Display the plan clearly, then use **AskUserQuestion** with exactly 3 options:

```
Current branch: <branch-name>

Proposed commits:
  [1] <commit message 1>  →  <files>
  [2] <commit message 2>  →  <files>
  [3] <commit message 3>  →  <files>

Proceed with this plan?
```

Options presented via AskUserQuestion:

- **Yes** — proceed with this plan
- **No** — discard, do nothing
- **Chat** — adjust something before proceeding

**Wait for answer. Do not stage or commit anything yet.**

If **No**: stop, report "Nothing committed."
If **Chat**: discuss adjustments, then re-present updated plan (loop back to Phase 3).
If **Yes**: proceed to Phase 4.

---

## Phase 4: Execute Commits

For each commit in the plan (in order):

1. `git add <specific files for this commit only>` — stage exactly the files for this commit
2. Show the exact commit command that will run:
   ```
   git commit -m "<message>"
   ```
3. Use **AskUserQuestion** (Yes/No): "Commit [N/total] with this message?"
4. **If Yes:** run `git commit -m "<message>"`
5. **If No:** stop, ask what to change, do not proceed until resolved

After all commits complete: confirm "All [N] commits done. On branch `<branch>`."

Then use **AskUserQuestion** (Yes/No): "Push `<feature-branch>` to remote? (`git push -u origin <feature-branch>`)"

- **If Yes:** `git push -u origin <feature-branch>`, then proceed to Phase 5
- **If No:** stop here — a PR requires the branch on the remote, so Phase 5 cannot run. Report: "Feature branch not pushed; no PR opened."

---

## Phase 5: Open Pull Request

The feature branch is pushed. Protected branches change only via a merged PR, so this phase opens one instead of merging locally.

Use **AskUserQuestion** (Yes/No): "Open a PR `<feature-branch>` → `development` now?"

**If No:** Done. Branch is pushed; report "No PR opened — open one later with `gh pr create --base development`."

**If Yes:**

1. Create the PR:
   ```
   gh pr create --base development --head <feature-branch> --fill
   ```
   `--fill` seeds title/body from the commits. For a dense change, replace `--fill` with explicit `--title`/`--body` summarizing what and why.
2. Report the PR URL.
3. Proceed to Phase 6.

---

## Phase 6: Merge the PR (CI-gated)

This repo has no server-side required checks (private repo, free plan), so the skill enforces the CI gate itself: **never merge a PR whose checks are not green.**

Use **AskUserQuestion** (Yes/No): "Merge PR #<n> once CI is green?"

**If No:** Done. Leave the PR open.

**If Yes:**

1. Check CI: `gh pr checks <pr>` (or `gh pr checks <pr> --watch` to wait for completion).
   - **Any check failing or pending →** do NOT merge. Report status; stop until green.
2. When all checks pass, merge and delete the remote branch:
   ```
   gh pr merge <pr> --squash --delete-branch
   ```
3. **Verify the PR was actually merged on GitHub first** — check the PR status
   or `gh pr view <pr> --json state`. Do NOT assume the merge succeeded just
   because you ran the command.

   **Only after confirming the merge**, sync local branches:
   ```bash
   git switch development && git pull
   git branch -d <feature-branch>
   ```

   **Pitfall — premature branch switch:** Do NOT switch back to `development`
   before the PR is actually merged. Verify on GitHub first. Switching early
   leaves the user on the wrong branch with a clean working tree — they'll
   wonder where their changes went and may re-do work that was already committed.
   If you already switched early by mistake: apologize, switch back immediately
   (`git checkout <feature-branch>`), and explain what happened.

   **Pitfall — never manually deploy or edit server files:** After pushing a
   feature branch and opening a PR, do NOT manually build Docker images, `scp`
   files, run `docker compose up`, or edit config files directly on the
   production server. The CI/CD pipeline (this project: `deploy-prod.yml` on
   push to `main`) is the single source of truth for deployment. Manual server
   edits cause git merge conflicts when the pipeline pulls. If the server needs
   a hotfix before CI/CD runs, tell the user and let them decide — never take
   it upon yourself. If you already edited a file on the server: discard the
   local change (`git checkout -- <file>`), pull, and restart the service.

---

## Merge Strategy

Merge PRs with **`--squash`** — each feature becomes one clean commit on `development`. Never merge a feature branch into `development` locally; the merge happens on GitHub via the PR (and the `pre-push` hook blocks a local push to `development` anyway).

---

## Summary

| Phase | Action                                    | Default mode                         | `--auto` mode                     |
| ----- | ----------------------------------------- | ------------------------------------ | --------------------------------- |
| 0     | Investigate (sub-agent)                   | None                                 | None                              |
| 1     | Safety check                              | None (auto-stop on protected branch) | None (same)                       |
| 2     | Generate commit plan                      | None                                 | None                              |
| 3     | Present plan                              | Yes / No / Chat                      | Display only, proceed immediately |
| 4     | Execute each commit + push feature branch | Yes / No per commit, Yes / No (push) | Automatic                         |
| 5     | Open PR into `development`                | Yes / No                             | Automatic (`gh pr create`)        |
| 6     | Merge PR (only when CI green) + sync dev  | Yes / No (after green)               | Wait for green, then merge        |

> **Note:** Merging `development → main` is a separate, intentional release decision.
> Use `/git-release-workflow` when you are ready to release everything in `development` to production.
