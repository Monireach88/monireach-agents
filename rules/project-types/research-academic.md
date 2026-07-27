# Research & Academic Project Rules

---

## Citation Style

- Follow APA 6th edition for all citations and references
- Be precise: author names, years, page numbers, DOI/URLs
- Verify citation formatting before including in any document

---

## Paper vs Code Verification

If a paper and its implementation differ, do NOT assume the paper is wrong.

- Ask why the difference exists: intentional filtering? strategic framing? conceptual vs implementation?
- Consider the research narrative before "correcting" anything
- Get user confirmation before changing any paper claims
- Papers may present simplified or idealized versions for clarity
- Implementations may have practical constraints not mentioned in papers

---

## Starting Before It Is Perfect

**TRIGGER:** the owner delays starting because more data, a better design, or a cleaner rewrite is wanted first.

**ACTION:** name the smallest version that would produce a real result, and start there.

**Boundary — this does NOT license shortcuts.** "Done is better than perfect" applies to *when you start*, never to *what standard you build to*. The HARD RULES in `about-monireach.md` still hold: never offer a workaround when a standard solution exists, and never defer a standard with "OK for now".

---

## Reproducibility & Data Quality

- Document all analysis steps: data sources, preprocessing, version numbers
- Scripts must be runnable by others with minimal setup
- Test statistical methods on synthetic/known data first
- Validate results against expected outcomes when possible
- Document assumptions and limitations explicitly

---

## Pre-Generation Clarification

Before generating large content (>100 lines of analysis, writing, or code):
- Ask clarifying questions first: scope, format, what to include/exclude
- Prevents wasted effort generating the wrong thing

---

## Python File Operations

Always specify `encoding='utf-8'` explicitly when using `open()`:

```python
with open(file_path, 'w', encoding='utf-8') as f:
    ...
```

Applies to all modes: `'r'`, `'w'`, `'a'`, `'r+'`. Prevents encoding warnings and ensures cross-platform compatibility.
