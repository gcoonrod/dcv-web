---
description: "Task list for 001-scaffolding-and-hero"
---

# Tasks: Scaffolding & Hero Section (Phase 1)

**Input**: Design documents from `/specs/001-scaffolding-and-hero/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/component-api.md, quickstart.md

**Tests**: No test tasks — not explicitly requested in the feature specification.

**Organization**: Tasks are grouped by user story. US1 (dark page load) establishes the
shell; US2 (terminal animation) extends it. US2 depends on US1's Layout output but each
is independently verifiable at its phase checkpoint.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no blocking dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to ([US1], [US2])
- All paths are relative to repository root

## Path Conventions

- Single Astro project at repository root
- Source: `src/components/`, `src/layouts/`, `src/pages/`, `src/styles/`
- Static assets: `public/`
- Config: `astro.config.mjs` at root

---

## Phase 0: Repository Bootstrap

**Purpose**: One-time git-flow setup required by the DCV Web Constitution (v1.1.0 Development
Workflow). Must complete before feature branch work begins.

- [x] T000 Initialize `develop` branch from `main`: run `git checkout main && git checkout -b develop && git push -u origin develop`; confirm `develop` exists on remote — per `.specify/memory/constitution.md` Development Workflow

**Checkpoint**: `git branch -a` shows both `main` and `origin/develop`. Current branch is the
feature branch `001-scaffolding-and-hero` (already checked out from develop per git-flow).

---

## Phase 1: Setup

**Purpose**: Initialize the Astro project and add Tailwind CSS v4.
These two steps must complete before any component work can begin.

- [x] T001 Scaffold Astro 5 project at repo root: run `npm create astro@latest . -- --template minimal --install --no-git` selecting TypeScript strict — per `plan.md` Step 1 and `quickstart.md` Step 1
- [x] T002 Add Tailwind CSS v4: run `npx astro add tailwind`, then verify `astro.config.mjs` uses `@tailwindcss/vite` plugin (NOT `@astrojs/tailwind`) and explicitly sets `output: 'static'` — per `plan.md` Step 2 and `quickstart.md` Step 2

**Checkpoint**: `npm run dev` starts without errors. `astro.config.mjs` contains `output: 'static'` and `vite.plugins: [tailwindcss()]`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Design tokens and static assets that both user stories depend on.
Both tasks target different files and can be worked on in parallel.

**CRITICAL**: No user story work can begin until T003 is complete (Layout.astro imports global.css).

- [x] T003 [P] Create `src/styles/global.css` with `@import "tailwindcss"` and `@theme` block defining `--color-dcv-bg: #0f172a`, `--color-dcv-accent: #22d3ee`, `--font-sans` (Geist Variable stack), `--font-mono` (JetBrains Mono stack) — per `plan.md` Step 3, `data-model.md` Design Token Schema, and `contracts/component-api.md` Contract 4
- [x] T004 [P] Create `public/favicon.svg` using the `>_` terminal prompt motif SVG (chevron + underscore cursor, `#0f172a` background, `#22d3ee` strokes) — per `plan.md` Step 8 and `data-model.md` Favicon Spec

**Checkpoint**: `src/styles/global.css` exists with all four `@theme` token definitions. `public/favicon.svg` exists as a valid SVG file.

---

## Phase 3: User Story 1 — The Instant Page Load (Priority: P1)

**Goal**: A dark-themed page loads instantly with correct typography and zero large JS bundles — the first visual impression signals the tool's quality before any copy is read.

**Independent Test**: Run `npm run build && npm run preview`. Open `http://localhost:4321`. Verify the background is `#0f172a` (no white flash), Geist Variable renders in prose, and the Network tab shows no React/Vue/Svelte bundles.

- [x] T005 [US1] Create `src/layouts/Layout.astro` with `title: string` and optional `description` props, Google Fonts preconnect + Geist+JetBrains Mono link tags in `<head>`, `import '../styles/global.css'`, `<body class="bg-dcv-bg text-slate-200 font-sans antialiased min-h-screen">`, and a default `<slot />` — per `plan.md` Step 4, `data-model.md` Layout.astro spec, and `contracts/component-api.md` Contract 1
- [x] T006 [US1] Create minimal `src/pages/index.astro` that renders only `<Layout title="dcv — The Developer CV Generator" />` with an empty body slot — this enables US1 independent verification before Hero exists — per `data-model.md` index.astro Content

**Checkpoint**: `npm run dev` renders a solid `#0f172a` dark page. DevTools Network tab confirms Geist Variable and JetBrains Mono load. No React/Vue/Svelte bundles present. This is the independently verifiable US1 deliverable.

---

## Phase 4: User Story 2 — The Terminal "Show, Don't Tell" (Priority: P1)

**Goal**: A split-panel Hero section with animated `dcv` CLI demo convinces a skeptical developer the tool is real and useful before they read a single line of copy.

**Independent Test**: Navigate to `http://localhost:4321`. Observe the split-panel layout (copy left, terminal right on desktop; stacked on mobile). Watch the terminal animate `dcv fetch` and `dcv export` commands with output, pause ~2s, then restart. Disable JS and confirm static fallback content is visible.

- [x] T007 [US2] Create `src/components/TerminalMockup.astro` with: `CommandSequence[]` and `pauseDuration` props; `<figure role="img" aria-label="...">` root; terminal chrome bar (slate-700, three colored circles); terminal body (slate-800, font-mono); `<script define:vars={{ commands, pauseDuration }}>` with the chained-`setTimeout` state machine (TYPING_INPUT 60ms/char → SHOWING_OUTPUT 300ms/line → PAUSED pauseDuration → CLEARING → loop); `<noscript>` fallback showing final command state; default `dcv fetch` and `dcv export` command sequence — per `plan.md` Step 5 (full animation skeleton and `define:vars` pattern), `data-model.md` TerminalMockup.astro spec (DOM structure + state machine table), and `contracts/component-api.md` Contract 3
- [x] T008 [US2] Create `src/components/Hero.astro` as a `<section aria-label="Hero">` with outer class `flex flex-col md:flex-row items-center gap-12 min-h-screen px-6 py-24 max-w-7xl mx-auto`; left panel `w-full md:w-1/2` containing H1 "Stop forgetting what you built.", sub-headline, descriptor, and CTA code block (`curl -fsSL https://get.dcv.sh/install.sh | sh`); right panel `w-full md:w-1/2` rendering `<TerminalMockup />`; copy panel first in DOM order — per `plan.md` Step 6, `data-model.md` Hero.astro spec, and `contracts/component-api.md` Contract 2
- [x] T009 [US2] Update `src/pages/index.astro` to import and render `<Hero />` inside `<Layout>` — replace the minimal US1 placeholder with the final Phase 1 page composition per `plan.md` Step 7 and `data-model.md` index.astro Content

**Checkpoint**: Full Hero section visible at `http://localhost:4321`. Animation cycles through both `dcv` commands. At 375px viewport — single column stack. At 1280px — split panel. JS disabled — noscript fallback readable. This is the independently verifiable US2 deliverable.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validate all four success criteria and confirm constitution compliance.

- [x] T010 Run `npm run build`; confirm `dist/` contains only `index.html`, `_astro/*.css`, `_astro/*.js` with no `.js` server bundles in `dist/` root; confirm `_astro/` has at most 1–2 JS files (animation only) — per `quickstart.md` SC-001
- [x] T011 [P] Test responsive layout: set viewport to 375px in DevTools and confirm single-column layout with no horizontal scroll; set to 1280px and confirm split-panel with both copy and terminal visible above the fold — per `quickstart.md` SC-002
- [x] T012 [P] Test terminal animation timing: confirm full cycle (TYPING_INPUT → SHOWING_OUTPUT → PAUSED 2s → CLEARING → restart) completes within 8 seconds; open DevTools Performance tab, record 10 seconds, confirm no CPU spike above ~5% — per `quickstart.md` SC-003
- [x] T013 [P] Test JS-disabled fallback: disable JS in DevTools → Settings → Debugger; reload; confirm all page text is readable and the `<noscript>` terminal content displays the final `dcv fetch --since/--until` command output — per `quickstart.md` SC-004
- [x] T014 [P] Audit constitution Rule V compliance: verify `<section aria-label="Hero">`, `<figure role="img" aria-label="...">` on TerminalMockup, all interactive/focusable elements have `aria-` labels, and `<main>` wraps slot content in `Layout.astro` as required by `contracts/component-api.md` Contract 1 — per `CLAUDE.md` Rule V
- [x] T015 [P] Test font fallback (EC-003): in DevTools Network tab block `fonts.googleapis.com`, reload, confirm page text remains readable using system fallback fonts (`ui-sans-serif`, `ui-monospace`) with no layout shift — per `spec.md` Edge Cases and `data-model.md` Design Token Schema font-stack values

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — BLOCKS both user stories
- **US1 (Phase 3)**: Depends on T003 (global.css must exist for Layout to import)
- **US2 (Phase 4)**: Depends on Phase 3 completion (Layout.astro must exist for Hero)
- **Polish (Phase 5)**: Depends on all Phase 4 tasks complete
- **T015** runs in parallel with T011–T014 in Phase 5 (independent network test)

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2 — no dependency on US2
- **US2 (P1)**: Can start after Phase 3 (US1) — Hero wraps TerminalMockup inside Layout

### Within Each Phase

- Phase 1: T001 → T002 (sequential — T002 modifies the project T001 creates)
- Phase 2: T003 and T004 are independent files — run in parallel
- Phase 3: T005 → T006 (sequential — T006 imports Layout from T005)
- Phase 4: T007 → T008 → T009 (sequential — each imports the previous)
- Phase 5: T010 first (build must succeed), then T011–T015 in parallel

### Parallel Opportunities

```bash
# Phase 2 — run together:
Task T003: Create src/styles/global.css
Task T004: Create public/favicon.svg

# Phase 5 — run together after T010 build passes:
Task T011: Responsive layout test (375px + 1280px)
Task T012: Animation timing + CPU test
Task T013: JS-disabled fallback test
Task T014: ARIA and semantics audit
Task T015: Font fallback test (block Google Fonts)
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1: Setup (T001, T002)
2. Complete Phase 2: Foundational (T003, T004)
3. Complete Phase 3: US1 (T005, T006)
4. **STOP and VALIDATE**: Dark page loads, fonts work, no JS bundles
5. Demo / share at this point if needed

### Full Phase 1 Delivery (Both User Stories)

1. Complete Setup + Foundational (T001–T004)
2. Complete US1 (T005–T006) → validate independently
3. Complete US2 (T007–T009) → validate independently
4. Complete Polish (T010–T015) → all SC criteria pass
5. Branch ready for PR to `develop`

---

## Notes

- [P] tasks = different files, no dependencies between them within their phase
- [Story] label maps each task to its user story for traceability to spec.md
- T007 (TerminalMockup) is the most complex single task — `plan.md` Step 5 contains the full animation skeleton and the critical `define:vars` pattern; read it before implementing
- T009 replaces T006's minimal index.astro — this is intentional and not a conflict
- All validation tasks (T010–T015) reference `quickstart.md` for exact pass/fail criteria
- Commit after each phase checkpoint, not after each individual task
