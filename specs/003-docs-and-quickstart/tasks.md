# Tasks: Docs, Installation, & Quickstart (Phase 3)

**Input**: Design documents from `/specs/003-docs-and-quickstart/`
**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/component-api.md ✅ | quickstart.md ✅

**Tests**: Not requested — all verification is manual browser testing per quickstart.md.

**Organization**: Phases 1–2 build shared infrastructure. Phases 3–5 each add one Markdown content file independently testable per user story. Phase 6 completes the remaining doc file and cross-cutting verification.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on each other)
- **[Story]**: Which user story this task belongs to
- No story label on Setup, Foundational, and Polish phase tasks

---

## Phase 1: Setup

**Purpose**: Verify the Phase 2 baseline is intact and install the one new dependency before any new files are created.

- [x] T001 Run `npm run build` from repo root and confirm zero errors; confirm `dist/_astro/` contains only CSS and the inlined TerminalMockup script with no unexpected `.js` files (plan.md §Technical Context)
- [x] T002 Install `@tailwindcss/typography` by running `npm install @tailwindcss/typography` and confirm it appears in `package.json` dependencies (plan.md §Step 1)

**Checkpoint**: Build passes, dependency installed → T003–T007 can all start in parallel.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build all shared infrastructure — config, layout components, routing, global CSS, and site header — before any user story content is added.

**⚠️ CRITICAL**: No user story content file can be independently tested until T009 is complete.

**Note**: T003–T007 target different files with no dependencies on each other and MUST all run in parallel. T008 depends on T005 and T006. T009 depends on T008.

- [x] T003 [P] Register `@plugin "@tailwindcss/typography"` in `src/styles/global.css` — add this line immediately after the existing `@import "tailwindcss"` line, before the `@theme` block; preserve all existing `@theme` tokens (contracts/component-api.md §Contract 7)
- [x] T004 [P] Add `markdown: { shikiConfig: { theme: 'github-dark' } }` to `defineConfig` in `astro.config.mjs`; keep existing `output: 'static'` and `vite.plugins` unchanged (contracts/component-api.md §Contract 6)
- [x] T005 [P] Create `src/content/config.ts` — use Astro 5 Content Layer API with `glob` loader from `astro/loaders`; define `docs` collection with Zod schema requiring `title: z.string()`, `description: z.string()`, `order: z.number()`; export `collections = { docs }` (contracts/component-api.md §Contract 1; research.md §Decision 2)
- [x] T006 [P] Create `src/components/DocsSidebar.astro` — Props interface with `entries` array and `currentSlug: string`; render `<nav aria-label="Documentation navigation">` with `<ul>`/`<li>`/`<a>` structure; active link (`entry.id === currentSlug`) gets `text-dcv-accent font-bold`, inactive gets `text-slate-400 hover:text-slate-200 transition-colors`; no `<script>` tag (contracts/component-api.md §Contract 2)
- [x] T007 [P] Update `src/layouts/Layout.astro` — add a `<header class="border-b border-slate-800 px-6 py-4">` element immediately before the existing `<main>` tag; header contains `<nav class="max-w-5xl mx-auto flex items-center justify-between">` with a home logo link (`href="/"`, `text-slate-100 font-semibold text-sm`) and a Docs link (`href="/docs/installation"`, `text-slate-400 hover:text-slate-200 transition-colors text-sm`); MUST NOT alter the `<main><slot /></main>` structure or any existing styles (contracts/component-api.md §Contract 5)
- [x] T008 Create `src/layouts/DocsLayout.astro` — frontmatter block MUST call `getCollection('docs')` and sort entries by `order` ascending; Props interface: `title`, `description`, `currentSlug`; output: `<Layout title={title} description={description}>` wrapping a `<div class="flex flex-col md:flex-row min-h-screen">` containing `<aside>` (DocsSidebar with `entries={sortedEntries}`) and `<div class="flex-1 min-w-0 overflow-hidden p-6 md:p-12">` (NOT `<main>` — Layout.astro already provides `<main>`) containing `<article class="prose prose-invert max-w-none prose-pre:overflow-x-auto prose-pre:bg-slate-800"><slot /></article>`; sidebar classes: `w-full md:w-64 md:shrink-0 md:sticky md:top-0 md:h-screen md:overflow-y-auto bg-slate-900 border-b md:border-b-0 md:border-r border-slate-800 p-6` (contracts/component-api.md §Contract 3; research.md §Decision 3, D4, D6)
- [x] T009 Create `src/pages/docs/[...slug].astro` — `getStaticPaths` calls `getCollection('docs')` and maps each entry to `{ params: { slug: entry.id }, props: { entry } }`; page frontmatter destructures `entry` from `Astro.props` and `slug` from `Astro.params`; calls `entry.render()` to get `Content`; renders `<DocsLayout title={entry.data.title} description={entry.data.description} currentSlug={slug}><Content /></DocsLayout>` (contracts/component-api.md §Contract 4)

**Checkpoint**: All infrastructure is in place. `npm run dev` starts without errors (build may warn about empty collection — that is expected until Phase 3). T010 can now begin.

---

## Phase 3: User Story 1 — The 30-Second Install (Priority: P1) 🎯 MVP

**Goal**: Deliver a working `/docs/installation` page with sidebar navigation, syntax-highlighted curl install command, and the Docs nav link on the landing page — enough for a developer to find and copy the install command in one click.

**Independent Test**: Navigate to `http://localhost:4321/docs/installation`. Verify: two-column layout with sidebar on left; sidebar shows "Installation" link highlighted in `text-dcv-accent`; code block containing `curl -fsSL https://dcv.dev/install.sh | bash` is syntax-highlighted with dark background; Docs nav link is visible in the site header. (Full steps: quickstart.md §Scenario 1 and §Scenario 4)

### Implementation for User Story 1

- [x] T010 [US1] Create `src/content/docs/installation.md` with frontmatter `title: "Installation"`, `description: "Install the dcv binary on macOS, Linux, or Windows."`, `order: 1`; body MUST include `## Quick Install (Recommended)` section with a `bash` fenced code block containing `curl -fsSL https://dcv.dev/install.sh | bash`; `## Manual Binary Download` section with platform binary table (macOS arm64/x86_64, Linux x86_64, Windows); `chmod`/`mv` commands; `dcv --version` verification step (data-model.md §Content Outline →installation.md)

**Checkpoint**: Dev server renders `/docs/installation` with sidebar + highlighted curl command. Docs nav link on landing page navigates here in 1 click. All Phase 3 independent test criteria pass.

---

## Phase 4: User Story 2 — Following the Quickstart (Priority: P1)

**Goal**: Deliver a working `/docs/quickstart` page with step-by-step headings and correct active sidebar state, giving a just-installed user a complete linear path from `dcv init` to report output.

**Independent Test**: Navigate to `http://localhost:4321/docs/quickstart`. Verify: "Quickstart" sidebar link shows `text-dcv-accent font-bold`; document contains `## Step 1: Initialize`, `## Step 2: Fetch Data`, `## Step 3: Analyze` headings; each step has a highlighted `bash` code block with the correct command. (Full steps: quickstart.md §Scenario 2)

### Implementation for User Story 2

- [x] T011 [US2] Create `src/content/docs/quickstart.md` with frontmatter `title: "Quickstart"`, `description: "Run your first dcv report in under 5 minutes."`, `order: 2`; body MUST include `## Step 1: Initialize` with `bash` block containing `dcv init`; `## Step 2: Fetch Data` with `bash` block containing `dcv fetch`; `## Step 3: Analyze` with `bash` block containing `dcv analyze`; output note referencing `./dcv-report.md` (data-model.md §Content Outline →quickstart.md)

**Checkpoint**: Dev server renders `/docs/quickstart` with "Quickstart" sidebar link active. Sidebar active state changes correctly when navigating between Installation and Quickstart.

---

## Phase 5: User Story 3 — Mobile Documentation Reading (Priority: P2)

**Goal**: Deliver a `/docs/configuration` page with a wide JSON schema code block that triggers and validates the mobile horizontal-scroll behavior, confirming SC-003 compliance.

**Independent Test**: At 375px viewport: sidebar collapses above content (no overlap); body text readable with no page-level horizontal scroll; JSON schema `<pre>` block scrolls horizontally within its container. (Full steps: quickstart.md §Scenario 3)

### Implementation for User Story 3

- [x] T012 [US3] Create `src/content/docs/configuration.md` with frontmatter `title: "Configuration"`, `description: "Configure dcv with ~/.dcv/config.json."`, `order: 3`; body MUST include `## Schema` section with `json` fenced code block containing the full config object (`sources`, `providers.openai.apiKey`, `output.format`, `output.path`); `## Fields` section with a Markdown table documenting each field (type, default, description) — this table is intentionally wide to trigger horizontal scroll testing on mobile (data-model.md §Content Outline →configuration.md)

**Checkpoint**: At 375px, sidebar collapses above content, JSON code block scrolls horizontally inside `<pre>` container without causing page-level overflow.

---

## Phase 6: Polish & Cross-Cutting Verification

**Purpose**: Complete the four-file doc set, run a full build verification, and confirm all success criteria across the assembled site.

- [x] T013 Create `src/content/docs/changelog.md` with frontmatter `title: "Changelog"`, `description: "Release history for dcv v1.x.x."`, `order: 4`; body MUST include `## v1.0.0 — 2026-03-06` with `### Added` list covering `dcv init`, `dcv fetch`, `dcv analyze`, and BYO-LLM key support (data-model.md §Content Outline →changelog.md) — Note: changelog has no owning user story; it completes FR-005 and is intentionally placed in Polish phase
- [x] T014 Run `npm run build` and verify SC-001 + SC-002: confirm `dist/docs/` contains four subdirectories (`installation/`, `quickstart/`, `configuration/`, `changelog/`), each with `index.html`; confirm `dist/_astro/` contains no new `.js` files beyond Phase 2 baseline; confirm `dist/docs/installation/index.html` contains the string `curl -fsSL` (quickstart.md §Scenario 6; contracts/component-api.md §Contract 4 verification)
- [x] T015 [P] Browser-verify Docs nav link — from `http://localhost:4321`, confirm "Docs" link is visible in site header; click it; confirm landing is `/docs/installation`; count clicks: MUST be ≤ 2 from landing page to curl command (quickstart.md §Scenario 4; SC-004)
- [x] T016 [P] Browser-verify zero JavaScript — open DevTools Network tab filtered by JS; hard-reload `/docs/installation`; confirm no `.js` requests from docs components; then disable JavaScript entirely and reload; confirm all four doc pages remain fully readable with correct layout (quickstart.md §Scenario 5; SC-002)
- [x] T017 [P] Frontmatter validation test — edit `src/content/docs/installation.md` and remove the `order` field; run `npm run build`; confirm build fails with a Zod validation error mentioning `order`; restore the field and confirm build passes (quickstart.md §Scenario 7; contracts/component-api.md §Contract 1 verification)
- [x] T018 [P] Browser-verify mobile layout SC-003 — set DevTools viewport to 375px; navigate to `http://localhost:4321/docs/configuration`; confirm sidebar collapses above main content (stacked, no overlap); confirm JSON `<pre>` block scrolls horizontally within its container without causing page-level horizontal overflow; confirm body text remains readable with no page overflow (quickstart.md §Scenario 3; spec.md SC-003)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion; T003–T007 are parallel; T008 depends on T005 + T006; T009 depends on T008
- **User Stories (Phases 3–5)**: All depend on Phase 2 (T009) completion; T010, T011, T012 are independent of each other and can run in parallel once T009 is done
- **Polish (Phase 6)**: Depends on T010–T012 all complete; T013 can run earlier (independent of US1/US2/US3 stories); T015–T018 are parallel

### User Story Dependencies

- **US1 (T010)**: Unblocked after T009 — no dependency on US2 or US3
- **US2 (T011)**: Unblocked after T009 — no dependency on US1 or US3
- **US3 (T012)**: Unblocked after T009 — no dependency on US1 or US2
- All three feed into Phase 6, which is the convergence point

### Within Each User Story

Each story is a single-task content file. All design artifacts provide the exact frontmatter values, headings, body copy, and code block content needed to complete each task without additional research.

### Parallel Opportunities

```text
T001 → T002 → ┬─ T003 [P] ─┐
               ├─ T004 [P] ─┤
               ├─ T005 [P] ─┼─ T008 → T009 → ┬─ T010 [US1] ─┐
               ├─ T006 [P] ─┘                 ├─ T011 [US2] ─┼─ T013 → T014 → ┬─ T015 [P]
               └─ T007 [P]                    └─ T012 [US3] ─┘                 ├─ T016 [P]
                                                                                ├─ T017 [P]
                                                                                └─ T018 [P]
```

---

## Parallel Example: Phase 2 Foundation

```bash
# After T001 and T002 complete, launch all five in parallel:
Task A: "Register @plugin in src/styles/global.css"                  (T003)
Task B: "Configure github-dark Shiki in astro.config.mjs"            (T004)
Task C: "Create src/content/config.ts with Content Layer schema"      (T005)
Task D: "Create src/components/DocsSidebar.astro"                    (T006)
Task E: "Update src/layouts/Layout.astro with global header"         (T007)

# After A–E complete:
Task F: "Create src/layouts/DocsLayout.astro"                        (T008)

# After F:
Task G: "Create src/pages/docs/[...slug].astro"                      (T009)
```

## Parallel Example: Content Files (after T009)

```bash
# After T009 completes, all three content files can start in parallel:
Task A: "Create src/content/docs/installation.md"   (T010 — US1)
Task B: "Create src/content/docs/quickstart.md"     (T011 — US2)
Task C: "Create src/content/docs/configuration.md"  (T012 — US3)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003–T009) — full infrastructure
3. Complete Phase 3: User Story 1 (T010) — installation.md
4. **STOP and VALIDATE**: `/docs/installation` renders correctly with sidebar, syntax-highlighted curl command, and Docs nav link
5. Proceed to US2 and US3

### Full Incremental Delivery

1. Phase 1 Setup (T001–T002) → dependency installed, baseline confirmed
2. Phase 2 Foundation (T003–T009) → all infrastructure ready
3. Phase 3 US1 (T010) → first page live
4. Phase 4 US2 (T011) → second page live, active state verified
5. Phase 5 US3 (T012) → third page live, mobile behavior confirmed
6. Phase 6 Polish (T013–T017) → four-page doc set complete, build verified

### Single-Developer Sequence

```text
T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008 → T009 → T010 → T011 → T012 → T013 → T014 → T015 → T016 → T017 → T018
```

---

## Notes

- **No test tasks**: Spec does not request TDD; verification is manual browser testing per quickstart.md
- **Exact content is mandated**: All frontmatter values, section headings, and code block content are specified in `data-model.md §Content Outline` — no invention needed during implementation
- **Nested `<main>` is a known trap**: T008 (DocsLayout) MUST use `<div>` for the content column, NOT `<main>`. Layout.astro already wraps everything in `<main>`. See contracts/component-api.md §Contract 3 constraint note.
- **No `/docs` index route**: Navigating to bare `/docs` will 404 by design. All links point to `/docs/installation`. This is documented in spec.md §Assumptions and research.md §Decision 7.
- **Content Layer API difference**: Entry identifier is `entry.id` (not `entry.slug` from the legacy API). See research.md §Decision 2.
- **T008 is the convergence point**: DocsLayout is the only task that creates a two-file dependency (needs both T005 for `getCollection` and T006 for `<DocsSidebar />`). It must come after both.
