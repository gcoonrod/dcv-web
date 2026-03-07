<!--
## Sync Impact Report

**Version change**: 1.0.0 → 1.1.0 (MINOR: new Development Workflow section added)

### Modified Principles
- None

### Added Sections
- Development Workflow (git-flow branching strategy + semver release tagging)

### Removed Sections
- None

### Templates Reviewed
| Template | Status | Notes |
|---|---|---|
| `.specify/templates/plan-template.md` | ✅ Compatible | Branch naming convention now derivable from this document |
| `.specify/templates/spec-template.md` | ✅ Compatible | No conflicts |
| `.specify/templates/tasks-template.md` | ✅ Compatible | No conflicts |
| `.specify/templates/agent-file-template.md` | ✅ Compatible | No conflicts |

### Deferred Items
- No CLAUDE.md exists yet. One MUST be generated and kept consistent with this constitution per the Governance section.
- No README.md exists yet.
-->

# DCV Marketing Website Constitution

## Core Principles

### I. Zero-JavaScript Default (Static First)

The website MUST be statically generated (SSG). Every page MUST be perfectly readable
and functional with JavaScript completely disabled in the browser.

- Client-side JavaScript is strictly reserved for non-critical enhancements
  (e.g., terminal typing animations, copy-to-clipboard buttons).
- The Astro configuration MUST be set to `output: 'static'`.
- Server-Side Rendering (SSR) Node/Edge adapters are strictly prohibited.

### II. Developer-Centric Aesthetic

The design language MUST respect the developer audience and prioritize high
signal-to-noise ratio over marketing fluff.

- **Dark Mode Default**: The primary theme MUST be dark (e.g., Slate or True Black
  backgrounds) with high-contrast text.
- **Typography**: System-native or highly optimized geometric sans-serif fonts MUST be
  used for prose; strict monospace fonts MUST be used for all code blocks, commands,
  and terminal mockups.
- **No Executive Jargon**: Copywriting MUST be direct, technical, and pragmatic. Words
  like "synergy," "empower," or "enterprise-grade" are prohibited. Use "offline,"
  "SQLite," and "binary."

### III. Infrastructure Simplicity (AWS Native)

The deployment artifact MUST be a folder of plain HTML, CSS, and optimized assets
(`dist/`) hostable on AWS S3 behind an AWS CloudFront distribution.

- The build process MUST NOT require a running Node.js server in production.
- CI/CD pipelines MUST build the Astro project and sync `dist/` directly to the
  target S3 bucket.

## Bright-Line Coding Rules

These are strict agent directives governing all development work on this project.
Any deviation requires explicit user override.

### Rule I. Tailwind CSS Exclusivity

All styling MUST be implemented using Tailwind CSS utility classes. External CSS
frameworks (Bootstrap, Bulma) and heavy UI component libraries (Material UI, Chakra UI)
are strictly prohibited. Custom CSS (`<style>` blocks) MUST be limited to complex
keyframe animations and nothing else.

### Rule II. Strict Island Architecture

Any UI component that absolutely requires client-side JavaScript MUST be implemented
as an isolated Astro Island using `client:load` or `client:visible` directives.
Global JavaScript bundles are forbidden.

### Rule III. Vanilla JS Preference

When adding interactive elements, the agent MUST prefer Vanilla JavaScript (`<script>`
tags within Astro components) over introducing a framework (React, Svelte, Vue) solely
for a single interaction.

### Rule IV. Asset Optimization

All images, screenshots, and icons MUST be optimized during the build step using
Astro's native `<Image />` component or equivalent tooling. SVG is preferred for all
non-photographic graphics.

### Rule V. Accessibility & Semantics

HTML output MUST be semantically correct (proper use of `<header>`, `<main>`,
`<article>`, `<footer>`) and accessible. All interactive elements MUST have appropriate
`aria-` labels. Color contrast ratios MUST meet WCAG AA standards.

## Development Workflow

### Branching Strategy (Git-Flow)

This project MUST follow the git-flow branching model:

- **`main`**: Production-ready code only. Direct commits are prohibited. Receives merges
  exclusively from `release/*` and `hotfix/*` branches.
- **`develop`**: Integration branch. All feature work targets this branch. MUST remain
  in a buildable state at all times.
- **`feature/<short-description>`**: Feature branches. MUST be branched from `develop`
  and merged back to `develop` via pull request upon completion.
- **`release/<version>`**: Release preparation branches (e.g., `release/1.2.0`). MUST
  be branched from `develop`. Only bug fixes, documentation, and version bumps are
  permitted. Merges into both `main` and `develop` on completion.
- **`hotfix/<short-description>`**: Emergency fixes for production. MUST be branched
  from `main` and merged into both `main` and `develop` on completion.

### Release Versioning (Semver)

All releases MUST follow [Semantic Versioning](https://semver.org/) (`vMAJOR.MINOR.PATCH`):

- **MAJOR**: Redesigns, structural overhauls, or breaking content changes.
- **MINOR**: New page sections, new features, or non-breaking content additions.
- **PATCH**: Bug fixes, copy corrections, style tweaks, dependency updates.

Release tags MUST be applied to `main` using the format `v<MAJOR>.<MINOR>.<PATCH>`
(e.g., `v1.2.0`). Pre-release tags use the suffix `-beta.N` or `-rc.N`.

## Vision & Target Audience

### Vision

To create a lightning-fast, visually striking landing page that instantly communicates
the technical value of the `dcv` CLI tool, convincing software engineers to download
the binary and try it in under 30 seconds.

### Target Audience

Software engineers, developers, and engineering managers who are highly skeptical of
bloated software, value their privacy, and prefer terminal-based workflows.

## Governance

- This constitution supersedes all other project practices. In any conflict between
  this document and another guideline (including CLAUDE.md), this constitution governs.
- Amendments MUST increment the version per semantic versioning:
  - **MAJOR**: Backward-incompatible removals or redefinitions of principles/rules.
  - **MINOR**: New principle, rule, or section added or materially expanded.
  - **PATCH**: Clarifications, wording fixes, non-semantic refinements.
- Any generated CLAUDE.md MUST remain consistent with this constitution and be updated
  whenever the constitution is amended.
- All feature plans MUST include a Constitution Check gate verifying compliance with
  Core Principles I–III and Bright-Line Rules I–V before implementation begins.
- Complexity violations (deviations from any Bright-Line Rule) MUST be documented in
  the plan's Complexity Tracking table with explicit justification.
- All feature branches MUST follow the git-flow naming conventions defined in the
  Development Workflow section.

**Version**: 1.1.0 | **Ratified**: 2026-03-05 | **Last Amended**: 2026-03-06
