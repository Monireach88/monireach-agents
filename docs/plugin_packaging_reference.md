# Plugin Packaging — Ready-to-Build Reference

**Status:** DEFERRED by owner 2026-06-09 ("no confidence building a plugin now"). This file holds everything needed to build it later with no re-research. Nothing here is started.

**Scope note:** this is `agent_core` infrastructure work — NOT tied to any single project. Plugin spec below verified against official Claude Code docs on 2026-06-06 and re-verified 2026-06-09.

---

## 1. Do you even need this? (read first — it may save you the build)

**Verified fact (2026-06-09):** your harness skills already work in **every project on this machine right now.** `~/.claude/skills/<skill>` and `agent_core/skills/<skill>` share the **same inode** (live-linked) — every edit to `agent_core/skills` is already global, no install, no copy. The skills appear in the skill list inside any project on this machine.

So the plugin's value is **NOT** "use skills across projects on this machine" — that is already solved. The plugin is worth building only for one or more of:

1. **Cross-machine portability** — clone the repo on a new computer and get the whole system. (The current live-link is tied to the exact Google-Drive mount path; on another machine it does not exist.)
2. **Robustness** — if the Google-Drive mount changes or breaks, the live-link dies and the skills vanish; a git repo does not.
3. **Versioned distribution** — git-SHA or semver versioning + `/plugin update`.
4. **The learning/career goal** — you stated you want to build a Claude Code plugin (it is on your "AI Agent Engineering" portfolio). This is a legitimate standalone reason.

If none of 1–4 is true when you revisit this, **do not build it** — the skills already work.

---

## 2. Scope when you build it

**Ship skills only (this pass).** Hooks and the `design-auditor` agent were the original plan's "layer 3" payload, but those are **Stage 2** (`spec_first_pipeline_design.md` §12), which is trigger-gated and not built. Package the skills that exist; add a hooks/agents update to the plugin later, once Stage 2 fires.

**Hybrid architecture (mandatory — a hard platform limit):** plugins **cannot** ship `.claude/rules/` or `CLAUDE.md`. So:
- Plugin carries: `skills/` (and later `agents/`, `hooks/hooks.json`).
- The existing **symlink system keeps delivering rules + CLAUDE.md** (`~/.claude/rules` → `agent_core/rules/universal`, etc.).
- `agent_core` stays the single source of truth for the rules half regardless of what happens to the skills half.

---

## 3. The one unresolved decision (resolve this FIRST when you return)

**The constraint:** a plugin must be a **git repo**, and **Google Drive sync corrupts `.git` directories**. Your skills currently live in `agent_core/skills/` on Google Drive. Therefore the plugin repo must live **outside Drive** (e.g. `~/projects/<name>`). That forces a source-of-truth choice:

| Option | What it does | Trade-off |
|---|---|---|
| **A — Plugin repo is the source (recommended)** | Move skill files to a new git repo at `~/projects/<name>` (outside Drive). `agent_core/skills` becomes a **symlink** to that repo's `skills/`. Single source, git-versioned, portable, no drift. `agent_core` keeps `rules/`. | Restructures the current setup; skills no longer physically inside the Drive `agent_core`. |
| **B — agent_core stays source; plugin mirrors it** | Skills stay on Drive; a sync script copies them into the plugin repo before each release. | **Two copies that drift** if you forget to sync — the exact anti-pattern the no-drift rule warns against. Not recommended. |

**Recommendation: Option A** — single source of truth, honors the no-drift / no-shortcut rule. The only real cost is the one-time move + symlink.

**Why not just git-init agent_core in place:** Drive + `.git` = corruption risk; also the Drive path contains spaces and a personal email, which is awkward for a repo. Keep the git repo off Drive.

---

## 4. Verified plugin spec (copy-pasteable — no re-research needed)

Docs: code.claude.com/docs — `plugins.md`, `plugins-reference.md`, `plugin-marketplaces.md`, `discover-plugins.md`.

### Manifest — `.claude-plugin/plugin.json`
Only `plugin.json` goes inside `.claude-plugin/`. **All components live at the plugin ROOT**, not inside `.claude-plugin/`. Only required field is `name` (kebab-case → becomes the namespace).

```json
{
  "name": "harness",
  "version": "1.0.0",
  "description": "Personal Harness Engineering system — spec-first pipeline + design audit",
  "author": { "name": "Monireach" },
  "license": "MIT"
}
```
Omit `version` → git commit SHA auto-versions (every commit = an update via `/plugin update`). Pin `version` → users update only when you bump it.

### Directory layout (components at ROOT)
```
harness/
├── .claude-plugin/
│   └── plugin.json            ← ONLY this file here
│   └── marketplace.json       ← if this repo is also the marketplace (see §5)
├── skills/
│   ├── product-spec/
│   │   ├── SKILL.md
│   │   └── archaeologist_mode.md   ← supporting files travel alongside SKILL.md
│   ├── design-audit/SKILL.md
│   ├── ideation/SKILL.md
│   └── ... (all skills to ship)
├── agents/                    ← LATER (Stage 2): design-auditor.md
├── hooks/hooks.json           ← LATER (Stage 2): journey-trace gate
└── README.md
```
- `skills` manifest field **adds to** the default `skills/` dir (does not replace).
- `commands`, `agents`, `outputStyles` manifest fields **replace** their defaults if set.
- SKILL.md format is **identical** inside a plugin vs in `~/.claude/skills/` — no changes needed to the skill files. (This is why §11.4 self-containment already paid off: the skills port as-is.)

### Namespacing (automatic)
Plugin skills become `/<plugin-name>:<skill-name>` (e.g. `/harness:product-spec`); agents `<plugin-name>:<agent-name>`.

### `${CLAUDE_PLUGIN_ROOT}`
Resolves to the plugin's install dir; usable in hooks, MCP/LSP configs, and skill/agent content. Use it for any plugin-internal path (this is the plugin-era replacement for absolute paths — relevant when Stage 2 hooks reference scripts).

### Plugin-shipped subagent restriction (matters for Stage 2)
Subagents shipped in a plugin **cannot** use `hooks` / `mcpServers` / `permissionMode` frontmatter (security). Root-level `hooks/hooks.json` **is** allowed. Subagent `memory: user|project` **is** allowed (so the `design-auditor` agent's project memory works in a plugin).

---

## 5. Marketplace — `.claude-plugin/marketplace.json`
A repo can be its own marketplace. Minimal form:
```json
{
  "name": "monireach-harness",
  "owner": { "name": "Monireach" },
  "plugins": [
    { "name": "harness", "source": "./" }
  ]
}
```
`source` can be a relative path (same repo), or `{ "source": "github", "repo": "owner/repo", "ref": "v1.0.0" }`, or git-url / git-subdir / npm.

---

## 6. Install + local testing commands (verified)
```bash
# Test a local plugin directory without installing (session-only):
claude --plugin-dir ./harness

# Validate manifest + skill frontmatter + hooks.json before shipping:
claude plugin validate ./harness            # add --strict to treat warnings as errors

# Reload everything mid-session without restart:
/reload-plugins

# Install from a local marketplace:
/plugin marketplace add ./<marketplace-repo>
/plugin install harness@monireach-harness
```

---

## 7. When you're ready — entry steps
1. Re-read §1: confirm at least one of cross-machine / robustness / versioning / learning-goal still applies. If not, stop.
2. Resolve §3 (recommend Option A).
3. `git init` a repo at `~/projects/<name>` (OUTSIDE Drive).
4. Move/symlink skills per the §3 decision; add `.claude-plugin/plugin.json` (§4) + `marketplace.json` (§5).
5. `claude plugin validate` → `claude --plugin-dir` to smoke-test → `/plugin marketplace add` + `/plugin install`.
6. Update `spec_first_pipeline_design.md` §12 Stage 3 item 8 status when done.

---

## 8. Related context
- Build plan + staging: `spec_first_pipeline_design.md` §12 (Stage 3 item 8) + §13.
- Original 2026-06-06 research + open decisions: smart_chatbot `archive/crucial_notes.md` "[NOT smart_chatbot] Personal Claude Code Plugin" section (now superseded by THIS file as canonical).
- Stage 2 components (hooks, design-auditor agent) that the plugin will carry later: `spec_first_pipeline_design.md` §6, §7, §12.
