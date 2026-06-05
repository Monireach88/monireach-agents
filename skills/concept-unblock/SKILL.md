---
name: concept-unblock
description: Use this skill when the user invokes "/concept-unblock" or says they don't understand something in software engineering, data science, or any technical field. Finds the exact blocker before explaining anything.
version: 1.1.0
---

# Concept Unblock

Do NOT explain yet. Find the blocker first.

---

## Phase 0: Diagnose Whether the Gap Is Foundational

**Before asking about the specific question, assess this first:**

When the user asks many questions at once, goes in circles, or says things like "I don't know where to start" or "my mind goes crazy" — this is a signal that the blocker is NOT the specific question. The blocker is a **missing foundational mental model**.

**How to detect a foundational gap:**
- User generates many rapid-fire questions that contradict each other
- User asks about ALL possible combinations ("can we convert X to Y? what about Y to Z? or X directly to Z?")
- User explicitly says they feel lost or have no foundation
- The questions span multiple layers (e.g., asking about client AND server AND wire simultaneously)

**What to do:**
1. Stop. Do NOT answer the specific questions.
2. Name the missing foundation explicitly: "The missing foundation here is [X]. Once you have that, all your questions answer themselves."
3. Confirm with the user: "Is that the gap?"
4. Build the foundation from scratch using Phase 2 protocol — one concept at a time, starting from what they DO know.

**Example from FastAPI session:**
- Monireach asked: "JSON to Pydantic directly? Dict to JSON? When to convert which to which?"
- Real gap: no mental model of what the wire carries between client and server
- Correct move: "The missing foundation is what actually happens at the boundary between client and server — what form data takes at each stage and why."
- Wrong move: answering each conversion question individually

---

## Phase 1: Find the Specific Blocker

When the gap is NOT foundational (user has a specific question that doesn't click), ask ONE of these before explaining:

**1. Which part specifically doesn't click?**
- Ask: "Which sentence or step is the first one that doesn't make sense to you?"
- Do NOT re-explain everything. Pinpoint the exact break point.

**2. Does it contradict something you already know?**
- Ask: "Does this conflict with something you've already seen or understood?"
- Example from DNS/SSL: User knew GitHub was providing SSL when DNS was DNS-only. When told "GitHub has no cert", it contradicted their knowledge → the real blocker was that the explanation implied GitHub *never* had a cert, when actually it *lost* its cert after proxying.

**3. Is a prerequisite mental model missing?**
- Ask: "Do you know how [prerequisite concept] works?"
- Example: Explaining ACME challenge assumes the user knows what Let's Encrypt does. Without that, the explanation fails.
- Common prerequisite mental models to check:
  - Networking: DNS resolution, what a proxy does at the network level, HTTP vs HTTPS
  - ML/DS: What a loss function is, what gradient descent does, what a tensor is
  - Systems: What a process vs thread is, what a port is, what a file descriptor is
  - Testing/mocking: What `patch` does to function calls inside the block vs outside

**CRITICAL — Never assume Monireach knows mocking/patching behavior:**
A recurring pattern: explanation fails because Monireach doesn't know that calling ANY function
inside a `patch` block returns a `MagicMock`, not the real return value.

Before explaining anything that involves `patch`, `mock`, or `return_value`, explicitly verify:
- "Do you know what happens when you call a function inside a `with patch(...)` block?"
- If not → explain this first: "Inside the patch block, the function is replaced by a MagicMock.
  Calling it returns a MagicMock object, not the real value. Outside the block, it's the real function."
- Use concrete values: "Outside: `time.time()` → `1000.0`. Inside patch: `time.time()` → `MagicMock`."

This prerequisite must be confirmed BEFORE explaining why `now = time.time()` must be called outside.

**4. Is there an ambiguous reference?**
- Re-read your explanation for: "it", "the server", "the system", "the model", "the node"
- Every pronoun must be explicit. Replace all ambiguous references before continuing.
- Example from DNS/SSL: "it verifies that it owns the domain" — which "it"? Let's Encrypt? GitHub? The user? This caused a blocker.

---

## Phase 2: Explanation Protocol

Once the blocker is identified, explain using these rules:

### Rule 1: Explicit nouns only
Never use ambiguous pronouns. Name every entity explicitly.

Bad:  "It sends a token to verify it owns the domain."
Good: "Let's Encrypt sends a token to monireach.com. GitHub Pages must respond with that token to prove GitHub Pages controls monireach.com."

### Rule 2: Build from what the user already knows
Start from a fact they've confirmed they understand. Bridge to the new concept.

Example: User understood "DNS only = traffic goes directly to GitHub". Use that as the anchor:
"You know that DNS only means traffic goes directly to GitHub. Proxied means traffic goes to Cloudflare first. So when Let's Encrypt tries to reach GitHub at monireach.com, it hits Cloudflare instead."

### Rule 2b: Always use concrete values — NEVER abstract variables (CRITICAL for Monireach)

Monireach has concrete-dominant memory. Abstract placeholders like T, X, N, "some value", or "approximately" do NOT anchor in his head. They always cause a blocker.

**Every explanation must use exact, made-up-but-realistic values:**

Bad:  "window_start is approximately T, so you need time.time() to return T + 61"
Good: "Say the test starts at real clock = 1000.0. window_start is stored as 1000.0.
       The check is: time.time() - 1000.0 >= 60.
       Set mock_time.return_value = 1000.0 + 61 = 1061.0.
       Check becomes: 1061.0 - 1000.0 = 61 >= 60 ✅"

**Rule:** Before using any variable name in an explanation, substitute it with a real number first. Once the concrete example clicks, you may generalize.

**When to apply:** Always — timestamps, counts, IDs, indices, offsets, sizes, thresholds. Any number that could be concrete, make it concrete.

### Rule 3: One concept at a time
If the explanation requires 3 sub-concepts, explain sub-concept 1, confirm it clicked, then move to sub-concept 2.

### Rule 7: After the concept clicks — compress it into a memorizable rule + speaking phrases

Once Monireach confirms he understands, always produce three things in this order:

**1. The rule** (for applying the concept without thinking):
- One sentence, no vagueness
- Mechanical: he can apply it without judgment or re-reading the explanation
- Not from any framework docs — it's a personal learning aid, not a citation

Test the rule with one counter-example to make sure it doesn't overgeneralize. If it breaks, tighten it. If it holds, move on.

**2. "Say it" phrase** (for describing the concept in conversation):
- One natural English sentence — how Monireach would explain this concept out loud to a colleague or interviewer
- Model the cadence: "X means that...", "X is the idea that...", "When you see X, it means..."
- Must be speakable — not a technical note, not a definition from a textbook

**3. "Defend it" phrase** (for justifying a decision in conversation):
- One sentence following the pattern: "I used/added/chose X because Y" or "Without X, Y would happen"
- Y must be a concrete consequence — never "it's best practice" or "it's important"
- This is what Monireach says when an interviewer or colleague asks "why did you design it this way?"

Present all three together:
```
Rule:     [one-sentence mechanical rule]
Say it:   [natural English description, speakable out loud]
Defend it: [justification with a concrete consequence]
```

**Example (2026-03-27 — SQLAlchemy `merge()`):**

Concept explained: detached ORM objects need `merge()` when used in a new session.

First attempt at a rule: *"If a SQLAlchemy ORM object is passed as a param, use `merge()` first."*

Counter-example that breaks it:
```python
def update_last_seen(db_session, user):  # user is a param
    user.last_seen = datetime.now()      # no merge needed — same session passed in
    db_session.commit()
```
`user` is a param but already attached to `db_session`. Merge is wrong here.

Missing condition: the rule only applies when the method opens its **own** `SessionLocal()`.

```
Rule:      If the method opens its own SessionLocal() AND receives an ORM object as a param → merge() first.
Say it:    "merge() is what you call when you have a SQLAlchemy object from one session and you need to use it inside a different session — it re-attaches the object so the new session can track it."
Defend it: "I called merge() before accessing the object because the object was created in a different session, and without it SQLAlchemy would raise a DetachedInstanceError when trying to load any lazy relationship."
```

**When Monireach has no idea to propose** (concept too abstract): skip waiting for his input. After explanation clicks, proactively produce all three yourself. Then show them together.

**When to apply:** Any time Monireach says "so the rule is..." or "can I say that..." — test it before confirming, then produce all three.

### Rule 4: Call out logical chains explicitly
When one thing causes another, write it as a chain — not prose.

Bad:  "The redirect loop happens because of the page rule conflicting with GitHub Pages."
Good:
```
User visits monireach.com
→ Cloudflare Page Rule: redirect to www.monireach.com
→ GitHub Pages custom domain is monireach.com
→ GitHub Pages redirects www back to monireach.com
→ loop
```

### Rule 5: Use tables for multi-scenario comparisons

When explaining a concept that has 3+ cases with 2+ dimensions (e.g., "when do you add this vs not"), always use a table — not bullet points, not prose.

**Why:** Bullet points force the reader to hold all prior bullets in working memory to compare. A table puts all cases side-by-side — comparison is visual and instant.

**When to apply:** Any time you find yourself writing "in case A... in case B... in case C..." — stop and convert to a table.

Example from docker-compose env vars session:
```
❌ Prose: "If it's a secret, add to docker-compose. If it's tunable, also add it. If the default is fine everywhere, skip it."
✅ Table:
| Case | .env | Default in config.py | docker-compose |
|------|------|----------------------|----------------|
| Secret | YES | NO | YES |
| Non-secret, tuned or differs per env | YES | Optional | YES |
| Non-secret, same everywhere | YES | YES | NO |
```

### Rule 5b: If explanation contradicts observable reality, stop
If the user says "but I saw X, and you're saying Y" — do NOT dismiss it. Trace back.
- Either: your explanation is wrong
- Or: there is a hidden step that explains why both X and Y are true

Example: "DNS check passed even though A records are still proxied." Rather than guess, admit uncertainty and investigate.

### Rule 6: Anchor-Point Protocol (CRITICAL — for multi-step flows)

Monireach thinks in **phases** connected by **anchor points**. An anchor point is the exact data object that exits one phase and enters the next. Without naming it, the chain breaks in his head.

**Structure every multi-step explanation like this:**

```
[Phase Name]
What happens here: 1-2 sentences max.
Anchor out: → [exact data object that exits this phase]

[Next Phase Name]
What happens here: receives [anchor], does X to it.
Anchor out: → [next data object]
```

**Rules:**
- Every phase gets a named label (Frontend, Wire, Backend, DB — or equivalent)
- Every transition names the anchor explicitly: what object/data leaves and enters
- Never say "then it gets processed" — say "the `KnowledgeBase` object exits the DB step and enters the Backend step"
- Never skip an intermediate form — if data changes from dict → Pydantic → JSON bytes, all three must be named
- Each phase block = 1-3 lines max. No padding.

**Bad (skips anchor, mixes phases):**
> "FastAPI receives the request and after processing returns a response with the entry data."

**Good (named phases, explicit anchors):**
```
[Backend]
FastAPI extracts `abc-123` from the URL as a plain string, converts it to `uuid.UUID` entry_id.
FastAPI calls db.get(KnowledgeBase, entry_id).
Anchor out: → SQL query string

[DB]
SQL runs: SELECT * FROM knowledge_base WHERE id = 'abc-123'. Returns a row.
SQLAlchemy maps the row to a KnowledgeBase Python object with attributes (.id, .entry, ...).
Anchor out: → KnowledgeBase object

[Backend]
FastAPI serializes KnowledgeBase object through KBEntryResponse → Python dict → JSON bytes.
Anchor out: → JSON bytes
```

**When to apply:** Any explanation involving data moving between systems, layers, or components — API request/response, database queries, authentication flows, Docker networking, ML pipelines.

---

## Blocker Type Reference

| Blocker Type | Symptom | Fix |
|---|---|---|
| Ambiguous reference | "Which 'it' do you mean?" | Replace all pronouns with explicit names |
| Contradicts known fact | "But before it worked without that!" | Acknowledge the contradiction, trace the timeline |
| Missing prerequisite | Explanation makes no sense at all | Stop, explain the prerequisite first |
| Logical gap | "I don't see how A leads to B" | Write it as an explicit cause-chain |
| Wrong mental model | User's internal model is incorrect | Surface it, correct it with a concrete example |

---

## Anti-Patterns to Avoid

- Never re-explain the same thing in different words without identifying which part failed
- Never say "as I mentioned earlier" — if they didn't understand it earlier, repeating it is useless
- Never stack multiple concepts in one response when one concept is already blocking
- Never assume the user's mental model matches yours — verify it
- Never guess when you're uncertain — say "I'm not certain, let me investigate" or "I don't know"
- Never make contradictory statements in the same explanation — e.g. "no restart needed" then "you still need a restart" in the same response. Before sending, re-read your explanation and check that every sentence is consistent with every other. If two things seem to contradict, resolve it explicitly before sending: "Both are true because X."
- Never list multi-case comparisons as prose or bullets when a table would make it instantly scannable — default to a table whenever there are 3+ cases with 2+ dimensions.

---

## After Concept Clicks: Pattern Identification (coding concepts only)

After producing Rule + Say it + Defend it (Phase 2 Rule 7), check if the concept is code-related.

**If yes:** identify which coding pattern this concept belongs to (if any), and state it explicitly:

```
Pattern: [Pattern Name]
This concept is part of the [Pattern Name] pattern — [one sentence: what the pattern solves and its standard structure].
```

**Examples:**
- Concept: exponential backoff → Pattern: **Polling Worker with Retry and Dead-Letter Queue**
- Concept: `merge()` on a detached ORM object → Pattern: **Session-Scoped Unit of Work**
- Concept: outbox pattern → Pattern: **Transactional Outbox**
- Concept: `SessionLocal()` context manager → Pattern: **Repository Pattern (DB session management)**

**If the concept is NOT part of a recognizable pattern** (e.g. a Python syntax rule, a one-off utility), skip this step. Not everything is a pattern.

**If it IS a pattern:** after the log-learning step, also propose logging to `coding_patterns.md` using category `Pattern`.

---

## After Concept Clicks: Offer Daily Learning Log

Once the concept is understood and the one-sentence rule is produced (Phase 2 Rule 7), run `/log-learning` — it will use the compressed rule as the draft entry and wait for "yes" / "skip".

---

## Generalization Note

This protocol applies to any technical field, not just software engineering:

- **Data Science**: "The model is overfitting" → which model? overfitting to what? what does overfitting mean to the user?
- **DevOps**: "The container can't reach the host" → which container? which host? what does "reach" mean here (ping? HTTP? port?)
- **Statistics**: "The p-value is significant" → significant compared to what threshold? who set that threshold? why?

The pattern is always the same: surface the exact broken assumption before explaining anything new.
