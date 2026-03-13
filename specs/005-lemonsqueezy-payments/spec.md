# Feature Specification: Lemon Squeezy Payment Integration

**Feature Branch**: `005-lemonsqueezy-payments`
**Created**: 2026-03-11
**Status**: Draft
**Input**: User description: "I want to integrate Lemon Squeezy as the payment platform for the dcv-web project"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Purchase Pro License (Priority: P1)

A developer visits the dcv-web pricing page, decides to purchase the DCV Pro perpetual license, clicks "Buy Pro", completes payment through the Lemon Squeezy checkout, and receives their license key via email so they can activate DCV Pro on their machine.

**Why this priority**: This is the core revenue-generating flow. Without a working purchase path, the Pro tier cannot generate any revenue. Everything else supports or enhances this primary journey.

**Independent Test**: Can be fully tested by clicking "Buy Pro" on the pricing page, completing a test purchase on Lemon Squeezy, and verifying that a receipt and license key email arrives — this alone delivers full purchase capability.

**Acceptance Scenarios**:

1. **Given** a visitor is on the pricing page, **When** they click "Buy Pro", **Then** they are directed to a Lemon Squeezy checkout for the DCV Pro perpetual license product
2. **Given** a visitor is on the Lemon Squeezy checkout, **When** they enter valid payment details and complete purchase, **Then** Lemon Squeezy sends a receipt and license key to their email address within 5 minutes
3. **Given** a visitor is on the Lemon Squeezy checkout, **When** they enter a valid discount code, **Then** the discount is applied and the adjusted total is shown before final confirmation
4. **Given** a visitor's payment is declined, **When** the checkout fails, **Then** Lemon Squeezy displays a clear error message and the customer is not charged

---

### User Story 2 - View Accurate Pro Pricing (Priority: P2)

A developer visiting the pricing page sees the real Pro tier price (e.g., "$49") instead of the current "[PRICE]" placeholder, allowing them to make an informed purchase decision without leaving the page.

**Why this priority**: A missing price creates friction and erodes trust. A visitor who cannot see the price is unlikely to click "Buy Pro". This directly supports conversion rate for Story 1.

**Independent Test**: Can be tested by loading the pricing page and verifying the Pro tier displays a real price — delivers credibility and transparency without requiring the checkout flow.

**Acceptance Scenarios**:

1. **Given** a visitor loads the pricing page, **When** the page renders, **Then** the Pro tier displays the correct numeric price (not a placeholder)
2. **Given** the Pro price is updated in the payment platform, **When** the site is redeployed, **Then** the updated price is reflected on the pricing page

---

### User Story 3 - Access Customer Portal (Priority: P3)

A returning customer who previously purchased DCV Pro wants to retrieve their license key, download an invoice, or manage their subscription details. They can access the Lemon Squeezy customer portal via a link provided in their original purchase email.

**Why this priority**: Supports post-purchase trust and reduces support burden. Lower priority because Lemon Squeezy's default email flow already provides a portal link without any custom work on dcv-web.

**Independent Test**: Can be tested by completing a purchase and following the customer portal link in the confirmation email — delivers self-service license management without any dcv-web changes.

**Acceptance Scenarios**:

1. **Given** a customer received their purchase confirmation email, **When** they click the customer portal link in that email, **Then** they can view their license key and download an invoice
2. **Given** a customer has lost their license key, **When** they access the customer portal, **Then** they can retrieve their license key without contacting support

---

### Edge Cases

- What happens when a customer's payment is declined mid-checkout? → Handled by Lemon Squeezy; overlay shows a decline message and the customer can retry; no dcv-web action required
- What happens if the Lemon Squeezy checkout service is temporarily unavailable when a visitor clicks "Buy Pro"? → Button is visually disabled with an "unavailable" message (FR-009)
- What happens if a customer attempts to purchase from a country with specific tax/VAT requirements? → Handled by Lemon Squeezy's built-in tax engine; no dcv-web action required (FR-006)
- What happens if a customer requests a refund — is there a stated refund policy? → Handled by Lemon Squeezy; refund policy is configured in the LS dashboard and communicated via checkout; no dcv-web action required
- What happens if a customer enters the checkout on mobile and their session times out? → Handled by Lemon Squeezy; no dcv-web action required
- What happens if a customer wants to purchase multiple licenses for a team? → Out of scope; single-seat purchases only in this integration

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The "Buy Pro" button on the pricing page MUST link to a working Lemon Squeezy checkout for the DCV Pro perpetual license product (see FR-007 for checkout modality)
- **FR-002**: The pricing page MUST display the actual current Pro tier price, not a placeholder
- **FR-003**: The checkout MUST support credit and debit card payment methods
- **FR-004**: Lemon Squeezy MUST automatically send a purchase receipt and license key to the customer's email upon successful payment
- **FR-005**: The checkout MUST allow customers to apply discount/promo codes before finalizing payment
- **FR-006**: The checkout MUST handle applicable sales tax and VAT automatically based on customer location
- **FR-007**: The "Buy Pro" button MUST open the Lemon Squeezy checkout as an overlay/popup on the dcv-web page (visitor does not leave the site during checkout); the JS embed script MUST be loaded as a scoped component `<script>` tag with `defer` so it does not block page rendering
- **FR-008**: After successful payment, the customer MUST be redirected to a custom confirmation page at `/dcv/success` on dcv-web; this page MUST be fully static and display: (1) a confirmation that the license key has been sent via email, (2) the CLI activation command (`dcv activate <key>`) as a static code example instructing the customer to substitute their emailed key, and (3) a link to the installation docs
- **FR-009**: If the Lemon Squeezy embed script fails to load, the "Buy Pro" button MUST be visually disabled and display a short "unavailable" message informing the visitor that checkout is temporarily unavailable; the button MUST NOT silently do nothing or produce a JS error
- **FR-010**: The site MUST remain fully static — no server-side code may be introduced as part of this integration

### Key Entities

- **Product**: The "DCV Pro" perpetual license product configured in the Lemon Squeezy dashboard; has a price, product ID, and checkout URL
- **Order**: A completed purchase record in Lemon Squeezy; associated with a customer email, payment amount, and timestamp
- **License Key**: A unique alphanumeric key generated by Lemon Squeezy upon order completion; delivered via email; used to activate Pro features in the DCV CLI
- **Checkout URL**: The Lemon Squeezy-hosted URL (or overlay trigger) that initiates the purchase flow for a specific product variant

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Visitors can complete a Pro license purchase in under 3 minutes from clicking "Buy Pro" to receiving a confirmation email
- **SC-002**: 100% of successful payments result in receipt and license key delivery via email within 5 minutes of purchase
- **SC-003**: The pricing page accurately displays the Pro tier price at all times (zero instances of "[PRICE]" placeholder visible to end users after deployment)
- **SC-004**: The purchase flow has a 0% error rate attributable to the dcv-web integration (payment processor errors are outside scope)
- **SC-005**: The "Buy Pro" call-to-action is reachable and functional on both desktop and mobile viewports

## Clarifications

### Session 2026-03-11

- Q: What should the `/dcv/success` page show for license activation instructions? → A: Static page — show the CLI activation command (`dcv activate <key>`) and instruct the customer to substitute their emailed license key; no client-side JS required to display the key
- Q: What should the "Buy Pro" button do if the Lemon Squeezy embed script fails to load? → A: Disable the button and display a short "checkout temporarily unavailable" message; must not silently fail or produce a JS error
- Q: Is multi-license/team purchasing in scope for this integration? → A: Out of scope — single-seat purchases only; team licensing is a future feature

## Assumptions

- The DCV Pro product and its pricing will be configured in the Lemon Squeezy dashboard before or during implementation — the exact price is not yet finalized in this spec
- Lemon Squeezy handles all PCI-DSS compliance, payment processing, and fraud prevention — dcv-web bears no responsibility for payment security
- License key validation for the DCV CLI is handled by the CLI application itself (potentially via Lemon Squeezy's license API) — this is out of scope for dcv-web
- The site will remain `output: 'static'`; no Astro SSR adapter will be introduced
- International tax compliance (VAT, GST, etc.) is handled entirely by Lemon Squeezy's built-in tax engine
- A refund policy will be established and communicated to customers via Lemon Squeezy's checkout configuration, not via custom dcv-web pages
- The perpetual license covers all v1.x.x minor updates and patches, consistent with the existing Pricing component copy
- Multi-seat and team licensing are explicitly out of scope for this integration; the checkout supports single-seat purchases only
- SC-001 (purchase in under 3 minutes) and SC-002 (receipt within 5 minutes) are Lemon Squeezy infrastructure SLAs; dcv-web tasks cannot measure or guarantee them — acceptance is implicit in a successful test purchase completing without error

## Dependencies

- A Lemon Squeezy account and configured "DCV Pro" product must exist before implementation
- The Pro tier price must be finalized before deploying the updated pricing page
- Lemon Squeezy's JS embed script must be evaluated for compatibility with the project's Vanilla JS and Astro Island architecture constraints before implementation (FR-007)
