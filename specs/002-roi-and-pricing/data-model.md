# Data Model: Differentiators, ROI, & Pricing (Phase 2)

**Branch**: `002-roi-and-pricing` | **Date**: 2026-03-06

All Phase 2 data is static and hardcoded within each component's frontmatter. There is no
database, API, or external data source. Entities below represent TypeScript types used
within Astro component files.

---

## Entity: Differentiator

**Used by**: `FeatureGrid.astro`
**Cardinality**: Array of 3+ items (Phase 2 minimum: exactly 3)

```typescript
interface Differentiator {
  title: string;        // Card heading (e.g., "No Telemetry")
  description: string;  // 1-2 sentence explanation of the guarantee
  icon: string;         // Raw SVG markup string; MUST include aria-hidden="true"
}
```

**Validation rules**:
- `title`: Non-empty; ≤ 40 characters (fits single-line card heading)
- `description`: Non-empty; ≤ 120 characters (fits 3-line card body at standard viewport)
- `icon`: MUST be a complete `<svg>` element string; MUST include `aria-hidden="true"` and
  `focusable="false"`; width/height MUST NOT be set inline (controlled by wrapper Tailwind classes)

**Phase 2 required instances**:

```typescript
const differentiators: Differentiator[] = [
  {
    title: "No Telemetry",
    description: "Your git history, commit messages, and code diffs never leave your machine. dcv runs entirely offline — no analytics, no crash reporting, no call-home.",
    icon: `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true" focusable="false"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285Z" /></svg>`
  },
  {
    title: "No Manager Dashboards",
    description: "There is no SaaS portal, no team-level visibility, and no org admin account. Your performance data belongs to you alone.",
    icon: `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true" focusable="false"><path stroke-linecap="round" stroke-linejoin="round" d="M3.98 8.223A10.477 10.477 0 0 0 1.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.451 10.451 0 0 1 12 4.5c4.756 0 8.773 3.162 10.065 7.498a10.522 10.522 0 0 1-4.293 5.774M6.228 6.228 3 3m3.228 3.228 3.65 3.65m7.894 7.894L21 21m-3.228-3.228-3.65-3.65m0 0a3 3 0 1 0-4.243-4.243m4.242 4.242L9.88 9.88" /></svg>`
  },
  {
    title: "BYO-LLM Key",
    description: "Provide your own API key for any supported LLM provider. We never proxy your requests through a shared endpoint or store your credentials.",
    icon: `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true" focusable="false"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 5.25a3 3 0 0 1 3 3m3 0a6 6 0 0 1-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1 .43-1.563A6 6 0 0 1 21.75 8.25Z" /></svg>`
  }
];
```

**Icon source**: Heroicons v2 outline (24×24 viewBox, `stroke-width="1.5"`, `stroke="currentColor"`, no fill).
Icons: `shield-check` (No Telemetry), `eye-slash` (No Manager Dashboards), `key` (BYO-LLM Key).
The implementing agent MUST copy these exact strings — do not substitute icon libraries or alter SVG attributes.

---

## Entity: PricingTier

**Used by**: `Pricing.astro`
**Cardinality**: Exactly 2 tiers (Free, Pro) — fixed for Phase 2

```typescript
interface PricingCta {
  label: string;   // Button or link text (e.g., "Install Free", "Buy Pro — v1.x.x")
  href: string;    // URL; Pro uses "#" placeholder in Phase 2 (TODO: replace with checkout URL)
}

interface PricingTier {
  name: string;         // Tier display name (e.g., "Free", "Pro")
  price: string;        // Display price string; Pro tier sourced from `proPrice` prop
  features: string[];   // Ordered list of included feature descriptions
  cta: PricingCta;
}
```

**Validation rules**:
- `name`: Non-empty; ≤ 10 characters
- `price`: For Free tier, `"Free"` (literal); for Pro tier, the `proPrice` prop value
  (default `"[PRICE]"`)
- `features`: Non-empty array; each item ≤ 80 characters
- `cta.href`: Free tier links to install docs; Pro tier uses `"#"` with a `<!-- TODO -->` comment

**Phase 2 instances**:

**Free tier**:
- features: `["Local Git repositories", "Public GitHub repositories", "Markdown report generation"]`
- cta: `{ label: "Install Free", href: "/docs/install" }` *(placeholder path)*

**Pro tier**:
- features: `["Jira, Linear, GH Enterprise, GitLab fetchers", "HTML & LaTeX export formats", "dcv query — Interactive RAG", "All minor updates & patches for v1.x.x"]`
- cta: `{ label: "Buy Pro", href: "#" }` *(TODO: replace with checkout URL)*
- Perpetual license statement: `"Perpetual License for v1.x.x — includes all minor updates and patches."`
  MUST appear as visible copy in the Pro card (not just in the features list)

---

## Entity: RoiExample

**Used by**: `RoiSection.astro`
**Cardinality**: Exactly 1 (hardcoded for Phase 2)

```typescript
interface RoiContentPair {
  label: string;  // STAR field name (e.g., "Action", "Result")
  text: string;   // Prose content for that field
}

interface RoiPanel {
  label: string;               // Panel heading (e.g., "Before", "After")
  content: string | RoiContentPair[];
  // Before panel: content is a plain string (raw commit line)
  // After panel:  content is RoiContentPair[] (labeled STAR pairs)
}

interface RoiExample {
  before: { label: string; content: string };
  after:  { label: string; content: RoiContentPair[] };
}
```

**Validation rules**:
- `before.content`: MUST be a realistic git commit message in conventional commits format;
  rendered in a `<code>` element using `font-mono`
- `after.content`: Array of `{ label, text }` pairs; Phase 2 requires exactly 2 entries:
  `Action` and `Result`; rendered as a `<dl>` / `<dt>` / `<dd>` definition list

**Phase 2 hardcoded instance**:

```typescript
const roiExample: RoiExample = {
  before: {
    label: "Raw Commit",
    content: "fix(cache): resolve race condition in redis worker"
  },
  after: {
    label: "STAR Accomplishment",
    content: [
      {
        label: "Action",
        text: "Architected a thread-safe Redis worker queue using atomic operations, eliminating a race condition affecting concurrent job processing."
      },
      {
        label: "Result",
        text: "Reduced P99 job queue latency by 40% and eliminated intermittent data loss incidents in production over a 6-month observation window."
      }
    ]
  }
};
```

---

## Entity Relationships

```text
index.astro
  └── <FeatureGrid />          — renders Differentiator[]  (self-contained data)
  └── <RoiSection />           — renders RoiExample        (self-contained data)
  └── <Pricing proPrice="?" /> — renders PricingTier[]     (proPrice from index.astro)
```

All data flows are one-directional (parent → component). No shared state, no context,
no stores. Components are purely presentational.
