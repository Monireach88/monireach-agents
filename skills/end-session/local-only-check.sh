#!/usr/bin/env bash
# local-only-check.sh [project_dir]
# Lists everything in a project that would be lost if this machine died.
# Rule: project-storage.md "No file is local only". Read-only: it changes nothing.
#
# A file is safe when it is ONE of:
#   tracked and pushed | a symlink into Google Drive | regenerable (deps, caches, build output)
# Every other file is printed with a tag. Exit 0 = nothing local-only, 1 = findings.
#
# Tags:
#   NOT-GIT        the folder has no .git
#   NO-REMOTE      the repo has no origin
#   UNPUSHED       a branch has commits that no remote has
#   NO-UPSTREAM    a branch exists only here
#   STASH          stash entries (they never leave this machine)
#   DIRTY          a tracked file is modified, or a file is untracked and not ignored
#   LOCAL-ONLY     an ignored file or folder that is not in Drive and not regenerable
#   LINK-OUTSIDE   an ignored symlink that points outside Drive
#   MISSING-LINK   a default private path holds real content but is not a Drive symlink
#
# Project-specific regenerable paths are declared in .gitignore. Every pattern line
# under a "# regenerable: <command that rebuilds them>" comment, up to the next blank
# or comment line, counts as regenerable:
#   # regenerable: uv run python -m trading_bot download
#   /data
set -u
cd "${1:-.}" || exit 2

AC="${AGENT_CORE_DIR:-}"
[ -n "$AC" ] || { echo "STOP: AGENT_CORE_DIR is not set"; exit 2; }
DRIVE="${AC%/resources/agent_core}"

# Path parts that are regenerable. Matched against every part of a path.
# settings.local.json = Claude Code's per-project "don't ask again" approvals; it recreates the file.
REGEN_RE='^(\.venv.*|venv.*|env|node_modules|\.uv-cache|\.uv|\.npm|\.pnpm-store|\.yarn|bower_components|__pycache__|\.pytest_cache|\.mypy_cache|\.ruff_cache|\.tox|\.nox|\.cache|\.parcel-cache|\.turbo|\.next|\.nuxt|\.svelte-kit|dist|build|out|target|coverage|htmlcov|\.coverage|\.ipynb_checkpoints|\.DS_Store|.*\.egg-info|.*\.py[cod]|.*\.log|logs|\.terraform|\.gradle|\.idea|\.vscode|\.worktrees|\.claude-worktrees|\.tmp|settings\.local\.json|.*\.tsbuildinfo|latexbuild|bin|\.vercel)$'

found=0
say() { echo "$1  $2"; found=1; }

is_regen() {
  local part IFS=/
  for part in $1; do [[ -n "$part" && "$part" =~ $REGEN_RE ]] && return 0; done
  is_repo_regen "$1"
}
# Paths declared regenerable in this repo's .gitignore (see the header).
REPO_REGEN=$(awk '/^# regenerable:/{on=1; next} /^[[:space:]]*$/ || /^#/{on=0} on{sub(/^\//,""); sub(/\/$/,""); print}' .gitignore 2>/dev/null)
is_repo_regen() {
  local p="${1%/}" r
  case "$p" in .husky/_|.husky/_/*) return 0;; esac   # husky rewrites it on install
  while IFS= read -r r; do [ -n "$r" ] || continue
    # Unquoted on purpose: .gitignore lines are globs (models/*.joblib).
    # shellcheck disable=SC2254
    case "$p" in $r|$r/*) return 0;; esac
  done <<< "$REPO_REGEN"
  return 1
}
in_drive() { case "$(readlink "$1")" in "$DRIVE"/*) return 0;; *) return 1;; esac; }

if [ ! -d .git ]; then
  say NOT-GIT "$(basename "$PWD") ($(find . -type f 2>/dev/null | wc -l | tr -d ' ') files)"
  exit 1
fi

# 1. Commits that live only here
git remote get-url origin >/dev/null 2>&1 || say NO-REMOTE "no origin"
git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads | while read -r b up; do
  if [ -z "$up" ]; then
    n=$(git rev-list --count "$b" --not --remotes 2>/dev/null || echo 0)
    [ "$n" -gt 0 ] && echo "NO-UPSTREAM  $b ($n commits not on any remote)"
  else
    n=$(git rev-list --count "$up..$b" 2>/dev/null || echo 0)
    [ "$n" -gt 0 ] && echo "UNPUSHED  $b ($n commits ahead of $up)"
  fi
done | grep . && found=1
s=$(git stash list 2>/dev/null | wc -l | tr -d ' '); [ "$s" -gt 0 ] && say STASH "$s entries"

# 2. Work not committed
dirty=$(git status --porcelain 2>/dev/null)
[ -n "$dirty" ] && { printf '%s\n' "$dirty" | sed 's/^/DIRTY  /'; found=1; }

# 3. The default private set must be Drive symlinks (project-storage.md).
# A path that exists nowhere is not flagged: nothing can be lost (structure is /start-local-dev's job).
P=$(basename "$PWD")
for p in current_state archive PROJECT.md CLAUDE.md AGENTS.md; do
  case "$p" in current_state) dst="$DRIVE/_project_current_state/$P";;
               archive)       dst="$DRIVE/_project_archive/$P";;
               *)             dst="$DRIVE/_project_root/$P/$p";; esac
  if [ -L "$p" ]; then in_drive "$p" || say MISSING-LINK "$p (links outside Drive)"
  elif [ -e "$p" ]; then say MISSING-LINK "$p (real file or folder; move it to Drive)"
  elif [ -e "$dst" ]; then say MISSING-LINK "$p (Drive has it; link missing)"
  fi
done

# 4. Ignored files: each must be in Drive or regenerable
git ls-files --others --ignored --exclude-standard --directory 2>/dev/null | while IFS= read -r e; do
  p="${e%/}"
  is_regen "$p" && continue
  case "$p" in current_state|current_state/*|archive|archive/*|PROJECT.md|CLAUDE.md|AGENTS.md) continue;; esac  # step 3 covers them
  if [ -L "$p" ]; then
    in_drive "$p" || echo "LINK-OUTSIDE  $p -> $(readlink "$p")"
    continue
  fi
  if [ -d "$p" ]; then
    # One line per folder: count what is neither regenerable nor a Drive symlink.
    n=0; ex=""
    while IFS= read -r f; do
      is_regen "${f#./}" && continue
      [ -L "$f" ] && in_drive "$f" && continue
      n=$((n+1)); [ -z "$ex" ] && ex="$f"
    done < <(find "$p" \( -type d \( -name node_modules -o -name '.venv*' -o -name 'venv*' -o -name __pycache__ -o -name .uv-cache -o -name .git \) -prune \) -o \( -type f -o -type l \) -print 2>/dev/null)
    [ -d "$p/.git" ] || [ -f "$p/HEAD" ] && { echo "LOCAL-ONLY  $p/ (a nested git repo)"; continue; }
    [ "$n" -gt 0 ] && echo "LOCAL-ONLY  $p/ ($n files, e.g. $ex)"
  else
    echo "LOCAL-ONLY  $p"
  fi
done | grep . && found=1

exit $found
