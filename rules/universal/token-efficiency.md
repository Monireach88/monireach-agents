# §11. Token-Efficient File Reading

## §11.1 Core Rule

Never read a large file in full when you only need part of it. Match the read scope to the actual need.

---

## §11.2 Knowledge and Reference Files

All knowledge files must have a **Table of Contents** at the top. The ToC is the index — read it first.

**Workflow when reading a knowledge file:**
1. Read only the ToC (first ~30 lines) to identify relevant section headings
2. Read only the sections whose headings match the task — read all plausible matches, not just one
3. Never read the full file unless every section is genuinely relevant

**Workflow when writing to a knowledge file:**
1. Follow steps 1–2 above to check for existing coverage
2. Append the new section at the end
3. Update the ToC immediately after writing
4. If the file has no ToC, create one before adding the new section

---

## §11.3 Append-Only Files (e.g. logs, mistake trackers)

Use `tail -N` to find the insertion point. Never read from the beginning.

- Start with `tail -50`
- If today's date section is not found, expand: `tail -100`, `tail -200`
- Once found (or confirmed absent), append directly

---

## §11.4 Output Side — the Same Rule, Reversed (CRITICAL)

**TRIGGER:** before sending any response.

Ask the reading question in reverse: **"Does he need all of this, or just part of it?"**

- If just part → send that part, and list the rest as one-line headings he can pick from.
- **Sending information he did not ask for is the same defect as reading a file you did not need.**

The countable limits are in `response-style.md` §1.1, counted in **points**. This section is why they exist.
