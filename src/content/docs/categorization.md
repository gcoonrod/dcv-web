---
title: "Context Categorization"
description: "Segregate work contexts and generate category-specific performance reviews."
order: 4
---

# Context Categorization

Learn how to segregate your work into categories (professional, personal, open-source, etc.) and generate context-specific performance reviews.

## Overview

Many developers work on both professional projects and personal side projects on the same machine. Context categorization lets you:

- Tag each data source with a category label
- Fetch artifacts that automatically inherit their source's category
- Generate reports filtered to a specific context — e.g., a work-only review for your manager
- Keep professional and personal journal entries in separate directories

## Prerequisites

- dcv installed and configured (`dcv init` completed with at least one source)
- Existing artifacts in the database are helpful but not required

---

## Step 1: Configure Source Categories

Edit your config file to add `category` fields to your sources:

```bash
$EDITOR ~/.dcv/config.json
```

Add a `"category"` field to each source:

```json
{
  "schema_version": 2,
  "sources": [
    {
      "id": "github-work",
      "type": "github",
      "status": "active",
      "token": "ghp_xxxxx",
      "username": "workuser",
      "repos": ["company/app"],
      "category": "professional"
    },
    {
      "id": "github-personal",
      "type": "github",
      "status": "active",
      "token": "ghp_yyyyy",
      "username": "personaluser",
      "repos": ["me/side-project"],
      "category": "personal"
    }
  ],
  "providers": []
}
```

**Default**: If you omit `"category"`, the source defaults to `"professional"`.

For category naming rules, see the [Configuration guide](/dcv/docs/configuration#category-system).

---

## Step 2: Fetch Data with Categories

Run `dcv fetch` to pull data from your sources:

```bash
dcv fetch --since 2026-01-01 --until 2026-03-31
```

**What happens**:
- Artifacts from `github-work` are tagged `category = professional`
- Artifacts from `github-personal` are tagged `category = personal`

**If you already have unfiled data**: dcv detects the category change and prompts you:

```text
⚠ Category mismatch detected for source "github-personal"
  Existing artifacts: professional
  Current config:     personal

Choose an action:
  1. Preserve existing categories (recommended)
  2. Update all artifacts to "personal"

Your choice [1]: 2
```

Choose option 2 to re-categorize your existing personal artifacts.

---

## Step 3: Journal with Categories

Log daily work with category tags:

```bash
# Professional work (default)
dcv journal -e "Fixed production bug in payment service"

# Personal side project — shorthand
dcv journal --personal -e "Added dark mode to my blog"

# Open source contribution — explicit flag
dcv journal --category open-source -e "Contributed PR to React"
```

**Result**: Journal files are organized by category:

```text
~/.dcv/journals/
├── professional/
│   └── 2026/03/2026-03-10_entry.md
├── personal/
│   └── 2026/03/2026-03-10_entry.md
└── open-source/
    └── 2026/03/2026-03-10_entry.md
```

> `--personal` is shorthand for `--category personal`. Both forms produce identical results.

---

## Step 4: Generate a Category-Filtered Report

Create a performance review that only includes professional work:

```bash
dcv analyze --category professional --since 2026-01-01 --until 2026-03-31
```

**Result**: The generated report includes only:
- Artifacts from sources tagged `"professional"`
- Professional journal entries

**Omitting `--category` includes all categories** — no silent filtering occurs:

```bash
dcv analyze --since 2026-01-01 --until 2026-03-31
```

---

## Step 5: Query by Category

Use RAG to query specific categories:

```bash
# Query professional work only
dcv query --category professional "What were my biggest accomplishments this quarter?"

# Query personal projects only
dcv query --category personal "What side projects did I work on?"

# Query all categories (default)
dcv query "What did I do in March?"
```

> `dcv query` requires Voyage AI to be configured as an embedding provider. See the [Configuration guide](/dcv/docs/configuration#embedding-providers).

---

## Common Workflows

### Quarterly Work Review

Generate a professional-only report for your 1-on-1:

```bash
dcv analyze \
  --category professional \
  --since 2026-01-01 \
  --until 2026-03-31 \
  -o ~/Desktop/q1_review.md
```

### Personal Projects Showcase

Generate a portfolio of personal work:

```bash
dcv analyze \
  --category personal \
  --since 2026-01-01 \
  --until 2026-12-31 \
  -o ~/Desktop/personal_projects_2026.md
```

### Combined Open Source + Professional

Show all non-personal contributions:

```bash
dcv analyze \
  --category professional,open-source \
  --since 2026-01-01 \
  --until 2026-03-31
```

---

## Category Naming Guidelines

**Valid category names** — lowercase letters, numbers, and hyphens, 1–32 characters:
- `professional` ✅
- `personal` ✅
- `open-source` ✅
- `side-projects` ✅
- `work-2024` ✅

**Invalid category names**:
- `My Work` ❌ (spaces not allowed)
- `personal_projects` ❌ (underscores not allowed)
- `where` ❌ (reserved SQL keyword)
- `all` ❌ (reserved keyword)
- `a-very-long-category-name-that-exceeds-the-thirty-two-character-limit` ❌ (too long)

For the authoritative rules table (format, length, reserved keywords), see [Configuration — Category Naming Rules](/dcv/docs/configuration#category-naming-rules).

---

## Troubleshooting

### My existing artifacts are all "professional"

If you added categories to sources after fetching data, run `dcv fetch` again. dcv will prompt you to choose whether to update existing artifacts or preserve their current categories.

### I need to recategorize journal entries

Journal entries are written to category-specific directories. To move a journal entry to a different category:

```bash
# 1. Move the file manually
mv ~/.dcv/journals/professional/2026/03/2026-03-10_entry.md \
   ~/.dcv/journals/personal/2026/03/

# 2. Sync the database
dcv journal sync
```

### How do I see all categories in my database?

Use `sqlite3` to inspect categories:

```bash
sqlite3 ~/.dcv/data.db \
  "SELECT category, COUNT(*) FROM artifacts GROUP BY category;"
```

---

## Advanced: Multiple Category Filters

Combine categories for complex filtering using comma-separated values:

```bash
# Professional + open source (exclude personal)
dcv analyze --category professional,open-source

# Personal + side projects
dcv analyze --category personal,side-projects
```

**Tip**: Create shell aliases for your most common filters:

```bash
alias dcv-work="dcv analyze --category professional"
alias dcv-personal="dcv analyze --category personal"
alias dcv-all="dcv analyze"
```
