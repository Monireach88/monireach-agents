---
name: design-md
description: Use when the user invokes "/design-md" or asks to create a DESIGN.md for a frontend project. Fetches the latest Google Stitch DESIGN.md spec, audits the project's existing tokens, reconciles gaps, and writes the file as a single source of truth.
version: 1.0.0
---

# Design MD

Generate a `DESIGN.md` for the current frontend project using the canonical Google Stitch format.
Always fetch the live spec — never rely on a cached version of the format.

---

## When This Skill Applies

- User invokes `/design-md`
- User asks to "create a DESIGN.md", "document the design system", "write design tokens"
- User says "create a single source of truth for the design"

---

## Instructions for Agent

### Step 1: Fetch the Latest Spec (MANDATORY — always do this first)

The DESIGN.md format is versioned as "alpha" and evolves. Never use a memorized version of the schema.

Fetch the canonical spec from the GitHub raw README:

```
https://raw.githubusercontent.com/google-labs-code/design.md/refs/heads/main/README.md
```

Extract and hold in working context:
- All YAML keys and their allowed types
- Token-reference syntax (e.g. `{colors.primary}`)
- Required vs optional fields
- Valid component token properties (`backgroundColor`, `textColor`, `typography`, `rounded`, `padding`, `size`, `height`, `width`)
- Canonical section order for the markdown body

If the fetch fails, tell the user: "I can't reach the spec. Can you paste the contents of `https://github.com/google-labs-code/design.md/blob/main/README.md` into the chat?"

---

### Step 2: Audit the Project for Existing Tokens

Scan the project for any existing design token definitions. Check in this order:

1. `tailwind.config.js` / `tailwind.config.ts` — look for `theme.extend.colors`, `fontFamily`, `spacing`
2. Any inline HTML/CSS files (e.g. `index.html`) — grep for hardcoded hex values, `font-family`, `letter-spacing`, `font-size` declarations
3. CSS variables in `:root {}` blocks
4. Any existing `tokens.json` or `design-tokens.json`

**For colors:** Collect ALL hex values found — both those registered in the config and any appearing inline in markup. Note which are registered (have a token name) and which are not.

**For typography:** Collect all `fontFamily`, `fontSize`, `fontWeight`, `lineHeight`, `letterSpacing` values.

**For spacing:** Collect `padding`, `margin`, `gap` values — identify the base unit (4px? 8px?).

---

### Step 3: Identify and Resolve Token Gaps

After collecting all values, compare registered tokens against inline values found in markup.

**For every unregistered value (a hex, a font size, a spacing unit with no token name):**
- Classify it by role: what section or component uses it?
- Propose a name based on its role (e.g. `#c47254` used only in the contact section → `terracotta`)
- Present the full list of unnamed tokens to the user before writing anything:

```
I found 3 color values in the markup that aren't registered as tokens:
- #a68a61 — used as the intro section background → I'd name it `sand`
- #c47254 — used as the contact/CTA section background → I'd name it `terracotta`
- #fcfbf9 — used as the soft alternating section background → I'd name it `paper`

Do these names work, or would you like different ones?
```

Wait for user confirmation before proceeding.

**Image fallback colors** (colors used only as `background-color` behind `<img>` tags for broken-image states) are NOT brand tokens. Document them under a comment in the Colors section but do not promote them to the token system.

---

### Step 4: Surface IA and Content Decisions

Before writing, flag any mismatches between the design prototype and the live/target site that affect which pages, sections, or navigation items exist.

Common mismatches to check:
- Nav items in the prototype vs nav items documented for the target site
- Pages shown in the prototype vs pages the site actually needs (e.g. Products, Artist, Career)
- E-commerce elements present on the live site but absent from the prototype (cart, product pages)

Present each mismatch as a decision:

```
The prototype nav shows: Home · Portfolio · About Us · Blog · Contact
The target site nav is: Home · About Us · Products · Stories · Artist · Career · Contact Us + cart

Which should DESIGN.md use as the canonical navigation?
  A) Follow the prototype nav
  B) Preserve the target site nav
  C) Hybrid — tell me which items to keep
```

Wait for user decision before writing.

---

### Step 5: Write DESIGN.md

With the spec loaded, tokens resolved, and decisions confirmed — write `DESIGN.md` in the project root.

**Structure (always follow this order):**

```
---
[YAML front matter]
version: alpha
name: [Project Name]
description: >
  [One-paragraph design philosophy — brand character, visual language, audience]

colors:
  [All tokens — primary palette first, then role-based section colors, then neutrals]

typography:
  [All type styles — display, h1–h3, section-label, body, caption, nav, button]

rounded:
  [Only values actually used — skip if all sharp corners]

spacing:
  [Named scale — xs through 3xl, base unit noted in a comment]

components:
  [One entry per UI component — backgroundColor, textColor, typography, padding]
---

## Overview
[Design principles — 3–5 bullets. Brand character, not technical specs.]

## Colors
[Table: Token | Hex | Role]
[Separate note for image fallback colors — "not brand tokens"]

## Typography
[Table: Token | Family | Size | Weight | Notes]

## Layout
[Max-width containers table, grid specs, breakpoints table, spacing base unit]

## Elevation & Depth
[How depth is achieved — overlays, transforms, or shadows. Be explicit about what's intentional.]

## Shapes
[Border-radius table. If sharp throughout, explain why.]

## Components
[One subsection per component: nav, hero, section bands, cards, forms, footer]
[Each subsection: description + any non-obvious rules]

## Do's and Don'ts
[Paired list — one rule per line]
[Focus on: type rules, color usage, shape constraints, accessibility requirements]
```

**Token naming conventions:**
- Color tokens: semantic role names preferred (`sand`, `terracotta`, `paper`) over generic (`gray-100`)
- Typography tokens: scale names (`display`, `h1`, `body-sm`) not size values (`text-xl`)
- Spacing tokens: t-shirt sizes (`xs`, `sm`, `md`, `lg`, `xl`, `2xl`, `3xl`)
- Component tokens: kebab-case, noun-first (`nav-primary`, `button-outline`, `story-card`)

**Token reference syntax:** Use `{colors.token-name}` inside component definitions to reference other tokens. Never hardcode hex values inside component blocks.

**YAML rules (from spec):**
- Unknown section headings are preserved without errors
- Duplicate section headings cause file rejection — never repeat a heading
- Token references that don't resolve trigger linting errors — verify all references exist before writing

---

### Step 6: Confirm and Offer Tailwind Config

After writing `DESIGN.md`, tell the user:

```
DESIGN.md is written. 

Would you also like me to generate a `tailwind.config.js` from the tokens?
It will map all color, typography, and spacing tokens directly to Tailwind classes
so the config stays in sync with DESIGN.md.
```

If yes — generate `tailwind.config.js` with the `theme.extend` block populated from the DESIGN.md tokens.

---

## Anti-Patterns to Avoid

- Never skip Step 1. Do not write DESIGN.md using a memorized version of the schema.
- Never silently copy only the tokens from `tailwind.config` — always scan for inline hex values too.
- Never promote image fallback colors to brand tokens.
- Never write a component block that hardcodes a hex value — always use `{colors.token}`.
- Never write DESIGN.md before resolving all unnamed tokens and IA decisions with the user.
- Never add duplicate `##` section headings — the spec rejects the file if any heading repeats.
