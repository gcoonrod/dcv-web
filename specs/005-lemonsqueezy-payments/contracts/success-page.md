# Contract: Success Page (`/dcv/success`)

**Feature**: 005-lemonsqueezy-payments
**Type**: Page Contract
**Date**: 2026-03-11

---

## Overview

Defines the required content and behavior of the post-purchase confirmation page at `/dcv/success`. This page is fully static — no server-side logic, no query parameter reading, no JS required for its primary function.

---

## URL

`https://apps.microcode.io/dcv/success`

Rendered as: `dist/success.html` (Astro `build.format: 'file'` convention with `base: '/dcv'`)

---

## Required Content Elements

All elements below MUST be present and visible without JavaScript:

| Element | Content |
|---------|---------|
| Page title (`<title>`) | `"Purchase Successful — DCV"` |
| Heading | `"Thank you for your purchase!"` or equivalent |
| Confirmation message | Confirms license key has been sent via email |
| Activation command | Static code block showing: `dcv activate <your-license-key>` |
| Activation instruction | Instructs user to substitute `<your-license-key>` with the key from their email |
| Docs link | Link to `/dcv/docs/installation` with label "View installation docs" or equivalent |
| Return link | Link to `/dcv/` (home/pricing page) |

---

## Content Must NOT Include

- The customer's actual license key (not available to static page; key is delivered by LS email)
- Any server-fetched dynamic data
- Order ID, email address, or any other purchase-specific data read from URL parameters
- JS-dependent content that is hidden without JS

---

## Layout & Styling Rules

- MUST use Tailwind utility classes only (Constitution Rule I)
- MUST use semantic HTML: at minimum `<main>` wrapper, `<h1>` for primary heading
- MUST be readable on dark background (`dcv-bg = #0f172a`)
- Code block for activation command MUST use monospace font (JetBrains Mono Variable)
- MUST be responsive (readable on mobile and desktop)

---

## Accessibility

- `<title>` MUST accurately describe the page purpose
- Activation command code block MUST have `<code>` or `<pre><code>` wrapping
- All links MUST have descriptive text (no "click here")
- Color contrast MUST meet WCAG AA

---

## CloudFront Routing

The CloudFront `dcv-index-resolver` function already rewrites extensionless paths to `.html`. The `/dcv/success` path resolves as follows:

```
Request: /dcv/success
  → dcv-index-resolver rewrites to: /dcv/success.html
  → S3 serves: success.html from website bucket
```

No additional CloudFront configuration is required for this page.

---

## Acceptance Tests

**Test 1 — Content present**:
Given a user navigates directly to `/dcv/success`,
Then the page renders with a confirmation heading, the activation command code block, and the docs link — all visible without JS.

**Test 2 — No dynamic data**:
Given the page is loaded with any or no query parameters,
Then the page content is identical regardless of query parameters present.

**Test 3 — Links work**:
Given a user is on the success page,
When they click the docs link,
Then they are navigated to `/dcv/docs/installation`.

**Test 4 — Mobile responsive**:
Given the page is rendered on a 375px-wide viewport,
Then all content is readable without horizontal scrolling.
