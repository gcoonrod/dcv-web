---
title: "Local Git"
description: "Configure local Git repositories as a data source for dcv"
order: 12
---

## Prerequisites

- A **local Git repository** on your machine
- **Git** installed and available on your `PATH`

## Configuration

Add a local Git source entry to the `sources` array in your `~/.config/dcv/config.json`:

```json
{
  "id": "my-project",
  "type": "local-git",
  "path": "/absolute/path/to/repo",
  "status": "active"
}
```

### Field reference

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier. Lowercase alphanumeric and hyphens, 2-64 characters. |
| `type` | Yes | Must be `"local-git"`. |
| `path` | Yes | Absolute path to the Git repository root directory. |
| `status` | Yes | `"active"` or `"inactive"`. Inactive sources are skipped during fetch. |

## Verify It Works

Run a fetch targeting this specific source:

```bash
dcv fetch --source my-project --since 2026-03-01 --until 2026-03-15
```

You should see output similar to:

```
Fetching my-project (local-git)...
  Found 23 commits
Done. 23 items saved.
```

## Tips

- **No API tokens needed** -- Local Git sources read directly from the repository on disk. No network access or authentication is required.
- **Email matching** -- Commits are attributed to you based on your `git config user.email`. Make sure this matches across all repositories you track.
- **Airgapped environments** -- This source type works entirely offline, making it ideal for airgapped or restricted networks where GitHub or other remote APIs are not available.
- **Multiple repositories** -- Create a separate source entry for each local repository you want to track.
