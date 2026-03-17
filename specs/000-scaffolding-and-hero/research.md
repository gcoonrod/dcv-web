# Research: Scaffolding & Hero Section (Phase 1)

**Branch**: `001-scaffolding-and-hero` | **Date**: 2026-03-06

## Summary

All "NEEDS CLARIFICATION" items from Technical Context are resolved. This document records
the decisions reached, their rationale, and alternatives considered.

---

## Decision 1: Astro Version

**Decision**: Astro 5.x (v5.18.0 — latest stable as of 2026-03-06)

**Rationale**: Astro 5 is the current production-stable line. Astro 6 is in beta (February
2026) with breaking changes (dropped Node 18/20, removed `Astro.glob()`, upgraded Zod 4) and
is not appropriate for a new production site.

**Alternatives considered**:
- Astro 6 Beta — rejected: too many breaking changes, not yet production-stable.

---

## Decision 2: Tailwind CSS Version + Integration Method

**Decision**: **Tailwind CSS v4** with the official `@tailwindcss/vite` Vite plugin.

**Rationale**: Tailwind v4 was released as stable in January 2025. As of Astro 5.2+, running
`npx astro add tailwind` automatically installs the Tailwind v4 Vite plugin path. The
`@astrojs/tailwind` package (referenced in FR-001) is now a legacy v3-only integration — it
is deprecated for use with Tailwind v4. Using v4 with `@tailwindcss/vite` is the correct,
forward-looking choice for a new Astro 5 project.

**Impact on spec**: FR-001 referenced `@astrojs/tailwind` and FR-003 referenced
`tailwind.config.mjs` as the configuration file. With Tailwind v4:
- Configuration is **CSS-first**: custom tokens are defined via `@theme` directives in
  `src/styles/global.css`, not in a `.mjs` file.
- The `dcv-bg` and `dcv-accent` tokens from FR-003 are expressed as:
  ```css
  @theme {
    --color-dcv-bg: #0f172a;
    --color-dcv-accent: #22d3ee;
  }
  ```
- These are still Tailwind utility classes in the output (e.g., `bg-dcv-bg`, `text-dcv-accent`).
  The spirit of FR-001/FR-003 is satisfied; only the mechanism differs.

**Browser support**: Tailwind v4 requires Safari 16.4+, Chrome 111+, Firefox 128+. This is
acceptable for a developer-tool audience.

**Alternatives considered**:
- Tailwind CSS v3 + `@astrojs/tailwind` — rejected: legacy path, deprecated for new Astro 5
  projects. Would also require maintaining a `tailwind.config.mjs` for a single-page site.

---

## Decision 3: dcv-accent Color

**Decision**: `#22d3ee` — Tailwind `cyan-400`

**Rationale**: Analysis of 100+ developer tool landing pages (Evil Martians, 2025) confirms
that cyan/teal variants have overtaken pure terminal green as the dominant accent for modern
CLI/infrastructure tool marketing. Cyan reads as "electric/systems-level" rather than retro.
`cyan-400` achieves WCAG AA contrast ratio (>4.5:1) against the `#0f172a` dark background.

**Color tokens**:
- `dcv-bg`: `#0f172a` — Tailwind slate-950 (slightly richer than slate-900)
- `dcv-accent`: `#22d3ee` — Tailwind cyan-400

**Alternatives considered**:
- `green-400` (`#4ade80`) — Terminal green; strong heritage signal but reads as retro ANSI.
  Supabase uses this successfully. Rejected in favor of more contemporary cyan.
- `teal-400` (`#2dd4bf`) — Warmer alternative; rejected as it reads more "brand-y" than
  "terminal".

---

## Decision 4: Typography — Body Font

**Decision**: **Geist Variable** (by Vercel), loaded via Google Fonts CDN or Fontsource CDN.

**Rationale**: Geist was purpose-built for developer interfaces, combining influences from
Inter, SF Pro, and Univers. It has slightly rounder apertures and better letter-spacing for
code-adjacent contexts. For a developer-first CLI tool site in 2026, Geist differentiates
and signals craftsmanship; Inter is ubiquitous and reads as generic SaaS.

**Phase 1 import method**: Google Fonts CDN `<link>` in `Layout.astro` `<head>` (simpler,
no WOFF2 self-hosting infrastructure needed). Self-hosting deferred to a later phase.

**Alternatives considered**:
- Inter — rejected: too widely deployed to differentiate; reads as generic SaaS.
- System fonts only — rejected: reduces visual polish; acceptable fallback but not primary.

---

## Decision 5: Typography — Monospace Font

**Decision**: **JetBrains Mono Variable**, loaded via Google Fonts CDN.

**Rationale**: JetBrains Mono has a deliberately larger x-height, taller character forms, and
wider letter-spacing specifically optimized for extended reading in constrained environments.
At terminal mockup display sizes (typically 12–14px), it is measurably more legible than Fira
Code. Fira Code's primary differentiator (ligatures) is irrelevant for a marketing terminal
mockup.

**Alternatives considered**:
- Fira Code — rejected: ligature advantage irrelevant for terminal mockup; slightly less
  legible at small sizes.
- `ui-monospace` system default — rejected: inconsistent cross-platform rendering degrades
  the terminal mockup's visual quality.

---

## Decision 6: Terminal Animation — Loop-with-Pause Pattern

**Decision**: Vanilla JS `setTimeout`-based loop: type characters → hold final state ~2000ms →
clear and restart.

**Rationale**: Matches clarification answer from `/speckit.clarify` (2026-03-06). This pattern
requires no dependencies, is approximately 30 lines of vanilla JS, and is trivially
interruptible for the JS-disabled fallback path (static final-state via `<noscript>`-friendly
initial HTML).

**Alternatives considered**:
- CSS `@keyframes` only — rejected: character-by-character typing with variable content is
  impractical to drive purely in CSS without JS-generated style injection.
- `typed.js` library — rejected: violates Rule III (Vanilla JS Preference).

---

## Decision 7: Hero Layout

**Decision**: Split panel — copy left (~50%), terminal right (~50%), single-column stack on
mobile. Implemented with `flex-col md:flex-row`.

**Rationale**: Canonical developer SaaS landing page pattern. Allows copy and demo to coexist
above the fold on desktop (1280px+) while stacking cleanly on mobile (375px). Confirmed in
clarification (2026-03-06).

**Alternatives considered**:
- Centered single column — rejected: forces terminal below the fold on most desktop viewports.
- Terminal dominant (full-width at top) — rejected: reduces copy visibility above the fold.

---

## Resolved Unknowns Summary

| Unknown | Resolution |
|---|---|
| Astro version | 5.18.x (stable) |
| Tailwind integration | v4 + `@tailwindcss/vite` |
| `tailwind.config.mjs` vs CSS-first | CSS-first (`@theme` in `global.css`) |
| `dcv-bg` value | `#0f172a` (slate-950) |
| `dcv-accent` value | `#22d3ee` (cyan-400) |
| Body font | Geist Variable (Google Fonts) |
| Mono font | JetBrains Mono Variable (Google Fonts) |
| Animation end behavior | Loop with 2000ms pause |
| Hero layout | Split panel, stacks on mobile |
| Analytics in Phase 1 | None (deferred) |
