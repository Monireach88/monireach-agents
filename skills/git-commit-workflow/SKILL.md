---
name: git-commit-workflow
description: Stage, commit, and optionally merge/push changes — with explicit user confirmation at each step.
version: 1.0.0
---

# Git Commit Workflow

**Trigger:** User invokes `/git-commit-workflow` or `/git-commit-workflow --auto`

**Purpose:** Stage, commit, and optionally merge/push changes — with explicit user confirmation at each step. Replaces the TTY-based git hooks that blocked Agent from running `git commit` directly.

**Flags:**

- _(no flag)_ — default mode: confirmation required at each step (Phase 3, each commit, push, merge, push dev)
- `--auto` — autonomous mode: skip ALL confirmations; execute the full workflow end-to-end without waiting (commits → push feature → merge to development → push development → return to feature branch)

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
6. **Phase 5**: Merge to `development` with `--no-ff` automatically; push `development` automatically; return to feature branch
7. Print a final summary: all commits made, push status, merge status

If a **merge conflict** occurs in Phase 5: stop, report the conflict, return to feature branch — this always requires human resolution regardless of flag.

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

- **If Yes:** `git push -u origin <feature-branch>`
- **If No:** skip, proceed to Phase 5

---

## Phase 5: Merge to Development

Use **AskUserQuestion** (Yes/No): "Merge `<feature-branch>` to `development` now?"

**If No:** Done. Stay on feature branch.

**If Yes:**

1. `git switch development`
2. `git merge --no-ff <feature-branch>`
   - If merge conflict → stop, report conflict details, return to feature branch: `git switch <feature-branch>`
3. Use **AskUserQuestion** (Yes/No): "Push development to remote? (`git push -u origin development`)"
4. **If Yes:** `git push -u origin development`
5. **If No:** skip push
6. `git switch <feature-branch>` — always return to feature branch after this phase

---

## Merge Strategy

Always use `--no-ff` (no fast-forward). This preserves branch history and makes it clear when a feature was merged.

---

## Summary

| Phase | Action                                    | Default mode                         | `--auto` mode                     |
| ----- | ----------------------------------------- | ------------------------------------ | --------------------------------- |
| 0     | Investigate (sub-agent)                   | None                                 | None                              |
| 1     | Safety check                              | None (auto-stop on protected branch) | None (same)                       |
| 2     | Generate commit plan                      | None                                 | None                              |
| 3     | Present plan                              | Yes / No / Chat                      | Display only, proceed immediately |
| 4     | Execute each commit + push feature branch | Yes / No per commit, Yes / No (push) | Automatic                         |
| 5     | Merge + push to development               | Yes / No (merge), Yes / No (push)    | Automatic                         |

> **Note:** Merging `development → main` is a separate, intentional release decision.
> Use `/git-release-workflow` when you are ready to release everything in `development` to production.
