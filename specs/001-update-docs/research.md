# Research: Sync Website Documentation to App v3.0.1

**Branch**: `001-update-docs` | **Date**: 2026-03-14

## Summary

This feature is pure content — no architectural unknowns, no new libraries, no API integrations. Research focused on: (1) confirming the Astro docs routing mechanism to determine what code changes are needed, (2) cataloguing all v3.0.1 commands and their exact syntax from the man page, and (3) establishing the Pro vs Coming Soon source-type labeling scheme.

---

## Decision 1: New Page Requires Zero Code Changes

**Decision**: The new `categorization.md` page requires only a new Markdown file. No routing, nav, or layout code changes are needed.

**Rationale**: The docs routing is fully data-driven:
- `src/pages/docs/[...slug].astro` uses `getStaticPaths()` to generate routes from all content collection entries — any new `.md` file automatically gets a route.
- `src/layouts/DocsLayout.astro` fetches all docs and sorts by `order` at build time — nav updates automatically.
- `src/components/DocsSidebar.astro` receives the sorted array as props — no hardcoded links.
- `src/content/config.ts` Zod schema only validates `title`, `description`, `order` — all standard fields.

**Alternatives considered**: Manually adding a nav link entry in a config file — rejected because no such config file exists; the architecture eliminates this need.

---

## Decision 2: Source Type Labeling Taxonomy

**Decision**: Use `(Pro)` and `(Coming Soon)` as mutually exclusive labels. Sources that are both Planned AND would be Pro tier get both labels.

**Rationale**: The `dcv init` wizard explicitly marks GitLab and Azure DevOps as `(Planned)` — they are not yet functional. Bitbucket, Jira, Linear, and Asana are documented with full working JSON in the configuration guide, indicating they are functional but paid-tier. Users need to distinguish "doesn't work yet" from "works but costs money."

**Source type classification** (from `dev-review-prep/docs/configuration.md` + `dcv.1` man page):

| Source | Label | Basis |
|--------|-------|-------|
| GitHub | (none) | Free, confirmed working |
| GitHub Enterprise | (none) | Free, confirmed working (uses custom_domain) |
| Local Git | (none) | Free, confirmed working |
| Trello | (none) | Free, confirmed working |
| GitLab | `(Pro)` `(Coming Soon)` | Listed as Planned in `dcv init` wizard; Pro config documented |
| Azure DevOps | `(Pro)` `(Coming Soon)` | Listed as Planned in `dcv init` wizard; Pro config documented |
| Bitbucket | `(Pro)` | Full config in docs; not marked Planned |
| Jira | `(Pro)` | Full config in docs; not marked Planned |
| Linear | `(Pro)` | Full config in docs; not marked Planned |
| Asana | `(Pro)` | Full config in docs; not marked Planned |

**Alternatives considered**: Single "Pro" label for all non-free sources — rejected because it falsely implies GitLab/Azure work today. Omitting non-working sources entirely — rejected per FR-006 (document all with labels).

---

## Decision 3: v3.0.1 Command Signatures (from man page)

All commands confirmed from `dev-review-prep/docs/dcv.1`:

| Command | Synopsis |
|---------|---------|
| `dcv init` | Interactive wizard; requires TTY |
| `dcv fetch --since DATE --until DATE [--force]` | Date-range mode (required flags) |
| `dcv fetch --url URL` | Single item by URL; mutually exclusive with date-range flags |
| `dcv fetch --source local-git [--path dir] --since DATE --until DATE` | Local git mode |
| `dcv index [--force]` | Backfill vector embeddings; requires Voyage AI |
| `dcv view [--since DATE] [--until DATE]` | Preview fetched artifacts |
| `dcv curate [--since DATE --until DATE]` | Add personal notes to artifacts |
| `dcv analyze [--since DATE] [--until DATE] [--category list] [--model id] [-D] [-o path]` | Generate report |
| `dcv compare baseline current [--model id] [-D] [-o path]` | Trajectory analysis |
| `dcv query [question] [--category list] [--model id] [-D]` | RAG Q&A |
| `dcv sources {list\|add\|configure id\|remove id} [flags]` | Manage sources |
| `dcv providers {list\|add\|configure id\|remove id} [flags]` | Manage providers |
| `dcv journal [-e text] [--date DATE] [--category name \| --personal] [--amend]` | Log entry |
| `dcv journal purge --date DATE` | Delete journal entry |
| `dcv journal sync` | Sync journal files to database |
| `dcv purge [--force]` | Wipe local database |
| `dcv upgrade [--check]` | Update binary |
| `dcv about` | Version, build info, license |
| `dcv --version` | Print version string |

**Key difference from V1**: `dcv fetch` now requires `--since` and `--until` in date-range mode (they were optional or inferred in V1).

---

## Decision 4: Anthropic Provider Config (from configuration.md)

**Decision**: Document Anthropic as the sole supported LLM provider with these models:

```json
{
  "id": "claude",
  "type": "anthropic",
  "role": "analysis",
  "apiKey": "sk-ant-xxxxxxxxxxxx",
  "model": "claude-opus-4-6",
  "default": true
}
```

**Available models** (from source docs):
- `claude-opus-4-6` — most capable, recommended
- `claude-sonnet-4-6` — balanced performance/cost
- `claude-haiku-4-5` — fastest, most economical

**OpenAI** is listed as `(Planned)` in the `dcv init` wizard — does not yet work.

---

## Decision 5: Installation Page Verification

**Decision**: The installation page references `https://apps.microcode.io/dcv/install.sh` and binaries `dcv-macos-arm64`, `dcv-macos-x86_64`, `dcv-linux-x86_64`, `dcv-windows-x86_64.exe`. These cannot be verified without access to the live URL or GitHub releases.

**Action**: Mark as **manual verification required** during implementation. The implementer MUST check `https://github.com/gcoonrod/dcv/releases/tag/v3.0.1` (or latest) to confirm binary names before updating. If the current names match, no change is needed. If different, update the table.

**Alternatives considered**: Skipping verification entirely — rejected because SC-001 requires all install commands to work as documented.

---

## Decision 6: Quickstart Canonical Workflow

**Decision**: The Quickstart page reflects the canonical workflow from the `dcv.1` man page DESCRIPTION section:

> init → fetch → curate → view → analyze → compare → query → purge

For a beginner Quickstart, scope to the core path:

**init → fetch → curate → view → analyze**

with `compare` and `query` mentioned as "Next Steps." This follows the canonical man page order and covers the essential value loop.

**Rationale**: The man page explicitly calls this the "typical workflow." The existing quickstart (3 steps) is too minimal — it omits `view` and `curate` which are part of the documented standard flow. `compare` and `query` require additional setup (a prior report for compare; Voyage AI for query) so they belong in Next Steps.
