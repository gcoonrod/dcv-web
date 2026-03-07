# Implementation Plan: Differentiators, ROI, & Pricing (Phase 2)

**Branch**: `002-roi-and-pricing` | **Date**: 2026-03-06 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-roi-and-pricing/spec.md`

## Summary

Implement three marketing sections below the existing Hero on the index page:
1. `FeatureGrid.astro` — Anti-feature differentiator grid (No Telemetry, No Manager Dashboards, BYO-LLM Key)
2. `RoiSection.astro` — Before/After ROI demonstration (raw commit → STAR-formatted bullet)
3. `Pricing.astro` — Two-tier pricing cards (Free + Pro perpetual license)

All components are purely static HTML/CSS — zero client-side JavaScript. The stack is fully
inherited from Phase 1. The only new authoring pattern is Astro's `set:html` directive for
rendering inline SVG strings stored in data arrays.

## Technical Context

**Language/Version**: TypeScript (strict, Astro default) — inherited from Phase 1
**Primary Dependencies**: Astro 5.18.x, @tailwindcss/vite (Tailwind CSS v4) — inherited from Phase 1
**Storage**: N/A — all content is hardcoded static data arrays within each component
**Testing**: Manual browser testing per Independent Test steps in spec.md; no test runner required
**Target Platform**: Static HTML/CSS; AWS S3 + CloudFront (same as Phase 1)
**Project Type**: SSG web application (Astro)
**Performance Goals**: Zero additional `.js` requests after all three components are included (SC-003)
**Constraints**: `output: 'static'` in `astro.config.mjs` unchanged; no SSR adapters; no icon font libraries
**Scale/Scope**: 3 new Astro component files + 1 page update (`index.astro`); ~4 files total

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Rule | Requirement | Status | Notes |
|------|-------------|--------|-------|
| Principle I — Zero-JS Default | All sections fully readable with JS disabled | ✅ PASS | Pure static HTML/CSS; no `<script>` tags in any Phase 2 component |
| Principle II — Developer-Centric Aesthetic | Dark theme, monospace for code, direct copy | ✅ PASS | `bg-dcv-bg`, `text-slate-200`, `font-mono` for Before panel |
| Principle III — Infrastructure Simplicity | `output: 'static'` unchanged | ✅ PASS | No new config changes; static build artifact only |
| Rule I — Tailwind CSS Exclusivity | All layout via Tailwind utility classes | ✅ PASS | Grid, flex, spacing, typography — all Tailwind |
| Rule II — Strict Island Architecture | No global JS bundles | ✅ PASS | No client-side JS at all; no `client:*` directives needed |
| Rule III — Vanilla JS Preference | N/A | ✅ N/A | No interactive elements in Phase 2 |
| Rule IV — Asset Optimization | Icons MUST be inline SVGs | ✅ PASS | SVG strings stored in data array, rendered via `set:html` |
| Rule V — Accessibility & Semantics | `<h2>` sections, `<h3>` cards, `<ul>`/`<li>` feature lists | ✅ PASS | Heading hierarchy enforced per spec FR and edge cases |

**Gate result: PASS** — No complexity violations. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/002-roi-and-pricing/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── component-api.md
├── checklists/
│   └── requirements.md  # Already complete (PASS)
└── tasks.md             # Phase 2 output (/speckit.tasks — not created here)
```

### Source Code (repository root)

```text
src/
├── components/
│   ├── Hero.astro              # Phase 1 — unchanged
│   ├── TerminalMockup.astro    # Phase 1 — unchanged
│   ├── FeatureGrid.astro       # Phase 2 NEW — anti-feature differentiator grid
│   ├── RoiSection.astro        # Phase 2 NEW — before/after ROI demonstration
│   └── Pricing.astro           # Phase 2 NEW — two-tier pricing cards
├── layouts/
│   └── Layout.astro            # Phase 1 — unchanged
├── pages/
│   └── index.astro             # Phase 1 — updated to import and render Phase 2 components
└── styles/
    └── global.css              # Phase 1 — unchanged (no new tokens needed)
```

**Structure Decision**: Flat `src/components/` directory (same as Phase 1). All Phase 2 components
are self-contained Astro files with their data arrays defined in the component frontmatter.
No sub-directories, no shared utility files — each component owns its own content.

## Complexity Tracking

No constitution violations — table omitted.

## Phase 0: Research

See [research.md](./research.md) for full findings. Summary:

- **Astro `set:html` for SVG**: Chosen approach for rendering raw inline SVG strings stored
  in data arrays. Safe because SVGs are author-controlled (not user input).
- **Tailwind v4 grid patterns**: `grid grid-cols-1 md:grid-cols-3` for FeatureGrid;
  `grid grid-cols-1 md:grid-cols-2` for Pricing cards.
- **STAR content rendering**: `<dl>` / `<dt>` / `<dd>` semantic structure for labeled
  After-panel pairs, styled with Tailwind prose classes.

## Phase 1: Design Artifacts

See linked files for full specifications:

- [data-model.md](./data-model.md) — Entity definitions for `Differentiator`, `PricingTier`, `RoiExample`
- [contracts/component-api.md](./contracts/component-api.md) — Component prop contracts and rendering rules
- [quickstart.md](./quickstart.md) — Integration scenarios and browser verification steps

## Implementation Steps (for /speckit.tasks)

Phase breakdown for task generation. Each step lists the artifact sections the implementing
agent MUST consult before writing code for that step.

1. **Setup**
   - Run `npm run build` and confirm Phase 1 still produces zero errors and the `dist/`
     directory contains no unexpected `.js` files beyond the inlined TerminalMockup script.
   - Read current `src/pages/index.astro` to establish the import baseline before modification.
   - *Artifacts*: none (baseline verification only)

2. **FeatureGrid component** (US1 P1) — `src/components/FeatureGrid.astro`
   - Data: copy the exact `differentiators` array (including SVG strings) from
     `data-model.md §Entity: Differentiator → Phase 2 required instances`.
   - SVG rendering: use `set:html` pattern from `research.md §Decision 1`.
   - Grid classes: use `grid grid-cols-1 md:grid-cols-3` per `research.md §Decision 2`.
   - Full rendering requirements (section wrapper, heading, card structure, theme, narrow
     viewport safety classes): `contracts/component-api.md §Contract 1`.
   - Heading text: exact string `"What dcv doesn't do"` — no substitution.

3. **RoiSection component** (US2 P1) — `src/components/RoiSection.astro`
   - Data: copy the exact `roiExample` object from
     `data-model.md §Entity: RoiExample → Phase 2 hardcoded instance`.
   - After-panel structure: `<dl>` / `<dt>` / `<dd>` per `research.md §Decision 3`
     (includes exact Tailwind class example for `<dt>` and `<dd>`).
   - Full rendering requirements (layout, panel headings, visual distinction, Before
     panel `<code>` element): `contracts/component-api.md §Contract 2`.
   - Heading text: exact string `"From Commits to Compensation"` — no substitution.

4. **Pricing component** (US3 P1) — `src/components/Pricing.astro`
   - Props: `proPrice?: string` defaulting to `"[PRICE]"` per `research.md §Decision 4`.
   - Data: copy Free and Pro tier feature arrays and CTA objects from
     `data-model.md §Entity: PricingTier → Phase 2 instances`.
   - Perpetual license copy: exact string `"Perpetual License for v1.x.x — includes all
     minor updates and patches."` — must appear as visible card copy (not only in features list).
   - Pro CTA TODO comment: exact text from `contracts/component-api.md §Contract 3 →
     Pro CTA TODO` row.
   - Full rendering requirements (card layout, headings, feature lists, Free vs Pro CTA
     distinction, narrow viewport classes): `contracts/component-api.md §Contract 3`.
   - Heading text: exact string `"Simple, Transparent Pricing"` — no substitution.

5. **Assembly** (FR-004) — `src/pages/index.astro`
   - Replace existing file content with the exact code block in
     `contracts/component-api.md §Contract 4 → Required Changes`.
   - Section order is mandated: `Hero → FeatureGrid → RoiSection → Pricing`.
   - Index TODO comment: `<!-- TODO: replace proPrice when payment is configured -->` MUST
     be present adjacent to `<Pricing />`.

6. **SC-003 verification** (build check)
   - Run `npm run build`.
   - Open DevTools Network tab, filter by JS, hard-reload the preview.
   - Confirm no new `.js` requests appear beyond those present after Phase 1.
   - Expected: `dist/_astro/` contains only CSS; the TerminalMockup script remains inlined.
   - *Artifacts*: `quickstart.md §Scenario 5` for exact verification steps.

7. **Polish** — browser verification against all acceptance scenarios
   - Follow all 5 scenarios in `quickstart.md` in order.
   - Verify JS-disabled (`quickstart.md §Scenario 4`) and narrow viewport (`quickstart.md
     §Scenario 1–3` resize steps).
   - Confirm SC-001–SC-004 all pass before marking the feature complete.
