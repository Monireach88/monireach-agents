---
name: update-profile
description: This skill should be used when the user asks to "update my profile", "update profile", "remember this about me", or invokes "/update-profile". Updates Monireach's personal profile based on current conversation context.
version: 1.0.0
---

# Update Profile

Updates Monireach's personal profile based on current conversation context.

## When This Skill Applies

- User says "update my profile", "update profile", "/update-profile"
- User says "remember this about me"
- Significant new context emerges about skills, health, preferences, goals, or life circumstances

## Instructions for Agent

### Step 1: Analyze Conversation
Look at the last 10-20 messages for:
- New expertise/skill level mentioned
- Learning progress or gaps identified
- Health updates or concerns
- Career/job seeking context
- Personal preferences or communication style
- Life circumstances that affect work/learning

### Step 2: Determine What Changed
Ask yourself:
- Is this high-priority context? → Update about-monireach.md
- Is this deep/detailed context? → Create/update detailed file
- Has a skill level changed? → Update expertise map
- Is this a preference? → Update quick reference

### Step 3: Update Files (CRITICAL: Keep Brief!)

**Writing style requirements:**
- Bullet points only, no paragraphs
- Facts only, no explanations
- Include date (YYYY-MM-DD) for time-sensitive info
- Maximum 3-5 bullets per topic
- Scannable in 5 seconds

**Example of GOOD entry:**
```markdown
## Python
- Level: Intermediate (2026-02-16)
- Focus: Data science (pandas, numpy), ML
- Gaps: Software eng patterns, advanced OOP
- Teach: Concrete examples first
```

**Example of BAD entry (TOO BLOATED):**
```markdown
## Python Skills
Monireach has intermediate Python skills. He primarily works with data science libraries and machine learning. He's not familiar with software engineering patterns. When teaching, always use concrete examples first.
```

### Step 4: Report Changes
Tell Monireach:
- What files were updated
- What new context was added
- Keep summary under 3 sentences

## File Structure

All paths below are under `AGENT_CORE`:

```
AGENT_CORE = <My Drive>/monireach/resources/agent_core
```

Use `AGENT_CORE`, **not** `~/.claude/...`. The two point at the same files, but only the Drive path is guaranteed writable — `~/.claude` is a bind mount that may not be in `additionalDirectories`.

**Centralized file (always loaded):**
- `AGENT_CORE/rules/universal/about-monireach.md`
- Update "Last Updated" timestamp
- Update relevant sections

**Detailed files (created as needed — the directory does not exist yet; create it on first write):**
- `AGENT_CORE/profile/ml_engineering.md`
- `AGENT_CORE/profile/devops.md`
- `AGENT_CORE/profile/portfolio.md`
- `AGENT_CORE/profile/job_seeking.md`
- `AGENT_CORE/profile/health.md`
- `AGENT_CORE/profile/learning_history.md`
- Create new files if needed (e.g., `python.md`, `relationships.md`)

**If you create any file here, add a pointer line to it under "Referenced Files" in `about-monireach.md`.** A profile file nothing points at will not get read.

## Anti-Bloat Checklist

Before writing, ask:
- [ ] Am I using bullet points?
- [ ] Am I stating facts, not explaining why they matter?
- [ ] Can someone scan this in 5 seconds?
- [ ] Did I include the date for time-sensitive info?
- [ ] Is this under 5 bullets per topic?

If NO to any → Make it briefer.
