---
title: "Quickstart"
description: "Run your first dcv report in under 5 minutes."
order: 2
---

# Quickstart

Run your first dcv performance review in 5 steps.

## Prerequisites

- dcv installed ([Installation guide](/dcv/docs/installation))
- An Anthropic API key for report generation
- Run `dcv init` to configure at least one data source before fetching

## Step 1: Initialize

Run the interactive wizard to create `~/.dcv/config.json`:

```bash
dcv init
```

The wizard guides you through configuring your data sources (GitHub, Jira, Trello, etc.) and your Anthropic API key. See the [Configuration guide](/dcv/docs/configuration) for the full schema reference.

> **Note**: `dcv init` requires an interactive terminal (TTY). It cannot be run in non-interactive scripts.

## Step 2: Fetch Your Data

Pull your activity data from configured sources for a date range:

```bash
dcv fetch --since 2026-01-01 --until 2026-03-31
```

> **Required**: `--since` and `--until` are required in date-range mode. Both must be provided.

To fetch a single item by URL instead:

```bash
dcv fetch --url https://github.com/org/repo/pull/123
```

## Step 3: Curate

Review fetched artifacts and add personal context notes before generating your report:

```bash
dcv curate --since 2026-01-01 --until 2026-03-31
```

This opens an interactive interface where you can annotate key PRs, commits, and tickets. Notes added here are included in the analysis and improve report quality.

## Step 4: View

Preview the fetched artifacts and any curation notes you added:

```bash
dcv view --since 2026-01-01 --until 2026-03-31
```

Use this to confirm your data looks correct before running the analysis.

## Step 5: Analyze

Generate your performance review report:

```bash
dcv analyze --since 2026-01-01 --until 2026-03-31 -o ~/Desktop/q1_review.md
```

Your report is written to the path specified by `-o`. The default output path is `./dcv-report.md`.

## Next Steps

Your first report is ready. From here you can:

- **Compare reports**: `dcv compare <baseline> <current>` — show your growth trajectory over time
- **Ask questions**: `dcv query "What were my biggest accomplishments?"` — RAG-powered Q&A over your data (requires Voyage AI — see the [Configuration guide](/dcv/docs/configuration))
- **Separate work and personal projects**: See the [Context Categorization guide](/dcv/docs/categorization) to generate work-only or personal-only reports
