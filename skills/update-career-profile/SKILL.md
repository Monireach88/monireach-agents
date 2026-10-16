---
name: update-career-profile
description: Update Monireach's career profile across CV, website, and LinkedIn when a new job, role change, or career event occurs. Reads context from user-provided text or files; rejects ambiguous input.
version: 1.0.0
---

# Update Career Profile

Update Monireach's public-facing career materials across three files when a new role or career change occurs.

## Trigger

User provides a new job, promotion, role change, or career update — either as raw text ("I started at X as Y") or as file paths (JD document, context file). The skill collects what's provided, derives what it can from sources, and stops on anything it can't.

## Files to Update

| File | Path |
|---|---|
| CV | `/Users/monireach/projects/portfolio/cv/Monireach_Tang_CV.html` |
| Website | `/Users/monireach/projects/portfolio/index.html` |
| LinkedIn | `/Users/monireach/Google Drive/My Drive/monireach/cv/linkedin_profile.md` |

---

## Step 1: Collect Input

The user provides context in one or both forms:

- **Raw text**: "I started at Manulife as Generative AI Specialist on June 2, 2026"
- **File paths**: a JD document, context file, or other source

Read any files provided. Extract everything that can be found.

---

## Step 2: Verify Completeness

For each field below, determine whether it can be **derived** from provided sources or **must be confirmed** by the user:

| Field | Rule |
|---|---|
| Company name | **Must confirm.** Cannot be guessed. |
| Title | **Must confirm.** Cannot be guessed. |
| Start date (month, year) | **Must confirm.** No JD tells you when someone started. |
| End date | **Must confirm** if role ended. "Present" if current. |
| Location (city, country) | **Must confirm.** Cannot be reliably derived. |
| Location type (on-site/hybrid/remote) | **Must confirm.** |
| Employment type (full-time/contract) | **Must confirm.** |

| Field | Rule |
|---|---|
| Responsibilities (3–5 bullets) | **Derive from JD** if provided, otherwise ask user for key points. |
| Skills (5–10) | **Derive from JD** and recommend. User confirms or tweaks. |
| Framing / tone | **Propose based on existing profile style.** User confirms. |
| Confidentiality restrictions | **Must confirm.** Ask if not stated. |

**If any "must confirm" field is missing and cannot be reliably derived → STOP and ask.** Do not guess. Do not proceed with incomplete hard facts.

**If "derive" fields are missing** → extract from JD or recommend based on the role. Present for confirmation.

---

## Step 3: Present Plan

Before touching any file, display exactly what will be added:

```
### Proposed Entry

**Company:** ...
**Title:** ...
**Dates:** ...
**Location:** ...
**Type:** ...

**Responsibilities:**
- ...
- ...

**Skills:** ...

**Files to update:**
1. CV → Work Experience section (or Volunteer Experience if unpaid)
2. Website → Experience section
3. LinkedIn → Experience section (or Volunteering if unpaid)
```

Also check: does any existing entry have "Present" as end date? If so, ask whether that role ended and needs an end date — two simultaneous "Present" roles on Work Experience can look like overemployment.

Wait for user confirmation. Do NOT edit files until confirmed.

---

## Step 4: Execute Edits

After confirmation, update all three files. Follow existing format conventions exactly.

### CV Format (`Monireach_Tang_CV.html`)

For paid employment, insert into `WORK EXPERIENCE` section as the first entry:

```html
<div class="experience-item">
    <h4>Company Name</h4>
    <p class="job-title">Title</p>
    <p class="date">Mon YYYY - Present | City, Country</p>
    <ul>
        <li>Responsibility bullet point</li>
        ...
    </ul>
</div>
<br>
```

For volunteer roles, use a separate `VOLUNTEER EXPERIENCE` section with title including "(Ad-hoc)" if part-time/occasional.

### Website Format (`index.html`)

Insert into `<section id="experience">` as the first entry:

```html
<div class="project-card">
    <div class="project-header">
        <span class="project-title">Company Name</span>
    </div>
    <p class="project-desc" style="margin-bottom: 0.5rem;">
        <strong style="color: var(--text);">Title</strong>
        <span style="color: var(--text-muted); font-size: 0.85rem;"> · Mon YYYY – Present · City</span>
    </p>
    <p class="project-desc">
        Short summary paragraph. ...
    </p>
</div>
```

Also update:
- `<title>` tag if role title changed
- Hero tag (`.hero-tag`) if employment status changed
- About section if current role should be mentioned

### LinkedIn Format (`linkedin_profile.md`)

Insert into `## Experience` as the first entry:

```markdown
### Company Name

- Title: Title
- Employment type: Full-time
- Start date: Month; Year: YYYY
- End date: Present
- Location: City, Country
- Location type: On-site
- Description:
  - Bullet point
  - Bullet point
- Skills:
  - Skill Name
  - Skill Name
```

For volunteer work, keep under `## Volunteering` section — do NOT add to Experience.

---

## Step 5: Sync Skills

When new skills are added to the LinkedIn entry, also update the skill sections in CV and website:

- **CV**: `TECHNICAL SKILLS` section — add skill badges to appropriate categories
- **Website**: `<section id="skills">` — add list items to appropriate groups

Only add genuinely new skills that aren't already listed. Don't duplicate.

---

## Step 6: Report

After all edits:

- List every file changed and what was added
- Offer to stage and commit (`git add -A && git commit`)
- Remind: LinkedIn profile must be updated manually on linkedin.com (the MD file is a reference, not auto-synced)

---

## Anti-Patterns

- **Never** guess hard facts (company, title, dates, location). Stop and ask.
- **Never** add a paid role and a volunteer role both as "Present" in Work Experience without clarifying the distinction.
- **Never** use project names or internal details if the user mentions confidentiality restrictions.
- **Never** change formatting — follow the existing patterns exactly.
- **Never** proceed without user confirmation after presenting the plan.
