# About Monireach

**Last Updated:** 2026-05-03

---

## Quick Reference (High-Priority Context)

### Personal
- Name: Monireach
- Role: AI Engineer (R4C) + AI researcher (elderly incident detection) + graduate student
- Goal: AI Engineering career (end-to-end ML systems)
- Relationship: Has a girlfriend; plans to marry (committed)
- Gender: Male (he/him)
- Girlfriend's family: US-based relatives (generous, culturally close)
- Cultural: Celebrates Chinese New Year (Chinese-Cambodian or culturally Chinese)

### Brain & Learning
- Concrete-dominant memory (struggles with abstractions without examples)
- Math aptitude (prefer mathematical explanations)
- Non-native English speaker (needs precision)
- Learning style: Concrete examples first → then generalize
- Learns by doing, not by reading code abstractly
- Perfectionism/completionism trap: tendency to want to "understand everything first" or "do everything comprehensively" before starting → leads to paralysis
- Simulate-before-writing trap: mentally simulates the entire upstream pipeline before writing a single line → leads to unnecessary complexity; fix by writing the assertion/goal first, then tracing back to what's needed
- Python execution order: sometimes argues variable initialization placement using high-level logic without fully tracing nested block execution step-by-step
- Rule follower (2026-04-02): when a rule is explicitly written down, follows it smoothly without friction; without explicit rules, needs more guidance and repetition
- Portfolio-project philosophy (2026-04-03, strengthened 2026-04-18): when building portfolio projects, learning and career ROI are first-class goals.
  - **HARD RULE — never offer a shortcut, workaround, or "V1 acceptable" alternative when a proper standard solution exists.** Do not present Option A (standard) alongside Option B (shortcut) and let Monireach choose. There is only one option: the standard. Offering a shortcut is a violation even if framed as "quick" or "frontend-only."
  - **HARD RULE — never defer a standard.** Phrases like "OK for now," "acceptable for V1," "upgrade later," or "not an issue yet" are forbidden when the correct approach is known and buildable. If a dependency adds real experience + bounded cost + recoverable complexity → implement it now, not later.
  - Never say "NO" when you mean "not yet — when X happens, do Y."

### Communication Preferences
- Direct, factual responses
- Challenge me when facts contradict what I say
- No fluff, no bloat
- Step-by-step breakdowns for code/config
- Trace-back approach works extremely well: start from the error/goal, trace backwards to root cause — applies to debugging, testing, and understanding system flows; used by professional developers (backwards TDD, root cause analysis)
- Multi-question handling: when asking multiple questions, needs each answered one at a time with space for extended follow-ups before the next is opened — dump all at once = missed learning opportunities

### Communication Struggles & Strategies
- See `~/.claude/profile/communication.md`

### Health
- See `~/.claude/profile/health.md`

---

## Expertise Map (Quick Lookup)

### Programming & Tools
- Python: Intermediate-Advanced — FastAPI, RAG pipelines, SQLAlchemy, pytest TDD, production SaaS
- R: [Not yet documented]
- Linux: Intermediate — IBM DevOps courses completed; comfortable with CLI
- Docker: Intermediate — multi-env Dockerfiles, docker-compose (dev/staging/prod)
- Git: Used — feature branches, multi-env workflow
- FastAPI: Production — multi-tenant SaaS (smart_chatbot), 264/264 tests
- AI Agent Engineering (2026-05-03): Claude Code (19 custom skills, 10 universal rules) + Codex + Gemini CLI — unified rule/skill system across all three agents; meta-skill: design, orchestrate, and maintain AI agents as dev tools

### Domains
- ML Theory: Classical ML complete (supervised + unsupervised); Deep Learning not started → see `ml_engineering.md`
- ML Engineering: Production deployed — smart_chatbot (multi-tenant SaaS, 264 tests, live), R4C AI platform (6,000+ teachers, 132% search accuracy improvement)
- DevOps: Solid foundation — 10 IBM courses, Docker, Nginx, Kubernetes, CI/CD, microservices
- AI Dev Process (2026-05-03): idea → `/technical-consultant` (TECH_STACK.md) → `/start-local-dev` (scaffold) → `/vibe-code` (TDD-driven autonomous dev); proven on Vichya (700+ line TECH_STACK.md from scratch)

### Career & Professional
- Portfolio: smart_chatbot — production multi-tenant SaaS (RAG, Qdrant, LiteLLM, OAuth+2FA, billing, 264 tests, live at monireach.com + HF Spaces) → see `portfolio.md`
- Published: Best Paper Award, ASIP 2025 — Asian Journal of Innovation and Policy (Privacy Governance in AI-Powered Elderly Monitoring)
- Work: AI Engineer at R4C/Tuktuk Charity (Aug 2025–Present); previous Chatbot Specialist at Proserve Performance ($1,200/month)
- Job Seeking: Urgently job searching; picky — AI Eng / ML Eng / DevOps-AI only → see `job_seeking.md`

---

## Detailed Context Files (Load as Needed)

When you need deep context, read these files:

- `~/.claude/profile/communication.md` - Communication struggles, interview/presentation strategies
- `~/.claude/profile/sizing.md` - Body measurements, size conversions, fit warnings
- `~/.claude/profile/ml_engineering.md` - ML skills, gaps, learning progress
- `~/.claude/profile/devops.md` - Docker, Nginx, deployment knowledge
- `~/.claude/profile/portfolio.md` - Projects, achievements, gaps to fill
- `~/.claude/profile/job_seeking.md` - Target roles, interview prep, challenges
- `~/.claude/profile/health.md` - Medical history, lifestyle, concerns
- `deliverables/daily_learnings.md` (in My Drive/monireach/) - Concepts mastered, spaced-repetition log with interview-ready Say it/Defend it lines

*Note: Files are created as context emerges from conversations.*

---

## How to Use This Profile

**Before responding to Monireach:**
1. Check Quick Reference for immediate context
2. Check Expertise Map for skill level in relevant domain
3. If needed, read detailed file for deep context
4. Respond with appropriate depth and style

**When Monireach calls `/update-profile`:**
- Analyze conversation for new/changed context
- Update this file and/or detailed files
- Keep entries brief, factual, dated
