---
name: vibe-code
description: Use this skill when the user invokes "/vibe-code". Activates vibe coding mode. Agent owns implementation, detects frontend/backend mode, and applies stack-appropriate verification while Monireach reviews and directs.
version: 1.5.1
---

# Vibe Code

Same framework as code-coach. Same rigor. Agent does all the coding.

Monireach's role: own decisions, write requirements, trace critical paths, write owner notes. Not write code.

---

## Ownership Loop

```
Old loop:         AI decides → AI writes → AI verifies → user approves
Interactive loop: User decides → AI writes → AI verifies → user traces → user summarizes
Autonomous loop:  AI implements → AI verifies → user studies chosen tasks later via /guided-explore debrief
Frontend:         AI owns 100% — no gates
```

---

## Autonomous Mode — Git Commit Permission

Invoking `/vibe-code` activates **fully autonomous operation**.

- **Git commits are pre-approved for this session.** Do NOT pause or ask for confirmation before `git commit`. Stage and commit completed work as you finish each task.
- **Push to remote is NOT pre-approved.** Still requires explicit user confirmation.
- This overrides the default "confirm before commit" rule in `user-confirmation.md` for the duration of this session.
- Applies to all agents running in vibe-code mode (Claude Code, Codex, sub-agents).

---

**Architectural decisions:** For concepts Monireach hasn't yet learned, Agent makes the decision and states the reasoning in one sentence, then moves on. As Monireach's knowledge grows (tracked via Gate 2 owner notes and `/guided-explore` debriefs), he can and should redirect any decision he disagrees with — that authority always belongs to him. Do NOT present a list of options and ask him to pick without explaining which is better and why.

---

## Git Branching Workflow (Mandatory)

Every atomic task runs on its own feature branch. This is non-negotiable.

**Before starting each atomic task:**
1. Run `git fetch origin` — sync remote state without touching local branches
2. Create: `git checkout -b feature/<task-slug> origin/development` (e.g. `feature/chromadb-readiness-check`) — always branch from `origin/development`, never from local `development`
3. **IMMEDIATELY write the dev notes file skeleton** — this is the FIRST tool call after branch creation, before reading any source file:
   - Backend/devops: `Write("archive/development_notes/YYYYMMDD_feature/task.md", "# TaskName\n\n## Step 0\n## Step 1\n...")`
   - Frontend: same path, lightweight format
   - **Path must be in the MAIN project checkout** (`~/projects/<repo>/archive/development_notes/...`), NOT inside a worktree directory — worktrees are deleted at cleanup and the file would be lost
   - If this `Write` call has not happened yet → do NOT call `Read`, `Edit`, or `Write` on any implementation or test file. No exceptions.
4. Do all remaining work and commits on that branch only — never on `development` directly

**After Step 7 passes (task complete and tested):**
4. Verify required task record is complete (backend/devops: full dev note; frontend: lightweight frontend dev note)
5. Run the independent assessment (see Step 7: the `adversarial-verifier` subagent) — if FAIL, apply its REQUIRED_FIXES and re-run Step 7 before proceeding; if the subagent is unavailable (agent file missing), apply the self-review fallback defined in Step 7
6. Stage and commit all changes on the feature branch
7. Push the feature branch and open a PR: `git push -u origin feature/<task-slug>` then `gh pr create --base development --head feature/<task-slug>` — **never merge into local `development`**
8. For the next task: run `git fetch origin` and branch from `origin/development` again (`git checkout -b feature/<next-slug> origin/development`)
   - If the previous PR has already been merged: `origin/development` includes that work — the next task builds on it naturally
   - If the previous PR is still open: the next task is independent and branches from the current `origin/development` state; tasks that depend on the unmerged PR must wait for it to be merged before starting

**Rules:**
- Never work directly on `development`, unless Monireach explicitly instructs it
- Never merge a feature branch into local `development` — this creates divergence when `development` is push-protected (the local commits get different SHAs than the cherry-picks created during PR creation, causing `git pull` to fail with "divergent branches")
- Only create the PR after: (a) all tests pass AND (b) the `adversarial-verifier` subagent returns PASS, OR (b′) subagent unavailable and self-review passes
- Do not wait for Monireach between independent feature branches — push the PR and start the next task autonomously

---

## Worktree Parallelization (Optional — independent tasks only)

When multiple independent atomic tasks exist in a session, vibe-code can run them in parallel using `git worktree`. The main checkout stays on `development`; each task gets its own feature branch and isolated directory.

**Core model:**
- Main checkout stays on `development` for review and merge — do not move it.
- Each independent task gets its own feature branch + dedicated worktree directory.
- Implementation and verification happen only inside that worktree.

**Workflow (per independent task):**
1. `git fetch origin && git worktree add ~/projects/<repo>_<feature_slug> -b feature/<feature_slug> origin/development` — Git creates the directory, branching from `origin/development`.
2. All work runs inside `~/projects/<repo>_<feature_slug>` only.
3. After review: `git push -u origin feature/<feature_slug>` then `gh pr create --base development --head feature/<feature_slug>` — merge via PR on GitHub; do NOT merge into local `development`.
4. Cleanup after the PR is merged: `git worktree remove ~/projects/<repo>_<feature_slug>` then `git branch -d feature/<feature_slug>`.

**Naming convention:** `~/projects/<repo>_<feature_slug>` (e.g. `~/projects/smart_chatbot_is-blocked-column`).

**Safety rules:**
- Only parallelize tasks with **disjoint write scopes** — no shared files, no shared Alembic migration path.
- Never put multiple features in one worktree.
- If two tasks touch the same files or the same migration chain → keep them sequential in one branch instead.
- Always record per worktree: path, owning feature branch, intended merge target, cleanup status.
- **Dev notes MUST be written to the main project path** (`~/projects/<repo>/archive/development_notes/...`), NOT inside the worktree directory. Worktrees are deleted at cleanup — any file written inside them is permanently lost.

**Ops summary (mandatory at end of any session that used worktrees):**
```
Worktree session summary:
  Created:  <worktree path> → <branch>
  Merged:   <branch> into development
  Cleaned:  <worktree path> removed, <branch> deleted
  Pending:  <branch> — awaiting manual testing
```

---

## Task Classification

Classify BEFORE starting. Announce immediately.

### Declarative Task
Pure structural code with no logic or behavior. Examples:
- SQLAlchemy model definition
- Pydantic schema definition (no validators)
- Import addition
- Config value change

**What to do:** Steps 0–3c only. Skip Steps 4–7. Write notes, implement, done.

### Simple Task
Small logic change ≤5 lines, obvious bug fix, rename, typo fix.

**What to do:** No framework. State what you're changing and why. Do it. Done.

### Atomic Task
Real logic or behavior: new function, endpoint, middleware, utility, integration, query filtering, page workflow, client state, or API wiring — anything requiring verification.

**What to do:** Full framework, Steps 0–7 + Gate 1 (interactive) and Gate 2 (interactive). No shortcuts.

---

## Division of Responsibility

Agent owns all steps. Monireach owns decisions, requirements, and owner notes.

| Step | Owner | What happens |
|------|-------|-------------|
| Gate 1: Requirement | **Monireach** | Interactive + atomic + backend/devops only. Monireach writes requirement draft in plain English. Agent asks 2–3 diagnostic questions per round; if answers surface new gaps, another round follows. Gap found in any round → Agent teaches + optional Jupyter skeleton → Monireach re-answers. Gate ends when no gaps remain — rounds are unbounded, 2–3 questions per round keeps each exchange digestible. **Skip for: Declarative, Simple, frontend, autonomous mode.** |
| Step 0: Context Check | Agent | Read relevant files. Pass/fail. **Declare domain (frontend / backend / devops / none). Standards are always in context — no `.claude/rules/` check needed. If the relevant domain standards are genuinely absent from context, warn Monireach and use the cheatsheet fallback (see Standards section).** |
| Step 1: Requirement | Agent | Formalize the Gate 1 requirement draft into one sentence + Pydantic schemas if applicable. In autonomous mode (Gate 1 skipped): Agent writes the requirement directly. |
| Step 2: Research | Agent | Identify library/function/approach. |
| Step 3a: Gherkin | Agent | **Read-first rule (AC precedence):** if the task's detail section in `project_status.md` carries an `**Acceptance:**` Gherkin block (written at phase planning), READ it and use it as-is — it is the source of product intent; do NOT author a second one. Only if no such block exists: author a task-local Given/When/Then block as fallback AND note the gap in the dev note ("no phase-planning AC — authored task-local"). Never two competing AC sets for one task. When authoring fallback AC, **think adversarially:** for each happy path, ask "what input, state, or caller behavior would break this?" Write negative scenarios only for genuine failure modes. If no meaningful negative scenarios exist, state why in one sentence — do not invent them to fill a quota. |
| Step 3b: Nouns/Verbs | Agent | Extract nouns and verbs. |
| Step 3c: Stubs | Agent | Write stubs with correct signatures. **Run §1 "At Design/Scaffold Time" checks + relevant domain section from project standards (or cheatsheet fallback — as determined at Step 0).** For backend/devops tasks only: write dataflow diagram JSON/SVG using `/Users/monireach/projects/dataflow_diagram/CONVENTIONS.md`, self-audit layout before generating, visually check the SVG, and embed the SVG path in the notes file. For frontend tasks: skip dataflow diagrams. |
| Step 4: Failing Test | Agent | Backend/devops: convert the Step 3a AC into failing tests (the TDD seed), run them, confirm Red. **The seed must include deny-path + boundary tests, not just the happy `Then`.** State-assertion ACs convert mechanically; async/eventual/infra ACs (job retries, webhook idempotency, migration reversibility) do NOT — map each to a named test+fixture pattern (time control/fake clocks, fake brokers, migration downgrade round-trips) instead of quietly downgrading the AC to a trivial assertion. **Test pyramid:** AC tests verify behavior at acceptance altitude; unit tests own branch coverage of logic-bearing modules independently — a green AC suite is NOT complete coverage. Frontend: write or update unit/component/E2E tests when a test stack exists; if no test stack exists, record the gap and proceed with lint/build/manual smoke verification. |
| Step 5: Passing Code | Agent | Write the implementation. Backend/devops: run the target test and confirm Green. Frontend: run the relevant discovered verification gate and confirm the changed behavior is covered or manually smoke-tested. |
| Step 6: Refactor | Agent | Clean up. Run full suite. Confirm Green. **Run §1 "At Refactor Time" checks + relevant domain section from project standards (or cheatsheet fallback — as determined at Step 0).** |
| Step 7: Integration | Agent | Run the relevant full verification gates. Manual test if needed. **Fresh machine check:** ask "Would this work on a fresh machine with only the committed files?" If no → close the loop immediately (.env.example, docker-compose, Dockerfile, nginx.conf, etc.) or create a 🔲 task in project_status.md if it can't be done now. **Independent assessment (autonomous mode): pre-commit by default.** First, stage all task files: `git add <relevant files>` — untracked new files are invisible to `git diff` but appear in `git diff --cached`. **Assessment engine:** spawn the `adversarial-verifier` subagent as the independent assessment, after the verification gates pass and before creating the task commit. Pass it: the task's detail section from `project_status.md` (including its `**Acceptance:**` block when present) and the project root. It reads the staged diff (`git diff --cached` — which is why staging first matters), forces a pass/fail/not-covered verdict per AC scenario with file:line evidence, runs the test suite itself, and returns VERDICT + GAPS + REQUIRED_FIXES. If it returns FAIL: apply its REQUIRED_FIXES, rerun the relevant verification gates, and re-spawn the verifier — record each round's verdict in the dev note; max 3 rounds, after a 3rd FAIL the task is blocked (write the blocker into the task's detail section, do not merge). **Commit only after the verifier returns PASS.** Its GAPS (even on PASS) become 🔲 tasks in project_status.md before moving on. When the `/design-audit` skill is installed it remains a complementary spec-level audit, but the verifier's verdict is the merge gate. **If the subagent cannot be spawned (agent file missing or Task tool unavailable):** fall back to self-review — verify (1) relevant verification gates pass, (2) required task record is complete, (3) fresh machine check is done — document outcome in the task record as "Independent assessment unavailable (adversarial-verifier missing) — self-review PASS" and proceed if all three pass. **Bug fix tasks — `/log-error` gate:** after all tests pass and fresh machine check is done, ask: was the root cause non-obvious? (masked by a mock, a missing mount, a migration side-effect, a renamed method, etc.) If YES → invoke `/log-error` before merging. If NO (trivially obvious fix: typo, wrong variable name) → skip. |
| Gate 2: Owner Note | **Monireach** | Interactive + atomic + backend/devops only. Triggers after Step 7 passes. Monireach writes a 5–7 line owner note (see Gate 2 section). Gap found → trace path together → Monireach rewrites. No gap → task done. **Skip for: Declarative, Simple, frontend, autonomous mode.** |

**Checkpoint rule:** After each Monireach-facing checkpoint (Steps 3c, 5, 7), pause and wait for approval before continuing. **Exception — autonomous mode (vibe-code):** Skip all pause-and-wait checkpoints. Use the `adversarial-verifier` subagent gate at Step 7 instead of waiting for Monireach. Gate 2 is skipped entirely — learning happens post-hoc via `/guided-explore task: <slug>` on the tasks Monireach chooses.

**Exception override:** If Monireach says "I'll do [step name]", hand it to him immediately.

---

## Before Starting

Always read from source EVERY session (do NOT rely on memory):

```
/Users/monireach/Google Drive/My Drive/monireach/deliverables/software_ai_engineering/engineering_practices/atomic_coding_framework.md
```

Engineering standards (`backend-standards.md`, `frontend-standards.md`, `devops-standards.md`) are **always injected into context** via the global CLAUDE.md — they do not need to be read proactively and no `.claude/rules/` check is needed. Do NOT use Glob to verify the rules directory; symlinks are invisible to Glob and will produce a false "not found" alarm.

**Fallback only — read these if the relevant domain standards are genuinely missing from context** (i.e. not listed in the claudeMd system reminder at all):

```
/Users/monireach/Google Drive/My Drive/monireach/deliverables/software_ai_engineering/engineering_practices/code_quality_dimensions.md

/Users/monireach/Google Drive/My Drive/monireach/deliverables/software_ai_engineering/engineering_practices/engineering_standards_cheatsheet.md
```

---

## Project Mode Detection

Detect the project mode before planning:

1. If `package.json` exists at the project root and no Python manifest exists (`pyproject.toml`, `requirements.txt`, `setup.py`) → **frontend mode**
2. If Python manifests exist and no `package.json` exists → **backend mode**
3. If both exist → ambiguous full-stack/monorepo; ask whether this session is frontend, backend, devops, or both before planning
4. Optional overrides such as `$vibe-code --frontend` or `$vibe-code --backend` may force the mode when autodetection is wrong

### Frontend Mode

Frontend mode keeps the rigor but removes backend-only artifacts.

**Skip in frontend mode:**
- Backend-style long Step 0–7 development notes
- Dataflow diagram JSON/SVG generation
- `pytest` assumptions
- Gate 1 and Gate 2 (AI owns frontend 100%)

**Keep in frontend mode:**
- Feature branch workflow
- Task classification
- Steps 0–7, with frontend-native verification
- Lightweight frontend development notes in `archive/development_notes/YYYYMMDD_feature_name/`
- Independent `adversarial-verifier` subagent review gate

**Frontend verification policy:**
- Read `package.json` and discover scripts; do not hardcode `npm test`, `pnpm test`, or framework commands
- Run available gates in this order:
  1. `lint` if present
  2. `test:unit` or `test` if present
  3. `build` if present
  4. `test:e2e` only when a route, page, navigation, auth flow, or critical user workflow changed and Playwright/Cypress is configured
- If no test framework exists, flag it as a project gap; do not add a new test stack unless the task explicitly requires test infrastructure
- For UI-visible changes, run the dev server and do a manual browser smoke test when feasible; use screenshots or browser inspection when layout, loading states, or responsive behavior changed
- Apply `frontend-standards.md` and `ux-standards.md` when present; do not duplicate their contents in this skill

**Framework detection from `package.json`:**
- `next` → Next.js
- `react` / `react-dom` → React
- `nuxt` → Nuxt
- `vue` → Vue
- `@angular/core` → Angular
- `svelte` → Svelte
- unknown → generic Node frontend; still use script discovery

---

## Session Planning (Mandatory — runs once before the first feature branch)

After reading the framework and before creating any feature branch:

**Step 0 — Detect project mode:**
- Apply the Project Mode Detection rules above
- In frontend mode, use the Frontend Mode workflow and verification policy
- In backend/devops mode, use the full notes + dataflow diagram workflow

**Step 1 — Read project state:**
1. `PROJECT.md` — understand tech stack, directory map, current focus
2. `current_state/project_status.md` — identify what is done and what is in the active backlog for the current version

**Step 1b — Verifier pre-flight check (autonomous mode only):**
Run `test -f ~/.claude/agents/adversarial-verifier.md` to verify the verifier subagent is installed.
- If it exists: independent assessment is available — proceed normally.
- If it is missing: log `⚠️ adversarial-verifier subagent unavailable — independent assessment will fall back to self-review for all Step 7 gates this session` in the first task record, and continue. Do NOT block.

**Step 2 — Identify all tasks:**
- Combine: tasks from the user's request + active backlog items for the current version
- Classify each as Declarative, Simple, or Atomic
- Order them so dependencies come before the tasks that need them

**Step 3 — Register with TaskCreate:**
- Create one TaskCreate entry per task
- Use the task slug as the subject (same slug will be used for the feature branch name)

**Step 4 — Post the plan:**

| Mode | What to do |
|---|---|
| **Interactive** | Post the full task list in chat. Pause and wait for Monireach to approve, reorder, or cut tasks before starting any work. |
| **Autonomous** | Post the full task list in chat. Do NOT pause — immediately start Task 1. Monireach sees the list when he wakes up. |

**Task list format (both modes):**
```
Session plan — N tasks identified:

#1 [Atomic]     feature/task-slug-one       — one-line description
#2 [Atomic]     feature/task-slug-two       — one-line description (depends on #1)
#3 [Simple]     —                           — one-line description
#4 [Declarative] —                          — one-line description

Starting with #1.
```

Simple and Declarative tasks do not get a feature branch — they are done on `development` directly.

---

## Output Rule (CRITICAL)

**Do NOT dump Steps 0–3b as a wall of text in chat.**

### Backend / DevOps Mode

**ENFORCEMENT — dev notes file must exist before any source file is read or edited:**
The notes file skeleton was written immediately after `git checkout -b` (step 3 of Git Branching Workflow). If it was not, stop — write it now before proceeding. Skipping this in the past (2026-05-28, B4–B6) caused undocumented implementation decisions and lost context. There is no exception.

Process:
1. Notes file skeleton already exists from branch creation (see Git Branching Workflow step 3)
2. Fill in Steps 0–3b in the notes file, then in chat post ONE line per step as a summary + file path:

```
Notes → archive/development_notes/YYYYMMDD_feature_name/task_name.md
- Step 0: PASS
- Step 1: [one-line summary of requirement]
- Step 2: [one-line summary of tools/libraries]
- Steps 3a/3b: Gherkin + components written
- Step 3c: Stubs written — ready for your review
```

Monireach reads the file for details. Chat is navigation only.

**Steps 4–7 — update the notes file as each step completes (MANDATORY):**

Never leave Steps 4–7 as placeholders. After completing each step, append its content to the notes file immediately — before posting the one-line chat summary. The notes file must be fully filled in by the time Step 7 is done.

| Step | What to write in the notes file |
|------|--------------------------------|
| Step 4 | Test file path + test case names + Red confirmed (output snippet) |
| Step 5 | Files written + key implementation decisions + Green confirmed (output snippet) |
| Step 6 | Linting/type errors fixed + refactor decisions + full suite result |
| Step 7 | Final suite result + manual integration path (how to verify end-to-end) + fresh machine check outcome (passed / what was closed or deferred) |

---

### Frontend Mode

Create a lightweight frontend development note at `archive/development_notes/YYYYMMDD_feature_name/<task-slug>.md`.

Do not use the backend Step 0–7 note format for frontend tasks.

Frontend note format:

```markdown
# Frontend Task — <task-slug>

**Mode:** frontend
**Framework:** <detected framework>
**Branch:** feature/<task-slug>

## Requirement
<one sentence>

## Files Changed
- <path>: <what changed>

## Verification Plan
- Lint: <command or not configured>
- Unit/component: <command or not configured>
- Build: <command or not configured>
- E2E/manual smoke: <planned check or skip reason>

## Verification Results
- Lint: <result>
- Unit/component: <result>
- Build: <result>
- E2E/manual smoke: <result>

## Fresh Machine Check
<pass/deferred and why>

## Gaps / Follow-Up
- <test gap, backend dependency, or none>
```

Use concise chat checkpoints instead:

```
Frontend task — feature/task-name
- Mode: frontend ([detected framework])
- Requirement: [one sentence]
- Files planned: [paths]
- Note: archive/development_notes/YYYYMMDD_feature_name/task-name.md
- Verification planned: lint=[yes/no], unit=[yes/no], build=[yes/no], e2e=[yes/no + reason]
```

After implementation, report:

```
Frontend verification
- Lint: [command/result or not configured]
- Unit/component: [command/result or not configured]
- Build: [command/result or not configured]
- E2E/manual smoke: [what was checked or why skipped]
- Fresh machine check: [pass/deferred]
```

---

## Documentation

Backend/devops tasks use the full note format below. Frontend tasks use the lightweight frontend note format above.

### File location

Notes go in: `{project_root}/archive/development_notes/{YYYYMMDD}_{feature_name}/{task_name}.md`

- `YYYYMMDD` = date the feature/task group was started
- Tasks with no parent feature: use `YYYYMMDD_core/` or `YYYYMMDD_misc/` as the subdirectory
- `docs/diagrams/` is reserved for shared architecture diagrams referenced from README only — not task-level diagrams

**Co-located artifacts (same subdirectory as the dev note):**
- `task_name.ipynb` — Gate 1 gap simulation (interactive) or practice notebook generated later by `/guided-explore` debrief
- `task_name.json` — dataflow diagram source
- `task_name.svg` — dataflow diagram output (generated); embed this path in the dev note

### When to create vs append

- **New task** → create a new file inside the feature subdirectory
- **Continuing an existing task** → read the existing file first, then append only the missing steps

### File format

```markdown
# Step 0: Context Check
...

# Step 1: Requirement
...

# Step 2: Research
...

# Step 3: Scaffold

## Step 3a: Gherkin Block
...

## Step 3b: Extract Components
...

## Step 3c: Stubs
...

# Step 4: Failing Test
...

# Step 5: Passing Code
...

# Step 6: Refactor
...

# Step 7: Integration Test
...
```

---

## Career-First Principle

Monireach is building this system for career growth. Tasks with real logic and behavior are high-value. Declarative scaffolding is not.

**When a task is purely structural:** say so, handle it fast, move on.

**When a task has real behavior:** follow the full framework without shortcuts.

If a proposed task has no meaningful logic and won't make for a good interview story, say so before starting.

---

## Gate 1: Requirement Ownership (Interactive, Atomic, Backend/DevOps only)

**Trigger:** At the start of every atomic backend/devops task in interactive mode — before Step 0.

**Skip for:** Declarative tasks, Simple tasks, frontend mode, autonomous mode.

### Procedure

0. **Spec-first load (Gate 1 shrink):** if `docs/prd.md` exists (or, failing that, a legacy root `PRODUCT_SPEC.md` — read it and tell the user once to migrate it by re-running /product-spec), FIRST read what it already answers for this task — which actors touch it (spec §1), the entity lifecycle cells it implements (§3 CRUD matrix), the journey arrows it serves (§4), and relevant NFRs/non-goals (§5/§6). Present those as the established baseline. The diagnostic rounds below then cover ONLY residual gaps the spec does not answer. Full elicitation (all questions from scratch) applies only when no spec exists. **The owner never answers the same question twice.**
1. Agent prompts: "Write your requirement draft in plain English — what should this task do?"
2. Monireach writes the draft (any length, informal language is fine).
3. Agent reads the draft and asks **2–3 focused diagnostic questions per round** — covering the most critical gaps it sees first (skipping anything the spec already answered in step 0). Examples:
   - "Who calls this endpoint and what does it return?"
   - "What changes in the database when this runs?"
   - "What should happen if the input is invalid / the external call fails?"
4. Monireach answers the round.
5. **If answers reveal new gaps** → Agent asks another round of 2–3 questions covering the newly surfaced gaps. Repeat until no gaps remain.
6. **During any round, if a gap is found** (Monireach can't answer a question confidently):
   - Agent explains the concept in 2–3 sentences.
   - Agent optionally scaffolds a minimal Jupyter notebook skeleton (`task_name.ipynb`) co-located with the dev note — Monireach fills in the logic, sees it fail then fix, explains back in one sentence.
7. **When no gaps remain** — implementation proceeds (Step 0 onward).

**Rule:** Gate 1 ends when all gaps are closed, not when a question count is hit. 2–3 per round keeps each exchange digestible; the number of rounds is unbounded.

### Gate 1 in autonomous mode

Gate 1 is **skipped**. Agent writes the requirement at Step 1 directly. No learning artifact is created during the run — Monireach studies completed tasks afterwards via `/guided-explore task: <slug>` (Completed-Task Debrief mode), which generates practice notebooks on demand.

---

## Gate 2: Owner Note (Interactive, Atomic, Backend/DevOps only)

**Trigger:** After Step 7 passes, before merging the feature branch.

**Skip for:** Declarative tasks, Simple tasks, frontend mode, autonomous mode.

### Procedure

1. Agent prompts: "Write your owner note for this task."
2. Monireach writes 5–7 lines covering:
   - **What it does** — one sentence
   - **Files touched** — list the files and tables changed
   - **Failure symptoms** — what breaks and how it looks to the user or in logs
   - **Recovery pointer** — "If this breaks, open `[file]` first, then check `[table/service]`"
3. **If the note has gaps** (missing a file, vague failure symptoms, no recovery pointer):
   - Agent traces the request path together with Monireach.
   - Monireach rewrites the note.
4. **If the note is complete** — task is done. Agent merges the feature branch.

### Owner note file

Saved co-located with the dev note:
`archive/development_notes/YYYYMMDD_feature_name/task_name_owner_note.md`

---

## Autonomous Mode — Learning Handoff

Engineering and learning logic are fully separated (owner decision 2026-06-12). Autonomous runs create NO learning artifacts — no practice notebooks, no owner notes. The dev notes (Steps 0–7 records) are engineering records and remain mandatory; they double as the raw material for learning later.

After the session, Monireach studies the tasks he chooses via `/guided-explore task: <slug>` (Completed-Task Debrief mode), which loads the dev note + diff + AC block and generates a practice notebook on demand. The session's final report should end with one line listing the completed task slugs as debrief candidates.

---

## Anti-Patterns to Avoid

- ❌ Skipping task classification
- ❌ Dumping Steps 0–3b as chat text in backend/devops mode — write the file first, summarize in one line each
- ❌ Enforcing Steps 4–7 on declarative tasks — there is no behavior to test
- ❌ Moving past a checkpoint without Monireach's approval (exception: autonomous vibe-code mode — use the `adversarial-verifier` subagent gate at Step 7; Gate 2 is skipped, learning happens via `/guided-explore` debrief)
- ❌ Explaining concepts not needed for the current step
- ❌ Spending time on tasks with no career or business value without flagging it
- ❌ Writing code without running it to verify (Red/Green must be confirmed, not assumed)
- ❌ Skipping the quality checklist at Step 3c and Step 6 — security, performance, and UX are not optional afterthoughts
- ❌ Leaving Steps 4–7 as placeholders in the backend/devops notes file — update the file immediately after each step completes, before the chat summary
- ❌ Presenting options without a recommendation — always state which is better and why, then decide. Monireach can redirect if he disagrees.
- ❌ Skipping Gate 1 in interactive mode for atomic backend/devops tasks — if Monireach hasn't written a requirement draft, ask for it before Step 0
- ❌ Skipping Gate 2 in interactive mode after Step 7 for atomic backend/devops tasks — task is not done until the owner note is written and gap-free
- ❌ Creating a flat dev note at `archive/development_notes/YYYYMMDD_task_name.md` — use the nested feature directory: `archive/development_notes/YYYYMMDD_feature_name/task_name.md`
- ❌ Running parallel worktrees on tasks that share files or the same Alembic migration path — keep them sequential
- ❌ Skipping `/log-error` for bug fix tasks with a non-obvious root cause — if the bug was masked by a mock, a missing config, a migration side-effect, or any other subtle mechanism, it belongs in `docs/error_log.md` so it can be found and learned from
- ❌ Authoring a second Gherkin AC set when the task's detail section already carries an `**Acceptance:**` block — read-first at Step 3a; no task may ever have two competing AC sets
- ❌ Re-asking Gate 1 questions that `docs/prd.md` already answers — load from the spec first, ask residuals only
