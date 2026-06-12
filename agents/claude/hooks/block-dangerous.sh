#!/bin/bash
# Block dangerous shell commands before Claude executes them.
# Receives tool input as JSON on stdin; exits 2 to deny.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command') or d.get('command') or '')
except:
    print('')
" 2>/dev/null)

# sudo — any escalation
if echo "$COMMAND" | grep -qE '(^|\s)sudo\s'; then
    echo "Blocked: sudo commands require explicit user approval outside Claude."
    exit 2
fi

# rm with -r/-rf on broad or root paths
if echo "$COMMAND" | grep -qE 'rm\s.*-[a-zA-Z]*r[a-zA-Z]*\s.*(\/\s*$|~\s*$|\$HOME\s*$|\*\s*$)'; then
    echo "Blocked: recursive delete on broad path requires explicit user approval."
    exit 2
fi

exit 0
