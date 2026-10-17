---
name: end-session
description: Use this skill when the user invokes "/end-session", says "end session", or asks to wrap up and close out the work. Runs the full close-out - appends today's decisions to the daily log, archives completed tasks, then validates and repairs current_state/project_status.md against the documented conventions, and ends with nothing local only (everything pushed or in Drive). Fixes what it finds; reports at the end.
version: 2.1.0
---

# End Session

Close the session so the next one can resume from the files alone. Three things happen, in this order, and the order matters: **log what happened -> move finished work out -> validate what remains.**

The validation step has the mechanical checks, and it is last on purpose. Validating a status file before archiving completed tasks out of it just produces violations you are about to fix anyway.

**Read the rules before checking against them.** The authority is `logging-workflow.instructions.md` §2.5/§2.6 and `documentation-structure.instructions.md` §10.3. What follows is the recurring shape, not a replacement. If the two disagree, the instruction file wins and this skill is out of date.

---

## Step 1 - Append today's decisions to `archive/daily_log.md`

**Never read the whole file.** It runs to thousands of lines. Read the last 50; if today's date heading is not there, expand to 100, then 200, then 500, stopping as soon as you find today or a date older than today. An older date means today has no section yet - create one.

What earns a line (§2.3): decisions and the evidence behind them, failed attempts and why they failed, blockers, mental-model shifts, anything that cost real time. What does not: commands run, files read, routine steps.

**Write the corrections too, not only the successes.** A log that records what worked reads like a highlight reel and is worth far less in six months than one recording where the session went wrong and what the fix was. If the user corrected you - on a wrong claim, an unverified assertion, a framing that flattered the result - that belongs in the log, in their words. It is the most useful kind of entry, because it is the mistake a future session is most likely to repeat.

Use the smallest format that carries the meaning: a one-liner for a simple event, a short bullet for a decision, a structured entry only when the complexity demands it.

---

## Step 2 - Archive completed work out of `project_status.md`

Per §2.6, a task that is fully complete leaves the status file:

1. Copy its `### ✅ Task Name` detail section into `current_state/milestone.md`, in that file's format - Quick Reference row at the top, full narrative section at the bottom, with `**Why this task existed:**` in plain English.
2. Delete the detail section from `project_status.md`.
3. Add the one-line row to the Completed Milestones table.
4. If the project keeps the `bugs.md` / `resolved_bugs.md` pair, apply the mirror sequence to any bug fixed today: remove the `### ◻️ BUG-NNN` detail and its Bug List row from `bugs.md`, add the Quick Reference row and narrative section to `resolved_bugs.md`, and bump the open/resolved counts in the `bugs.md` header.

**Open both files and say what you found, even when the answer is "nothing changed."**

- `current_state/milestone.md` - always open it. Report its size and last entry, and either what you added or why nothing needed adding. "No `### ✅` sections, so nothing to archive" is a finding; skipping the file silently is not.
- `current_state/bugs.md` - check whether it exists. The pair is optional (§10.4) and a project either has both files or neither. Report which, and whether anything moved.

A close-out that mentions neither file is indistinguishable, to the person reading it, from one that forgot them. That has happened; it is why this paragraph exists.

Two things that look complete and are not:

- **A completed child subtask under a parent still in progress stays put.** Removing it makes the task tree ambiguous.
- **A completed task whose phase still has open tasks stays put** when it carries an `**Acceptance:**` block, because the Gherkin chains across tasks in a phase. Mark it `### ✅ Task Name *(awaiting phase-end archival)*` so the integrity check can tell it apart from an oversight.

**And the reverse: tasks that ARE finished but are not marked ✅.** A task leaves the list when its work is over, not when somebody remembered to change its symbol, and the symbol is the last thing anyone updates. Find them in two steps, and keep the cost down by reading details only where a line gives a reason to.

**Step A — read every line of every Task List (V1, V2, V3 …), and nothing below them.** The lists are a few dozen lines, so this is cheap, and reading them side by side is what catches a task overtaken by *another* task. Mark a line as a **suspect** when any of these holds:

- this session worked on it, or changed something it names (a file, a package, an ID, a person's decision);
- its own words say the remaining work is someone else's call, or is done ("only owner calls remain", "half done");
- it names a date that has passed, or an event that has happened (a meeting, a demo);
- it contradicts `Current State`, the project's instruction file, or another line (a count, a status, a file said to exist).

**Step B — open the details of suspects only, and give each a verdict backed by one fact from the files** (a merged pull request, a deleted directory, a gate that now exits 0, a decision recorded in the log), never by the task's own words:

| The task… | Verdict | Do |
|---|---|---|
| has every step done, or its only remainder is already another open task's subject | **finished** | archive it as above; its milestone entry names which task now owns the remainder |
| is about something removed, retired or ruled out since it was written | **overtaken** | close it under one `❌ … closed without building` entry in `milestone.md`, with the reason, and remove it |
| still describes open work, but a sentence in it is no longer true | **open, corrected** | keep it; fix the stale sentence and its list line |
| needs the user to say whether an event happened, the work is still wanted, or it belongs in V2 | **ask** | ask once, for all such tasks together; never decide it yourself |

**What makes Step A enough: a task's list line always states its current state.** Whenever this session writes progress or a decision into a task's details, update that task's list line in the same edit, in a few words ("decided out of scope 2026-10-04", "only the owner's call remains"). A decision that lives only in the details is invisible to Step A, and that is exactly how a task stays open after it is over. Before finishing, check that every task this session wrote details for has a list line that says what changed.

*Evidence: on 2026-10-13 a close-out of `project_documentations` archived the two tasks marked ✅ and reported the file clean; every mechanical check passed. The user asked for the tasks to be checked one by one, and 17 of 35 were finished or overtaken — a backend clean-up whose pull request had merged two weeks earlier, a meeting-pack task for a meeting already held, a check on packages that no longer existed, a task the user had closed by decision nine days before. None carried a ✅. Re-reading only the list lines afterwards, about 10 of the 17 could be judged from the line alone; the other 7 had their real state only in the details — the user's decision on one sat in its details while its list line still read "Settle" — which is why the list line must be kept current. Only 1 of the 17 had been worked on by the closing session, so a rule limited to the session's own tasks would have found 1.*

---

## Step 3 - Validate and repair `project_status.md`

**1. Only these sections may exist**, in this order:

- `Current State`
- `Completed Milestones`
- `V1 Task List`
- `V1 Task Details`
- `V2 Task List`
- `V2 Task Details`

Any other top-level section is a violation. Report the heading and its line number.

**2. `Current State` holds at most six bullets, and `Next` is the last one.**

The rule most often broken, because finished work accumulates there. Over six usually means completed items should have moved to `Completed Milestones` or into a task's detail section.

**Check the bullets are TRUE, not just that there are six of them.** This is the failure a count alone will not catch. A `Current State` describing work as "in progress" that finished hours ago is worse than a long one, because the next session acts on it. Read every bullet against what this session actually did, and rewrite anything the session overshot - a crawl that has since finished, a blocker that has since cleared, a run command that has since been replaced by a script. Every claim in `Current State` is a claim about **now**.

**2b. Every `Current State` bullet gets a printed verdict before the file is saved.**

Not a reading - a recorded verdict per bullet, `live` / `dead` / `unverified`:

- **`live`** - you can name the decision the next session would get wrong without it. Keep.
- **`dead`** - its subject is resolved, shipped, or overtaken. **Delete it.**
- **`unverified`** - you could not check it this session. Say so inside the bullet, or delete it.

**Keeping is what needs justification, not deleting.** If you cannot name the decision a bullet changes, it goes. `dead` means delete - **not rewrite, not soften, not "keep the useful part"**. Rewriting a resolved bullet into a caveat is the exact move this step exists to stop: it preserves the words after the reason for them is gone, and the next reader has to work out for themselves that nothing depends on it.

_Evidence: the bullet-count rule above is followed reliably because it fails when broken. This one was prose, and was broken four times in one project - most instructively on 2026-09-15, when a Git LFS blocker was rewritten into a caveat an hour after it was fixed, while `Current State` sat at exactly six bullets and every mechanical check passed._

**3. `Next` answers one question - what should the next session do first?**

The six-bullet cap counts bullets, so a `Next` that has swallowed the whole status report still passes it. That is the loophole, and it is worth closing separately because `Next` is the one bullet guaranteed to be read:

`Next` may carry three things and nothing else:

- **the first action**, named specifically enough to begin without deciding anything first;
- **what must be true before it can start**, where that is not obvious;
- **what is blocking it**, if something is.

Everything else routes by the question it answers. Ask it of each sentence:

| The sentence answers...              | It belongs in                                      |
| :----------------------------------- | :------------------------------------------------- |
| what happened, what was learned      | `archive/daily_log.md`                             |
| what shipped                         | `Completed Milestones` + `milestone.md`            |
| what is true of the system right now | its own `Current State` bullet                     |
| what comes after the first thing     | the `V1 Task List`                                 |
| how to do the work                   | the task's detail section                          |
| what someone else must decide        | its own bullet, or the project's decision register |

**When it is too long, move - do not compress.** This is the instruction that matters, because a size limit on its own produces the worse outcome: twelve topics rewritten as twelve dense clauses, still unreadable and now also unsearchable. If `Next` runs past about five lines, that is a signal that something has been routed wrong, not an instruction to tighten the prose.

**Why it drifts, and it is always the same reason.** `Next` is the last thing written at close-out and the first thing read at open, so it attracts anything that felt important on the way past. Nothing else in the file has that pull. Left alone it becomes the file's junk drawer - and then the next session reads 1,100 words to find one instruction, or worse, skims and misses it.

_Evidence: on 2026-09-15 this project's `Next` bullet held 1,125 words across twelve bold-led topics - the next action, two completed features, four open findings, a list of standing rules, sign-in credentials and the commit state. Current State still passed its six-bullet check._

**4. Every task sits in V1 by default.** A task belongs in V2 only where the user has said so explicitly. If something is in V2 without that, ask rather than assume - moving a task between versions changes what gets built next.

**5. Every task in a Task List has a matching Task Details section, and the reverse.**

Run the check mechanically, in both directions. On Windows:

```powershell
cd current_state
$cl = Select-String -Path project_status.md -Pattern '^- (🔲|⬜|🔄|⏳|✅|❌) ' |
    ForEach-Object { ($_.Line -replace '^- (🔲|⬜|🔄|⏳|✅|❌) ','') -replace ' \(.*',"" } |
    Sort-Object -Unique
$dt = Select-String -Path project_status.md -Pattern '^#{3,4} (🔲|⬜|🔄|⏳|✅|❌) ' |
    ForEach-Object { (($_.Line -replace '^#{3,4} (🔲|⬜|🔄|⏳|✅|❌) ','') -replace ' \(.*','') -replace ' \*\(.*','' } |
    Sort-Object -Unique
Compare-Object $cl $dt   # '=>' is an orphan detail; '<=' is a checklist entry with no detail
```

**A pair that matches in meaning but fails this check is still a violation - fix the file, not the check**. The commonest cause is markup: a checklist entry written `- ⬜ **Task name**` never matches a heading written `### ⏳ Task name`, so the pair is flagged on every run until someone strips the bold. A check that cries wolf every time gets ignored, and then a real orphan slips past it.

**6. Status symbols are the documented set** - ⬜ not started, 🔄/⏳ in progress, ✅ done, ❌ superseded. A bullet with no symbol cannot be counted, which defeats the point of the list.

On Windows agent hosts the file-write tool corrupts non-BMP emoji into U+FFFD. Prefer the BMP-safe set (⬜ ⏳ ❌), and check for corruption after every write:

```powershell
Select-String -Path project_status.md -Pattern ([char]0xFFFD) | Measure-Object
```

**7. No `### ✅` sections remain**, except those marked `_(awaiting phase-end archival)_`:

```powershell
Select-String -Path project_status.md -Pattern '^### ✅'
```

**8. The `<details>` collapsing convention keeps the file navigable as it grows - apply it, and never let it become a way to avoid deleting a dead bullet.**

As of 2026-09-19, `project_status.md` collapses backward-looking material behind `<details>/</summary>` so the file stays scannable at any size. This is presentation only - every check above still applies to the content underneath, whether it is expanded or collapsed. When counting Current State bullets under check 2, or scanning for a stray `### ✅` under check 7, look inside the `<details>` block; collapsing something does not exempt it from any check above.

**What collapses, what stays visible.** The rule is the same one that governs Next - forward-facing, decision-relevant text stays visible by default; backward-looking narrative, evidence, and settled history collapses:

| location                | Stays visible                    | Collapses                                                                                                                                                                                                                                                                                                                                                                                    |
| :---------------------- | :------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Current State           | the Next bullet only             | every other bullet, wrapped in one <details> block                                                                                                                                                                                                                                                                                                                                           |
| Completed Milestones    | the section heading              | the entire table, behind a <summary> that keeps whatever plain-text pointer (e.g. "Full narrative for each entry lives in...") used to sit above it                                                                                                                                                                                                                                          |
| V1 / V2 Task List       | the checklist itself             | any intro prose above it - a Goal: paragraph, an execution-order rationale - none of it is what someone scans this section for                                                                                                                                                                                                                                                               |
| a task's detail section | the ### symbol heading line only | the entire body underneath it - problem statement, progress log, and any still-open notes together, behind one empty-summary <details> block. Unlike Current State, a task's forward-looking notes collapse too: the heading + status symbol already say whether it needs attention, and the reader opens the block when they are about to work on that specific task, not to scan the list. |

**The exact markup, copied from what already works in this project** - two shapes, depending on whether the summary is empty or carries text:

Empty summary (used once per file, typically for `Current State`):

```md
<details>
<summary></summary>

- bullet
- bullet

</details>
```

Text summary, inline, when the label is a plain sentence or has only inline markdown (a milestone table's pointer):

```md
<details><summary>Full narrative for each entry lives in [`milestone.md`](milestone.md).</summary>

| table |

</details>
```

Empty summary wrapping an entire task's body (heading stays outside, everything below it collapses together):

```md
### 📋 (HIGH) Task name

<details><summary></summary>

Problem statement.

**Progress (date):**

- ✅ sub-bullet
- ✅ sub-bullet

**Still pending:**

- next step
- next step

</details>
```

**This is not a way to avoid deleting a dead bullet**. Check 2b already says a bullet with no live decision behind it gets deleted, not rewritten into a caveat. Wrapping it in `<details>` instead is the same failure with extra steps - it still occupies the file, still needs re-reading to confirm it is inert, and now also hides from a plain-text search. Collapse only what earned its place in `Completed Milestones` or a task's own settled history; delete what did not.

_Evidence: found 2026-09-19 - a `**Goal:**` paragraph and an `**Execution order set...**` paragraph sat in plain view above the `V1 Task List` checklist, uncaptured by any check above because check 2's six-bullet cap only counts `Current State`. First instinct was to collapse both. Cross-checking against `Completed Milestones` first showed 0 of the paragraph's 10 numbered items were already `✅` there, and the one dependency note it carried (RSP POM before config externalization) was most now that config externalization was done - so most of it was deleted outright, not collapsed. The two facts that were NOT duplicated anywhere else (a still-open decommission task, and the KInner-PI-before-model-comparison-before-chunking sequence) were promoted into a real checklist bullet and a real task detail, and the remaining sequence was encoded by bullet position instead of prose. **Check completeness against `Completed Milestones` before collapsing a stale-looking paragraph - collapsing what should have been deleted just delays finding this out.**_

**9. Every `### symbol heading` in task Details has its own `<details>`/`</details>` pair, correctly closed before the next heading.**

An unclosed `<details>` does not fail loudly - the file still renders, git still diffs it, and every check above except this one still passes. What it actually does is swallow every heading and bullet after it into the wrong task's collapsed block, until the next `</details>` (or end of file) closes it. The next task silently disappears from the outline.

Check mechanically - pair every `<details>`/`</details>` in document order like balanced brackets, then confirm no `###` heading falls strictly between an opening and its matching close:

```powershell
python -c "
with open('current_state/project_status.md', encoding='utf-8') as f:
    lines = f.readlines()
stack, pairs = [], []
for i, l in enumerate(lines, start=1):
    if '<details>' in l: stack.append(i)
    if '</details>' in l:
        if not stack: print('ORPHAN CLOSE at line', i)
        else: pairs.append((stack.pop(), i))
if stack: print('UNCLOSED <details> opened at lines:', stack)
headings = [i for i, l in enumerate(lines, start=1) if l.startswith('### ')]
for o, c in pairs:
    swallowed = [h for h in headings if o < h < c]
    if swallowed: print(f'block {o}-{c} swallows heading(s) at {swallowed}')
print('pairs:', len(pairs), '| headings:', len(headings))
"
```

`pairs` should equal the number of `### ` headings plus the two section-level wraps (`Current State`, `Completed Milestones`). If it does not, or anything printed above that line, a `<details>` is missing its close.

_Evidence: found 2026-09-19, in the same session as check 8 - the "Decommission the old `ai-search-kh-test`" task opened a `<details><summary></summary>` and was never given a matching `</details>`. It silently swallowed the entire next task ("Add citation architecture....") into its own collapsed block. Both checklist/detail cross-checks (rule 5) and the stray-`### ✅` scan (rule 7) passed the whole time, because neither one looks at `<details>` balance - this is a distinct failure mode from either._

**10. The corruption scan in check 6 only catches `U+FFFD` and tab. Widen it - a PowerShell double-quoted string (or here-string) silently eats a backtick immediately before a letter with escape meaning, and does not raise an error.**

`` `t `` becomes a real tab, `` `r `` becomes a real carriage return, `` `a ``becomes a real bell character (0x07), `` `n ` `` a real newline - in every case the backtick, the letter, and the code-fence meaning of both are gone, replaced by one invisible control character. This happens whenever generated content containing backtick-wrapped identifiers (`` `rag-khmer-textlayer` ``, `` `awspot-forms` ``) is written via a double-quoted PowerShell string or here-string (`@"..."@`) instead of a single-quoted one (`@'...'@`). Prefer `[System.IO.File]::AppendAllText` with a single-quoted here-string for exactly this reason; when that is not possible, scan afterward:

```powershell
Select-String -Path project_status.md -Pattern "[\x00\x07\x08\x0B\x0C\x0D]" | Measure-Object
```

A hit reads as a short, plausible-looking gap in running prose (a missing word, a missing backtick pair) - not as an obvious garbage character - so it survives a casual read. Confirm by checking the exact bytes around the hit, not just that something matched.

---

## Step 4 - Leave nothing local only

The session can end on any machine, and the next one may start on another (the MacBook or the server). So close-out ends with **zero local-only state**: everything is pushed to GitHub or lives in Drive. Rule: `project-storage.md` "No file is local only".

**1. Run the check** for every repository the session touched:

```bash
"$AGENT_CORE_DIR/skills/end-session/local-only-check.sh" <repo>
```

**2. Turn every output line into one proposed action.** Decide the action yourself from the file; do not ask what to do with it.

| Tag | Proposed action |
| :-- | :-- |
| `DIRTY` (session work) | commit it on the current feature branch |
| `DIRTY` (not from this session) | name it; ask whether it is kept (commit) or junk |
| `UNPUSHED`, `NO-UPSTREAM` | `git push -u origin <branch>` |
| `NO-REMOTE` | create a private GitHub repo, add `origin`, push. Ask which owner/org |
| `STASH` | show `git stash list`; apply onto a branch and commit, or drop on the user's yes |
| `MISSING-LINK`, `LOCAL-ONLY` env file or other private file | move into Drive and symlink: `project-storage.md` "Making a file private" |
| `LOCAL-ONLY` that is regenerable (deps, cache, build output, downloaded data) | add its pattern to `.gitignore` under a `# regenerable: <command that rebuilds it>` comment; the check then skips it |
| `LINK-OUTSIDE` | name the target; propose moving the target into Drive |
| `NOT-GIT` | propose `git init` + a private repo, or moving the folder into Drive |

**3. Ask ONCE for the whole list**, as a numbered plan with your action per line, ending with `Apply all, commit and push? yes/no`. Commits, pushes, moves and deletions still need that yes (`user-confirmation.md` §6.1–6.2); one yes covers the list it was asked for, nothing more.

**4. Apply, then re-run the check.** Report the session closed only when it exits 0 for every touched repo. If the user declined a line, name that line in the final report as still local only.

Also:

- **Never stage `current_state/`, `archive/`, `CLAUDE.md`, `PROJECT.md` or any `.env`.** They are gitignored symlinks into Drive.
- **Before every commit, run this. Both counts must be 0:**
  ```bash
  git diff --cached --raw | grep -c ' 120000 '                              # staged symlinks
  git diff --cached | grep -c -i -E 'CloudStorage|gmail\.com|/Users/'      # personal paths
  ```
  A Drive link whose `.gitignore` pattern has a trailing slash (`personal/`) is NOT ignored, so `git add -A` commits it, and the link text holds the Drive path with the email. Fix: unstage it, add `/name` (no slash) to `.gitignore`, re-run. This happened on 2026-10-15 in a public repo.
- **Name what is left running** - background servers, watchers, agents - and how to stop it. A session that ends with an undocumented process holding a port costs the next one a confusing failure.
- **Update `PROJECT.md` only if the project's structure changed.** Not for routine work.

---

## Guarding against the two ways this goes wrong

**Do not report progress against your own previous attempt.** "Down from 33 problems to 19" is not a result; 19 problems is the result. Measure against correct, and say plainly when the answer is not yet correct. A close-out that flatters the session is the most expensive document in the repository, because the next session trusts it.

**Do not write a claim you have not checked this session.** Everything in Current State is asserted as true right now. If a bullet cannot be verified, say so inside the bullet rather than leaving it standing.

---

## Action

Work through the four steps and **fix what you find** - do not merely report it. Ask only where the instructions genuinely require a decision: a task that appears to belong in V2, or the single Step 4 approval.

When finished, report in a few lines. **Every file the close-out touches gets a line, including the ones nothing happened to** - a file that goes unmentioned reads exactly like a file that was forgotten, and the reader cannot tell the difference:

- `archive/daily_log.md` - what was appended, under which date heading
- `current_state/project_status.md` - which violations were repaired
- `current_state/milestone.md` - what was archived into it, or why nothing was
- `current_state/bugs.md` / `resolved_bugs.md` - what moved, or that the project does not keep the pair
- repositories - the check's exit code per repo, what was committed and pushed, and any line the user declined
- anything left running, and how to stop it
