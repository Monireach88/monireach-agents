---
name: humanize-writing
description: >
  Humanizes academic writing to read as authentic human scholarly prose.
  Trigger with /humanize-writing, or natural phrases like "humanize this text",
  "make this sound more human", "edit my manuscript to avoid AI detection",
  "write this section from scratch", "draft this section", "rewrite this passage".
---

# Skill: Humanize Writing

## Purpose

Produce or edit academic prose so it reads as authentic human scholarly writing — competent, rigorous, naturally imperfect — not over-polished AI output.

---

## Step 1: Determine Mode

| Scenario | Mode |
|----------|------|
| User provides file path or raw existing text | **Edit mode** |
| User provides topic, outline, or brief with no existing text | **Create mode** |

**Format detection (no asking unless genuinely ambiguous):**
- `.tex` file or LaTeX syntax → treat as LaTeX
- `.md` or Markdown syntax → treat as Markdown
- Plain block of text → treat as plain prose

If user provides a file path → read the file first before doing anything.

---

## Step 2 (Edit Mode): Scan for AI-Like Patterns

Before editing, identify which of these are present:

- **Uniform sentence length** — no rhythm variation, every sentence ~same length
- **Overly symmetrical paragraph structure** — perfectly balanced topic → support → conclusion in every paragraph
- **Excessive hedging** — "it is important to note that", "it should be noted", "it is worth mentioning"
- **Formulaic transitions** — "Furthermore,", "Moreover,", "In addition," used repeatedly
- **Perfectly parallel lists** where flowing prose would be more natural
- **Zero passive voice** — too clean; humans use some passive naturally
- **Meta-commentary on structure** — "This paper aims to…", "This section will discuss…"
- **Grandiose claim immediately hedged** — "X is transformative — however, more research is needed"
- **Uniform polish** — every sentence equally well-crafted, no natural variation in quality
- **Citation dumps** — multiple citations stacked at end of paragraph with no synthesis

Note which patterns are flagged. Only touch passages that exhibit these patterns.

---

## Step 3 (Edit Mode): Apply Targeted Fixes

**Only touch flagged passages. Preserve the author's existing voice in untouched sections.**

Apply these principles to flagged passages:

**Sentence construction:**
- Target 20–35 words for complex ideas; 10–15 words for emphasis points
- Front-load main claims — don't bury key points in nested clauses
- Break sentences exceeding 40 words into two
- Vary sentence length for natural rhythm — some short, some long

**Authenticity markers to introduce:**
- Allow minor grammatical quirks (preposition endings, split infinitives where natural)
- Introduce occasional clunky transition or slightly labored phrasing
- Use parenthetical clarifications mid-sentence where appropriate
- Some passive voice (not every sentence active)
- Selective hedging only on genuinely uncertain claims — not on established facts
- Slight redundancy when introducing complex concepts is fine
- Varied sentence quality — not every sentence equally polished

**What to remove:**
- "it is important to note that", "it should be noted", "it is worth mentioning"
- Repeated use of "Furthermore,", "Moreover,", "In addition,"
- Meta-commentary: "This paper aims to…", "This section will…"
- Grandiose claims hedged immediately after

**Maintain:**
- Discipline-specific terminology — do not dumb down
- Author's existing voice in untouched sections
- All citations — do not remove or move without reason
- APA 6th or whatever citation style is already in use

---

## Step 3 (Create Mode): Draft from Principles

Apply these drafting principles to generate new content:

**Paragraph structure:**
- Begin with clear topic sentence
- Develop ideas linearly — minimize backtracking
- 4–7 sentences per paragraph
- Each paragraph serves one clear purpose
- Connect paragraphs through logical flow, not forced transitions

**Vocabulary:**
- Technical terminology when it adds precision
- Define specialized terms on first use
- Avoid jargon when plain language communicates equally well
- Discipline-specific vocabulary naturally, not performatively

**Authentic voice:**
- Not every sentence equally polished — natural variation in quality
- Some passive voice
- Occasional parenthetical clarification mid-sentence
- Selective hedging on uncertain claims only
- Some imperfect transitions — not everything flows seamlessly

**Tone:**
- Professional without excessive formality
- Confident without arrogance
- Measured and thoughtful, not defensive
- Rigorous without pedantry
- Direct without unnecessary hedging

**Avoid:**
- Meta-commentary on writing process
- Pre-emptive apologies for scope or limitations
- Over-cautious hedging on established facts
- Informal colloquialisms
- Grandiose claims immediately hedged back

**Section-specific guidance:**

*Abstract:*
- Condensed representation: context → gap → contribution → method → findings → implications
- Self-contained, readable without full paper
- Minimal citations unless discipline requires
- Avoid vague promises and unexplained acronyms

*Introduction:*
- Establish context and significance
- Articulate research gap or problem clearly
- State research questions/objectives explicitly
- Preview methodology and contributions
- Build narrative arc: broad context → specific contribution

*Literature Review:*
- Synthesize thematically, not just chronologically
- Identify patterns, debates, contradictions, gaps
- Build analytical case for contribution
- Integrate citations into analytical narrative — no citation lists without synthesis

*Methodology:*
- Sufficient detail for replication
- Justify key methodological choices briefly
- Specify procedures, tools, analytical approaches
- Acknowledge limitations in dedicated subsection

*Results:*
- Present findings objectively, no interpretation
- Organize by research questions or thematic logic
- Report all relevant findings (positive and negative)
- Reserve interpretation for Discussion

*Discussion:*
- Interpret results relative to research questions
- Connect findings to existing literature
- Consider alternative explanations
- Articulate theoretical and practical implications
- Address limitations honestly without defensiveness

*Conclusion:*
- Synthesize key contributions concisely
- State theoretical and practical implications
- Suggest specific future research directions
- End with clear statement of significance
- No new information; don't repeat abstract verbatim

**Citation practices:**
- Cite all factual claims, data, and others' ideas
- Integrate citations naturally into prose flow — not dumped at paragraph end
- Place citations logically: usually at claim's end, sometimes mid-sentence for clarity
- Include units, sample sizes, relevant parameters for quantitative claims
- Reference specific tools, frameworks, versions when relevant

---

## Step 4: Quality Verification

Before returning output, run these internal checks:

**Authenticity:**
- [ ] Sentence length varied (not uniform)?
- [ ] Any AI-telltale patterns remaining (excessive hedging, formulaic transitions, perfect symmetry)?
- [ ] Some passive voice present?
- [ ] Sentence quality varies naturally — not all equally polished?
- [ ] Prose rhythm varied, not artificially uniform?
- [ ] Writing feels competent-human, not perfect-AI?

**Content:**
- [ ] All factual claims cited or justified?
- [ ] Technical terminology used accurately and consistently?
- [ ] Research questions/objectives addressed?
- [ ] Logical argumentation throughout?

**Style:**
- [ ] Clear topic sentences present?
- [ ] Coherent paragraph development?
- [ ] Transitions natural (not forced)?
- [ ] Professional, measured tone maintained?

**Citations:**
- [ ] Consistent citation format throughout?
- [ ] All claims appropriately attributed?
- [ ] Citations integrated into prose, not dumped?

---

## Step 5: Output Format

**For edits:**
- Return only the modified passages (not the full unchanged document unless it's short)
- Include a brief note per passage: what AI pattern was present, what was changed, why
- Format: modified text first, then note below it

**For create:**
- Return the full drafted section
- No meta-commentary about the writing process in the output itself

**Universal rule:** Never explain or summarize your own writing process inside the returned prose. The output is the writing — not a report about the writing.

---

## Core Philosophy

> Write authentic academic prose that communicates clearly while maintaining the natural imperfections of human scholarly writing. Competent academics produce rigorous work with minor inconsistencies — this is the standard to replicate.

The goal: effective scholarly communication, not demonstration of perfect grammar or prose. Clear enough to be understood, rigorous enough to be trusted, imperfect enough to be real.
