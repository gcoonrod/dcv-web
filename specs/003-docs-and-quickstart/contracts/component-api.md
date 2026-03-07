# Component API Contracts: Docs, Installation, & Quickstart (Phase 3)

**Branch**: `003-docs-and-quickstart` | **Date**: 2026-03-06

---

## Contract 1: src/content/config.ts

Defines the `docs` Content Collection using Astro 5's Content Layer API. Failing to satisfy this contract causes a build error.

### Required Export

```typescript
import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const docs = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/docs' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    order: z.number(),
  }),
});

export const collections = { docs };
```

### Verification

- `npm run build` produces no Zod schema validation errors.
- All four baseline Markdown files pass schema validation (title, description, order all present and correctly typed).
- `getCollection('docs')` in `[...slug].astro` returns exactly 4 entries.

---

## Contract 2: src/components/DocsSidebar.astro

Renders a `<nav>` listing all doc entries, sorted by `order`, with the active entry visually distinguished.

### Props Interface

```typescript
interface Props {
  entries: Array<{
    id: string;
    data: { title: string; order: number };
  }>;
  currentSlug: string;
}
```

### Required Output Structure

```html
<nav aria-label="Documentation navigation">
  <ul>
    <li>
      <a href="/docs/{entry.id}"
         class="... [active classes if entry.id === currentSlug] ...">
        {entry.data.title}
      </a>
    </li>
    <!-- one <li> per entry, sorted ascending by entry.data.order -->
  </ul>
</nav>
```

### Active State Classes

| State | Classes |
|---|---|
| Active (current page) | `text-dcv-accent font-bold` |
| Inactive | `text-slate-400 hover:text-slate-200 transition-colors` |

### Constraints

- MUST use `<nav>` with `aria-label="Documentation navigation"`.
- MUST use `<ul>`/`<li>` list structure (Rule V: Accessibility).
- MUST NOT include a `<script>` tag (Rule I/II: no JS for sidebar).
- Entries MUST render in ascending `order` order.

---

## Contract 3: src/layouts/DocsLayout.astro

A layout component that wraps all doc pages, composing the global `Layout`, `DocsSidebar`, and a content slot. DocsLayout is responsible for fetching and sorting all doc entries to pass to DocsSidebar.

### Props Interface

```typescript
interface Props {
  title: string;
  description: string;
  currentSlug: string;
}
```

### Required Frontmatter Block

DocsLayout MUST fetch and sort all docs entries itself so it can supply them to DocsSidebar:

```astro
---
import { getCollection } from 'astro:content';
import Layout from './Layout.astro';
import DocsSidebar from '../components/DocsSidebar.astro';

interface Props {
  title: string;
  description: string;
  currentSlug: string;
}

const { title, description, currentSlug } = Astro.props;

const allDocs = await getCollection('docs');
const sortedEntries = allDocs.sort((a, b) => a.data.order - b.data.order);
---
```

### Required Output Structure

```html
<!-- Outer Layout provides <html>, <head>, <header>, <body> shell -->
<Layout title={title} description={description}>
  <div class="flex flex-col md:flex-row min-h-screen">

    <!-- Sidebar: stacks above on mobile, fixed-width left column on desktop -->
    <aside class="w-full md:w-64 md:shrink-0 md:sticky md:top-0 md:h-screen md:overflow-y-auto
                  bg-slate-900 border-b md:border-b-0 md:border-r border-slate-800 p-6">
      <DocsSidebar entries={sortedEntries} currentSlug={currentSlug} />
    </aside>

    <!-- Content column: prose-styled Markdown output -->
    <!-- NOTE: Use <div> not <main> — Layout.astro already wraps slot in <main> -->
    <div class="flex-1 min-w-0 overflow-hidden p-6 md:p-12">
      <article class="prose prose-invert max-w-none
                      prose-pre:overflow-x-auto prose-pre:bg-slate-800">
        <slot />
      </article>
    </div>

  </div>
</Layout>
```

### Constraints

- Layout MUST use `<aside>` for the sidebar (Rule V: Semantics).
- The content column MUST use `<div>` — NOT `<main>` — because `Layout.astro` already wraps the entire slot in `<main>`. Nesting `<main>` inside `<main>` is invalid HTML and a WCAG violation.
- The content area MUST apply `prose prose-invert` from `@tailwindcss/typography`.
- `prose-pre:overflow-x-auto` MUST be applied to satisfy US3 / SC-003 (mobile horizontal scroll).
- MUST NOT include client-side JavaScript (Constitution Principle I: Zero-JS Default).
- On mobile, sidebar MUST appear above content in DOM order and visual order.
- `description` MUST be passed through to `<Layout>` for the `<meta name="description">` tag.

---

## Contract 4: src/pages/docs/[...slug].astro

The dynamic route page that generates one static HTML file per doc entry.

### Required Implementation

```astro
---
import { getCollection } from 'astro:content';
import DocsLayout from '../../layouts/DocsLayout.astro';

export async function getStaticPaths() {
  const docs = await getCollection('docs');
  return docs.map((entry) => ({
    params: { slug: entry.id },
    props: { entry },
  }));
}

const { entry } = Astro.props;
const { slug } = Astro.params;
const { Content } = await entry.render();
---

<DocsLayout
  title={entry.data.title}
  description={entry.data.description}
  currentSlug={slug}
>
  <Content />
</DocsLayout>
```

### Generated Routes

| Markdown File | `entry.id` | Generated Route |
|---|---|---|
| `installation.md` | `installation` | `/docs/installation/index.html` |
| `quickstart.md` | `quickstart` | `/docs/quickstart/index.html` |
| `configuration.md` | `configuration` | `/docs/configuration/index.html` |
| `changelog.md` | `changelog` | `/docs/changelog/index.html` |

### Verification

- `npm run build` produces no errors.
- `dist/docs/installation/index.html` exists and contains the curl install command.
- `dist/docs/quickstart/index.html` exists and contains `dcv init`.
- Zero new `.js` files appear in `dist/_astro/` (only CSS may change hash).

---

## Contract 5: src/layouts/Layout.astro (Modification)

The existing global layout must be updated to add a site-wide `<header>` with a "Docs" nav link. **Important**: The current `Layout.astro` has NO `<header>` element — one must be created from scratch.

### Current Structure (before change)

```astro
<body class="bg-dcv-bg text-slate-200 font-sans antialiased min-h-screen">
  <main>
    <slot />
  </main>
</body>
```

### Required Change

Add a `<header>` element with a site nav immediately before `<main>`:

```astro
<body class="bg-dcv-bg text-slate-200 font-sans antialiased min-h-screen">
  <header class="border-b border-slate-800 px-6 py-4">
    <nav class="max-w-5xl mx-auto flex items-center justify-between">
      <a href="/" class="text-slate-100 font-semibold text-sm">dcv</a>
      <div class="flex items-center gap-6">
        <a href="/docs/installation" class="text-slate-400 hover:text-slate-200 transition-colors text-sm">
          Docs
        </a>
      </div>
    </nav>
  </header>
  <main>
    <slot />
  </main>
</body>
```

### Constraints

- The "Docs" link MUST point to `/docs/installation` (not bare `/docs`).
- MUST use `<header>` and `<nav>` semantic elements (Rule V: Accessibility).
- MUST NOT break or visually conflict with the existing Hero, FeatureGrid, RoiSection, or Pricing sections on the index page.
- The home logo link (`href="/"`) is required so the header is navigable from docs pages back to the landing page.
- MUST NOT add a `<script>` tag (no JS in the header).

---

## Contract 6: astro.config.mjs (Modification)

The Astro config must be updated to set the Shiki theme for Markdown code block highlighting.

### Required Change

```javascript
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  output: 'static',
  markdown: {
    shikiConfig: {
      theme: 'github-dark',
    },
  },
  vite: {
    plugins: [tailwindcss()],
  },
});
```

---

## Contract 7: src/styles/global.css (Modification)

The existing global CSS must be updated to register the `@tailwindcss/typography` plugin.

### Required Change

Add `@plugin "@tailwindcss/typography"` after the existing `@import "tailwindcss"` directive.

```css
@import "tailwindcss";
@plugin "@tailwindcss/typography";

/* existing @theme block and styles follow unchanged */
```

### Constraints

- The `@plugin` line MUST appear after `@import "tailwindcss"`.
- Existing `@theme` tokens (`--color-dcv-bg`, `--color-dcv-accent`, etc.) MUST be preserved.
