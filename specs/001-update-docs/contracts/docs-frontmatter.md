# Contract: Docs Page Frontmatter

**Type**: Content Schema Contract
**Enforced by**: `src/content/config.ts` (Zod validation at build time)
**Consumer**: `src/layouts/DocsLayout.astro`, `src/pages/docs/[...slug].astro`, `src/components/DocsSidebar.astro`

## Schema

Every file in `src/content/docs/*.md` MUST begin with YAML frontmatter conforming to this schema:

```yaml
---
title: "Page Title"           # string, required
description: "One sentence."  # string, required
order: N                      # integer >= 1, required; controls nav sort position
---
```

## Invariants

1. `order` values MUST be unique across all docs pages (duplicate orders produce unpredictable nav ordering).
2. `order` values SHOULD be contiguous (1, 2, 3…) — gaps are allowed but not preferred.
3. `title` MUST match the primary `# Heading` in the page body.
4. `description` SHOULD be ≤ 160 characters for SEO.

## Post-Feature Page Registry

| File | title | description | order |
|------|-------|-------------|-------|
| `installation.md` | `"Installation"` | `"Install the dcv binary on macOS, Linux, or Windows."` | `1` |
| `quickstart.md` | `"Quickstart"` | `"Run your first dcv report in under 5 minutes."` | `2` |
| `configuration.md` | `"Configuration"` | `"Configure dcv with ~/.dcv/config.json."` | `3` |
| `categorization.md` | `"Context Categorization"` | `"Segregate work contexts and generate category-specific performance reviews."` | `4` |
| `changelog.md` | `"Changelog"` | `"Release history for dcv."` | `5` |

## Validation

Run `npm run build` — a Zod schema error will surface immediately if any field is missing or has the wrong type. The build will exit non-zero with the file path and field name of the violation.
