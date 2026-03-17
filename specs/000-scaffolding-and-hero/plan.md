# Implementation Plan: Scaffolding & Hero Section (Phase 1)

**Branch**: `001-scaffolding-and-hero` | **Date**: 2026-03-06 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-scaffolding-and-hero/spec.md`

## Summary

Scaffold a greenfield Astro 5 static site with Tailwind CSS v4 design tokens, global
developer-centric typography (Geist Variable + JetBrains Mono), and a Hero section using
a split-panel layout. The right panel renders a `TerminalMockup` component — a pure
HTML/CSS terminal chrome with a vanilla JS loop-with-pause typing animation demonstrating
`dcv` CLI commands. Build output is a `dist/` directory of pure static files (HTML + CSS +
minimal JS) suitable for deployment to AWS S3 + CloudFront.

## Technical Context

**Language/Version**: Node.js 20 LTS, TypeScript (strict, Astro default)
**Primary Dependencies**: Astro 5.18.x, @tailwindcss/vite (Tailwind CSS v4), Geist Variable font, JetBrains Mono font
**Storage**: N/A
**Testing**: Manual browser verification (SC-001 to SC-004 in quickstart.md)
**Target Platform**: Modern browsers (Safari 16.4+, Chrome 111+, Firefox 128+); AWS S3 + CloudFront
**Project Type**: Static web application (SSG)
**Performance Goals**: Animation cycle <=8s (SC-003); no large JS bundles on initial load
**Constraints**: `output: 'static'`; no SSR adapter; no Node server in production; vanilla JS only for interactions; Tailwind v4 CSS-first config
**Scale/Scope**: 1 page (index), 3 components (Layout, Hero, TerminalMockup), 1 styles entry point

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Principle / Rule | Status | Notes |
|---|---|---|---|
| Static output only | Core Principle I | PASS | `output: 'static'` explicit in `astro.config.mjs` |
| No SSR adapter | Core Principle I | PASS | No adapter in `astro.config.mjs` |
| JS-disabled fallback | Core Principle I | PASS | `<noscript>` / static initial HTML in TerminalMockup |
| Dark mode default | Core Principle II | PASS | `bg-dcv-bg (#0f172a)` on `<body>` |
| Monospace for terminal | Core Principle II | PASS | JetBrains Mono Variable via `font-mono` class |
| No executive jargon | Core Principle II | PASS | Copy uses "offline", "binary", "CLI" |
| Static `dist/` for S3 | Core Principle III | PASS | Build produces plain static files |
| No Node server in prod | Core Principle III | PASS | SSG only |
| Tailwind CSS only | Rule I | PASS | All styling via Tailwind utility classes |
| No CSS frameworks | Rule I | PASS | No Bootstrap, Material UI, etc. |
| style blocks only for keyframes | Rule I | PASS | Cursor blink uses `animate-pulse` (Tailwind); no custom style block needed |
| Island architecture | Rule II | PASS | TerminalMockup uses inline script; no `client:` directive needed |
| No global JS bundles | Rule II | PASS | Single inline script per component |
| Vanilla JS only | Rule III | PASS | No framer-motion, typed.js, React, Svelte, Vue |
| HTML/CSS terminal | Rule IV | PASS | Terminal built from div/span — no .gif/.mp4 |
| No raster assets for animation | Rule IV | PASS | Pure DOM manipulation |
| Semantic HTML | Rule V | PASS | section, figure, main, header used correctly |
| ARIA labels | Rule V | PASS | role="img" aria-label on TerminalMockup |
| WCAG AA contrast | Rule V | PASS | cyan-400 (#22d3ee) on slate-950 (#0f172a): 5.2:1 ratio |

**Result**: All 19 gates pass. No violations. No Complexity Tracking required.

**Note on FR-001/FR-003**: The spec referenced `@astrojs/tailwind` and `tailwind.config.mjs`.
Research (Phase 0) confirmed these are the legacy Tailwind v3 path. For new Astro 5 projects,
Tailwind v4 with `@tailwindcss/vite` is the official recommendation (as of Astro 5.2+). The
spirit of both requirements is satisfied — Tailwind CSS exclusivity is maintained; only the
integration mechanism differs. This is a spec assumption update, not a constitution violation.

## Project Structure

### Documentation (this feature)

```text
specs/001-scaffolding-and-hero/
├── plan.md              # This file
├── research.md          # Phase 0 output — all technology decisions with rationale
├── data-model.md        # Phase 1 output — component specs, tokens, animation state machine
├── quickstart.md        # Phase 1 output — step-by-step setup + SC validation checklist
├── contracts/
│   └── component-api.md # Phase 1 output — prop interfaces, rendered guarantees
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
src/
├── components/
│   ├── Hero.astro              # Split-panel Hero section
│   └── TerminalMockup.astro    # Animated CLI demo component
├── layouts/
│   └── Layout.astro            # Global HTML shell (fonts, meta, dark body)
├── pages/
│   └── index.astro             # Route: / — composes Layout + Hero
└── styles/
    └── global.css              # Tailwind v4 entry + @theme tokens

public/
└── favicon.svg                 # SVG favicon

astro.config.mjs                # output: 'static', @tailwindcss/vite plugin
package.json
tsconfig.json
```

**Structure Decision**: Single Astro project at repository root. No `src/backend` or
`src/frontend` split — this is a pure frontend SSG project. The Astro convention of
`src/pages/`, `src/layouts/`, and `src/components/` is followed exactly.

## Implementation Sequence

Build in this order. Each step references the document and section that contains the full
specification for that step. Do not skip ahead — each step's output is a dependency for
the next.

---

### Step 1 — Scaffold the Astro project

**What**: Run `npm create astro@latest` to initialize the project at the repo root.

**Reference**: `quickstart.md` Step 1

**Output**: `astro.config.mjs`, `package.json`, `tsconfig.json`, `src/pages/index.astro`

**Verify**: `npm run dev` starts without errors.

---

### Step 2 — Add Tailwind CSS v4

**What**: Run `npx astro add tailwind` to install `@tailwindcss/vite` and update
`astro.config.mjs`. Manually add `output: 'static'` if the wizard omits it.

**Reference**: `quickstart.md` Step 2 | `research.md` Decision 2

**Output**: `astro.config.mjs` with `@tailwindcss/vite` plugin and `output: 'static'`

**Critical check**: The config MUST use `vite.plugins: [tailwindcss()]`, NOT
`integrations: [tailwind()]` — the latter is the deprecated v3 path.

---

### Step 3 — Create `src/styles/global.css`

**What**: Create the Tailwind v4 CSS entry point defining the project design tokens.

**Reference**: `quickstart.md` Step 3 | `data-model.md` Design Token Schema |
`contracts/component-api.md` Contract 4

**Output**: `src/styles/global.css` with `@import "tailwindcss"` and `@theme` block
containing `--color-dcv-bg`, `--color-dcv-accent`, `--font-sans`, `--font-mono`.

**Note**: This file is the single source of truth for all design tokens. Do not define
color or font values anywhere else in the codebase.

---

### Step 4 — Create `src/layouts/Layout.astro`

**What**: Build the global HTML shell. Imports `global.css`, adds Google Fonts link tags,
applies dark-mode body classes, and exposes a default slot.

**Reference**: `data-model.md` Component Specifications / Layout.astro |
`contracts/component-api.md` Contract 1 | `quickstart.md` Step 4

**Props**: `title: string`, `description?: string`

**Body class**: `bg-dcv-bg text-slate-200 font-sans antialiased min-h-screen`

**Google Fonts href** (exact string, single link tag):
```
https://fonts.googleapis.com/css2?family=Geist:wght@300..900&family=JetBrains+Mono:wght@400;500;700&display=swap
```

**Verify**: `npm run dev` — page background renders as `#0f172a`, not white.

---

### Step 5 — Create `src/components/TerminalMockup.astro`

**What**: The most complex component. A self-contained terminal chrome with a vanilla JS
loop-with-pause typing animation. Must degrade gracefully with JS disabled.

**Reference**: `data-model.md` Component Specifications / TerminalMockup.astro
(exact DOM structure, animation state machine timing table, default command sequence) |
`contracts/component-api.md` Contract 3

**Props**: `commands?: CommandSequence[]`, `pauseDuration?: number` (default `2000`)

#### Passing Astro props into the inline script tag

In Astro, frontmatter variables cannot be referenced directly inside a `<script>` tag —
the script runs on the client while the frontmatter runs at build time. Use the
`define:vars` directive to serialize props from the server context into the script:

```astro
---
const { commands = DEFAULT_COMMANDS, pauseDuration = 2000 } = Astro.props;
---

<figure ...>
  <!-- terminal DOM here -->
</figure>

<script define:vars={{ commands, pauseDuration }}>
  // `commands` and `pauseDuration` are injected as const declarations here.
  // They are JSON-serialized at build time — no runtime prop passing.
</script>
```

`define:vars` serializes the values to JSON and injects them as `const` declarations at
the top of the script block. `CommandSequence[]` is fully JSON-serializable.

#### Animation skeleton

The state machine uses chained `setTimeout` (not `setInterval`) to avoid timing drift.

```js
// Inside: <script define:vars={{ commands, pauseDuration }}>

let cmdIndex = 0;

function runCycle() {
  const { input, output } = commands[cmdIndex];
  const inputEl = document.getElementById('term-input');
  const outputEl = document.getElementById('term-output');
  const cursorEl = document.getElementById('term-cursor');

  // TYPING_INPUT: append one character per tick
  let charIndex = 0;
  function typeChar() {
    if (charIndex < input.length) {
      inputEl.textContent += input[charIndex++];
      setTimeout(typeChar, 60);
    } else {
      showOutput(0);
    }
  }

  // SHOWING_OUTPUT: reveal one output line per tick
  function showOutput(lineIndex) {
    if (lineIndex < output.length) {
      const line = document.createElement('p');
      line.textContent = output[lineIndex];
      outputEl.appendChild(line);
      setTimeout(() => showOutput(lineIndex + 1), 300);
    } else {
      // PAUSED: hide cursor, hold final state
      cursorEl.style.display = 'none';
      setTimeout(clearAndAdvance, pauseDuration);
    }
  }

  // CLEARING: safe DOM removal, then advance to next command
  function clearAndAdvance() {
    inputEl.textContent = '';
    while (outputEl.firstChild) {
      outputEl.removeChild(outputEl.firstChild);
    }
    cursorEl.style.display = '';
    cmdIndex = (cmdIndex + 1) % commands.length;
    setTimeout(runCycle, 200);
  }

  typeChar();
}

runCycle(); // Astro defers scripts by default; DOM is ready at execution
```

**Verify**: Both demo commands animate through, pause ~2s, then replay. Disabling JS shows
the `<noscript>` fallback with static final-state content.

---

### Step 6 — Create `src/components/Hero.astro`

**What**: The above-the-fold split-panel section. Left: copy + CTA. Right: TerminalMockup.

**Reference**: `data-model.md` Component Specifications / Hero.astro |
`contracts/component-api.md` Contract 2

**Outer layout class**: `flex flex-col md:flex-row items-center gap-12 min-h-screen px-6 py-24 max-w-7xl mx-auto`

**Panel width**: Each panel `w-full md:w-1/2`. DOM order: copy panel first, terminal
panel second — so mobile single-column stack is copy-above, terminal-below.

**Copy (Phase 1 draft)**:
- H1: `"Let your work speak for itself."`
- Sub-headline: `"The offline, privacy-first, developer focused performance review prep and career reflection tool."`
- Descriptor: `"dcv reads your work output and generates a structured reports to help you reflect on your performance and prepare for reviews. No cloud, no accounts, no data leaving your machine."`
- CTA label: `"Install"`

**CTA code block** (exact command string):
```
curl -fsSL https://apps.microcode.io/dcv/install.sh | sh
```

**Verify**: At 375px — single column, no horizontal overflow. At 1280px — two columns,
copy left and terminal right both visible above the fold.

---

### Step 7 — Update `src/pages/index.astro`

**What**: Replace the scaffolded placeholder content with the Layout + Hero composition.
This is the complete file content for Phase 1 — nothing more.

```astro
---
import Layout from '../layouts/Layout.astro';
import Hero from '../components/Hero.astro';
---
<Layout title="dcv — The Developer CV Generator">
  <Hero />
</Layout>
```

**Verify**: `http://localhost:4321` renders the full Hero section inside the dark layout.

---

### Step 8 — Add `public/favicon.svg`

**What**: A minimal SVG favicon for the browser tab.

**Reference**: `data-model.md` Favicon Spec

**Verify**: Browser tab shows the icon after `npm run build && npm run preview`.

---

### Step 9 — Run the full validation checklist

**What**: Confirm all four success criteria pass.

**Reference**: `quickstart.md` Validation Checklist (SC-001 through SC-004)

All four criteria must pass before this branch is considered complete and ready for
`/speckit.tasks` sign-off.

---

## Complexity Tracking

> No constitution violations detected. This section is intentionally empty.
