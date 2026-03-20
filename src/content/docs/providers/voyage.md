---
title: "Voyage AI"
description: "Configure Voyage AI as an embedding provider for dcv"
order: 21
---

## Prerequisites

- A **Voyage AI API key** from [dash.voyageai.com](https://dash.voyageai.com/)

## Configuration

Add a Voyage AI provider entry to the `providers` array in your `~/.config/dcv/config.json`:

```json
{
  "id": "voyage",
  "type": "voyage",
  "role": "embedding",
  "apiKey": "pa-xxxxxxxxxxxx",
  "model": "voyage-3.5-lite",
  "default": true,
  "status": "active"
}
```

### Field reference

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier. Lowercase alphanumeric and hyphens, 2-64 characters. |
| `type` | Yes | Must be `"voyage"`. |
| `role` | Yes | Must be `"embedding"`. Voyage AI models are used for generating vector embeddings. |
| `apiKey` | Yes | Voyage AI API key. Can also be set via the `DCV_VOYAGE_API_KEY` environment variable. |
| `model` | No | Model to use. Default: `voyage-3.5-lite` (1024 dimensions). |
| `default` | No | Set to `true` to make this the default embedding provider. |
| `status` | Yes | `"active"` or `"inactive"`. Inactive providers are skipped. |

## Verify It Works

Run the index command to generate embeddings:

```bash
dcv index
```

You should see output similar to:

```text
Indexing contributions...
  Using provider: voyage (voyage-3.5-lite)
  Embedding 59 items...
Done. Index updated.
```

## Tips

- **RAG query** -- Embeddings power the semantic search used by the RAG query feature (Pro). After indexing, you can query your contributions using natural language.
- **Rate limits** -- Voyage AI applies rate limits per API key. dcv retries failed requests with exponential backoff automatically.
- **Dimensions** -- The default `voyage-3.5-lite` model produces 1024-dimensional vectors, providing a good balance of accuracy and storage efficiency.
