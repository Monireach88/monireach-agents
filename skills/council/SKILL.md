---
name: council
description: >-
  Use when the user invokes "/council", or asks for a "council review", a "multi-perspective review", to "get different perspectives", or to "review this with several lenses". The session agent picks 3-6 non-overlapping lenses, sends each to a blind reviewer agent in parallel, then judges their reports - merges agreements, decides conflicts with a stated reason, drops wrong or unverified claims - and gives ONE combined recommendation. Works on any topic: code, a plan, a document, research, a life decision.
version: 1.0.0
---

# Council — several blind reviewers, one judged answer

**Trigger:** `/council <artifact or question>` — e.g. `/council docs/prd.md`, `/council should I take this job offer?`

## Words used in this skill

- **Artifact:** the one thing being reviewed — files, a folder, or a written question with its context.
- **Lens:** one reviewer agent with one concrete job. Lenses never see each other.
- **Orchestrator:** you, the session agent. You write the brief, spawn the lenses, and judge their reports. You never act as a lens.
- **Run folder:** where every file of one run is saved.

## When to use it

| Situation | Use |
| --- | --- |
| One artifact or decision, several different angles, one combined answer | **/council** |
| A list of tasks done one by one, each verified | `/loop-dev` |
| A quick opinion on a small change | Neither — answer directly |

## Step 0 — Pick the lenses (3-6)

1. Name the **purpose** in one sentence: what decision the user will make from this review.
2. List who will use or be affected by the artifact (a reader, a builder, a tester, a future self, an opponent). Each real use becomes a candidate lens.
3. Keep 3-6 lenses. **No two lenses may share a job.** If two candidates would read the same thing for the same reason, merge them.
4. Give each lens a **Task that is work, not an opinion.** A Task passes only if all three hold:
   - It starts with a verb that produces something: write, build, plan, list, trace, prove, predict, count, classify, answer.
   - It names what the lens hands back (a list, a plan, test cases, counts).
   - The lens cannot finish it without using the artifact, and the answer cannot be one word.

   | Rejected | Rewrite |
   | --- | --- |
   | "Is the README clear?" | "Using only README.md, write the day-one commands in order; list every step where you had to guess." |
   | "Review my career plan." | "List every claim in the plan that a hiring manager would ask proof for; for each, name the proof that exists or write 'none'." |

5. Give each lens a **Pass when** line that is observable: a count, an empty list, or two outputs that match. "Good", "clear" or "complete" without a count fails.
6. Write one line per lens saying **why it was chosen** (which purpose or user it covers).

## Step 1 — Write the brief

1. Create the run folder: `archive/council/<YYYYMMDD>_<slug>/` in the current project. If the project has no `archive/`, use the session scratchpad and tell the user the path in the final report.
2. Write `brief.md` from `references/brief_template.md`:
   - **Inputs:** every file or fact the lenses read, with paths. Check each path exists (`ls`).
   - **Confirmed facts:** what is already known. Lenses must not re-ask these.
   - **User decisions — do not argue:** choices the user has fixed. Lenses may advise on how, never on whether.
   - **Lenses:** the table from Step 0.
   - **Output contract:** copy it from `references/lens_contract.md`.
3. Show the user the lens list (name + one-line why) in ≤6 lines, then continue without waiting, unless the purpose is unclear. If unclear, ask one question with your recommended answer.

## Step 2 — Spawn every lens in parallel, blind

1. Send **one Agent call per lens, all in the same message**, so they run at the same time. Use the general-purpose agent type.
2. Each prompt is the filled lens prompt from `references/lens_contract.md`, and nothing else. It never mentions other lenses, never includes another lens's output, and lists the run folder as **must not read**.
3. Lenses are **read-only**: they edit no file and write nothing into the run folder. You save what they return.
4. Optional: if the harness offers other model families, you may give some lenses a different model. This reduces shared blind spots. It is never required.

## Step 3 — Save and check each report

1. Save each report exactly as returned to `<run folder>/<N>_<lens-slug>.md` (N = 1, 2, 3 …).
2. A report is **hollow** when any of these hold: no evidence or citations; no count or named set checked; Pass-when result missing; more than 5 recommendations; over 40 lines; it argues a "do not argue" decision.
3. Re-spawn a hollow lens **once**, with the same prompt plus: "Your previous report did not show the work. Show evidence and counts." A second hollow report is recorded in the synthesis as a failed lens. Never invent its content.

## Step 4 — Judge and synthesize

Write `<run folder>/0_synthesis.md` from `references/synthesis_template.md`. You are the judge, not a vote counter.

1. **Finding IDs.** Give every distinct finding a stable ID `F-01`, `F-02`, … in the order first found. Never renumber or reuse an ID, also in later rounds.
2. **Agreements.** A finding that ≥2 lenses reached independently goes in the agreement table, with every source lens.
3. **Conflicts.** When lenses make incompatible claims, keep both claims and **decide**. State the decision and the reason: the stronger evidence, the user's own data, or the user's stated priority. Never average two positions into a middle answer. Never decide by count alone. If only the user can decide, the conflict becomes an open question.
4. **Check before you trust.** For each claim the plan depends on, verify it yourself (read the file, run the command, search the source) when you can. A claim you cannot verify is either dropped or marked `unverified` and kept out of decisions.
5. **Dropped claims.** List each dropped claim with its reason: wrong (with evidence), unverified, out of scope, or argues a user decision.
6. **One combined plan.** One recommendation, not a menu. Each action has: what, when, and how to measure it ("done when"). Never offer a shortcut next to the standard solution.
7. **Open questions.** Only questions the user alone can answer. Each one has your recommended answer.

## Step 5 — Verifier (optional, for high stakes)

Use it when the decision is costly or hard to reverse: money, a job, health, a production change, a publication. Skip it for low-stakes reviews and say "verifier skipped: low stakes" in the synthesis.

1. Spawn **one fresh agent** with the prompt in `references/synthesis_template.md` § Verifier prompt. Its job is to **refute** the synthesis, not approve it.
2. Save its report as `<run folder>/verifier.md`.
3. For each point it raises: fix the synthesis if the evidence holds, or record why it does not. Never delete a finding because of it; change the finding's status and keep both sides.

**Optional fix loop** (only when the artifact is a file and the user asked for fixes): the finder cannot fix — a lens or the verifier never edits the artifact. A fresh fixer agent (or you, if the user prefers) applies the plan. Then re-run only the lenses whose inputs changed, each given its own earlier findings to re-check. Stop at 3 rounds, or when a round leaves the same open finding IDs as the round before. Then report what is still open.

## Step 6 — Report to the user

Follow the user's plain-language and response-length rules. The report is short; the run folder holds the detail.

1. **First sentence: the answer** — the one combined recommendation.
2. Then at most 5 points: the top agreed findings, each conflict you decided (one line each), and the first action for the next 24 hours.
3. Then the open questions, each with your recommended answer.
4. Last line: the run folder path.

Never paste lens reports or the full synthesis into the chat.

## Never do

- Never let one lens see another lens's existence or output.
- Never give a lens a question it can answer with an opinion.
- Never average a conflict or decide it without a stated reason.
- Never put an unverified claim into the plan as fact.
- Never offer a list of options where one recommendation is possible.
- Never let a lens or the verifier edit the artifact.
- Never commit, push or delete files as part of this skill without the user's confirmation.
