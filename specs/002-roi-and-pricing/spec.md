# Feature Specification: Differentiators, ROI, & Pricing (Phase 2)

**Feature Branch**: `002-roi-and-pricing`
**Created**: 2026-03-06
**Status**: Draft
**Input**: Web Roadmap Phase 2 — Implement the core marketing sections: an "Anti-Feature"
differentiation grid, an ROI demonstration section, and a transparent Major-Version Pricing
component, assembled sequentially below the existing Hero on the index page.

## Clarifications

### Session 2026-03-06

- **Section 1 — Anti-Feature Grid**: The system MUST implement a `FeatureGrid` component
  highlighting what `dcv` does *not* do (No Telemetry, No Manager Dashboards, BYO-LLM Key).
  Icons MUST be inline SVGs — no icon font libraries or external image requests.
- **Section 2 — ROI Section**: The system MUST implement an `RoiSection` component presenting
  a visual "Before → After" transformation: raw git commit input on the left, a STAR-formatted
  accomplishment bullet on the right.
- **Section 3 — Pricing**: The system MUST implement a `Pricing` component with two tiers:
  - **Free**: Local Git, Public GitHub, standard Markdown report generation.
  - **Pro**: Enterprise Fetchers (Jira, Linear, GH Enterprise, GitLab), HTML/LaTeX Exports,
    Interactive RAG (`dcv query`).
- **Perpetual License Model**: The Pro tier copy MUST state explicitly that the purchase is a
  perpetual license for the current Major Version (v1.x.x), including all minor updates and
  patches. A new license is required for the next major version.
- **Payment Gateway**: The Pro CTA button links to an external checkout page (Lemon Squeezy or
  Stripe). The Astro site does not handle cart or payment logic.

### Session 2026-03-06 (Clarify)

- Q: Should the Pro price be passed as an Astro prop from `index.astro` or stored as an editable constant inside `Pricing.astro`? → A: Astro prop from `index.astro` (e.g., `<Pricing proPrice="[PRICE]" />`), defaulting to `"[PRICE]"` if omitted.
- Q: What is the type of each element in `RoiExample.after.content[]`? → A: Labeled pairs — `{ label: string, text: string }[]` (e.g., `[{label: "Action", text: "..."}, {label: "Result", text: "..."}]`).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reading the Anti-Features (Priority: P1)

As a privacy-conscious developer evaluating `dcv`, I want to immediately see a clear list of
what the tool does *not* do, so I can confirm my company's proprietary code will never leave
my machine or appear in a vendor dashboard.

**Why this priority**: Privacy and trust are the top conversion blockers for a CLI tool that
reads git history. Establishing the "no cloud, no tracking" guarantee visually — before any
pricing is shown — removes the primary objection. Without this section, a skeptical developer
has no reason to scroll further.

**Independent Test**:

1. Navigate to the index page and scroll past the Hero.
2. Verify the presence of a multi-column differentiator grid (3 columns on desktop,
   collapsing to 1 on mobile).
3. Verify each card contains an inline SVG icon, a title, and a short description.
4. Confirm the grid cards cover: No Telemetry, No Manager Dashboards, and BYO-LLM Key.
5. Resize viewport to 375px and confirm single-column layout with no horizontal scroll.

**Acceptance Scenarios**:

1. **Given** the `FeatureGrid` component, **When** rendered, **Then** it displays at least
   three differentiator cards, each driven by a data array of `{ title, description, icon }`.
2. **Given** the layout, **When** viewed at any viewport, **Then** all cards use Tailwind
   utility classes and maintain the dark-theme aesthetic (`bg-dcv-bg`, `text-slate-200`).
3. **Given** the icons, **When** inspected in source, **Then** each is an inline SVG with an
   `aria-hidden="true"` attribute (decorative, not interactive).

---

### User Story 2 - Understanding the ROI (Priority: P1)

As a software engineer who struggles with self-promotion, I want to see a concrete, before-and-after
example of how `dcv` transforms raw commit data into a performance review bullet point, so I can
immediately understand the tool's practical value for my career.

**Why this priority**: Equal priority to US1 — this section converts skeptics into buyers. A
developer who understands "my git history → polished STAR bullet" in 10 seconds has a clear
mental model of the value exchange. Without this section, the tool sounds like another CV-builder.

**Independent Test**:

1. Scroll to the ROI section.
2. Verify a two-panel "Before → After" layout is present.
3. **Before** panel: Displays a raw git commit line in monospace font
   (`fix(cache): resolve race condition in redis worker`).
4. **After** panel: Displays a STAR-formatted bullet in prose font with **Action:** and
   **Result:** fields, demonstrating concrete impact language.
5. Verify the two panels are visually distinct (e.g., muted border, different background
   shade, different typography).

**Acceptance Scenarios**:

1. **Given** the `RoiSection` component, **When** rendered, **Then** it presents the raw input
   in a `<code>` or monospace-styled element and the polished output in a prose-styled element.
2. **Given** the visual design, **When** a developer views both panels, **Then** the contrast
   between raw/machine and polished/human-readable is immediately apparent.
3. **Given** the section heading, **When** rendered, **Then** it uses a semantic `<h2>` with
   the heading text "From Commits to Compensation".

---

### User Story 3 - Evaluating the Price (Priority: P1)

As a prospective buyer, I want to understand exactly what I get for free, what Pro costs, and
the terms of the license, without having to read a separate FAQ or legal document.

**Why this priority**: The pricing section is the final conversion step. Ambiguity about what
"perpetual" means or which integrations are Pro-only creates friction. Transparent, in-page
pricing copy eliminates the need for a support interaction before purchase.

**Independent Test**:

1. Scroll to the Pricing section.
2. Verify two distinct pricing cards are present: **Free** and **Pro**.
3. **Free** card: Lists local Git and public GitHub as included sources.
4. **Pro** card: Lists at minimum Jira, Linear, GH Enterprise, GitLab as enterprise fetchers;
   lists `dcv query` Interactive RAG; lists HTML/LaTeX export formats.
5. **Pro** card: Contains explicit perpetual license copy referencing `v1.x.x`.
6. **Pro** card: CTA button is visually prominent using the `dcv-accent` color.
7. Both cards are readable with JavaScript disabled.

**Acceptance Scenarios**:

1. **Given** the `Pricing` component, **When** rendered, **Then** two cards are visible side
   by side on desktop and stacked on mobile.
2. **Given** the Pro tier, **When** a visitor reads the card, **Then** they can determine
   price, included features, and license terms from the card alone.
3. **Given** the Pro tier copy, **When** rendered, **Then** it explicitly states
   "Perpetual License for v1.x.x — includes all minor updates and patches."
4. **Given** the Free tier, **When** rendered, **Then** it contains no CTA button — only a
   link to the install command or documentation.

---

### Edge Cases

- What if the Pro checkout URL is not yet configured? The CTA button MUST render as a
  visually complete element with an `href` placeholder (`#`), clearly marked in the source
  with a `TODO` comment. The page MUST NOT break.
- What if a visitor has JavaScript disabled? All three sections are purely static HTML/CSS —
  no JS is used. All content MUST be fully readable without JavaScript.
- What if a visitor views on a very narrow viewport (< 375px)? All grids and card layouts
  MUST use `min-w-0` and `overflow-hidden` to prevent layout breakage at extreme widths.
- What if a screen reader user navigates the pricing section? Each card MUST have a
  discernible heading (`<h3>`) so screen reader landmark navigation works correctly.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create `src/components/FeatureGrid.astro` rendering a responsive
  grid of differentiator cards driven by an internal data array.
- **FR-002**: System MUST create `src/components/RoiSection.astro` presenting a two-panel
  "Before → After" transformation with monospace input and prose output.
- **FR-003**: System MUST create `src/components/Pricing.astro` rendering Free and Pro
  pricing cards with feature lists and the Pro perpetual license statement. The component
  MUST accept a `proPrice?: string` prop (default: `"[PRICE]"`) passed from `index.astro`,
  so the price can be updated without modifying the component itself.
- **FR-004**: System MUST update `src/pages/index.astro` to import and render `FeatureGrid`,
  `RoiSection`, and `Pricing` sequentially below `<Hero />`.

### Agent Directives & Constraints (DCV Web Constitution v1.1.0)

- **Rule I (Tailwind CSS Exclusivity)**: All layout (grids, flex, spacing) MUST use Tailwind
  utility classes. No custom `<style>` blocks for layout or typography.
- **Rule IV (Asset Optimization)**: All icons MUST be inline SVGs copied directly into the
  component. No icon font libraries, no `<img>` tags referencing external icon URLs.
- **Rule V (Accessibility)**: The ROI Before/After panels and Pricing cards MUST use semantic
  heading hierarchy (`<h2>` for section, `<h3>` for cards) and accessible list structures
  (`<ul>`, `<li>`) for feature lists.

### Key Entities

- **Differentiator**: `{ title: string, description: string, icon: SVG string }` — one card in
  the anti-feature grid. Phase 2 requires at minimum: No Telemetry, No Manager Dashboards,
  BYO-LLM Key.
- **PricingTier**: `{ name: string, price: string, features: string[], cta: { label, href } }` —
  one pricing card. Phase 2 has exactly two tiers: Free and Pro. The Pro tier's `price`
  value is sourced from the `proPrice` prop on the `Pricing` component.
- **RoiExample**: `{ before: { label: string, content: string }, after: { label: string, content: { label: string, text: string }[] } }` —
  the static Before/After data driving the ROI section. Hardcoded for Phase 2. The `after.content`
  array contains one entry per STAR field (e.g., `Action`, `Result`), rendered as labeled prose pairs.

## Assumptions

- **Responsiveness**: Standard Tailwind breakpoints (`sm`, `md`, `lg`) are sufficient. No
  custom breakpoints required in Phase 2.
- **Payment Gateway**: The Pro CTA links to an external checkout page. URL is a placeholder
  (`#`) in Phase 2 — to be replaced when Lemon Squeezy or Stripe is configured.
- **Pro Price**: The actual price point is not defined in Phase 2. The Pricing component MUST
  render a `[PRICE]` placeholder or accept a prop, so it can be set without a code change.
- **Section order**: Anti-Features → ROI → Pricing is the mandated scroll order. This mirrors
  the objection-handling funnel: prove privacy → prove value → show price.
- **No navigation anchors**: Phase 2 does not add a sticky nav or section anchor links. That
  is deferred to a future phase.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A visitor reading only the anti-features section can identify at least three
  distinct privacy or autonomy guarantees without scrolling to the pricing section.
- **SC-002**: A prospective buyer can determine the Pro price, the included feature set, and
  the license terms from the pricing card alone in under 60 seconds (no external links required).
- **SC-003**: Adding the three new sections introduces zero additional client-side JavaScript —
  the browser network tab shows no new `.js` requests after the components are included.
- **SC-004**: All three sections are fully readable and navigable with JavaScript disabled in
  the browser.
