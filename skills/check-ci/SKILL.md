---
name: check-ci
description: Use when the user invokes "/check-ci" or asks to check CI/CD status, GitHub Actions status, or deployment status. Defaults to the current project's repo (discovered from git remote); "/check-ci all" sweeps every repo of the authenticated owner. Also callable by automations (/loop, /loop-dev), which persist failures to archive/ci_inbox.md.
version: 1.2.0
---

# Check CI

Check GitHub Actions status. No hardcoded repos — scope is discovered at runtime, so the skill works in any environment and any project.

## When This Skill Applies

- User invokes `/check-ci` (current project) or `/check-ci all` (every repo)
- User asks "what's the CI status?", "check my pipelines", "any failed runs?"
- An automation (`/loop 5m /check-ci`, or `/loop-dev` post-push) invokes it

## Step 0: Resolve Scope (never assume)

1. **Pre-flight:** `gh auth status` — if not authenticated, report it and stop; do not guess at results.
2. **Default scope (no argument):** the current project —
   ```bash
   git remote get-url origin
   ```
   Parse `owner/repo` from the URL (handles both `git@github.com:owner/repo.git` and `https://github.com/owner/repo.git`). If the cwd is not a git repo or has no GitHub remote, fall back to `all` scope and say so.
3. **`all` scope:** discover repos dynamically —
   ```bash
   gh repo list --limit 30 --json nameWithOwner,pushedAt --jq 'sort_by(.pushedAt) | reverse | .[].nameWithOwner'
   ```
   Check the most recently pushed repos first; skip repos whose run list is empty (no workflows) without flagging them as problems.

## Step 1: Fetch Run Lists

For each repo in scope:

```bash
gh run list --repo <owner/repo> --limit 5
```

## Step 2: Format Output

Display results grouped by repo. For each run show:

- Status icon: ✅ (success) | ❌ (failure) | 🔄 (in_progress/queued) | ⏸️ (cancelled)
- Workflow name
- Branch
- Elapsed time or timestamp
- Run ID (for failures only — needed for log drill-down)

**Example output format:**

```
=== owner/repo-a ===
✅  CI Tests           main        2m 14s ago
❌  CI Tests           feature/x   5h ago        (Run ID: 1234567890)
🔄  Deploy             main        running now

=== owner/repo-b ===
✅  Deploy Pages       main        1d ago
```

## Step 3: Flag Failures

If any run has status `failure`:
- List the repo, workflow, branch, and run ID
- Show the command to view logs:
  ```bash
  gh run view <run-id> --repo <owner/repo> --log-failed
  ```

## Step 3a: Diagnose Whether Failure Is Real

A CI failure on `main` (merge push) that passed on the PR branch is usually environmental, not a code defect. Before reporting it as a bug:

1. **Cross-reference:** check if the same commit passed on the PR branch CI — `gh run list` shows both the `pull_request` run (feature branch) and the `push` run (main merge). If the PR CI was green with the same code, the failure is likely a flake.
2. **Reproduce locally:** run the specific failing test(s) in the project's authoritative environment:
   ```bash
   # For smart_chatbot: Docker
   docker exec chatbot_backend_dev uv run pytest tests/path/to/test.py::test_name -rAq --tb=short
   ```
3. **Decide:**
   - Local passes → suggest re-running the CI job: `gh run rerun <run-id> --repo <owner/repo>`
   - Local also fails → treat as a real code defect and investigate

Common flake signatures: UUID/float type-mapping (`AttributeError: 'float' object has no attribute 'replace'`), race conditions in DB fixtures, transient network timeouts.

If a failure persists across reruns but passes locally, load `references/debugging-persistent-ci-failures.md` for a systematic environment-comparison playbook — DB version mismatches, SQLite library build differences, module-level import side effects, test ordering, and unnecessary `session.refresh()` patterns.

## Step 4: Summary Line

End with one summary line:
- All green: "All pipelines passing."
- Any failures: "X failure(s) detected — run IDs listed above."
- Any in progress: "X run(s) in progress."

## Step 5: Automation Mode (when invoked by /loop or /loop-dev)

Chat output is ephemeral across loop iterations — persist findings:

- On any failure, append one line per failure to `archive/ci_inbox.md` in the current project (create the file with a `# CI Inbox` header if missing):
  ```
  - 🔲 YYYY-MM-DD HH:MM — <repo> / <workflow> / <branch> — Run ID <id>
  ```
- Skip appending if an open 🔲 line with the same Run ID already exists (no duplicates).
- The inbox is a **triage** file: items are surfaced to the owner at the next session start (same treatment as `crucial_notes.md` — never auto-promote to `project_status.md` without the owner's decision).
- All green → do not write anything.
