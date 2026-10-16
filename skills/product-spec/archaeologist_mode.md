# /product-spec — Archaeologist Mode (Documentation Backfill for a Completed Project)

This file is the full procedure for `archaeologist` mode. SKILL.md routes here when the user runs `/product-spec --mode=archaeologist`. It is a supporting file INSIDE the skill directory — it travels with the skill on any machine (§11.4 self-containment), so it references no external paths.

**When this mode applies:** a working (or finished) codebase needs documentation backfilled — for a client handoff, an audit, a portfolio writeup, or to re-establish a spec that was never written. You are documenting what IS, not designing what SHOULD be.

**The governing law — Backfill by derivability:** a document is backfillable only to the degree it is derivable from the code.
- **ERD, API contract → fully derivable** (mechanical).
- **SRS (requirements) → partially derivable** (reverse-generate from behavior, then verify).
- **BRD (the *why*) → never derivable.** Intent lives only in human heads. It MUST be elicited by interview. Inferring intent from code and stating it as fact is the single forbidden move.

**The cardinal rule of this mode:** existing docs are HYPOTHESES, never ground truth. Ground truth = code + schema + running behavior. Every claim in an existing doc is suspect until spot-checked against the code.

**Where the files live:** this mode writes `docs/prd.md` and `docs/architecture.md` (plus `docs/erd.md` via `/design-audit`). All are tracked in git. Run `mkdir -p docs` before the first write.

---

## Step 0 pre-check: Existing Output (re-run safety)

Before Phase 0, check for this mode's own output. Never silently overwrite it.

- **Absent** → run the full procedure.
- **`docs/prd.md` or `docs/architecture.md` exists** → read it, tell the user in 1–2 lines what it covers, and enter UPDATE mode: refine in place and keep content that still passes the trust audit. Your own earlier output is a hypothesis too — it goes through the 0.3 trust audit like any other doc.
- **Legacy root file** (`PRODUCT_SPEC.md` or `ARCHITECTURE.md`) → say so and propose `mkdir -p docs && git mv <old> docs/<new>` (plain `mv` if not a git repo). Move only after the user says yes, then continue in UPDATE mode. A legacy `TECH_STACK.md` is `/tc`'s file — read it as an existing doc and tell the user once to migrate it by re-running `/tc`.
- **Both old and new copies exist** → stop and ask which one is current. Never keep two copies, and never delete either without confirmation.

---

## Project Shape

Run the same shape detection as author mode (web service | CLI | library | data pipeline | frontend | hybrid) and the same persistence-model detection. Every slot below is shape-adjusted: "API contract" means OpenAPI for a web service, `--help` for a CLI, the documented public API for a library. Deep non-web specialization is still maturing — when a step does not map cleanly to the detected shape, say so and ask the owner rather than forcing a web-shaped artifact.

---

## The Epistemic Three-Class Gate (applies to EVERY section of EVERY document you write)

Before writing any section, classify it. Unclassified sections may not be written. This is the no-hallucination rule compiled into a workflow.

| Class | Definition | How to handle | Marking |
|---|---|---|---|
| **1 — MECHANICAL** | Deterministic procedure, rerun-reproducible (ERD via tool, OpenAPI export, module map, deployment topology read from compose file) | AI writes it without asking | no marking needed |
| **2 — DERIVED** | AI synthesis from artifacts, run-variant (reverse-generated SRS, data-flow narrative, agent-emitted ERD for an exotic store) | Must verify against a source and cite it | `[derived — verified against <source>]` |
| **3 — ELICITED** | Exists only in human heads (the BRD *why*, a decision's rationale) | STOP and ask the owner | `[owner interview]` or, if the owner is unavailable, `[inferred — UNVERIFIED]` |

**The forbidden move:** inferring a Class-3 rationale from code and stating it as Class-2 fact. "The team chose Postgres because…" is never derivable — it is elicited or marked UNVERIFIED.

---

## Phase 0 — Reconnaissance (MANDATORY — run fully before deriving ANY document)

You cannot document a system you have not seen run and cannot navigate. Skipping this is how stale docs get faithfully copied into new stale docs.

### 0.1 Get it running

(Inlined onboarding procedure — do not skip even if it "looks obvious".)
1. Read `README.md` or any setup docs that exist.
2. Install dependencies.
3. Run the project in dev mode.
4. Confirm the happy path works — send a request, load a page, run the main script.

**Why first:** you cannot tell a current doc from a stale one if you do not know what "working" looks like. Record what you actually had to do — the gap between the README's steps and the steps that actually worked is your first finding (category `setup-gap`).

### 0.2 Rough map (orientation, not full understanding — 30–60 min, then stop)

1. List top-level folders — what does each do?
2. Find where the program starts (`main.py`, `app.py`, `index.js`, the CLI entry point…).
3. Identify the main "things" the program works with (users, orders, messages — the candidate entities).
4. Read the tests if they exist — tests show what the code is *supposed* to do, in plain examples.

Output a rough mental map: `program starts here → core logic runs here → data is saved here → response goes back`.

### 0.3 Docs inventory + TRUST AUDIT (the heart of reconnaissance)

List every existing document (README, wiki, comments-as-docs, old design notes, this repo's `current_state/`, anything). For each, spot-check its concrete, falsifiable claims against the code/schema/running behavior. Assign one verdict per document:

| Verdict | Meaning |
|---|---|
| **current** | claims match the code as it runs today |
| **stale** | was true once; code has moved on |
| **wrong** | never matched, or actively misleading |
| **unverifiable** | claims something not checkable from code (e.g., a business reason) — route to owner interview |

This table is the Reconnaissance section of FINDINGS.md. Never treat an existing doc as a source for the new docs until it has a `current` verdict.

### 0.4 Convention survey

Survey the patterns the code *actually* follows vs. the ones it half-follows (naming, error handling, layering, test style). Every inconsistency becomes an **owner-interview question**, never a silent guess — "I see two error-handling patterns; which is intended?" is a question, not something you resolve by picking one.

### 0.5 Write the Reconnaissance section of FINDINGS.md

Create `FINDINGS.md` (if `/design-audit` has not already created it this session) with the Reconnaissance section: the trust-audit table (0.3) + the convention findings (0.4) + the setup-gap notes (0.1). `/design-audit` archaeologist mode appends its findings table and undecided table to the same file — FINDINGS.md is the single shared register.

---

## Phase 1 — Backfill the 8 SDLC Slots (only after Phase 0)

Walk the slots in derivability order: mechanical first (cheap, certain), elicited last (needs the owner). Mark every section's class as you go.

### Slot 4 — ERD (Class 1, mechanical) — FIRST, it grounds everything
Call `/design-audit` (it owns ERD generation in Pass 1): it produces `docs/erd.md` from the persistence layer and runs unused-entity detection. Orphaned tables/columns become `orphaned-schema` findings in FINDINGS.md — they do NOT get silently dropped from the ERD (the diagram is a photograph of reality; suspicions are judgments that live in the register).

### Slot 5 — API contract (Class 1 when emit-tier A; shape-dependent)
Per the detected shape: web service → export the live OpenAPI spec (emit-tier A frameworks export for free; tier B needs annotations — missing routes are `setup-gap`/drift findings; tier C → there is none, note it). CLI → capture `--help` as the contract. Library → extract the documented public API. Drift (routes in code not in the exported spec) is a `/design-audit` touchpoint-3 finding.

### Slot 2 — SRS / requirements (Class 2, derived — reverse-generate, then verify)
Run the SAME AI-generation step as author mode Step 2, but sourced from the CODE: entities from the schema, CRUD paths from exposed surfaces, actors from auth/role logic, journeys reconstructed from the routes a real user would traverse. Write it into `docs/prd.md` §§1–6. Every reconstructed claim is Class 2 — cite the code location it was derived from. This is the same artifact author mode produces, reached backwards.

### Slot 1 — BRD / the *why* (Class 3, elicited — NEVER derivable)
Interview the owner for §0 of `docs/prd.md`: the problem, who pays, the business goal, the success metric. If the owner is unavailable, mark each line `[inferred — UNVERIFIED]` — never present an inferred *why* as fact. A completed project whose owner is gone still gets a §0; it is just honestly flagged as unverified.

### Slot 3 — docs/architecture.md (client-facing in this mode)
In author mode slot 3 = `docs/architecture.md` + `docs/adr/`, written by `/tc`. In archaeologist mode it is `docs/architecture.md` written client-facing, with these LITERAL sections, each tagged by epistemic class. If the file already exists, add missing sections in place rather than replacing it:
1. **System overview** — one Mermaid diagram.
2. **Module / service map** — [Class 1].
3. **Data flow** — [Class 2, cited].
4. **Deployment topology** — [Class 1] (read from compose/IaC).
5. **Key decisions & rationale** — each line tagged `verified-from-code` | `owner-interview` | `inferred — UNVERIFIED`.
6. **Integration points** — [Class 1].

### Slot 7 — Backlog
If `project_status.md` exists, note its state; if not, record its absence. Archaeologist mode documents what is — it does not invent a backlog.

### Setup docs (operational deliverable — not one of the 8 SDLC slots; the one with an executable done-criterion)
Produce/repair:
- **(a) README quick-start** — 6 steps: prereqs (with versions), clone, install, configure via `.env.example`, run + verify, test. Each step = a copy-pasteable command + an EXPECTED OUTCOME line.
- **(b) `.env.example`** — variable list grepped from the config-loading code (Class 1), one comment per var (purpose/format/dev-only markers).
- **(c) Runtime doc** — services table, volumes, per-environment differences, 5 common ops (start/stop/logs/rebuild/db-access).
- **(d) Deploy runbook** — only if a deploy pipeline exists: deploy + ROLLBACK + health-verify + secret rotation. Legacy deploy procedure is often Class 3 (interview or UNVERIFIED).

**Done-criterion (executable, agent-runnable):** clean environment = a throwaway container from a fresh clone in a tmp volume — NEVER the host. Execute the README verbatim, top to bottom. Any failure = not done → fix the doc → rerun. Done = the final verify step passes clean in the throwaway container.

**Scope honesty:** the throwaway-container run catches missing STEPS. It cannot catch missing CONTEXT — tacit knowledge the executor already had in their head. Close that gap with one human attestation: "did you type anything that is not written in the doc?" The done-criterion is exactly "the mechanical run passes" + that one attestation — claim no more.

**Archaeologist twist:** for a completed project, the setup-doc verification FAILURES are themselves the discovery — each failure is a FINDINGS.md finding, category `setup-gap`. You are not just writing setup docs; you are surfacing every undocumented assumption the original developers carried in their heads.

### Slot 6 — UI/UX
Per-project optional; for a frontend project, point at the existing components/design tokens as the de-facto spec, or mark consciously skipped.

---

## Phase 2 — Coverage Footer

Close `docs/prd.md` with the 8-slot coverage footer (same table as author mode), each slot marked `file: <name>` / `derivable` / `consciously skipped`, plus its dominant epistemic class. This footer is the proof the backfill is complete — a blank slot is a conscious skip recorded, never an oversight.

---

## What NOT To Do (archaeologist mode)

- Do NOT derive any document before Phase 0 reconnaissance is complete — undocumented assumptions get faithfully copied forward otherwise.
- Do NOT treat any existing doc as ground truth until it has a `current` trust verdict.
- Do NOT infer the BRD *why* or a decision's rationale from code and state it as fact — elicit it, or mark `[inferred — UNVERIFIED]`.
- Do NOT write any document section without first assigning its epistemic class.
- Do NOT silently drop orphaned schema from the ERD — the diagram is a photograph; suspicions go to FINDINGS.md.
- Do NOT resolve a convention inconsistency by guessing — it becomes an owner-interview question.
- Do NOT claim setup docs are done without the throwaway-container run + the tacit-knowledge attestation.
- Do NOT run a guessed CLI flag for ERD/API export — use the verified command or stop and flag `TODO: verify <command>`.
- Do NOT reference any file outside this skill's own directory in instructions you emit.

## Coverage honesty

Archaeologist findings depth is bounded by which `/design-audit` passes RAN. Passes 1 (lifecycle/ERD/unused-entity) and 6 (completeness) always run; Passes 2–5 (authz/BOLA, state-machine, journey-failure, seam) run when their applicability gate fires and are recorded `consciously skipped — <trigger> absent` otherwise. So FINDINGS.md covers lifecycle holes, orphaned schema, drift, completeness gaps, setup-gaps, AND — for a project that triggers the gates — authz, state-machine, journey-failure, and seam findings. Two bounds remain and MUST be stated in the FINDINGS.md epistemic-contract header so coverage is never overstated: (1) any pass whose gate did not fire was skipped, not run clean; (2) the parallel multi-agent + refuter execution path is not yet built, so on a codebase too large to hold a seam's two sides in one session, Pass 5 ran degraded.
