# Implementation Plan: Sync Website Documentation to App v3.0.1

**Branch**: `001-update-docs` | **Date**: 2026-03-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-update-docs/spec.md`

## Summary

Update five documentation pages in `src/content/docs/` to accurately reflect dcv v3.0.1. This is a pure content update — no new components, no routing changes, no Astro config changes. The site's fully data-driven docs architecture (dynamic routing via `[...slug].astro`, auto-sorted nav in `DocsLayout.astro`) means a new Markdown file with valid frontmatter is sufficient to add the new Categorization page.

**Pages affected**:
1. `quickstart.md` — full rewrite (V1 3-step → V2 full workflow)
2. `configuration.md` — full rewrite (V1/OpenAI schema → V2/Anthropic/Voyage)
3. `installation.md` — targeted update (verify binary names + install URL for v3.0.1)
4. `changelog.md` — append v3.0.1 entry
5. `categorization.md` — create new (order: 4; changelog shifts to order: 5)

## Technical Context

**Language/Version**: TypeScript (strict) — Node.js 20 LTS + Astro 5.18.x
**Primary Dependencies**: `@tailwindcss/vite` (Tailwind v4), `@tailwindcss/typography` (prose rendering for docs)
**Storage**: File-based — Markdown in `src/content/docs/`, Zod-validated at build time (`src/content/config.ts`)
**Testing**: Manual verification — run `npm run build` to confirm Zod schema acceptance and static rendering; visually verify all pages and navigation order in `npm run preview`
**Target Platform**: Static site (SSG), AWS S3 + CloudFront
**Project Type**: Static web application (marketing + documentation site)
**Performance Goals**: N/A — static content, no runtime performance considerations
**Constraints**: `output: 'static'` must remain; all prose styled via `prose prose-invert` Tailwind typography classes; no new components or JS
**Scale/Scope**: 5 Markdown files; ~4–6 hours of content authoring

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Rule | Status | Notes |
|------|--------|-------|
| I. Zero-JavaScript Default | ✅ Pass | Pure Markdown content updates; no JS added |
| II. Developer-Centric Aesthetic | ✅ Pass | Content only; no design or styling changes |
| III. Infrastructure Simplicity | ✅ Pass | No build or deployment changes |
| Rule I. Tailwind CSS Exclusivity | ✅ Pass | No new `<style>` blocks; prose rendered by existing `prose prose-invert` class |
| Rule II. Strict Island Architecture | ✅ Pass | N/A — no new interactive components |
| Rule III. Vanilla JS Preference | ✅ Pass | N/A |
| Rule IV. Asset Optimization | ✅ Pass | No new images or assets |
| Rule V. Accessibility & Semantics | ✅ Pass | Markdown renders via existing semantic DocsLayout; no HTML structure changes |

**Result**: All gates pass. No complexity violations. No Complexity Tracking table required.

**Post-Phase-1 re-check**: No design artifacts change any of the above. Gate status unchanged.

## Source Material Index

All content for this feature is derived from these authoritative sources. Every phase below references these explicitly.

| Source | Path | Used by |
|--------|------|---------|
| dcv man page (v3.0.1) | `/Users/greg.coonrod/dev/personal/claude/dev-review-prep/docs/dcv.1` | Phases 1, 2, 3, 5 |
| Configuration guide (v3.0.1) | `/Users/greg.coonrod/dev/personal/claude/dev-review-prep/docs/configuration.md` | Phase 3 |
| Context categorization guide | `/Users/greg.coonrod/dev/personal/claude/dev-review-prep/docs/quickstart.md` | Phase 4 |
| Command signatures table | `specs/001-update-docs/research.md` — Decision 3 | Phases 2, 3, 4 |
| Source type taxonomy | `specs/001-update-docs/data-model.md` — Source Type Taxonomy table | Phase 3 |
| Category system rules | `specs/001-update-docs/data-model.md` — Category System Rules table | Phases 3, 4 |
| Anthropic provider config | `specs/001-update-docs/research.md` — Decision 4 | Phase 3 |
| Source type labeling | `specs/001-update-docs/research.md` — Decision 2 | Phase 3 |
| Quickstart workflow scope | `specs/001-update-docs/research.md` — Decision 6 | Phase 2 |
| Nav order (post-feature) | `specs/001-update-docs/contracts/docs-frontmatter.md` — Post-Feature Page Registry | All phases |

## Project Structure

### Documentation (this feature)

```text
specs/001-update-docs/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (frontmatter contract)
├── quickstart.md        # Phase 1 output (contributor guide)
├── contracts/
│   └── docs-frontmatter.md   # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
src/content/docs/
├── installation.md      # MODIFY: verify binary names + install URL for v3.0.1
├── quickstart.md        # MODIFY: full rewrite for v3.0.1 workflow
├── configuration.md     # MODIFY: full rewrite for V2 schema + Anthropic provider
├── categorization.md    # CREATE: new page (order: 4)
└── changelog.md         # MODIFY: update order: 4→5; append v3.0.1 entry

# No code changes needed:
src/content/config.ts         # Zod schema already accepts any valid frontmatter
src/layouts/DocsLayout.astro  # Already auto-sorts by order; no change needed
src/pages/docs/[...slug].astro  # Dynamic routing; no change needed
src/components/DocsSidebar.astro  # Nav auto-generates from collection; no change needed
```

**Structure Decision**: Single-project web app. All changes are in `src/content/docs/`. The data-driven Astro architecture requires no routing or component code changes to accommodate the new page or reordered nav.

## Implementation Phases

### Phase 1: installation.md (targeted update)

**Source**: `dev-review-prep/docs/dcv.1` SYNOPSIS section for the `--version` flag; GitHub releases page at `https://github.com/gcoonrod/dcv/releases` for binary asset names.

**What is currently in the file** (read before editing):
- Install script URL: `https://apps.microcode.io/dcv/install.sh`
- Binary table: `dcv-macos-arm64`, `dcv-macos-x86_64`, `dcv-linux-x86_64`, `dcv-windows-x86_64.exe`
- Verification command: `dcv --version`

**Verification checklist** (check each against the v3.0.1 GitHub release):
- [ ] Install script URL still resolves to a valid script
- [ ] `dcv-macos-arm64` binary exists in release assets
- [ ] `dcv-macos-x86_64` binary exists in release assets
- [ ] `dcv-linux-x86_64` binary exists in release assets
- [ ] `dcv-windows-x86_64.exe` binary exists in release assets

Update only what has changed. If all names match, no content change is required (frontmatter `order: 1` is already correct).

**Done when**: `npm run build` succeeds; every binary name in the table matches a real asset in the v3.0.1 release.

**Spec success criteria satisfied**: SC-006 (installation page renders without errors), SC-001 (install commands work as documented).

**Files changed**: `src/content/docs/installation.md`

### Phase 2: quickstart.md (full rewrite)

**Sources**:
- Workflow scope decision: `research.md` → Decision 6 (explains why compare/query are deferred to Next Steps)
- Exact command signatures: `research.md` → Decision 3 (command signatures table)
- Canonical workflow order: `dev-review-prep/docs/dcv.1` → DESCRIPTION section ("typical workflow")

**New content structure**:
1. Prerequisites (dcv installed; run `dcv init` to configure at least one source)
2. Step 1: `dcv init` — interactive wizard; note it requires a TTY
3. Step 2: `dcv fetch --since YYYY-MM-DD --until YYYY-MM-DD` — pull data; explicitly note `--since` and `--until` are required
4. Step 3: `dcv curate` — open interactive curation to add personal notes to key artifacts
5. Step 4: `dcv view [--since DATE --until DATE]` — preview fetched artifacts and notes
6. Step 5: `dcv analyze --since YYYY-MM-DD --until YYYY-MM-DD [-o path]` — generate the report
7. Next Steps section: mention `dcv compare` (trajectory analysis) and `dcv query` (RAG Q&A, requires Voyage AI) with links to Configuration and Categorization guides

**Cross-page consistency**: The `init` step should tell users "see the [Configuration guide](/dcv/docs/configuration) to understand the config file that's created."

**Done when**: A reader can copy-paste each command in order and produce a report without consulting any other page. Verify commands against `research.md` Decision 3 before writing.

**Spec success criteria satisfied**: SC-004 (user generates report from Quickstart alone), SC-001 (commands work as documented).

**Files changed**: `src/content/docs/quickstart.md`

### Phase 3: configuration.md (full rewrite)

**Sources**:
- Primary content source: `dev-review-prep/docs/configuration.md` (the actual app config guide — mirror its structure closely)
- Source type labels (Pro/Coming Soon): `research.md` → Decision 2 (labeling taxonomy table)
- Source type taxonomy and ID conventions: `data-model.md` → Source Type Taxonomy table
- Anthropic provider JSON: `research.md` → Decision 4 (exact fields and model IDs: `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5`)
- Category system rules: `data-model.md` → Category System Rules table (authoritative for both this page and Phase 4 — do not duplicate rules, link to this page from categorization.md instead)
- Environment variables: `dev-review-prep/docs/configuration.md` → Environment Variables section

**New content structure**:
1. Quick Start — `dcv init` wizard
2. Configuration File Structure — V2 schema (`schema_version: 2`, `sources[]`, `providers[]`); show minimal working example
3. Category System — optional `category` field, default `"professional"`, naming rules (draw from `data-model.md` Category System Rules table), usage matrix across commands
4. Data Sources — each source type subsection with required + optional fields, labeled per `research.md` Decision 2:
   - GitHub (no label)
   - GitHub Enterprise (no label)
   - Local Git (no label)
   - Trello (no label)
   - Bitbucket `(Pro)`
   - Jira `(Pro)`
   - Linear `(Pro)`
   - Asana `(Pro)`
   - GitLab `(Pro)` `(Coming Soon)`
   - Azure DevOps `(Pro)` `(Coming Soon)`
5. LLM Providers — Anthropic section only; note OpenAI is `(Coming Soon)`
6. Embedding Providers — Voyage AI; note it is required for `dcv query` and `dcv index`
7. Environment Variables — all `DCV_*` overrides (source from `dev-review-prep/docs/configuration.md`)
8. Secret Management — file permissions (`600`), best practices
9. Migration V1 → V2 — `dcv init` migration wizard, backup to `config.json.v1.bak`, before/after JSON example
10. Troubleshooting — invalid category error, reserved keyword error, file permissions fix

**Cross-page consistency**: The category naming rules documented here are the authoritative reference. The Categorization guide (Phase 4) should link back to this section rather than duplicating the rules.

**Done when**: Every JSON snippet in the page is valid and matches the V2 schema. Zero mentions of OpenAI as an active provider. All source types carry correct labels per `research.md` Decision 2.

**Spec success criteria satisfied**: SC-002 (zero OpenAI references), SC-003 (zero V1 schema references), SC-001 (config examples are valid for v3.0.1).

**Files changed**: `src/content/docs/configuration.md`

### Phase 4: categorization.md (create new)

**Sources**:
- Primary content source: `dev-review-prep/docs/quickstart.md` (the app's feature 027 categorization guide — mirror its structure and examples closely)
- Command signatures: `research.md` → Decision 3 (journal, fetch, analyze, query signatures)
- Category naming rules: `data-model.md` → Category System Rules table (do NOT restate rules here; link to the Configuration guide's Category System section instead)
- Frontmatter values: `contracts/docs-frontmatter.md` → Post-Feature Page Registry row for `categorization.md`

**Frontmatter for this new file**:
```yaml
---
title: "Context Categorization"
description: "Segregate work contexts and generate category-specific performance reviews."
order: 4
---
```

**Content structure**:
1. Overview — what context categorization does (professional vs personal vs open-source work on one machine)
2. Prerequisites — dcv installed and configured, at least one source set up
3. Step 1: Configure Source Categories — adding `"category"` field to sources in `~/.dcv/config.json`; link to [Configuration guide](/dcv/docs/configuration#category-system) for naming rules
4. Step 2: Fetch Data with Categories — `dcv fetch --since ... --until ...`; show how artifacts inherit category from source; show the mismatch detection prompt and recommended action
5. Step 3: Journal with Categories — `dcv journal -e "..."` (defaults to professional), `dcv journal --personal -e "..."`, `dcv journal --category open-source -e "..."`; show resulting directory structure
6. Step 4: Generate a Category-Filtered Report — `dcv analyze --category professional --since ... --until ...`; note that omitting `--category` includes all categories
7. Step 5: Query by Category — `dcv query --category professional "..."` and `dcv query --category personal "..."`
8. Common Workflows — quarterly work review, personal showcase, combined categories (`--category personal,open-source`)
9. Troubleshooting — existing artifacts all showing "professional", recategorizing journal entries (manual file move + `dcv journal sync`), listing categories via SQLite
10. Advanced — multiple comma-separated categories, shell aliases

**Cross-page consistency**: Category naming rules live in the Configuration guide. Link there; do not restate the rules table here. The `--personal` shorthand equals `--category personal` — show both forms in Step 3.

**Done when**: A user with no prior knowledge of categories can follow steps 1–4 and produce a `professional`-only report. `npm run build` succeeds with the new page appearing in nav at position 4.

**Spec success criteria satisfied**: SC-005 (user produces professional-only report within 10 minutes from this guide alone), SC-006 (new page renders without errors).

**Files changed**: `src/content/docs/categorization.md` (new)

### Phase 5: changelog.md (order update + v3.0.1 entry)

**Sources**:
- Release date: `dev-review-prep/docs/dcv.1` man page header (`"2026-03-07"`)
- Command list: `research.md` → Decision 3 (command signatures table — all commands not present in v1.0.0)
- Model IDs: `research.md` → Decision 4 (use full model IDs: `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5`)
- Migration behavior: `dev-review-prep/docs/configuration.md` → Migration from V1 to V2 section

**Two changes to make**:
1. Update frontmatter `order: 4` → `order: 5` (changelog shifts to last position per `contracts/docs-frontmatter.md`)
2. Insert this v3.0.1 entry **above** the existing `## v1.0.0` entry (newest first):

```markdown
## v3.0.1 — 2026-03-07

### Added
- `dcv journal` — log daily work entries with optional date, category, and inline text flags
- `dcv query` — interactive RAG Q&A over your indexed artifacts (requires Voyage AI)
- `dcv index` — backfill vector embeddings for all existing artifacts
- `dcv compare` — trajectory analysis comparing two performance review reports
- `dcv curate` — add personal context notes to individual artifacts
- `dcv sources` — manage data sources (list, add, configure, remove) without re-running init
- `dcv providers` — manage LLM/embedding providers (list, add, configure, remove)
- `dcv upgrade` — check for and apply binary updates
- `dcv about` — show version, build info, and license
- Context categorization — `category` field on sources + `--category` flag on fetch, analyze, query, and journal

### Changed
- Config schema updated to V2 (`schema_version: 2`) with `sources[]` and `providers[]` arrays
- LLM provider changed from OpenAI to Anthropic Claude (models: `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5`)
- Added Voyage AI as embedding provider for RAG features
- `dcv fetch` now requires `--since` and `--until` in date-range mode

### Migration
- Run `dcv init` to migrate V1 config. The wizard detects existing V1 config, backs it up to `config.json.v1.bak`, and migrates sources to the V2 multi-source format.
```

**Done when**: Changelog shows v3.0.1 entry first (newest-first order), all 9 new commands are listed, model IDs use the `claude-` prefix format, and `npm run build` succeeds with changelog at nav position 5.

**Spec success criteria satisfied**: SC-006 (changelog renders without errors); spec FR-010 (all new commands listed with migration note).

**Files changed**: `src/content/docs/changelog.md`

## Post-Implementation Verification

Run these checks after all 5 phases are complete, before marking the branch ready for review.

### Build & Render
```bash
npm run build    # Must exit 0 — Zod schema validates all frontmatter
npm run preview  # Open each docs page and verify nav order: Installation → Quickstart → Configuration → Context Categorization → Changelog
```

### Content Accuracy Checklist

- [ ] `quickstart.md`: Every command shown matches a signature in `research.md` Decision 3
- [ ] `quickstart.md`: `dcv fetch` shows `--since` and `--until` as required (not optional)
- [ ] `quickstart.md`: Workflow step order is `curate → view` (matching spec FR-001 and the man page canonical order)
- [ ] `configuration.md`: Zero mentions of OpenAI as an active provider (SC-002)
- [ ] `configuration.md`: Zero occurrences of V1 schema format — no top-level `"github"`, `"providers.openai"` etc. (SC-003)
- [ ] `configuration.md`: All source type labels match `research.md` Decision 2 table exactly
- [ ] `configuration.md`: Anthropic model IDs match `research.md` Decision 4: `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5`
- [ ] `categorization.md`: Appears in nav at position 4 (between Configuration and Changelog)
- [ ] `categorization.md`: Links to Configuration guide for category naming rules (does not restate them)
- [ ] `changelog.md`: At nav position 5; v3.0.1 entry appears above v1.0.0 entry
- [ ] `changelog.md`: Model IDs use `claude-` prefix (not bare `opus-4-6`)
- [ ] `installation.md`: All binary names verified against v3.0.1 GitHub release assets

### Spec Success Criteria Sign-off

| Criterion | Verified by |
|-----------|------------|
| SC-001: All commands work as documented | Manual command check against `research.md` Decision 3 |
| SC-002: Zero OpenAI references in config/quickstart | Grep for "openai" in `src/content/docs/` |
| SC-003: Zero V1 schema references | Grep for `"github":` and `"providers": {` (V1 patterns) |
| SC-004: User can generate report from Quickstart alone | Walk through quickstart steps end-to-end |
| SC-005: User produces professional-only report from Categorization guide | Walk through categorization steps 1–4 |
| SC-006: All 5 pages render without errors | `npm run build` exits 0 |
