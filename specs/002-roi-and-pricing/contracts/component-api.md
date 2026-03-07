# Component API Contracts: Differentiators, ROI, & Pricing (Phase 2)

**Branch**: `002-roi-and-pricing` | **Date**: 2026-03-06

These contracts define the public interface for each Phase 2 Astro component — their props,
rendering guarantees, and accessibility requirements. Implementation MUST satisfy all
contracts before the feature is considered complete.

---

## Contract 1: `FeatureGrid.astro`

**File**: `src/components/FeatureGrid.astro`
**Props**: None (all data is self-contained within the component)

### Rendering Contract

| Requirement | Expected Output | Spec Ref |
|-------------|-----------------|----------|
| Section wrapper | `<section aria-label="Why dcv">` or equivalent | Rule V |
| Section heading | `<h2>What dcv doesn't do</h2>` | FR-001, Rule V |
| Grid container | `<div class="grid grid-cols-1 md:grid-cols-3 gap-...">` | US1 test step 2 |
| Card count | Exactly 3 cards (No Telemetry, No Manager Dashboards, BYO-LLM Key) | FR-001 |
| Card structure | `<article>` or `<div>` with icon + `<h3>` + `<p>` | Rule V |
| Icon rendering | `<span set:html={item.icon} />` with `aria-hidden="true"` on the SVG | FR-001, US1 AS-3 |
| Theme | `bg-dcv-bg` page bg; card bg `bg-slate-800` or similar elevated dark | US1 AS-2 |
| Narrow viewport | All cards include `min-w-0 overflow-hidden` | Edge Case 3 |
| No JS | Zero `<script>` tags; fully readable with JS disabled | SC-004 |

### Acceptance Scenario Mapping

| Scenario | Test | Pass Condition |
|----------|------|----------------|
| US1-AS-1 | Inspect rendered HTML | `differentiators` array maps to exactly 3 card elements |
| US1-AS-2 | Inspect classes | `bg-dcv-bg` and `text-slate-200` present on card elements |
| US1-AS-3 | Inspect SVG source | Each `<svg>` has `aria-hidden="true"` attribute |

---

## Contract 2: `RoiSection.astro`

**File**: `src/components/RoiSection.astro`
**Props**: None (all data is self-contained within the component)

### Rendering Contract

| Requirement | Expected Output | Spec Ref |
|-------------|-----------------|----------|
| Section wrapper | `<section aria-label="ROI" >` or equivalent | Rule V |
| Section heading | `<h2>From Commits to Compensation</h2>` | US2 AS-3 |
| Layout | Two-panel `flex flex-col md:flex-row` or `grid grid-cols-1 md:grid-cols-2` | US2 test step 2 |
| Before panel heading | `<h3>` with label (e.g., "Raw Commit") | Rule V |
| Before panel content | `<code>` or element with `font-mono` class | US2 AS-1 |
| After panel heading | `<h3>` with label (e.g., "STAR Accomplishment") | Rule V |
| After panel content | `<dl>` with `<dt>` / `<dd>` pairs for each `{ label, text }` in `after.content` | Research Decision 3 |
| Visual distinction | Before/After panels MUST have different background shades or borders | US2 test step 5, AS-2 |
| No JS | Zero `<script>` tags; fully readable with JS disabled | SC-004 |

### Acceptance Scenario Mapping

| Scenario | Test | Pass Condition |
|----------|------|----------------|
| US2-AS-1 | Inspect HTML | Before panel uses `<code>` or `font-mono`; After uses `font-sans` prose |
| US2-AS-2 | Visual inspection | Panels are perceptibly distinct (background, border, or both) |
| US2-AS-3 | Inspect `<h2>` | Heading present and frames value proposition |

---

## Contract 3: `Pricing.astro`

**File**: `src/components/Pricing.astro`
**Props**:

```typescript
interface Props {
  proPrice?: string;  // Default: "[PRICE]"
}
```

### Rendering Contract

| Requirement | Expected Output | Spec Ref |
|-------------|-----------------|----------|
| Section wrapper | `<section aria-label="Pricing">` or equivalent | Rule V |
| Section heading | `<h2>Simple, Transparent Pricing</h2>` | Rule V |
| Card layout | `grid grid-cols-1 md:grid-cols-2` or `flex` equivalent | US3 test step 2 |
| Card headings | Each card has a `<h3>` (e.g., `<h3>Free</h3>`, `<h3>Pro</h3>`) | Edge Case 4 |
| Feature lists | `<ul>` + `<li>` per tier | Rule V |
| Free tier CTA | Text link or `<a>` to install docs — NO `<button>` | US3 AS-4 |
| Pro tier CTA | `<a href="#">` styled as prominent button using `bg-dcv-accent` color | US3 test step 6 |
| Perpetual license copy | Exact string: `"Perpetual License for v1.x.x — includes all minor updates and patches."` | US3 AS-3 |
| Pro price display | `proPrice` prop value rendered visibly in card | FR-003 |
| Pro CTA TODO | `<!-- TODO: replace href="#" with checkout URL when payment is configured -->` | Edge Case 1 |
| Index TODO | `<!-- TODO: replace proPrice in index.astro when price is set -->` in `index.astro` | Research Decision 4 |
| Narrow viewport | Cards include `min-w-0 overflow-hidden` | Edge Case 3 |
| No JS | Zero `<script>` tags; fully readable with JS disabled | SC-004 |

### Acceptance Scenario Mapping

| Scenario | Test | Pass Condition |
|----------|------|----------------|
| US3-AS-1 | Resize browser | Two cards visible side-by-side at `md:`; stacked below |
| US3-AS-2 | Read Pro card | Price, feature list, and license terms all present on card alone |
| US3-AS-3 | Inspect text | Exact perpetual license string present in Pro card |
| US3-AS-4 | Inspect Free card | No `<button>` element; only a text link or `<a>` to install/docs |

---

## Contract 4: `index.astro` Update

**File**: `src/pages/index.astro`

### Required Changes

```astro
---
import Layout from '../layouts/Layout.astro';
import Hero from '../components/Hero.astro';
import FeatureGrid from '../components/FeatureGrid.astro';
import RoiSection from '../components/RoiSection.astro';
import Pricing from '../components/Pricing.astro';
---

<Layout title="dcv — The Developer CV Generator">
  <Hero />
  <FeatureGrid />
  <RoiSection />
  <!-- TODO: replace proPrice when payment is configured -->
  <Pricing proPrice="[PRICE]" />
</Layout>
```

**Section order** is mandated by spec Assumptions: `Hero → FeatureGrid → RoiSection → Pricing`.
Do NOT reorder without explicit user approval.

### Rendering Contract

| Requirement | Expected Output | Spec Ref |
|-------------|-----------------|----------|
| Import order | FeatureGrid, RoiSection, Pricing imported in spec order | FR-004 |
| Render order | Same as import order, below `<Hero />` | FR-004, Assumptions |
| proPrice prop | Passed explicitly; TODO comment present | FR-003, Research Decision 4 |
| No new JS | `dist/` output contains no new `.js` file from Phase 2 components | SC-003 |
