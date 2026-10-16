# About Monireach

**Last Updated:** 2026-07-26

---

## Quick Reference

### Who
- Name: Monireach. Male (he/him). Chinese-Cambodian.
- Role: AI Engineer (R4C) + AI researcher (elderly incident detection) + graduate student
- Goal: AI Engineering career (end-to-end ML systems)

### English — read `response-style.md` §1.3 for the enforceable rule

Roughly **B2 reading toward C1**. This is a measurement, not a label, and it comes from his own vocabulary study files: he keeps cards for *unraveled*, *phenomena*, *inevitable*, *rigorous*, and a confused-pair entry for *genuine vs authentic*.

**"Precision" means one unambiguous meaning per sentence. It does NOT mean rare vocabulary.**

Technical terms are wanted — he needs them for interviews. Rare general-English words are not. The countable rule lives in `response-style.md` §1.3.

### Brain & Learning
- **Concrete-dominant memory** — struggles with abstractions that arrive without an example first
- Math aptitude — mathematical explanations land well
- Learns by doing, not by reading code abstractly
- **Perfectionism/completionism trap:** wants to "understand everything first" before starting → paralysis
- **Simulate-before-writing trap:** mentally simulates the whole upstream pipeline before writing one line → unnecessary complexity. Fix: write the assertion/goal first, then trace back to what is needed.
- Python execution order: sometimes argues variable placement from high-level logic without tracing nested block execution step by step
- **Rule follower:** when a rule is written down concretely, he follows it without friction. When it is vague, he needs repetition. Write rules concretely.

### Portfolio-project philosophy
- **HARD RULE — never offer a shortcut, workaround, or "V1 acceptable" alternative when a proper standard solution exists.** Do not present Option A (standard) alongside Option B (shortcut) and let him choose. There is only one option: the standard. Offering a shortcut is a violation even if framed as "quick" or "frontend-only."
- **HARD RULE — never defer a standard.** "OK for now", "acceptable for V1", "upgrade later", "not an issue yet" are forbidden when the correct approach is known and buildable. If a dependency adds real experience + bounded cost + recoverable complexity → implement it now.
- Never say "NO" when you mean "not yet — when X happens, do Y."

### Communication Preferences
- Direct, factual responses. Challenge him when facts contradict what he says.
- What to leave out, and how to make a message easy to read: `plain-language.md`.
- Step-by-step breakdowns for code and config.
- **Trace-back approach works extremely well:** start from the error or goal, trace backwards to root cause. See `teaching-protocol.md` §4.1.
- **Multi-question handling:** one answer at a time, with space for follow-ups. See `question-handling.md` §12.

---

## Expertise Map

Use this to decide whether a topic is new to him. **If a topic appears here at Intermediate or above, do not explain it from scratch.** If it is absent, it is new — but still apply the tier limits in `response-style.md` §1.1.

### Programming & Tools
- **Python:** Intermediate-Advanced — FastAPI, RAG pipelines, SQLAlchemy, pytest TDD, production SaaS
- **Linux:** Intermediate — IBM DevOps courses; comfortable with CLI
- **Docker:** Intermediate — multi-env Dockerfiles, docker-compose (dev/staging/prod)
- **Git:** Used — feature branches, multi-env workflow
- **FastAPI:** Production — multi-tenant SaaS (smart_chatbot), 264/264 tests
- **AI Agent Engineering:** Claude Code + Codex + Gemini CLI; unified rule/skill system across all three

### Domains
- **ML Theory:** Classical ML complete (supervised + unsupervised). **Deep Learning not started.**
- **ML Engineering:** Production deployed — smart_chatbot (multi-tenant SaaS, 264 tests, live), R4C AI platform (6,000+ teachers, 132% search accuracy improvement)
- **DevOps:** Solid foundation — 10 IBM courses, Docker, Nginx, Kubernetes, CI/CD, microservices
- **AI Dev Process:** idea → `/ideation` → `/product-spec` → `/tc` → `/start-local-dev` → `/vibe-code`

### Career
- **Portfolio:** smart_chatbot — production multi-tenant SaaS (RAG, Qdrant, LiteLLM, OAuth+2FA, billing, 264 tests, live at monireach.com + HF Spaces)
- **Published:** Best Paper Award, ASIP 2025 — Asian Journal of Innovation and Policy (Privacy Governance in AI-Powered Elderly Monitoring)
- **Work:** AI Engineer at R4C/Tuktuk Charity (Aug 2025–Present)
- **Job seeking:** urgent, and picky — AI Eng / ML Eng / DevOps-AI only

---

## Referenced Files

- `deliverables/daily_learnings.md` (in My Drive/monireach/) — concepts mastered, spaced-repetition log with interview-ready Say it/Defend it lines. **Verified to exist.**

**If a file referenced anywhere is missing, say so in one line. Never assume its contents.**
