# Tasks: Lemon Squeezy Payment Integration

**Input**: Design documents from `/specs/005-lemonsqueezy-payments/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: No test tasks generated — no TDD approach requested in spec.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no blocking dependency on incomplete task)
- **[Story]**: Which user story this task belongs to
- No tests are included (not requested)

---

## Phase 1: Setup

**Purpose**: Confirm the existing project environment is ready — no new dependencies, no new directories at root level. The dcv-web project is fully bootstrapped.

- [x] T001 Read plan.md Component Interfaces, research.md Decisions 1-5, contracts/checkout-overlay.md, and contracts/success-page.md before writing any code — these documents contain the full specification for every file changed in this feature

**Checkpoint**: All design artifacts reviewed — implementation can begin

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Manual Lemon Squeezy dashboard configuration that produces the `CHECKOUT_URL` constant required by all US1 code tasks. No code can be finalized without this value.

**⚠️ CRITICAL**: T003 (CheckoutButton.astro) and T004 (success.astro) can be written with a placeholder URL, but T005 (wiring CheckoutButton into Pricing.astro) requires the real checkout URL. T007 (index.astro price prop) requires the final price from this step.

- [ ] T002 Configure DCV Pro product in Lemon Squeezy dashboard: create one-time purchase product, enable license key generation (one key per order), set Redirect URL to `https://apps.microcode.io/dcv/success` under Product Options → Confirmation Page, copy the Share URL — follow `quickstart.md` Steps 1–3 exactly (manual, no code changes)

**Output**: A checkout URL of the form `https://{store}.lemonsqueezy.com/buy/{variant-id}` and a finalized price string (e.g., `"$49"`) ready to embed in source code.

**Checkpoint**: Checkout URL obtained — `src/components/CheckoutButton.astro` and `src/pages/index.astro` can now be finalized

---

## Phase 3: User Story 1 — Purchase Pro License (Priority: P1) 🎯 MVP

**Goal**: A visitor on the pricing page can click "Buy Pro", complete payment through a Lemon Squeezy checkout overlay, and land on a branded `/dcv/success` confirmation page with activation instructions.

**Independent Test**: Click "Buy Pro" on the pricing page in a browser, verify the overlay opens, complete a LS test-mode purchase, verify redirect to `/dcv/success`, verify the page shows the activation command and docs link.

### Implementation for User Story 1

- [x] T003 [P] [US1] Create `src/components/CheckoutButton.astro`: render `<a href="{checkoutUrl}" class="lemonsqueezy-button">` with Tailwind styling matching the existing Pro CTA (Pricing.astro lines 69-76); add `<script>` that dynamically appends lemon.js to `<head>` with `script.onerror` handler that replaces the `<a>` with `<button disabled aria-disabled="true">` showing "Checkout temporarily unavailable" — disabled state Tailwind classes: `opacity-50 cursor-not-allowed pointer-events-none text-slate-400 border border-slate-600` (NO inline styles per Constitution Rule I); accept `checkoutUrl: string` (required) and `label: string` (optional, default `"Buy Pro"`) props — see `plan.md` Component Interfaces, `research.md` Decision 2, `contracts/checkout-overlay.md` Button States and WCAG requirements, `data-model.md` State Transitions

- [x] T004 [P] [US1] Create `src/pages/success.astro`: static page using `Layout.astro` as shell, with `<title>Purchase Successful — DCV</title>`; `<main>` wrapper containing `<h1>` confirmation heading, a paragraph confirming license key sent via email, a `<pre><code>dcv activate &lt;your-license-key&gt;</code></pre>` block instructing the user to substitute the key from their email, a link to `${import.meta.env.BASE_URL}/docs/installation` labelled "View installation docs", and a return link to `${import.meta.env.BASE_URL}/`; dark bg (`dcv-bg`), monospace font (JetBrains Mono) on code block, WCAG AA contrast — see `contracts/success-page.md` Required Content Elements, Layout & Styling Rules, and Accessibility

- [x] T005 [US1] Update `src/components/Pricing.astro`: import `CheckoutButton` from `./CheckoutButton.astro`; add `checkoutUrl: string` to the component's `Props` interface; replace the Pro tier `cta` object's `href: "#"` with the checkout URL received via prop; replace the `<a href={tier.cta.href}>` Pro tier CTA block (lines 69-76) with `<CheckoutButton checkoutUrl={checkoutUrl} />`; remove the `<!-- TODO: replace href="#" with checkout URL when payment is configured -->` comment — see `plan.md` Step 4, `data-model.md` Configuration Constants (depends on T003)

- [ ] T006 [P] [US1] Update CloudFront Response Headers Policy on the `apps.microcode.io` distribution: open AWS CloudFront console → the distribution from `DEPLOYMENT_GUIDE.md` → Behaviors → `/dcv/*` → Response headers policy; if a policy exists (from feature 004), edit it; otherwise create a new one; under Custom Headers add `Content-Security-Policy: script-src 'self' https://app.lemonsqueezy.com; frame-src https://assets.lemonsqueezy.com https://checkout.lemonsqueezy.com;`; save and deploy — see `plan.md` Step 7 and `research.md` Decision 5 (manual, parallelizable with T003-T005)

**Checkpoint**: User Story 1 is fully functional — overlay opens, purchase completes, `/dcv/success` renders correctly. All four acceptance tests in `contracts/checkout-overlay.md` and all four in `contracts/success-page.md` should pass.

---

## Phase 4: User Story 2 — View Accurate Pro Pricing (Priority: P2)

**Goal**: The pricing page displays the real Pro tier price instead of the `"[PRICE]"` placeholder.

**Independent Test**: Load the pricing page in a browser and verify the Pro tier shows a numeric price string (e.g., `"$49"`) — no `"[PRICE]"` text visible anywhere on the page.

### Implementation for User Story 2

- [x] T007 [US2] Update `src/pages/index.astro`: locate the `<Pricing />` component usage; add `proPrice="$XX"` prop using the finalized price string from T002; also add `checkoutUrl="https://..."` prop using the checkout URL from T002 (to thread through to CheckoutButton via Pricing.astro); verify value is NOT the placeholder string `"[PRICE]"` — see `plan.md` Step 5, `data-model.md` Product Variant validation rule (depends on T002 for price value, T005 for Pricing.astro prop interface)

**Checkpoint**: Pricing page shows correct numeric price and functional checkout button. User Stories 1 and 2 are both independently functional.

---

## Phase 5: User Story 3 — Access Customer Portal (Priority: P3)

**Goal**: A returning customer can retrieve their license key and invoices via the Lemon Squeezy customer portal link delivered in their purchase confirmation email.

**Independent Test**: Complete a test purchase and verify the confirmation email contains a customer portal link that, when clicked, shows the order details and license key.

### Implementation for User Story 3

- [ ] T008 [US3] Verify Lemon Squeezy sends a customer portal link in the purchase confirmation email: complete a test-mode purchase (requires T003, T004, T005, T006 complete and deployed to a preview environment), check the confirmation email for a portal link, click it and confirm the license key and invoice are accessible — no code changes required; this story is handled natively by Lemon Squeezy (manual verification only)

**Checkpoint**: All three user stories independently functional. No dcv-web code changes were needed for US3 — confirmed as a correct assumption.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Build verification, documentation, and end-to-end validation.

- [x] T009 Local build verification: run `npm run build` and confirm `dist/success.html` is emitted without errors, `dist/index.html` does not contain `href="#"` on the Pro CTA, no TypeScript errors; then run `npm run preview` and manually verify `http://localhost:4321/dcv/success` and `http://localhost:4321/dcv/` load correctly — see `plan.md` Step 6 (depends on T003, T004, T005, T007)

- [x] T010 [P] Update `DEPLOYMENT_GUIDE.md`: add "Step 19 — Configure CloudFront Response Headers Policy (Lemon Squeezy CSP)" section documenting the exact CSP directives added in T006, which behavior they apply to (`/dcv/*`), the note to verify LS iframe domains via browser DevTools during UAT, and the checkout URL location (`src/components/Pricing.astro` → `checkoutUrl` prop passed from `index.astro`) for future operators — see `plan.md` Step 8

- [ ] T011 End-to-end test: run all 9 items in `quickstart.md` Testing Checklist using Lemon Squeezy test mode against a deployed preview or production build; verify all acceptance tests pass: overlay opens (JS enabled), link redirect (JS disabled), disabled state (lemon.js blocked in DevTools), test purchase → `/dcv/success`, success page content, docs link, correct price display, discount code accepted, no CSP console errors; additionally verify: (a) receipt email and license key arrive within 5 minutes of test purchase (FR-004 / SC-002), (b) no tax-related errors shown during domestic test purchase (FR-006), (c) overlay opens and `/dcv/success` renders correctly on a 375px mobile viewport (SC-005 / contracts/success-page.md Acceptance Test 4) — see `plan.md` Step 9, `contracts/checkout-overlay.md` Acceptance Tests, `contracts/success-page.md` Acceptance Tests (depends on T006 CSP deployed, T009 build verified)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS finalization of T005 and T007 (requires real checkout URL and price)
- **User Story 1 (Phase 3)**: T003 and T004 can start with placeholder URL; T005 requires real URL from T002; T006 (CloudFront) is independent of code tasks
- **User Story 2 (Phase 4)**: T007 depends on T002 (price value) and T005 (Pricing.astro prop interface)
- **User Story 3 (Phase 5)**: T008 depends on full US1 code being deployed and LS product configured
- **Polish (Phase 6)**: T009 depends on all code tasks complete; T010 is independent documentation; T011 depends on T006 (CSP) and T009 (build verified)

### User Story Dependencies

- **User Story 1 (P1)**: Foundational phase complete → T003 and T004 in parallel → T005 → T006 in parallel with code
- **User Story 2 (P2)**: T005 complete → T007 (single task, small edit)
- **User Story 3 (P3)**: Full US1 deployed → T008 (manual verification)

### Within User Story 1

- T003 (`CheckoutButton.astro`) and T004 (`success.astro`) are fully independent — different new files
- T005 (`Pricing.astro`) depends on T003
- T006 (CloudFront CSP) is a manual AWS step independent of all code tasks
- T005 must complete before T007 (US2) since T007 uses the `checkoutUrl` prop added to `Pricing.astro` in T005

### Parallel Opportunities

- T003 and T004 can run simultaneously (different new files)
- T006 (CloudFront, manual) can be done at any time after T002 — no code dependency
- T010 (DEPLOYMENT_GUIDE.md update) can be written at any time — it's documentation

---

## Parallel Example: User Story 1

```
After T002 (checkout URL obtained):

  ┌─ T003: Create CheckoutButton.astro
  ├─ T004: Create success.astro          } run in parallel
  └─ T006: Update CloudFront CSP         } (independent files/systems)

Then:
  T005: Update Pricing.astro             (depends on T003)

Then:
  T007: Update index.astro               (depends on T005 + T002 for real values)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Read design artifacts
2. Complete Phase 2: LS dashboard setup — obtain checkout URL
3. Complete Phase 3: T003 → T004 (parallel) → T005 → T006 (parallel with code)
4. **STOP and VALIDATE**: Click "Buy Pro" overlay, complete test purchase, verify `/dcv/success`
5. Deploy MVP — payment integration is live

### Incremental Delivery

1. T001 → T002 → Foundation ready
2. T003 + T004 + T006 (parallel) → T005 → User Story 1 code complete → validate → deploy (MVP!)
3. T007 → User Story 2 — pricing shows real price → validate → deploy
4. T008 → User Story 3 — customer portal verified (no deploy needed)
5. T009 + T010 + T011 → Polish complete

### Single Developer Sequence

```
T001 (read docs) → T002 (LS dashboard, manual)
→ T003 + T004 (parallel, new files)
→ T005 (Pricing.astro update, needs T003)
→ T006 (CloudFront CSP, manual, can slot in anywhere)
→ T007 (index.astro price prop)
→ T008 (US3 portal verification, manual)
→ T009 (build verification)
→ T010 (DEPLOYMENT_GUIDE.md)
→ T011 (E2E test checklist)
```

---

## Notes

- **No new npm dependencies**: `lemon.js` is a CDN script, not installed — `npm install` is not needed for this feature
- **No test files**: Tests not requested; acceptance tests are manual browser checks defined in contracts/
- **2 manual AWS steps**: T006 (CloudFront CSP) and the UAT portion of T011 require AWS console access
- **3 manual LS steps**: T002 (dashboard setup), T008 (portal email verification), test purchases in T011
- **Commit strategy**: Commit after T003+T004 (new files), after T005+T007 (component/page updates), after T010 (docs update); do not commit T006/T008 (no code changes)
