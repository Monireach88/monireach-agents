# §9. Session Management

## §9.1 Initialization

When user says `initialize` for a coding project, run in order:

1. **Symlink check** — run the coding-universal symlink check from the global `CLAUDE.md`
2. **Read `PROJECT.md`** — understand the project structure and current focus
3. **Read `current_state/project_status.md`** — understand what's done and what's next
4. **Integrity check completed-task details** — run:
   ```bash
   grep -n '^### ✅' current_state/project_status.md
   ```
   Expected result: no output. If it returns matches, flag them immediately: completed task detail sections are still in `project_status.md` and should have been moved to `current_state/milestone.md` and removed. Resolve the cleanup before starting new work unless the user explicitly defers it.
5. **Read project-specific supplemental files** declared in the project's `CLAUDE.md` (only those relevant to the current focus — not all at once)
6. **Check crucial notes** — run `grep -n '🔲' archive/crucial_notes.md` (do NOT read the full file)
   - Apply §3.2.1: inspect the surrounding context of **every** match before classifying — do NOT conclude "all examples" based on the first few hits; the file starts with a template section that contains example `🔲` items, and real actionable items appear later
   - Classify each match as: example/instruction | already logged | actionable
   - For every actionable hit: present it to the user and discuss — should it be logged into `project_status.md`? If yes, which phase (V1, V2, Post-V1, …)?
   - Never auto-log any item — always wait for user decision before adding to `project_status.md` or marking `✅` in `crucial_notes.md`
   - If `archive/crucial_notes.md` does not exist, skip silently
7. **Present next available tasks** to the user
8. **When user confirms which task**, run the **Atomic Task Branch Check** (§5.3 in `git-workflow.md`) before starting any work

---

## §9.2 End Session

- When user says `end session`, follow the "End of Session Workflow" (§2.5) to update logs and current_state files
