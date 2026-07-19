# Claude Agent Core — Master Instructions

Universal rules are loaded from `~/.claude/rules/` automatically at every session.
This file handles project-type routing, standard project structure, and session initialization patterns.

---

## Project Type System

Every project declares its type in its `CLAUDE.md`. At session start:

1. Read the project's `CLAUDE.md` — note the declared project type
2. Apply the category rules for that type

| Project Type        | Rules that apply                                                                         |
| ------------------- | ---------------------------------------------------------------------------------------- |
| `coding`            | Read `agent_core/rules/project-types/coding.md` — it lists which standards files to read |
| `research-academic` | Read `agent_core/rules/project-types/research-academic.md`                               |
| `personal`          | Universal rules only — no additional file needed                                         |

**Universal rules** (`~/.claude/rules/` = `agent_core/rules/universal/`) are auto-loaded every session.
**Project-type rules** (`agent_core/rules/project-types/`) are NOT auto-loaded — read them explicitly at session start based on the project type declared in the project's `CLAUDE.md`.

If no project `CLAUDE.md` exists: ask the user the project type before starting work.

---

## Standard Project File Structure

Every coding project must have these files. Verify they exist before starting work; if any are missing, flag it.

| File / Directory                  | Purpose                                                                                                                              |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `CLAUDE.md`                       | Project type declaration + project-specific rules only. Never put universal rules here.                                              |
| `.claude/`                        | Project-specific Claude config: `rules/` (standards files), `settings.local.json`                                                    |
| `PROJECT.md`                      | Internal navigation hub — current focus, tech stack, directory map, context loading guide                                            |
| `README.md`                       | External docs — what it is, setup, API, stack. For public/recruiter audience.                                                        |
| `DOCKER_SETUP.md`                 | Docker and environment variable reference (required if project uses Docker — skip only when explicitly no Docker)                    |
| `current_state/project_status.md` | Current state + active tasks + backlog (source of truth for what's live NOW)                                                         |
| `current_state/milestone.md`      | Full detail archive of completed tasks (rows flow here from `project_status.md`)                                                     |
| `current_state/bugs.md`           | **Optional** - open bug tracker; mirrors `project_status.md` structure. See `documentation-structure.md` §10.4.                      |
| `current_state/resolved_bugs.md`  | **Optional** - resolved bug archive; mirrors `milestone.md` structure. Paired with `bugs.md` - a project either has both or neither. |
| `archive/daily_log.md`            | Session-by-session log of decisions, blockers, and progress                                                                          |
| `docs/error_log.md`               | Debugging investigations requiring root cause analysis                                                                               |
| `.env.example`                    | Documents all required environment variables (no real values — always safe to commit)                                                |

**Rule:** Verify in `project_status.md` (and `bugs.md` if that pair exists) before assuming any feature is built or any bug is open. Do not trust memory or conversation history.

---

## Session Initialization (Coding Projects)

When user says `initialize` at the start of a session for a coding project:

**Step 1 — Coding-universal symlink check (run immediately):**

```bash
CODING_UNIVERSAL="$(dirname "$(readlink ~/.claude/rules)")/project-types/coding-universal"
ls .claude/rules/coding-universal &>/dev/null \
  && echo "symlink exists" \
  || (ln -s "$CODING_UNIVERSAL" .claude/rules/coding-universal && echo "symlink created")
```

- If **symlink exists**: the 6 coding-universal files were auto-loaded at startup — proceed
- If **symlink just created**: explicitly read all 6 files now (resolve full path via `readlink ~/.claude/rules` → replace `universal` with `project-types/coding-universal/`):
  - `documentation-structure.md`, `git-workflow.md`, `logging-workflow.md`, `project-navigation.md`, `session-management.md`, `testing-commands.md`

**Step 2 — Follow `session-management.md §9.1`** for the full initialization procedure.

---

## Project CLAUDE.md — What Must Never Appear

Project CLAUDE.md files are committed to git and may be public. Never write:

- The owner's name — use "the user" or impersonal phrasing
- Personal traits described as flaws (perfectionism, paralysis, etc.) — these belong in `agent_core/rules/` only
- Blame or self-critical language about past incidents ("careless", "catastrophic due to my mistake")
- Real people's names (collaborators, clients, presenters) — use roles instead ("the presenter", "the client")
- Absolute paths containing personal info (email addresses, usernames embedded in Google Drive paths)
- Universal rules verbatim — they are auto-loaded from `~/.claude/rules/`; duplicating them in project CLAUDE.md adds noise and causes drift

---

## Project CLAUDE.md — Minimal Template

Every new project's CLAUDE.md should follow this pattern (populated by `/start-local-dev`):

```markdown
# CLAUDE.md — [Project Name]

## Project Type

`coding`

## Session Initialization

Follow `session-management.md §9.1`. Also read on demand:

- `current_state/milestone.md`
- `DOCKER_SETUP.md`
  [add project-specific files here as they emerge]

Rule: verify in `project_status.md` before assuming something is built.

## End Session

Follow `logging-workflow.md §2.5`. Additionally:

- Update `current_state/project_status.md`
- Update `PROJECT.md` only if structure/stack/architecture changed

## Doc Sync Rule

| Changed in `project_status.md`     | Sync target                  |
| ---------------------------------- | ---------------------------- |
| Task completed                     | `current_state/milestone.md` |
| Features, API, tech stack, roadmap | `README.md`                  |
| Deployment, env vars               | `DOCKER_SETUP.md`            |

[add project-specific rows here]

## Bug Tracker (Optional)

If this project uses the `current_state/bugs.md` + `current_state/resolved_bugs.md` pair (see `documentation-structure.md` §10.4), add a one-line pointer under `## Current State` in `project_status.md`.
`Bug tracker: see [current_state/bugs.md](bugs.md); resolved entires in [current_state/resolved_bugs.md](resolved_bugs.md).`
```
