---
name: loop-dev
description: Use this skill when the user invokes "/loop-dev". The Loop Engineering driver — runs the clarity gate, then drives the full autonomous development loop (implement → adversarial verify → merge → status update) over a target phase until no incomplete task remains, enforced by the loop-stop-gate Stop hook. Built on top of /vibe-code, which it uses as the per-task implementation playbook.
version: 1.1.0
---

# Loop Dev — Loop Engineering Driver

You are not the implementer of one task; you are the operator of a loop. The loop's contract: **the session does not end while the target section still contains 🔲/🔄 tasks** (enforced by the Stop hook), and **no diff merges without an independent adversarial verdict**.

Invoking `/loop-dev` activates `/vibe-code` autonomous mode for the whole session — read that skill and apply its playbook per task. Git commits are pre-approved (vibe-code rule); push to remote is NOT.

**Trigger:** `/loop-dev [instruction]` — instruction optional; default is "continue the active version/phase backlog".

---

## Phase 0 — Self-check (before anything else)

1. Verify the harness is wired; if any check fails, report it and ask the user to fix wiring before proceeding (do NOT run an unenforced loop silently):
   - `~/.claude/agents/adversarial-verifier.md` and `~/.claude/agents/clarity-gatekeeper.md` exist
   - The Stop hook script exists and is executable: `test -x ~/.claude/hooks/loop-stop-gate.sh`
2. Confirm no `current_state/.loop_active` already exists. If it does, a previous loop ended abnormally — read it, report the stale target to the user, and ask whether to resume that target or delete the flag.

## Phase 1 — Clarity gate (hard gate, never skipped)

Spawn the `clarity-gatekeeper` subagent with: the project root, and the user's instruction verbatim.

- **REJECT** → relay its QUESTIONS to the user word-for-word, add nothing, and STOP. Do not write the flag. Do not start any work. No exceptions — a vague task in a loop burns tokens and produces nothing.
- **READY** → record TARGET (exact section heading), TASKS, and WARNINGS. Relay WARNINGS to the user in the kickoff message (do not pause for them).

Also at kickoff: if `archive/ci_inbox.md` exists and contains 🔲 lines, relay them with the warnings — they are owner-triage items from past CI-watch automations, never auto-promoted to `project_status.md`.

## Phase 2 — Arm the loop

1. Write the flag — **line 1 must be the exact TARGET heading text** from the gatekeeper (the Stop hook string-matches it):
   ```bash
   printf '%s\n' '<TARGET heading>' > current_state/.loop_active
   ```
   The hook maintains line 2 itself: a global block counter. After 30 blocked stop attempts the gate disarms (allows stops, loud warning, flag kept) so a stuck loop can never trap a session — never write line 2 yourself.
2. Run vibe-code Session Planning (project mode detection, session plan, TaskCreate registration, post the plan). Skip vibe-code's `claude -p` CLI pre-flight — verification here uses the adversarial-verifier subagent, not the CLI.

## Phase 3 — The loop (per atomic task, in dependency order)

```
┌─> pick next 🔲 task from TARGET section
│   implement per /vibe-code playbook (branch → dev notes FIRST → Steps 0–7)
│   stage all task files (git add — untracked files are invisible to git diff without staging)
│   spawn adversarial-verifier (task detail section + AC block + project root)
│   ├─ PASS → commit → merge to development → delete branch
│   │         → update project_status.md (symbol flip; §2.6 archival rules apply —
│   │           respect phase-end AC archival; checklist task gets ✅)
│   ├─ FAIL → apply REQUIRED_FIXES → re-run verification gates → re-spawn verifier
│   │         (max 3 rounds; each round's verdict goes in the dev note)
│   └─ 3rd FAIL → blocked: write the blocker into the task's detail section
│                 (keep symbol 🔄 + "**Blocked:**" line), log to daily_log.md,
│                 leave the branch unmerged, move to next INDEPENDENT task
└── repeat until no 🔲 task in TARGET remains unattempted
```

Rules inside the loop:
- One atomic task per iteration — never batch.
- The verifier's GAPS (even on PASS) become 🔲 backlog entries in project_status.md before moving on.
- `AC_MISSING: true` on PASS → note it in the dev note; the AC gap is a WARNING already relayed at kickoff.
- Tasks blocked on user input (credentials, external services) are blockers immediately — do not retry what cannot succeed.

## Phase 3-P — Parallel mode (Workflow orchestration)

When the session plan identifies **3 or more independent atomic tasks** — independent per the vibe-code worktree safety rules (disjoint write scopes, no shared files, no shared Alembic migration chain) — orchestrate them with the **Workflow tool** instead of running them sequentially. This section is the explicit instruction that authorizes the Workflow call; fewer than 3 independent tasks, or any shared-scope doubt → stay sequential (Phase 3).

Shape of the workflow script:

- `pipeline(tasks, implement, verify)` — one chain per task, no barrier between tasks: task A can be in verification while task B is still implementing
- **Implement stage:** one agent per task with `isolation: 'worktree'`, instructed to follow the vibe-code playbook (Steps 0–7) inside its worktree. Dev notes still go to the MAIN checkout path (vibe-code rule — worktrees are deleted at cleanup)
- **Verify stage:** one `adversarial-verifier` agent per task (`agentType: 'adversarial-verifier'`), same FAIL → fix → re-verify contract, max 3 rounds inside the stage
- The workflow returns per-task results; it does NOT merge

After the workflow completes, the main loop merges **serially**: for each PASS task — merge its branch into `development`, run the full suite, update `project_status.md` — one at a time, so a bad merge is caught before the next lands. FAIL/blocked tasks follow the same blocker procedure as Phase 3.

## Phase 4 — Goal evaluation and shutdown

When every task in TARGET is ✅ or documented-blocked:

1. Run the full test suite using the project CLAUDE.md command (container, never host, when the project says so).
2. **If all clear (no 🔲/🔄 remain):** run the end-session workflow (logging-workflow §2.5: daily_log → current_state sync → §2.6 archival check). The Stop hook removes the flag itself once the section is clean — do not race it; verify with `test ! -f current_state/.loop_active` after your final status update, and delete it manually only if it lingers.
3. **If blocked tasks remain:** the Stop hook will keep blocking (🔄 still present). This is the one sanctioned manual exit: confirm every remaining task carries a `**Blocked:**` line in its detail section, then `rm current_state/.loop_active` and stop.
4. Final report to the user: tasks completed (with verifier round counts), tasks blocked (with the exact blocker), gaps added to backlog, test suite result.

## Phase 5 — CI watch automation (post-push, optional)

Push to remote still requires the user's explicit confirmation — this phase only arms AFTER an approved push.

1. Run `/check-ci` once immediately (it scopes to the current repo automatically).
2. If runs are in progress, start the watch: `/loop 4m /check-ci` — the loop re-checks until the pipeline resolves. Failures are persisted by check-ci to `archive/ci_inbox.md` (its automation mode), so findings survive the loop's ephemeral iterations.
3. Stop the watch when the pipeline is green or every failure is logged in the inbox. Inbox items are owner-triage material — surfaced at the next loop-dev kickoff (Phase 1), never auto-promoted into `project_status.md`.

## Model tiering (measure first, then tune)

- Both subagents default to `model: inherit`. The verifier is judgment-critical — never downgrade it below the session model.
- **Measure now:** record each verifier round's approximate token cost in the task's dev note (round count × verdict is already required; add cost when visible).
- **Tune later:** when the data shows mechanical fix rounds dominate cost, set a cheaper tier (e.g. Haiku-class) on fix-round implement agents via the subagent `model:` frontmatter or the Workflow `model` option — the brain-and-limbs split. Do not pre-optimize without the data.

## Abort safety

If the user interrupts or aborts the loop mid-run: delete `current_state/.loop_active` before stopping, and note the interruption in daily_log.md. The flag must never outlive the session that wrote it.

## Anti-patterns

- ❌ Starting any work after a gatekeeper REJECT ("I'll just do the clear parts")
- ❌ Merging on your own judgment when the verifier FAILs ("the verifier is being pedantic")
- ❌ Editing project_status.md symbols without the verifier PASS that justifies them
- ❌ Deleting `.loop_active` to make the Stop hook go away while unblocked 🔲 tasks remain
- ❌ Weakening, skipping, or deleting tests to get a PASS — the verifier treats this as an integrity violation, and so must you
