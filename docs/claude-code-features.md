# Claude Code — Advanced Features Reference

**Researched:** 2026-04-28
**Source:** Official Claude Code documentation (code.claude.com/docs)

---

## Table of Contents

1. [Hooks](#1-hooks)
2. [MCP Servers](#2-mcp-servers)
3. [Headless Mode (`claude -p`)](#3-headless-mode-claude--p)
4. [Custom Slash Commands & Skills](#4-custom-slash-commands--skills)
5. [Subagents](#5-subagents)
6. [Memory System](#6-memory-system)
7. [settings.json — Advanced Options](#7-settingsjson--advanced-options)
8. [`.claude/` Project Directory Structure](#8-claude-project-directory-structure)
9. [Claude Code SDK](#9-claude-code-sdk)
10. [Other Features](#10-other-features)

---

## 1. Hooks

Callbacks that fire at lifecycle events in the agentic loop. Can block, allow, transform, or log any tool call automatically.

### Hook Events

| Event | When it fires |
|---|---|
| `PreToolUse` | Before any tool executes — can block |
| `PostToolUse` | After successful execution — can modify output |
| `PostToolBatch` | After a batch of tools completes |
| `SessionStart` / `SessionEnd` | Session init / close |
| `UserPromptSubmit` | Before Claude sees your prompt |
| `Stop` | When Claude finishes responding |
| `PostCompact` | After `/compact` runs |
| `PermissionRequest` | When Claude needs a permission |
| `Notification` | When Claude is waiting for input or idle |

### Exit Codes

- `0` — allow (parse JSON output for decision)
- `2` — block (output is shown to Claude as "permission denied")
- Other — non-blocking error, logged and continues

### Configuration (in `settings.json`)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/script.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

`matcher` accepts:
- `"Bash"` — all Bash tool calls
- `"Bash(rm *)"` — Bash calls where command starts with `rm`
- `"Edit(src/**)"` — Edit calls on matching paths

### Useful Patterns

**Block dangerous commands** (`PreToolUse`):
```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command') or d.get('command') or '')
except:
    print('')
" 2>/dev/null)

if echo "$COMMAND" | grep -qE '(^|\s)sudo\s'; then
    echo "Blocked: sudo requires explicit user approval."
    exit 2
fi
if echo "$COMMAND" | grep -qE 'rm\s.*-[a-zA-Z]*r[a-zA-Z]*\s.*(\/\s*$|~\s*$|\$HOME\s*$|\*\s*$)'; then
    echo "Blocked: recursive delete on broad path."
    exit 2
fi
exit 0
```

**Auto-lint on file edit** (`PostToolUse`, project-level):
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit(src/**/*.py)",
        "hooks": [{"type": "command", "command": "ruff check --fix"}]
      }
    ]
  }
}
```

**Re-inject critical context after compaction** (`PostCompact`):
```json
{
  "hooks": {
    "PostCompact": [
      {
        "hooks": [{"type": "command", "command": "cat ~/.claude/project-critical-facts.md"}]
      }
    ]
  }
}
```

### Configuration Locations

| File | Scope |
|---|---|
| `~/.claude/settings.json` | Global — all projects |
| `.claude/settings.json` | Project — team-shared (commit to git) |
| `.claude/settings.local.json` | Project — personal (git-ignored) |

### Gotchas
- Hooks block the agentic loop while running — keep them fast (<5s)
- Exit code 2 feels like a hard denial to Claude, not a retry request
- `"async": true` runs the hook in parallel without blocking

---

## 2. MCP Servers

Plugins that give Claude new tools — GitHub, databases, monitoring, etc. Claude can query them directly during a session.

### Configuration

In `~/.claude/.mcp.json` (global) or `.claude/.mcp.json` (project):

```json
{
  "mcpServers": {
    "postgres": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {"DATABASE_URL": "${DATABASE_URL}"}
    },
    "github": {
      "type": "http",
      "url": "https://api.github.com",
      "auth": {"bearerToken": "${GITHUB_TOKEN}"}
    }
  }
}
```

### Transport Types

- `stdio` — local process (safer, no CORS issues)
- `http` — remote HTTP server
- `sse` — Server-Sent Events (real-time)

### Useful MCP Servers

| Server | Use |
|---|---|
| `@modelcontextprotocol/server-postgres` | Query dev database directly |
| GitHub MCP | Read issues, PRs, workflow status |
| Sentry / Datadog MCP | Pull production errors and metrics |
| Filesystem MCP | Search and index large codebases |
| Slack MCP | Post team notifications from session |

### Gotchas
- Slow servers get skipped by Claude's tool search — use local stdio when possible
- Large MCP responses (>100KB) are truncated; configure `mcpOutputLimitTokens` to raise limit
- Credentials in `~/.claude/.mcp.json` are local-only; project `.mcp.json` should use env vars
- Token consumption can be high depending on response size — evaluate before adopting

---

## 3. Headless Mode (`claude -p`)

Non-interactive mode for scripting, CI/CD, and cron jobs.

### Key Flags

| Flag | Purpose |
|---|---|
| `-p "prompt"` | Non-interactive mode |
| `--bare` | Skip CLAUDE.md, hooks, MCP (deterministic, CI-safe) |
| `--allowedTools "Read,Edit"` | Pre-approve tools (no permission prompts) |
| `--permission-mode acceptEdits` | Auto-approve file operations |
| `--output-format json` | Capture result + session ID as JSON |
| `--output-format stream-json` | Real-time token streaming |
| `--resume <id>` | Continue a specific session by ID |
| `--continue` | Resume most recent session |
| `--append-system-prompt "..."` | Add instructions for this run |
| `--settings <file>` | Custom settings JSON for this run |
| `--mcp-config <file>` | MCP servers for this run |

### Examples

```bash
# One-off query
claude -p "Summarize this codebase"

# Pipe input
cat build-error.log | claude -p "Explain this error"

# CI-safe security review
claude --bare -p "Review recent changes for security issues" \
  --allowedTools "Read,Bash(git diff *)" \
  --output-format json | jq '.result' > security-$(date +%Y%m%d).txt

# Auto-fix lint in CI
claude --bare -p "Apply ruff fixes to src/" \
  --allowedTools "Read,Edit,Bash(ruff *)" \
  --permission-mode acceptEdits
```

### Gotchas
- `--bare` disables keychain — must use `ANTHROPIC_API_KEY` env var
- No permission prompts in `-p` mode — all tools must be pre-approved
- Anthropic plans to make `--bare` the default for `-p` in a future release

---

## 4. Custom Slash Commands & Skills

### Commands (Simple)

Files in `~/.claude/commands/` or `.claude/commands/`. Invoked with `/command-name`.

```markdown
---
name: commit
allowed-tools: Bash(git add *) Bash(git commit *) Bash(git status *)
---

Review staged changes and create a conventional commit message.
```

### Skills (Advanced)

Files in `~/.claude/skills/<name>/SKILL.md` or `.claude/skills/<name>/SKILL.md`.

Key features over commands:
- **Dynamic context injection**: `` !`command` `` runs before Claude sees the prompt
- **Subagent execution**: `context: fork` runs skill in isolated context
- **Argument support**: `$0`, `$1`, etc.
- **Invocation control**: `disable-model-invocation: true` (only you), `user-invocable: false` (only Claude)

```yaml
---
name: deploy-production
allowed-tools: Bash(npm run *)
---

Pre-flight checks:
- Tests: !`npm test`
- Build: !`npm run build 2>&1 | tail -5`
- Uncommitted: !`git status --porcelain`

If all pass, proceed with deployment.
```

### Skill Locations

| Location | Scope | Git-shared |
|---|---|---|
| `~/.claude/skills/` | All projects | No |
| `.claude/skills/` | This project | Yes |

---

## 5. Subagents

Specialized agents Claude spawns automatically to handle isolated tasks. They have their own context window and restricted tools.

### Define in `.claude/agents/<name>.md`

```yaml
---
name: code-reviewer
description: Review code for bugs, security issues, and performance problems
model: claude-opus-4-6
when-to-use: User asks for code review, or significant changes are made
tools: Read Glob Grep
---

Review code for: bugs (null refs, logic errors, race conditions), security issues
(injection, auth bypass, credential leaks), performance problems.
Report findings with file and line references.
```

Claude auto-delegates when the task matches `when-to-use`. Returns a summary — doesn't pollute main context.

### Benefits

- Context isolation — research stays in subagent
- Tool restrictions — give only what's needed
- Model override — use cheaper models (Haiku) for simple subtasks
- Parallelization — multiple subagents work simultaneously

### Gotchas
- Subagents are fully isolated — they don't see main conversation
- Must pass enough context in the agent definition itself
- Tool restrictions are enforced strictly

---

## 6. Memory System

### CLAUDE.md (You Write)

Persistent instructions loaded every session. Locations in precedence order:

1. Managed (org-wide, enforced): `/Library/Application Support/ClaudeCode/CLAUDE.md`
2. Project (team-shared): `./CLAUDE.md` or `./.claude/CLAUDE.md`
3. User (personal, all projects): `~/.claude/CLAUDE.md`
4. Local (personal, this project): `./CLAUDE.local.md` (git-ignored)

**Best practices:**
- Keep under 200 lines — each line is context consumption
- Be specific: "Use 4-space indentation" beats "Format code nicely"
- Never duplicate universal rules — they auto-load from `~/.claude/rules/`

### Auto Memory (Claude Writes)

Claude takes notes about patterns, corrections, and preferences it discovers.
Stored in `~/.claude/projects/<project>/memory/MEMORY.md` + topic files.
First 200 lines (or 25KB) loaded every session; topic files loaded on demand.

```json
{
  "autoMemoryEnabled": true,
  "autoMemoryDirectory": "~/my-claude-memory"
}
```

### Path-Scoped Rules

Rules in `.claude/rules/` can be scoped to file patterns — only load when Claude edits matching files:

```yaml
---
paths:
  - "src/api/**/*.py"
---

# API Rules
- Validate all inputs with schema
- Use standard error response format
```

Most useful for large projects with both backend and frontend code in the same repo.

---

## 7. settings.json — Advanced Options

### Permission Modes

```json
{
  "permissions": {
    "defaultMode": "plan",
    "allow": ["Bash(npm test *)", "Read(src/**)"],
    "deny": ["Bash(sudo *)", "Bash(rm -rf *)", "Read(.env*)"]
  }
}
```

| Mode | Behavior |
|---|---|
| `default` | Ask for each tool |
| `acceptEdits` | Auto-approve file operations |
| `plan` | Read-only; propose plan before acting |
| `bypassPermissions` | Approve everything (dangerous) |

### Other Useful Settings

```json
{
  "env": {
    "NODE_ENV": "development",
    "MY_VAR": "${SHELL_VAR}"
  },
  "model": "claude-sonnet-4-6",
  "alwaysThinkingEnabled": false,
  "autoMemoryEnabled": true,
  "autoCompactEnabled": false,
  "sandbox": {
    "filesystem": {
      "denyRead": ["~/.ssh", "~/.aws", "~/.gnupg"]
    }
  }
}
```

---

## 8. `.claude/` Project Directory Structure

```
my-project/
├── CLAUDE.md                    # Project instructions
├── CLAUDE.local.md              # Personal overrides (git-ignored)
└── .claude/
    ├── settings.json            # Team config (commit to git)
    ├── settings.local.json      # Personal config (git-ignored)
    ├── .mcp.json                # MCP servers (project scope)
    ├── keybindings.json         # Custom keyboard shortcuts
    ├── skills/
    │   └── <name>/SKILL.md
    ├── agents/
    │   └── <name>.md
    ├── rules/                   # Auto-loaded into context
    │   ├── backend.md           # Optional: path-scoped
    │   └── frontend.md
    └── hooks/
        └── hooks.json           # Alternative hooks location
```

---

## 9. Claude Code SDK

Programmatic API for building agents — same runtime as CLI but with structured outputs, tool approval callbacks, streaming, and session management.

### Python

```python
from anthropic_code import query, tool

@tool
def my_tool(input: str) -> str:
    return "result"

result = query(
    "Do something",
    tools=[my_tool],
    allowedTools=["Read", "Bash(git *)"]
)
print(result)
print(result.session_id)  # Resume later
```

### TypeScript

```typescript
import { query, tool } from "@anthropic-ai/sdk/claude-code";

const result = await query("Do something", {
  tools: [myTool],
  allowedTools: ["Read"]
});
console.log(result.result);
```

### Features
- Real-time token streaming
- Per-turn cost tracking
- Tool approval callbacks
- Session checkpointing and resumption
- Programmatic subagent spawning

---

## 10. Other Features

### Extended Thinking
- Toggle: `Meta+T` in session
- Always on: `"alwaysThinkingEnabled": true` in settings
- On-demand: include "ultrathink" anywhere in your prompt
- Best for: architectural decisions, complex bugs, security reviews

### `/usage`
Shows tokens used + cost for the current session. Useful for identifying context bloat.

### Plan Mode
```bash
claude --permission-mode plan
```
Claude reads files and proposes a plan before touching anything. Good for high-risk refactors (auth, billing).

### Keybindings (`~/.claude/keybindings.json`)
```json
{
  "bindings": [
    {
      "context": "Chat",
      "bindings": {
        "ctrl+shift+t": "chat:thinkingToggle",
        "ctrl+g": "chat:externalEditor"
      }
    }
  ]
}
```
Vim mode: `"editorMode": "vim"` in settings.json.

---

## Quick Reference — What to Actually Implement

| Feature | Worth implementing when... |
|---|---|
| Hooks (dangerous block) | Always — set it globally once |
| Hooks (auto-lint) | Project has a linter; add to `.claude/settings.json` per project |
| Path-scoped rules | Project has both backend + frontend code in one repo |
| Subagent definitions | You have a repeatable specialized task (code review, research) |
| MCP servers | Specific integration need that's awkward via CLI |
| `claude -p` headless | You have a workflow to automate in CI or cron |
| Extended thinking | Complex architectural or security decisions |
