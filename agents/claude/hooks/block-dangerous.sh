#!/bin/bash
# Block dangerous shell commands before Claude executes them.
# Receives tool input as JSON on stdin; exits 2 to deny (the message on stderr goes back to Claude).
#
# Heredoc bodies are removed before matching: they are data (file content, a Python
# script), not commands, so a "sudo" quoted inside one must not block the call.

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | python3 -c "
import sys, json, re
try:
    d = json.load(sys.stdin)
    cmd = d.get('tool_input', {}).get('command') or d.get('command') or ''
except Exception:
    cmd = ''
out, end = [], None
for line in cmd.split('\n'):
    if end is not None:
        if line.strip() == end:
            end = None
        continue
    out.append(line)
    m = re.search(r'<<-?\s*[\'\"]?(\w+)[\'\"]?', line)
    if m:
        end = m.group(1)
print('\n'.join(out))
" 2>/dev/null)

# sudo in command position: line start, after ; & | ( \$( backtick, or opening a quoted
# script such as sh -c 'sudo ...'. Not when it is only a word inside other text.
if printf '%s\n' "$COMMAND" | grep -qE "(^|[;&|(\`'\"]|\\$\\()[[:space:]]*sudo[[:space:]]"; then
    echo "Blocked: sudo commands require explicit user approval outside Claude." >&2
    exit 2
fi

# rm with -r/-rf on broad or root paths: /, ~, $HOME, *, ./*, /* (not build/ or dir/*)
if printf '%s\n' "$COMMAND" | grep -qE 'rm\s.*-[a-zA-Z]*r[a-zA-Z]*\s(.*\s)?(/|~/?|\$HOME/?|\*|\./\*|/\*)\s*$'; then
    echo "Blocked: recursive delete on broad path requires explicit user approval." >&2
    exit 2
fi

exit 0
