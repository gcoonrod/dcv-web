# Quickstart: Verifying Phase 2 Components

**Branch**: `002-roi-and-pricing` | **Date**: 2026-03-06

This document provides browser-based verification steps for each Phase 2 component after
`npm run dev` or `npm run build && npm run preview`.

---

## Prerequisites

```bash
# On branch 002-roi-and-pricing, from repo root:
npm run dev
# Dev server at http://localhost:4321
```

---

## Scenario 1: FeatureGrid — Anti-Features (US1)

**Goal**: Confirm 3 differentiator cards render correctly across viewports.

### Steps

1. Open `http://localhost:4321` and scroll past the Hero section.
2. Locate the anti-features grid section.
3. **Desktop (≥ 768px)**: Verify 3 cards appear in a horizontal row.
4. **Mobile (375px)**: Open DevTools → Responsive mode → set width to 375px. Verify cards
   stack vertically with no horizontal scroll.
5. Inspect source: verify each `<svg>` inside a card has `aria-hidden="true"`.
6. Confirm all three card titles are present: "No Telemetry", "No Manager Dashboards",
   "BYO-LLM Key".

### Pass Conditions

- [ ] 3 cards visible on desktop in a 3-column grid
- [ ] Cards collapse to single column at 375px with no overflow
- [ ] Each card has an icon, `<h3>` heading, and description paragraph
- [ ] SVG icons have `aria-hidden="true"` in source

---

## Scenario 2: RoiSection — Before/After (US2)

**Goal**: Confirm the two-panel ROI layout renders with correct typography and content.

### Steps

1. Scroll to the ROI section (below FeatureGrid).
2. Verify a two-panel layout is present (side-by-side on desktop, stacked on mobile).
3. **Before panel**: Confirm the raw commit message
   `fix(cache): resolve race condition in redis worker` is displayed in monospace font.
4. **After panel**: Confirm two labeled entries are visible:
   - "Action" label with prose text about the Redis worker queue
   - "Result" label with prose text about P99 latency reduction
5. Confirm the Before and After panels have visually distinct backgrounds or borders.
6. Inspect source: verify `<h2>` section heading exists and `<dl>` / `<dt>` / `<dd>`
   structure is used for the After panel.

### Pass Conditions

- [ ] Two panels visible, side-by-side on desktop
- [ ] Before panel uses `font-mono` or `<code>` element
- [ ] After panel uses `font-sans` prose and `<dl>` structure
- [ ] Panels are visually distinct (background or border difference)
- [ ] `<h2>` heading present; `<h3>` headings on each panel

---

## Scenario 3: Pricing — Tier Cards (US3)

**Goal**: Confirm Free and Pro cards render correctly with all required content.

### Steps

1. Scroll to the Pricing section (below RoiSection).
2. Verify two cards are visible: "Free" and "Pro".
3. **Free card**:
   - Confirm feature list includes "Local Git repositories" and "Public GitHub repositories"
   - Confirm there is NO prominent button — only a text link or subtle CTA
4. **Pro card**:
   - Confirm the perpetual license string is present:
     `"Perpetual License for v1.x.x — includes all minor updates and patches."`
   - Confirm the price placeholder `[PRICE]` is visible (or real price if set)
   - Confirm the CTA button uses the `dcv-accent` cyan color (`#22d3ee`)
   - Confirm the CTA button `href` is `"#"` (inspect source)
   - Confirm `<!-- TODO: replace href="#" with checkout URL... -->` comment is in source
5. Resize to 375px: cards should stack vertically.

### Pass Conditions

- [ ] Two cards visible on desktop; stacked on mobile
- [ ] Free card: no `<button>` element present
- [ ] Pro card: perpetual license string exact match
- [ ] Pro card: CTA button visually uses accent color
- [ ] Pro card: CTA `href="#"` with TODO comment in source

---

## Scenario 4: JavaScript-Disabled (SC-004)

**Goal**: Confirm all three sections are fully readable with JS disabled.

### Steps

1. In Chrome DevTools → Settings → Debugger → check "Disable JavaScript".
2. Hard-reload `http://localhost:4321`.
3. Scroll through FeatureGrid, RoiSection, and Pricing.
4. Confirm all text, icons, and layout are intact.
5. Re-enable JavaScript after verification.

### Pass Conditions

- [ ] FeatureGrid renders all 3 cards with icons
- [ ] RoiSection renders both panels with full content
- [ ] Pricing renders both cards with all features and CTA button

---

## Scenario 5: Zero New JS Bundles (SC-003)

**Goal**: Confirm Phase 2 components introduce no new client-side JavaScript files.

### Steps

1. Run `npm run build` (production build).
2. Open DevTools Network tab → filter by "JS".
3. Hard-reload `http://localhost:4321` (or preview at `http://localhost:4322`).
4. Confirm the only `.js` files are the same ones present after Phase 1 (TerminalMockup
   animation script, inlined). No new `.js` files from FeatureGrid, RoiSection, or Pricing.

### Pass Conditions

- [ ] Network tab shows no new `.js` requests after Phase 2 components are added
- [ ] `dist/_astro/` directory contains only CSS (and the existing inlined script)
