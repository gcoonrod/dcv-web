# dcv-web Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-03-06

## Active Technologies

- Node.js 20 LTS, TypeScript (strict, Astro default) + Astro 5.18.x, @tailwindcss/vite (Tailwind CSS v4), Geist Variable font, JetBrains Mono Variable font (001-scaffolding-and-hero)

## Project Structure

```text
src/
├── components/     # Astro components (Hero.astro, TerminalMockup.astro)
├── layouts/        # Layout.astro (global HTML shell)
├── pages/          # index.astro (file-based routing)
└── styles/         # global.css (Tailwind v4 @theme tokens)
public/             # Static assets (favicon.svg)
astro.config.mjs    # output: 'static', @tailwindcss/vite
```

## Commands

```bash
npm run dev       # Start dev server at http://localhost:4321
npm run build     # Build static site to dist/
npm run preview   # Preview production build locally
```

## Code Style

Node.js 20 LTS, TypeScript (strict, Astro default): Follow standard conventions

## Recent Changes

- 001-scaffolding-and-hero: Added Node.js 20 LTS, TypeScript (strict, Astro default) + Astro 5.18.x, @tailwindcss/vite (Tailwind CSS v4), Geist Variable font, JetBrains Mono fon

<!-- MANUAL ADDITIONS START -->

## Constitution Rules (DCV Web Constitution v1.1.0)

The following rules are NON-NEGOTIABLE. Any deviation requires explicit user override.

- **Rule I — Tailwind CSS Only**: ALL styling MUST use Tailwind utility classes. No external
  CSS frameworks (Bootstrap, Bulma, Material UI). Custom `<style>` blocks only for keyframe
  animations.
- **Rule II — Island Architecture**: Any component requiring client-side JS MUST be an Astro
  Island (`client:load` or `client:visible`). No global JS bundles.
- **Rule III — Vanilla JS Preference**: Interactive elements MUST use plain `<script>` tags.
  Do NOT install framer-motion, typed.js, React, Svelte, or Vue for UI interactions.
- **Rule IV — Asset Optimization**: Terminal mockup MUST be built from HTML `div`/`span`
  elements. No .gif, .mp4, or raster animation imports. Use Astro's `<Image />` for photos.
- **Rule V — Accessibility**: Semantic HTML required (`<header>`, `<main>`, `<article>`,
  `<footer>`). All interactive elements need `aria-` labels. WCAG AA contrast required.

**Core constraint**: `output: 'static'` MUST remain set in `astro.config.mjs`. SSR adapters
are strictly prohibited.

**Design tokens** (do not rename without global find-and-replace):
- `dcv-bg` = `#0f172a` (page background)
- `dcv-accent` = `#22d3ee` (cyan-400, accent/highlight color)

**Governance**: If this file conflicts with `.specify/memory/constitution.md`, the
constitution governs. Keep this file in sync with the constitution when it is amended.
<!-- MANUAL ADDITIONS END -->
