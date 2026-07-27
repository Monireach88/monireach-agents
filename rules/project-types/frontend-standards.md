---
name: Frontend Engineering Standards
description: Mandatory frontend coding standards for this project — covers visual design, component architecture, state, interaction, accessibility, performance, forms, error handling, security, and testing. Replaces cheatsheet §1 and §2 reading in vibe-code sessions.
type: project
---

# Frontend Engineering Standards

**ALL RULES BELOW ARE MANDATORY. Apply during implementation — do not defer to post-review.**

**If a section does not apply to this project, output one line: `SKIPPED §N — reason`.** A section skipped with no line is a violation. Without this, a rule that genuinely does not apply and a rule you forgot look identical.

---

## §1. Code Quality (All Layers)

### At Design / Scaffold Time

- Cover edge cases and concurrent access in the test plan — not just the happy path
- All credentials and API keys in environment variables — never hardcoded; no secrets in component or utility files
- Irreversible operations (delete, reset, bulk update) must have confirmation dialog or rollback path before implementation
- Design loading state, error state, and empty state for every async operation before writing the implementation
- Wrap every external API call in error handling; partial failure must leave the UI in a recoverable state
- All config values in env vars (12-Factor App); nothing environment-specific hardcoded in components

### At Refactor Time

- Extract all magic values to named constants
- Each function has a single responsibility; names are self-documenting without comments
- All inputs validated; error responses shown to the user must not expose stack traces or internal details

---

## §2. Visual Design

- Use semantic color tokens only — never hardcode hex or RGB values in component files
- Body text minimum: 16px on mobile, 14px on desktop for secondary text
- Spacing follows 8pt grid — all spacing values must be multiples of 8px; 4px allowed only for micro-spacing
- Maximum 2 fonts per project; 4–6 distinct type sizes only
- Line length 60–80 characters for body text

---

## §3. Component Architecture

- Atoms have no business logic; pages own all data fetching
- Dependency direction: atoms never import molecules; lower-level components never import higher-level ones
- Components with more than 10 props must be split
- No prop drilling beyond 2 levels — use Context or lift state instead
- Never use `any` in props; all interfaces typed; exported when reused across files
- Display components (presentational) kept separate from container components (data-fetching)

---

## §4. State Management

- Local UI state → `useState`; server data → TanStack Query or SWR; never Redux or Context for server data
- API responses must not be copied into global stores; global stores hold UI state only
- Every async operation must explicitly handle all three states: loading, error, and empty
- After a mutation succeeds, invalidate all related queries; errors must always surface to the user

---

## §5. Interaction Design

- Animations must be ≤ 500ms; enter animations use `ease-out`; exit animations use `ease-in`
- Respect `prefers-reduced-motion` — disable or reduce animations when set
- Every interactive element must have distinct hover, active, and focus states
- Focus ring: 2px solid, ≥ 3:1 contrast ratio — never `outline: none` without a visible replacement
- Page-level loading → skeleton screen; single action in progress → spinner on the button (disabled); long async task → progress bar

---

## §6. Accessibility (WCAG 2.1 AA)

- Every focusable element must show a visible focus indicator at all times
- Use semantic HTML — never use ARIA to patch a `<div>` when a native element (`<button>`, `<input>`, etc.) exists
- One `<h1>` per page; heading levels must never skip (h1 → h2 → h3, never h1 → h3)
- Use `<button>` for actions and `<a href>` for navigation — never swap these
- All icon-only buttons must have `aria-label` describing the action
- Touch targets must be ≥ 44×44px — raw `<button>` elements must have `min-h-[44px] min-w-[44px] flex items-center justify-center`
- No content lost or broken at 320px viewport width

---

## §7. Responsive Design

- Mobile-first: base styles target mobile; breakpoints add larger-screen rules
- Minimum supported viewport: 320px
- Sidebars must collapse on narrow viewports; tables must scroll horizontally or switch to card view
- All `<img>` elements must have explicit `width` and `height` attributes to prevent layout shift (CLS)

---

## §8. Performance (Core Web Vitals)

- LCP element must be in the initial HTML; never `loading="lazy"` on the LCP image; use `fetchpriority="high"` on LCP image
- No JavaScript tasks > 50ms on the main thread; use `startTransition` for non-urgent state updates; virtualize long lists
- No content inserted above existing content after the page loads (causes CLS)
- Code-split by route; lazy-load heavy components; never `import *`

---

## §9. Data Display

- Text columns: left-aligned; numeric columns: right-aligned; use monospace font for numbers
- Default page size: 25 rows; use server-side pagination and filtering for datasets > 1,000 rows
- Every table and list must have three distinct empty states: (1) no data exists, (2) filter returned no results, (3) search returned no results — each with a different message
- Search and filter inputs must be debounced 200–300ms; active filter count must show as a badge; "clear all" action must be present when filters are active

---

## §10. Forms

- Labels must be positioned above fields (top labels); never use placeholder text as the only label
- Validation order: on blur for untouched fields; on change to clear an existing error; on submit for empty required fields
- Error messages placed next to the field; messages must be explicit ("Enter a valid email address"), never generic ("Invalid input")
- Errors must use color AND icon together — never color alone to communicate an error
- Destructive form submissions (delete, reset, bulk action) must require a confirmation dialog with an action-named button (e.g., "Delete entry", not "OK")

---

## §11. Navigation

- Admin dashboards use a sidebar (240–280px expanded, 56–64px icon-only collapsed)
- Maximum 7–8 sidebar items before introducing sub-navigation; maximum 2 nesting levels
- Active navigation state must use at least 2 visual cues (e.g., color + bold, or color + background fill)
- Breadcrumbs only when hierarchy is ≥ 3 levels deep; the last item (current page) is plain text, not a link

---

## §12. Error Handling & Feedback

- Toast auto-dismiss: 3–5 seconds for success, 5–8 seconds for warning; maximum 3 toasts visible simultaneously
- **Toasts must NOT be used for errors that prevent the user from completing a task** — use inline field error, inline banner, or modal instead
- Every page section must be wrapped in a React ErrorBoundary with a meaningful fallback message and a retry action
- Destructive actions must always be confirmed in a modal that has a named action button (e.g., "Reset to default") and a cancel option

---

## §13. Frontend Security

- Never use `dangerouslySetInnerHTML` without DOMPurify sanitization
- Auth tokens in HttpOnly cookies (backend-set only) — never in `localStorage` or `sessionStorage`
- API keys never in client-side code — server-side only
- No hardcoded business-specific or environment-specific values in component defaults (name, greeting, demo data) — violates 12-Factor App

---

## §14. Code Quality (Frontend)

- `strict: true` in `tsconfig.json`; never use `any`; use `unknown` and narrow explicitly
- Use Zod to validate all API responses — never use `as SomeType` casting on API data
- File names: kebab-case; components: PascalCase; hooks: camelCase; constants: SCREAMING_SNAKE_CASE
- Business logic in custom hooks, not page files
- Tests co-located: `component.test.tsx` beside `component.tsx`

---

## §15. Testing

- Unit tests (Vitest): utility functions and custom hooks
- Component tests (RTL): query by role, label, or text — never by class name or HTML tag
- Integration tests (MSW): mock at the network layer, not the module layer
- E2E tests (Playwright): critical user journeys only; run against real dev/staging server
- Run axe-core accessibility tests on every page and every complex component
- Every data-loading component must have tests for all 4 states: loading, success, error, and empty
