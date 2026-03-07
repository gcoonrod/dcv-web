# Research: Docs, Installation, & Quickstart (Phase 3)

**Branch**: `003-docs-and-quickstart` | **Date**: 2026-03-06

---

## Decision 1: @tailwindcss/typography with Tailwind v4

**Decision**: Install `@tailwindcss/typography` as a regular dependency (under `dependencies` in `package.json`, matching `tailwindcss`/`@tailwindcss/vite`) and register it using the `@plugin "@tailwindcss/typography"` directive in `src/styles/global.css`.

**Rationale**: Tailwind CSS v4 eliminated `tailwind.config.js` in favor of CSS-based configuration. Plugins are now registered with `@plugin "..."` in the CSS entry point — not in a JS config file. The `@tailwindcss/typography` package supports v4 via this mechanism starting at v0.5.15. This approach aligns with the project's existing `@tailwindcss/vite` setup and Rule I (no custom CSS except keyframe animations).

**Implementation**:
```css
/* src/styles/global.css */
@import "tailwindcss";
@plugin "@tailwindcss/typography";
```

Usage: `class="prose prose-invert max-w-none"` on the `<Content />` wrapper div.

**Alternatives considered**:
- Writing custom typography CSS styles manually — rejected: violates Rule I (custom `<style>` blocks only for keyframe animations).
- Using `@tailwindcss/typography` v0.5.x legacy JS config — rejected: no `tailwind.config.js` exists in this project.

---

## Decision 2: Astro Content Collections — Content Layer API (Astro 5 Native)

**Decision**: Use the **new Content Layer API** introduced in Astro 5, not the legacy `type: 'content'` API.

**Rationale**: The project is on Astro 5.18.x. The Content Layer API is the first-class, future-proof approach. Key differences from legacy:
- `loader: glob({ pattern: '**/*.md', base: './src/content/docs' })` replaces `type: 'content'`
- Entry identifier is `entry.id` (derived from filename, e.g., `installation`) not `entry.slug`
- `getStaticPaths` uses `params: { slug: entry.id }` to map to `[...slug].astro`

**Implementation** (`src/content/config.ts`):
```typescript
import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const docs = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/docs' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    order: z.number().int().min(1),
  }),
});

export const collections = { docs };
```

**Alternatives considered**:
- Legacy `type: 'content'` API — still functional in Astro 5 but marked as legacy; avoids future deprecation.

---

## Decision 3: Sidebar Active State Detection

**Decision**: Pass `currentSlug` as a prop from `[...slug].astro` to `DocsSidebar.astro`. Compare `currentSlug === entry.id` to apply the active Tailwind class at build time.

**Rationale**: Zero JavaScript — the active state is determined server-side (at build time) per generated page. Each page compiles with its own pre-computed active sidebar link. No `Astro.url` comparison is needed at runtime.

**Implementation**:
```astro
<!-- In [..slug].astro -->
<DocsLayout currentSlug={slug}>

<!-- In DocsSidebar.astro -->
const { entries, currentSlug } = Astro.props;
<a class={`... ${entry.id === currentSlug ? 'text-dcv-accent font-bold' : 'text-slate-400 hover:text-slate-200'}`}>
```

**Alternatives considered**:
- `Astro.url.pathname` comparison at render time — valid but introduces trailing-slash fragility and is slightly less explicit.

---

## Decision 4: Mobile Layout — CSS Flex Collapse (Confirmed by Clarification Q1)

**Decision**: `flex flex-col md:flex-row` on the DocsLayout two-panel container. Sidebar renders above content on mobile via natural DOM order. No JavaScript required.

**Rationale**: Confirmed in spec clarification (Q1: Option A). The sidebar is the first child element, so `flex-col` causes it to appear above the content. `md:flex-row` restores the side-by-side layout on desktop. This is identical to how Astro's own documentation site handles its sidebar collapse.

---

## Decision 5: Shiki Theme for Code Blocks

**Decision**: Use the `github-dark` Shiki theme, configured in `astro.config.mjs`.

**Rationale**: `github-dark` matches the dcv dark aesthetic (`dcv-bg: #0f172a`), is high-contrast, and is the most universally recognized dark theme for developers. Astro applies Shiki automatically to all fenced code blocks in Markdown — no extra packages needed.

**Implementation** (`astro.config.mjs`):
```javascript
export default defineConfig({
  output: 'static',
  markdown: {
    shikiConfig: {
      theme: 'github-dark',
    },
  },
  vite: { plugins: [tailwindcss()] },
});
```

**Alternatives considered**:
- `dracula`, `night-owl` — also valid dark themes, lower recognition.
- Default Astro theme — acceptable but not explicitly aligned with dcv brand colors.

---

## Decision 6: Sidebar Independent Scroll on Desktop

**Decision**: Apply `sticky top-0 h-screen overflow-y-auto` to the sidebar container on desktop using Tailwind's responsive prefix (`md:sticky md:top-0 md:h-screen md:overflow-y-auto`).

**Rationale**: The edge case requirement states "the sidebar must scroll independently from the main content area." Sticky + full viewport height + overflow-y-auto achieves this without JavaScript. On mobile (`flex-col`), the sidebar is not sticky and flows naturally above content.

---

## Decision 7: Docs Index Route (/docs with no slug)

**Decision**: No special handling — 404 is acceptable. The nav links directly to `/docs/installation`. No `src/pages/docs/index.astro` redirect page is created. (Confirmed by Clarification Q3: Option A.)

**Rationale**: Avoids adding an extra page/file. SC-004 only requires the nav to link to `/docs/installation` directly. A 404 on `/docs` bare is benign given the nav always bypasses it.

---

## Decision 8: Implementation Steps Order

1. Install `@tailwindcss/typography` (package dep, one-line CSS registration)
2. Configure Shiki theme in `astro.config.mjs`
3. Create `src/content/config.ts` (Content Layer schema)
4. Create four baseline Markdown files in `src/content/docs/`
5. Create `src/components/DocsSidebar.astro`
6. Create `src/layouts/DocsLayout.astro`
7. Create `src/pages/docs/[...slug].astro`
8. Update `src/layouts/Layout.astro` to add "Docs" nav link
9. Build and verify
