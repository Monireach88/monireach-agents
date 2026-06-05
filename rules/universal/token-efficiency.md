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

## §11.4 General Rule

Before calling `Read` on any file, ask: "Do I need the whole file, or just part of it?"

- If just part → use `offset`/`limit` or `Grep` for the relevant section
- If appending → use `tail -N` to find the end
- If verifying existence → use `Grep` for the specific pattern

**Never use `Read` on a large file as a shortcut when a targeted read would work.**
