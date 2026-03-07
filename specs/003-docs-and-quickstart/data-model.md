# Data Model: Docs, Installation, & Quickstart (Phase 3)

**Branch**: `003-docs-and-quickstart` | **Date**: 2026-03-06

---

## Entity: DocEntry

A Markdown file stored in `src/content/docs/`. Validated at build time by the Zod schema in `src/content/config.ts`. Missing or invalid frontmatter causes a build error.

### Frontmatter Schema

| Field | Type | Required | Constraints | Description |
|---|---|---|---|---|
| `title` | `string` | Yes | Non-empty | Human-readable page title; used in `<title>`, `<h1>`, and sidebar nav link |
| `description` | `string` | Yes | Non-empty | Short summary; used in `<meta name="description">` |
| `order` | `number` | Yes | Integer ≥ 1 | Controls sidebar sort order; lower numbers appear first |

### Derived Fields (Content Layer API)

| Field | Source | Description |
|---|---|---|
| `id` | Filename without extension | Used as the URL slug (e.g., `installation.md` → id `installation` → route `/docs/installation`) |
| `body` | Markdown body | Raw Markdown content rendered to HTML via `render(entry)` from `astro:content` |

### Phase 3 Required Instances

All four files MUST be created in `src/content/docs/`:

| File | `title` | `description` | `order` |
|---|---|---|---|
| `installation.md` | `"Installation"` | `"Install the dcv binary on macOS, Linux, or Windows."` | `1` |
| `quickstart.md` | `"Quickstart"` | `"Run your first dcv report in under 5 minutes."` | `2` |
| `configuration.md` | `"Configuration"` | `"Configure dcv with ~/.dcv/config.json."` | `3` |
| `changelog.md` | `"Changelog"` | `"Release history for dcv v1.x.x."` | `4` |

---

## Entity: DocsSidebar (Component Props)

The `DocsSidebar.astro` component receives sorted doc entries and the current slug, rendering a `<nav>` with one link per entry.

### Props Interface

```typescript
interface Props {
  entries: Array<{
    id: string;      // URL slug (e.g., "installation")
    data: {
      title: string; // Link label
      order: number; // Already sorted before passing in
    };
  }>;
  currentSlug: string; // Active page slug — drives active class
}
```

### Active State Rule

A sidebar link is active when `entry.id === currentSlug`. Active links receive `text-dcv-accent font-bold`. Inactive links receive `text-slate-400 hover:text-slate-200 transition-colors`.

---

## Entity: DocsLayout (Component Props)

The `DocsLayout.astro` layout wraps all doc pages. It composes the global `Layout`, the `DocsSidebar`, and a `<slot />` for the Markdown `<Content />`.

### Props Interface

```typescript
interface Props {
  title: string;       // Page title — passed through to Layout
  description: string; // Meta description — passed through to Layout
  currentSlug: string; // Forwarded to DocsSidebar for active state
}
```

### Layout Behavior

| Viewport | Behavior |
|---|---|
| Mobile (< 768px) | `flex-col` — sidebar stacks above content; full-width both panels |
| Desktop (≥ 768px) | `md:flex-row` — sidebar fixed-width left column (~64px or `w-64`), content fills remaining space |

### Sidebar Desktop Behavior

- `md:sticky md:top-0 md:h-screen md:overflow-y-auto` — sidebar stays fixed while content scrolls; scrollable independently if it overflows viewport height.

### HTML Nesting Constraint

`Layout.astro` wraps its `<slot />` in `<main>`. DocsLayout's content column MUST use `<div>`, NOT `<main>`, to avoid nested `<main>` elements (invalid HTML, WCAG violation). The single `<main>` is provided by `Layout.astro`.

---

## Content Outline: Phase 3 Required Markdown Files

### installation.md

```markdown
---
title: "Installation"
description: "Install the dcv binary on macOS, Linux, or Windows."
order: 1
---

# Installation

## Quick Install (Recommended)

```bash
curl -fsSL https://dcv.dev/install.sh | bash
```

## Manual Binary Download

Download the latest binary for your platform from the [releases page](https://github.com/gcoonrod/dcv/releases).

| Platform | Binary |
|---|---|
| macOS (Apple Silicon) | `dcv-macos-arm64` |
| macOS (Intel) | `dcv-macos-x86_64` |
| Linux (x86_64) | `dcv-linux-x86_64` |
| Windows | `dcv-windows-x86_64.exe` |

Place the binary in a directory on your `$PATH` and make it executable:

```bash
chmod +x dcv-macos-arm64
mv dcv-macos-arm64 /usr/local/bin/dcv
```

Verify the install:

```bash
dcv --version
```
```

### quickstart.md

```markdown
---
title: "Quickstart"
description: "Run your first dcv report in under 5 minutes."
order: 2
---

# Quickstart

## Step 1: Initialize

Run `dcv init` inside a Git repository to create the default config file:

```bash
cd ~/my-project
dcv init
```

This creates `~/.dcv/config.json` with sensible defaults.

## Step 2: Fetch Data

Pull your activity data from configured sources:

```bash
dcv fetch
```

## Step 3: Analyze

Generate your CV report:

```bash
dcv analyze
```

Output is written to `./dcv-report.md` by default.
```

### configuration.md

```markdown
---
title: "Configuration"
description: "Configure dcv with ~/.dcv/config.json."
order: 3
---

# Configuration

dcv reads from `~/.dcv/config.json`. Run `dcv init` to generate a default config.

## Schema

```json
{
  "sources": ["git-local", "github-public"],
  "providers": {
    "openai": {
      "apiKey": "sk-..."
    }
  },
  "output": {
    "format": "markdown",
    "path": "./dcv-report.md"
  }
}
```

### Fields

| Field | Type | Default | Description |
|---|---|---|---|
| `sources` | `string[]` | `["git-local"]` | Data sources to fetch from |
| `providers.openai.apiKey` | `string` | — | Your OpenAI API key (never leaves your machine) |
| `output.format` | `"markdown" \| "html" \| "latex"` | `"markdown"` | Report output format |
| `output.path` | `string` | `"./dcv-report.md"` | Output file path |
```

### changelog.md

```markdown
---
title: "Changelog"
description: "Release history for dcv v1.x.x."
order: 4
---

# Changelog

## v1.0.0 — 2026-03-06

Initial release.

### Added
- `dcv init` — initialize config
- `dcv fetch` — fetch from local Git and public GitHub
- `dcv analyze` — generate Markdown report
- BYO-LLM key support (OpenAI)
```

---

## Relationships

```text
DocEntry (Markdown file)
  └── rendered by → [..slug].astro
        └── uses layout → DocsLayout.astro
              ├── passes entries + currentSlug → DocsSidebar.astro
              └── renders Content → <slot />
```
