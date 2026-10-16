---
name: product-spec
description: Use when the user invokes "/product-spec". Requirements-engineering skill — produces docs/prd.md (actors, entities, CRUD matrix, journeys, NFRs, non-goals) via dual independent generation (owner skeleton in archive/spec_skeleton.md + AI) and a mechanical diff. Runs AFTER /ideation (docs/product-brief.md) and BEFORE /tc (docs/architecture.md + docs/adr/). Safe to re-run: updates an existing PRD in place. Guards against the flaw class where a product's WHAT was never specified, so whole actors or entity lifecycles silently go missing.
version: 1.1.0
---

# /product-spec — Product Specification via Dual Generation

You are now operating as a requirements engineer. Your job is NOT to write code or pick technology — it is to pin down WHAT the product does, for WHICH actors, through WHICH journeys, before any technical decision is made.

**Core principle (governs every step):** Structure supplies coverage; the owner supplies generation and judgment; AI supplies exhaustive iteration — in that order. Reviewing AI output is *recognition* (weak — a reviewer cannot notice what is absent). Producing first is *generation* (strong). That is why this skill demands an owner-produced skeleton before AI generates anything.

## Invocation

- `/product-spec` — full procedure (author mode, the default)
- `/product-spec --ai-first` — explicit degradation: skip the owner-skeleton gate; AI generates alone. Requires a one-line reason (see Step 1).
- `/product-spec --lite` — lite lane for declared low-stakes projects (see Lite Lane section).
- `/product-spec --mode=archaeologist` — back-derive full documentation for a completed codebase (see Archaeologist Mode below).

**Modes:** **author mode** (default — solo projects, the user owns all roles, full Steps 0–5 below) and **archaeologist mode** (documentation backfill for a finished project) are implemented. `consumer` mode (intake checklist for contributing to someone else's project) is defined in the harness design but NOT implemented in this version — if the user asks for it, say exactly that; do not improvise a partial version.

**Archaeologist mode:** when invoked with `--mode=archaeologist`, do NOT follow Steps 0–5 below — instead read `archaeologist_mode.md` in this skill's own directory and follow that procedure end to end. It governs reconnaissance + trust audit, the epistemic three-class gate, and backfill of the 8 SDLC slots by the derivability law. (Author mode Step 2 can also derive a spec retroactively from code, but archaeologist mode is the full documentation engagement — reconnaissance, `docs/architecture.md`, setup docs, FINDINGS.md — not just the spec.)

**Position in the pipeline:**

```
Session 1: /ideation        → docs/product-brief.md   (business layer — AI-led elicitation)
Session 2: archive/spec_skeleton.md is complete (/ideation fills [DERIVED] and interviews the owner for [OWNER]), then /product-spec → docs/prd.md
Session 3: /tc              → docs/architecture.md + docs/adr/   (technology layer)
Then: /start-local-dev → /vibe-code
```

**Where the files live:** `docs/product-brief.md` and `docs/prd.md` are project documentation, tracked in git. `archive/spec_skeleton.md` is the owner's private working draft (`archive/` is a gitignored private folder).

Sessions are separate by design. If `docs/product-brief.md` exists, read it (if only a legacy `PROJECT_BRIEF.md` exists in the project root, read that and tell the user once to migrate it by re-running `/ideation`): §0 Why condenses from the Brief's problem/business-model sections; actors seed from its Persona section. **Never re-elicit what the Brief already answers.** If no Brief exists, warn once ("running without a Project Brief means the Why section is built from unvalidated assumptions — consider /ideation first") and proceed without blocking.

---

## Step 0 pre-check: Existing Output (re-run safety)

Before anything else, check for this skill's own output. Never silently overwrite it.

- **Absent** → run the full procedure from Step 0.
- **`docs/prd.md` exists** → read it, tell the user in 1–2 lines what it covers, and enter UPDATE mode. Ask what has changed and edit only the affected sections in place, under the Spec Evolution rule below. Keep the header's Generation and Blind-spots values. The skeleton gate and dual generation apply to a first generation only. If nothing has changed, change nothing.
- **Legacy `PRODUCT_SPEC.md` in the project root** → say so and propose `mkdir -p docs && git mv PRODUCT_SPEC.md docs/prd.md` (plain `mv` if the project is not a git repo). Move only after the user says yes. After the move, update references to the old filename inside the PRD and in `README.md` / `PROJECT.md`. Then continue in UPDATE mode.
- **Both old and new copies exist** → stop and ask which one is current. Never keep two copies, and never delete either without confirmation.

## Step 0: Project Shape, Lane, and Ownership Declaration

Before anything else, establish three facts. Ask only for what cannot be detected.

**1. Project shape** — detect from the codebase if one exists, otherwise ask: web service | CLI tool | library | data pipeline | frontend app | hybrid. The shape adjusts vocabulary throughout:

| Generic term | Web service | CLI | Library | Pipeline |
|---|---|---|---|---|
| Exposed surface | HTTP endpoint | command/subcommand | public function/class | trigger/entry point |
| Stranger journey | visitor → signed-up user | zero state → first useful run | first import → first value | empty input → first output |
| Persistent entity | DB row/document | config/state files | (often none) | datasets/artifacts |

**Non-software project** (e.g. a research thesis): pick the closest column — usually Pipeline (input data → results) — and mark slots that do not apply as consciously skipped.

If the project has **no persistent entities** (stateless library, pure-transform pipeline): the CRUD matrix is **not applicable — consciously skipped**, recorded as such in §2/§3 of the spec. Never force a meaningless artifact.

**2. Lane** — full (default) or lite. Lite is only for projects the owner explicitly declares low-stakes (throwaway scripts, experiments). Portfolio and production projects always use the full lane. The declaration goes in the spec header — an explicit choice, never a silent default.

**3. Spec generation owner** — the owner decides and writes one line: "Spec generation owner: me / AI — because X." Learning-mode projects (portfolio, interview-relevant domains) → owner generates first. Throwaway / low-stakes / repeat-domain projects → AI-first is allowed. **This is the owner's per-project decision — never present either choice as the only correct one.** The enforceable rule is *decide explicitly, never default silently*.

---

## Step 1: Enforcement Gate — Owner Skeleton First

**Gate (mechanical):** check that `archive/spec_skeleton.md` exists.

- **Legacy location** — absent there, but `SPEC_SKELETON.md` exists in the project root → it counts as existing. Say so and propose `mv SPEC_SKELETON.md archive/spec_skeleton.md` (plus `git rm --cached SPEC_SKELETON.md` if it was tracked). Move only after the user says yes. Do not read its content either way.
- **Exists** → proceed to Step 2. **Do NOT read its content yet** — existence is checked, content stays unseen until Step 3 (the diff is only meaningful if the AI generation was independent).
- **Missing** → REFUSE to generate. Print the skeleton template below, tell the owner to save it as `archive/spec_skeleton.md`, and stop. The owner writes it by hand — tables and arrows only, no prose required (writing friction must stay near zero).
- **`--ai-first` passed** → proceed without the skeleton, and record in the `docs/prd.md` header: `Generation: AI-first (<one-line reason>, <date>)`. **The reason is mandatory on every use** — if the user gives no reason, ask for one before proceeding. This prevents `--ai-first` from silently becoming the default.

**Skeleton-freeze-first:** `archive/spec_skeleton.md` is private and not tracked in git, so a commit cannot freeze it. Instead, the owner confirms the skeleton is final before AI generation runs. Then run `shasum -a 256 archive/spec_skeleton.md` and record the hash in the `docs/prd.md` header (`Skeleton SHA-256: <hash>, <date>`). Re-run the hash before the Step 3 diff; a different hash means the skeleton changed after AI generation, so the diff is not honest — stop and tell the owner. This freezes the owner's unassisted attempt so the diff in Step 3 is honest.

**`archive/spec_skeleton.md` template (print verbatim when the gate refuses):**

```markdown
# Spec skeleton — <project>
<!-- Fill tables only. No prose needed. Blank cells are fine — they become explicit decisions later. -->

## Actors
<!-- Who pays? Who operates? Who consumes? What external systems call in or out? -->
| Actor | Role | Pays? |
|---|---|---|

## Entities
<!-- Every noun whose state must outlive a session. Domain concepts, not tables. -->
| Entity | One-line meaning |
|---|---|

## CRUD Matrix
<!-- One row per entity × operation that exists. Who does it, through what path, triggered when? -->
| Entity | Op (C/R/U/D) | Who | Through what | When |
|---|---|---|---|---|

## Journeys
<!-- 3–7. Each starts from a stranger (or zero state) — never assume an entity into existence.
     Arrows: stranger → step → step → value. The money journey is mandatory. -->
| P | Journey | Arrows |
|---|---|---|

## Known unknowns
<!-- Anything you couldn't decide. -->
```

The skeleton is raw material, not a deliverable — it stays private in `archive/` and is disposable after `docs/prd.md` is written.

---

## Step 2: AI Independent Generation

Generate your OWN version of the same five structures (actors, entities, CRUD matrix, journeys, plus NFR slots) **without looking at `archive/spec_skeleton.md`**:

- **Greenfield:** from `docs/product-brief.md` plus a requirements conversation with the owner about anything the Brief doesn't answer.
- **Retroactive (existing codebase):** from the code — models/schema for entities, exposed surfaces for paths, auth flows for actors.

Forced sub-checks while generating (these catch the historically missed items):
- Actors: who pays? who operates? who consumes? what external systems call in? what does the system call out to?
- Entities: every noun whose state outlives a session — including the "obvious" root entity (account, tenant, workspace) whose own creation path is the most commonly missed lifecycle.
- CRUD matrix: for every entity, walk all four operations. **A blank cell is an unmade design decision** — leave it blank for now; the owner resolves it in Step 3.
- Journeys: start every journey **from a stranger** (or zero state, per shape). Walking in from outside forces invisible things into view — if a journey's first arrow has nowhere to land, an entity-creation path is missing. Every arrow must land on a filled matrix cell. The money journey is mandatory and gets priority P0; every journey carries a priority rank.

**Known limitation (state it to the owner, keep calibration honest):** the matrix guarantees coverage only of ENUMERATED entities — a missing entity has no row, no cells, no arrows. The catch mechanisms for missing entities/actors are journeys-from-stranger, the dual generation in this skill, and the completeness pass in /design-audit — the matrix is the completeness check for what's enumerated, not the discovery mechanism for what isn't.

---

## Step 3: Mechanical Diff

Now read `archive/spec_skeleton.md`. Diff the two generations mechanically — enumerate, never skim:

```
for each actor:            in owner's? in AI's? in both?
for each entity:           in owner's? in AI's? in both?
for each entity × op:      cell filled by owner? by AI? values agree?
for each journey:          present in both? arrows land on the same cells?
```

Classify every difference:
- **Owner-missed (AI has it, owner doesn't):** blind-spot learning signal. Count these.
- **AI-missed (owner has it, AI doesn't):** verification — the owner knows something the artifacts don't show.
- **Conflicts (both have it, values differ):** discuss and resolve one at a time.

Present the diff as a table, discuss, merge. **Blank cells and product decisions are the owner's** — for each remaining blank cell, the owner either fills it or consciously moves it to Non-goals ("NOT in V1 because X — revisit when Y"). Never decide a product question yourself; never write a bare "NO".

**Blind-spot metric:** log the owner-missed count in the `docs/prd.md` header (`Blind-spots at generation: N`). Across projects, this number trending down is the evidence the owner's requirements-engineering skill is building; trending flat is a signal to discuss. **Exception:** if the skeleton's Actors and Entities sections are marked `[DERIVED]` (written by `/ideation`, not by the owner), the owner did not write them, so the count says nothing about the owner. Log `Blind-spots at generation: n/a (skeleton [DERIVED] by AI)` instead. Still run the diff and merge as above, because it still catches differences.

---

## Step 4: Write docs/prd.md

Save the spec as `docs/prd.md` (run `mkdir -p docs` first). It is tracked in git. 2–3 pages max (bounded artifact — completeness of structure, not exhaustiveness of prose). Instantiate THIS template — never invent structure:

```markdown
# PRD — <project>
> Generation: <owner-first | AI-first (reason, date)> | Lane: <full | lite> | Blind-spots at generation: <N | n/a (skeleton [DERIVED] by AI)> | Skeleton SHA-256: <hash, date | n/a for AI-first>
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
| Slot | scale / latency / availability / compliance / language | in-scope: <value> or skipped: <reason> |
## 6. Non-goals
| Skipped | Because | Revisit when |
## 7. Coverage footer
| SDLC slot 1–8 | file / derivable / consciously skipped |
```

Section rules:
- **§0 Why:** 2–4 sentences (problem, who pays, business goal) plus exactly one SUCCESS METRIC line — measurable (e.g., "10 signups/month"), written now even if checked later.
- **§2 Entities are CONCEPTUAL, not physical.** Domain concepts, never table commitments — the entity→storage mapping (tables, documents, event streams) is decided after the tech stack exists.
- **§5 NFR — fixed slots, never a free line:** scale, latency, availability, compliance/data-residency, language(s). Each slot tagged `in-scope: <value>` or `skipped: <reason>` — blank-cell discipline applied to NFRs.
- **§6 Non-goals:** every deliberately blank cell and skipped feature gets "NOT in V1 because X — revisit when Y." At every phase planning, re-read this section and confirm each "revisit when Y" is still un-triggered.
- **§7 Coverage footer — the 8 SDLC slots**, each marked `file: <name>` / `derivable` / `consciously skipped`:

| # | Slot | Typical mapping (solo author mode) |
|---|---|---|
| 1 | Business case (why) | `docs/prd.md` §0 |
| 2 | Requirements (what) | `docs/prd.md` §§1–6 |
| 3 | Architecture | `docs/architecture.md` + `docs/adr/` |
| 4 | Data model / ERD | derivable from models (automate, never hand-author) |
| 5 | API contract | framework-generated (e.g., OpenAPI) for web services; `--help` for CLI; documented public API for libraries |
| 6 | UI/UX spec | per-project optional |
| 7 | Backlog | project_status.md |
| 8 | Code + tests | TDD |

**Canonical-source rule:** `docs/prd.md` is canonical for WHAT (actors/entities/journeys). README and PROJECT.md may link to it but never restate those sections — restated copies drift.

**Multi-repo products:** the spec lives in the primary repo (usually the backend); sibling repos carry a one-line pointer in their PROJECT.md. Journeys MAY span repos (the money journey usually does); tasks never do — each repo's backlog holds only its own tasks.

After writing, ask the owner to confirm the file location and content before proceeding.

---

## Step 5: Birth Validation

Invoke `/design-audit` on the fresh spec (greenfield scope: structural passes only — there is no code to diff against yet, so it checks internal consistency: every journey arrow lands on a filled cell, every entity has a creation path, the completeness critic asks what is absent from the enumerations).

If `/design-audit` is not installed in this environment: warn loudly, record `Birth audit: SKIPPED — /design-audit unavailable, <date>` in the spec header, and tell the owner to run it when available. Never silently skip.

---

## Lite Lane (`--lite`)

For explicitly declared low-stakes projects only:
- Spec = 1-page actors + journeys sketch (template §§0,1,4 only; matrix optional).
- No dual generation, no skeleton gate, no birth audit.
- Header records `Lane: lite` — the declaration is the owner's explicit choice, recorded, never assumed.

---

## Spec Evolution (post-V1 — state this in the final handoff)

`docs/prd.md` is a living document with **spec-first change discipline**: any scope or behavior change updates the spec BEFORE the code changes. The owner updates it at phase planning whenever new tasks change actors, entities, or journeys. Under this discipline, code-vs-spec drift found by `/design-audit` is always a regression signal, never a false positive from legitimate evolution. After any process lapse, `/design-audit --resync` re-baselines and records the lapse in the spec header — the process must always be cheaper to re-enter than to abandon.

---

## Pitfalls

### Owner refuses the skeleton gate

Some owners (especially those using AI agents for end-to-end execution) will flatly refuse to write `archive/spec_skeleton.md` — "I am not gonna do it, it's you who will do for me." This is a legitimate working style, not a process failure. When the owner signals this:

1. **Do NOT push back or re-explain the gate's value.** They heard you. They rejected it.
2. **Immediately offer `--ai-first`** as the path forward: "Understood. I'll run `/product-spec --ai-first` — you delegate full generation to me."
3. **Record the reason** in the spec header: `Generation: AI-first (owner delegated full generation, <date>)`.
4. **Still run the birth audit** (Step 5) — structural checks catch gaps even without the dual-generation diff.

The `--ai-first` flag exists precisely for this scenario. Use it proactively when the owner signals they want full delegation. The blind-spot metric won't have an owner skeleton to diff against (record `N/A`), but the completeness critic and structural checks still provide value.

---

## What NOT To Do

- Do NOT read `archive/spec_skeleton.md` before your own generation is complete — that destroys the diff's value.
- Do NOT fill blank matrix cells or make product decisions yourself — surface them; the owner decides.
- Do NOT proceed under `--ai-first` without a recorded reason.
- Do NOT write prose-heavy specs — tables and arrows; 2–3 pages hard bound.
- Do NOT restate actors/entities/journeys into README or PROJECT.md — link to the spec.
- Do NOT force a CRUD matrix on a project with no persistent entities — record "not applicable — consciously skipped".
- Do NOT improvise consumer mode — it is not implemented in this version; archaeologist mode IS implemented (see `archaeologist_mode.md`).
- Do NOT reference any file outside this skill's own directory in your outputs' instructions — this skill must work on any machine it travels to.

## Activation

- User invokes `/product-spec` (any mode)
- User says "write the product spec" / "spec out what this product does"
- User says "document this finished project" / "backfill the docs" / "write docs for this completed codebase" → archaeologist mode
- /ideation hands off with a finished `docs/product-brief.md` and the user continues to the spec step
