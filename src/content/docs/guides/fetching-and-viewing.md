---
title: "Fetching & Viewing"
description: "Pull data from sources and inspect what was collected"
order: 30
---

# Fetching & Viewing

This guide walks through pulling your work data from configured sources and reviewing what was collected before generating reports.

## Your First Fetch

Once you have at least one source configured (via `dcv init`), fetch your activity for a date range:

```bash
dcv fetch --since 2026-03-01 --until 2026-03-15
```

The output summarizes what was collected:

```
Fetching from GitHub (gcoonrod)...
  ✓ 12 pull requests
  ✓ 47 commits

Fetch complete: 59 artifacts collected (1 source)
```

Each source reports its artifact counts individually, so you can immediately see whether data is flowing from each integration.

## Multi-Source Fetching

When you have multiple sources configured — say GitHub, Trello, and Local Git — a single `dcv fetch` pulls from all of them:

```bash
dcv fetch --since 2026-03-01 --until 2026-03-15
```

```
Fetching from GitHub (gcoonrod)...
  ✓ 12 pull requests
  ✓ 47 commits
Fetching from Trello (dev-board)...
  ✓ 8 cards
Fetching from Local Git (/home/user/projects/api)...
  ✓ 23 commits

Fetch complete: 90 artifacts collected (3 sources)
```

The combined summary gives you a quick health check across all your tracked work.

## Date Ranges & Incremental Fetching

Both `--since` and `--until` are **required** in date-range mode. They define the window of activity to pull:

```bash
dcv fetch --since 2026-01-01 --until 2026-03-31
```

**Incremental fetching**: If you run the same fetch command again (same date range), dcv performs a delta computation. New artifacts are added and existing artifacts are upserted — they update in place rather than creating duplicates. This means you can safely re-fetch to pick up recent activity without worrying about inflated counts.

**Narrowing the window**: For weekly check-ins, use tighter date ranges. For quarterly reviews, use the full quarter. The date range you fetch determines what is available for curation, viewing, and analysis.

## Viewing Your Data

After fetching, use `dcv view` to inspect what was collected:

```bash
dcv view --since 2026-03-01 --until 2026-03-15
```

The view summarizes your data by source and type:

```
Activity Summary (2026-03-01 to 2026-03-15)
────────────────────────────────────────────
GitHub (gcoonrod):
  Pull Requests:  12
  Commits:        47

Trello (dev-board):
  Cards:           8

Total: 67 artifacts across 2 sources
```

Use this to confirm your data looks correct before running curation or analysis. If counts seem low, check the troubleshooting section below.

## Troubleshooting

**No pull requests found** — Verify the username in your GitHub source configuration matches the account that authored the PRs. dcv filters pull requests client-side by matching the `user.login` field, so a mismatched username returns zero results.

**Authentication error** — Your API token may have expired or been revoked. Re-run `dcv init` to update the token, or edit `~/.dcv/config.json` directly. See the relevant source guide for token requirements.

**Empty results for a date range** — Double-check your `--since` and `--until` values. Activity outside the specified window is not included. Also verify that work was actually merged or committed within those dates (not just opened).

**Source not configured** — If a source does not appear in the fetch output, it has not been set up yet. Run `dcv init` to add it, or refer to the source-specific setup guides:

- [GitHub](/dcv/docs/sources/github)
- [Trello](/dcv/docs/sources/trello)
- [Local Git](/dcv/docs/sources/local-git)
