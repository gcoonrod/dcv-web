---
title: "Anthropic"
description: "Configure Anthropic as an AI provider for dcv analysis"
order: 20
---

## Prerequisites

- An **Anthropic API key** from [console.anthropic.com](https://console.anthropic.com/)

## Configuration

Add an Anthropic provider entry to the `providers` array in your `~/.config/dcv/config.json`:

```json
{
  "id": "anthropic",
  "type": "anthropic",
  "role": "analysis",
  "apiKey": "sk-ant-xxxxxxxxxxxx",
  "model": "claude-3-5-sonnet-latest",
  "default": true,
  "status": "active"
}
```

### Field reference

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier. Lowercase alphanumeric and hyphens, 2-64 characters. |
| `type` | Yes | Must be `"anthropic"`. |
| `role` | Yes | Must be `"analysis"`. Anthropic models are used for generating contribution reports. |
| `apiKey` | Yes | Anthropic API key. Can also be set via the `DCV_ANTHROPIC_API_KEY` environment variable. |
| `model` | No | Model to use. Default: `claude-3-5-sonnet-latest`. |
| `default` | No | Set to `true` to make this the default analysis provider. |
| `status` | Yes | `"active"` or `"inactive"`. Inactive providers are skipped. |

## Verify It Works

Run an analysis with a date range:

```bash
dcv analyze --since 2026-03-01 --until 2026-03-15
```

You should see output similar to:

```
Analyzing contributions...
  Using provider: anthropic (claude-3-5-sonnet-latest)
  Processing 59 items...
Report generated: ~/.local/share/dcv/reports/2026-03-01_2026-03-15.md
```

## Tips

- **Model selection** -- `claude-3-5-sonnet-latest` offers the best balance of quality and speed for contribution analysis. You can also use `claude-3-5-haiku-latest` for faster, lower-cost runs.
- **Token budgets** -- The model has a 200K context window. For most contributors, two weeks of data fits within a single context. dcv uses map-reduce for larger datasets that exceed the context window.
- **Map-reduce for large datasets** -- When contribution data exceeds the context window, dcv automatically splits the data into chunks, analyzes each chunk independently, then synthesizes the results into a single report.
- **Cost management** -- Each analysis run consumes API credits. Use `--since` and `--until` to limit the date range and reduce token usage.
