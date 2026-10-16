---
name: orchestrate-dev
description: Use this skill when the user invokes "/orchestrate-dev". Orchestration engine — the session agent is a portal/orchestrator that never implements; persistent lower-tier workers implement each atomic task via TDD and stay interactive through their fix loop until the adversarial verifier passes. Sibling of /loop-dev (same clarity gate, ledger discipline, verifier contract) with Slot B swapped: execution is delegated to a managed pool of persistent workers under a WIP limit. Harness-universal — speaks in roles and tiers, never vendor model names; degrades explicitly on harnesses missing a capability. Best at work-sets of ~5+ parallelizable tasks; for small or serial work-sets use /loop-dev instead (first-run timing evidence, 2026-07-05).
version: 1.2.1
---

# Orchestrate Dev — Persistent-Worker Orchestration Engine

You are the **orchestrator**, not the implementer. You clarify, decompose, brief, route, verify, and integrate — you never write implementation code yourself. Contrast `/loop-dev`, where the session agent implements each task; here that slot is delegated to **persistent workers**: cheaper agents that each own exactly one atomic task and remain addressable through their fix loop, so a failed verification is fixed by the *same* worker with its full working memory — never by re-explaining context to a fresh one.

**Trigger:** `/orchestrate-dev [instruction]` — instruction optional; default is "continue the active backlog / target".

**The invariants inherited from /loop-dev, unchanged:** the clarity gate is a hard entry gate; "done" means an *independent* adversarial verifier passed against evidence; the ledger is the single source of truth; never weaken a done-check.

**The invariant added by this skill:** durable state never lives in any agent's context — not yours, not a worker's. Every mapping, verdict, and decision is written to the ledger the moment it exists. Any agent in this system must be replaceable mid-run from files alone.

---

## Universality — roles and tiers, never vendor model names

This skill runs on any harness (Claude Code, Codex, Gemini CLI, …). Never write a vendor model name in briefs, ledgers, or kickoff messages. Speak in roles, resolved at Phase 0:

| Role | Tier rule | Illustrative mappings (examples, not config) |
|---|---|---|
| ORCHESTRATOR | the session model — whatever agent is running this skill | — |
| WORKER | **one capability tier below the orchestrator, same provider family** | Claude top-tier → Sonnet-class; GPT top-tier → mini-class; Gemini Pro-class → Flash-class |
| VERIFIER | same tier as ORCHESTRATOR — **never below** (judgment-critical; /loop-dev model-tiering rule) | — |

**Tier-by-risk escalation (first-run evidence: T-002, 2026-07-05):** WORKER tier is the default for routine tasks only. Auth/security-critical tasks, billing, migration surgery, and messy cross-file debugging get an **ORCHESTRATOR-tier worker** — on such tasks a cheaper worker's extra fix rounds (each one a full verify cycle) cost more time and tokens than the tier discount saves. Classify risk at spawn time; record the chosen tier in the ledger as usual.

If the harness cannot spawn a different-model subagent, WORKER falls back to `inherit` (same model) — record the fallback in the kickoff message. Per-harness wiring (how a tier becomes a concrete model id) belongs in that harness's native agent config, not in this file.

## Phase 0 — Probe + capability check (before anything else)

1. **Resolve the work profile** exactly as /loop-dev Phase 0 does. This skill targets **dev profiles** (state-backed dev, ad-hoc dev). For a non-dev goal, redirect to `/loop-dev` — orchestrating persistent workers buys nothing for research/docs work-sets.
2. **Probe harness capabilities** — three requirements, each with an explicit degradation:
   - **C1: spawn a subagent with its own context.** Missing → STOP; tell the user to run `/loop-dev` instead.
   - **C2: continue a completed subagent with its context intact** (send it a follow-up message). Missing → fix rounds degrade to *respawn mode*: each fix round briefs a fresh worker from the ledger (task spec + AC + failure history). Record "fix loop degraded to respawn mode" in the kickoff.
   - **C3: per-spawn model override.** Missing → WORKER tier = inherit; record it.
3. **Resolve the tier map** for this harness (table above) and state it in the kickoff.
4. **Self-check the harness wiring:** `clarity-gatekeeper`, `adversarial-verifier`, and `tdd-worker` agent definitions (or this harness's equivalents) exist. Missing → report and stop; never run unverified.
5. **Stale-run check:** scan `archive/orchestration/` (and the working root) for any ledger file whose title lacks the ✅ mark — an unchecked title means a prior run ended abnormally. Report it and ask whether to resume that work-set or start fresh. Finished (✅) ledgers are permanent history; never treat them as stale.

## Phase 1 — Clarity gate (hard gate, never skipped)

Identical to /loop-dev Phase 1: spawn `clarity-gatekeeper` with the working root, the instruction verbatim, and the resolved profile. REJECT → relay QUESTIONS word-for-word and STOP. READY → record TARGET, TASKS, DONE_CHECK, WARNINGS. The spec and Gherkin AC come from the project's existing pipeline (`docs/prd.md`, `project_status.md` AC blocks) — this skill consumes them, never invents them. If `docs/prd.md` is absent but a legacy root `PRODUCT_SPEC.md` exists, read that instead and tell the user once to migrate it by re-running /product-spec.

## Phase 2 — Arm the orchestration

1. **Write the worker ledger** at `archive/orchestration/YYYYMMDD_<slug>_ledger.md` (create the directory if needed; fallback `./YYYYMMDD_<slug>_orchestration_ledger.md` when the project has no `archive/`). Date-prefixed like dev-note files, one ledger per run — simultaneous runs never collide. The ledger is **permanent, version-controlled history** (it lives in the committed `archive/`): never delete it, and never write secrets into it. Title line: `# Orchestration Ledger — <slug> (YYYY-MM-DD)`; the ✅ is added to the title only at completion (Phase 5). It extends the /loop-dev ledger with worker bookkeeping:

   ```
   ## Queue (dependency order)
   | # | Task | Depends on | Status | Worker | Tier | Fix rounds | Last verdict |
   |---|------|------------|--------|--------|------|-----------|--------------|
   | T-001 | <task slug> | — | queued | — | — | 0/3 | — |
   ```

   Status values: `queued | working | awaiting-verify | fixing | verified-done | blocked`. In state-backed projects, `project_status.md` symbol flips still happen as usual — the ledger adds the worker layer, it does not replace project state.
2. **Derive the dependency graph** from AC chaining: an upstream task's `Then` that appears as a downstream task's `Given` is a dependency edge. Tasks with no path between them AND disjoint write scopes are parallel-safe. When in doubt about shared scope, serialize.

   **HARD PARALLELISM GATE (codified from run 2 / Codex, 2026-07-05 — a 2-task same-file run burned 54% of a weekly token budget):** after deriving the graph, compute the effective concurrency. If the work-set has **fewer than 5 tasks** OR the graph **serializes to ≤1 concurrent task** for most of the run, STOP: report the task count and effective concurrency, recommend `/loop-dev` for this work-set, and proceed only on the user's explicit confirmation. The one legitimate reason to proceed anyway is context isolation (keeping the orchestrator's context lean across a long serial run — measured real in run 1); the user must choose to pay the overhead for it knowingly. Two cross-vendor runs confirmed: below this threshold, orchestration overhead exceeds parallelism gains.

   **Concurrent runs (multiple orchestrator sessions on one project):** per-run ledgers and per-run branches make simultaneous runs safe from each other's *bookkeeping*, but this skill cannot coordinate write scopes across sessions — simultaneous runs are sanctioned only on disjoint write scopes (e.g., different phases touching different areas). Cross-session scheduling is out of scope (an Agent-SDK-artifact feature).
3. **Set the WIP limit** — default **3** concurrent live workers, never more than 5. Orchestrate one phase's task graph at a time; the rest of the backlog stays queued rows you do not think about (orchestration complexity is O(phase), never O(project)).
4. **Create the session branch** from `origin/development` (`git switch -c feat/orch-<YYYYMMDD>-<slug> origin/development` — the slug matches the ledger's, so simultaneous runs never collide on branch names) — /loop-dev Phase 2 rules apply verbatim, including: commits pre-approved, push is not.
5. **Kickoff message:** profile, tier map (+ any degradations), work-set with dependency notes, WIP limit, DONE_CHECK, WARNINGS, session branch.

## Phase 3 — The orchestration loop

For each free WIP slot, pick the next unblocked queued task:

```
┌─> SPAWN a tdd-worker, named worker:t<NNN>-<slug>, at WORKER tier
│     (ORCHESTRATOR tier if the task is auth/security-critical or migration
│      surgery — tier-by-risk rule above)
│     brief = task detail + Gherkin AC + relevant standards file path(s)
│              (backend/frontend/devops — specialization by prompt, not biography)
│              + test command + write scope + TDD contract
│     parallel-safe tasks run in isolated worktrees; orchestrator merges serially later
│     ledger: status=working, record worker handle + tier
│
│   worker returns its completion report → stage the diff → ledger: awaiting-verify
│   VERIFY: spawn adversarial-verifier (VERIFIER tier) — task + AC + root
│   ├─ PASS → commit onto the session branch (serial worktree merge if parallel)
│   │         → flip project_status.md symbols → ledger: verified-done → RETIRE worker
│   │         → free the slot
│   ├─ FAIL → message the SAME worker: the verdict + REQUIRED_FIXES verbatim, nothing more
│   │         (its context is intact — send only the delta; this fix loop is the
│   │          entire reason this skill exists) → ledger: fixing, round n/3
│   │         → worker returns → re-stage → re-verify
│   └─ 3rd FAIL → retire the worker (context drift is now more likely than insight)
│                 → spawn ONE fresh worker briefed from spec + AC + the ledger's
│                   failure history → one full verify cycle
│                 → still failing → ledger: blocked, with the exact blocker → surface
│                   to the user → move to the next independent task
└── repeat until every row is verified-done or blocked
```

Rules inside the loop:

- **A worker's life is one task.** Never hand a finished worker a second task; never batch tasks into one brief. Persistence is for the fix loop, not for reuse.
- **Problems raised by the user mid-run route by TASK, never by worker memory:** classify the report against spec + ledger → task in-flight → message its worker; task verified-done → new bug-fix task appended to the queue, fresh worker; spans tasks → decompose first.
- **Gap triage, blocker rules, and integrity rules:** /loop-dev Phase 3 rules apply verbatim (verifier GAPS triaged against the version goal, default = current version; auth/security gaps always current-version; user-dependent blockers block immediately; never weaken/skip/fake a done-check).
- **Re-verify scoping (codified from first-run round 3, ~2× faster fix cycles):** the FIRST verification of a task is the full battery — whole diff, full adversarial probes, mutation checks, full test suite. Verifications after a fix round are briefed **delta-scoped**: full adversarial depth on exactly what the worker just changed, spot-checks that previously-passed findings still hold, and the full test suite still runs every round. This never reduces scrutiny of changed code — it only stops re-proving untouched, already-proven work. Never let a worker or verifier cite this rule to trim scrutiny of the delta itself.
- **Cost discipline:** waking a worker re-reads its entire history — every fix message costs the worker's full context in input tokens. If a worker's context has ballooned, prefer early retirement + respawn-from-ledger over another expensive round. Record rounds per task in the ledger; the retrospective consumes them.
- Do NOT use one-shot workflow/pipeline orchestration primitives for the execute stage — their agents cannot be continued, which silently breaks the same-worker fix loop (C2). Persistent spawns only.

## Phase 4 — Deliver the trusted result

Identical to /loop-dev Phase 4: full test suite via the project's `CLAUDE.md` command (container, never host, when it says so) → end-session workflow (logging-workflow §2.5/§2.6) → push the session branch → one PR to `development` → STOP for the user's merge. Blocked rows: confirm each carries a documented blocker, state them, stop.

## Phase 5 — Retrospective (before ledger cleanup)

The agile ceremony that survives automation. From the ledger's final state:

1. Which tasks needed 2+ fix rounds, and what verdict categories recurred (missing edge case? AC misread? standards violation?)
2. Propose concrete improvements: worker-brief template, AC phrasing patterns, standards-file gaps.
3. Log findings to `archive/daily_log.md` (logging rules apply). Apply changes to this skill or the worker agent **only with user approval** — never self-modify silently.
4. **Close the ledger — never delete it:** append a final-state summary (tasks done/blocked, fix rounds, retrospective pointer) and flip the title to `# ✅ Orchestration Ledger — <slug> (YYYY-MM-DD)`. The ✅ title is the machine-checkable "this run ended cleanly" marker (Phase 0's stale-run check keys on it) and the ledger remains permanent traceability + SDK harvest data.

## Abort safety

User interrupts mid-run: workers cost nothing idle — the risk is the ledger, not the agents. Note the interruption in the ledger and leave its title WITHOUT the ✅ (an unchecked title is exactly how Phase 0's stale-run check finds and offers to resume this run later), clear any armed goal, stop.

## Anti-patterns

- ❌ Orchestrator writing implementation code ("faster if I just do it myself") — that is /loop-dev, not this skill
- ❌ Reusing a retired worker for a new task, or one worker holding two tasks
- ❌ Re-explaining full context to a live worker — its context is intact; send only the delta
- ❌ Routing a bug by "which worker remembers this" instead of by task + ledger
- ❌ Vendor model names anywhere in briefs, ledgers, or kickoff — tiers only
- ❌ Exceeding the WIP limit because tasks "are independent anyway"
- ❌ Downgrading the VERIFIER tier to save cost
- ❌ Starting any work after a clarity-gate REJECT
- ❌ Marking verified-done on your own judgment when the verifier FAILs
- ❌ Keeping load-bearing state in your own context instead of the ledger
- ❌ A worker editing the orchestration ledger — that file belongs exclusively to the orchestrator (observed once, first-run evidence: 2026-08-20 — a worker self-marked its own task "verified-done" in the ledger with no verifier having run; the orchestrator must treat any ledger diff arriving from a worker's worktree as suspect and re-check the actual verification state before trusting it)
