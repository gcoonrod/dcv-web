# Implementation Plan: Lemon Squeezy Payment Integration

**Branch**: `005-lemonsqueezy-payments` | **Date**: 2026-03-11 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-lemonsqueezy-payments/spec.md`

## Summary

Integrate Lemon Squeezy as the payment platform for the DCV Pro perpetual license. The integration adds a new `CheckoutButton` Astro component that loads the Lemon Squeezy overlay script and promotes the "Buy Pro" button from a placeholder link to a working checkout trigger. A new static `/dcv/success` confirmation page is added for post-purchase activation instructions. The existing `Pricing.astro` component is updated to use the real checkout URL and display the actual price. CloudFront Response Headers are updated to permit the Lemon Squeezy JS and iframe domains. The site remains fully static throughout.

---

## Technical Context

**Language/Version**: TypeScript (strict) — Node.js 20 LTS
**Primary Dependencies**: Astro 5.18.x, `@tailwindcss/vite` (Tailwind CSS v4), Lemon Squeezy `lemon.js` (external CDN script — no npm install)
**Storage**: N/A — no persistent data on dcv-web; all data owned by Lemon Squeezy
**Testing**: Manual browser testing + Lemon Squeezy test mode
**Target Platform**: Static HTML/CSS/JS — AWS S3 + CloudFront
**Project Type**: Static marketing/product site
**Performance Goals**: No degradation to existing page load; `lemon.js` loads with `defer` (non-blocking)
**Constraints**: `output: 'static'` MUST remain; no SSR adapter; no new npm dependencies beyond existing stack
**Scale/Scope**: Single-product checkout; single-seat purchases only

---

## Constitution Check

*GATE: Must pass before implementation. Re-checked post-design.*

### Core Principles

| Principle | Status | Notes |
|-----------|--------|-------|
| I — Zero-JavaScript Default (Static First) | ✅ PASS (with note) | `/dcv/success` page is fully static. `CheckoutButton` renders as a plain `<a>` link without JS — purchase path works via redirect. LS script enhances to overlay. See Complexity Tracking for FR-009 nuance. |
| II — Developer-Centric Aesthetic | ✅ PASS | Dark theme, monospace activation command block on success page |
| III — Infrastructure Simplicity (AWS Native) | ✅ PASS | Static `dist/` output; CSP via CloudFront Response Headers Policy (no Lambda@Edge) |

### Bright-Line Rules

| Rule | Status | Notes |
|------|--------|-------|
| I — Tailwind CSS Only | ✅ PASS | All new styling via utility classes |
| II — Strict Island Architecture | ✅ PASS | `CheckoutButton.astro` uses a scoped `<script>` tag (Astro auto-scopes as a module); no global JS bundle |
| III — Vanilla JS Preference | ✅ PASS | Plain `<script>` tag; no framework installed |
| IV — Asset Optimization | ✅ PASS | No new images/assets introduced |
| V — Accessibility & Semantics | ✅ PASS | Disabled button state uses `aria-disabled="true"`; success page uses `<main>`, `<h1>`, semantic code blocks |

---

## Project Structure

### Documentation (this feature)

```text
specs/005-lemonsqueezy-payments/
├── plan.md              # This file
├── research.md          # Phase 0: Lemon Squeezy integration research
├── data-model.md        # Phase 1: Entities and state model
├── quickstart.md        # Phase 1: Setup and testing guide
├── contracts/
│   ├── checkout-overlay.md  # Checkout button interaction contract
│   └── success-page.md      # /dcv/success page contract
└── tasks.md             # Phase 2 output (/speckit.tasks — not yet created)
```

### Source Code (repository root)

```text
src/
├── components/
│   ├── CheckoutButton.astro   # NEW: Lemon Squeezy overlay button component
│   ├── Pricing.astro          # MODIFIED: use CheckoutButton, real price, remove TODO
│   ├── Hero.astro             # unchanged
│   ├── FeatureGrid.astro      # unchanged
│   ├── RoiSection.astro       # unchanged
│   └── TerminalMockup.astro   # unchanged
├── layouts/
│   └── Layout.astro           # unchanged
└── pages/
    ├── index.astro            # MODIFIED: pass real proPrice prop to Pricing
    ├── success.astro          # NEW: /dcv/success confirmation page
    └── docs/                  # unchanged

public/                        # unchanged
```

**Structure Decision**: Extending the existing Astro project structure. No new directories at the root level. The new `CheckoutButton` component lives alongside existing components. The new `success.astro` page lives alongside `index.astro` following Astro's file-based routing convention.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| FR-009: Disabled button state when LS script fails (minor tension with Constitution I) | User explicitly selected "disabled + message" as the failure behavior (clarification Q2). A JS-enabled user whose LS script fails gets a clear "unavailable" signal rather than a silent broken link. | Fallback-link approach (button redirects to LS hosted checkout on failure) satisfies Constitution I more cleanly but was explicitly rejected by the user in favour of a clearer unavailability signal. The baseline no-JS behavior (plain link) fully satisfies Constitution I; the disabled state only applies when JS is enabled AND the LS script specifically fails — a narrow, intentional trade-off. |

---

## Component Interfaces

### `CheckoutButton.astro` (new)

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `checkoutUrl` | `string` | Yes | The full Lemon Squeezy hosted checkout URL (e.g., `https://gcoonrod.lemonsqueezy.com/buy/{variant-id}`). Hardcoded at call-site in `Pricing.astro` — NOT read from env or fetched at runtime. See `data-model.md` → Configuration Constants for the `CHECKOUT_URL` constant. |
| `label` | `string` | No | Button label text. Defaults to `"Buy Pro"`. |

**Rendered HTML structure** (server-side, before JS):
```html
<a href="{checkoutUrl}" class="lemonsqueezy-button [tailwind classes]">
  Buy Pro
</a>
```

**Script behavior**: A `<script>` tag in the component dynamically appends the `lemon.js` script element to `<head>`. On `script.onerror`, the `<a>` element is replaced with a disabled `<button>` showing "Checkout temporarily unavailable" and `aria-disabled="true"`. On `script.onload`, lemon.js auto-binds the overlay to `.lemonsqueezy-button` elements — no additional JS call needed.

**Reference**: `research.md` Decision 1 (overlay pattern) + Decision 2 (degradation strategy), `data-model.md` Entity 6 (button states), `contracts/checkout-overlay.md` (button states and WCAG requirements).

---

### `success.astro` (new)

No Astro props. Fully static page. Uses `Layout.astro` as its shell.

**Required content** (exact elements): see `contracts/success-page.md` → Required Content Elements table.
**Styling rules**: see `contracts/success-page.md` → Layout & Styling Rules.
**Accessibility requirements**: see `contracts/success-page.md` → Accessibility.
**CloudFront routing**: no additional configuration needed — see `contracts/success-page.md` → CloudFront Routing.

---

## Manual Pre-Deployment Steps

The following steps MUST be completed by the developer before deploying this feature. They require access to external systems and cannot be automated:

1. **Lemon Squeezy**: Create the "DCV Pro" product and configure pricing, license key generation, and the success redirect URL (`https://apps.microcode.io/dcv/success`) — see `quickstart.md` Steps 1–3
2. **Source code**: Embed the checkout URL as the `checkoutUrl` prop in `Pricing.astro` and the final price as the `proPrice` prop in `index.astro` — see Component Interfaces above and `data-model.md` → Configuration Constants
3. **AWS CloudFront**: Add CSP directives to the distribution's Response Headers Policy — see Implementation Sequence Step 7 and `quickstart.md` Step 7. Check first whether an existing policy is attached to the distribution (from feature 004); if so, amend it rather than creating a new one.
4. **UAT**: Verify CSP headers allow the LS script and overlay iframe without console errors — see `quickstart.md` → Testing Checklist

---

## Implementation Sequence

Each step references the specific artifacts that specify its requirements. An implementer MUST read the referenced documents before writing code for that step.

### Step 1 — Lemon Squeezy Dashboard Setup *(manual, pre-code)*

**What**: Create the DCV Pro product in the LS dashboard, enable license key generation, set the success redirect URL, and copy the checkout URL.

**How**: Follow `quickstart.md` Steps 1–3 exactly.

**Output**: A checkout URL of the form `https://{store}.lemonsqueezy.com/buy/{variant-id}` ready to embed in source code.

**Done when**: Test purchase in LS test mode completes and redirects to `https://apps.microcode.io/dcv/success`.

---

### Step 2 — Create `src/components/CheckoutButton.astro` *(new file)*

**What**: New Astro component wrapping the Lemon Squeezy overlay button with graceful degradation.

**Specification**:
- Props interface: see **Component Interfaces → `CheckoutButton.astro`** above
- Button states (default / ready / unavailable) and WCAG requirements: `contracts/checkout-overlay.md` → Button States
- Script loading pattern and `onerror` DOM update logic: `research.md` Decision 2 (Graceful Degradation Strategy)
- State transition diagram: `data-model.md` → State Transitions
- Tailwind styling: match the existing "Buy Pro" button in `src/components/Pricing.astro` (lines 69-76)

**Done when**: All four acceptance tests in `contracts/checkout-overlay.md` pass manually in a browser.

---

### Step 3 — Create `src/pages/success.astro` *(new file)*

**What**: New fully static post-purchase confirmation page served at `/dcv/success`.

**Specification**:
- Required content elements (title, heading, confirmation text, activation command, links): `contracts/success-page.md` → Required Content Elements
- Styling rules (Tailwind only, dark bg, JetBrains Mono for code block): `contracts/success-page.md` → Layout & Styling Rules
- Accessibility requirements (semantic HTML, WCAG AA): `contracts/success-page.md` → Accessibility
- Page shell: use `Layout.astro` (same as `index.astro` and docs pages)

**Done when**: All four acceptance tests in `contracts/success-page.md` pass; `npm run build` emits `dist/success.html` without errors.

---

### Step 4 — Update `src/components/Pricing.astro`

**What**: Replace the Pro tier's placeholder `href="#"` CTA with `<CheckoutButton>` and remove the `<!-- TODO -->` comment.

**Changes**:
- Import and use `CheckoutButton.astro` for the Pro tier CTA (replaces the `<a href={tier.cta.href}>` block for the Pro tier, lines 69-76)
- Pass `checkoutUrl` as a prop — value comes from `Pricing.astro`'s own props or hardcoded constant; see **Component Interfaces → `CheckoutButton.astro`** above for the prop name
- The `proPrice` prop already exists on `Pricing.astro` — it will receive its value from `index.astro` (Step 5)
- Remove the `<!-- TODO: replace href="#" with checkout URL when payment is configured -->` comment

**Reference**: existing `src/components/Pricing.astro` (read the file before editing); `data-model.md` → Configuration Constants for the `CHECKOUT_URL` and `PRO_PRICE` values.

**Done when**: `npm run dev` shows the pricing page with a functional "Buy Pro" button that opens the overlay.

---

### Step 5 — Update `src/pages/index.astro`

**What**: Pass the real Pro tier price to the `Pricing` component's `proPrice` prop.

**Changes**:
- Find the `<Pricing />` usage in `index.astro`
- Add `proPrice="$XX"` prop with the finalized price from Step 1
- Value MUST NOT be the placeholder string `"[PRICE]"` — validation rule from `data-model.md` → Product Variant

**Done when**: The pricing page renders the correct numeric price (no `[PRICE]` placeholder visible).

---

### Step 6 — Local Build Verification

**What**: Confirm the static build emits both `success.html` and the updated pricing page correctly.

**Commands**:
```bash
npm run build
npm run preview   # verify at http://localhost:4321/dcv/success and /dcv/
```

**Check**:
- `dist/success.html` exists
- `dist/index.html` references the checkout URL (not `href="#"`)
- No Astro build errors or TypeScript type errors

**Risk mitigated**: `build.format: 'file'` emitting `success.html` correctly — see Risk Register.

---

### Step 7 — Update CloudFront Response Headers Policy *(manual, AWS console)*

**What**: Add CSP directives to the CloudFront distribution to permit the Lemon Squeezy script and overlay iframe.

**How**:
1. Open the AWS CloudFront console → the `apps.microcode.io` distribution (from `DEPLOYMENT_GUIDE.md`)
2. Check **Behaviors → `/dcv/*`** → **Response headers policy**: if a policy is already attached (from feature 004), edit it; otherwise create a new one
3. Under **Custom Headers → Content-Security-Policy**, add (or append to existing value):
   ```
   script-src 'self' https://app.lemonsqueezy.com;
   frame-src https://assets.lemonsqueezy.com https://checkout.lemonsqueezy.com;
   ```
4. Save and deploy the policy change

**CSP decisions**: see `research.md` Decision 5 for rationale and domain choices.

**Risk**: Exact LS iframe domain(s) may differ — verify via browser DevTools console during UAT; update policy if CSP violations appear. See Risk Register.

---

### Step 8 — Update `DEPLOYMENT_GUIDE.md`

**What**: Add a new step documenting the CSP Response Headers Policy change so future operators know it exists and why.

**Changes**:
- Add a new "Step 19 — Configure CloudFront Response Headers Policy (Lemon Squeezy CSP)" section to `DEPLOYMENT_GUIDE.md`
- Document the exact CSP directives, which behavior they apply to, and the LS domain verification step from Step 7 above
- Document the checkout URL location: `src/components/Pricing.astro` → `checkoutUrl` prop — so a future operator knows where to update it if the LS product is recreated

**Risk mitigated**: "Checkout URL hardcoded — stale if LS product is recreated" — see Risk Register.

---

### Step 9 — End-to-End Test *(manual)*

**What**: Full integration test using Lemon Squeezy test mode.

**Test procedure**: Follow `quickstart.md` → Testing Checklist (all 9 items).

**Key scenarios to verify**:
- Overlay opens on click (JS enabled)
- Link redirect on click (JS disabled via DevTools)
- Disabled button + message when lemon.js blocked (DevTools → Network → block `app.lemonsqueezy.com`)
- Test purchase completes → redirected to `/dcv/success`
- `/dcv/success` page content matches `contracts/success-page.md` → Required Content Elements
- No CSP console errors when overlay opens

**Done when**: All 9 items in `quickstart.md` testing checklist checked off.

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| LS iframe domains differ from assumed (`checkout.lemonsqueezy.com`) | Medium | Medium — checkout overlay blocked by CSP | Verify via browser DevTools during UAT; update CSP policy before production deploy |
| LS script CDN URL changes | Low | High — checkout broken site-wide | Monitor LS changelog; pin to versioned URL if LS provides one |
| `build.format: 'file'` emits `success.html` correctly | Low | High — success page 404 | Verify via `npm run build && npm run preview` locally |
| Checkout URL hardcoded — stale if LS product is recreated | Low | High — broken purchase flow | Document checkout URL location in DEPLOYMENT_GUIDE.md |
