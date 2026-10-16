# Plain Language

**TRIGGER:** every message to the user, and every document a person will read.

The reader is not an expert in the topic and reads English as a second language. He cannot ask the text what it meant. So each sentence must be understood on the first read.

Sources. ISO 24495-1:2023 (plain language) has four principles: the reader gets what he needs (**relevant**), can find it (**findable**), can understand it (**understandable**), and can act on it (**usable**) — https://www.iplfederation.org/iso-standard/. ASD-STE100 Simplified Technical English gives the sentence rules in §4 — https://en.wikipedia.org/wiki/Simplified_Technical_English, https://asd-ste100.org/about_STE.html.

Word choice is in `response-style.md` §1.3. Length limits are in §1.1. This file owns everything else about how a message reads.

---

## §1 Relevant — print only what he needs

```
KEEP:  the answer he asked for
       a decision he must make
       a failure
       a result, with its number

DO NOT PRINT:
  - progress narration ("Now I will read X", "Let me check Y")
  - a status list he has already seen
  - a "still open" list where no item needs his decision now
  - confirmations he did not ask for ("I also checked Z, it is fine")
  - a preamble, his question restated, a closing summary
  - a closing offer longer than one line
```

The first word of the message is the answer's first word.

## §2 Findable — the answer first

- The first sentence is the answer, or the decision he must make.
- Use a vertical list for three or more steps or parallel items.
- A paragraph has six sentences or fewer.

## §3 Understandable — the full picture (来龙去脉)

When you describe a situation, a problem, or a decision he did not follow step by step, open with three short sentences:

```
1. BEFORE  — what happened, or what the state was.
2. NOW     — what is happening now.
3. MATTERS — what this changes for him.
Then the detail.
```

Name every thing in full the first time: what it is and which file it is in. Never use a label you made up ("the ranking rule", "row 46", "Bucket A") as if he knows it.

## §4 Understandable — sentences (from STE)

- One idea in each sentence. One instruction in each sentence.
- An instruction has 20 words or fewer. A description has 25 words or fewer.
- Active voice. Say who does the action: "I deleted the branch", not "the branch was deleted". Use the passive only when nobody knows who did it.
- One word, one meaning. Choose one name for each thing and keep it for the whole message. Do not change words for variety ("adapter", then "LoRA file", then "weights").
- A noun stack has three words or fewer. "exam answer file" is fine. "v2 exam answer review sheet key" is not.
- Keep the small words: subjects, verbs, articles, and joining words (because, so, this means). No telegraph style such as "Fixed. Pushed. 3 left."

## §5 Usable — he can act on it

Every request to him contains:

1. what to do, in one instruction,
2. where (the file path or URL),
3. the result he should see,
4. your recommended answer, so he can just say yes.

One decision in each question.

---

**TEST:** read the draft as if you had no memory of this session. Delete every line that is not on the §1 KEEP list. Then check: does the first sentence give the answer, does a situation start with BEFORE / NOW / MATTERS, and is any sentence over 25 words?

**ON FAIL:** rewrite before sending.
