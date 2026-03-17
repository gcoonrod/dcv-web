# Data Model: Sync Website Documentation to App v3.0.1

**Branch**: `001-update-docs` | **Date**: 2026-03-14

## Overview

This feature has no new data model — it modifies static Markdown content files. The only "data model" is the Astro content collection schema that validates docs frontmatter at build time.

---

## Docs Content Collection Schema

**Defined in**: `src/content/config.ts`

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `title` | `string` | Required | Page title displayed in `<title>` and `<h1>` |
| `description` | `string` | Required | Meta description for SEO and sidebar subtitle |
| `order` | `number` (integer) | Required, min: 1 | Sort position in sidebar navigation |

**Validation**: Enforced by Zod at `npm run build`. Build fails if any `.md` file in `src/content/docs/` has missing or invalid frontmatter.

---

## Navigation Order (Post-Feature)

After this feature is implemented, the docs nav order will be:

| Order | Slug | Title | Status |
|-------|------|-------|--------|
| 1 | `installation` | Installation | Unchanged (possibly minor content update) |
| 2 | `quickstart` | Quickstart | Full rewrite |
| 3 | `configuration` | Configuration | Full rewrite |
| 4 | `categorization` | Context Categorization | **New** |
| 5 | `changelog` | Changelog | Order updated (4→5) + v3.0.1 entry added |

---

## Source Type Taxonomy

Not a runtime data model, but a content taxonomy used consistently across the Configuration page:

| Source Type | ID Prefix Convention | Tier | Status |
|-------------|---------------------|------|--------|
| `github` | `github-*` | Free | Active |
| `github_enterprise` | `github-enterprise-*` | Free | Active |
| `local-git` | `local-*` | Free | Active |
| `trello` | `trello-*` | Free | Active |
| `bitbucket` | `bitbucket-*` | Pro | Active |
| `jira` | `jira-*` | Pro | Active |
| `linear` | `linear-*` | Pro | Active |
| `asana` | `asana-*` | Pro | Active |
| `gitlab` | `gitlab-*` | Pro | Coming Soon |
| `azure_repos` | `azure-*` | Pro | Coming Soon |

---

## Category System Rules (Content Reference)

Rules to be documented accurately in `configuration.md` and `categorization.md`:

| Rule | Detail |
|------|--------|
| Default value | `"professional"` (if `category` field is omitted from source) |
| Format | Lowercase alphanumeric with hyphens only |
| Length | 1–32 characters |
| Reserved keywords | `all`, `none`, `any` (from config docs); `where` (reserved SQL keyword per quickstart docs) |
| Invalid characters | Spaces, underscores, uppercase |
| Inheritance | All artifacts fetched from a source inherit that source's `category` value |
