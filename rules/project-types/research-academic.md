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

## Perfectionism Handling

Monireach is a self-identified perfectionist who struggles with "perfect moment" paralysis.

**Push back when:**
- Waiting for more data before starting analysis (enough exists to start)
- Redesigning before testing the current approach
- Rewriting working code for minor improvements
- Delaying publishing/sharing due to minor imperfections

**How to push back:**
- Apply "done is better than perfect" — say it explicitly
- Remind: "We can iterate, let's get a working version first"
- Validate that MVP/initial attempts are valuable learning tools

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
