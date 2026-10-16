# CLAUDE.md — Khmer AI Model (kh_ai_model)

## Project Type
`coding`

---

## Design Philosophy

This project has two simultaneous goals: **producing a genuinely natural-sounding Khmer conversational model, and building AI-Engineering career value.** The deliverable is not the weights — it is the end-to-end system (data pipeline → tuned model → evaluation harness → served chatbot). Every phase must leave behind an artifact that survives without the model.

| Type | Rule |
|---|---|
| Empirical check that replaces an assumption (tokenizer fertility, eval baseline) | Do it now — always. An assumed base model is a silent cost multiplier. |
| Runtime dependency (serving stack, eval harness, experiment tracking) | Do it IF: adds learning/career value AND cost is bounded (days not weeks) AND complexity is recoverable |
| Pre-training from scratch, own continued pre-training, multi-week integrations | Out of scope — the blueprint's core decision. Revisit only if evaluation proves the tuned base cannot reach the naturalness target. |

Never say "NO" when you mean "Not now — when X happens, do Y." State the condition explicitly.

---

## Session Initialization

Follow `session-management.md §9.1`. Also read on demand:
- `docs/KHMER_LLM_BLUEPRINT.md` — the decided 6-phase execution plan (Hybrid path). The **anchor doc** for any question about what to build next or why.
- `current_state/milestone.md` — full details on completed tasks
- `archive/20260725_research_concepts.md` — concept-learning notes (one concept per section, appended as each is understood)
- `archive/20260725_research_with_gemini.md` — the original research draft the blueprint refines

Rule: verify in `project_status.md` before assuming something is built.

---

## Concept-Learning Track

This repo carries a **teaching track alongside the execution track.** Concepts behind the blueprint are taught one at a time, and each is appended to `archive/20260725_research_concepts.md` only after the owner confirms understanding.

- Never teach ahead — one concept per turn, then stop and wait.
- Never mark a concept ✅ in `project_status.md` from a plausible-sounding response. It is ✅ only when the owner says it landed.
- Numbers written into the concept notes must be derived, not illustrative. If a value cannot be derived, say so in the note rather than inventing a figure.

---

## Domain Rules (non-obvious, cost the project if broken)

- **Base model is chosen empirically, never assumed.** Tokenizer fertility (tokens per Khmer word) is measured in Phase 0 before any training decision. Any claim that a base is "good for Khmer" without a fertility number is unverified.
- **Never machine-translate an English instruction dataset into Khmer.** That manufactures the exact translation-syntax stiffness the project exists to remove.
- **Training data is rewritten by a native speaker, not generated.** The pipeline stores `(prompt, stiff, native)` triples so one labeling pass feeds both supervised fine-tuning and preference pairs.
- **Replay data is mandatory.** 10–15% general reasoning data mixed into the fine-tuning set, to prevent catastrophic forgetting.
- **Evaluation is native-human-rated first**, LLM-as-judge second. A benchmark score with no native rating behind it is not evidence of naturalness.
- **Named collaborators:** refer to the native-speaker reviewer by role in any committed file. Personal names belong only in private notes.

---

## End Session

Follow `logging-workflow.md §2.5`. Additionally:
- Update `current_state/project_status.md` (symbol rule, milestone.md archival, grep for task name)
- Update `PROJECT.md` only if structure/stack/architecture changed
- Append newly-taught concepts to `archive/20260725_research_concepts.md` and update its Table of Contents

## Doc Sync Rule

| Changed in `project_status.md` | Sync target |
|---|---|
| Task completed | `current_state/milestone.md` |
| Phase scope, method, or cost changed | `docs/KHMER_LLM_BLUEPRINT.md` |
| Concept taught and confirmed | `archive/20260725_research_concepts.md` (+ its ToC) |
| Features, API, tech stack, roadmap | `README.md` |
| Deployment, env vars | `DOCKER_SETUP.md` |
| Base model, dataset, or eval result changed | model card section of `README.md` |

---

## Testing

Run with:
```
uv run pytest tests/ -v
```

Current suite: `tests/test_chat_contract.py` — covers the `/chat` endpoint's request/response contract (`experiments/phase4_vertex/app.py`). Mocks `call_gemma` and the Firestore client, so no real GCP/Vertex AI call happens.

Notebook and training runs are **not** tests. A phase is done when its acceptance criteria in `project_status.md` are met, not when a notebook runs without error.
