# Quickstart: Lemon Squeezy Payment Integration

**Feature**: 005-lemonsqueezy-payments
**Date**: 2026-03-11

---

## Prerequisites

Before implementation begins, the following manual setup steps in the Lemon Squeezy dashboard MUST be completed:

### Step 1 — Create the DCV Pro Product

1. Log into [app.lemonsqueezy.com](https://app.lemonsqueezy.com)
2. Navigate to **Store → Products → New Product**
3. Configure:
   - **Name**: `DCV Pro`
   - **Type**: One-time purchase (perpetual license)
   - **Price**: Set the final price (e.g., `$49.00`)
   - **License keys**: Enable license key generation (one key per order)
   - **Description**: Copy from the existing Pricing component feature list

### Step 2 — Configure the Success Redirect URL

1. Within the DCV Pro product, go to **Product Options → Confirmation Page**
2. Set **Redirect URL** to: `https://apps.microcode.io/dcv/success`
3. Save

### Step 3 — Get the Checkout URL

1. Navigate to the product's variant page
2. Copy the **Share URL** — this is your checkout URL
   - Format: `https://{store}.lemonsqueezy.com/buy/{variant-id}`
3. Note this URL — it will be embedded in `CheckoutButton.astro`

---

## Implementation Steps (developer)

### Step 4 — Create `CheckoutButton.astro`

Create `src/components/CheckoutButton.astro` with:
- The `<a>` element using `class="lemonsqueezy-button"` and `href="{CHECKOUT_URL}"`
- A `<script>` that loads `lemon.js` with `onerror` fallback (disables button on failure)
- Tailwind classes matching the existing "Buy Pro" button style in `Pricing.astro`

### Step 5 — Update `Pricing.astro`

- Replace the placeholder `href="#"` on the Pro CTA with `<CheckoutButton />`
- Pass the real price to the `proPrice` prop from `index.astro`
- Remove the `<!-- TODO: replace href="#" with checkout URL -->` comment

### Step 6 — Create `src/pages/success.astro`

New page at `src/pages/success.astro` rendering the `/dcv/success` confirmation content per the contract in `contracts/success-page.md`.

### Step 7 — Update CloudFront Response Headers Policy

In the AWS CloudFront console, add or update the Response Headers Policy for the distribution to include:

```
Content-Security-Policy:
  script-src 'self' https://app.lemonsqueezy.com;
  frame-src https://assets.lemonsqueezy.com https://checkout.lemonsqueezy.com;
```

> **Note**: Verify exact LS iframe domain(s) during UAT by checking browser console for CSP violation messages when the overlay opens. Update the policy if additional domains are required.

---

## Testing Checklist

- [ ] "Buy Pro" button opens the LS checkout overlay (JS enabled)
- [ ] "Buy Pro" button links to LS hosted checkout (JS disabled)
- [ ] LS script failure shows disabled button + "unavailable" message
- [ ] Test purchase completes and redirects to `/dcv/success`
- [ ] `/dcv/success` page displays correctly on desktop and mobile
- [ ] Docs link on success page navigates to `/dcv/docs/installation`
- [ ] Pricing page shows the correct price (no `[PRICE]` placeholder)
- [ ] Discount codes accepted in checkout
- [ ] CloudFront CSP headers permit LS script and overlay without console errors

---

## Environment Variables / Secrets

No new secrets required. The checkout URL is a public URL embedded directly in the component source. The LS store API key is NOT used by the static site.
