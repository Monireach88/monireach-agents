# Spec-First Pipeline — Build Journal

**Purpose:** the "what happened and why" companion to the spec-first pipeline. When Monireach returns to fine-tune the skills, an agent reads THIS for the conversational context, decisions, and rationale that the code/spec files don't capture — so nobody restarts from scratch.

**Relationship to the other docs (read in this order when resuming):**
1. **`spec_first_pipeline_journal.md`** (this file) — session narrative, decisions, open threads, conceptual context. Start here.
2. **`spec_first_pipeline_design.md`** — the formal blueprint: full skill specs, the 7-role panel sign-off, MVP staging triggers, pinned clarifications. The "what to build" authority.
3. **`plugin_packaging_reference.md`** — build-ready plugin reference (deferred; read only when packaging).
4. The skills themselves — `agent_core/skills/{ideation,product-spec,design-audit,technical-consultant,vibe-code}/` — the live source of truth for behavior.

**How to use this file:** the *Current Build State* snapshot below is the single fastest answer to "where are we?". Session entries are append-only, newest at the bottom. Update the snapshot whenever build state changes.

---

## Current Build State (snapshot — update on every build)

**Last updated:** 2026-06-09

### The system in one paragraph
A spec-first development pipeline that closes the flaw class where a product's WHAT (actors, entities, lifecycles, journeys) is never specified, so whole actors or entity-creation paths silently go missing. Born from a real incident in smart_chatbot: self-registration (the root tenant-creation journey) was never specified, so it was never built — structurally guaranteed, not carelessness. The fix is a chain of skills that force the WHAT to be written and audited before and during code.

### The pipeline (author mode — greenfield)
```
/ideation     → PROJECT_BRIEF.md   (AI-led CTO interview; business layer) + writes empty SPEC_SKELETON.md
[owner fills SPEC_SKELETON.md by hand — generation, not review]
/product-spec → PRODUCT_SPEC.md    (dual independent generation + mechanical diff; calls /design-audit at birth)
/tc           → TECH_STACK.md       (tech-stack decisions only)
/start-local-dev → scaffold
/vibe-code    → code + tests (TDD; calls /design-audit --scope=diff per task)
```

### Built & reviewer-verified
- **`/ideation`** v1.0.0 — Phase 1 of the old `/technical-consultant`, split out. 7-dimension inquiry, sub-agent web research, writes PROJECT_BRIEF.md + empty SPEC_SKELETON.md.
- **`/product-spec`** v1.1.0 — author mode (skeleton gate, `--ai-first` w/ mandatory reason, `--lite`, dual generation + mechanical diff, blind-spot metric, birth audit) + **archaeologist mode** (supporting file `archaeologist_mode.md`).
- **`/technical-consultant` (`/tc`)** v2.0.0 — tech-stack only after the split; NFR seeds from spec §5; API-contract emit-tier A/B/C criterion.
- **`/design-audit`** v1.2.0 — Passes 1–6 + journey-trace, author + archaeologist modes, degraded-sequential path, read-only invariant, `--resync`.
  - Pass 1 (lifecycle/drift + ERD + unused-entity), Pass 6 (completeness critic), journey-trace — always run.
  - **Passes 2–5 (authz/BOLA, state-machine, journey-failure, seam) — built 2026-06-09 as gated conditional sweeps.**
- **`/vibe-code`** v1.3.0 — AC read-first, TDD seed (deny-path + boundary), spec-first shrink, Step 7 design-audit wrap.
- **AC format** — Gherkin `**Acceptance:**` blocks live in `project_status.md` task details; rules in `documentation-structure.md §10.3` + `logging-workflow.md §2.6`.

### Deferred (trigger-gated — NOT abandoned)
- **Refuter Workflow / parallel multi-agent execution path** — the scale mechanism (sub-agent fan-out). Trigger: a project large enough to overflow a single session, or sustained MVP use across 2+ phases. This is the upgrade that makes Passes 2–5 scale and stay low-noise.
- **design-auditor agent + memory** (re-flag suppression across runs).
- **Hooks (journey-trace commit gate) + CI mirror.**
- **Consumer mode** (intake checklist for contributing to someone else's project) — defined, explicitly NOT implemented; both skills refuse and say so rather than improvise.
- **Non-web deep specialization** — shape detection exists; deep CLI/library/pipeline/data specialization "still maturing."
- **Plugin packaging** — see `plugin_packaging_reference.md`.

### The three modes (orientation)
| Mode | Direction | Command | Produces |
|---|---|---|---|
| **Author** | forward (idea → spec → code) | the full pipeline above | PROJECT_BRIEF, PRODUCT_SPEC, TECH_STACK, code |
| **Archaeologist** | backward (code → spec → docs) | `/product-spec --mode=archaeologist` | PRODUCT_SPEC, ARCHITECTURE.md, docs/erd.md, FINDINGS.md, setup docs |
| **Consumer** | (gap) | NOT BUILT | — |

---

## Session — 2026-06-09 (mode walkthrough + Passes 2–5 build)

**Frame:** Monireach asked to be walked through how to actually USE the three modes (everything was built but he didn't know the flow), then drilled into archaeologist confidence for a large project, then authorized building Passes 2–5. Session is conceptual context + one build. Stopping after the build; he asked for this comprehensive log.

### Thread A — the three-mode walkthrough (file flows)
Documented the author and archaeologist pipelines slot-by-slot (captured in the snapshot above). Correction made and standing: **Consumer mode is NOT built** — he had assumed "everything" was built. Author + archaeologist are the two working modes.

### Thread B — Gherkin AC: when and where (his Q1)
- **Location:** inside `current_state/project_status.md`, in each task's `### 🔲` detail section, as the LAST element (`**Acceptance:**` + a ```gherkin block). NOT in PRODUCT_SPEC.md, TECH_STACK.md, or PROJECT.md — the documentation phase produces ZERO Gherkin.
- **Timing:** written at **phase planning, per phase** — all of a phase's AC together, never one-at-a-time during implementation, never all-upfront for the whole project. Reason: the per-journey chain (upstream task's `Then` becomes downstream task's `Given`) can only be reasoned about one coherent phase at a time.
- So "do all Gherkin blocks exist before `/vibe-code`?" → for the phase you're about to build, YES; for the whole project, NO.
- `/vibe-code` Step 3a is **read-first**: it consumes the AC, authoring one only as a fallback if missing. A missing AC at vibe-code time signals skipped phase planning, not a normal path.
- Dual generation applies here too (owner drafts from intent, AI drafts from PRODUCT_SPEC.md, diff).

### Thread C — archaeologist confidence on a LARGE, different-stack project (his Q2)
This is the project he'll use archaeologist mode for most. Honest assessment, by axis:
1. **Tech-stack coverage — risk #1.** ERD (Slot 4) is VERIFIED only for SQLAlchemy (`paracelsus`). Prisma/Django/Rails are refuse-to-guess `TODO: verify` stubs; NoSQL → hand-emit + field-by-field verify. API contract (Slot 5) assumes you know the framework's emit-tier (A/B/C). So on a new stack, Slots 4/5 STOP and require a one-time tooling verification before producing output. Per-stack setup cost, by design.
2. **Scale — risk #2.** Execution is degraded-sequential, single-session, no fan-out. Phase 0 recon is "rough map, 30–60 min, then stop." On a codebase much larger than smart_chatbot, one session can't hold it all and the rough map covers proportionally less. **Least confident axis.**
3. **Documentation deliverables — moderate-high confidence**, conditional on #1. The 8-slot backfill, epistemic 3-class gate, trust-audit, throwaway-container setup verification — all stack-agnostic and solid.
4. **Audit depth — was the gap that triggered the build.** Before today, FINDINGS.md covered only lifecycle/orphaned-schema/drift/completeness/setup-gaps — NOT authz/state-machine/journey-failure/seam. And those four DOMINATE large systems (small projects rarely have complex authz matrices or many seams). So the missing passes hurt proportionally more the bigger the system.

**Recommendation given:** before building anything, **smoke-test on the real project** — run Phase 0 + Slot 4 (ERD) to surface the stack-tooling and scale realities with facts, not speculation. (He chose to build the passes first; the smoke-test is still the proposed next step — see Open Threads.)

### Thread D — why Slots 4/5 "stop and ask YOU" (his Q1 follow-up — important misconception fixed)
- The stop is an **anti-hallucination guard on one specific action** (the ERD/API CLI command), **NOT** an overwhelm/context-size limit. Size-independent: a 50-line Prisma toy hits it; a million-line SQLAlchemy project does not.
- The ERD is produced by a TOOL reading the models, not by the LLM reading all the code. The skill only refuses to run a *guessed* command (global "never guess CLI flags" rule). It can always fall through to Tier 4 (read the schema, hand-emit Mermaid, then verify field-by-field).
- "Why me and not the AI?" — the AI **can** self-verify (`--help` + a real generation) if it has shell access to the running project. It asks the human only when it can't (tool not installed, needs the app's deps/live DB, or tool choice is a judgment call).
- **Harness-engineering reflection (his):** he had partly built "Harness Engineering" to solve large-codebase overwhelm via "understand tiny components gradually until the whole project is screened," and concluded it "wasn't the solution." Correction: two problems were fused. The harness (knowledge/judgment/timing layers — skills/rules/hooks) captures JUDGMENT; it was never the mechanism for SCALE. His decomposition instinct was right as a *strategy*; what was missing was the *execution mechanism* (Thread E). The two are complementary, not competing.

### Thread E — the scale mechanism (his follow-up: "is using sub-agents the solution?")
- **Why gradual decomposition alone fails:** done inside ONE context window, "understand component 1…50" overflows — by component 50, component 1 has been summarized away. The decomposition is conceptual but the container is a single context. Never converges.
- **The mechanism:** sub-agent fan-out + **compress at the boundary.** Each sub-agent burns its OWN fresh full context understanding ONE component, returns only a ~300-token structured finding. The orchestrator holds N small summaries, never N codebases. That's how you screen a codebase larger than any single context.
- **The catch (the hard part):** each sub-agent is blind to anything spanning components — an auth flow across 5 modules, a seam between services, a cross-system journey. So the full mechanism is three parts: (1) the decomposition boundary [the hard judgment — bad slices hide cross-cutting logic], (2) a structured return contract [a fixed schema], (3) a **synthesis + seam pass** on the assembled summaries [the cross-component blind-spot fix].
- **Key insight:** part (3) IS exactly Passes 4–5 (journey-failure, seam) run on assembled summaries. So the SCALE problem and the AUDIT-DEPTH problem **collapse into one build** — the unbuilt "parallel multi-agent path with adversarial refuters."
- **The vehicle in this environment:** the `Workflow` tool — `parallel()`/`pipeline()` fan out sub-agents, structured-output schemas enforce the return contract, a final stage does the synthesis/seam pass.
- **Sub-agent count control (his side question):** controllable + bounded. You set the count by how many items you pass to `parallel()`/`pipeline()`; the runtime caps *concurrent* execution at `min(16, cores−2)` (extras queue); can scale to a token budget. Not left to model discretion.

### Thread F — the Passes 2–5 build (his Q3 → "go, build the four passes")
**Difficulty re-assessment (I had overstated it; he challenged, correctly):** the four passes are NOT hard to write — each follows the same shape as Pass 1 (enumerate → loop → forced verdict), and their **enumeration sources already exist in PRODUCT_SPEC.md**, so each is ~Pass-1-sized prose (~250 lines total, a few hours). What IS genuinely hard is the *orchestration layer* (parallel fan-out + refuters), and that is NOT a prerequisite — Pass 1 already runs without it, so Passes 2–5 ship the same degraded-sequential way and get the orchestration upgrade later.

**Gate design (his instinct, adopted):** list the passes AND make each a CONDITIONAL sweep with an applicability gate. Beats both alternatives — "named but refuse to run" wastes the knowledge; "list without a gate" runs an authz sweep on a single-user script and generates noise. Gate fires → run; gate absent → record `consciously skipped — <trigger> absent`.

**The four passes as built:**
| Pass | Catches | Enumeration source | Fires when |
|---|---|---|---|
| 2 authz/BOLA | logged-in user reads another's data; privileged op, no role check | actors §1 × CRUD matrix §3 | >1 actor, OR auth exists, OR per-user/per-tenant data ownership |
| 3 state-machine | illegal/orphan transitions, unguarded transitions | status enums in schema | a state field with a *constrained* transition (terminal/one-way/guarded) |
| 4 journey-failure | a step with only a happy path; half-completed payment | journeys §4, each step | journeys exist (≈always; structural variant at greenfield) |
| 5 seam | external call w/o timeout/retry/idempotency/error-handling | external actors §1 + grep | a third-party API / inter-service / queue boundary (NOT the app's own DB) |

Greenfield: 2/3/5 need code (skipped at birth); 4 runs a structural variant (does the spec name each step's failure branch?).

**Reviewer loop (independent Opus, per his standing instruction "edit until passing"):** Round 1 → NEEDS-EDIT, **5 real defects, all genuinely my errors:**
1. Pass 2 gate keyed on actor COUNT → missed single-role/multi-user BOLA. Fix: per-user/per-tenant ownership is an independent fire condition.
2. Pass 3 gate ">2 states" → wrongly skipped 2-state one-way/terminal transitions. Fix: gate on constrained-transition existence, not count.
3. Pass 5 gate "DB across network" → fired on every web app's own Postgres = noise. Fix: exclude the app's own datastore; only third-party/inter-service/queue.
4. Pass 5 enumeration source cited spec §2/entities → call-outs actually live in §1/actors. Fix: corrected citation.
5. Output-discipline wording "which passes ran and which are not implemented" → read active passes as unimplemented. Fix: separated "consciously skipped (gate absent)" from "not-implemented (execution path/hooks)."
All 5 fixed → Round 2 re-verify → **PASS**, no regressions, fences clean.

**Doc sync done:** `spec_first_pipeline_design.md` (Status + §5 MVP staging + §12 build order) records Passes 2–5 built as an **owner override of the Stage-2 mechanical trigger** (≥2 phases w/ verified findings) — same sanctioned-early pattern as archaeologist mode. smart_chatbot `daily_log.md` got a build entry.

### Decisions locked this session
- Passes 2–5 = conditional sweeps with applicability gates (not unconditional, not refuse-to-run).
- Built ahead of the Stage-2 trigger by explicit owner authorization; refuter/agent/memory/hooks stay trigger-gated.
- Scale problem + audit-depth problem are ONE build (the parallel/refuter path) — recognized, deferred together.
- The harness (judgment) and orchestration (scale) are complementary layers, not competitors.

### Open threads / proposed next steps (for the next fine-tuning session)
1. **Smoke-test archaeologist mode on the real large project** — run Phase 0 (recon) + Slot 4 (ERD) to surface: (a) does the stack's ERD/API tooling need a verification pass; (b) does one session hold enough or do we need subsystem-by-subsystem scoping; (c) how much do the new passes actually fire on this system's shape. **This validates the passes against real code — they've passed documentation review but never been exercised.**
2. **Build the refuter / parallel multi-agent path** when a real project overflows the sequential path (the scale mechanism from Thread E; collapses with audit-depth). `Workflow` tool is the vehicle.
3. **Consumer mode** — still a gap; build when the first external-contribution scenario lands.
4. **Per-stack ERD/API tooling verification** — turn the Prisma/Django/Rails/NoSQL `TODO: verify` stubs into verified commands as each stack is first encountered.
5. **Non-web deep specialization** — first non-web project.

### Caveat to carry forward
"Built" here = complete as skill instructions + passed adversarial *documentation* review. The passes have NOT been exercised on a real codebase. First real run (open thread #1) is where gate behavior and enumeration-source correctness get validated against actual code.

---

## Session — 2026-10-06 (file rename to `docs/`)

The owner approved an SDLC docs convention. Pipeline outputs moved out of the repo root into `docs/`, tracked in git:

- `PROJECT_BRIEF.md` → `docs/product-brief.md`
- `SPEC_SKELETON.md` → `archive/spec_skeleton.md` (private working draft, not committed)
- `PRODUCT_SPEC.md` → `docs/prd.md`
- `TECH_STACK.md` → `docs/architecture.md` (what the system is) + `docs/adr/NNNN-<title>.md` (one file per decision, Nygard format, immutable once Accepted)

Every producer skill is now safe to re-run: it updates its existing output, and offers to migrate a legacy root file. Consumer skills read the new path and fall back to the legacy file with a one-time migrate notice. Old names in earlier entries and in the snapshot above are historical; the skills and `spec_first_pipeline_usage.md` hold the live paths.

