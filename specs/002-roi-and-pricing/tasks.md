# Tasks: Differentiators, ROI, & Pricing (Phase 2)

**Input**: Design documents from `/specs/002-roi-and-pricing/`
**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/component-api.md ✅ | quickstart.md ✅

**Tests**: Not requested — all verification is manual browser testing per quickstart.md.

**Organization**: Tasks grouped by user story. Components T003/T004/T005 are fully
parallelizable (separate files, no shared state). T006 (assembly) is the only task
that depends on all three component tasks completing first.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on each other)
- **[Story]**: Which user story this task belongs to
- No story label on Setup and Polish phase tasks

---

## Phase 1: Setup

**Purpose**: Confirm Phase 1 baseline is intact before any new files are created.

**Note**: No separate Foundational phase is needed — there is no shared infrastructure
to build before user stories can begin. Phase 1 completion directly unblocks T003/T004/T005
in parallel.

- [x] T001 Run `npm run build` from repo root and confirm zero build errors; confirm `dist/_astro/` contains only CSS and the inlined TerminalMockup script with no unexpected `.js` files (plan.md §Implementation Steps Step 1)
- [x] T002 Read `src/pages/index.astro` to confirm the current import baseline (Layout + Hero only) before modification (contracts/component-api.md §Contract 4)

**Checkpoint**: Build passes, baseline confirmed → T003, T004, T005 can all start in parallel.

---

## Phase 2: User Story 1 — Reading the Anti-Features (Priority: P1) 🎯 MVP

**Goal**: Deliver a responsive 3-column anti-feature grid that visually establishes
dcv's privacy and autonomy guarantees before pricing is shown.

**Independent Test**: Navigate to `http://localhost:4321`, scroll past Hero, verify 3 cards
render on desktop (3-column) and collapse to 1-column at 375px with no horizontal scroll.
Inspect source: each `<svg>` has `aria-hidden="true"`. No `<script>` tags in component.
(Full steps: quickstart.md §Scenario 1)

### Implementation for User Story 1

- [x] T003 [P] [US1] Create `src/components/FeatureGrid.astro` with complete Differentiator TypeScript interface, hardcoded `differentiators` array (exact SVG strings, titles, and descriptions) from `data-model.md §Entity: Differentiator → Phase 2 required instances`; `<section aria-label="Why dcv">` wrapper; `<h2>What dcv doesn't do</h2>` heading; `grid grid-cols-1 md:grid-cols-3 gap-6` container per `research.md §Decision 2`; per-card `<article>` with `<span set:html={item.icon} />` per `research.md §Decision 1`, `<h3>` title, `<p>` description; card theme `bg-slate-800 text-slate-200 min-w-0 overflow-hidden`; satisfy all requirements in `contracts/component-api.md §Contract 1`

**Checkpoint**: `FeatureGrid.astro` created and satisfies Contract 1. Temporarily import
into `index.astro` to visually verify before proceeding (revert import before T006).

---

## Phase 3: User Story 2 — Understanding the ROI (Priority: P1)

**Goal**: Deliver a two-panel Before/After section that concretely demonstrates the
commit-to-STAR-bullet transformation, making dcv's value immediately tangible.

**Independent Test**: Scroll to ROI section; verify `fix(cache): resolve race condition in redis worker`
appears in monospace font on the left; verify "Action" and "Result" labeled pairs appear
as prose on the right in a visually distinct panel. Inspect source: `<h2>` present, `<dl>`/`<dt>`/`<dd>`
structure in After panel. (Full steps: quickstart.md §Scenario 2)

### Implementation for User Story 2

- [x] T004 [P] [US2] Create `src/components/RoiSection.astro` with complete `RoiContentPair` and `RoiExample` TypeScript interfaces plus the hardcoded `roiExample` object from `data-model.md §Entity: RoiExample → Phase 2 hardcoded instance`; `<section aria-label="ROI section">` wrapper; `<h2>From Commits to Compensation</h2>` heading; two-panel `flex flex-col md:flex-row` layout; Before panel with `<h3>` label and `<code class="font-mono">` for commit text; After panel with `<h3>` label and `<dl>` / `<div>` / `<dt>` / `<dd>` structure per `research.md §Decision 3` (including exact Tailwind classes for `<dt>`: `text-sm font-semibold text-dcv-accent uppercase tracking-wide`); visual distinction between panels via differing backgrounds or borders; satisfy all requirements in `contracts/component-api.md §Contract 2`

**Checkpoint**: `RoiSection.astro` created and satisfies Contract 2. Can be verified in
isolation by temporarily importing into `index.astro` (revert before T006).

---

## Phase 4: User Story 3 — Evaluating the Price (Priority: P1)

**Goal**: Deliver transparent Free/Pro pricing cards with perpetual license copy and
a visually prominent Pro CTA, so a buyer can determine price, features, and license
terms from the card alone.

**Independent Test**: Scroll to Pricing section; verify two cards side-by-side on desktop,
stacked on mobile; Free card has no `<button>`, only an `<a>`; Pro card shows `[PRICE]`
placeholder, lists all 4 Pro features, and displays the exact perpetual license string;
Pro CTA button uses `bg-dcv-accent` cyan color; inspect source for both TODO comments.
(Full steps: quickstart.md §Scenario 3)

### Implementation for User Story 3

- [x] T005 [P] [US3] Create `src/components/Pricing.astro` with `Props` interface (`proPrice?: string`, default `"[PRICE]"`) per `research.md §Decision 4`; `PricingCta` and `PricingTier` interfaces; hardcoded Free and Pro tier objects using exact feature arrays and CTA values from `data-model.md §Entity: PricingTier → Phase 2 instances`; Pro tier `price` field set to `proPrice` prop; `<section aria-label="Pricing">` wrapper; `<h2>Simple, Transparent Pricing</h2>` heading; `grid grid-cols-1 md:grid-cols-2 gap-8` card layout; each card with `<h3>` name, price display, `<ul>`/`<li>` feature list; perpetual license copy `"Perpetual License for v1.x.x — includes all minor updates and patches."` as visible text in Pro card body (not only in features list); Free CTA as plain `<a>` (no `<button>`); Pro CTA as `<a href="#">` styled with `bg-dcv-accent text-dcv-bg font-semibold`; `<!-- TODO: replace href="#" with checkout URL when payment is configured -->` comment in source; `min-w-0 overflow-hidden` on all cards; satisfy all requirements in `contracts/component-api.md §Contract 3`

**Checkpoint**: `Pricing.astro` created and satisfies Contract 3. Can be verified in
isolation by temporarily importing into `index.astro` with `proPrice="[PRICE]"`.

---

## Phase 5: Assembly

**Purpose**: Wire all three components into the index page in the mandated order.

**⚠️ CRITICAL**: Do not begin T006 until T003, T004, and T005 are all complete.

- [x] T006 Update `src/pages/index.astro` — replace file content with the exact code block from `contracts/component-api.md §Contract 4 → Required Changes`: add imports for FeatureGrid, RoiSection, Pricing; render in mandated order `<Hero /> → <FeatureGrid /> → <RoiSection /> → <Pricing proPrice="[PRICE]" />`; include `<!-- TODO: replace proPrice when payment is configured -->` comment adjacent to `<Pricing />`; section order MUST NOT be changed (spec.md §Assumptions)

**Checkpoint**: Dev server renders all four sections in correct scroll order. All Phase 2–4
independent tests now pass on the fully assembled page.

---

## Phase 6: Polish & Cross-Cutting Verification

**Purpose**: Validate all success criteria (SC-001–SC-004) against the assembled page.

- [x] T007 Run `npm run build` and verify SC-003 — open `dist/_astro/`, confirm no new `.js` files beyond Phase 1 baseline; open DevTools Network tab filtered by JS, hard-reload preview, confirm zero new `.js` requests from Phase 2 components (quickstart.md §Scenario 5)
- [x] T008 [P] Browser-verify FeatureGrid at desktop (≥ 768px) and mobile (375px) — 3-column → 1-column collapse, no horizontal scroll, SVG `aria-hidden="true"` in source, card content matches data-model.md instances (quickstart.md §Scenario 1)
- [x] T009 [P] Browser-verify RoiSection — two-panel layout side-by-side on desktop, stacked on mobile; resize to 375px and confirm no horizontal scroll (spec.md Edge Case 3); Before panel in `font-mono`; After panel `<dl>`/`<dt>`/`<dd>` with Action + Result fields; panels visually distinct (quickstart.md §Scenario 2)
- [x] T010 [P] Browser-verify Pricing — Free/Pro cards, exact perpetual license string in Pro card, Pro CTA uses accent color, Free card has no `<button>`, both TODO comments present in source (quickstart.md §Scenario 3)
- [x] T011 Disable JavaScript in DevTools and verify SC-004 — all three sections (FeatureGrid, RoiSection, Pricing) fully readable and laid out correctly with JS disabled (quickstart.md §Scenario 4)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **User Stories (Phases 2–4)**: Depend on Phase 1 completion; T003/T004/T005 are independent of each other and can run in parallel
- **Assembly (Phase 5)**: Depends on T003 + T004 + T005 all complete — this is the only blocking dependency
- **Polish (Phase 6)**: Depends on T006 (Assembly) complete

### User Story Dependencies

- **US1 (T003)**: Unblocked after Phase 1 — no dependency on US2 or US3
- **US2 (T004)**: Unblocked after Phase 1 — no dependency on US1 or US3
- **US3 (T005)**: Unblocked after Phase 1 — no dependency on US1 or US2
- All three feed into Assembly (T006), which is the convergence point

### Within Each User Story

Each story is a single-task implementation (the component is self-contained). The design
artifacts provide all data, TypeScript types, Tailwind classes, and exact copy strings
needed to complete the task without additional research.

### Parallel Opportunities

```text
T001 → T002 → ┬─ T003 [US1] ─┐
               ├─ T004 [US2] ─┼─ T006 → T007 → ┬─ T008 [P]
               └─ T005 [US3] ─┘                 ├─ T009 [P]
                                                 ├─ T010 [P]
                                                 └─ T011
```

---

## Parallel Example: All Three Components

```bash
# After T001 and T002 complete, launch all three in parallel:
Task A: "Create src/components/FeatureGrid.astro" (T003)
Task B: "Create src/components/RoiSection.astro"  (T004)
Task C: "Create src/components/Pricing.astro"     (T005)

# After A, B, C all complete:
Task D: "Update src/pages/index.astro"            (T006)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001, T002)
2. Complete Phase 2: User Story 1 (T003)
3. Temporarily wire FeatureGrid into index.astro
4. **STOP and VALIDATE**: 3-column grid, correct cards, SVG icons, mobile collapse
5. Proceed to US2 and US3

### Full Incremental Delivery

1. Phase 1 Setup (T001–T002) → baseline confirmed
2. Phases 2–4 Components in parallel (T003 + T004 + T005) → all three components ready
3. Phase 5 Assembly (T006) → full page assembled
4. Phase 6 Build check (T007) → SC-003 confirmed
5. Phase 6 Browser verification (T008–T011) → all SC criteria confirmed
6. Feature complete

### Single-Developer Sequence

```text
T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008 → T009 → T010 → T011
```

---

## Notes

- **No test tasks**: Spec does not request TDD; verification is manual browser testing per quickstart.md
- **No foundational phase**: Stack fully inherited from Phase 1; zero new dependencies or config needed
- **Data is complete**: All SVG strings, copy text, and TypeScript types are specified in data-model.md — no invention needed during implementation
- **Exact strings are mandated**: `<h2>` text, perpetual license copy, and TODO comment text must match contracts/component-api.md exactly — no paraphrasing
- **[P] tasks**: T004 and T005 carry [P] markers because they target different files from T003 with no shared state
- **Assembly is the convergence point**: T006 is the only task that creates a file dependency (index.astro) across stories; it must come last in the implementation chain
