---
name: design-audit
description: Use when the user invokes "/design-audit". The single design-judgment engine — audits a codebase against PRODUCT_SPEC.md through enumerated passes (lifecycle/drift + ERD + unused-entity, authz/BOLA, state-machine, journey-failure, seam, completeness critic, journey trace). Never an open-ended "find flaws" prompt; every item gets a forced verdict ok | flaw | undecided with file:line evidence. Read-only on source code — findings are reported, never applied. Called at spec birth by /product-spec, manually mid-development, and by /vibe-code on diffs.
version: 1.3.0
---

# /design-audit — Enumerated Design Audit

You are now operating as a design auditor. Your job is to find where the code and the product's stated WHAT (actors, entities, lifecycles, journeys) disagree — by exhaustively walking enumerations, never by skimming for whatever catches attention.

**Core principle:** never run an open-ended "find flaws" prompt. Enumerate → loop → classify every item → force a verdict. Attention-sampled review misses items with no salience; an enumerated loop cannot skip a row. The ONE deliberate exception is the completeness critic (Pass 6), which is open-ended on purpose — it hunts what the enumerations themselves are missing.

## Invocation

- `/design-audit` — full scope (whole codebase vs whole spec)
- `/design-audit --scope=phase` — active phase only; on pass, writes the journey-trace marker
- `/design-audit --scope=diff` — staged/recent diff only (the /vibe-code post-task call site)
- `/design-audit --mode=archaeologist` — documentation-engagement audit: writes a FINDINGS.md register (see Archaeologist Mode below)
- `/design-audit --resync` — amnesty re-baseline after a process lapse (see Resync section)

**Modes:** author (default — findings presented in-session, no register file) and **archaeologist** (writes a `FINDINGS.md` register file — see the Archaeologist Mode section). `consumer` mode (register-only, no task creation) is defined in the harness design but NOT implemented — say so if asked, do not improvise it.

**Call sites:** (1) /product-spec at spec birth, (2) manual mid-development, (3) /vibe-code after a task's diff, (4) /product-spec archaeologist mode (Pass 1 ERD + unused-entity + drift, written to FINDINGS.md). One more call site exists in the harness design but is NOT implemented yet: hook delegation — if asked, say exactly that; do not improvise it.

**Implemented passes (this version):** Pass 1 (lifecycle/drift + ERD + unused-entity), Pass 2 (authz/BOLA), Pass 3 (state-machine), Pass 4 (journey-failure), Pass 5 (seam), Pass 6 (completeness critic), and the journey trace. Passes 2–5 are **conditional sweeps** — each fires only when its applicability gate matches the project (see each pass); when a gate does not fire, record `consciously skipped — <trigger> absent` and move on. Never run a sweep whose gate is absent (that manufactures noise — e.g. an authz sweep on a single-user script with no protected resources).

**Execution paths (this version):** TWO are implemented. (1) **Sequential** — passes run one-by-one in this session, with a single verification pass over findings; the default that always works, and the ONLY path for `--scope=diff` and `--scope=phase` (a small diff gains nothing from fan-out). (2) **Parallel (Workflow)** — for `--scope=full` audits: passes fan out as concurrent Workflow agents with a synthesis stage; see the Parallel Execution Path section. Use parallel when scope is full AND the Workflow tool is available; fall back to sequential otherwise and say so in the report. Passes 5 (seam) and 4 (journey-failure) benefit most from the parallel path, because a seam spans two components and a single sequential reader can miss the cross-component half; in sequential mode that bound is stated in the report.

## Inputs

1. **PRODUCT_SPEC.md** — the canonical WHAT. If absent: run DEGRADED with a loud warning ("auditing without a spec — drift cannot be measured, only internal code inconsistencies; run /product-spec to enable the full audit"). In degraded-no-spec mode, Pass 1 still re-derives the CRUD matrix from code and reports lifecycle holes (entities with no creation/deletion path), but cannot diff against intent.
2. **The codebase** — ground truth for what IS.
3. **Scope parameter** — full | phase | diff (default full).

**Read-only invariant (absolute):** this audit NEVER edits source code, configs, or tests, and never applies fixes. Its only writes are its own artifacts: `docs/erd.md`, `docs/journey_traces/<phase-slug>.md`, and — in archaeologist mode only — `FINDINGS.md`. Findings become proposed tasks only after the owner approves each one.

---

## Step 0: Project Shape and Persistence Model

Detect (or ask): web service | CLI | library | data pipeline | frontend app | hybrid. Then detect the persistence model — relational (ORM models / migrations / SQL), document store, event store, files, or none. Pass 1 reads whatever persistence model the stack chose — never assume SQL.

If the project has **no persistent entities**: Pass 1's matrix/ERD work is *not applicable — consciously skipped* (say so in the report); Pass 6 and the journey trace still run.

**Greenfield (spec exists, no code yet — the /product-spec birth call):** structural passes only, since there is nothing to drift against. Check: every journey arrow lands on a filled matrix cell; every entity has a creation path somewhere in the matrix (an entity nobody can create is the classic missing-lifecycle flaw); every blank cell is either filled or listed in Non-goals; NFR slots all tagged. Then run Pass 6. Skip ERD, unused-entity, and the trace marker. **Passes 2, 3, 5 require code → skipped at greenfield** (run them once code exists). Pass 4 (journey-failure) runs a STRUCTURAL variant at birth: for each journey step, does the spec acknowledge its failure branch (declined payment, validation failure, external-call failure), or only the happy path? A spec that names only happy paths is a finding now, before any code exists to forget them.

---

## Pass 1 — Lifecycle Completeness, Drift, ERD, Unused Entities

### 1a. Re-derive the CRUD matrix from code

From the persistence layer (models, migrations, collections, event types — whatever the stack uses), enumerate every persistent entity. For each entity × {Create, Read, Update, Delete}: find the code path that performs it (exposed surface → handler → persistence call) and record WHO can trigger it through WHAT path. "Exposed surface" means whatever the shape exposes: HTTP endpoint, CLI command, public function, message handler, scheduled job.

### 1b. Diff vs spec (the drift check)

Cell-by-cell against PRODUCT_SPEC.md §3:

```
for each entity × op:
  in spec only  → unimplemented intent (flaw or planned-future — check the backlog before flagging)
  in code only  → undocumented behavior (spec-first discipline lapse, or scope creep)
  in both, but WHO/path disagree → drift
  in neither    → confirm it appears in Non-goals; absent there too → unmade decision
```

Entities present in code but absent from the spec (or vice versa) are findings at the entity level before any cell comparison.

### 1c. ERD (side artifact of this pass)

Standard artifact: Mermaid `erDiagram` text in `docs/erd.md` — diffable, renders on GitHub. Decision tree, first match wins:

1. **No persistent entities** → slot consciously skipped, no file.
2. **Stack-native code reader exists** → use it. VERIFIED command (SQLAlchemy projects):
   ```bash
   uv run --with paracelsus paracelsus graph <module.path>:Base --import-module "<models.module>:*" --python-dir . --format mermaid
   ```
   (verified 2026-06-07 against a production SQLAlchemy project; emits Mermaid to stdout). It must run where the models import — inside the app container for Docker projects: `docker exec <container> uv run --with paracelsus paracelsus graph ...`. Other ORMs — `TODO: verify before first use, run the tool's --help and a real generation, never guess flags`: `prisma-erd-generator` (Prisma), `django-extensions graph_models` (Django), `rails-erd` (Rails). If the verification cannot be done now, STOP on this tier and fall through — never run a guessed command.
3. **Live DB reachable, mainstream SQL** → `mermerd` reads the schema directly (language-irrelevant). `TODO: verify flags + supported-DB list before first use.` Run inside the Docker network or against a published port.
4. **Everything else (incl. NoSQL)** → the schema always lives somewhere readable (migrations, model files, schema definitions): emit the Mermaid yourself from that source, then MANDATORY verification — diff your output against the schema source (or `information_schema` if a DB is reachable) entity-by-entity, field-by-field. Mark the file header `agent-generated`.

**Artifact contract:** `docs/erd.md` header = tool + source + date + the exact regeneration command (container-aware form). Generated file — hand-edits forbidden; regenerate, don't edit. Freshness is audited by this pass: regenerate and diff against the committed file; mismatch = finding.

The ERD is a **photograph of reality** — orphaned tables and columns appear in it. Facts go in the diagram; judgments go in findings. Never mix them.

### 1d. Unused-entity detection

For every table/column (or document field) in the schema: grep the codebase for references. Zero references → `suspected-unused` finding with the grep evidence and a confidence level. This check MUST support `undecided` — grep is blind to reflection, dynamic query builders, and external consumers (BI tools, other services reading the DB). NEVER auto-recommend dropping anything; in author mode, confirmed suspicions become *proposed* cleanup tasks for the owner to judge.

---

## Passes 2–5 — Conditional Sweeps

Each of these fires ONLY when its applicability gate matches the project. **Check the gate first; if it does not fire, record `consciously skipped — <trigger> absent` in the report and move to the next pass.** Running a sweep whose trigger is absent manufactures noise (an authz sweep on a single-user script, a state-machine sweep on an entity with no status field). The gate is read from `PRODUCT_SPEC.md` + the code; when the spec is missing, derive the gate input from code and mark the pass `undecided` where intent can't be confirmed.

All four follow the Pass-1 discipline: enumerate from a named source, loop every item, force a verdict `ok | flaw | undecided` with file:line evidence. Category = the pass name (`authz` | `state-machine` | `journey-failure` | `seam`), so coverage stays auditable.

### Pass 2 — Authorization / BOLA sweep

**Applies when:** the spec has more than one actor, OR any resource is non-public (auth exists), OR any data is owned per-user / per-tenant — one actor *type* but each user must not see another's rows (BOLA exists with a single role; actor *count* is NOT the test). **Skip when:** single-user, no auth, no per-user data ownership (e.g. a local single-user CLI).

**Enumeration source:** actors (spec §1) × the CRUD matrix (spec §3) — every `(actor, entity, op)` the matrix permits.

```
for each (actor × entity × op) the matrix permits:
  locate the handler / code path
  authentication present?          (is the caller identified at all)
  object-level ownership check?    (can actor A act on actor B's row?)        ← OWASP API1 BOLA
  function-level role check?       (is a privileged op gated by role, not just auth?) ← API5 BFLA
  multi-tenant: row-level isolation enforced at the DB layer?
  verdict: ok | flaw | undecided + file:line
```

The matrix's **Who** column is the authority: if code permits an op the matrix restricts to another actor, that is a `flaw`. **undecided** when authorization is enforced somewhere not statically visible (middleware, a decorator, an external policy engine) — flag it for confirmation, never assume it is absent. Authentication-without-ownership (any logged-in user can read any record by ID) is the single most common real flaw this pass exists to catch.

### Pass 3 — State-machine sweep

**Applies when:** any entity has a status / state / lifecycle field whose transitions are domain-constrained — a terminal state, a one-way transition (`draft → published` that must never revert), or a guarded transition. State *count* is not the test: a two-value field with a one-way or terminal rule qualifies. **Skip when:** the only multi-value fields are freely-toggling flags with no ordering or terminality constraint.

**Enumeration source:** the status enums in the schema (the field + its allowed values). Build the ACTUAL transition graph from code — what sets the field, from which value to which.

```
for each state:        reachable from the initial state?  has an exit (unless terminal)?
for each transition:   guarded by a precondition, or unconditional?  who can trigger it (→ cross to Pass 2)?
illegal transitions:   can code jump directly between states the domain forbids?
orphan states:         a state nothing transitions INTO, or nothing transitions OUT of
verdict per state + per transition: ok | flaw | undecided + file:line
```

The **intended** transition graph ideally comes from the spec/owner. If it was never documented, the graph you reconstruct from code is a Class-2 derived artifact — present it to the owner to confirm; do NOT assume the code's current graph is the intended one (that would "verify" a bug as correct).

### Pass 4 — Journey-failure sweep

**Distinct from the journey TRACE** (below): the trace walks the happy-path AC chain (upstream `Then` → downstream `Given`). This pass walks the FAILURE branches the trace ignores — what happens when a step does not succeed.

**Applies when:** journeys exist in spec §4 (≈ always). At greenfield it runs the structural variant (does the spec name each step's failure branch?).

**Enumeration source:** journeys (spec §4), each step (arrow).

```
for each journey (money journey P0 first — half-completed payment is the classic incident):
  for each step:
    enumerate its failure modes (external call fails, validation fails, payment declined,
                                 concurrent conflict, partial write, timeout)
    is there a handling path?   (retry / rollback / compensating action / user-facing error)
    does failure leave the system recoverable, or stuck / inconsistent?
    verdict: ok | flaw | undecided + file:line
```

**undecided** when handling may live in a layer not visible from the step's handler (global error middleware, a queue dead-letter path) — flag, don't assume. A step whose only coded path is the happy path, with an unhandled failure mode that leaves persisted state half-written, is a `flaw`.

### Pass 5 — Seam sweep

**Applies when:** any external or inter-service boundary exists — a third-party API, another internal service, or a message queue/broker. The app's OWN primary datastore on its trusted network is NOT a seam for this pass (its lifecycle is Pass 1's job; only a DB reached across an untrusted or cross-service boundary counts). **Skip when:** pure single-process with no outbound calls beyond its own datastore.

**Enumeration source:** the call-out inventory — external systems appear as actors in spec §1 (the actor generation asks "what external systems call in? what does the system call out to?"), so start from the external actors listed there, then grep for HTTP clients, SDK calls, and queue publishes to catch any the spec missed.

```
for each seam:
  error handling?         (the call is wrapped; its failure does not crash the caller)
  timeout set?            (no unbounded wait)
  retry + backoff?        (transient failure tolerated, with jitter)
  idempotency?            (safe to retry without double-effect — critical for writes / payments) ← API9 §9 backend rule
  partial-failure state?  (caller left recoverable, per the §1 design rule)
  return data validated?  (do not trust external data)                                          ← OWASP API10
  verdict per seam: ok | flaw | undecided + file:line
```

This is the pass most exposed to the single-session blind spot: a seam straddles two components, so a sequential reader holding only one side can miss the other half. In sequential mode, state that bound in the report when the codebase is too large to hold both sides at once. In the parallel path, this pass runs on the assembled component summaries from the scout stage (not raw code), which is exactly what it needs.

---

## Pass 6 — Completeness Critic

The one deliberately open-ended pass: ask "what is ABSENT from these enumerations?" — a missing actor (who operates this in production?), a missing entity (where does the audit trail live?), a missing journey (how does anyone become the first admin?), a missing document. Spawn one fresh sub-agent for this when available (independence from the session's accumulated assumptions); otherwise run it as a dedicated step after deliberately re-reading the spec's actor/entity/journey lists as a stranger would.

This pass exists because Pass 1 can only verify what is enumerated — a missing entity has no row, no cells, no arrows to visit.

---

## Journey Trace (`--scope=phase`, and within full scope)

Walk **each journey's ordered path** through whichever tasks implement it:

- Along a journey, an upstream task's `Then` must produce the downstream task's `Given` (the Gherkin `**Acceptance:**` blocks in the backlog's task details are the chain links). Fan-out/fan-in is allowed — one task can feed several, several can converge.
- NEVER applied phase-wide across unordered tasks — parallel independent tasks have no chain obligation to each other. Only tasks on the same journey chain.
- A broken link (a `Given` no upstream `Then` establishes, starting from stranger/zero state) is exactly the incident class this audit exists for: an entity or state assumed into existence.
- **Multi-repo products:** the primary repo's trace walks the full cross-repo journey; a sibling repo's trace walks only its local segment.

**On a passing phase trace, write the marker** `docs/journey_traces/<phase-slug>.md` containing:
1. The trace itself — journeys walked, the task chain per journey, AC links verified.
2. A content hash of the phase's AC-block text: concatenate the phase's `**Acceptance:**` blocks in task order, normalize whitespace (strip trailing spaces, collapse blank runs), then `shasum -a 256`. Record the hash and the exact command. Content hash, never file dates — git does not preserve mtimes.

The marker is evidence a trace passed, not a flag to flip. Downstream tooling compares the stored hash against the current AC content to detect staleness.

---

## Parallel Execution Path (Workflow — `--scope=full` only)

This section is the explicit instruction that authorizes calling the **Workflow tool**. Gate: scope is `full`, code exists (not greenfield), and the Workflow tool is available. Any other case → sequential path.

Workflow script shape (three stages):

1. **Scout stage (sequential, in-script first):** one agent builds the shared inputs every pass needs — the entity list, the actor list, the journey list from the spec, and per-component summaries (the seam pass consumes these instead of raw code). Cheap, and it prevents N agents re-deriving the same enumerations divergently.
2. **Pass fan-out (parallel):** one agent per applicable pass — Pass 1 (lifecycle/drift/ERD/unused-entity), and Passes 2–5 each ONLY if its applicability gate fires (gates are evaluated in the scout stage; a skipped gate is recorded, never fanned out). Pass 6 (completeness critic) runs as its own fresh agent — its independence requirement is native here. Each agent receives: its pass section from this skill verbatim, the scout outputs, and a structured-output schema (`{items: [{id, category, verdict, evidence, severity?}]}`) so returns are mergeable without parsing prose.
3. **Synthesis stage (barrier — genuinely needs all results):** dedup findings that two passes surfaced (same file:line + same defect → keep the higher-severity one, cross-reference the categories), then assemble the standard report. The barrier is justified: dedup requires the full result set.

**Optional refuter panel (when the user asked for a thorough/pre-release audit):** for each `flaw` finding, fan out 3 adversarial refuters with distinct lenses (does the evidence hold at that file:line? is there a mitigating layer elsewhere — middleware, decorator, dead-letter path? does the spec actually require this?). A finding survives only if ≥2 of 3 fail to refute it; refuted findings become `undecided` with the refutation noted — never silently dropped. This kills plausible-but-wrong findings before they reach the owner.

Everything else is unchanged: read-only invariant, forced verdicts, owner approval per finding, epistemic contract. The report must state which path ran.

---

## Output Discipline

**Forced verdict per enumerated item:** `ok | flaw | undecided` + file:line evidence. `undecided` is mandatory in the vocabulary — without it, uncertainty gets silently rounded to ok or flaw. The single verification pass re-checks each `flaw` against its evidence once; anything that doesn't conclusively hold becomes `undecided`, never silently dropped.

**Author-mode report (no findings file is written):** findings grouped by severity, presented to the owner one at a time for a verdict on each:
- **approve** → becomes a 🔲 task in the project's backlog (owner picks placement/phase) — never auto-logged;
- **reject (with reason)** → recorded in the session report; persistent re-flag suppression across runs is a later-stage addition (a dedicated auditor agent with memory) — until then, a re-run may re-present a previously rejected finding, and that is expected behavior, not a bug;
- **defer** → noted, no task.

Severity anchors: CRITICAL = exploitable / data loss; HIGH = product story broken; MEDIUM = degraded correctness; LOW = hygiene. Category = the originating pass (makes coverage auditable).

`undecided` items are presented as **questions to the owner, never as tasks** — they are an epistemic state, not a severity.

**Epistemic contract (state at the top of every report):** this audit guarantees that no flaw of an *enumerated class* survives the passes that ran; it cannot guarantee flaws outside the enumeration — a missing entity has no cells to visit. Mitigations: journeys-from-stranger, the spec's dual generation, Pass 6. Also state, per pass: which ran, which were **consciously skipped because their applicability gate was absent**, which **execution path ran** (sequential or parallel, refuter panel or not), and which capabilities **are not yet implemented** (hook integration, consumer mode). A skipped-gate pass is not the same as an unimplemented one — never conflate them, so coverage is never overstated.

---

## Archaeologist Mode (`--mode=archaeologist`)

For a documentation engagement on a completed project (usually called by /product-spec archaeologist mode, but runnable standalone). Same passes, same forced verdicts — the difference is the OUTPUT: a written `FINDINGS.md` register file instead of an in-session report, because a documentation deliverable must persist and be handed off.

**Write `FINDINGS.md` with these sections, in order:**

1. **Epistemic-contract header** — which passes ran, which were skipped, and WHY each was skipped (gate absent vs not-yet-implemented). State per pass: Pass 1 (lifecycle/ERD/unused-entity) and Pass 6 (completeness) always run; Passes 2–5 (authz/state-machine/journey-failure/seam) run when their applicability gate fires and are recorded `consciously skipped — <trigger> absent` otherwise. State which execution path ran (sequential or parallel Workflow — archaeologist engagements are full-scope, so the parallel path applies when the Workflow tool is available); if the seam pass ran sequentially on a codebase too large to hold both sides of a seam, say it ran degraded. Always include the enumerated-class guarantee statement. Coverage is never overstated.
2. **Reconnaissance** (this section is created by /product-spec archaeologist mode's Phase 0 — if it already exists in the file, APPEND to the file below it; if running standalone without that phase, write a one-line note that reconnaissance was not performed). It holds the docs trust-audit table (current/stale/wrong/unverifiable) + convention findings.
3. **Findings table** — literal headers, never reworded:
   ```
   | ID | Severity | Category | Finding | Evidence | Recommendation | Status |
   ```
4. **Undecided table** — SEPARATE from findings (an epistemic state, not a severity), literal headers:
   ```
   | ID | Category | Question | Why automation can't resolve it |
   ```

**Column rules:**
- **Severity** anchors: CRITICAL = exploitable/data-loss; HIGH = product-story broken; MEDIUM = degraded correctness; LOW = hygiene.
- **Category** = the originating pass — plus two archaeologist-specific categories: `orphaned-schema` (unused-entity findings from Pass 1d) and `setup-gap` (a setup-doc step that failed the throwaway-container run, or a config/assumption the existing docs omitted). Category makes coverage auditable from the register.
- **Status** column is owned by the client post-delivery (open/accepted/fixed/wontfix) — the audit leaves it blank.

**API-contract drift (touchpoint 3):** export the live API contract per the project's emit-tier/shape, diff routes-in-code vs paths-in-the-exported-spec; routes in code but absent from the spec = a finding (for emit-tier B frameworks this is the predictable skipped-annotation failure). Findings go in the table with category `drift`.

**Diagram vs register (never mix):** the ERD (`docs/erd.md`) stays a photograph of reality — orphaned tables/columns appear IN it. The *judgment* that they look unused is a finding in FINDINGS.md (category `orphaned-schema`), never a deletion from the diagram.

Archaeologist mode still **never auto-creates backlog tasks** and never edits source — it writes the register; the owner/client decides what becomes work.

---

## Resync (`--resync`)

After a process lapse (phases shipped without traces, spec not updated spec-first): re-baseline in one step — regenerate the ERD, rewrite the current phase's trace marker from present state, and record one line in the PRODUCT_SPEC.md header: `Process lapse resynced: <date>, <one-line what happened>`. No historical back-audit is demanded. The process must always be cheaper to RE-ENTER than to abandon.

---

## What NOT To Do

- Do NOT run open-ended "find flaws" sweeps (outside Pass 6) — enumerate and loop.
- Do NOT edit source code, configs, or tests — report only; artifacts limited to `docs/erd.md`, `docs/journey_traces/`, and (archaeologist mode) `FINDINGS.md`.
- Do NOT auto-create tasks from findings — the owner approves each one.
- Do NOT recommend dropping suspected-unused schema — flag with evidence; the owner judges.
- Do NOT hand-edit `docs/erd.md` or run guessed CLI flags — regenerate with the verified command, or stop at a `TODO: verify` tier and fall through.
- Do NOT round `undecided` to ok or flaw — uncertainty is reported as uncertainty.
- Do NOT overstate coverage — name the passes that ran and the ones that didn't.
- Do NOT run a Pass 2–5 sweep whose applicability gate is absent — record `consciously skipped — <trigger> absent`; running it anyway manufactures noise.
- Do NOT improvise hook integration — it remains a declared future stage. (Passes 1–6, archaeologist mode, and the parallel Workflow / refuter execution path ARE implemented; consumer mode is NOT.)
- Do NOT use the parallel Workflow path for `--scope=diff` or `--scope=phase` — a small scope gains nothing from fan-out; sequential is correct there.
- Do NOT mix the findings table and the undecided table in archaeologist mode — they are separate; undecided is an epistemic state, not a severity.
- Do NOT reference any file outside this skill's own directory in instructions you emit — this skill must work on any machine it travels to.

## Activation

- User invokes `/design-audit` (any scope or mode)
- /product-spec archaeologist mode calls it for ERD + unused-entity + drift findings into FINDINGS.md
- /product-spec finishes writing PRODUCT_SPEC.md (birth validation)
- /vibe-code completes a task and calls the diff-scope review
- User says "audit the design", "check code against the spec", "run the drift check"
