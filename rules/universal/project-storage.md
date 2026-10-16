# Project Storage Convention — Private Files Live in Drive

**TRIGGER:** you create, move, restructure, track, or gitignore a project file or directory, or scaffold a new project.

Private project files live in Google Drive. The repo holds only symlinks to them, and every symlink is gitignored.

`<Drive>` = `/Users/monireach/Google Drive/My Drive/monireach`
`<project>` = the repo's directory name.

| Repo path | Real location |
|---|---|
| `current_state/` | `<Drive>/_project_current_state/<project>/` |
| `archive/` | `<Drive>/_project_archive/<project>/` |
| `CLAUDE.md`, `PROJECT.md` | `<Drive>/_project_root/<project>/<same name>` |
| any other private file | `<Drive>/_project_root/<project>/<same relative path>` (mirror the repo path) |

```
DEFAULT PRIVATE SET: current_state/, archive/, CLAUDE.md (or AGENTS.md), PROJECT.md,
  and every real env file: .env, .env.staging, .env.prod (never .env.example).
  An env file mirrors the repo path: <Drive>/_project_root/<project>/.env
Anything else becomes private ONLY when the user says so. Ask; never guess.
Public, always in git: README.md, docs/, .env.example, source code, tests.
  (docs/ = product-brief.md, prd.md, architecture.md, adr/ — documentation-structure.md §10.4.)
  (PROJECT.md is private: §10.2 requires it to link to current_state/ and archive/,
   so in a clone those links would be broken.)
```

## No file is local only

**TRIGGER:** end of any session in a project, `/start-local-dev`, or the user asks if a project is safe to leave.

The user works from the MacBook and from the server. A project must be fully rebuilt on a new machine from `git clone` + the Drive links + installing dependencies. So every file is exactly one of:

```
1. tracked in git AND pushed
2. a symlink into Drive (or inside a Drive-linked folder)
3. regenerable: dependencies, caches, build output, logs
Anything else is LOCAL-ONLY, and it is a defect.
```

**TEST:** `"$AGENT_CORE_DIR/skills/end-session/local-only-check.sh" <project>`. Exit 0 = safe. Each output line is a tag plus a path.

**ON FAIL:** propose one action for each line (tracked → commit; private → move to Drive with the block below; regenerable → add it to `.gitignore`, under a `# regenerable: <command that rebuilds it>` comment when the check does not already know the name (e.g. `/data` rebuilt by a download command); junk → ask to delete). Moving, deleting, committing and pushing still need the user's yes (`user-confirmation.md`). Ask once for the whole list, not per file.

## Classifying any other file

**TRIGGER:** a file is outside the default private set and outside the public line above.

**TEST:** "Would a teammate who clones the repo need this file to understand or change the code?"

- **Yes** → tracked in git.
- **No** (personal workflow state: status files, logs, agent instructions, personal notes, working drafts) → candidate for a Drive symlink, gitignored.

The test gives your recommendation. It does not replace the rule above: ask the user before making a new file private.

## Making a file private (one file or dir at a time)

```bash
D="<Drive>"; P="$(basename "$PWD")"
mkdir -p "$D/_project_root/$P"                       # or _project_archive / _project_current_state
mv CLAUDE.md "$D/_project_root/$P/CLAUDE.md"         # move the real content first
ln -s "$D/_project_root/$P/CLAUDE.md" CLAUDE.md      # then link it back
git rm --cached -r --ignore-unmatch CLAUDE.md        # untrack if it was tracked
echo "/CLAUDE.md" >> .gitignore
```

- **`.gitignore` patterns have NO trailing slash:** write `/archive`, not `archive/`. Git sees a symlink as a file, so `archive/` never matches it.
- If the Drive target already exists, **stop and ask** — never overwrite either copy.
- Moving, untracking and deleting still need confirmation (`user-confirmation.md` §6.2).

## Superseded versions

**TRIGGER:** a new dated version of a deliverable (a workbook, a pack, a brief) replaces an older one in the repo.

```
MOVE each old version to:
  archive/superseded/<deliverable>/<date of that version>/
  e.g. archive/superseded/qualification_pack/20261006/

KEEP in the repo: the newest version, plus every file still in use
  (scoring rules, answer keys). Update any README that names the files.
Git history keeps every old version, so the move loses nothing.
If the deliverable is also attached to a ClickUp task: clickup-sync §2.10.
```

The move removes tracked files from the repo, so it needs the user's approval (`user-confirmation.md` §6.2).

**TEST:** the repo holds exactly one version of each deliverable.

## TEST

```bash
for f in current_state archive CLAUDE.md PROJECT.md; do
  [ -L "$f" ] && echo "link ok: $f" || echo "NOT A SYMLINK: $f"
  git check-ignore -q "$f" && echo "ignored: $f" || echo "NOT IGNORED: $f"
  git ls-files --error-unmatch "$f" >/dev/null 2>&1 && echo "STILL TRACKED: $f"
done
```

**ON FAIL:** report each failing path to the user. Never "fix" a regular file by deleting it — it may be the only copy.
