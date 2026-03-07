# dcv-web

Marketing site for [dcv](https://apps.microcode.io/dcv) — the offline, privacy-first developer
performance review prep and career reflection tool.

Built with Astro 5 + Tailwind CSS v4. Deploys to AWS S3 + CloudFront as a folder of static files.

---

## Stack

| Concern | Tool |
|---------|------|
| Framework | [Astro 5](https://astro.build) (`output: 'static'`) |
| Styling | [Tailwind CSS v4](https://tailwindcss.com) via `@tailwindcss/vite` |
| Body font | Geist Variable (Google Fonts CDN) |
| Mono font | JetBrains Mono Variable (Google Fonts CDN) |
| Interactivity | Vanilla JS inline scripts only — no framework |
| Deployment | AWS S3 + CloudFront |

---

## Quick start

```bash
npm install
npm run dev      # http://localhost:4321
npm run build    # outputs to dist/
npm run preview  # serve dist/ locally
```

Node 20+ required.

---

## Project structure

```
src/
├── components/
│   ├── Hero.astro            # Split-panel hero section
│   ├── TerminalMockup.astro  # Animated CLI demo, degrades without JS
│   ├── FeatureGrid.astro     # Feature highlights grid
│   ├── RoiSection.astro      # ROI / value proposition section
│   ├── Pricing.astro         # Free vs Pro pricing cards
│   └── DocsSidebar.astro     # Docs nav with build-time active state
├── content/
│   ├── config.ts             # Content Layer collection schema (Zod)
│   └── docs/                 # Markdown doc pages (installation, quickstart, …)
├── layouts/
│   ├── Layout.astro          # Global HTML shell (fonts, meta, header, dark body)
│   └── DocsLayout.astro      # Two-column docs layout (sidebar + prose content)
├── pages/
│   ├── index.astro           # Route: / — composes Layout + Hero + sections
│   └── docs/
│       └── [...slug].astro   # Route: /docs/:slug — dynamic catch-all for docs
└── styles/
    └── global.css            # Tailwind v4 entry point + @theme design tokens

public/
└── favicon.svg               # >_ terminal prompt motif

specs/                        # Feature design artifacts (speckit workflow)
├── 001-scaffolding-and-hero/
├── 002-roi-and-pricing/
└── 003-docs-and-quickstart/
    ├── spec.md
    ├── plan.md
    ├── tasks.md
    └── ...
```

---

## Design tokens

Defined in `src/styles/global.css` via Tailwind v4 `@theme`. These names are stable — renaming
requires a global find-and-replace.

| Token | CSS variable | Value | Tailwind class |
|-------|-------------|-------|----------------|
| Background | `--color-dcv-bg` | `#0f172a` | `bg-dcv-bg` |
| Accent | `--color-dcv-accent` | `#22d3ee` | `text-dcv-accent` |
| Body font | `--font-sans` | Geist Variable → `ui-sans-serif` | `font-sans` |
| Mono font | `--font-mono` | JetBrains Mono → `ui-monospace` | `font-mono` |

---

## Build output

`npm run build` produces a `dist/` directory of plain static files — no Node server required
in production:

```
dist/
├── index.html
├── favicon.svg
├── docs/
│   ├── installation/index.html
│   ├── quickstart/index.html
│   ├── configuration/index.html
│   └── changelog/index.html
└── _astro/
    └── *.css   # Tailwind-purged CSS bundle
```

Zero JS bundles. The terminal animation script is inlined directly into `index.html`
via Astro's `define:vars` pattern. Doc pages ship no JavaScript at all.

---

## Deployment

Sync `dist/` to an S3 bucket fronted by CloudFront:

```bash
aws s3 sync dist/ s3://<your-bucket> --delete
aws cloudfront create-invalidation --distribution-id <id> --paths "/*"
```

No server. No runtime. Any static host works.

---

## Development workflow

This project follows git-flow and semver (see `.specify/memory/constitution.md`):

- `main` — production-ready, tagged releases only
- `develop` — integration branch, PR target for features
- `feature/<n>-<name>` — short-lived feature branches from `develop`

Feature design artifacts live in `specs/<branch-name>/` alongside the source code. Each feature
goes through the speckit pipeline (`spec → plan → tasks → implement`) before code is written.

---

## Constitution

Hard rules governing all development — enforced by convention and code review:

1. **Static first** — `output: 'static'` always, no SSR adapter
2. **Tailwind only** — no custom CSS except `@keyframes`
3. **Vanilla JS** — no React, Vue, Svelte, or animation libraries
4. **HTML/CSS for visuals** — no `.gif` or `.mp4` for the terminal demo
5. **Accessible** — semantic HTML, `aria-label` on all interactive and decorative elements

Full text: `.specify/memory/constitution.md`
