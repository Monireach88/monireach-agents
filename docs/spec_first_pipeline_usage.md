# Spec-First Pipeline — Usage Guide (Modes Walkthrough)

**Purpose:** how to actually *run* the spec-first pipeline — which skill to invoke first, what file each produces, and what feeds the next. The how-to companion to the two reference docs.

**Last updated:** 2026-10-06 (file paths moved to `docs/` — see the note under §2)

**Related docs (read by intent):**
- **How do I use it?** → this file.
- **Why is it built this way? / decision history** → `spec_first_pipeline_journal.md`.
- **Full skill specs / blueprint** → `spec_first_pipeline_design.md`.
- **Behavior source of truth** → the skills themselves under `agent_core/skills/{ideation,product-spec,technical-consultant,design-audit,vibe-code}/`.

---

## Table of Contents

1. [Two working modes (and one gap)](#1-two-working-modes-and-one-gap)
2. [Mode 1 — Author (greenfield: a new project from nothing)](#2-mode-1--author-greenfield-a-new-project-from-nothing)
3. [Mode 2 — Archaeologist (documentation backfill for a finished codebase)](#3-mode-2--archaeologist-documentation-backfill-for-a-finished-codebase)
4. [Mode 3 — Consumer (NOT built)](#4-mode-3--consumer-not-built)
5. [Quick mental model](#5-quick-mental-model)

---

## 1. Two working modes (and one gap)

`/product-spec` and `/design-audit` each have three *defined* modes, but only two are implemented:

- **Author** — fully implemented. Forward direction: idea → spec → code.
- **Archaeologist** — fully implemented. Backward direction: code → spec → docs.
- **Consumer** — defined in the design doc, **deliberately not implemented**. Both skills are coded to refuse it and say so rather than improvise a partial version.

Author and Archaeologist use the same slot structure so you can compare them slot-for-slot.

---

## 2. Mode 1 — Author (greenfield: a new project from nothing)

**When:** you have an idea, no code yet. This is the main pipeline.

**The sequence — 5 skills across separate sessions, each producing one file the next consumes:**

| # | Session / command | What it does | File (input → output) |
|---|---|---|---|
| 1 | `/ideation` | AI-led CTO interview: 7 dimensions (problem, persona, market, business model, MVP scope, compliance, differentiation), sub-agent web research, iterate to saturation | idea → **docs/product-brief.md** + writes **archive/spec_skeleton.md** with every `[DERIVED]` section filled |
| 2a | `/ideation` Step 6 *(owner interview)* | The skill asks the owner one question at a time and writes only the owner's answers into the `[OWNER]` sections (pricing, product rules, out of scope). It also asks the owner to confirm every `assumed —` cell. The owner may choose to fill the sections by hand instead. | archive/spec_skeleton.md (`[OWNER]` empty) → filled |
| 2b | `/product-spec` | Reads the Brief, **does NOT read your skeleton yet**, generates its own version independently, *then* reads yours and runs a mechanical diff → you merge/resolve | docs/product-brief.md + archive/spec_skeleton.md → **docs/prd.md** |
| 2c | `/design-audit` *(auto-called by 2b)* | "Birth validation" — greenfield structural passes: every journey arrow lands on a filled cell, every entity has a creation path, Pass 6 completeness critic | docs/prd.md → in-session findings (no file) |
| 3 | `/tc` | Tech-stack decisions only (the old Phase 1 is now `/ideation`). Seeds NFRs from spec §5 | docs/product-brief.md + docs/prd.md → **docs/architecture.md** + one **docs/adr/NNNN-<title>.md** per decision |
| 4 | `/start-local-dev` | Scaffolds the repo; absorbs the Brief into PROJECT.md + README.md | → project skeleton |
| 5 | `/vibe-code` | TDD build loop; after each task's diff it calls `/design-audit --scope=diff` | backlog tasks → code + tests |

**The whole point of the split:** ideation is AI-led (recognition is fine for business strategy). The skeleton is co-authored. `/ideation` fills the `[DERIVED]` sections (actors, entities, CRUD, journeys) from the brief. The owner supplies the `[OWNER]` decisions (prices, product rules, scope) through the Step 6 interview: the owner gives every answer, and the skill writes only what the owner said or accepted. Missing actors and entities are caught later by three checks: `/product-spec`'s independent generation and mechanical diff, journeys that start from a stranger, and the `/design-audit` completeness pass. `/product-spec` refuses to run until the skeleton exists (unless you pass `--ai-first` with a written reason).

> **File locations (since 2026-10-06):** the brief, PRD, architecture doc and ADRs live in `docs/` and are tracked in git. Every producer skill is safe to re-run: it updates its existing file instead of regenerating it. If a project still has the old root files (`PROJECT_BRIEF.md`, `PRODUCT_SPEC.md`, `TECH_STACK.md`, `SPEC_SKELETON.md`), re-run the producer skill and it offers to migrate them.

> **Where do the Gherkin acceptance criteria come from?** Not from any document above. They're written into `current_state/project_status.md` task details **at phase planning, per phase** — all of a phase's AC together, just before you `/vibe-code` that phase. `/vibe-code` reads them (read-first), authoring one only as a fallback if missing.

---

## 3. Mode 2 — Archaeologist (documentation backfill for a finished codebase)

**When:** the code already works; you need docs — for a client handoff, audit, or portfolio writeup. You're documenting **what IS**, not designing what should be.

**The sequence — one command, two skills, governed by one law:**

```
/product-spec --mode=archaeologist
```

This routes into `archaeologist_mode.md`. **The governing law — backfill by derivability:** a doc is only backfillable to the degree it's derivable from code:

- **ERD, API contract** → fully derivable (mechanical)
- **SRS / requirements** → partially (reverse-generate, then verify)
- **BRD / the *why*** → never derivable → must interview you, or mark `[inferred — UNVERIFIED]`

**Phases and their files:**

| Phase | What runs | File produced |
|---|---|---|
| **0 — Reconnaissance** (mandatory first) | Get it running, rough-map the code, **trust-audit every existing doc** (current/stale/wrong/unverifiable), convention survey | starts **FINDINGS.md** (Reconnaissance section) |
| **1 — Backfill 8 SDLC slots** (derivability order) | Slot 4 ERD → calls `/design-audit` Pass 1; Slot 5 API contract; Slot 2 SRS reverse-generated + cited; Slot 1 BRD elicited from you; Slot 3 → **docs/architecture.md** (6 class-tagged sections); setup docs | **docs/prd.md**, **docs/architecture.md**, **docs/erd.md**, README/`.env.example`/runtime/deploy docs |
| *(inside Phase 1)* | `/design-audit --mode=archaeologist` writes its findings + undecided tables into the shared **FINDINGS.md** | FINDINGS.md (full register) |
| **2 — Coverage footer** | 8-slot table, each marked file / derivable / skipped + epistemic class | closes docs/prd.md |

**The enforcement that keeps it honest — the epistemic three-class gate** (you can't write any section without tagging it):

- **Class 1 MECHANICAL** (ERD, module map) → write freely, no marking
- **Class 2 DERIVED** (reverse-generated SRS) → `[derived — verified against <source>]`
- **Class 3 ELICITED** (the *why*) → `[owner interview]` or `[inferred — UNVERIFIED]`

The forbidden move: inferring a Class-3 rationale from code and stating it as fact ("they chose Postgres because…").

**Coverage bound (state it in FINDINGS.md, never overstate):** archaeologist findings depth is capped by which `/design-audit` passes *ran*. As of 2026-06-09 the audit carries **Pass 1** (lifecycle / ERD / orphaned-schema / drift), **Pass 6** (completeness), **setup-gaps**, **plus the conditional sweeps Pass 2 (authz/BOLA), Pass 3 (state-machine), Pass 4 (journey-failure), Pass 5 (seam)** — each fires only when its applicability gate matches the project, and records `consciously skipped — <trigger> absent` otherwise. Two honesty bounds remain: (1) a gate that didn't fire = skipped, not run clean; (2) the parallel multi-agent + refuter execution path is not yet built, so on a codebase too large to hold a seam's two sides in one session, the seam pass runs degraded. FINDINGS.md's header states all of this.

---

## 4. Mode 3 — Consumer (NOT built)

**Defined intent:** an intake checklist for when you join *someone else's* existing project as a contributor (register-only audit, no task creation).

**Status:** explicitly **not implemented**. Both skills are coded to say exactly that if asked, and not improvise a partial version. If you want it, that's a build task — it was parked alongside Stage 2 (see `spec_first_pipeline_design.md` §12).

---

## 5. Quick mental model

- **Author** = forward (idea → spec → code).
- **Archaeologist** = backward (code → spec → docs), gated by *"is this derivable, or must I ask you?"*
- **Consumer** = the gap, still empty.
