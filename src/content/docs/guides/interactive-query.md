---
title: "Interactive Query"
description: "Search your work history with natural language (Pro feature preview)"
order: 33
---

# Interactive Query

> **Pro Feature** — Interactive Query requires a dcv Pro license. This guide previews the feature for users considering Pro. During the Open Beta, Pro features are not yet available.
>
> **Experimental** — This feature is highly experimental and under active development. **All information in this guide, including the command names, syntax, output format, and behavior, is subject to significant change before the feature becomes available.** Please do not rely on the specifics described here for production workflows. Check back regularly for updates as the feature evolves.

Interactive Query lets you search your work history using natural language. Instead of manually browsing commits and PRs, you ask questions and get answers synthesized from your actual work data.

## How It Works

Interactive Query uses a three-stage pipeline:

1. **Indexing** — Voyage AI generates vector embeddings from your work artifacts (commits, PRs, cards, curation notes) and stores them locally
2. **Search** — When you ask a question, dcv performs semantic search over the embeddings to find the most relevant artifacts
3. **Synthesis** — Anthropic synthesizes a natural language answer from the matching artifacts

Because embeddings capture meaning rather than keywords, you can ask questions like "What did I work on related to authentication?" and get results even if none of your commits contain the word "authentication."

## Building Your Index

Before querying, build your vector index:

```bash
dcv index
```

This command processes all fetched artifacts and generates embeddings via your configured Voyage AI provider. See the [Voyage AI setup guide](/dcv/docs/providers/voyage) for configuration details.

**Note**: The `dcv index` command is available on the Free tier. It prepares your data for querying, so you can build the index in advance.

What gets indexed:

- Commit messages and metadata
- Pull request titles, descriptions, and review comments
- Trello card titles and descriptions
- Curation notes you added during `dcv curate`

Re-run `dcv index` after fetching new data to keep the index current.

## Querying Your Work

With a Pro license and a built index, ask questions about your work:

```bash
dcv query "What did I work on related to authentication?"
```

The output includes:

- **Matching artifacts** — The specific commits, PRs, and cards that are semantically relevant to your question, ranked by relevance
- **Synthesized answer** — A natural language summary that draws on the matching artifacts to answer your question directly

```text
Found 7 matching artifacts:

  1. PR #142 — "Add OAuth2 PKCE flow for mobile clients"
  2. Commit a3f19b2 — "Migrate session tokens to JWT"
  3. PR #138 — "Fix token refresh race condition"
  ...

Answer:
Over the past quarter, your authentication work centered on two
initiatives: migrating the session layer from opaque tokens to JWTs
(commits a3f19b2, d7e4c1a) and implementing OAuth2 PKCE for mobile
clients (PR #142). You also resolved a token refresh race condition
that was causing intermittent logouts (PR #138).
```

## Interactive Mode

For exploratory sessions, use interactive mode to ask follow-up questions:

```bash
dcv query
```

This starts a multi-turn conversation where each question can refine or build on previous results:

```bash
dcv> What did I work on related to authentication?
[... answer ...]

dcv> Which of those involved cross-team coordination?
[... refined answer focusing on collaboration aspects ...]

dcv> Summarize that as a STAR format accomplishment
[... formatted accomplishment ...]
```

Interactive mode maintains conversation context, so follow-up questions do not need to repeat the full context of your original question. Type `exit` or press `Ctrl+C` to end the session.
