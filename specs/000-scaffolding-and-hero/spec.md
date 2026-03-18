# Feature Specification: Scaffolding & Hero Section (Phase 1)

**Feature Branch**: `001-scaffolding-and-hero`
**Created**: 2026-03-06
**Status**: Draft
**Input**: Web Roadmap Phase 1 — Scaffold the Astro static site, integrate Tailwind CSS,
establish the global developer-centric typography/color palette, and build a high-conversion
Hero section featuring a terminal animation.

## Clarifications

### Session 2026-03-06

- **Build Target**: The Astro configuration (`astro.config.mjs`) MUST be explicitly set to
  `output: 'static'` to ensure a pure HTML/CSS build output suitable for AWS S3.
- **Tailwind Integration**: The project MUST use `@tailwindcss/vite` (Tailwind CSS v4). Design
  tokens are defined via `@theme` in `src/styles/global.css` — no `tailwind.config.mjs` needed.
  Custom color palette (`dcv-bg: #0f172a`, `dcv-accent: #22d3ee`) and font families are
  configured there.
- **Typography**: The layout MUST import a highly legible sans-serif font (like *Inter* or
  *Geist*) for standard prose, and a distinct monospace font (like *Fira Code* or *JetBrains
  Mono*) for all code and terminal references.
- **The Hero Component**: The landing page (`src/pages/index.astro`) MUST feature a prominent
  Hero section. This section includes direct copywriting ("Let your work speak for itself." /
  "The offline, privacy-first, developer focused performance review prep and career reflection
  tool.") and a simulated terminal window.
- **Terminal Animation**: The terminal window MUST feature a lightweight typing animation
  demonstrating `dcv` commands (e.g., typing `$ dcv init`, then showing a success output).
  This MUST be implemented in vanilla JavaScript or CSS keyframes to respect Rule III.
- Q: What should the terminal animation do after completing the full command sequence? →
  A: Loop with pause — complete the sequence, hold the final state for ~2 seconds, then restart.
- Q: Should Phase 1 include any visitor analytics or tracking? →
  A: Deferred — no analytics code in Phase 1; decision to be made in a later phase.
- Q: What layout structure should the Hero section use? →
  A: Split panel — headline copy (left ~50%) and terminal mockup (right ~50%), stacking to a
  single column on mobile viewports.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The Instant Page Load (Priority: P1)

As an impatient software engineer, I want the landing page to load instantly and not blind me
with a white background, so I immediately respect the tool's performance and design choices.

**Why this priority**: First visual impression determines whether a developer stays or leaves.
A dark, fast-loading page signals the project shares their values before a single word is read.

**Independent Test**:

1. Run `npm run build` followed by `npm run preview`.
2. Open `http://localhost:4321`.
3. Verify the background is `#0f172a` (the `bg-dcv-bg` design token — no white flash).
4. Verify the text is high-contrast off-white (`text-slate-200`).
5. Open Chrome DevTools → Network Tab. Verify no large JavaScript bundles (React, Vue) are
   downloaded to render the initial page.

**Acceptance Scenarios**:

1. **Given** the user navigates to the index page, **When** the page loads, **Then** the
   `Layout.astro` component applies global dark-mode body styles with no flash of white.
2. **Given** the page load, **When** text renders, **Then** the primary prose uses the
   configured sans-serif font, and code/terminal elements use the monospace font.

---

### User Story 2 - The Terminal "Show, Don't Tell" (Priority: P1)

As a skeptical developer, I want to see exactly what the CLI does before I consider running
`curl | bash` on my machine, so I can make an informed decision to download it.

**Why this priority**: Equal priority to US1 — the terminal demo is the core value proposition.
Without it, the page is just text; with it, the CLI's capability is self-evident.

**Independent Test**:

1. Navigate to the index page.
2. Observe the Hero section containing a visual mockup of a macOS/Linux terminal window.
3. Verify a cursor blinks and types out `$ dcv fetch --since 2025-01-01 --until 2025-06-30`.
4. Verify the terminal outputs simulated success lines.
5. Verify the animation completes the sequence, holds for ~2 seconds, then restarts cleanly.

**Acceptance Scenarios**:

1. **Given** the `Hero.astro` component renders, **When** the page is viewed, **Then** it
   displays a `<figure role="img">` element styled like a terminal window (dark gray background,
   top bar with traffic light buttons).
2. **Given** the terminal content area, **When** the page loads, **Then** a vanilla JavaScript
   `<script>` tag controls a typing effect, appending characters to a span over a set interval.
3. **Given** the animation completes, **When** the final state is reached, **Then** the display
   holds for approximately 2 seconds before resetting and replaying from the start.
4. **Given** the animation is running, **When** rendered, **Then** it uses the configured
   monospace font and does not cause perceptible CPU spike.

---

### Edge Cases

- What happens when JavaScript is disabled? The terminal mockup MUST still render as static
  content (e.g., showing the final command output without animation).
- What happens on mobile viewports? The Hero split panel MUST collapse to a single column
  (copy above, terminal below) using responsive Tailwind classes (e.g., `flex-col md:flex-row`).
- What happens if a font fails to load? System fallback fonts (`ui-sans-serif`, `ui-monospace`)
  MUST ensure the page remains readable with no layout shift.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The project MUST be initialized as an Astro site with the `@tailwindcss/vite`
  Tailwind CSS v4 integration installed and configured (via `npx astro add tailwind`).
- **FR-002**: The build MUST produce a purely static `dist/` directory with no server-side
  runtime dependency (`output: 'static'`).
- **FR-003**: Design tokens MUST be defined via the `@theme` directive in
  `src/styles/global.css`, including color tokens (`--color-dcv-bg: #0f172a`,
  `--color-dcv-accent: #22d3ee`) and font family aliases (`--font-sans`, `--font-mono`).
- **FR-004**: A global layout component MUST wrap every page, providing the `<html>` shell,
  `<head>` metadata (title, description, viewport), and global dark-mode body styles.
- **FR-005**: The index page MUST include a Hero section laid out as a split panel: headline
  copy and call-to-action on the left (~50%), terminal mockup on the right (~50%). On mobile
  viewports the two halves MUST stack vertically (copy above, terminal below).
- **FR-006**: The terminal mockup component MUST be self-contained, animated via vanilla
  JavaScript with a loop-with-pause behavior (complete → hold ~2s → restart), and degrade
  gracefully to static final-state content when JavaScript is disabled.

### Agent Directives & Constraints (DCV Web Constitution v1.1.0)

- **Rule I (Tailwind CSS Exclusivity)**: All layout, typography, and color styling MUST use
  Tailwind utility classes. No external CSS frameworks. Custom `<style>` blocks are limited to
  keyframe animation definitions only.
- **Rule II (Island Architecture)**: If the terminal animation component requires a `client:`
  directive, it MUST be a proper Astro Island. No global JS bundles.
- **Rule III (Vanilla JS Preference)**: The typing animation MUST be implemented as a plain
  `<script>` tag. Do NOT install `framer-motion`, `typed.js`, React, Svelte, or Vue.
- **Rule IV (Asset Optimization)**: The terminal mockup MUST be built from HTML `div`/`span`
  elements. No `.gif`, `.mp4`, or raster image imports for the animation.
- **Rule V (Accessibility)**: All interactive elements MUST have `aria-` labels. The terminal
  mockup MUST have `role="img"` or equivalent ARIA annotation with a descriptive label.

### Key Entities

- **Layout**: The global HTML shell wrapping all pages — owns `<head>`, fonts, and body styles.
- **Hero**: The above-the-fold landing section — split-panel layout (copy left, terminal right
  on desktop; stacked single column on mobile).
- **TerminalMockup**: The animated CLI demo component — self-contained, JS-optional,
  loop-with-pause behavior (types sequence → holds ~2s → resets).

## Assumptions

- **Copywriting**: Initial copy will be functional draft text ("Let your work speak for itself."
  / "The offline, privacy-first, developer focused performance review prep and career reflection
  tool.") — easily refined in HTML later.
- **Fonts**: Phase 1 uses Google Fonts CDN imports in `<head>` or system fallbacks
  (`ui-sans-serif`, `ui-monospace`) rather than self-hosted `.woff2` files. Self-hosting can
  be addressed in a later phase.
- **Node/npm**: The developer environment is assumed to have Node.js and npm available for
  `npm run build` and `npm run preview`. No CI pipeline is configured in this phase.
- **Analytics**: No analytics or tracking scripts will be included in Phase 1. The decision
  on whether to add privacy-respecting analytics (e.g., cookieless, self-hosted) is deferred
  to a future phase.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Running `npm run build` completes without errors and produces a `dist/` directory
  containing only static HTML, CSS, and asset files — no `.js` server bundles.
- **SC-002**: The landing page renders correctly on desktop (1280px+) and mobile (375px)
  viewports with no horizontal scroll or broken layout.
- **SC-003**: The terminal animation completes at least one full `dcv` command sequence
  (input → output → 2s hold → restart) within 8 seconds, with no CPU spike above ~5%
  (measured in DevTools Performance tab over a 10-second recording) and no layout jank.
- **SC-004**: The page is readable and the terminal mockup displays final-state content when
  JavaScript is disabled in the browser.
