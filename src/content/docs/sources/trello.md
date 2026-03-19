---
title: "Trello"
description: "Configure Trello as a data source for dcv"
order: 11
---

## Prerequisites

- A **Trello API key** from the [Trello Developer Portal](https://developer.atlassian.com/cloud/trello/)
- A **Trello token** generated via OAuth authorization
- One or more **board IDs** you want to track

## Configuration

Add a Trello source entry to the `sources` array in your `~/.config/dcv/config.json`:

```json
{
  "id": "trello-work",
  "type": "trello",
  "apiKey": "your-api-key",
  "token": "your-token",
  "boardIds": ["board-id-1"],
  "doneListNames": ["Done", "Completed"],
  "category": "professional",
  "status": "active"
}
```

### Field reference

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier. Lowercase alphanumeric and hyphens, 2-64 characters. |
| `type` | Yes | Must be `"trello"`. |
| `apiKey` | Yes | Trello API key. Can also be set via the `DCV_TRELLO_API_KEY` environment variable. |
| `token` | Yes | Trello OAuth token. Can also be set via the `DCV_TRELLO_TOKEN` environment variable. |
| `boardIds` | Yes | Array of Trello board IDs to fetch cards from. |
| `doneListNames` | No | List names that indicate completed work. Default: `["Done", "Completed"]`. Supports `*` wildcard and is case-insensitive. |
| `category` | No | Defaults to `"professional"`. Used for contribution categorization. |
| `status` | Yes | `"active"` or `"inactive"`. Inactive sources are skipped during fetch. |

## Verify It Works

Run a fetch command:

```bash
dcv fetch --since 2026-03-01 --until 2026-03-15
```

You should see output similar to:

```
Fetching trello-work (trello)...
  Found 8 cards
Done. 8 items saved.
```

## Tips

- **Finding board IDs** -- The board ID is in the Trello URL: `trello.com/b/{boardId}/board-name`. Copy the alphanumeric string after `/b/`.
- **Wildcard patterns** -- Use `*` in `doneListNames` to match partial list names. For example, `"Complete *"` matches "Complete Sprint 1", "Complete Sprint 2", etc.
- **Member ID** -- Your Trello member ID is resolved automatically via the `/members/me` endpoint using your token. You do not need to configure it manually.
- **Multiple boards** -- Add all relevant board IDs to a single source entry. There is no need to create separate entries per board unless you want different categories.
