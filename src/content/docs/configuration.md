---
title: "Configuration"
description: "Configure dcv with ~/.dcv/config.json."
order: 3
---

# Configuration

dcv reads from `~/.dcv/config.json`. Run `dcv init` to generate a default config.

## Schema

```json
{
  "sources": ["git-local", "github-public"],
  "providers": {
    "openai": {
      "apiKey": "sk-..."
    }
  },
  "output": {
    "format": "markdown",
    "path": "./dcv-report.md"
  }
}
```

## Fields

| Field | Type | Default | Description |
|---|---|---|---|
| `sources` | `string[]` | `["git-local"]` | Data sources to fetch from |
| `providers.openai.apiKey` | `string` | — | Your OpenAI API key (never leaves your machine) |
| `output.format` | `"markdown" \| "html" \| "latex"` | `"markdown"` | Report output format |
| `output.path` | `string` | `"./dcv-report.md"` | Output file path |
