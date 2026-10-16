# Rules Refactor Plan

> ### ▶ THIS REFACTOR IS COMPLETE. Nothing here is waiting on a future session.
> Both acceptance tests passed on 2026-07-26 (session 3) and the one leftover path bug is fixed. Read [§10](#10-start-here-next-session-handoff) for the closing record — what was verified, how, and the list of things not to redo. The rest of this document is the reasoning behind the changes.

**Date:** 2026-07-26  
**Status:** COMPLETE — executed ([§9](#9-what-was-actually-executed-2026-07-26)) and verified ([§10](#10-start-here-next-session-handoff)). No open items.  
**Evidence:** 12-agent audit of all 21 files in `agent_core/rules/`. Every finding below was quote-verified against the real file by a second agent whose job was to refute it. 25 claims were killed as false. 108 survived with lowered severity. 11 survived at full severity.

---

## Table of Contents

1. [Diagnosis](#1-diagnosis)
2. [The four root-cause lines](#2-the-four-root-cause-lines)
3. [Per-file plan](#3-per-file-plan)
4. [The four mechanisms you picked](#4-the-four-mechanisms-you-picked)
5. [My read on your framework research](#5-my-read-on-your-framework-research)
6. [Execution order](#6-execution-order)
7. [Open decisions](#7-open-decisions)
8. [The CDF test — acceptance criteria](#8-the-cdf-test--acceptance-criteria-for-the-whole-refactor)
9. [What was actually executed](#9-what-was-actually-executed-2026-07-26)
10. [**START HERE — next-session handoff**](#10-start-here-next-session-handoff) ← closing record + the "do not redo" list

---

## 1. Diagnosis

Your three complaints are one disease with three symptoms.

**The disease:** almost every rule is written as *advice to a human reader*, not as an *instruction to a model*. Advice uses adjectives — "brief", "appropriate", "thorough", "as needed". A model cannot fail an adjective. It picks the reading that suits it and reports full compliance. That is why the agent tells you the rules are crystal clear and violates them in the same turn. It is not lying. Under the text as written, it did comply.

A rule only binds if it has three parts:

| Part | Question it answers |
|---|---|
| TRIGGER | When does this fire? |
| TEST | How do we check afterwards that it was obeyed? |
| ON FAIL | What happens when it is broken? |

Across all 10 universal files, **zero rules have all three.** Only one file even attempts part 3 (`core-principles.md` §3.4), and its prescribed action is to apologise and continue.

**Two things I found that are worse than a loophole:**

1. **Your rules are loaded twice, every session.** `~/.claude/rules/` and `~/.claude_storage/rules/` are two mount points onto the same files (verified: identical inode 10442). Both are injected into context. That is ~8,000 tokens of duplicate rules per session — larger than every other token saving in this plan combined. **This is a harness/config fix, not a file edit. Do not delete anything under either path — they are the same single copy of your files.**

2. **Seven pointers in `about-monireach.md` are dead.** `~/.claude/profile/` does not exist. `communication.md`, `health.md`, `ml_engineering.md`, `portfolio.md`, `job_seeking.md`, `devops.md`, `sizing.md` — none of them are there. The file that was supposed to hold your communication and English guidance, the exact subject of complaint #2, is a broken link. So the agent reads "see communication.md", assumes the guidance exists somewhere, and applies none.

---

## 2. The four root-cause lines

If you only fix four lines, fix these. Each one is the single sentence that causes one of your complaints.

### Complaint #1 — output too long

> `response-style.md` §1.1 line 5:
> **"Match response length to complexity + user's context, not to a fixed rule."**

The clause **"not to a fixed rule"** forbids exactly the thing you are asking me to build. Any word count added later in the file is pre-cancelled by this line. And "matched complexity" cannot be checked by anyone after the fact.

Its partner, line 22: **"Complex question + beginner → Full explanation with examples"**. The short branch has a number ("2-3 sentences"). The long branch has none. The agent classifies both inputs itself — it decides whether your question is "complex" and whether you are a "beginner" — so it controls which branch it lands in, and one branch is unbounded.

### Complaint #1 (second engine) — the template that guarantees a wall of text

> `teaching-protocol.md` §4.6:
> **"Once you establish a structure for concept A, lock it in. Use that EXACT structure for concepts B, C, D."**

This mandates 7 filled sections per concept — Intro, Components, Sub-components, Under the Hood, When to Use / NOT Use, Visual Representation, Summary — with no word cap and no permission to skip a slot. Floor is roughly 700–1500 words *per concept*. Three related concepts is a guaranteed 2000–4500 word wall, and the agent can prove it was required to write it. The section is even labelled CRITICAL, so it beats the length rule in any conflict.

It also contradicts its own file: §4.2 says "one concept at a time", §4.3 says the brain holds ~4 new concepts, and §4.2 says "don't always go to Level 4" — while §4.6 forces 7 blocks including a mandatory "Under the Hood".

### Complaint #2 — output too hard to understand

> `response-style.md` §1.3 line 65:
> **"Use technical terminology appropriate to the domain"**

This is the **only** line in all 10 universal files that governs vocabulary. It is a licence, not a limit. "Appropriate to the domain" authorises any word the agent can connect to the topic. There is no glossing duty, no cap on new terms, no line between a term you need for interviews and a rare word that helps nobody.

> `about-monireach.md` line 21:
> **"Non-native English speaker (needs precision)"**

This is the only statement of your English level anywhere. It is a trait label for a human reader, and **"needs precision" actively backfires** — it reads as *use the exact technical term rather than a loose everyday word*, which increases jargon. The one line meant to protect you authorises the behaviour you are complaining about.

### Complaint #3 — rules get violated

> `core-principles.md` §3.4:
> **"When you make a mistake → Acknowledge it factually, explain what you'll do differently, MOVE ON"**

This is the only after-violation instruction in the entire ruleset, and it costs the agent one sentence. Nothing requires it to name the rule, and nothing requires it to **redo the bad output**. So: agent writes 1,500 words, you object, agent says "correct, I exceeded the budget, I will keep it shorter next time," and moves on — and you still never got the short answer. The violation is free.

---

## 3. Per-file plan

Legend: **FIX** = rewrite as trigger/test/on-fail · **CUT** = delete, saves tokens and changes nothing · **KEEP** = already good, do not touch.

### `response-style.md` — heaviest rewrite (largest single win)

| Action | Target | Note |
|---|---|---|
| FIX | §1.1 whole section | Replace with the tier table (§4 below). Delete "not to a fixed rule". Delete the beginner/expert matrix — the reader is always you, and your level is already in the Expertise Map. |
| FIX | §1.3 "Use technical terminology appropriate to the domain" | Replace with the two-list vocabulary rule (§4 below). |
| FIX | §1.3 "Be thorough and proactive" | Split doing from reporting: *be thorough in the WORK, short in the REPORT.* Right now this line silently exempts most sessions from any length limit, because most sessions are action tasks. |
| CUT | §1.4 Output Token Limit Handling (lines 85–158) | **74 lines — 46% of the file — teaching the agent how to successfully deliver 20,000-token outputs.** In the file whose job is to make output shorter. Fires maybe monthly. Replace with 2 lines. **Saves ~900 tokens/session.** |
| CUT | §1.1 Examples block (lines 25–34) | Hypothetical beginners turning off a computer. You are not hypothetical. ~110 tokens. |
| KEEP | §1.2 Clarifying Questions Protocol | Genuinely good — has real triggers and a real anti-pattern. |
| KEEP | §1.3 "After reading files" | Short, testable, correct. |

### `teaching-protocol.md` — second heaviest

| Action | Target | Note |
|---|---|---|
| FIX | §4.6 the 7-slot template | Add a hard trigger (only when you name 2+ things to compare) and a per-slot cap. Make Under the Hood / Sub-components / Visual opt-in. |
| FIX | §4.2 Ladder Approach — "Stop at the level where understanding clicks" | The stop condition is inside your head. The model cannot see it, so it never stops. Replace with: write L1+L2, stop, ask by name. Never L3/L4 unless requested. |
| FIX | §4.1 CRITICAL RULES — "wait for user to apply fix" | Contradicts `/vibe-code`, contradicts §1.3 "update all affected files", and contradicts the harness default. Add a precedence line: this applies only under `/code-coach`, `/concept-unblock`, `/guided-explore`. |
| FIX | §4.4 checklist | Six checkboxes a model cannot tick, with no failure action. Convert to a numeric pre-send gate. |
| ADD | §4.0 blocker-first | See §5. |
| ADD | §4.2 framework picker | See §5. |
| CUT | §4.5 Good vs Bad Examples | Third copy of the same Bad/Good pattern already shown in §4.3. ~280 tokens. |
| CUT | §4.6 "Why this works" + "Example Application" + "Result" | The example application contains no example — three sklearn class names each followed by the literal text `[Use EXACT SAME template structure]`. ~450 tokens. |
| CUT | §4.3 "Human brains hold ~4 concepts" | Neuroscience trivia for a human. No condition, no action. ~80 tokens. |
| CUT | Purpose line 3 "Maximize learning effectiveness" | A goal, not a procedure. |
| KEEP | **§4.1 the five-step backwards trace** | The best rule in the whole set. Numbered, ordered, testable, and it matches how you actually learn. Do not touch it. |

### `about-monireach.md`

| Action | Target | Note |
|---|---|---|
| FIX | "Non-native English speaker (needs precision)" | Replace with the executable English spec (§4). |
| FIX | 7 dead profile pointers | Either create the files or delete the pointers. Right now they make the agent believe guidance exists elsewhere. Add: *if a referenced file is missing, say so in one line — never assume its contents.* |
| FIX | "No fluff, no bloat" | A four-word slogan with no unit. Replace with a countable ban list (preamble, restating the question, closing summaries). |
| CUT | "How to Use This Profile" (lines 89–103) | Tells the agent to read a file already fully in context, then ends with "respond with appropriate depth and style". ~150 tokens. |
| CUT | Personal lines 13–16 (relationship, girlfriend's family, Chinese New Year) + `R: [Not yet documented]` | Cannot change a technical answer. Move to a load-on-demand file. ~75 tokens. |
| KEEP | **The two HARD RULE bullets on shortcuts** | These are the best-written rules you have — explicit, absolute, with named forbidden phrases. This is the model for everything else. |

### `core-principles.md`

| Action | Target | Note |
|---|---|---|
| FIX | §3.4 "MOVE ON" | Add the mandatory repair procedure (§4). This single fix is the biggest lever on complaint #3. |
| CUT | §3.5 Test Before Deploy | Two untestable bullets, already enforced with real commands by `testing-commands.md` and the `/vibe-code` verifier. |
| CUT | §3.2 "NEVER HALLUCINATE in any session, anywhere, anyhow! EVER!" | Volume, not procedure. The executable version is the bullet above it. |
| CUT | §3.4 the "DISGUSTING" sermon | Emotional appeal to a human. The banned-phrase list on the line above is the part that works — keep that. |
| KEEP | **§3.2.1 Search Result Verification Protocol** | Numbered, has a real procedure, names the exact violation pattern. Excellent. |
| KEEP | §3.1 final bullet ("I cannot verify this") · §3.4 banned-phrase list |  |

### `user-confirmation.md` — small file, two real holes

| Action | Target | Note |
|---|---|---|
| FIX | "or any other terms that show affirmation" | **HIGH.** The file builds a closed list of five approval phrases, then this last bullet dissolves it into agent judgement — on the rule the file itself calls the #1 violation. "nice, thanks" becomes approval. Make the list exhaustive. |
| FIX | "or semantically similar phrases" | **MEDIUM.** "Explicitly says" is cancelled two clauses later by an unbounded paraphrase test. "Just get it done and stop asking me" becomes blanket commit-and-push permission. |
| KEEP | **§6.1 the 4-step workflow, §6.2, §6.3** | §6.3 (no re-running background tasks) is the single best-formed rule you own: absolute, observable, with a stated consequence. Model other rules on it. |

### `token-efficiency.md`

| Action | Target | Note |
|---|---|---|
| ADD | §11.5 output-side mirror | The file is titled *File **Reading***. Input is disciplined with real numbers (`tail -50 → -100 → -200`, first ~30 lines). Output has no equivalent anywhere in 10 files. **You spend real effort protecting the agent's context window and zero protecting your own attention.** Add the mirror question: *does he need all of this, or just part of it?* |
| CUT | §11.4 General Rule | Restates §11.1 as a rhetorical question and re-lists tactics §11.2/§11.3 already gave with numbers. ~97 tokens. |
| KEEP | **§11.2 and §11.3** | Both excellent — concrete numbers, real escalation ladder. |

### `coding.md`

| Action | Target | Note |
|---|---|---|
| FIX | "read all files in `agent_core/rules/project-types/coding-universal/`" | Relative path that resolves from nowhere, with no failure action, so 6 mandatory files can go silently unloaded. Worse: the documented workaround in `CLAUDE.md` uses `readlink ~/.claude/rules`, and I ran it — **it returns empty**, because that path is a real directory here, not a symlink. Both routes are broken. Needs an absolute path plus a hard stop. |
| KEEP | **Cross-Project Issues + Python Dependency Management** | Both excellent — absolute prohibitions, named tools, exact format requirements. |

### `external-resources.md`

| Action | Target | Note |
|---|---|---|
| CUT | Examples 1–7 + "How to ask effectively" | Seven restatements of one instruction with the noun swapped. ~300 tokens. |
| KEEP | Core rule, lines 3–7 | Has a trigger and a stop condition. |

### `personal.md`

| Action | Target | Note |
|---|---|---|
| CUT | **Whole file** | Self-refuting: `CLAUDE.md`'s routing table already says personal projects need "universal rules only — no additional file needed", so the file's own content says it should not exist. Meanwhile it sits in `universal/` and loads unconditionally in *every* session, including coding ones — a permanent, trigger-less exemption from rigor that any agent can cite. |

### `question-handling.md`

| Action | Target | Note |
|---|---|---|
| KEEP | **Entire file** | The only file the audit could not break. It has a real trigger list, a real exception list, worked bad/good examples, and it names its own most common violation ("the action-task reframe trap"). **This is the template. Every other rule file should be rewritten to look like this one.** |

### `project-types/` — lighter, loaded selectively

| Action | Target | Note |
|---|---|---|
| CUT | `logging-workflow.md` §2.1–§2.4 | Biggest offender outside universal. Four templates ending in a 16-line "full structured entry" with no trigger; a 12-category emoji list all self-graded; a rewrite of `token-efficiency.md` §11.3; and a six-question "Golden Rule" expansion test sitting *under a compactness rule*. **~1,470 tokens/coding session.** |
| CUT | `frontend-standards.md` §1 Code Quality | Near-verbatim duplicate of `backend-standards.md` §1. Full-stack sessions load both copies. |
| CUT | `project-navigation.md` | 5 lines, both of which already exist in `session-management.md` §9.1. Delete the file, fold into §9.1. |
| CUT | `devops-standards.md` §9 SRE | SLOs, error budgets, toil %, 48–72h blameless postmortems. Org-process rules you cannot execute in a solo repo. Inert rules under a MANDATORY banner teach the agent that MANDATORY is soft. |
| CUT | `research-academic.md` Perfectionism Handling | Duplicates `about-monireach.md`, names you inside a file symlinked into repos, and its "done is better than perfect" **contradicts your HARD RULE against shortcuts.** |
| CUT | `ux-standards.md` §1 "Read frontend-standards.md Fully" | Contradicts `token-efficiency.md` §11.1. |
| FIX | The `ALL RULES BELOW ARE MANDATORY` banner (4 files) | No way to check which were applied and no procedure for one that cannot apply. A skipped rule and an inapplicable rule look identical. Add: output `SKIPPED §N — reason` per skipped section. |
| KEEP | `testing-commands.md` (whole file) · `git-workflow.md` §5.2/§5.3/§5.4 · `backend-standards.md` §4/§8.1/§10 · `documentation-structure.md` §10.2 and the `comm -13` orphan check |  |

### Token budget

| Change | Saving |
|---|---|
| Stop double-loading the rules tree (config, not an edit) | **~8,000/session** |
| Universal-file cuts above | ~2,100/session |
| `logging-workflow.md` cuts | ~1,470/coding session |
| Other project-type cuts | ~640/relevant session |

---

## 4. The four mechanisms you picked

You chose these in the questions earlier. Specs below; they are what I would write into the files.

### 4a. Length — tiers with hard caps (`response-style.md` §1.1, full replacement)

```
DEFAULT IS T0. Escalate only on a listed trigger. No trigger = T0.
When two tiers both look right, take the SHORTER one.

T0  fact / yes-no / where-is-it / status
    -> 1-3 sentences. No preamble. No summary. No closing offer.

T1  "how do I" / "what should I use" / "is X better than Y"
    -> answer in <=3 sentences, then <=5 bullets. Cap 150 words.
    -> end with one line: "Want the why?"

T2  trigger words: why / explain / teach / I don't understand /
    walk me through
    -> MANDATORY ORDER:
       (1) one plain sentence saying what the thing IS.
           Before any analogy. No exceptions.
       (2) ONE framework (§5), named in brackets.
       (3) exactly ONE mental picture. Never a second one.
           Never switch pictures mid-explanation.
       Cap 250 words.
    -> end by naming 2-3 specific next steps he can pick from,
       not a yes/no question.
       GOOD: "Next: (a) the graph, (b) the Python, (c) PDF vs CDF?"
       BAD:  "Want to know more?"

T3  action task (code, files, analysis, deployment)
    -> the WORK has no cap. PROSE about the work caps at 120 words:
       what changed (1 line per file) / how verified (1 line) /
       what is still open (1 line each).
    -> never restate code you just wrote, never summarize files
       you just read, never list options you rejected unless asked.

OVER-BUDGET RULE: if the answer will not fit the cap, do NOT write it.
Print the section headings in <=10 lines and ask which one to write first.
```

**Why this closes the hole:** every branch has a number, the default is the short one, ties break short, and there is a defined action for "it doesn't fit" — which is currently missing everywhere.

### 4b. English level — two separate budgets (`response-style.md` §1.3 + `about-monireach.md`)

I checked your own `resources/vocabulary.md` to calibrate this rather than guessing. You have study cards for **"unraveled", "phenomena", "inevitable", "rigorous"**, and a confused-pair entry for **genuine vs authentic** with Chinese memory aids. That is a solid B2 reader working toward C1. If "inevitable" earned a vocabulary card, then "orthogonal", "salient", "nuanced" and "germane" are far above your working line.

```
BUDGET 1 — ordinary English (verbs, adjectives, sentence glue)
  Use the commonest word that is still accurate.
  Sentences: average <=20 words, hard max 25.
  No Latin abbreviations (write "for example", not "e.g.").
  BANNED, with replacements:
    leverage->use      utilize->use        myriad->many
    nuanced->subtle    salient->important  orthogonal->unrelated
    delve into->look at    elucidate->explain    obviate->remove the need for
    canonical->standard    germane->relevant     underpin->support
    non-trivial->hard      first-class->fully supported

BUDGET 1b — REGISTER (added 2026-07-26 after the CDF test, §8)
  Showy academic English is one failure. Fake-casual English is the
  OTHER failure, and it is just as hard to read. Both are banned.
  NO slang or profanity-adjacent punchiness:
    "no-BS", "cut the garbage", "you're screwed", "newbies", "brutal"
  NO English idioms:
    "apples to oranges", "cheat sheet", "street address", "the whole
    nine yards", "ballpark", "under the hood" as a casual filler
  NO culture-specific settings in analogies. He is Chinese-Cambodian.
    BAD:  carnival dunk tank, basketball backboard, baseball radar gun,
          rollercoaster height rule, Thanksgiving, football downs
    GOOD: a test score in a class, a queue of people, a water bucket,
          a price list, a train timetable, a bank balance
  Plain formal English is EASIER for him than casual English.
  Sounding relaxed is not a goal. Being understood is.

BUDGET 2 — technical terms
  ALLOWED and WANTED if you would hear them in an AI/ML job interview
    or a code review: idempotent, race condition, foreign key,
    backpropagation, migration, gradient, index.
  On first use in a session, add a gloss of 4-8 words in parentheses:
    "idempotent (running it twice changes nothing)"
  Max 3 NEW technical terms per response. If a 4th is needed,
    stop and ask before introducing it.
  BANNED: rare jargon with no career payoff — monad, catamorphism,
    epistemic, isomorphic (outside its React meaning).
```

**Note — a real tension you should rule on.** Your `target_vocabulary.md` is an Academic Word List study file: you are *deliberately* learning "rationale", "empirical", "encompass", "constitute", "derive". Budget 1 above would ban that whole register. My reading is that these are two different tracks — AWL is for your paper and presentations, plain English is for explanations — so the rule should apply to explanations only, and your handwriting/paper work stays untouched. Confirm that split.

### 4c. Compliance stamp (new §1.5)

```
End every response with exactly one line:

  [T1 | 87w | new terms: idempotent | unverified: 0]

  T#          the tier you chose
  ##w         actual word count of your prose
  new terms   technical terms you introduced and glossed this turn
  unverified  count of factual claims you did NOT check with a tool.
              Must be 0, or each one named.
```

**Why it works:** it is not a promise, it is a measurement, and it sits on the same screen as the thing it measures. The agent cannot print `[T0 | 40w]` above 600 words without you seeing the contradiction instantly. It also converts complaint #3 from "did it follow the rule?" (unanswerable) into "does the number match the text?" (three seconds to check).

### 4d. Violation repair (`core-principles.md` §3.4, replacing "MOVE ON")

```
On noticing a violation — yours or one the user points out:
  1. Print: RULE VIOLATED: <file> <section>
  2. State the observable fact that proves it
     (word count, banned word, missing confirmation).
  3. IMMEDIATELY re-deliver the same turn in compliant form,
     in the same message.
     An apology without a corrected output is a SECOND violation.

"Move on" means move on after step 3, not instead of it.
No promise about next time counts as a fix.
```

**Removed (2026-07-26):** an earlier draft added a 4th step writing each violation to `archive/rule_violations.md`. Cut, and the owner was right to cut it. Three reasons: (a) he never selected the ledger option — I added a mechanism he had declined, which is my error, not a design choice; (b) the logger is the violator, so a rule the agent is ignoring is a rule it will also not log; (c) nothing in the plan ever reads the file, and a log with no reader is dead weight. `/log-mistake` already exists if he wants a record. **Step 3 is the part that fixes complaint #3** — the redo, not the record.

---

## 5. My read on your framework research

### Honest assessment

**The research is good, and it is aimed at the wrong problem.**

All four frameworks are real and well chosen. But they answer *"which lens do I explain through?"* They do not answer *"how long?"* or *"which words?"* — and those are two of your three complaints. **A Feynman explanation can be 2,000 words.** So the frameworks help complaint #2 somewhat, do nothing for complaint #1, and could make it worse: analogies and origin stories add words by construction.

So: adopt them, but only *inside* a tier cap. Framework chooses the shape. Tier chooses the size. They are separate controls and must stay separate.

### Ranked for you specifically

| Framework | My verdict for you |
|---|---|
| **Via Negativa** (show the chaos without it) | **Strongest.** Your profile says concrete-dominant memory and struggling with abstractions. Absence is concrete; a definition is not. This should be the default for "what is X / why does X exist". |
| **Historical origin** (the problem that forced the invention) | **Strong but risky.** It makes a design feel necessary instead of arbitrary — good for your "this seems stupid" moments. **Risk: it invites hallucination.** Origin stories are exactly where a model invents plausible history. Must be bound to `core-principles.md` §3.2: state the historical claim only if verifiable, otherwise say "roughly, the problem it solved was…" without inventing dates, names, or companies. |
| **Feynman** (12-year-old words, zero jargon) | **Good, with a caveat.** It is your best tool for level-matching. But it conflicts with your career goal — stripping all jargon means you never learn the interview words. Resolve it with Budget 2 above: Feynman the *explanation*, then name the real term once at the end. "That fingerprint machine is called a hash function." |
| **Definition + Example + Analogy** | **Weakest of the four for you — demote it.** It is three explanations of the same thing stacked, so it is 3× the length by construction, and it is roughly what the agent already does badly. Restrict it to one case: when you are mixing up two similar things and need them separated. |

### The missing fifth thing — and it matters most

None of the four frameworks *diagnose*. They all assume you already know which part confuses you. You told me you want the agent "explaining things intelligently by first recognizing my pain points or unblocking my blockers" — no framework in your research does that. A perfectly executed Feynman explanation of the wrong sub-step is still wasted.

You already own the fix: `/concept-unblock` Phase 1, "Find the Specific Blocker". It is genuinely good, and it is **locked inside a skill you have to remember to invoke.** It should be a universal precondition, because most of your confusion happens in ordinary conversation, not after you type a slash command.

### Ingestion plan (`teaching-protocol.md`)

You chose: frameworks live in `teaching-protocol.md` with a picker. Concretely:

```
§4.0  BEFORE EXPLAINING — FIND THE BLOCKER FIRST      [new, promoted
                                                      from /concept-unblock]
  Never explain a whole topic because one part of it was unclear.
  1. Name the single step you believe he is stuck on.
  2. Say it back in one sentence and ask: "Is this the part
     that's unclear, or is it earlier?"
  3. Explain ONLY that step.
  Skip §4.0 only if he named the exact sub-step himself.

§4.2  PICK ONE FRAMEWORK. NAME IT. THEN EXPLAIN.      [rewritten]

  his signal                          -> framework
  ------------------------------------------------------------
  "what even IS this / why does       -> VIA NEGATIVA
   it exist"                             show the mess without it

  "I know what it does, not HOW"      -> FEYNMAN
                                         12-year-old words; name the
                                         real term once at the end

  "I keep mixing this up with X"      -> DEF + EXAMPLE + ANALOGY
                                         only for confusable pairs

  "this design seems arbitrary"       -> HISTORICAL ORIGIN
                                         the problem that forced it;
                                         no invented dates or names

  HARD RULES
   - Exactly ONE framework per concept. Two = the answer is too long.
   - Print the framework name in brackets first: [Via Negativa]
   - The framework does not change the tier cap. T2 is still 250 words.
   - If no signal matches, use VIA NEGATIVA.

§4.0b  NEVER EXPLAIN AN UNKNOWN WITH ANOTHER UNKNOWN   [new, added
                                                       2026-07-26]
  Before using term B to explain term A, ask: has he already met B?
  Check the Expertise Map in about-monireach.md and this session.
  If B is also new, you have made the problem twice as hard.
    BAD:  explaining CDF by contrasting it with PDF
          (two unknowns, and the contrast teaches neither)
    GOOD: explaining CDF with a class test score
          (he has met test scores; he has not met PDF)
  Build only from things he already owns. If the concept genuinely
  cannot be explained without B, teach B first, on its own, and say
  so: "This needs one thing first. Two sentences on B, then A."
  Contrast with a sibling concept is allowed ONLY when he names the
  sibling himself, or when he says he is mixing the two up.
```

Printing the name is not decoration — it makes the choice auditable, same logic as the compliance stamp. If the agent writes `[Feynman]` and then uses the word "orthogonal", you can see the contradiction without reading the whole thing.

---

## 6. Execution order

Ordered by payoff per unit of risk. Each phase is independently useful — you can stop after any of them.

| Phase | Work | Why first |
|---|---|---|
| **0** | Fix the double-load of the rules tree. Config only, no file edits. | ~8,000 tokens/session, zero risk, larger than everything else combined. |
| **1** | Rewrite `response-style.md` §1.1/§1.3, cut §1.4, add §1.5 stamp. | Directly fixes complaints #1 and #2. Biggest single-file win. |
| **2** | `core-principles.md` §3.4 repair procedure + `user-confirmation.md` two closures. | Fixes complaint #3's mechanism and your self-declared #1 violation. Small, surgical. |
| **3** | `teaching-protocol.md`: add §4.0 and the §4.2 picker, cap §4.6, fix the Ladder. | Ingests your research. Depends on phase 1's tier caps existing. |
| **4** | `about-monireach.md`: English spec, dead pointers, "no fluff" → ban list. | |
| **5** | The CUT list: `personal.md`, `token-efficiency.md` §11.4, `external-resources.md` examples, `logging-workflow.md`, `project-navigation.md`, the rest. | Pure token savings, no behavior change, safe to batch last. |

**Verification after each phase:** run a fixed set of probe prompts (one T0, one T2, one action task) and check the stamp against the actual word count. If the stamp lies, the rule did not take.

---

## 7. Open decisions

1. **AWL tension (§4b).** Does the plain-English rule apply only to explanations, leaving your academic-vocabulary work untouched? My assumption: yes.
2. **Dead profile pointers.** Create the 7 files, or delete the pointers and inline the 3 lines that change behavior? Cheaper: delete and inline.
3. **`personal.md`.** I recommend deleting the file outright. It is your file, so I will not remove anything without you saying so.
4. **Stamp scope.** On every response, or only responses over 120 words? Every response is more auditable; over-120 only is less noisy.
5. **Phase 0** may need a harness/settings change I cannot make from here. If `settings.json` does not expose the rule-load path, this becomes a Claude Code config question rather than a file edit.

---

## 8. The CDF test — acceptance criteria for the whole refactor

**Added 2026-07-26.** The owner ran the same request ("explain CDF") against two models, one with a frameworks-only system prompt. Model A produced ~900 words he could not follow. Model B produced ~230 words he found easy. This is the best test data in the whole project, because the *concept and the reader were held constant* — only the output shape changed.

### First finding: the prompt was not the problem, and neither was model intelligence

Model A **obeyed its system prompt correctly.** It was told: via negativa, counterfactual, one vivid picture, no academic language. It delivered all four. It still failed.

That prompt specified **shape** (which frameworks) but not **size** (no word cap), not **level** (no vocabulary ceiling), and not **target** (no step to find what was actually confusing). That is the identical defect class as the current rule files — frameworks and adjectives with no countable limits. **The experiment accidentally reproduced this project's own bug in miniature.** It is strong evidence the diagnosis in §1 is right.

### What actually separated the two outputs

| | Model A (confusing) | Model B (clear) |
|---|---|---|
| Words | ~900 | ~230–250 |
| Plain one-sentence definition **before** any analogy | No — opened with the carnival | **Yes** — opened with the definition |
| Mental pictures used | **3** (dunk tank, hose+bucket, fraud engineer) | **1** (test score / one line of people) |
| Explained the unknown using another unknown | **Yes** — CDF via PDF | No |
| New technical terms, unglossed | **6+** (PDF, GAN, diffusion model, inverse CDF, calibration, quantile normalization) | 0–1, and only inside the *offer* list, never the explanation |
| Idioms / slang | Many — "no-BS", "you're completely screwed", "apples to oranges", "cheat sheet", "newbies" | None |
| Culture-specific setting | Yes — US carnival, baseball radar gun, basketball backboard | Test score, queue of people |
| Asked what was confusing first | No | Yes (the non-incognito run: "Blocker A / B / C — which is you?") |
| Ended by stopping | No — kept going into ML applications | **Yes** — named 2–3 specific next steps |

Eight mechanical differences. Not one of them is about intelligence or effort. **Every single one is enforceable by a countable rule.**

Note the incognito run: Model B was still clear *without* the diagnosis step. So diagnosis helps, but the load-bearing items are **answer-first, one picture, no second unknown, short, stop.**

### Direct answer: will the refactor produce Model A or Model B?

**Model B — with five gaps this test exposed, which are now closed in the plan.** Before this test, the plan caught Model A on three counts (250-word cap, one framework, max 3 new terms). It would have missed the other five. Added since:

| Gap this test exposed | Now in plan |
|---|---|
| No rule forcing a plain definition *before* the analogy | §4a T2 mandatory order, step 1 |
| No rule limiting the answer to ONE mental picture | §4a T2 mandatory order, step 3 |
| No ban on explaining an unknown with another unknown | §4.0b (new) |
| No ban on slang and idiom — only on showy academic words | §4b Budget 1b (new) |
| Ending was a yes/no question, not named options | §4a T2 closing line |

### Use this as the standing regression test

After each phase in §6, ask the configured agent to explain a concept not in the Expertise Map, then score it against the eight rows above. Any row matching the Model A column means that phase did not take. Keep the two raw outputs — they are the reference answers.

### One honest limit

Rules can enforce all eight rows because all eight are countable. Rules **cannot** guarantee the analogy chosen is a *good* one — "a test score in a class" beating "a carnival dunk tank" is judgment, not arithmetic. What the rules can do is force one analogy instead of three, force it to be culturally neutral, and force it to come after a plain definition. That converts a bad analogy from a wall of text into one wrong sentence you can correct in five words.

---

## 9. What was actually executed (2026-07-26)

Backup of all 21 original files: `docs/rules_backup_20260726/`.

### Done

| File | Change |
|---|---|
| `response-style.md` | Rewritten. §1.1 tier table (T0–T3), §1.3 two vocabulary budgets + register ban, §1.4 forbidden-openings list, §1.5 compliance stamp, §1.6 truncation (was 74 lines, now 3). |
| `teaching-protocol.md` | Rewritten. New §4.0 blocker-first, §4.0b never-explain-unknown-with-unknown, §4.2 framework picker, §4.3 ladder stops at L2, §4.5 numeric pre-send gate, §4.6 comparison template cut from 7 slots to 4 with a hard trigger. |
| `core-principles.md` | "MOVE ON" replaced by §3.6 Violation Repair (name it, prove it, re-deliver in the same message). §3.5 and the sermon lines cut. |
| `user-confirmation.md` | Approval list closed. "any other terms that show affirmation" and "semantically similar phrases" both removed. |
| `about-monireach.md` | English spec replaces "needs precision". "No fluff, no bloat" replaced by a countable ban list. 7 dead `~/.claude/profile/` pointers deleted. Personal-life block and "How to Use This Profile" cut. |
| `token-efficiency.md` | §11.4 replaced by the output-side mirror rule. |
| `coding.md` | Broken relative path replaced by a symlink check with a hard stop. |
| `external-resources.md` | 7 worked examples cut to one rule with a 3-part test. |
| `personal.md` | **Deleted.** Zero inbound references. |
| `project-navigation.md` | **Deleted.** Folded into `session-management.md` §9.1 step 2; `CLAUDE.md` updated. |
| `logging-workflow.md` | §2.1–§2.4 collapsed to §2.1–§2.3. Four templates and the six-question Golden Rule cut; 6-line cap added. §2.5/§2.6 kept their numbers — six files cite them. |
| `devops-standards.md` | §9 SRE deleted. |
| `ux-standards.md` | §1 replaced (it contradicted `token-efficiency.md` §11.1). |
| `research-academic.md` | Perfectionism section rewritten with an explicit boundary so it no longer contradicts the HARD RULES. |
| 4 standards files | `SKIPPED §N — reason` requirement added to the MANDATORY banner. |
| `CLAUDE.md` | Symlink check fixed — `readlink ~/.claude/rules` returns empty here, so the old command built a broken path. |

### Deviations from the plan — both deliberate

**1. `frontend-standards.md` §1 was NOT deleted.** The plan called it a duplicate of `backend-standards.md` §1. It is. But frontend-only projects never symlink the backend file, so deleting it would silently drop those rules from every frontend project. The audit judged text similarity and missed load paths. A comment now records that the overlap is intentional.

**2. `settings.json` was NOT changed.** Phase 0 is real — `~/.claude` is listed in `additionalDirectories`, which makes `.claude/CLAUDE.md` and `.claude/rules/` load a second time as "project instructions" (~8,000 tokens/session). Removing that one line should fix it. **But 19 references across 7 skills** (`update-profile`, `start-hf-spaces`, `start-local-dev`, `vibe-code`, `loop-dev`, `workflow-generator`) read from `~/.claude/...` paths, and they would break. This needs a decision, not a unilateral edit — see below. **Correction (session 2): the premise of this paragraph is false.** `additionalDirectories` was not the cause and no skill path ever needed rewriting; the double load came from a duplicate bind mount. `settings.json` was correctly left alone, but for a different reason than the one given here.

### Token outcome — the plan was wrong

| | Predicted | Actual |
|---|---|---|
| `universal/` | ~2,100 saved | **~255 LARGER** |
| `project-types/` | ~2,100 saved | ~478 saved |

The universal rules grew. The cuts were real, but the enforcement machinery that replaced them — tier tables, vocabulary lists, the framework picker, the pre-send gate — costs more than the bloat it displaced.

I also had to correct myself mid-execution: the first pass added "why the old rule was wrong" notes to every edited file. Those are precisely the human-reader rationale (rubric defect I) that this refactor exists to remove. They were stripped from the rule files; the history lives in this document instead, which is not loaded every session.

**The honest read:** rule-file size was never the complaint. Output length and comprehension were. Trading ~255 tokens of always-loaded context for countable, auditable rules is the right trade — but the plan should not have promised a saving it could not deliver.

### Open — needs a decision *(both closed; kept for the record)*

1. ~~**The 8,000-token double load.** Either (a) remove `~/.claude` from `additionalDirectories` and rewrite 19 skill paths to the Drive path, or (b) accept the duplicate.~~ **CLOSED session 2–3.** Both options were wrong because the diagnosis was wrong — `additionalDirectories` was never the cause. It was a duplicate bind mount in `docker-compose.yml`. Removing one mount line fixed it; no skill paths were rewritten. Confirmed by a fresh session in §10 Test 1.
2. ~~**Verify the stamp actually appears.**~~ **CLOSED session 3.** The compliance stamp was removed from the design before this test ever ran (see §10 "should NOT redo"). The §8 CDF test was run on its own merits and scored 8/8 — §10 Test 2.

---

## Appendix — what I could not verify

Two of the 12 audit agents died on a session token limit: the English-level evidence sweep and the prior-art survey. I redid both by hand, but narrower than planned:

- **English level:** based on `resources/vocabulary.md` and `resources/target_vocabulary.md` only. I did not sweep your CV, `daily_learnings.md`, or `archive/` for writing samples. The B2 estimate is from vocabulary cards, not from your own prose.
- **Prior art:** I grepped `agent_core/skills/` for the four framework names. None of the teaching skills (`concept-unblock`, `guided-explore`, `code-coach`) define any of them, so there is no duplication risk. I read `concept-unblock`'s section headings but not its full text.

Full raw audit output, including the 25 refuted claims and all 108 lowered-severity findings:
`/tmp/claude-1000/.../tasks/wgn3la1nd.output` *(session-scoped — likely gone now)*

---

## 10. START HERE — next-session handoff

**Written 2026-07-26 at the end of the refactor session. Updated 2026-07-26 (session 2), then closed in session 3. Read this section only; the rest is background.**

### ✅ CLOSED 2026-07-26 (session 3) — no outstanding work

| Item | Outcome |
|---|---|
| Test 1 — double load stopped | PASS. `response-style.md` appears **once** in a fresh session's context. |
| Test 2 — do the new rules bind | PASS, **8/8** on the CDF case. |
| `coding-universal` path bug | FIXED via a new `AGENT_CORE_DIR` env var. All four snippet branches tested. |

The env var reaches sessions started after the next container rebuild — a routine environment step, owned by the operator, not a task for a future agent. Nothing else is pending.

**A future session should read the rest of §10 as a record, not a to-do list.** The two test procedures are kept because they are the standing regression tests: re-run them if the rule files, the mount table, or the harness changes. The "should NOT redo" list at the end is the part that still binds.

### Session 2 in three lines

Test 1 was re-run and returned **twice**. The cause was traced to a duplicate bind mount in `~/projects/rermork-ops/docker-compose.yml`, not to `additionalDirectories`, and the offending mount line was removed. Test 1 now needs one fresh-session confirmation; **Test 2 has still not been run at all.**

### What happened, in five lines

The 10 universal rule files were rewritten so every rule has a **trigger, a test, and a failure action**. The old ones were written as advice to a human ("be brief", "be thorough"), which a model cannot fail — that was the root cause of the owner's three complaints: output too long, output too hard to read, rules ignored. Two files were deleted, five project-type files trimmed, two skills repointed. Full record in §9. **Backup of all 21 original files: `agent_core/docs/rules_backup_20260726/`.**

### ✅ Both tests are VERIFIED (2026-07-26, session 3). Nothing to re-run.

The two subsections below are kept as the record of what was tested and how, plus the reusable regression procedure. Neither is an outstanding task any more.

Both needed a **genuinely new session** — not `--continue`, not resume, not a container restart with the session resumed. The context block is assembled once at session start, so a resumed session still shows the pre-fix state and cannot test itself.

**How to tell you are in a genuinely new session:** run `echo $CLAUDE_CODE_SESSION_ID`. If it matches the ID from the session that made the change, you are resumed — the test is invalid.

---

**TEST 1 — Did the ~8,000-token double load stop?** *(10 seconds)*

> **STATUS 2026-07-26, session 3 — ✅ PASSED AND CLOSED.** Fresh session `fdc41d44…` reported the text of `response-style.md` appearing **once**, and all 9 universal rule files appearing once each from `/Users/monireach/.claude_storage/rules/`. OS-level state at the same moment: `~/.claude/rules` does not exist; `grep rules /proc/self/mountinfo` lists only `.claude_storage/rules` and `.gemini/rules`. ~8,000 tokens/session recovered. Do not re-run.
>
> *History, superseded by the session-3 line above:* **STATUS 2026-07-26, session 2 — ROOT CAUSE FOUND AND FIXED. Awaiting one fresh-session confirmation.**

**The original hypothesis in this document was wrong.** `additionalDirectories` was never the cause. Session 2 re-ran the test, got **twice**, and traced it to the container mount table.

Real cause — `~/projects/rermork-ops/docker-compose.yml` mounted the *same host directory* at *both* paths Claude Code scans:

```yaml
- ${HOME}/.claude/rules:${HOME}/.claude/rules            # scanned as project scope
- ${HOME}/.claude/rules:${HOME}/.claude_storage/rules    # scanned as CLAUDE_CONFIG_DIR
```

`CLAUDE_CONFIG_DIR=${HOME}/.claude_storage` is set at compose line 25, so Claude Code read all 9 rule files once per path. Verified: `stat -c %i` returns the same inode (471741) for `~/.claude/rules/response-style.md`, `~/.claude_storage/rules/response-style.md`, and the real file in `agent_core/rules/universal/`.

**Fix applied:** the first line was deleted from `docker-compose.yml`. Rules are now mounted only at `CLAUDE_CONFIG_DIR`.

**Verified at OS level after the container restart:**

| Check | Result |
|---|---|
| `ls ~/.claude/rules` | does not exist |
| `ls ~/.claude_storage/rules` | present, all 9 files |
| `grep rules /proc/self/mountinfo` | only `.claude_storage/rules` and `.gemini/rules` |

**What is still open:** the mechanical precondition holds, but no fresh session has confirmed the context itself now carries one copy. Ask a genuinely new session:

> How many times does the text of `response-style.md` appear in your context?

| Answer | Meaning | Action |
|---|---|---|
| Once | Fixed. ~8,000 tokens/session recovered. | Record it here and close the item. |
| Twice | A third scan path exists that mountinfo did not reveal. | Re-run `grep -E ' /Users/monireach/\.claude(/\|$)' /proc/self/mountinfo` and check for a `rules/` dir beside every loaded `CLAUDE.md`. |
| Zero | The surviving mount is not the one Claude Code reads. | Revert: swap the two compose lines so `${HOME}/.claude/rules:${HOME}/.claude/rules` is the one kept. |

Background: **never `rm` either path — both are bind mounts of the single real copy at `agent_core/rules/universal/`.** Deduplication is done by removing a *mount line in `docker-compose.yml`*, never by deleting files. `~/.claude/CLAUDE.md` (compose line 47) is a separate mount of `agent_core/CLAUDE.md` and was deliberately left in place.

---

**Rollback for the compose change**

```bash
# in ~/projects/rermork-ops/docker-compose.yml, restore under "--- Claude Shared Brain ---":
#   - ${HOME}/.claude/rules:${HOME}/.claude/rules
# then rebuild the container
```

---

**TEST 2 — Do the new rules actually bind?** *(the one that matters)*

> **STATUS 2026-07-26, session 3 — ✅ RUN, SCORED 8/8. The new rules bind.**
>
> Case used: CDF, the reference case from §8. Fresh session `fdc41d44…`, no prior turns in the session.
>
> | # | Check | Result |
> |---|---|---|
> | 1 | Under 250 words | PASS — 191 |
> | 2 | Plain one-sentence definition before any analogy | PASS — opening sentence |
> | 3 | Exactly one mental picture | PASS — one class of 30 sorted exam scores, reused for both the absence case and the mechanism |
> | 4 | Unknown explained via another unknown | PASS — PDF never mentioned |
> | 5 | Framework named in brackets | PASS — `[Via Negativa]` |
> | 6 | Idioms or slang | PASS — none |
> | 7 | Culture-specific analogy | PASS — "test score in a class" is on the GOOD list in `response-style.md` §1.3 Budget 1b |
> | 8 | Ends with 2–3 named next steps | PASS — three, each naming a specific artifact (graph shape / numpy code / reading a percentile) |
>
> **Known weakness of this run:** the same agent produced the explanation and graded it — the self-report problem that §10 flags for the rejected compliance stamp. The rows are mechanically checkable (word count, presence of a bracketed framework name, presence of "PDF"), so the grading is auditable, but an independent grader would be stronger evidence. If this is re-run for confidence, have a second agent score the transcript.
>
> *History, superseded by the session-3 line above:* **STATUS 2026-07-26, session 2 — STILL NOT RUN.** Session 2 was spent finding the Test 1 root cause.

Ask the fresh session to explain a concept **absent from the Expertise Map** in `about-monireach.md`. CDF is the reference case — §8 has two graded example answers, one bad and one good.

Score the reply against these eight rows. Each maps to a specific rule:

| # | Check | Rule if it fails |
|---|---|---|
| 1 | Under 250 words? | `response-style.md` §1.1 T2 |
| 2 | Plain one-sentence definition **before** any analogy? | §1.1 T2 step 1 |
| 3 | Exactly **one** mental picture? | §1.1 T2 step 3 |
| 4 | Did it explain the unknown using **another unknown** (e.g. CDF via PDF)? | `teaching-protocol.md` §4.0b |
| 5 | Framework named in brackets, e.g. `[Via Negativa]`? | §4.2 |
| 6 | Any idioms or slang ("no-BS", "apples to oranges")? | `response-style.md` §1.3 Budget 1b |
| 7 | Culture-specific analogy (carnival, baseball, rollercoaster)? | §1.3 Budget 1b |
| 8 | Ends with 2–3 **named** next steps, not "want more?" | §1.1 T2 closing |

**Any row that fails → that rule did not bind.** Report the row number and the offending text; the fix is in the named section.

### Open decisions — all closed

1. **Nothing is pending on the rules themselves.** They are complete and structurally verified (all 43 internal `§` references resolve; no dangling pointers to deleted files).
2. ~~Test 1's fresh-session confirmation.~~ **Done, session 3 — passed.** Test 2 also passed, 8/8.
3. **Separate pre-existing bug, found session 2 — FIXED session 3, needs a container rebuild to take effect.** The session-init snippet in `agent_core/CLAUDE.md` ("Session Initialization → Step 1") could never find `coding-universal`:

   ```bash
   RULES_ROOT="$(readlink ~/.claude/rules || true)"
   [ -z "$RULES_ROOT" ] && RULES_ROOT="$HOME/.claude/rules"
   CODING_UNIVERSAL="$(dirname "$RULES_ROOT")/project-types/coding-universal"
   ```

   `readlink` returns empty on a **bind mount** (it is a real directory, not a symlink), so `RULES_ROOT` fell back to the literal path and `CODING_UNIVERSAL` resolved to `/Users/monireach/.claude/project-types/coding-universal` — which has never existed. The snippet therefore always printed `STOP: coding-universal not found`. This was already broken before the compose fix; removing the `~/.claude/rules` mount did not cause it.

   **Fix — stop deriving the path, supply it.** Two files changed:

   | File | Change |
   |---|---|
   | `~/projects/rermork-ops/docker-compose.yml` | new env var `AGENT_CORE_DIR`, beside `CLAUDE_CONFIG_DIR` (compose line 25), pointing at `agent_core` |
   | `agent_core/CLAUDE.md` Step 1 | the 3 derivation lines replaced by `CODING_UNIVERSAL="${AGENT_CORE_DIR:-}/rules/project-types/coding-universal"` plus an `if/elif` chain that reports an unset variable separately from a wrong path |

   Hardcoding the literal `agent_core` path into `CLAUDE.md` was rejected: it contains an email address, and this file is committed — see "What Must Never Appear" in `agent_core/CLAUDE.md`. The compose file already carries that path, so the variable belongs there.

   **Verified session 3:**

   | Check | Result |
   |---|---|
   | `docker compose config -q` | exit 0 |
   | `docker compose config \| grep AGENT_CORE_DIR` | resolves to the real `agent_core` path |
   | `/Users/monireach/Library/CloudStorage` mounted whole in the container | yes — so the path is valid inside the container, not only on the host |
   | Snippet, variable unset | `STOP: AGENT_CORE_DIR is not set` |
   | Snippet, variable correct, no symlink | `symlink created`; target resolves and holds exactly the 5 files |
   | Snippet, run twice | `symlink exists` — idempotent |
   | Snippet, variable pointing at a wrong path | `STOP: coding-universal not found at /nope/…` |

   **One note, not a task:** `AGENT_CORE_DIR` was absent from session 3's own environment, because compose env vars are read when the container starts. Any session begun after the next rebuild has it. Until then Step 1 prints the unset-variable STOP, which is the intended loud failure rather than the old silent wrong path. `echo $AGENT_CORE_DIR` confirms it whenever someone happens to look.

### Things a future agent should NOT redo

- **Do not re-add `${HOME}/.claude/rules:${HOME}/.claude/rules` to `docker-compose.yml`.** That mount is the double-load. It was removed 2026-07-26 session 2.
- **Do not chase `additionalDirectories` for the double load.** It was investigated twice and is not the cause. `~/.claude` is already absent from it in `~/.claude_storage/settings.json`.
- **Do not `rm` `~/.claude/rules` or `~/.claude_storage/rules`.** They are bind mounts of the one real copy. Fix mounts in `docker-compose.yml`.
- **Do not go back to deriving `agent_core` from `~/.claude/rules` with `readlink`.** That is the Open decisions #3 bug: bind mounts are real directories, so `readlink` returns empty. The path comes from `AGENT_CORE_DIR` now. If a new harness lacks the variable, set it there — do not reintroduce the derivation.
- **Do not hardcode the `agent_core` path into `agent_core/CLAUDE.md`.** It contains an email address and the file is committed. The variable exists for this reason.
- **Do not delete `frontend-standards.md` §1** as a duplicate of `backend-standards.md` §1. It is a duplicate by text, but frontend-only projects never symlink the backend file. The overlap is deliberate and marked in a comment.
- **Do not add a compliance stamp** (`[T1 | 87w | …]`). It was built, then removed at the owner's request — it measured length, which he can already see, and it was self-reported by the same agent that would break the rule. The enforcement lives in §1.1 caps, `teaching-protocol.md` §4.5 pre-send gate, and `core-principles.md` §3.6 violation repair.
- **Do not re-add "why the old rule was wrong" notes to rule files.** That rationale is human-reader prose loaded every session. It belongs in this document.
- **Do not write violations to a log file.** Considered and rejected: the only reader would be the agent that ignored the rule. `/log-mistake` covers it.

### Rollback

```bash
# restore every original rule file
cp -r "<My Drive>/monireach/resources/agent_core/docs/rules_backup_20260726/universal"      \
      "<My Drive>/monireach/resources/agent_core/rules/"
cp -r "<My Drive>/monireach/resources/agent_core/docs/rules_backup_20260726/project-types"  \
      "<My Drive>/monireach/resources/agent_core/rules/"
```

Deleted files live in the backup too: `universal/personal.md`, `project-types/coding-universal/project-navigation.md`.

### One hard-won operational rule

`settings.json` **fails silently and totally**. During this session a `#` comment was added to it — JSON has no comment syntax, so the whole file became unparseable, and the statusline, the `block-dangerous.sh` guard hook, and all 8 permission-deny rules went dead at once with no error shown.

**Always validate after hand-editing:**

```bash
jq . ~/.claude_storage/settings.json >/dev/null && echo OK || echo BROKEN
```
