---
title: "Quickstart"
description: "Run your first dcv report in under 5 minutes."
order: 2
---

# Quickstart

## Step 1: Initialize

Run `dcv init` inside a Git repository to create the default config file:

```bash
cd ~/my-project
dcv init
```

This creates `~/.dcv/config.json` with sensible defaults.

## Step 2: Fetch Data

Pull your activity data from configured sources:

```bash
dcv fetch
```

## Step 3: Analyze

Generate your CV report:

```bash
dcv analyze
```

Output is written to `./dcv-report.md` by default.
