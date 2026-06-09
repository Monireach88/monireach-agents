# Spec-First Pipeline + Validation Layer — Design

**Origin:** 2026-06-06 discussion after the smart_chatbot self-registration incident (full trail: smart_chatbot `archive/daily_log.md` 2026-06-06).
**Status:** WHAT-layer complete and approved by Monireach. **Build progress (2026-06-08):** Stage 1 BUILT — `/product-spec` (author mode), `/design-audit` (Pass 1 + Pass 6 + journey-trace), `/ideation`+`/tc` split, AC format change + `/vibe-code` reconciliation; each gated by an independent Opus compliance review to PASS. **Archaeologist mode BUILT (early, on the Pass-1+Pass-6 base — design-sanctioned independent trigger):** `/product-spec --mode=archaeologist` (supporting file `archaeologist_mode.md`) + `/design-audit --mode=archaeologist` (FINDINGS.md register). **Passes 2–5 BUILT (2026-06-09, owner override of the Stage-2 mechanical trigger — same sanctioned-early pattern as archaeologist mode):** `/design-audit` now carries Pass 2 (authz/BOLA), Pass 3 (state-machine), Pass 4 (journey-failure), Pass 5 (seam) as conditional sweeps with applicability gates, degraded-sequential path; passed an independent Opus reviewer loop (5 gate/source/wording defects fixed → PASS). Still NOT built: refuter Workflow path, design-auditor agent+memory + re-flag suppression, hooks, CI mirror, consumer mode, non-web deep specialization, plugin packaging. Build remaining on command only.
**Review:** Adversarially reviewed 2026-06-07 (independent Opus agent): 14 findings applied. Panel-reviewed by 7 SDLC-role agents (PO, Architect, Backend, QA, DevOps, TechWriter, EM): 39 findings → consensus edits applied; owner decisions: lite-lane YES, Stage-2 kill-rule YES, success-metric number-now/check-later. **FORMAL SIGN-OFF 2026-06-07: 7/7 APPROVE — all 32 role conditions verified MET. The document is consensus-final; further changes require a reason logged here, not silent edits.**
**Precedence rule (build-time):** §12.5 pins and inline review-finding notes OVERRIDE body prose on any conflict. Body = context; pins = binding.

---

## Table of Contents

1. [Root Diagnosis](#1-root-diagnosis)
2. [Target Pipeline](#2-target-pipeline)
3. [PRODUCT_SPEC.md Artifact Format](#3-product_specmd-artifact-format)
4. [Skill Spec: /product-spec](#4-skill-spec-product-spec)
5. [Skill Spec: /design-audit](#5-skill-spec-design-audit)
6. [Hooks (Layer 3)](#6-hooks-layer-3)
7. [Subagent: design-auditor](#7-subagent-design-auditor)
8. [/vibe-code Upgrade](#8-vibe-code-upgrade)
9. [Gherkin Acceptance Criteria in Task Details](#9-gherkin-acceptance-criteria-in-task-details)
10. [SDLC 8-Slot Coverage Checklist + 3 Modes](#10-sdlc-8-slot-coverage-checklist--3-modes)
11. [Core Principles (carry into every skill)](#11-core-principles-carry-into-every-skill)
11.4. [Skill Self-Containment Rule (MANDATORY)](#114-skill-self-containment-rule-mandatory--monireach-2026-06-07)
11.5. [Generalization Requirements (MANDATORY at skill-build time)](#115-generalization-requirements-mandatory-at-skill-build-time)
12. [Recommended Build Order](#12-recommended-build-order)
12.5. [Pinned Clarifications (binding at build time)](#125-pinned-clarifications-monireach-review-2026-06-07--binding-at-build-time)
13. [Related Context Elsewhere](#13-related-context-elsewhere)

---

## 1. Root Diagnosis

The smart_chatbot auth flaw (no tenant-creation path anywhere; intent was self-registration) was structurally guaranteed by the pipeline shape, not by carelessness. The pipeline `idea → /technical-consultant → /start-local-dev → /vibe-code` answers HOW (stack), WHERE (scaffold), and IS-IT-CORRECT-AGAINST-THE-TASK (TDD) — but no step ever answers WHAT the product does, for which actors, through which journeys. The missing discipline: **requirements engineering / domain modeling — specifically actor/entity lifecycle specification.**

Key secondary insight: AI agents are readers. Docs are the interface between Monireach and his agents — "solo developer" no longer means no documentation contracts needed. The incident was a multi-party documentation failure between him and the frontend agent.

## 2. Target Pipeline

```
idea → [OWNER generates spec skeleton]          ← generation-first, never AI-first in learning mode
     → /product-spec                            ← AI: independent generation + diff + prose; calls /design-audit at birth
     → /technical-consultant → /start-local-dev
     → PHASE 1 = ALWAYS THE WALKING SKELETON     ← thinnest end-to-end slice of the money journey, deployed;
                                                    journeys built vertically, never layer-by-layer (panel: Arch-5)
     → per phase: [journey-trace gate (hook)] → /vibe-code → [/design-audit on diff]
     → per milestone: [/design-audit drift check]
```

**Lite lane (owner-approved 2026-06-07; panel EM-1):** for explicitly low-stakes projects (throwaway scripts, experiments), the owner may declare `lite` at kickoff: spec = 1-page actors+journeys sketch, no dual-generation, no birth audit. The declaration is recorded in the spec header — an explicit choice, never a silent default. Portfolio/production projects always use the full lane (no-shortcuts hard rule applies to them, not to declared-throwaway work).

## 3. PRODUCT_SPEC.md Artifact Format

2–3 pages max (anti-perfectionism bound). Sections in fixed generation order:

0. **Why (BRD payload):** 2–4 sentences — problem, who pays, business goal — **plus one SUCCESS METRIC line** (measurable, e.g. "10 tenant signups/month"; panel PO-1, owner decision: metric written now, the recurring per-milestone goal-check joins Stage 2).
1. **Actors:** every human/system touching the product. Forced sub-checks: who pays? who operates? who consumes? what external systems call in/out?
2. **Entities — CONCEPTUAL, not physical (panel Arch-1):** every noun whose state must outlive a session. These are domain concepts, NOT table commitments — the entity→table mapping is a post-stack decision (NoSQL/event-sourced stacks map differently).
3. **CRUD matrix:** per entity × {Create, Read, Update, Delete}: WHO, through WHAT path, triggered WHEN. **A blank cell is an unmade design decision** — either fill it or move it to non-goals consciously.
4. **Journeys (3–7):** per primary actor, **starting from a stranger** (never assume the entity into existence). Every arrow must land on a filled matrix cell. The money journey is mandatory **and each journey carries a priority rank (money journey = P0) — phase ordering follows journey priority (panel PO-2).**
5. **NFR checklist — fixed slots, not a free line (panel Arch-4):** scale, latency, availability, compliance/data-residency, language(s) — each tagged `in-scope: <value>` or `skipped: <reason>` (blank-cell discipline applied to NFRs).
6. **Non-goals:** for every deliberately blank cell / skipped feature: "NOT in V1 because X — revisit when Y." Never bare "NO". **Re-read at every phase planning: confirm each "revisit-when-Y" is still un-triggered (panel PO-3).**
7. **SDLC coverage footer:** the 8-slot checklist (see §10) — each slot: file | derivable | consciously skipped.

**Canonical-source rule (panel TW-4):** PRODUCT_SPEC.md is canonical for WHAT (actors/entities/journeys); README and PROJECT.md may reference it but never restate those — restated copies drift.

**Literal template (panel TW-1 — skills instantiate THIS, never invent structure):**
```markdown
# PRODUCT_SPEC — <project>
> Generation: <owner-first | AI-first (reason, date)> | Lane: <full | lite>
## 0. Why
<problem; who pays; goal>  Success metric: <measurable target>
## 1. Actors
| Actor | Role | Pays? |
## 2. Entities (conceptual)
| Entity | One-line meaning |
## 3. CRUD Matrix
| Entity | Op | Who | Through what | When |
## 4. Journeys
| P | Journey (stranger → value) | Arrows (each lands on a matrix cell) |
## 5. NFR
| Slot | scale / latency / availability / compliance / language | in-scope: <val> or skipped: <reason> |
## 6. Non-goals
| Skipped | Because | Revisit when |
## 7. Coverage footer
| SDLC slot 1–8 | file / derivable / consciously skipped |
```

**Known limitation (promoted from §5 per review finding 5 — state this in the skill too):** the matrix guarantees coverage only of ENUMERATED entities — a missing entity has no row, no cells, no arrows (the incident's exact class: tenant creation was missing because nobody enumerated the transition). The primary catch mechanism for missing entities/actors is **journeys-from-stranger** (walking from outside forces invisible things into view) + dual independent generation + Pass 6 — the matrix is the completeness check for what's enumerated, not the discovery mechanism for what isn't.

**Spec evolution rule (post-V1; review finding 8):** PRODUCT_SPEC.md is a living document with spec-first change discipline — any scope/behavior change updates the spec BEFORE the code changes (expand/contract applied to specs). Owner updates it at phase planning when new tasks change actors/entities/journeys. Under this discipline, drift (code ≠ spec) is always a regression signal, never a false positive from legitimate evolution. **Soft enforcement (panel PO-4):** when a commit touches models/migrations with no PRODUCT_SPEC.md edit in the same phase, the gate WARNS (never blocks) — the warning is the tripwire for forgotten spec-first updates. **Amnesty (panel EM-3):** after any process lapse, `--resync` re-baselines markers + records the lapse in the spec header in one step — no historical back-audit demanded. Core principle: the process must always be cheaper to RE-ENTER than to abandon.

## 4. Skill Spec: /product-spec

**Position:** before /technical-consultant. The Project Brief from /technical-consultant ideation phase may feed it, but spec precedes Tech Stack Decision Record.

**Procedure:**
1. **Enforcement gate:** refuses to generate until the owner's skeleton exists (same first-tool-call enforcement pattern as vibe-code dev-notes rule). Skeleton = `SPEC_SKELETON.md` in the project root — owner-produced actors/entities/CRUD-matrix/journeys in tables-and-arrows form (no prose required; non-native-English friction must stay zero). Gate is mechanical: file exists → proceed; missing → refuse + explain what to create, OR owner passes `--ai-first` — a one-keystroke inline degradation that proceeds AI-first and RECORDS the ownership decision + a one-line reason in the PRODUCT_SPEC.md header ("Spec generation: AI-first, <reason>, <date>"). The reason is mandatory per use — prevents `--ai-first` silently becoming the default (panel Backend-5). **Skeleton-commit-first + learning metric (panel EM-5):** the owner's skeleton is committed BEFORE AI generation runs; the diff's blind-spot count (owner-missed cells) is logged in the spec header per project — the requirements-engineering skill is building only if that number trends down across projects. The skeleton is raw material, not a deliverable — disposable after PRODUCT_SPEC.md is written.
   - **Session timeline (pinned 2026-06-07, after owner confusion — encode in skill docs):** Session 1: `/tc ideation` → PROJECT_BRIEF.md. Session 2: owner writes SPEC_SKELETON.md, runs `/product-spec` → PRODUCT_SPEC.md. Session 3: `/tc tech-stack` → TECH_STACK.md. Sessions are separate by design (/tc was always two separate sessions).
   - **Ownership flexibility (Monireach's explicit correction — never make this absolute):** at project kickoff the owner decides and writes one line: "Spec generation owner: me / AI — because X." Learning-mode projects (portfolio, interview-relevant domains) → owner generates first. Throwaway/low-stakes/repeat-domain projects → AI-first is allowed. The rule is *decide explicitly, never default silently*.
2. **AI independent generation:** same 5-step structure, from requirements discussion (greenfield) or codebase (retroactive), WITHOUT seeing the owner's skeleton.
3. **Mechanical diff:** cell-by-cell (`for entity × op: compare`), journey-by-journey. Owner-missed items = blind-spot learning signal; AI-missed items = verification. Present diff, discuss, merge. Owner fills blank-cell decisions (product decisions are never AI's).
4. **Prose write-up:** AI writes final PRODUCT_SPEC.md (format §3).
5. **Birth validation:** invoke /design-audit (greenfield scope: structural passes only).

**Modes (parameter):**
- `author` — solo projects, full procedure above.
- `consumer` — Monireach contributes code to someone else's project: the skill becomes an **intake checklist** — verify upstream docs (slots 1–3, 7) exist and are coherent before coding; missing slot = risk flag to raise (be the frontend agent).
- `archaeologist` — documentation for completed projects. **Phase 0 — Reconnaissance (MANDATORY, before any derivation; Monireach requirement 2026-06-07):** (1) get-it-running + rough map per `deliverables/software_ai_engineering/engineering_practices/codebase_onboarding.md` Phases 1–2; (2) docs inventory + TRUST AUDIT — every existing doc's concrete claims spot-checked against code, verdict per doc: current/stale/wrong/unverifiable; existing docs are HYPOTHESES, never ground truth (ground truth = code + schema + running behavior); (3) convention survey — patterns actually vs half-followed; inconsistencies become owner-interview questions, never silent guesses; (4) output = reconnaissance section in FINDINGS.md. Only then: derive ERD/API from code mechanically; reverse-generate SRS via the AI-generation step; **BRD payload must be elicited from the owner by interview — intent is never derivable from artifacts.** FINDINGS.md ownership rule: §12.5 item 8 is the single authoritative statement (review finding 10) — author = no file; consumer = register only, no reconnaissance, no task creation; archaeologist = full register incl. reconnaissance.

## 5. Skill Spec: /design-audit

**Standalone skill — the single judgment engine. Five call sites:** (1) /product-spec at birth, (2) manual mid-development, (3) hook delegation target, (4) consumer/archaeologist modes, (5) /vibe-code dimension review.

**Inputs:** PRODUCT_SPEC.md (or its absence → run degraded with loud warning), codebase, scope parameter (full | phase | diff).

**Passes (each = exhaustive loop over an enumeration; never open-ended "find flaws"):**
- **Pass 1 — Lifecycle completeness:** re-derive CRUD matrix from code, diff vs spec (this is also the drift check).
- **Pass 2 — Authz sweep:** for every exposed surface × actor (per §11.5-1 — never read as HTTP-only): can reach? should? (BOLA hunting.)
- **Pass 3 — State-machine sweep:** for every entity status/flag field: all transitions enumerated; who triggers; illegal transitions actually blocked in code?
- **Pass 4 — Journey-failure sweep:** for every journey arrow: mid-failure behavior (half-created records, partial payments, dead syncs).
- **Pass 5 — Seam sweep (broadened per panel Arch-3):** for every subsystem pair sharing an entity OR a message/event contract (queue payload, webhook schema) OR a migration window (expand/contract coexistence): do both sides agree on meaning/lifecycle/schema? Contract seams and temporal seams are first-class, not just entity seams.
- **Pass 6 — Completeness critic:** one agent, open-ended on purpose: "what is absent from these enumerations?" (missing actor/entity/document — the only pass allowed to be unstructured).

**Output discipline:** schema-forced verdict per item: `ok | flaw | undecided` + file:line evidence (`undecided` mandatory in schema — without it models guess). Then **adversarial refuter agents** per flagged flaw (prompted to refute; majority-refuted findings die). Only verified findings surface → become 🔲 tasks in the project's project_status.md (owner approves each — never auto-log).

**Execution (amended per review findings 7, 11):** two paths, both mandatory in the skill. (a) Workflow path when ultracode available: parallel dimension passes, then refuters — a skill instructing the Workflow tool is a supported explicit opt-in (verified 2026-06-06). (b) **Degraded sequential path (default, always works):** passes run one-by-one in-session, single verification pass instead of refuter panel — **the single verifier records `undecided` on uncertainty, never silently drops (panel QA-4)**. The skill must never fail just because ultracode is off. **Refutation audit trail (panel QA-4):** refuter-killed findings are logged to design-auditor MEMORY.md with the refute rationale (alongside owner-rejected ones) — on a later prod incident, matching killed findings are reopened. **Read-only invariant:** auditor agents get read-only tools (Read/Grep/Glob) in BOTH paths — the Workflow acceptEdits caveat applies to general workflows, never to audit agents; findings are reported, not applied. Caveats: Workflow path = higher token cost, no mid-run input.

**MVP staging (owner-approved 2026-06-07; explicit triggers, not deferral — the full design remains the standard):** MVP = Pass 1 (lifecycle/drift + ERD + unused-entity) + Pass 6 (completeness critic) + journey-trace, author mode, web-service shape, degraded path. Staged additions with triggers: ~~Passes 2–5~~ **BUILT 2026-06-09 ahead of trigger (owner override) — gated conditional sweeps, sequential path**; the **refuter Workflow path** (the parallel multi-agent execution upgrade for Passes 2–5) → still triggered: when MVP shows sustained use across 2+ phases; consumer/archaeologist modes → ~~when the first external contribution or documentation engagement lands~~ **archaeologist BUILT 2026-06-08; consumer still triggered**; non-web shapes → first non-web project.

**Epistemic contract (state in skill output, keep owner calibrated):** guarantees no flaw of an *enumerated class* survives; cannot guarantee flaws outside the enumeration (a missing entity has no cells to visit). Mitigations: dual generation, 8-slot checklist, journeys-from-stranger, Pass 6. New flaw classes discovered in production → added as new pass dimensions → system compounds (see §7 memory).

## 6. Hooks (Layer 3)

Currently EMPTY across agent_core — the missing harness layer (knowledge=rules ✓, judgment=skills ✓, timing+enforcement=hooks ✗). Hooks are deterministic shell: they trip and delegate; judgment stays in skills/agents.

- **Journey-trace gate (mechanics overhauled per panel DevOps-1/2/3, QA-6, Backend-3, EM-3):**
  - **Freshness = content hash, never dates/mtimes.** Git does not preserve mtimes (clone/rebase destroy them). The marker `docs/journey_traces/<phase-slug>.md` is WRITTEN BY `/design-audit --scope=phase` on a passing trace and contains: the trace itself (journeys walked, AC chains verified) + a HASH of the phase's AC-block content. Stale = stored hash ≠ current AC hash. Whitespace-only AC edits can be normalized before hashing.
  - **Scoped, not universal:** the `PreToolUse` git-commit hook trips ONLY when the staged diff touches code paths implementing the active phase's journeys (path filter). Docs-only, test-only, config-only, WIP/branch commits pass freely. Gate authority sits at merge-to-`development` (PR level), not every commit.
  - **Logged bypass:** `SKIP_TRACE_GATE=1` allowed, recorded in the spec header — never raw `--no-verify` (invisible). `--resync` (see §3 amnesty) re-baselines after lapses.
  - **No inline regeneration:** the hook only compares hashes — it never runs ERD/OpenAPI regen inline (those are per-phase `/design-audit` duties; panel Backend-3).
  - **CI mirror (panel DevOps-1 — hooks are local-only and bypassable):** Stage 2 adds a CI job running the SAME freshness+drift script on PR/push. Hook = fast local feedback; CI = unbypassable authority. Without this, the gate doesn't exist on any other machine — the gate's own portability problem.
  - Marker is the evidence, not a flag. Hook depends on /design-audit (hooks ship after it; §12 order correct).
  - **Canonical hook home (panel DevOps-5):** plugin `hooks/hooks.json` from the start — never settings.json first with a later migration (double-registration hazard).
- **Post-edit tripwire:** `PostToolUse` on Edit/Write → deterministic checks (lint, targeted greps) → findings injected via `additionalContext` (≤10k chars).
- Registered in settings.json or shipped in plugin `hooks/hooks.json` (root-level plugin hooks are allowed; subagent-frontmatter hooks in plugins are NOT).

## 7. Subagent: design-auditor

`agents/design-auditor.md` — runs /design-audit passes when delegated. Frontmatter: `memory: project` → persistent MEMORY.md per project (first ~200 lines auto-injected) accumulating found flaw patterns + rejected findings (re-flag suppression, §12.5-8), so detection compounds across sessions instead of starting cold. Read-only tools (Read, Grep, Glob) + schema output — read-only holds in Workflow mode too (§5 invariant). **§11.4 compatibility note (review undecided-3 resolved):** agent memory does NOT violate self-containment — §11.4 governs static file references inside SKILL.md/agent files; `memory:` is a runtime path provided by the harness itself, valid on any machine.

## 8. /vibe-code Upgrade

**CRITICAL build-time context (review findings 1–3): /vibe-code ALREADY has overlapping machinery — the upgrade is a RECONCILIATION, not an addition. Read the current SKILL.md fully before editing it.**

- **AC precedence (finding 1 — resolves the Step 3a contradiction):** /vibe-code Step 3a currently authors Gherkin per-task. New rule: Step 3a first READS the `**Acceptance:**` block from project_status.md (phase-planning AC = the source of product intent); only if absent does it author task-local AC as fallback (and notes the gap). Never two competing AC sets for one task.
- **Review wrap (finding 2):** /vibe-code's existing post-task `claude -p` diff review (with auth-error self-review fallback) is PRESERVED as the degraded path. `/design-audit --scope=diff` WRAPS it: when /design-audit is installed, it runs instead (Workflow or sequential per §5); the claude -p chain remains the fallback when /design-audit is absent or errors. Never delete the existing fallback chain.
- **Gate 1 shrink (finding 3):** /vibe-code Gate 1 (Requirement Ownership: actor/DB-state/failure-mode elicitation) currently re-asks questions the spec now answers. New rule: when PRODUCT_SPEC.md exists, Gate 1 first loads answers from the spec and only asks the owner about residual gaps; full elicitation only when no spec exists. The owner never answers the same question twice.
- Task pickup: read Gherkin AC from project_status.md task details (§9) and convert to failing tests before implementation (TDD seed). **TDD seed must include deny-path + boundary tests, not just the happy Then (panel QA-2).**
- **"Mechanical" conversion has limits (panel Backend-2):** state-assertion ACs convert mechanically; async/eventual/infra ACs (job retries, webhook idempotency, migration reversibility) map to NAMED test+fixture patterns (time control, fake brokers, downgrade round-trips) — the skill must say this, or devs hit it on task 1 and quietly downgrade AC to trivial assertions.
- **Test pyramid statement (panel QA-3, goes in the skill):** AC tests verify behavior/journeys at acceptance altitude; unit tests own branch coverage of logic-bearing modules independently. A green AC suite is NOT complete coverage.
- **Edit map for the SKILL.md reconciliation (panel Backend-4):** Step 3a (line ~139) → read-spec-AC-first; Gate 1 (lines ~446–467) → load-from-spec, ask residuals only; Step 7 (line ~145) → wrap with /design-audit, preserve claude -p fallback. Post-edit assertion: no task may ever have two competing AC sets.

## 9. Gherkin Acceptance Criteria in Task Details

Upgrade to documentation-structure.md task-detail format: each task detail section MAY carry `**Acceptance:**` block in Given/When/Then. Highest-ROI single change: encodes product intent in a form no agent can misread, and converts mechanically to pytest tests.

**AC quality checklist (panel QA-1 — INLINED into the skill, §11.4 forbids referencing the gherkin guide file):** declarative style (what, not how); `Then` = an observable, checkable state/output — never "system works"; one behavior per scenario; no UI selectors/URLs in backend AC; `Given` = a persisted/establishable state. **Each behavior AC gets a negative or boundary counter-scenario at phase planning (panel QA-2).** **AC dual-generation (panel PO-5 — solo collapses the Three Amigos):** owner drafts AC from intent, AI drafts independently from the spec, diff — same generation-vs-recognition guard the spec gets; otherwise AC inherits its author's blind spots and "verifies" them.

**Timing + placement rule (Monireach 2026-06-07):** AC is written at PHASE PLANNING — all tasks of the phase together, in project_status.md — NEVER one-at-a-time inside /vibe-code, and NEVER in dev notes. Two reasons: (1) cross-task picture — the journey-trace gate walks **each JOURNEY's ordered path** through whichever tasks implement it (fan-out/fan-in allowed — review finding 4): along a journey, an upstream task's `Then` must produce the downstream task's `Given`; NEVER applied phase-wide across unordered tasks (parallel independent tasks have no chain obligation to each other); catches inter-task contradictions pre-implementation (the incident's flaw class); (2) /vibe-code speed — AC→failing-test is mechanical translation, eliminating behavior-inference rewrites. Division: project_status.md task detail = WHAT (AC, at planning); dev note = HOW it went (during implementation). Reference for writing AC: `deliverables/software_ai_engineering/engineering_practices/gherkin_writing_guide.md` (already exists). Example that would have prevented the incident:
```gherkin
Given a stranger with a Google account not in the system
When they log in via Google
Then a tenant exists with balance_usd=0 and they receive a JWT
```

## 10. SDLC 8-Slot Coverage Checklist + 3 Modes

Validated 2026-06-06 (sources in research trail). No canonical "8 types" exists; this is the working taxonomy. Corrections locked in: SRS ⊇ FRS (not synonyms — FRS = functional only, no NFRs); BRD authored by BA, owner signs off; backlog: PO solely accountable, team contributes; Gherkin AC written by Three Amigos; tests-as-living-documentation strongest for BDD.

| Slot | Doc | Monireach's mapping |
|---|---|---|
| 1 | BRD | PRODUCT_SPEC.md §0 Why (merged — solo: BA/owner/PO same person) |
| 2 | SRS | PRODUCT_SPEC.md §§1–6 |
| 3 | Architecture | TECH_STACK.md (= ADR-0001) + append-only ADR log + PROJECT.md map (naming mode-dependent — §12.5-5) |
| 4 | ERD | Derivable from models (automate, never hand-author) |
| 5 | API contract | FastAPI OpenAPI (free) |
| 6 | UI/UX spec | Per-project optional; frontend standards rules cover defaults |
| 7 | Backlog | project_status.md (+ Gherkin AC per §9) |
| 8 | Code/tests | /vibe-code TDD |

Docs are **role interfaces**; roles collapsing into one person merges files but the payload of every interface must survive (coverage checklist proves it). **Backfill law:** a doc is backfillable only if derivable from code — ERD/API fully, SRS partially (reverse generation), **BRD never** (must be elicited).

**Modes:** author (own all slots, merge map) | consumer (own slot 8; slots 1–3,7 are inputs — intake checklist, demand missing docs) | archaeologist (backfill by derivability law).

**ADR log (panel Arch-2 — author-mode slot 3 was decision-blind over time):** TECH_STACK.md is ADR-0001, a point-in-time record. Subsequent stack/architecture changes (swap a queue, add a cache) append one bounded entry each to `docs/adr/` (≤1 paragraph: decision, why, supersedes-pointer — perfectionism guard). Without this, superseded decisions live only in the owner's head — the incident's pattern, architecture edition.

## 11. Core Principles (carry into every skill)

1. **Structure supplies coverage; owner supplies generation and judgment; AI supplies exhaustive iteration — in that order.**
2. Generation vs recognition: reviewing AI output is recognition (weak — cannot notice absence); producing first is generation (strong). Learning mode = owner generates first; production mode = AI-first allowed by explicit per-project decision.
3. Never open-ended "find flaws" prompts: enumerate, loop, classify, force `undecided`. (Same principle as core-principles.md §3.2.1.)
4. A blank cell is a decision, not an omission, only once it's written down.
5. Bounded artifacts (2–3 pages) — perfectionism guard. Flawlessness is not the promise; "no identified flaw class can hurt twice" is.
6. Never absolute rules where Monireach reserved flexibility (ownership decision is his, per project, explicit).

## 11.4 Skill Self-Containment Rule (MANDATORY — Monireach 2026-06-07)

**SKILL.md files must NEVER reference files outside their own skill directory** — no paths into deliverables/, profile/, agent_core docs, or absolute paths. Reason: skills travel (other PCs, plugin distribution); external references break on arrival. If a skill needs methodology content (e.g., codebase-onboarding phases for /product-spec archaeologist mode), INLINE the needed payload into SKILL.md or ship it as a supporting file INSIDE the skill's own folder (skill-dir contents travel together; `${CLAUDE_PLUGIN_ROOT}` exists for plugin-internal paths). This design doc may reference Monireach's files freely — it is not shipped; only skill files are.

---

## 11.5 Generalization Requirements (MANDATORY at skill-build time)

This doc was derived from a SaaS incident and uses smart_chatbot examples. The examples are illustrations; the procedures are general — BUT three SaaS-shaped assumptions are baked into the vocabulary and MUST be generalized when writing the SKILL.md files (flagged by Monireach 2026-06-07):

1. **"Endpoint" → "exposed surface"**: HTTP endpoint, CLI command, public function/API, message handler, cron entry point. Pass 2 (authz) iterates over exposed surfaces × actors.
2. **CRUD matrix requires persistent entities**: if the project has none (stateless library, pure-transform pipeline), the skill must offer an explicit "not applicable — consciously skipped" path, never force a meaningless artifact.
3. **"Stranger" journeys require external actors**: for single-actor tools, generalize to "from zero state to first value."
4. **"Entity ≈ DB table" assumes relational persistence (panel Arch-1)**: spec entities are domain concepts; the entity→storage mapping (tables, documents, event streams) is decided post-stack. Pass 1's "re-derive CRUD from code" must read whatever persistence model the stack chose, not assume SQL.

**Implementation pattern:** every new skill opens with a project-shape detection step (web service | CLI | library | pipeline | frontend | hybrid) — same pattern as /vibe-code's frontend/backend mode detection — and applies shape-appropriate vocabulary. All smart_chatbot references in skill files must be marked `Example (SaaS shape):` and carry no procedural weight.

---

## 12. Recommended Build Order

**MVP-staged (owner-approved 2026-06-07, review findings 11–12). Stages have explicit triggers — sequencing, not deferral; the full design remains the standard.**

**Stage 1 — MVP (build on command):**
1. `/product-spec` — author mode, web-service shape, `--ai-first` degradation
2. `/design-audit` — Pass 1 (lifecycle/drift/ERD/unused-entity) + Pass 6 (completeness critic) + journey-trace, degraded sequential path, author mode
3. `/technical-consultant` SPLIT into `/ideation` + `/tc` per §12.5 item 1
4. Gherkin AC format change (documentation-structure.md §10.3 + logging-workflow.md §2.6 verbatim-AC rule) + /vibe-code reconciliation per §8 (READ CURRENT SKILL FIRST — findings 1–3)

**Stage 2 — trigger (mechanical, panel EM-2): `/design-audit` has run on ≥2 completed phases AND produced ≥1 verified finding the owner acted on. Owner records the fire/kill decision + date in this doc. KILL RULE (owner-approved 2026-06-07): if 2 phases produce zero actionable findings, Stage 2 is CANCELLED — removed from the plan, not deferred. Evidence decides, not hope.**
5. ~~Passes 2–5~~ **BUILT 2026-06-09 (owner override of the Stage-2 trigger above) — gated conditional sweeps, degraded-sequential path, reviewer-loop PASS.** Still in Stage 2: the refuter Workflow path (parallel multi-agent execution upgrade for these passes); design-auditor agent (+memory, re-flag suppression — memory not built before this stage, panel EM-4)
6. Hooks (journey-trace gate — depends on /design-audit writing markers, §6) + **CI mirror job of freshness+drift checks (panel DevOps-1)**
6b. Per-milestone success-metric check against spec §0 (owner decision: deferred here from Stage 1; panel PO-1)

**Stage 3 — trigger: first external contribution / documentation engagement / non-web project:**
7. Consumer + archaeologist modes; non-web shapes
8. Plugin packaging (DEFERRED 2026-06-09 — owner low confidence. Build-ready reference: `agent_core/docs/plugin_packaging_reference.md`. Skills-only scope; hybrid (rules stay symlinked); the unresolved source-of-truth fork is documented there.)
9. Optional: /design-md `--source=figma` (§12.5 item 7)

**Global build rule (review finding 14):** any "verify at build time" item (ERD CLI flags, OpenAPI scaffold rows, Figma MCP names) that CANNOT be verified in the build session (offline, tool unavailable) ships as an explicit refuse-to-guess `TODO: verify <command>` stub — the skill errors loudly on that row rather than running a guessed command. Guessed flags are forbidden.

## 12.5 Pinned Clarifications (Monireach review, 2026-06-07 — binding at build time)

1. **/technical-consultant split + handoff contract (Monireach decision 2026-06-07):** SPLIT the skill — ideation phase becomes standalone `/ideation` skill (produces PROJECT_BRIEF.md; behavior unchanged: Step 0 brief + 7 fixed dimensions one at a time + sub-agent research); `/tc` covers tech-stack ONLY, no argument needed (produces TECH_STACK.md). Handoff contract: ideation Dimensions 1–2 (Problem, Persona) overlap PRODUCT_SPEC §0/§1 — Project Brief FEEDS /product-spec (§0 condensed from Brief; actors seeded from Persona; never re-elicit). Edits: (a) `/ideation` closing step: after writing PROJECT_BRIEF.md, PRINT the empty SPEC_SKELETON.md template (5-step table + generating questions) into project root — kills blank-page friction while keeping skeleton content owner-generated (structure supplies coverage; content from owner's head); next step pointer → /product-spec; (b) `/tc` requires PROJECT_BRIEF.md + PRODUCT_SPEC.md (warn-don't-block, mirroring existing line-248 pattern); NFR Step 1 seeds from spec §5, never re-elicits; (c) add "OpenAPI generation support" as a stack-selection criterion (Phase 2 Step 4, Backend Architecture). BOUNDARY KEPT (do not merge): ideation = business layer, AI-led elicitation correct; skeleton = system-design layer, owner generation mandatory (generation vs recognition), and requires a finished Brief anyway.
2. **ERD:** standard artifact = Mermaid `erDiagram` text in `docs/erd.md` (diffable, GitHub-renderable). **Owner: /design-audit Pass 1** (re-derives entities anyway; ERD is a side artifact; archaeologist mode calls same procedure). Decision tree, first match wins: (1) no persistent entities → slot consciously skipped; (2) stack-native code-reader: `paracelsus` (SQLAlchemy, emits Mermaid — preferred over eralchemy2), `prisma-erd-generator`, `django-extensions graph_models`, `rails-erd`; (3) live DB reachable → `mermerd`; (4) agent emits Mermaid from schema source + MANDATORY verification diff vs information_schema or migrations, header marked agent-generated. Artifact contract: header = tool + source + date + exact regeneration command; regenerate-don't-edit rule (generated file, hand-edits forbidden); freshness audited by drift pass (regenerate + diff = finding on mismatch). **Build-time rule: exact CLI flags must be VERIFIED by running each tool once against a real project before being written into the skill — never from memory.** **Execution context per tool (panel DevOps-4):** code-readers (paracelsus) run inside the app container (`docker exec <container> uv run ...` — models import only there); DB-readers (mermerd) run inside the Docker network or against a published port; the recorded regeneration command must be the container-aware form. Tier coverage logic: tier 2 = big ORMs (reads code, no DB needed); tier 3 = ANY language whose DB is mainstream SQL (mermerd reads the DB, language-irrelevant; supported-DB list verified at build); tier 4 = everything else incl. NoSQL (schema always lives somewhere readable: migrations/models/SQL files). No stack falls through all tiers. **Unused-entity detection (Monireach requirement 2026-06-07):** /design-audit Pass 1 gains a schema-vs-code cross-reference — every DB table/column grepped for code references; zero references → `suspected-unused` finding with evidence + confidence, MUST support `undecided` (grep is blind to reflection/external consumers like BI tools), NEVER auto-recommends dropping. ERD stays a photograph of reality (orphans included); suspicions go to FINDINGS.md (archaeologist, category: orphaned-schema) or proposed cleanup tasks in project_status.md (author). Diagram = facts; register = judgments; never mixed.
3. **OpenAPI is NOT universal — three touchpoints (pinned C3; "Class"→"emit-tier" renamed per panel TW-2 to avoid collision with the §12.5-6 epistemic classes):** emit-tier A auto-emitting: FastAPI/Litestar/NestJS/Spring(springdoc)/ASP.NET(Swashbuckle)/Go-huma; emit-tier B annotation-required: Express(tsoa)/Go-swaggo/Rails(rswag); emit-tier C none: spec-first openapi.yaml or conscious skip — never silent. Touchpoint 1 `/tc` Step 4: scored criterion "API contract generation", outcome recorded in TSDR. Touchpoint 2 `/start-local-dev`: emit-tier A → document export command; emit-tier B → install annotation lib + one annotated example endpoint as copy-pattern. Touchpoint 3 `/design-audit` drift: export live spec, diff routes-in-code vs paths-in-spec; code-not-in-spec = finding (emit-tier B's predictable failure = skipped annotation). Shape rule: slot 5 = OpenAPI only for web services; CLI → --help contract; library → documented public API. Build-time verification rule applies to each scaffold row.
4. **Gherkin AC format change:** one backward-compatible addition to `documentation-structure.md` §10.3 — task detail sections MAY carry `**Acceptance:**` Gherkin block as the LAST element of the detail section (added inside, never replacing prose/bullets; prose+bullets = how to build, AC = how to verify done). SHOULD for behavior-changing tasks; refactor/docs tasks may omit. No migration of existing files. **Lifecycle (size concern resolved 2026-06-07):** AC block archives to milestone.md with its task per §2.6; the AC's permanent form is the converted test suite (living documentation) — project_status.md size tracks active workload only; §10.1 multi-file pattern is the escape valve if ever needed. **Additional edit required: `logging-workflow.md` §2.6 milestone entry format — the `**Acceptance:**` block is copied VERBATIM into the milestone entry (the §2.6 rewrite-to-plain-English rule applies to bullets, never to the Gherkin block).** **Archival timing fix (panel Backend-1 — sharpest single catch): AC blocks stay in project_status.md until the WHOLE PHASE completes, then archive with their tasks — per-task §2.6 archival would delete task N's AC while task N+1 still chains from its `Then`, splitting the chain source across two files mid-phase.**
5. **Slot-3 naming is mode-dependent (deliberate):** author mode = TECH_STACK.md + ADR log + PROJECT.md (internal convention); archaeologist mode = ARCHITECTURE.md (client-facing). **ARCHITECTURE.md sections (literal, panel TW-1):** 1. System overview (one Mermaid diagram) · 2. Module/service map [class 1] · 3. Data flow [class 2, cited] · 4. Deployment topology [class 1] · 5. Key decisions & rationale [each tagged: verified-from-code | owner-interview | inferred-UNVERIFIED] · 6. Integration points [class 1].
6. **Epistemic three-class taxonomy (expanded from "mechanical", C6 2026-06-07):** Class 1 MECHANICAL = deterministic procedure, rerun-reproducible (ERD via tool, OpenAPI export, module map, deployment topology from compose) → AI writes without asking, no marking. Class 2 DERIVED = AI synthesis from artifacts, run-variant (reverse-SRS, data-flow narrative, tier-4 ERD) → must verify + cite: `[derived — verified against <source>]`. Class 3 ELICITED = exists only in human heads (BRD why, decision rationale) → stop and ask: `[owner interview]` or `[inferred — UNVERIFIED]`. Skill rule: every deliverable section gets a class BEFORE writing; unclassed sections may not be written; class-3-as-class-2 (inferring rationale from code and stating it as fact) is the forbidden move. This is §3.2 no-hallucination compiled into workflow form.
7. **/design-md Figma source (optional enhancement, off critical path; C7 caveats pinned 2026-06-07):** upgrade = new input adapter only — existing reconcile-into-DESIGN.md machinery unchanged. Verified: Figma connector available in Claude environment; official Figma Dev Mode MCP server exists (desktop-app-local, exposes variables/components). To verify at build: (1) exact MCP tool names/capabilities; (2) Figma plan gating (Dev Mode historically paid-seat); (3) route choice: claude.ai remote connector vs desktop Dev Mode MCP — test both. (4) **Input-quality rule (C6 taxonomy applies):** file uses Figma variables/styles → token extraction is class 1 mechanical; hardcoded-hex file → class 2 derived (AI infers token groupings, marked + human-reviewed). Skill must detect and declare which case — never silently treat a sloppy file as tokenized.
8. **/design-audit output by mode (full schema pinned C8, 2026-06-07):** FINDINGS.md sections: Reconnaissance (archaeologist only: docs trust table current/stale/wrong/unverifiable + conventions) → Findings table → SEPARATE Undecided table (epistemic state, not a severity — never mixed). **Literal headers (panel TW-1):** `| ID | Severity | Category | Finding | Evidence | Recommendation | Status |` and Undecided: `| ID | Category | Question | Why automation can't resolve it |`. Severity anchors: CRITICAL=exploitable/data-loss; HIGH=product-story broken; MEDIUM=degraded correctness; LOW=hygiene. Category = originating pass (makes coverage auditable from the register). Status column owned by client post-delivery. Author mode = NO file: findings grouped by severity → owner verdicts each (approve→🔲 task, owner picks placement / reject-with-reason / defer); undecided → questions, never tasks; **rejected findings + reason → design-auditor MEMORY.md for re-flag suppression (silent on re-runs unless evidence changed) — required for audit convergence.** Consumer mode: register file only, no task creation anywhere.
9. **"Setup docs" (full spec pinned C9, 2026-06-07):** (a) README quick-start — 6 steps (prereqs w/ versions, clone, install, configure via .env.example, run+verify, test), each = copy-pasteable command + EXPECTED OUTCOME line; (b) `.env.example` — var list grepped from config loading (class 1), comment per var (purpose/format/dev-only markers); (c) runtime doc — services table, volumes, per-env differences, 5 common ops (start/stop/logs/rebuild/db-access); (d) deploy runbook iff pipeline exists — deploy + ROLLBACK + health verify + rotation. Done-criterion (executable, agent-runnable): clean environment = throwaway container from a fresh clone in a tmp volume, never the host (panel DevOps-6) → execute README verbatim top-to-bottom → any failure = not done, fix doc, rerun → done = final verify passes clean. **Scope honesty (panel QA-5):** the mechanical check catches missing STEPS; missing CONTEXT (tacit knowledge the executor already had) needs the human attestation "did you type anything not in the doc?" — the criterion is constrained to what's mechanically checkable plus that one attestation. **Archaeologist: verification failures ARE the discovery — each failure = FINDINGS.md finding, category `setup-gap`.** Classes: var names/services table = 1; descriptions = 2 (execution is the citation); legacy deploy procedure = often 3 (interview or UNVERIFIED).
10. **Multi-repo products (review finding 9 — the originating incident WAS cross-repo):** PRODUCT_SPEC.md lives in the primary (backend) repo; sibling repos (e.g., a frontend console) carry a one-line pointer in their PROJECT.md. Journeys MAY span repos (the money journey usually does); tasks NEVER do (matches the existing cross-project boundary rule — each repo's project_status.md holds only its own tasks). The journey-trace gate in the primary repo walks the full cross-repo journey; sibling repos' gates walk only their local segments. /design-audit seam pass treats the repo boundary as a first-class seam.

---

## 13. Related Context Elsewhere

- **Session narrative + decisions + open threads: `agent_core/docs/spec_first_pipeline_journal.md`** — the "what happened and why" companion to this blueprint. Read it FIRST when resuming, for the conversational context this spec doc doesn't carry (mode walkthroughs, the scale-mechanism reasoning, build/reviewer history, proposed next steps).
- Incident + resolution: smart_chatbot `archive/daily_log.md` 2026-06-06; B7–B10 in its `project_status.md`; backend-agent verdict in admin_console `tmp_backend_frontend_discussion.md`.
- Pending exercise (deliberate practice, owner decided to do): **retroactive Pass-0 on smart_chatbot** — owner generates skeleton from head, AI independently from code, diff. Converts "are there flaws left?" into finite table-filling. Not yet scheduled.
- Plugin packaging: canonical build-ready reference is `agent_core/docs/plugin_packaging_reference.md` (supersedes the older smart_chatbot `archive/crucial_notes.md` "[NOT smart_chatbot]" section).
