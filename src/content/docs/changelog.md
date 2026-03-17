---
title: "Changelog"
description: "Release history for dcv."
order: 5
---

# Changelog

## v3.0.1 — 2026-03-07

### Added
- `dcv journal` — log daily work entries with optional date, category, and inline text flags
- `dcv query` — interactive RAG Q&A over your indexed artifacts (requires Voyage AI)
- `dcv index` — backfill vector embeddings for all existing artifacts
- `dcv compare` — trajectory analysis comparing two performance review reports
- `dcv curate` — add personal context notes to individual artifacts
- `dcv sources` — manage data sources (list, add, configure, remove) without re-running init
- `dcv providers` — manage LLM/embedding providers (list, add, configure, remove)
- `dcv upgrade` — check for and apply binary updates
- `dcv about` — show version, build info, and license
- Context categorization — `category` field on sources + `--category` flag on fetch, analyze, query, and journal

### Changed
- Config schema updated to V2 (`schema_version: 2`) with `sources[]` and `providers[]` arrays
- LLM provider changed from OpenAI to Anthropic Claude (models: `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5`)
- Added Voyage AI as embedding provider for RAG features
- `dcv fetch` now requires `--since` and `--until` in date-range mode

### Migration
- Run `dcv init` to migrate V1 config. The wizard detects existing V1 config, backs it up to `config.json.v1.bak`, and migrates sources to the V2 multi-source format.

---

## v1.0.0 — 2026-03-06

Initial release.

### Added
- `dcv init` — initialize config
- `dcv fetch` — fetch from local Git and public GitHub
- `dcv analyze` — generate Markdown report
- BYO-LLM key support (OpenAI)
