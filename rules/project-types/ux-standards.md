---
name: UX Engineering Standards
description: Mandatory UX standards for frontend projects — covers loading state granularity, static vs data-dependent rendering, persistent navigation, dropdown design, client-side session behavior, and cascading attention signals for service-disrupting states. Apply alongside frontend-standards.md.
type: project
---

# UX Engineering Standards

**ALL RULES BELOW ARE MANDATORY. Apply during implementation — do not defer to post-review.**

---

## §1. Read `frontend-standards.md` Fully Before Writing Any Frontend Code

- Read the entire file before starting any frontend task — not selected sections
- Apply every applicable rule during implementation, not after review
- If unsure whether a rule applies: it does

---

## §2. Identify Static vs Data-Dependent Content Before Writing Any Loading State

- Before writing a single shimmer or loading state, list every visible element and classify each: (A) static — value is known at build time, or (B) data-dependent — value comes from an API call
- Static elements must render immediately — never block them on auth resolution or data fetching. Examples: nav links, card titles, icons, table headers, section labels, action buttons
- Loading states must be scoped to the smallest unit of data that is unknown. Within a component that mixes static structure with dynamic values, only the specific data values shimmer — not the container, not the title, not the icon. Example: a stats card renders its title and icon immediately; only the number and its sub-label shimmer while the API responds
- A full-page or full-shell skeleton is almost always wrong. It is only appropriate when there is literally nothing static to show yet

---

## §3. Persistent Navigation Must Remain Visible While the User Scrolls

- Sidebars on desktop: `position: sticky`, `top: 0`, `height: 100vh`
- Navbars on desktop: `position: sticky`, `top: 0`
- On mobile where overlays are used: `position: fixed`
- Never leave persistent navigation as `position: static` — it will scroll out of view

---

## §4. Dropdown Menus Must Not Repeat Content Already Visible in Their Trigger

- If the trigger element already displays the user's name, email, or other identifying information, the dropdown must not repeat it as a header
- Only add a dropdown header when the trigger is compact (icon-only, avatar-only, or initials-only) and the header provides context the user cannot see from the trigger alone

---

## §5. Client-Side Session Checks Must Disable Automatic Revalidation Triggers

- When using SWR, TanStack Query, or any data-fetching library for session or auth state, disable focus-based and reconnect-based revalidation (`revalidateOnFocus: false`, `revalidateOnReconnect: false`)
- Session state is determined by the server cookie — browser focus events and reconnects do not change the session. Leaving these enabled creates race conditions during logout, tab-switching, and network interruptions, causing auth state flicker

---

## §6. Cascading Attention Signals for Service-Disrupting States

When a feature can enter a state where the user ignoring it will cause a service disruption — not merely a warning, but a concrete failure (e.g. zero balance cuts off the chatbot, an unindexed knowledge entry means the chatbot cannot find that content) — every navigation layer in the path to that feature must carry a visible attention signal.

**What qualifies:**
- Zero or critically low account balance (service stops working)
- Knowledge base entries that failed to reach the search index (chatbot cannot retrieve that content)
- A failed background job whose output the product actively depends on
- Do NOT apply to informational warnings or states the user can safely ignore

**Signal requirements:**
- The affected element itself must be visually distinct (badge, amber/red colour, icon)
- Every parent navigation item leading to that element (sidebar item, sub-menu, tab) must carry a dot or badge — even if the user has never visited that page
- If a global notification system (bell icon, notification inbox) exists, the signal must also appear there
- If no notification system exists yet, wire the sidebar/nav layer signal now and add a code comment marking where the notification entry point should connect when built

**Architecture requirement (applies to SWR and TanStack Query projects):**
- The attention state must be derived from a background data source — a polling SWR key or equivalent — not from local page state. A sidebar dot that only appears after the user visits the page defeats the purpose
- Expose derived booleans (e.g. `hasUnindexedEntries: boolean`) from a high-level provider or shared SWR key; never copy raw API responses into a global store (see `frontend-standards.md §4`)
- If computing the attention state requires data that is too heavy to fetch in the shell (e.g. full entry list), introduce a lightweight dedicated endpoint that returns only the boolean summary

**Validation checklist (run at PR review and standards audit):**
- [ ] Is the disruption genuine — does ignoring this state break a core feature?
- [ ] Does the sidebar/nav item for the affected page show a signal without the user visiting the page first?
- [ ] Is the attention state derived from a background poll, not local component state?
- [ ] If a notification system exists, is the signal wired to it?
- [ ] If no notification system exists, is the future hook point marked in a comment?
