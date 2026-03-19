---
title: "GitHub"
description: "Configure GitHub as a data source for dcv"
order: 10
---

## Prerequisites

- A **GitHub personal access token** (classic or fine-grained)
  - `repo` scope for private repositories
  - `public_repo` scope if you only need public repositories
- Your **GitHub username**

You can generate a token at [github.com/settings/tokens](https://github.com/settings/tokens).

## Configuration

Add a GitHub source entry to the `sources` array in your `~/.config/dcv/config.json`:

```json
{
  "id": "github-work",
  "type": "github",
  "token": "ghp_xxxxxxxxxxxx",
  "username": "your-username",
  "repos": ["owner/repo-name"],
  "category": "professional",
  "status": "active"
}
```

### Field reference

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier. Lowercase alphanumeric and hyphens, 2-64 characters. |
| `type` | Yes | Must be `"github"`. |
| `token` | Yes | GitHub personal access token. Can also be set via the `DCV_GITHUB_TOKEN` environment variable. |
| `username` | Yes | Your GitHub username. Used to filter PRs and commits to your contributions. |
| `repos` | Yes | Array of repositories in `owner/repo-name` format. |
| `category` | No | Defaults to `"professional"`. Used for contribution categorization. |
| `status` | Yes | `"active"` or `"inactive"`. Inactive sources are skipped during fetch. |

## Verify It Works

Run a fetch command with a date range:

```bash
dcv fetch --since 2026-03-01 --until 2026-03-15
```

You should see output similar to:

```
Fetching github-work (github)...
  Found 12 PRs, 47 commits
Done. 59 items saved.
```

## Tips

- **Private vs public repos** -- If your token only has the `public_repo` scope, private repositories will return zero results without an error. Use the `repo` scope to include private repositories.
- **Multi-org setups** -- Create a separate source entry for each organization. Each entry can use the same token if it has access to all orgs.
- **PR filtering** -- Pull requests are filtered client-side by matching `user.login` against your configured `username`. Only PRs you authored are included.
- **Rate limiting** -- GitHub allows 5,000 authenticated requests per hour. Large repositories with many PRs may consume more quota. dcv respects rate limit headers and will pause automatically if needed.
