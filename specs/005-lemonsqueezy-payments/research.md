# Research: Lemon Squeezy Payment Integration

**Feature**: 005-lemonsqueezy-payments
**Date**: 2026-03-11
**Status**: Complete — all NEEDS CLARIFICATION resolved

---

## Decision 1: Checkout Overlay Implementation

**Decision**: Use the `lemonsqueezy-button` CSS class on an `<a>` element pointing to the LS hosted checkout URL. Load `https://app.lemonsqueezy.com/js/lemon.js` with `defer` in the component.

**Rationale**: The `class="lemonsqueezy-button"` pattern is the simplest LS overlay mechanism — no programmatic JS calls required. The `<a href="...">` base element satisfies Constitution I (readable and functional without JS as a standard redirect), and the external script promotes it to an overlay when available.

**Alternatives considered**:
- `LemonSqueezy.Url.Open(url)` programmatic call: requires more JS scaffolding and loses the native link fallback
- Lemon Squeezy Buy Button embed widget: generates an iframe, harder to style with Tailwind, not keyboard-accessible

---

## Decision 2: Graceful Degradation Strategy

**Decision**: Start button as a standard `<a>` link (fallback to LS hosted checkout on click). On `script.onerror`, disable the button and display a "Checkout temporarily unavailable" message. Do not disable the button pre-emptively on page load.

**Rationale**: This satisfies both Constitution I (the link works with JS disabled, routing to the LS hosted checkout) and FR-009 (if the LS script explicitly fails to load in an otherwise-JS-enabled browser, the button is disabled with a message). A user with JS entirely disabled gets a redirect, not a broken experience.

**Implementation pattern**:
1. Render `<a href="CHECKOUT_URL" class="lemonsqueezy-button">` (fully functional as plain link)
2. Load LS script via `script.onerror` / `script.onload` pattern to detect failure
3. On `onerror`: replace button with disabled state + message via DOM update
4. On `onload`: LS auto-initializes the overlay via the `lemonsqueezy-button` class — no further action needed

**Alternatives considered**:
- Start button disabled, enable on script load: breaks Constitution I (purchase path unavailable without JS); rejected
- Silent failure (button does nothing on click if script fails): violates FR-009; rejected

---

## Decision 3: Success Page Redirect URL

**Decision**: Configure the success redirect URL (`https://apps.microcode.io/dcv/success`) in the Lemon Squeezy product dashboard under **Product Options → Redirect URL**. No API calls or dynamic parameters needed.

**Rationale**: The static site cannot generate server-side checkout sessions, so per-checkout API redirect URL configuration is not feasible. Dashboard configuration is a one-time setup step. The `/dcv/success` page is fully static HTML — no query parameters need to be read client-side (FR-008 resolution: activation instructions are static, not personalized).

**Alternatives considered**:
- Pass `redirect_url` as query param to LS checkout URL: LS does not support per-request redirect URL override via query params (only via Checkouts API); rejected
- Use `Checkout.Success` event handler in JS to navigate client-side: requires the LS script to have already loaded; less reliable; rejected

---

## Decision 4: Pro Price Display

**Decision**: Hardcode the Pro tier price in the Astro component at build time via the existing `proPrice` prop on `Pricing.astro`. Managed by updating the prop value in `src/pages/index.astro` before each deploy.

**Rationale**: Lemon Squeezy provides no client-side pricing widget. The LS Prices API requires a server-side call (API key required; not safe in static frontend). Prices for a perpetual license are expected to be stable. The existing `proPrice` prop architecture already accommodates this pattern.

**Alternatives considered**:
- Build-time API fetch via Astro's `fetch` in frontmatter: possible, but requires LS API key available at build time in CI (new secret); adds latency to builds; over-engineered for a stable one-time price; deferred to future if dynamic pricing is needed
- Client-side price fetch: exposes API key in frontend bundle; security violation; rejected

---

## Decision 5: CSP Header Strategy

**Decision**: Add a CloudFront Response Headers Policy (not Lambda@Edge) to inject the following CSP directives for the distribution:

```
script-src 'self' https://app.lemonsqueezy.com;
frame-src https://assets.lemonsqueezy.com https://checkout.lemonsqueezy.com;
```

**Rationale**: CloudFront Response Headers Policies natively support custom security headers without any compute function, reducing cost and operational complexity. The exact LS domains for the checkout iframe (`checkout.lemonsqueezy.com` and `assets.lemonsqueezy.com`) need verification via browser console during testing — CSP implementation is flagged as a **manual verification step** in the deployment guide.

**Alternatives considered**:
- Lambda@Edge for CSP headers: higher cost, requires Node.js function in `us-east-1`; rejected in favor of native Response Headers Policy
- No CSP update: browser may block the LS script or iframe; security posture regression; rejected

---

## Open Questions (deferred)

- Exact LS iframe domain(s): `checkout.lemonsqueezy.com` assumed but must be verified via browser DevTools during UAT
- Whether `window.createLemonSqueezy()` call is needed for Astro's component lifecycle: test during implementation; the `defer` attribute on the script tag should ensure DOM-ready initialization

---

## Key Reference Links

- [Checkout Overlay docs](https://docs.lemonsqueezy.com/help/checkout/checkout-overlay)
- [Lemon.js methods](https://docs.lemonsqueezy.com/help/lemonjs/methods)
- [Handling events](https://docs.lemonsqueezy.com/help/lemonjs/handling-events)
- [Link Variables / redirect URL](https://docs.lemonsqueezy.com/help/products/link-variables)
- [Astro e-commerce guide](https://docs.astro.build/en/guides/ecommerce/)
