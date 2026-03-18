# Component API Contracts: Scaffolding & Hero Section (Phase 1)

**Branch**: `001-scaffolding-and-hero` | **Date**: 2026-03-06

> For a static Astro site there are no HTTP endpoints. The "contracts" are the public
> component prop interfaces that must remain stable once implemented. Changing a prop name
> or type is a breaking change requiring all callers to be updated.

---

## Contract 1: Layout.astro

**File**: `src/layouts/Layout.astro`
**Type**: Astro Layout Component

### Props

```typescript
interface Props {
  /** Page title inserted into <title> tag. Required. */
  title: string;

  /**
   * Meta description for SEO.
   * @default "The offline, privacy-first Developer CV generator."
   */
  description?: string;
}
```

### Slot

| Slot | Description |
|---|---|
| `default` | Page body content rendered inside `<main>` |

### Rendered Guarantee

- MUST render valid HTML5 with `lang="en"` on `<html>`.
- MUST include `<meta name="viewport" content="width=device-width, initial-scale=1">`.
- MUST apply `bg-dcv-bg text-slate-200 font-sans antialiased` on `<body>`.
- MUST NOT render any client-side framework JS unless a downstream component uses `client:`.
- MUST import Google Fonts (Geist Variable + JetBrains Mono) via `<link rel="preconnect">`.

### Usage Example

```astro
---
import Layout from '../layouts/Layout.astro';
---
<Layout title="dcv — The Developer CV Generator">
  <main>Page content here</main>
</Layout>
```

---

## Contract 2: Hero.astro

**File**: `src/components/Hero.astro`
**Type**: Astro Component (no client-side hydration required)

### Props

```typescript
interface Props {
  // Phase 1: No props — all copy is hardcoded draft text.
  // Future phases may extract `headline`, `subheadline`, `ctaCommand`.
}
```

### Rendered Guarantee

- MUST render as a `<section aria-label="Hero">` element.
- MUST implement a split-panel layout: `flex-col md:flex-row`.
- Left panel MUST contain: H1 headline ("Let your work speak for itself."), sub-headline, brief copy, CTA code block.
- Right panel MUST contain: `<TerminalMockup />`.
- MUST be fully readable with CSS disabled (semantic HTML flow order: copy before terminal).
- MUST NOT import any external JS libraries.

### Usage Example

```astro
---
import Hero from '../components/Hero.astro';
---
<Hero />
```

---

## Contract 3: TerminalMockup.astro

**File**: `src/components/TerminalMockup.astro`
**Type**: Astro Component with inline `<script>` (vanilla JS)

### Props

```typescript
interface CommandSequence {
  /** The shell command string to type out (without the `$ ` prompt). */
  input: string;
  /** Lines of simulated output to reveal after typing is complete. */
  output: string[];
}

interface Props {
  /**
   * Sequence of commands to animate in order.
   * Loops back to the first command after the last completes.
   * @default Built-in dcv demo sequence (see data-model.md)
   */
  commands?: CommandSequence[];

  /**
   * Milliseconds to hold the final state before clearing and restarting.
   * @default 2000
   */
  pauseDuration?: number;
}
```

### Rendered Guarantee

- MUST render a `<figure role="img" aria-label="...">` as the root element.
- MUST render a terminal chrome bar with three colored circles (red/yellow/green).
- MUST render the final command sequence state as static HTML inside a `<noscript>` block
  OR as the initial `innerHTML` of the terminal body (so JS-disabled users see content).
- MUST apply `font-mono` class to terminal body.
- MUST use only vanilla JS in a `<script>` tag — no external libraries or framework imports.
- Animation MUST follow the loop-with-pause state machine:
  `TYPING_INPUT → SHOWING_OUTPUT → PAUSED (2s) → CLEARING → (next command)`
- MUST NOT use `setInterval` for the typing loop (use chained `setTimeout` to avoid drift).

### Usage Example

```astro
---
import TerminalMockup from '../components/TerminalMockup.astro';

const commands = [
  { input: "dcv fetch --since 2025-01-01 --until 2025-06-30", output: ["✔ GitHub: 47 PRs, 117 commits"] }
];
---
<TerminalMockup commands={commands} pauseDuration={2000} />
```

---

## Contract 4: Design Token Stability

**File**: `src/styles/global.css`

The following token names are **stable** once defined. Renaming them requires a global
find-and-replace across all component files.

| Token Name | Tailwind Utility Class | Value (Phase 1) |
|---|---|---|
| `--color-dcv-bg` | `bg-dcv-bg`, `text-dcv-bg` | `#0f172a` |
| `--color-dcv-accent` | `bg-dcv-accent`, `text-dcv-accent`, `border-dcv-accent` | `#22d3ee` |
| `--font-sans` | `font-sans` | `Geist Variable, ui-sans-serif, ...` |
| `--font-mono` | `font-mono` | `JetBrains Mono Variable, ui-monospace, ...` |

> Changing a token value (e.g., adjusting `dcv-accent` hue) is a **non-breaking patch**.
> Renaming a token key is a **breaking change** requiring a full component audit.
