---
title: "Configuration"
description: "Configure dcv with ~/.dcv/config.json."
order: 3
---

# Configuration

Developer CV (dcv) uses a JSON configuration file at `~/.dcv/config.json` to manage data sources, LLM providers, and categorization settings.

## Quick Start

Run the interactive configuration wizard:

```bash
dcv init
```

This guides you through setting up:
- Code repositories (GitHub, GitLab, Azure Repos, Bitbucket)
- Project tracking (Trello, Jira, Linear, Asana)
- LLM providers (Anthropic)
- Vector embedding providers (Voyage AI)

## Configuration File Structure

The configuration file uses schema version 2, which introduces multi-source support and category-based organization.

```json
{
  "schema_version": 2,
  "sources": [
    {
      "id": "github-work",
      "type": "github",
      "status": "active",
      "token": "ghp_xxxx",
      "username": "your-username",
      "repos": ["org/repo"],
      "category": "professional"
    },
    {
      "id": "github-personal",
      "type": "github",
      "status": "active",
      "token": "ghp_yyyy",
      "username": "your-username",
      "repos": ["personal/side-project"],
      "category": "personal"
    }
  ],
  "providers": [
    {
      "id": "claude",
      "type": "anthropic",
      "role": "analysis",
      "apiKey": "sk-ant-xxxx",
      "model": "claude-opus-4-6",
      "default": true
    },
    {
      "id": "voyage",
      "type": "voyage",
      "role": "embeddings",
      "apiKey": "pa-xxxx",
      "default": true
    }
  ]
}
```

## Category System

Categories allow you to segregate work contexts (e.g., professional work vs. personal projects) within a single database.

### Category Configuration

Every data source accepts an optional `category` field:

```json
{
  "schema_version": 2,
  "sources": [
    {
      "id": "github-work",
      "type": "github",
      "status": "active",
      "category": "professional"
    },
    {
      "id": "trello-side-project",
      "type": "trello",
      "status": "active",
      "category": "personal"
    }
  ],
  "providers": []
}
```

**Default Behavior**: If `category` is omitted, the system defaults to `"professional"`.

### Category Naming Rules

Category names must:
- Use only lowercase letters, numbers, and hyphens
- Be 1–32 characters long
- Not use reserved keywords: `all`, `none`, `any`, `where`

**Valid examples**: `professional`, `personal`, `open-source`, `work-2024`

**Invalid examples**: `Professional` (uppercase), `work project` (space), `personal_projects` (underscore), `all` (reserved)

### Using Categories

Categories are applied at multiple levels:

| Command | Flag | Effect |
|---------|------|--------|
| `dcv fetch` | (automatic) | Artifacts inherit category from their source |
| `dcv journal` | `--category name` or `--personal` | Tags the journal entry with a category |
| `dcv analyze` | `--category name` | Filters report to matching artifacts only |
| `dcv query` | `--category name` | Filters vector search to matching category |

Omitting `--category` on `analyze` or `query` includes **all** categories.

See the [Context Categorization guide](/dcv/docs/categorization) for a step-by-step walkthrough.

## Data Sources

### GitHub

```json
{
  "id": "github-work",
  "type": "github",
  "status": "active",
  "token": "ghp_xxxxxxxxxxxx",
  "username": "your-username",
  "repos": ["org/repo", "org/another-repo"],
  "category": "professional"
}
```

**Required Fields**:
- `id`: Unique identifier for this source (lowercase alphanumeric with hyphens)
- `type`: Must be `"github"`
- `status`: `"active"`, `"planned"`, or `"unconfigured"`
- `token`: GitHub personal access token (needs `repo` scope)
- `username`: Your GitHub username (for filtering commits)
- `repos`: List of repositories in `owner/repo` format

**Optional Fields**:
- `category`: Category for work context segregation (default: `"professional"`)

### GitHub Enterprise

Same as GitHub, but add a `custom_domain` field:

```json
{
  "id": "github-enterprise",
  "type": "github_enterprise",
  "status": "active",
  "custom_domain": "https://github.company.com",
  "token": "ghp_xxxx",
  "username": "your-username",
  "repos": ["org/repo"],
  "category": "professional"
}
```

### Local Git Repositories

```json
{
  "id": "local-work",
  "type": "local-git",
  "status": "active",
  "path": "/Users/you/work/project",
  "category": "professional"
}
```

Use `dcv fetch --source local-git --path /path/to/repo --since DATE --until DATE` to fetch from local repositories.

### Trello

```json
{
  "id": "trello-work",
  "type": "trello",
  "status": "active",
  "apiKey": "your-api-key",
  "token": "your-token",
  "boardIds": ["board-id-123"],
  "doneListNames": ["Done"],
  "category": "professional"
}
```

### Bitbucket `(Pro)`

```json
{
  "id": "bitbucket-work",
  "type": "bitbucket",
  "status": "active",
  "token": "app-password",
  "username": "your-username",
  "workspace": "workspace-slug",
  "repos": ["repo-name"],
  "category": "professional"
}
```

### Jira `(Pro)`

```json
{
  "id": "jira-work",
  "type": "jira",
  "status": "active",
  "custom_domain": "https://company.atlassian.net",
  "email": "you@company.com",
  "token": "your-api-token",
  "category": "professional"
}
```

### Linear `(Pro)`

```json
{
  "id": "linear-work",
  "type": "linear",
  "status": "active",
  "token": "lin_api_xxxxxxxxxxxx",
  "category": "professional"
}
```

### Asana `(Pro)`

```json
{
  "id": "asana-work",
  "type": "asana",
  "status": "active",
  "token": "your-personal-access-token",
  "workspace": "1234567890",
  "category": "professional"
}
```

### GitLab `(Pro)` `(Coming Soon)`

```json
{
  "id": "gitlab-work",
  "type": "gitlab",
  "status": "active",
  "token": "glpat-xxxxxxxxxxxx",
  "username": "your-username",
  "repos": ["group/project"],
  "category": "professional"
}
```

> **Coming Soon**: GitLab integration is planned but not yet implemented. Configuration shown above is for future reference.

### Azure DevOps `(Pro)` `(Coming Soon)`

```json
{
  "id": "azure-work",
  "type": "azure_repos",
  "status": "active",
  "token": "your-pat-token",
  "username": "your-email@company.com",
  "organization": "your-org",
  "project": "ProjectName",
  "repos": ["repo-name"],
  "category": "professional"
}
```

> **Coming Soon**: Azure DevOps integration is planned but not yet implemented. Configuration shown above is for future reference.

## LLM Providers

### Anthropic

```json
{
  "id": "claude",
  "type": "anthropic",
  "role": "analysis",
  "apiKey": "sk-ant-xxxxxxxxxxxx",
  "model": "claude-opus-4-6",
  "default": true
}
```

**Available Models**:
- `claude-opus-4-6` — most capable, recommended for analysis
- `claude-sonnet-4-6` — balanced performance and cost
- `claude-haiku-4-5` — fastest, most economical

> **OpenAI** `(Coming Soon)`: OpenAI provider support is planned but not yet implemented.

## Embedding Providers

### Voyage AI

```json
{
  "id": "voyage",
  "type": "voyage",
  "role": "embeddings",
  "apiKey": "pa-xxxxxxxxxxxx",
  "default": true
}
```

Required for RAG features (`dcv query`, `dcv index`). Without Voyage AI configured, `dcv query` and `dcv index` are unavailable.

## Environment Variables

You can override configuration values using environment variables:

```bash
export DCV_GITHUB_TOKEN="ghp_xxxx"
export DCV_TRELLO_API_KEY="your-key"
export DCV_TRELLO_TOKEN="your-token"
export DCV_ANTHROPIC_API_KEY="sk-ant-xxxx"
export DCV_VOYAGE_API_KEY="pa-xxxx"
export DCV_CONFIG_DIR="/custom/path/.dcv"
```

Environment variables take precedence over configuration file values.

## Secret Management

The configuration file contains sensitive API keys. dcv automatically sets file permissions to `600` (owner read/write only) when writing the config file.

**Best practices**:
1. Never commit `config.json` to version control
2. Use environment variables in CI/CD pipelines
3. Rotate API keys periodically
4. Use token scopes minimally (e.g., GitHub tokens only need `repo` scope)

## Migration from V1 to V2

If you have an existing V1 configuration, run `dcv init` to migrate. The wizard will:
1. Detect your V1 config
2. Prompt for confirmation
3. Back up your old config to `config.json.v1.bak`
4. Migrate sources to the new multi-source format
5. Add default categories (`"professional"`) to all sources

**Manual migration example:**

V1 format:

```json
{
  "github": {
    "token": "ghp_xxxx",
    "username": "you",
    "repos": ["org/repo"]
  }
}
```

V2 format:

```json
{
  "schema_version": 2,
  "sources": [
    {
      "id": "github-main",
      "type": "github",
      "status": "active",
      "token": "ghp_xxxx",
      "username": "you",
      "repos": ["org/repo"],
      "category": "professional"
    }
  ],
  "providers": []
}
```

## Troubleshooting

### Invalid Category Error

```
Error: Invalid category - Category must be lowercase alphanumeric with hyphens
```

**Solution**: Use only lowercase letters, numbers, and hyphens. Change `Work-Project` to `work-project`.

### Reserved Category Keyword

```
Error: Invalid category - Category 'all' is reserved
```

**Solution**: Choose a different category name. Reserved keywords: `all`, `none`, `any`, `where`.

### Config File Permissions

If you see permission warnings, run:

```bash
chmod 600 ~/.dcv/config.json
```
