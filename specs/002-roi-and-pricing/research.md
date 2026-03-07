# Research: Differentiators, ROI, & Pricing (Phase 2)

**Branch**: `002-roi-and-pricing` | **Date**: 2026-03-06

No `NEEDS CLARIFICATION` items were identified in the Technical Context — the Phase 2 stack
is fully inherited from Phase 1. This document records four authoring patterns that are
new or non-obvious for Phase 2 components.

---

## Decision 1: Inline SVG Rendering in Astro

**Decision**: Use Astro's `set:html` directive to render raw SVG markup strings stored in
data arrays.

**Rationale**: The `FeatureGrid` component stores each differentiator card as a data object
`{ title, description, icon }` where `icon` is a raw `<svg>...</svg>` string. Astro's
`set:html` injects the string as trusted HTML — it is the idiomatic Astro approach for
author-controlled markup that should not be escaped.

**Usage**:
```astro
<span set:html={item.icon} />
```
Each SVG MUST include `aria-hidden="true"` (decorative, not interactive) and `focusable="false"`.
Width/height MUST be controlled via Tailwind classes on the wrapper `<span>`, not inline
SVG attributes, so Tailwind's responsive utilities apply correctly.

**Security note**: `set:html` does NOT sanitize content. This is safe here because SVG
strings are hardcoded in-repo by the developer — they are not sourced from user input,
API responses, or any external system. If SVG source ever becomes dynamic or external,
an HTML sanitizer MUST be introduced before using `set:html`.

**Alternatives considered**:
- `<img src="...svg">` — rejected: external file requests violate Rule IV (Asset Optimization);
  also loses inline styling flexibility.
- SVG sprite + `<use>` — rejected: requires a separate sprite file and build tooling;
  overkill for 3–4 icons.
- Astro Icon library — rejected: adds a dependency not in the Phase 1 stack; constitution
  favors minimal external dependencies.

---

## Decision 2: Tailwind v4 Responsive Grid Patterns

**Decision**: Use `grid grid-cols-1 md:grid-cols-3` for FeatureGrid; `grid grid-cols-1 md:grid-cols-2`
for Pricing cards.

**Rationale**: Tailwind v4 retains identical responsive grid class names from v3. The
`md:` breakpoint (`768px`) is the natural collapse point for both layouts:
- FeatureGrid: 3-column desktop → 1-column mobile (spec requirement)
- Pricing: 2-column desktop → 1-column stacked mobile (spec requirement)

**Card safety classes** (per spec edge case): All grid children MUST include `min-w-0`
to prevent grid blowout on extreme narrow viewports (< 375px). Cards with long
unbreakable strings (e.g., `v1.x.x`) MUST also include `overflow-hidden`.

**Alternatives considered**:
- CSS custom grid — rejected: violates Rule I (Tailwind CSS Exclusivity).
- `flex flex-wrap` — rejected: less predictable column alignment than `grid`; gaps require
  more verbose class combinations in Tailwind v4.

---

## Decision 3: STAR Content Semantic Structure

**Decision**: Use `<dl>` / `<dt>` / `<dd>` for the ROI After-panel labeled pairs.

**Rationale**: The `RoiExample.after.content[]` array contains `{ label: string, text: string }`
pairs (e.g., `Action` / `Result`). A definition list (`<dl>`) is the semantically correct
HTML element for key-value / label-value pairs. Screen readers announce `<dt>` as a term
and `<dd>` as its definition — aligning naturally with the STAR format's structure.

**Rendered structure**:
```html
<dl class="space-y-3">
  <div>
    <dt class="text-sm font-semibold text-dcv-accent uppercase tracking-wide">Action</dt>
    <dd class="text-slate-200 font-sans">Architected a thread-safe Redis worker queue…</dd>
  </div>
  <div>
    <dt class="text-sm font-semibold text-dcv-accent uppercase tracking-wide">Result</dt>
    <dd class="text-slate-200 font-sans">Reduced P99 latency by 40%…</dd>
  </div>
</dl>
```

**Alternatives considered**:
- `<strong>` labels inline with `<p>` — rejected: visually similar but semantically weaker;
  screen readers do not distinguish label from value.
- `<table>` — rejected: overcomplicated for 2 rows; introduces layout rigidity.
- Bold markers embedded in a single string (`"**Action:** ..."`) — rejected: prevents
  independent styling of label vs. value; not compatible with the typed `{ label, text }`
  entity structure.

---

## Decision 4: Pricing Component `proPrice` Prop Default

**Decision**: `Pricing.astro` accepts `proPrice?: string` with a default of `"[PRICE]"`.

**Rationale**: The price is a business decision deferred to a future phase. Defaulting to
`"[PRICE]"` means the component renders a visible placeholder that signals "fill me in"
without breaking the page. The `index.astro` caller passes the real value when known:

```astro
<Pricing proPrice="$149" />
```

Until then, omitting the prop renders `[PRICE]` in the Pro card.

**The `TODO` comment** (per spec edge case): A `<!-- TODO: replace proPrice in index.astro when payment URL is configured -->` comment MUST appear in `index.astro` adjacent to the `<Pricing />` usage.

**Alternatives considered**:
- Editable constant at top of `Pricing.astro` — rejected: requires modifying the component
  file itself when the price changes; prop is cleaner and more idiomatic Astro.
- Environment variable — rejected: overkill for a static site; requires build-time env setup.
