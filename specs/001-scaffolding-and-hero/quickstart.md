# Quickstart: Scaffolding & Hero Section (Phase 1)

**Branch**: `001-scaffolding-and-hero` | **Date**: 2026-03-06

Use this document to bootstrap the project from scratch and verify the Phase 1 deliverables.

---

## Prerequisites

- Node.js 20+ (LTS recommended): `node --version`
- npm 10+: `npm --version`
- Git on branch `001-scaffolding-and-hero`: `git branch --show-current`

---

## Step 1: Scaffold the Astro Project

```bash
# From the repo root (dcv-web/):
npm create astro@latest . -- --template minimal --install --no-git

# When prompted:
#   - Template: minimal
#   - Install dependencies: yes
#   - Initialize git: no (already initialized)
#   - TypeScript: yes (strict)
```

This creates `astro.config.mjs`, `package.json`, `tsconfig.json`, and `src/pages/index.astro`.

---

## Step 2: Add Tailwind CSS v4

```bash
npx astro add tailwind
# Accept all prompts — this installs @tailwindcss/vite and updates astro.config.mjs
```

Verify `astro.config.mjs` now contains:

```js
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  output: 'static',          // Must be explicit
  vite: {
    plugins: [tailwindcss()],
  },
});
```

---

## Step 3: Configure Design Tokens

Create `src/styles/global.css`:

```css
@import "tailwindcss";

@theme {
  /* Project color tokens */
  --color-dcv-bg: #0f172a;
  --color-dcv-accent: #22d3ee;

  /* Font families */
  --font-sans: "Geist Variable", "Geist", ui-sans-serif, system-ui, sans-serif;
  --font-mono: "JetBrains Mono Variable", "JetBrains Mono", ui-monospace, monospace;
}
```

Import this in `src/layouts/Layout.astro`:

```astro
---
import '../styles/global.css';
---
```

---

## Step 4: Add Google Fonts

In `src/layouts/Layout.astro` `<head>`:

```html
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
<link
  href="https://fonts.googleapis.com/css2?family=Geist:wght@300..900&family=JetBrains+Mono:wght@400;500;700&display=swap"
  rel="stylesheet"
/>
```

---

## Step 5: Create Components

Create the following files per `data-model.md` and `contracts/component-api.md`:

- `src/layouts/Layout.astro`
- `src/components/Hero.astro`
- `src/components/TerminalMockup.astro`
- `src/pages/index.astro`

---

## Step 6: Verify the Build

```bash
# Development server
npm run dev
# Open http://localhost:4321

# Production build
npm run build
# Inspect dist/ — should contain only index.html, _astro/*.css, _astro/*.js

# Preview production build
npm run preview
# Open http://localhost:4321
```

---

## Validation Checklist (SC-001 → SC-004)

Run through these after `npm run preview`:

### SC-001: Static Build

```bash
ls dist/
# Expected: index.html, _astro/, favicon.svg
# FAIL if: any .js files in dist/ root (server bundle indicator)

# Count JS files in _astro/ — should be small (animation only)
ls dist/_astro/*.js | wc -l
# Expected: 1–2 files maximum
```

### SC-002: Responsive Layout

1. Open DevTools → Toggle Device Toolbar.
2. Set viewport to **375px** (iPhone SE): verify single-column layout, no horizontal scroll.
3. Set viewport to **1280px** (desktop): verify split-panel (copy left, terminal right).

### SC-003: Terminal Animation

1. Navigate to `http://localhost:4321`.
2. Observe terminal mockup:
   - Characters type one by one into the `$ ` prompt.
   - Output lines appear line by line after input completes.
   - Final state holds for ~2 seconds.
   - Terminal clears and replays from the start.
3. Open DevTools → Performance tab → Record 10 seconds: confirm no CPU spike above ~5%.
4. Full cycle (input + output + pause + clear) should complete within 8 seconds.

### SC-004: JavaScript Disabled

1. DevTools → Settings → Debugger → Disable JavaScript.
2. Reload `http://localhost:4321`.
3. Verify: page text is readable, terminal mockup shows static final-state content
   (the `<noscript>` fallback or initial static HTML).

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| White flash on load | Missing `bg-dcv-bg` on `<body>` | Add class to `<body>` in `Layout.astro` |
| Fonts not loading | Missing `<link>` tags | Verify Google Fonts imports in `<head>` |
| Terminal animation jank | Using `setInterval` | Switch to chained `setTimeout` (see contracts) |
| JS bundle in `dist/` root | SSR adapter added | Remove adapter, confirm `output: 'static'` |
| Tailwind classes not purged | Wrong `content` glob | Ensure `@import "tailwindcss"` is in global.css |
