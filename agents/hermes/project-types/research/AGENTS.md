# AGENTS.md — Research Project Template

**Symlink this file into your research project root as `AGENTS.md`.**
**Customize sections marked with `<!-- CUSTOMIZE -->` for your specific project.**

**Persona rules (fact-checking, intellectual rigor, teaching style, response style)**
**are in `~/.hermes/SOUL.md` — this file covers only research-domain rules.**

---

## Project Context

<!-- CUSTOMIZE: Replace with your project's topic, venue, and goals -->
**Navigation:** Always read `./PROJECT.md` first — it's the navigation hub for this project.

## Research Style

- Follow [citation style — e.g., APA 6th, IEEE, Chicago] for all citations and references.
- <!-- CUSTOMIZE: Specify citation style above -->

## CRITICAL RULES

### No Perfectionism

- The researcher is already a perfectionist, always hesitating to start and waiting for the "perfect moment."
- Apply "Done is better than perfect" — use it to remind and challenge when you see the perfectionist trap forming.
- Push to start writing, submit drafts, and iterate rather than waiting for completeness.

### Paper vs Code Verification

- If a paper and its accompanying code disagree, do NOT assume the paper is wrong.
- Ask WHY the difference exists: intentional filtering? Strategic framing? Conceptual vs implementation gap?
- Consider the research narrative and presentation strategy before "correcting" anything.
- Get explicit user confirmation before changing claims that appear in the paper.

## Research Workflow

### Literature Review

- Search arXiv, Google Scholar, and domain-specific databases.
- For each relevant paper: capture the key claim, methodology, dataset, and how it relates to this project.
- Maintain a structured literature review document (e.g., `literature_review.md` or a BibTeX file).

### Data Collection & Analysis

- Document data sources, collection methods, and preprocessing steps.
- Keep raw data separate from processed data. Never modify raw data in place.
- Version your datasets — tag snapshots before major changes.

### Writing

- Draft in the project's writing directory (e.g., `paper/`, `manuscript/`).
- Keep figures, tables, and references in structured subdirectories.
- Before submitting: verify all citations resolve, all figures are referenced, and the reference list matches in-text citations.

## Initialization

When the user says `initialize` for this project:

1. Read `PROJECT.md`.
2. Identify the current phase: literature review, data collection, analysis, writing, or revision.
3. Review recent progress from any log files or status documents.
4. Present the next logical step based on the current phase.

## End Session

When the user says `end session`:

1. Log what was accomplished in the project's progress document.
2. Note any blockers, open questions, or next steps.
3. Update `PROJECT.md` if the project phase or structure changed.
