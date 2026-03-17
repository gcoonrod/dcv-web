# Feature Specification: Sync Website Documentation to App v3.0.1

**Feature Branch**: `001-update-docs`
**Created**: 2026-03-14
**Status**: Draft
**Input**: User description: "Using the documentation in /Users/greg.coonrod/dev/personal/claude/dev-review-prep/docs I want to completely update the documentation in the dcv-web project so that it accurately matches the actual dcv application documentation."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Accurate Quickstart Guide (Priority: P1)

A new user visits the dcv website and follows the Quickstart guide to generate their first performance review. They expect the commands and workflow shown on the website to actually work with the installed application.

**Why this priority**: The Quickstart is the most critical first-contact documentation. The current guide shows only 3 bare commands with no date ranges, no source configuration details, and no mention of the curate/view/analyze workflow that real users need. A visitor who follows the current guide will hit errors immediately, causing distrust and abandonment.

**Independent Test**: Can be fully tested by reading only the Quickstart page and verifying every command shown matches the `dcv --help` output for v3.0.1, and that the workflow produces a working report.

**Acceptance Scenarios**:

1. **Given** a user with dcv installed reads the Quickstart page, **When** they copy and run each command in order, **Then** each command succeeds without errors and the final output is a generated performance review report.
2. **Given** the Quickstart page is loaded, **When** a reader reviews the workflow steps, **Then** the steps correctly reflect the full workflow: `init` → `fetch` → `curate` → `view` → `analyze` — matching the canonical workflow described in the application man page.
3. **Given** the Quickstart shows `dcv fetch`, **When** a reader checks the command syntax, **Then** the page accurately shows that `--since` and `--until` date flags are required parameters, not optional ones.

---

### User Story 2 - Accurate Configuration Reference (Priority: P2)

An existing user visits the Configuration page to set up a second data source or configure the Anthropic LLM provider. The page currently shows a V1 schema with an OpenAI provider, which does not match the V2 schema the application actually uses.

**Why this priority**: Users who consult the configuration page to add sources or configure providers will construct invalid JSON that is rejected by the application. This directly blocks usage and erodes trust.

**Independent Test**: Can be fully tested by comparing every JSON snippet on the Configuration page against the V2 schema validated by `dcv init`, ensuring all fields, types, and provider names are correct.

**Acceptance Scenarios**:

1. **Given** a user reads the Configuration page and copies the example `config.json` structure, **When** they save it at `~/.dcv/config.json` and run `dcv fetch --since ... --until ...`, **Then** dcv accepts the configuration without schema errors.
2. **Given** the Configuration page shows provider configuration, **When** a reader reviews it, **Then** it correctly documents Anthropic (not OpenAI) as the supported LLM provider with the correct `type: "anthropic"` field and available model IDs.
3. **Given** the Configuration page is read, **When** a user wants to configure a GitHub source, **Then** the page shows the correct V2 source object format including `id`, `type`, `status`, `token`, `username`, `repos`, and the optional `category` field.
4. **Given** the Configuration page is read, **When** a user wants to segregate work and personal sources, **Then** the page explains the category system, naming rules, and how categories flow through to fetch, journal, analyze, and query commands.

---

### User Story 3 - Context Categorization Guide (Priority: P3)

A user with both professional and personal projects on the same machine wants to generate a work-only performance review for their manager. There is currently no documentation on the website about the category system.

**Why this priority**: Context categorization is a key differentiating feature of dcv v3.0.1. Without documentation, users are unaware it exists, reducing the perceived value of the product and increasing support questions.

**Independent Test**: Can be fully tested by reading only the Categorization guide and completing the scenario of generating a professional-only report from a mixed-source configuration. The guide may link to the Configuration guide's category naming rules section; no other external resource is required.

**Acceptance Scenarios**:

1. **Given** a user reads the Categorization guide, **When** they follow the steps, **Then** they can configure a `"professional"` and a `"personal"` source, fetch data, and generate a professional-only report using `dcv analyze --category professional`.
2. **Given** the Categorization guide is read, **When** a user wants to log a personal journal entry, **Then** the page shows the correct syntax: `dcv journal --personal -e "..."` or `dcv journal --category personal -e "..."`.
3. **Given** the Categorization guide is read, **When** a user encounters a category mismatch warning, **Then** the page explains the prompt options and recommends the correct action.

---

### User Story 4 - Updated Changelog (Priority: P4)

A returning user checks the Changelog page to understand what has changed between the version they previously used and the current v3.0.1 release.

**Why this priority**: The current changelog only documents v1.0.0. Without an updated changelog, users cannot understand the scope of changes or whether to re-run `dcv init` after upgrading.

**Independent Test**: Can be fully tested by reading the Changelog and confirming all major commands introduced between v1.0.0 and v3.0.1 are listed with their release versions.

**Acceptance Scenarios**:

1. **Given** a user reads the Changelog page, **When** they scan for new commands, **Then** they find entries for `journal`, `query`, `index`, `compare`, `curate`, `sources`, `providers`, `upgrade`, and `about`.
2. **Given** a user reads the Changelog page, **When** they look for breaking changes, **Then** the V1 → V2 config schema migration is documented as a notable change requiring `dcv init` re-run.

---

### Edge Cases

- What happens when a documentation page references a command flag that has been renamed or removed in v3.0.1?
- Pro-tier sources (GitLab, Azure DevOps, Bitbucket, Jira, Linear, Asana) MUST be documented with full JSON examples but labeled `(Pro)` to indicate paid-tier availability.
- Sources shown as `(Planned)` in `dcv init` (GitLab, Azure Repos) MUST also be labeled `(Coming Soon)` in the docs to signal they are not yet functional, distinguishing them from Pro sources that are available but paid.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Quickstart page MUST reflect the full canonical workflow: `init` → `fetch` (with `--since`/`--until`) → `curate` → `view` → `analyze` — as documented in the dcv v3.0.1 man page.
- **FR-002**: The Quickstart page MUST show that `dcv fetch` requires `--since` and `--until` date arguments in date-range mode.
- **FR-003**: The Configuration page MUST show the V2 config schema (`schema_version: 2`) with `sources[]` and `providers[]` arrays, replacing the current V1 schema.
- **FR-004**: The Configuration page MUST document Anthropic as the supported LLM provider (not OpenAI), with correct field names (`type: "anthropic"`, `role: "analysis"`, `apiKey`, `model`) and list available model IDs.
- **FR-005**: The Configuration page MUST document Voyage AI as the supported embedding provider, noting it is required for RAG features (`dcv query`, `dcv index`).
- **FR-006**: The Configuration page MUST document all source types with full JSON examples: confirmed-working sources (GitHub, GitHub Enterprise, Local Git, Trello) with no label; Pro-tier sources (GitLab, Azure DevOps, Bitbucket, Jira, Linear, Asana) labeled `(Pro)`; and sources shown as planned-only in `dcv init` additionally labeled `(Coming Soon)`.
- **FR-007**: The Configuration page MUST document the category system: the optional `category` field on sources, the default value of `"professional"`, and category naming rules.
- **FR-008**: The Configuration page MUST document the V1 → V2 migration path using `dcv init`, including the backup behavior.
- **FR-009**: A new Categorization guide page MUST be created at `src/content/docs/categorization.md` with `order: 4`, covering: adding `category` fields to sources, running `dcv fetch` with categories, writing journal entries by category, generating category-filtered analyze reports, and querying by category. The existing Changelog page MUST be updated from `order: 4` to `order: 5` to accommodate this insertion.
- **FR-010**: The Changelog page MUST be updated to include a v3.0.1 entry that lists all commands added since v1.0.0: `journal`, `query`, `index`, `compare`, `curate`, `sources`, `providers`, `upgrade`, `about`, and the V2 config schema.
- **FR-011**: All command examples on every documentation page MUST use correct v3.0.1 syntax, matching the man page command signatures.
- **FR-012**: Documentation MUST apply consistent labeling: `(Pro)` for paid-tier sources that are functional, `(Coming Soon)` for sources listed as planned-but-unimplemented in `dcv init`. These labels are mutually exclusive.

### Key Entities

- **Documentation Page**: A Markdown file in `src/content/docs/` with frontmatter (`title`, `description`, `order`) rendered as a website page. Existing pages: installation (order: 1), quickstart (order: 2), configuration (order: 3), changelog (order: 4 → shifting to 5). New page: categorization (order: 4).
- **Source Type**: A data source connector (GitHub, GitHub Enterprise, GitLab, Azure DevOps, Bitbucket, Trello, Jira, Linear, Asana, Local Git) with its specific required and optional configuration fields.
- **Category**: A string label attached to a data source or journal entry that enables filtering artifacts in analyze, query, and view operations.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every command shown in the documentation produces the same behavior as described when run against dcv v3.0.1, verified by manually executing each example.
- **SC-002**: Zero references to OpenAI remain in the configuration or quickstart documentation after the update is applied.
- **SC-003**: Zero references to the V1 config schema format remain in the documentation after the update is applied.
- **SC-004**: A new user can read only the Quickstart page and successfully generate a performance review report without consulting any external resource.
- **SC-005**: A user who has never heard of "categories" can read the new Categorization guide and produce a professional-only report within 10 minutes.
- **SC-006**: All four existing pages (installation, quickstart, configuration, changelog) and the new categorization page render without errors in the dcv-web build. The installation page's install script URL and binary names match the v3.0.1 release assets.

## Clarifications

### Session 2026-03-14

- Q: For data source types in the config docs — should Pro-tier (functional but paid) and Planned (not yet implemented) sources use different labels, or be treated the same? → A: Use both labels: `(Pro)` for paid-tier functional sources, `(Coming Soon)` for truly unimplemented sources.
- Q: Where should the new Categorization guide page sit in the docs navigation order? → A: Insert between Configuration and Changelog — new page gets `order: 4`, Changelog shifts to `order: 5`.
- Q: What scope of review applies to `installation.md`? → A: Verify install script URL and binary names against v3.0.1 release assets; update only confirmed-changed fields, no structural rewrite.

## Assumptions

- The `installation.md` page requires verification of the install script URL and binary names against v3.0.1 release assets; only confirmed-changed fields are updated. No structural rewrite is needed.
- Source types are labeled using two distinct labels: `(Pro)` for paid-tier sources that are functional (GitLab, Azure DevOps, Bitbucket, Jira, Linear, Asana), and `(Coming Soon)` for sources that are planned but not yet implemented (as shown in `dcv init`). These labels are mutually exclusive.
- The Categorization guide is based on the `quickstart.md` file from `dev-review-prep/docs/`, which describes the context categorization feature (feature 027-context-categorization) in the actual dcv application.
- The changelog is being written retroactively; specific version numbers for intermediate releases (v1.x to v2.x) are not available in the source docs, so a single v3.0.1 entry documenting all new capabilities relative to v1.0.0 is acceptable.
- The `dcv journal --personal` shorthand is equivalent to `dcv journal --category personal` and both forms should be shown in the docs.
