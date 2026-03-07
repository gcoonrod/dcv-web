# Data Model: Scaffolding & Hero Section (Phase 1)

**Branch**: `001-scaffolding-and-hero` | **Date**: 2026-03-06

## Overview

This is a static Astro site with no persistent data, database, or server-side state. The
"data model" for Phase 1 describes the **component tree**, **design token schema**, and
**animation data structure** — the structured inputs that drive the rendered UI.

---

## Component Tree

```text
src/pages/index.astro               # Route: /
└── Layout.astro                    # Global HTML shell
    └── (slot)
        └── src/pages/index.astro   # Page content
            └── Hero.astro          # Above-the-fold Hero section
                ├── (copy panel)    # Static headline + CTA
                └── TerminalMockup.astro  # Animated CLI demo
```

---

## Design Token Schema

Defined in `src/styles/global.css` via Tailwind v4 `@theme` directive.

| Token | CSS Variable | Value | Usage |
|---|---|---|---|
| Background | `--color-dcv-bg` | `#0f172a` | Page background, terminal chrome background |
| Accent | `--color-dcv-accent` | `#22d3ee` | Cursor, prompt symbol, active text, CTA highlight |
| Surface | `--color-slate-800` | Tailwind built-in | Terminal window body background |
| Terminal chrome | `--color-slate-700` | Tailwind built-in | Terminal top bar |
| Body text | `--color-slate-200` | Tailwind built-in | Primary readable prose |
| Muted text | `--color-slate-400` | Tailwind built-in | Secondary/hint text, output lines |
| Font sans | `--font-sans` | `Geist Variable, ui-sans-serif, system-ui, sans-serif` | All prose |
| Font mono | `--font-mono` | `JetBrains Mono Variable, ui-monospace, monospace` | All code/terminal |

---

## Component Specifications

### Layout.astro

The global HTML shell. Renders once per page.

**Props**:
| Prop | Type | Required | Default | Description |
|---|---|---|---|---|
| `title` | `string` | Yes | — | Contents of `<title>` tag |
| `description` | `string` | No | `"The offline, privacy-first Developer CV generator."` | Meta description |

**Renders**:
- `<!DOCTYPE html>`, `<html lang="en">`, `<head>`, `<body>`
- Google Fonts preconnect + Geist Variable + JetBrains Mono `<link>` tags
- Tailwind CSS entry point `<link>` or inline import
- Global dark-mode body class: `bg-dcv-bg text-slate-200 font-sans antialiased`
- `<slot />` for page content

---

### Hero.astro

The above-the-fold landing section. Split-panel layout on desktop, single-column on mobile.

**Props**: None (Phase 1 — all content is hardcoded draft copy).

**Layout**: `flex flex-col md:flex-row items-center gap-12 min-h-screen px-6 py-24 max-w-7xl mx-auto`

**Left panel** (~50% width on desktop):
- H1 headline: `"Stop forgetting what you built."`
- Sub-headline: `"The offline, privacy-first Developer CV generator."`
- Brief descriptor: 1–2 sentences of draft copy
- CTA: Download link placeholder (e.g., `curl` command in a code block)

**Left panel copy** (Phase 1 draft — hardcoded, no props):
- H1: `"Let your work speak for itself."`
- Sub-headline: `"The offline, privacy-first, developer focused performance review prep and career reflection tool."`
- Descriptor: `"dcv reads your work output and generates a structured reports to help you reflect on your performance and prepare for reviews. No cloud, no accounts, no data leaving your machine."`
- CTA label: `"Install"` above a `<code>` block containing the install command:
  ```
  curl -fsSL https://apps.microcode.io/dcv/install.sh | sh
  ```

**Right panel** (~50% width on desktop):
- `<TerminalMockup />` component

**Accessibility**: `<section aria-label="Hero">` wrapper.

---

### TerminalMockup.astro

The animated CLI demo. Self-contained. Degrades to static content without JS.

**Props**:
| Prop | Type | Required | Default | Description |
|---|---|---|---|---|
| `commands` | `CommandSequence[]` | No | Built-in `dcv` demo | Sequence of commands to animate |
| `pauseDuration` | `number` | No | `2000` | Ms to hold final state before restart |

**Type: CommandSequence**:
```typescript
interface CommandSequence {
  input: string;          // The command to "type", e.g. "dcv init"
  output: string[];       // Lines of simulated output
}
```

**Default command sequence** (hardcoded if no prop provided):
```typescript
[
  {
    input: "dcv fetch --since 2025-01-01 --until 2025-06-30",
    output: [
      "✔ GitHub: 47 PRs, 117 commits",
      "✔ 164 embedded",
      "✔ Trello: 13 cards",
      "✔ 13 embedded (164 skipped — unchanged)",
    ]
  },
  {
    input: "dcv analyze --since 2025-01-01 --until 2025-06-30",
    output: [
      "✔ Report saved to ~/.dcv/reports/dcv_report_20250101_to_20250630.md",
      "Tokens: 14,424 input → 4,126 output | Model: claude-sonnet-4-6",
    ]
  }
]
```

**DOM structure**:
```html
<figure
  class="w-full rounded-lg overflow-hidden shadow-2xl"
  role="img"
  aria-label="Terminal demo showing dcv CLI commands"
>
  <!-- Chrome bar -->
  <div class="bg-slate-700 px-4 py-2 flex items-center gap-2">
    <span class="w-3 h-3 rounded-full bg-red-500"></span>
    <span class="w-3 h-3 rounded-full bg-yellow-400"></span>
    <span class="w-3 h-3 rounded-full bg-green-500"></span>
    <span class="ml-4 text-slate-400 text-xs font-mono">dcv — terminal</span>
  </div>
  <!-- Terminal body -->
  <div class="bg-slate-800 p-4 font-mono text-sm min-h-[180px]">
    <!-- Prompt line: typed by JS -->
    <p class="text-dcv-accent">
      <span class="select-none">$ </span>
      <span id="term-input"></span>
      <span id="term-cursor" class="animate-pulse">▋</span>
    </p>
    <!-- Output lines: revealed by JS -->
    <div id="term-output" class="mt-1 text-slate-400 space-y-0.5"></div>
  </div>
  <!-- Fallback for JS-disabled: static final state -->
  <noscript>
    <div class="bg-slate-800 p-4 font-mono text-sm text-slate-400">
      <p class="text-dcv-accent">$ dcv fetch --since 2025-01-01 --until 2025-06-30</p>
      <p>✔ GitHub: 47 PRs, 117 commits</p>
      <p>✔ 164 embedded</p>
      <p>✔ Trello: 13 cards</p>
      <p>✔ 13 embedded (164 skipped — unchanged)</p>
    </div>
  </noscript>
</figure>
```

**Animation state machine**:
```
IDLE → TYPING_INPUT → SHOWING_OUTPUT → PAUSED → CLEARING → IDLE (loop)
```

| State | Duration | Action |
|---|---|---|
| `TYPING_INPUT` | `input.length × 60ms` | Append one char to `#term-input` per tick |
| `SHOWING_OUTPUT` | `output.length × 300ms` | Reveal one output line per tick |
| `PAUSED` | `pauseDuration` (2000ms default) | Hold final state |
| `CLEARING` | ~200ms | Clear `#term-input` and `#term-output`, advance to next command |

---

## File Layout (Source)

```text
src/
├── components/
│   ├── Hero.astro
│   └── TerminalMockup.astro
├── layouts/
│   └── Layout.astro
├── pages/
│   └── index.astro
└── styles/
    └── global.css          # Tailwind v4 entry point + @theme tokens

public/
└── favicon.svg             # SVG preferred (Rule IV)

astro.config.mjs            # output: 'static', Tailwind v4 Vite plugin
package.json
```

---

---

## index.astro Content

`src/pages/index.astro` is intentionally minimal in Phase 1 — it is a composition file
only. Its complete content is:

```astro
---
import Layout from '../layouts/Layout.astro';
import Hero from '../components/Hero.astro';
---
<Layout title="dcv — The Developer CV Generator">
  <Hero />
</Layout>
```

No additional sections, navigation, or footer are in scope for Phase 1.

---

## Favicon Spec

**File**: `public/favicon.svg`

A minimal SVG representing a terminal prompt — consistent with the CLI tool identity.
The `>_` motif is the conventional "command line" symbol and requires no image assets.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" fill="none">
  <!-- Background -->
  <rect width="32" height="32" rx="6" fill="#0f172a"/>
  <!-- Chevron prompt symbol -->
  <polyline
    points="6,10 14,16 6,22"
    stroke="#22d3ee"
    stroke-width="2.5"
    stroke-linecap="round"
    stroke-linejoin="round"
    fill="none"
  />
  <!-- Cursor underscore -->
  <line
    x1="17" y1="22" x2="26" y2="22"
    stroke="#22d3ee"
    stroke-width="2.5"
    stroke-linecap="round"
  />
</svg>
```

Colors use the design tokens directly: `dcv-bg` (`#0f172a`) for the background,
`dcv-accent` (`#22d3ee`) for the symbol. If the token values change, update this file.

---

## Build Output

```text
dist/
├── index.html              # Fully rendered static HTML
├── _astro/
│   ├── *.css               # Tailwind-purged CSS bundle
│   └── *.js                # Minimal JS for TerminalMockup animation
└── favicon.svg
```

No server bundles. No `.js` runtime entrypoints in root. All assets under `_astro/`.
