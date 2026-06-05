---
name: check-ci
description: Use when the user invokes "/check-ci" or asks to check CI/CD status, GitHub Actions status, or deployment status across project repos.
version: 1.0.0
---

# Check CI

Check GitHub Actions status across all tracked project repos.

## When This Skill Applies

- User invokes `/check-ci`
- User asks "what's the CI status?", "check my pipelines", "any failed runs?"

## Tracked Repos

| Repo | Description |
|------|-------------|
| `mt-robotics/smart-chatbot` | FastAPI chatbot + HF Spaces deployment |
| `mt-robotics/portfolio` | GitHub Pages portfolio at monireach.com |

## Instructions for Agent

### Step 1: Fetch Run Lists

Run these two commands:

```bash
gh run list --repo mt-robotics/smart-chatbot --limit 5
gh run list --repo mt-robotics/portfolio --limit 5
```

### Step 2: Format Output

Display results grouped by repo. For each run show:

- Status icon: ✅ (success) | ❌ (failure) | 🔄 (in_progress/queued) | ⏸️ (cancelled)
- Workflow name
- Branch
- Elapsed time or timestamp
- Run ID (for failures only — needed for log drill-down)

**Example output format:**

```
=== mt-robotics/smart-chatbot ===
✅  CI Tests           main        2m 14s ago
✅  Deploy to HF       main        2m 30s ago
❌  CI Tests           feature/x   5h ago        (Run ID: 1234567890)
🔄  Deploy to HF       main        running now

=== mt-robotics/portfolio ===
✅  Deploy Pages       main        1d ago
✅  Deploy Pages       main        3d ago
```

### Step 3: Flag Failures

If any run has status `failure`:
- List the repo, workflow, branch, and run ID
- Show the command to view logs:
  ```bash
  gh run view <run-id> --repo <owner/repo> --log-failed
  ```

### Step 4: Summary Line

End with one summary line:
- All green: "All pipelines passing."
- Any failures: "X failure(s) detected — run IDs listed above."
- Any in progress: "X run(s) in progress."

## Adding More Repos

When Monireach creates a new repo, add it to the **Tracked Repos** table above and add a matching `gh run list` command in Step 1.

Format: `gh run list --repo mt-robotics/<repo-name> --limit 5`
