---
name: loop-dev
description: >-
  Use this skill when the user invokes "/loop-dev". A general-purpose autonomous loop engine — starts with a hard CLARITY gate, then drives an execute → independently-verify → record loop over a target work-set until every item is verified done, and delivers a result you can fully trust. Works on software projects (its most common use), broader one-off dev work (a bug, a feature, documentation), and non-dev work (research, idea-testing to saturation). Adapts to the environment: runs with or without project state files.
version: 2.0.0
---

# Loop Dev — Autonomous Loop Engine

You are not the implementer of one task; you are the operator of a loop with one promise: **it starts with CLARITY and ends with a result the user can totally trust.** Trust does not come from finishing — it comes from every unit of work passing an *independent* done-check before it counts.

**Trigger:** `/loop-dev [instruction]` — instruction optional; default is "continue the active backlog / target".

This skill is domain-neutral. Three things are **pluggable slots**, resolved by the Phase-0 probe, never hardcoded:

| Slot | What it answers | Software project | One-off dev | Non-dev (research / idea-test / docs) |
|---|---|---|---|---|
| **A. Work source** | what is the work-set? | `project_status.md` target section | a checklist derived from the instruction | claims / experiments / sections, derived from the instruction |
| **B. Executor** | how is one unit done? | `/vibe-code` playbook | lightweight implement + that unit's checks | do the work directly per the instruction |
| **C. Done-check** | how do we *trust* it's done? | `adversarial-verifier` (diff + tests) | `adversarial-verifier` | `adversarial-verifier-general` (artifact + criteria + evidence) |

**The one invariant that never bends:** whatever Slot C is, "done" must be **independently checkable** — verified by a separate adversarial pass, against evidence, not by the implementer's say-so. If a task's "done" cannot be checked that way, the clarity gate must REJECT it (Phase 1). That invariant is the entire source of the trust promise.

The loop is enforced by the built-in **`/goal`** (a completion condition re-checked every turn), backed by a neutral **ledger** the gate and verifier write to. The skill's own instructions drive the loop body, so it still works if `/goal` is unavailable (e.g. a non-Claude-Code agent) — see Phase 2.

---

## Phase 0 — Environment probe + self-check (before anything else)

1. **Probe the environment** and resolve the loop profile (the three slots above). Detect, in order:
   - `current_state/project_status.md` with a 🔲/🔄 target section → **state-backed dev** (A=project_status, B=/vibe-code, C=adversarial-verifier).
   - A software project without that file (`pyproject.toml`/`package.json`/a git repo with code) and a bounded instruction (one bug, one feature, "document X") → **ad-hoc dev** (A=derived checklist, B=lightweight implement, C=adversarial-verifier).
   - Neither (no project state, non-code goal) → **non-dev** (A=derived work-set, B=direct execution, C=adversarial-verifier-general).
   Record the resolved profile; you will state it in the kickoff message.
2. **Self-check the harness** for the resolved profile:
   - `~/.claude/agents/clarity-gatekeeper.md` exists (always required).
   - The Slot-C verifier agent for this profile exists (`adversarial-verifier.md` and/or `adversarial-verifier-general.md`).
   - If a required agent is missing, report it and ask the user to fix wiring before proceeding — never run an unverified loop silently.
3. **Stale-ledger check:** if a `<ledger>` from a prior run already exists (see Phase 2 for its path) with unfinished items, a previous loop ended abnormally — report it and ask whether to resume that work-set or start fresh.

## Phase 1 — Clarity gate (hard gate, never skipped)

Spawn the `clarity-gatekeeper` subagent with: the project/working root, the user's instruction verbatim, and the resolved profile.

- **REJECT** → relay its QUESTIONS to the user word-for-word, add nothing, and STOP. Do not arm the loop. A vague goal — or a goal whose "done" is not independently checkable — burns tokens and produces nothing trustworthy. No exceptions.
- **READY** → record TARGET (the work-source pointer), TASKS (ordered work-set), DONE_CHECK (how each item is verified + which Slot-C verifier), and WARNINGS. Relay WARNINGS in the kickoff message (do not pause for them).

**If `delegate_task` fails** (provider config, missing API key, agent not found): self-drive the clarity gate. Read the target document/source yourself, extract verifiable claims, define done-criteria, and produce the same READY output (TARGET, TASKS, DONE_CHECK, WARNINGS). Do NOT skip the clarity gate — the gate is mandatory, only the transport changes. The same applies to Phase 3 verification: if you can't spawn an adversarial-verifier subagent, verify each item yourself against live evidence and mark PASS/FAIL with evidence refs.

In a state-backed dev project, also relay any 🔲 lines in `archive/ci_inbox.md` with the warnings (owner-triage items from past CI watches; never auto-promoted).

## Phase 2 — Arm the loop

1. **Write the neutral ledger.** One markdown file listing every work-set item and its state. Path by profile:
   - state-backed dev → the `project_status.md` target section already *is* the ledger (its 🔲/🔄 checklist); no separate file needed.
   - otherwise → `current_state/.loop_ledger.md` if `current_state/` exists, else `./.loop_ledger.md` in the working root.
   Ledger line format: `- [ ] <item>` (todo), `- [~] <item>` (in progress), `- [x] <item> — verified PASS <evidence ref>`, `- [!] <item> — BLOCKED: <reason>`. The ledger is the single source of truth for what remains.
2. **Arm `/goal`** with the completion condition, verbatim-precise so its evaluator can check it each turn:
   > "Every item in `<ledger path / target section>` is marked verified-PASS (`[x]`) or documented-blocked (`[!]`)."
   `/goal`'s evaluator re-checks this against the ledger after every turn and keeps the loop running until it holds. **`/goal` unavailable?** Skip this step and self-drive: at the end of every turn, re-read the ledger and continue to the next unfinished item yourself; only stop when the condition above is true. The condition is identical either way — `/goal` is enforcement assist, not the contract.
3. **For dev profiles: create the session branch.** Branch from `origin/development`:
   ```
   git switch -c feat/loop-<YYYYMMDD> origin/development
   ```
   All commits this session go on this branch. Never commit directly to `development` — not code, not docs, not one-liners.
4. Post the kickoff message: resolved profile, TARGET, ordered work-set, DONE_CHECK, WARNINGS, and the session branch name. Git commits are pre-approved for dev profiles (vibe-code rule); push to remote is NOT (until Phase 4).

## Phase 3 — The loop (per atomic item, in dependency order)

```
┌─> pick next unfinished item from the ledger
│   mark it [~]
│   EXECUTE via Slot B:
│     /vibe-code playbook (dev)  |  lightweight implement (ad-hoc dev)  |  do the work (non-dev)
│   stage the work so the verifier can see it
│     dev: git add (untracked files are invisible to git diff without staging)
│     non-dev: ensure the produced artifact + its done-criteria are written to a file the verifier can read
│   VERIFY via Slot C: spawn the resolved verifier (item + its done-criteria/AC + root)
│   ├─ PASS → record [x] with evidence ref → (dev: commit all changes including docs updates
│   │         onto the session branch → continue to next task — no PR yet)
│   │         → update the work source (project_status.md symbol flip / ledger line)
│   ├─ FAIL → apply REQUIRED_FIXES → re-run the unit's checks → re-spawn the verifier
│   │         (max 3 rounds; each round's verdict recorded)
│   └─ 3rd FAIL or external blocker → mark [!] with the blocker, leave it unmerged,
│                 move to the next INDEPENDENT item
└── repeat until no unfinished item remains in the ledger
```

Rules inside the loop:
- One atomic item per iteration — never batch.
- The verifier's GAPS (even on PASS) require **gap triage** before moving on. For each gap:
  1. Read the current version goal (V1 goal statement in `project_status.md`, or the original instruction).
  2. Ask: "Would this version be incomplete or incorrect without fixing this gap?"
     → YES  → add to the **current version** backlog (state-backed: V1 Task Details in `project_status.md`; ledger-backed: append to the ledger)
     → NO   → Post-V1 or V2 — you **must** state the reason it is out of scope in the gap note
     → UNCLEAR → surface to user immediately; do not place it silently
  3. **Default = current version.** Post-V1/V2 requires an explicit written reason. No reason = V1.
  4. Auth and security coverage gaps (missing 401/403/auth tests for a new endpoint, unguarded edge cases on an existing auth flow) are **always current-version** — an untested auth boundary is never optional.
- A blocker that needs the user (credentials, a sign-off, an external service) is a blocker *immediately* — never retry what cannot succeed unattended.
- Never weaken, skip, or fake a done-check to get a PASS. The verifier treats this as an integrity violation, and so must you — it is the one thing that voids the trust promise.
- **Tightly-coupled items.** When two or more task checklist items share the SAME file(s) and the SAME handler/state machinery (e.g. a progress bar + its completion callback + its failure callback), they are de facto one implementation unit. Implement them together in one iteration, commit together, then flip all their symbols at once. The "one atomic item" rule means one *independent* item — coupled items are not independent. If a later item legitimately extends earlier work in a different file or subsystem, it's separate; if it's adding a branch to the handler you just wrote, it's the same iteration.
- **Hook ordering (React).** When adding a new hook (especially one using `useEffect` + `setInterval`) that references `useCallback`-defined functions, ensure the hook call and its callback definition come AFTER all referenced `useCallback` declarations in the component body. JavaScript's temporal dead zone on `const` will throw "Cannot access X before initialization" for any reference before declaration — this silently breaks every test that renders the component, not just the ones exercising the new hook.
- **Test execution: container, never host.** For dev profiles, run tests via the project's containerized command (e.g. `docker compose exec <service> pnpm vitest run`), not via host-level tooling. Host-level runs often fail on platform-specific module mismatches (e.g. a `rollup-darwin-arm64` module missing in a Linux-built `node_modules`). If the project's `CLAUDE.md` or docker-compose files define a containerized dev setup, use it — never default to bare `pnpm test` on the host. This applies to per-item verification in Phase 3, not just the Phase 4 final suite run.
- **Post-merge CI failure: verify it's unrelated before debugging.** If CI fails on a test in a file the loop didn't touch (e.g. all commits only modified `knowledge-base.tsx` but the failure is in `conversations.test.tsx`), the failure is pre-existing. Run the failing test in isolation to confirm it's flaky. Do NOT start a new debug loop — surface the flaky test to the user with a proposed fix. If they approve, fix it in a SEPARATE branch (`fix/<description>`), not the loop's session branch (which is already merged). This keeps the loop's commit history clean and respects the single-responsibility PR pattern.

## Phase 3-P — Parallel mode (Workflow orchestration)

When the work-set has **3 or more independent items** (disjoint write scopes; for dev, no shared files and no shared migration chain), orchestrate them with the **Workflow tool** instead of running sequentially. Shape: `pipeline(items, execute, verify)` — one chain per item, no barrier; execute stage runs one agent per item (dev: `isolation: 'worktree'`, vibe-code playbook); verify stage runs the resolved Slot-C verifier per item, same FAIL→fix→re-verify contract (max 3 rounds). The workflow does NOT merge. After it returns, the main loop integrates **serially** — for each PASS item, merge its worktree branch into the session branch (`git merge <branch> --no-ff`) one at a time, so a bad result is caught before the next lands. Do NOT merge into `development` directly. FAIL/blocked items follow the Phase-3 blocker procedure. Fewer than 3 independent items, or any shared-scope doubt → stay sequential.

## Phase 4 — Deliver the trusted result

When every ledger item is `[x]` or `[!]`:

1. Run the work-set's overall done-check (dev: full test suite via the project's `CLAUDE.md` command — container, never host, when it says so; non-dev: confirm the saturation/coverage criterion the gate recorded).
2. **All clear:** for dev profiles, run the end-session workflow (logging-workflow §2.5: daily_log → current_state sync → §2.6 archival). Then push the session branch and open one PR:
   ```
   git push -u origin feat/loop-<YYYYMMDD>
   gh pr create --base development --title "<one-line summary of the work-set>" \
     --body "<bullet list of tasks completed, gaps added, test count>"
   ```
   Tell the user: "All tasks complete. One PR is ready for your review: `<PR title>`. Please merge when ready." Then STOP — do not merge locally. After the user confirms the PR is merged: `git pull` to sync local development, delete the local session branch. Remove the ledger file (`.loop_ledger.md`) if one was created. `/goal` clears itself once its condition holds.
3. **Blocked items remain:** confirm each carries a documented blocker, then stop — clearing `/goal` is sanctioned here (state the remaining blockers).
4. **Final report:** items completed (with verifier round counts), items blocked (with the exact blocker), gaps added to the backlog/ledger, and the overall done-check result.

## Phase 5 — CI watch (state-backed dev only, optional)

Only after an approved push to remote. Run `/check-ci` once; if runs are in progress, `/loop 4m /check-ci` until the pipeline resolves (check-ci persists failures to `archive/ci_inbox.md`). Surface inbox items at the next kickoff; never auto-promote them.

## Model tiering (measure first, then tune)

Verifier agents default to `model: inherit` and are judgment-critical — never downgrade below the session model. Record each verifier round's approximate token cost in the work note. Only when data shows mechanical fix-rounds dominate cost, set a cheaper tier on fix-round *executor* agents (brain-and-limbs split) — never on the verifier. Do not pre-optimize without the data.

## Abort safety

If the user interrupts mid-run: remove the `.loop_ledger.md` (if created) or note the interruption, clear `/goal`, and stop. A loop's state must never silently outlive the session that started it.

## Anti-patterns

- ❌ Starting any work after a clarity-gate REJECT ("I'll just do the clear parts")
- ❌ Merging / marking `[x]` on your own judgment when the verifier FAILs ("it's being pedantic")
- ❌ Treating "I did the work" as done — done is what the *independent* verifier confirms
- ❌ Accepting a goal whose "done" isn't independently checkable (that breaks the whole trust promise — REJECT at Phase 1)
- ❌ Weakening, skipping, or faking a done-check to get a PASS
- ❌ Hardcoding a software assumption (project_status.md, pytest, git diff) when the resolved profile is non-dev

## References

- `references/testing-localstorage.md` — localStorage test isolation with `vi.stubGlobal` vs `vi.spyOn`
- `references/hermes-credential-masking.md` — when Hermes masks credential-like strings in file output during verification, use `od -c` to see raw bytes
- `references/archive-verification.md` — /loop-dev pattern for verifying a markdown archive/execution log against live server state
