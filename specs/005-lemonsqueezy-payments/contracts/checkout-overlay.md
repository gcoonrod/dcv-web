# Contract: Checkout Overlay Interaction

**Feature**: 005-lemonsqueezy-payments
**Type**: UI Interaction Contract
**Date**: 2026-03-11

---

## Overview

This contract defines the observable behavior of the "Buy Pro" checkout interaction on the dcv-web pricing page. It governs what the user sees and experiences from button render through purchase completion.

---

## Preconditions

- The pricing page (`/dcv/`) has loaded in the browser
- The `CheckoutButton` component has rendered the "Buy Pro" button
- A valid Lemon Squeezy checkout URL is embedded in the button's `href` attribute

---

## Button States

### State: Default (JS disabled or before script loads)

- Button renders as a styled `<a>` element with `href` pointing to the LS hosted checkout
- Visually identical to the "ready" state
- Clicking navigates to LS hosted checkout in same tab (standard link behavior)
- **WCAG**: `role="link"` implied; `href` present ensures keyboard focus and Enter key work

### State: Ready (LS script loaded)

- Button retains same visual appearance
- Clicking opens Lemon Squeezy checkout overlay (popup) within the page
- Visitor does not navigate away from dcv-web
- **WCAG**: Button remains focusable; overlay managed by LS (external accessibility)

### State: Unavailable (LS script load error)

- The `<a>` element is replaced by a `<button disabled aria-disabled="true">` element
- Button text changes to: `"Checkout temporarily unavailable"`
- Visual appearance: reduced opacity, `cursor-not-allowed`, `pointer-events-none` (Tailwind utility classes — no inline styles)
- Clicking has no effect (`disabled` attribute prevents interaction natively)
- **WCAG**: `disabled` + `aria-disabled="true"` on `<button>`; descriptive label text communicates the failure reason; element remains visible in the DOM for screen readers

---

## Interaction Sequence (JS-enabled, happy path)

```
1. Page loads
2. CheckoutButton renders <a href="CHECKOUT_URL" class="lemonsqueezy-button">Buy Pro</a>
3. Inline script loads lemon.js from https://app.lemonsqueezy.com/js/lemon.js (defer)
4. lemon.js initializes, binds overlay handler to .lemonsqueezy-button elements
5. User clicks "Buy Pro"
6. Lemon Squeezy checkout overlay opens (centered modal)
7. User fills payment details
8. User clicks "Complete purchase"
9. Payment succeeds → LS closes overlay → LS redirects browser to SUCCESS_URL
10. Browser navigates to /dcv/success
```

---

## Interaction Sequence (script load failure)

```
1. Page loads
2. CheckoutButton renders standard <a> link (same as default state)
3. Inline script attempts to load lemon.js
4. lemon.js fails to load (network error, blocked, etc.)
5. script.onerror fires
6. DOM update: button disabled, text → "Checkout temporarily unavailable"
7. User cannot trigger checkout
```

---

## Post-Purchase Redirect

After a successful payment, Lemon Squeezy redirects the browser to the configured SUCCESS_URL:

**URL**: `https://apps.microcode.io/dcv/success`

Lemon Squeezy may append query parameters (order ID, email, etc.) via link variables — the success page MUST NOT depend on any query parameters being present, as the page is fully static.

---

## Failure Modes

| Failure | Expected behavior |
|---------|------------------|
| LS script load error | Button disabled + "unavailable" message (FR-009) |
| LS service unavailable (checkout fails to open) | Managed by LS — user sees LS error UI |
| Payment declined | Managed by LS — overlay shows decline message, user can retry |
| Network loss mid-checkout | Managed by LS — user can retry or re-open checkout |

---

## Acceptance Test

**Test 1 — Overlay opens**:
Given the pricing page is loaded with JS enabled and lemon.js loads successfully,
When the user clicks "Buy Pro",
Then the Lemon Squeezy checkout overlay appears without navigating away from the page.

**Test 2 — Disabled state**:
Given lemon.js fails to load (simulate by blocking the script URL in DevTools),
When the page renders and the onerror fires,
Then the "Buy Pro" button is visually disabled and shows "Checkout temporarily unavailable".

**Test 3 — No-JS fallback**:
Given JavaScript is disabled in the browser,
When the user clicks "Buy Pro",
Then the browser navigates to the Lemon Squeezy hosted checkout page.

**Test 4 — Post-purchase redirect**:
Given a user completes a test purchase,
When payment is confirmed by Lemon Squeezy,
Then the browser is redirected to `/dcv/success`.
