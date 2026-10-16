#!/usr/bin/env bash
# settings-link-check.sh — SessionStart hook, on the laptop and the server.
# Keeps ~/.claude/settings.json a link to agent_core/agents/claude/settings.json (one source of truth).
# If a program replaced the link with a real file, that file is kept as a dated backup in
# ~/.claude/backups/ and the link is put back.
here="$(dirname "$(readlink -f "$0")")"          # .../agent_core/agents/claude/hooks
src="$(cd "$here/.." && pwd)/settings.json"
dst="$HOME/.claude/settings.json"
[ -f "$src" ] || exit 0
[ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ] && exit 0
if [ -e "$dst" ] && [ ! -L "$dst" ]; then
  mkdir -p "$HOME/.claude/backups"
  mv "$dst" "$HOME/.claude/backups/settings.json.$(date +%Y%m%d-%H%M%S)"
fi
ln -sfn "$src" "$dst"
echo "settings.json was not a link to agent_core: link restored, the old file is in ~/.claude/backups/" >&2
exit 0
