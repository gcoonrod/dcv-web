---
title: "Curating & Analyzing"
description: "Add context to your work data and generate AI-powered reports"
order: 31
---

# Curating & Analyzing

This guide covers adding context to your fetched data and generating AI-powered performance review reports.

## Why Curate?

Raw commits and pull requests capture *what* you did, but they rarely explain *why*. A commit message like `fix: handle null response` does not convey that you diagnosed a production incident, identified the root cause across three services, and shipped a fix under time pressure.

Curation lets you add that missing context. You can annotate individual artifacts with personal notes and group related work into named workstreams. When dcv generates your report, it synthesizes these notes alongside the raw data to produce accomplishments that reflect the full picture — not just the code diff.

## Adding Notes

Start curation for a date range:

```bash
dcv curate --since 2026-03-01 --until 2026-03-15
```

This opens an interactive interface that presents your fetched artifacts. For each item, you can:

- **Skip** it if no additional context is needed
- **Add a note** explaining the significance, impact, or difficulty of the work
- **Tag** it with a workstream name (see below)

Notes do not need to be long. A sentence or two is often enough:

> "Resolved a race condition that caused intermittent 500s in production. Required coordinating a deploy with the platform team."

The more context you provide, the better your analysis report will read.

## Creating Workstreams

Workstreams group related artifacts under a named theme. When you tag multiple PRs, commits, and cards with the same workstream name, dcv treats them as a cohesive body of work in the analysis.

**Example**: You worked on an authentication overhaul that touched three repositories over two weeks. The individual commits and PRs are scattered across sources, but by tagging them all under the workstream "Authentication Overhaul", the analysis can describe the initiative as a single accomplishment rather than a list of disconnected changes.

During curation, assign a workstream name when prompted. Workstream names are freeform — use whatever label makes sense for your work.

## Running Analysis

Generate your performance review report with `dcv analyze`:

```bash
dcv analyze --since 2026-03-01 --until 2026-03-15 -o ~/review.md
```

This sends your artifacts and curation notes to your configured AI provider for synthesis. The Anthropic provider must be set up in your configuration. See the [Anthropic provider setup guide](/dcv/docs/providers/anthropic) for details.

The `-o` flag specifies the output file path. If omitted, the report is written to `~/.local/share/dcv/reports/`.

## Reading Your Report

The generated report follows a structured format:

- **Summary** — A high-level overview of what you accomplished during the period
- **Accomplishments** — Individual items written in STAR format (Situation, Task, Action, Result), synthesized from your commit messages, PR descriptions, and curation notes
- **Technical Contributions** — Breakdown of technical work by area
- **Collaboration** — Cross-team work, code reviews, and coordination efforts

The AI synthesizes raw data with your curation notes. Artifacts you annotated with detailed notes tend to produce richer, more accurate accomplishment descriptions. Artifacts without notes still appear but rely solely on commit messages and PR titles.

## Comparing Reports

Track your growth over time by comparing two reports:

```bash
dcv compare ~/q1_review.md ~/q2_review.md
```

The comparison performs trajectory analysis between two time periods. It highlights:

- **Growth areas** — Skills or responsibilities that expanded between periods
- **Consistency** — Themes that appear in both reports, showing sustained contributions
- **New directions** — Work areas that appear in the later report but not the earlier one

This is particularly useful for annual reviews where you want to show progression across multiple quarters.
