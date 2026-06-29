Skill: concept-unblock
Context:
Session: 2026-06-12 — Monireach received a line-by-line walkthrough of loop-stop-gate.sh (the /loop-dev Stop hook, at agent_core/agents/claude/hooks/loop-stop-gate.sh) and found it too difficult — he lacks foundational bash/shell scripting knowledge. The concept-unblock session should find the EXACT blocker first (one at a time, per protocol), starting from the simplest candidates and using the real script as the concrete example. Likely blockers, in rough dependency order:
1. Exit codes as the universal success/failure signal (0 vs non-zero; why this script's whole interface is "exit 0 = allow stop, exit 2 = block")
2. Test brackets `[ -f file ]`, `[ -n str ]`, `[ "$a" -gt 0 ]` — these are commands with exit codes, not syntax
3. `||` and `&&` chaining as if/else shorthand (`[ -f "$FLAG" ] || exit 0`)
4. Shell parameter expansion: `${VAR:-default}`
5. Command substitution: `VAR=$(command)`
6. `case` glob patterns (`''|*[!0-9]*` as "empty or contains a non-digit")
7. Arithmetic expansion: `$((COUNT + 1))`
8. Redirection: `>` truncate-write, `>&2` to stderr, and why a Stop hook writes its re-prompt to stderr
9. Heredocs: `cat >&2 <<EOF ... EOF`
10. sed basics: `sed -n '2p'` (print only line 2)
11. The awk state machine: `index($0, h) == 1 { on=1; next }` / `on && /^## /  { on=0 }` / bare `on` — extracting a section of a markdown file
12. `grep -E -c 'A|B'` — count matching lines
Teaching approach that already exists for him: concrete-first with the real script, math framing welcome (state machine, predicates), one concept per round, backwards tracing.
