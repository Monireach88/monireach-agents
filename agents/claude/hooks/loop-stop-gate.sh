#!/bin/sh
# loop-stop-gate.sh — Stop hook for /loop-dev.
# If a loop is active and incomplete tasks remain in the target section of
# project_status.md, block the stop and re-inject the loop instruction.
# POSIX-only. Fail-open: any unexpected state allows the stop (exit 0) —
# the skill's own checks are the backup; a hook must never trap a session.
#
# Flag file format (current_state/.loop_active):
#   line 1 = exact text of the target section heading (written by /loop-dev)
#   line 2 = block counter (written by this script; absent on a fresh flag)
#
# Global cap: after MAX_BLOCKS blocked stop attempts, the gate disarms
# (allows stops, with a loud warning) so a stuck loop can never trap a
# session indefinitely. The flag is left in place so the next /loop-dev
# Phase 0 sees the stale state and asks the owner to resume or delete.

MAX_BLOCKS=30

PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
FLAG="$PROJ/current_state/.loop_active"
STATUS="$PROJ/current_state/project_status.md"

# No active loop, or no status file -> normal stop.
[ -f "$FLAG" ] || exit 0
[ -f "$STATUS" ] || exit 0

HEADING=$(head -n 1 "$FLAG")
[ -n "$HEADING" ] || exit 0

# Read the block counter (line 2); default to 0 when absent or non-numeric.
COUNT=$(sed -n '2p' "$FLAG")
case "$COUNT" in
  ''|*[!0-9]*) COUNT=0 ;;
esac

# Count incomplete markers from the heading line to the next same-level
# heading (## ) or EOF. Counts absence of incomplete work, NOT presence of
# completed work — completed tasks may be archived to milestone.md (§2.6).
REMAIN=$(awk -v h="$HEADING" '
  index($0, h) == 1 { on = 1; next }
  on && /^## /      { on = 0 }
  on
' "$STATUS" | grep -E -c '🔲|🔄')

if [ "${REMAIN:-0}" -gt 0 ]; then
  if [ "$COUNT" -ge "$MAX_BLOCKS" ]; then
    # Global cap reached: the loop is stuck. Disarm — allow the stop, warn loudly.
    echo "loop-stop-gate: global cap reached ($COUNT blocked stops) with $REMAIN task(s) still incomplete under \"$HEADING\". The loop appears stuck — allowing the stop. The flag file current_state/.loop_active was kept; the next /loop-dev run will surface it as a stale loop to resume or delete." >&2
    exit 0
  fi

  COUNT=$((COUNT + 1))
  printf '%s\n%s\n' "$HEADING" "$COUNT" > "$FLAG"

  cat >&2 <<EOF
loop-dev active: $REMAIN incomplete task(s) remain under "$HEADING" in current_state/project_status.md. [stop-block $COUNT/$MAX_BLOCKS]
Continue the loop: pick the next 🔲 task and run it through the /loop-dev pipeline (implement -> adversarial-verifier -> merge -> status update).
If every remaining task is genuinely blocked (3 failed verifier rounds or a missing external dependency), document each blocker in its task detail section, then delete current_state/.loop_active and stop.
EOF
  exit 2
fi

# Target section is clear -> loop is done; remove the flag and allow the stop.
rm -f "$FLAG"
exit 0
