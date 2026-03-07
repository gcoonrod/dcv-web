# Feature Specification: Docs, Installation, & Quickstart (Phase 3)

**Feature Branch**: `003-docs-and-quickstart`
**Created**: 2026-03-06
**Status**: Draft
**Input**: Web Roadmap Phase 3 — Implement a documentation portal using Astro Content Collections to host the Installation guide, Quickstart, Configuration Schema, and Changelog.

## Clarifications

### Session 2026-03-06
- **Architecture**: The system MUST utilize Astro Content Collections (`src/content/docs/`).
- **Documentation Layout**: The system MUST implement `src/layouts/DocsLayout.astro` featuring a persistent left-hand sidebar for navigation and a main content area for the Markdown payload.
- **Syntax Highlighting**: The system MUST leverage Astro's built-in Shiki integration to provide build-time syntax highlighting for all code blocks (e.g., `bash`, `json`, `yaml`). This ensures zero client-side JavaScript is shipped for code styling.
- **Core Pages**: The initial content MUST include:
  1. `installation.md`: The `curl | bash` installation script and manual binary download instructions.
  2. `quickstart.md`: A step-by-step guide (`dcv init` -> `dcv fetch` -> `dcv analyze`).
  3. `configuration.md`: The JSON schema for `~/.dcv/config.json`, explaining sources and providers.
  4. `changelog.md`: A mirrored version of the CLI's changelog.
- Q: Mobile sidebar behavior on viewports < 768px → A: Collapse to top (sidebar stacks above content via CSS `flex-col`; no JavaScript, no hamburger toggle).
- Q: Copy to Clipboard button — in scope or deferred? → A: Explicitly out of scope for V1; deferred to a future enhancement.
- Q: `/docs` index route — 404, redirect, or listing? → A: 404 is acceptable. The nav links directly to `/docs/installation`; no special handling for the bare `/docs` route is required.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The 30-Second Install (Priority: P1)

As a developer convinced by the landing page, I want to click "Docs", find the installation command immediately, and copy it to my terminal.

**Why this priority**: This is the highest-value conversion moment — a user who lands on the docs site and can install the tool immediately is the entire purpose of the documentation portal. Failure here means losing the developer at the exact moment they are ready to act.

**Independent Test**:
1. Navigate to `/docs/installation`.
2. Verify the layout includes a navigation sidebar on the left and content on the right.
3. Verify the presence of a code block containing `curl -fsSL https://dcv.dev/install.sh | bash`.
4. Verify the code block is syntax-highlighted and visually distinct (e.g., darker background).

**Acceptance Scenarios**:

1. **Given** the user requests a docs route, **When** the page is served, **Then** Astro's dynamic routing (`[...slug].astro`) fetches the corresponding Markdown file from the `docs` collection.
2. **Given** the Markdown content, **When** the site is built, **Then** Astro renders it to HTML at build time, applying Shiki highlighting to code blocks.

---

### User Story 2 - Following the Quickstart (Priority: P1)

As a new user who just installed the binary, I want a linear guide showing me exactly which commands to run to get my first Markdown report.

**Why this priority**: Tied with US1 as the critical post-install funnel. A developer who installs but cannot complete the quickstart will churn. The quickstart is the product's first real impression.

**Independent Test**:
1. Navigate to `/docs/quickstart`.
2. Verify the document clearly separates the steps into headings (`## Step 1: Initialize`, `## Step 2: Fetch Data`, `## Step 3: Analyze`).
3. Verify text contrast meets WCAG AA (minimum 4.5:1) against the `dcv-bg` dark background.
4. Verify the sidebar clearly indicates that "Quickstart" is the currently active page.

**Acceptance Scenarios**:

1. **Given** the `DocsSidebar` component, **When** iterating over docs routes, **Then** it renders a link for each available document.
2. **Given** the current URL matches a sidebar link, **When** the page is rendered, **Then** that link receives an active Tailwind class (e.g., `text-dcv-accent font-bold`).

---

### User Story 3 - Mobile Documentation Reading (Priority: P2)

As a developer browsing on my phone during a commute, I want to read the configuration schema without having to scroll horizontally to see the code blocks.

**Why this priority**: A secondary but important quality-of-life requirement. Developer documentation is frequently read on mobile. Broken layouts damage trust in the tool's quality.

**Independent Test**:
1. Resize browser to 375px width.
2. Verify the sidebar collapses above the main content (stacked layout, no overlap).
3. Verify wide code blocks (`<pre>`) scroll horizontally within their container without breaking page layout.
4. Verify body text remains readable with no horizontal overflow.

**Acceptance Scenarios**:

1. **Given** a mobile viewport (< 768px), **When** the page loads, **Then** the `DocsLayout` MUST stack the sidebar above the main content using CSS `flex-col` — no JavaScript or hamburger toggle required.
2. **Given** a wide code block (`<pre>`), **When** the content exceeds viewport width, **Then** it MUST scroll horizontally within its container without affecting the page layout.

---

### Edge Cases

- What happens when a user navigates to `/docs` (no slug)? A 404 is acceptable — `/docs` is not a valid route. All navigation links directly to `/docs/installation`; no redirect or index page is required.
- What happens if a Markdown file is missing required frontmatter (`title`, `order`)? The Zod schema MUST fail the build with a descriptive error.
- What happens if a code block language is not supported by Shiki? Shiki gracefully falls back to plain text — no build error should occur.
- What happens when the docs sidebar has too many items to fit on one screen? The sidebar must scroll independently from the main content area.
- What happens if a user navigates to a non-existent doc slug? Astro's static generation produces a 404 page by default — this is acceptable behavior.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST configure `src/content/config.ts` defining a `docs` collection with a strict Zod schema (title, description, order).
- **FR-002**: System MUST implement `src/pages/docs/[...slug].astro` using `getStaticPaths` to generate all doc pages at build time.
- **FR-003**: System MUST implement `src/layouts/DocsLayout.astro` with a responsive layout: two-column (`flex-row`) on desktop (≥ 768px) and single-column (`flex-col`, sidebar stacked above content) on mobile — implemented with Tailwind CSS only, no JavaScript.
- **FR-004**: System MUST implement `src/components/DocsSidebar.astro` that iterates over all docs collection entries, sorted by `order`, and highlights the active route.
- **FR-005**: System MUST include baseline Markdown files: `installation.md`, `quickstart.md`, `configuration.md`, and `changelog.md` in `src/content/docs/`.
- **FR-006**: System MUST apply `@tailwindcss/typography` (`prose prose-invert`) to the Markdown content area for consistent typographic styling.
- **FR-007**: System MUST add a "Docs" link to the site navigation pointing to `/docs/installation`.

### Agent Directives & Constraints (DCV Web Constitution v1.0.0)

- **Rule I (Tailwind CSS Exclusivity)**: The documentation typography MUST be styled using `@tailwindcss/typography` (the `prose` plugin), customized to match the dark theme (`prose-invert`).
- **Rule III (Vanilla JS Preference)**: Copy to Clipboard functionality is explicitly out of scope for V1 and deferred to a future enhancement. No JS clipboard libraries are authorized if this is added later.
- **Rule IV (Asset Optimization)**: Do NOT install heavy client-side search libraries like Algolia or FlexSearch for V1. Rely on logical sidebar navigation.

### Key Entities

- **Doc Entry**: A Markdown file in `src/content/docs/` with frontmatter fields: `title` (string), `description` (string), `order` (number). Rendered as a full-page document via `DocsLayout`.
- **DocsSidebar**: A component that receives all doc entries sorted by `order` and the current page slug, rendering a nav list with active state highlighting.
- **DocsLayout**: A layout component wrapping all doc pages, composing the global `Layout`, the `DocsSidebar`, and the Markdown `<Content />` slot. Uses `flex-col md:flex-row` to collapse sidebar above content on mobile.

## Assumptions

- **Tailwind Typography**: The installation of `@tailwindcss/typography` is approved, as it is the industry-standard approach for styling raw HTML generated from Markdown with Tailwind CSS.
- **Hosting**: The generated URLs (e.g., `/docs/quickstart/index.html`) will map correctly to AWS S3 / CloudFront routing rules.
- **Shiki is bundled**: Astro 5.x bundles Shiki for Markdown code block highlighting by default — no additional package installation is required.
- **No authentication**: Documentation is entirely public. No login, gating, or role-based access is needed.
- **Changelog content**: The `changelog.md` will contain placeholder content for v1.0.0 — it is not dynamically fetched from the CLI repository.
- **No /docs index redirect**: The `/docs` route (no slug) may produce a 404; linking to `/docs/installation` explicitly from the nav avoids this.

## Success Criteria *(mandatory)*

- **SC-001**: Markdown files added to `src/content/docs/` automatically generate properly formatted, syntax-highlighted web pages at build time, with zero manual routing changes required.
- **SC-002**: The documentation pages achieve a Lighthouse performance score of 90+ due to the zero-JS static output. No client-side JavaScript is shipped by Phase 3 docs pages.
- **SC-003**: The mobile experience is seamless — all content is readable at 375px viewport width with no horizontal page overflow, and the sidebar collapses above content without any JavaScript.
- **SC-004**: A developer can navigate from the landing page to a working installation command in 2 clicks or fewer (Nav "Docs" link → Installation page with curl command visible above the fold).
