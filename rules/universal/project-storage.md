# Project Storage: Private Files Live in Google Drive

Trigger: you create, move, track or gitignore a project file, or scaffold a new project.
`<Drive>` = `/Users/monireach/Google Drive/My Drive/monireach`. `<project>` = the repo folder name.

| Repo path | Real location |
|---|---|
| `archive/` | `<Drive>/_project_archive/<project>/` |
| `current_state/` | `<Drive>/_project_current_state/<project>/` |
| `CLAUDE.md`, `AGENTS.md`, `PROJECT.md`, `.env`, `.env.*` (never `.env.example`), any other private file | `<Drive>/_project_root/<project>/<same relative path>` |

- The repo holds a symlink to each private path, and every symlink is listed in `.gitignore` with no trailing slash (`/archive`, not `archive/`), because git sees a symlink as a file.
- Public and always in git: README.md, docs/, .env.example, source code, tests.
- Anything else becomes private only when he says so. Recommend using this test: "Would a teammate who clones the repo need this file?" Yes means git; no means it may be private.

## No file is local only
He works from the MacBook and from the server. A project must rebuild on a new machine from git clone, the Drive links and a dependency install. So every file is exactly one of: tracked and pushed; a symlink into Drive (or inside a linked folder); or regenerable (dependencies, caches, build output, logs).
Check with `"$AGENT_CORE_DIR/skills/end-session/local-only-check.sh" <project>` (exit 0 = safe). Anything else is a defect. Propose one action per file (commit, move to Drive, add to .gitignore under a `# regenerable: <command>` comment, or delete) and ask once for the whole list.

## Making a file private
1. If the Drive target already exists, stop and ask. Never overwrite either copy.
2. Move the real file or folder into Drive: `mv <path> "<Drive>/_project_root/<project>/<path>"`.
3. Link it back: `ln -s "<Drive>/_project_root/<project>/<path>" <path>`.
4. If it was tracked, run `git rm --cached -r --ignore-unmatch <path>`. Then add `/<path>` to .gitignore.
Moving, untracking and deleting need his yes (user-confirmation §6.2).

## Superseded versions
When a new dated version of a deliverable replaces an old one, move the old one to `archive/superseded/<deliverable>/<date of that version>/`. Keep only the newest version plus files still in use, and update any README that names them. If the deliverable is attached to a ClickUp task, follow clickup-sync §2.10. This removes tracked files, so it needs his yes.
