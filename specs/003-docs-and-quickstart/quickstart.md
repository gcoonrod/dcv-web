# Quickstart: Docs, Installation, & Quickstart (Phase 3)

**Branch**: `003-docs-and-quickstart` | **Date**: 2026-03-06

## Prerequisites

- Phase 2 (`002-roi-and-pricing`) merged to `develop` ✅
- On branch `003-docs-and-quickstart` (branched from `develop`)
- Dev server: `npm run dev` (http://localhost:4321)

---

## Setup

```bash
# Install the new dependency
npm install @tailwindcss/typography
```

Verify `package.json` now includes `"@tailwindcss/typography"` in dependencies.

---

## Scenario 1: Installation Page Renders with Sidebar

**Tests**: Contract 4 (generated routes), Contract 2 (sidebar), Contract 3 (DocsLayout)

1. Start dev server: `npm run dev`
2. Navigate to `http://localhost:4321/docs/installation`
3. **Verify**:
   - Two-column layout: sidebar on left, content on right
   - Sidebar contains 4 links: Installation, Quickstart, Configuration, Changelog
   - "Installation" link is visually highlighted (`text-dcv-accent font-bold`)
   - Code block with `curl -fsSL https://dcv.dev/install.sh | bash` is syntax-highlighted
   - Code block has a visually distinct background (darker than page background)

---

## Scenario 2: Active Sidebar State Changes Per Page

**Tests**: Contract 2 (active state), Contract 4 (routing)

1. Navigate to `http://localhost:4321/docs/quickstart`
2. **Verify**:
   - "Quickstart" sidebar link is highlighted, all others are not
3. Navigate to `http://localhost:4321/docs/configuration`
4. **Verify**:
   - "Configuration" sidebar link is highlighted, all others are not

---

## Scenario 3: Mobile Layout — Sidebar Collapses Above Content

**Tests**: US3 acceptance scenarios, FR-003, SC-003

1. Open DevTools → set viewport to 375px width
2. Navigate to `http://localhost:4321/docs/configuration`
3. **Verify**:
   - Sidebar appears above the main content (stacked, not side-by-side)
   - Sidebar does NOT overlap content
   - No horizontal scrollbar on the page body
4. Scroll within the code block (JSON schema) → **Verify** code scrolls horizontally within the `<pre>` container without causing page scroll

---

## Scenario 4: Docs Nav Link on Landing Page

**Tests**: FR-007, SC-004

1. Navigate to `http://localhost:4321`
2. **Verify** the page header/nav contains a "Docs" link
3. Click "Docs" → **Verify** navigates to `/docs/installation` (not `/docs`)
4. Count clicks from landing page to curl command: should be exactly 1 click

---

## Scenario 5: Zero JavaScript on Docs Pages

**Tests**: SC-002, Constitution Principle I

1. In browser DevTools → Network tab → filter by JS
2. Navigate to `http://localhost:4321/docs/installation`
3. Hard-reload (Shift+Refresh)
4. **Verify**: No `.js` requests from docs components (no clipboard, no sidebar toggle)
5. Disable JavaScript in DevTools → reload
6. **Verify**: All content remains fully readable; sidebar and content both visible; no broken layout

---

## Scenario 6: Build Verification — No New JS Files

**Tests**: SC-002, Contract 4 verification

```bash
npm run build
ls dist/docs/
# Expected: installation/  quickstart/  configuration/  changelog/
ls dist/_astro/
# Expected: Only one .css file (hash may differ from Phase 2 baseline); no new .js files
```

Verify `dist/docs/installation/index.html` contains `curl -fsSL`.

---

## Scenario 7: Frontmatter Validation — Build Fails on Bad Frontmatter

**Tests**: Contract 1 (Zod schema), Edge Case (missing frontmatter)

1. Temporarily edit `src/content/docs/installation.md` and remove the `order` field
2. Run `npm run build`
3. **Verify**: Build fails with a Zod validation error mentioning `order`
4. Restore the `order` field → build passes

---

## Scenario 8: Sidebar Scroll Independence on Desktop (Optional — Visual)

**Tests**: Edge Case (sidebar overflow)

1. If testing with many docs (> 10), **verify** the sidebar scrolls independently while main content stays in place
2. For Phase 3 with 4 docs, this edge case is not triggered — can be verified visually by temporarily reducing `md:h-screen` to `md:h-48` and confirming overflow scrolling works

---

## Common Issues

| Symptom | Likely Cause | Fix |
|---|---|---|
| `prose` classes not applying | `@plugin "@tailwindcss/typography"` missing from `global.css` | Add the `@plugin` directive |
| Build error: "Cannot find module 'astro/loaders'" | Old Astro version | Confirm Astro 5.x is installed |
| Sidebar not highlighting active link | `currentSlug` prop mismatch | Verify `params.slug` matches `entry.id` |
| `/docs` returns 404 | Expected — by design | Link to `/docs/installation` from nav (FR-007) |
| Code blocks not highlighted | Shiki config missing | Add `markdown.shikiConfig` to `astro.config.mjs` |
