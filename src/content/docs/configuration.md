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
      "model": "voyage-3.5-lite",
      "default": true
    }
  ]
}
```

## Configuration Folder Structure

Developer CV stores all data and configuration in the `~/.dcv` directory:

```
~/.dcv/
├── config.json              # Main configuration file (API keys, sources, providers)
├── data.db                  # SQLite database (work artifacts, notes, embeddings)
├── templates/               # User-customizable Handlebars templates (optional)
│   ├── system.hbs          # AI persona & instructions
│   ├── analysis.hbs        # Performance review analysis prompt
│   ├── map.hbs             # Map-Reduce chunk summarization
│   ├── compare.hbs         # Report comparison prompt
│   └── query.hbs           # Interactive RAG query prompt
├── context/                 # User-supplied contextual markdown (optional)
│   ├── job_description.md  # Your role, responsibilities, expectations
│   └── career_goals.md     # Career aspirations and skill development areas
├── examples/                # Boilerplate template starters
│   ├── job_description.example.md
│   └── career_goals.example.md
├── reports/                 # Generated analysis & comparison reports
│   ├── dcv_report_*.md
│   └── dcv_compare_*.md
└── data.db-shm / data.db-wal  # SQLite write-ahead logging files
```

### Directory Details

| Directory | Purpose | Auto-Created? | User Modifies |
|-----------|---------|---|---|
| `config.json` | API tokens, data sources, LLM providers | Yes (on `dcv init`) | Yes, via `dcv init` or manual editing |
| `data.db` | SQLite database: PRs, commits, cards, notes, embeddings | Yes (on first `dcv fetch`) | No (managed by dcv) |
| `data.db-shm` / `data.db-wal` | SQLite write-ahead log and shared-memory files for `data.db` | Yes (created by SQLite when needed) | No (managed by SQLite/dcv) |
| `templates/` | Handlebars `.hbs` templates for AI prompts | Yes (on `dcv init`) | Yes, edit files in place |
| `context/` | Optional Markdown files for personalization | No | Yes, create job_description.md & career_goals.md by copying from examples/ |
| `examples/` | Reference boilerplate for context files (job_description, career_goals) | Yes (on `dcv init`) | No (reference only; copy to context/ and edit) |
| `reports/` | Output from `dcv analyze` and `dcv compare` | No | No (generated output) |

**Security**: `config.json` is automatically saved with `600` file permissions (owner read/write only). Never commit it to version control.

## Configuring the LLM Templates

### Overview

Developer CV uses [Handlebars](https://handlebarsjs.com/) templates to control how the AI analyzes your work. Templates define:

- **AI Persona** — Who the AI thinks it is (e.g., "performance review advisor" vs. "tech lead")
- **Analysis Structure** — What sections appear in reports and how data is presented
- **Prompt Engineering** — How context files (job description, career goals) are injected into the AI's instructions

If you don't customize templates, dcv uses built-in defaults that work well for most users. To customize, copy the defaults to `~/.dcv/templates/` and edit them.

### Template Reference

| Template | Used By | Purpose | Context Variables |
|----------|---------|---------|-------------------|
| `system.hbs` | All commands | Defines AI persona, tone, and high-level instructions | None (empty context) |
| `analysis.hbs` | `dcv analyze` | Main analysis prompt; structures the performance review | `github_prs`, `github_commits`, `trello_cards`, `counts`, `date_range`, `job_description`, `career_goals` |
| `map.hbs` | `dcv analyze` (Map-Reduce mode) | Summarizes individual time chunks before synthesis | Same as `analysis.hbs`, scoped to one chunk |
| `compare.hbs` | `dcv compare` | Compares two reports and identifies trajectory changes | `baseline_report`, `current_report`, `job_description`, `career_goals` |
| `query.hbs` | `dcv query` (Pro) | Interactive RAG query prompt with conversation history | `user_question`, `search_results`, `chat_history` |

### Using Templates

Templates are automatically created in `~/.dcv/templates/` when you run `dcv init`. To customize them:

**Step 1: Locate your templates:**

```bash
ls ~/.dcv/templates/
# Output: system.hbs, analysis.hbs, map.hbs, compare.hbs, query.hbs
```

**Step 2: Edit with Handlebars variables**

Templates use Handlebars syntax to inject work data:

```handlebars
{{variable}}                    {{! Output a variable }}
{{{ raw_variable }}}            {{! Output as raw HTML/Markdown (no escaping) }}
{{#if condition}}...{{/if}}     {{! Conditional block }}
{{#each array}}...{{/each}}     {{! Loop over array items }}
{{#if job_description}}
  Job context provided: {{{job_description}}}
{{/if}}
```

**Step 3: Test**

Run `dcv analyze` — it will automatically use your custom templates from `~/.dcv/templates/`. If a template has a syntax error, dcv will warn you with the file path and line number.

### Example: Emphasizing Mentorship Impact

Suppose you want analyses to focus on how your work demonstrates mentorship and team growth, not just raw code metrics.

**Step 1: Customize `system.hbs`** to emphasize this perspective:

```handlebars
You are a career development advisor helping a software engineer reflect on their 
impact on colleagues and team growth.

Often, engineering impact is measured purely by code shipped. But your role also 
involves mentoring others, unlocking team potential, and building trust.

Analyze this developer's work with a focus on:
- How they've helped teammates grow through code reviews, knowledge sharing, and pair programming
- Leadership demonstrated through unblocking others and raising team standards
- Technical judgment applied to critical decisions that influenced team trajectory
```

**Step 2: Customize `analysis.hbs`** to add a mentorship-focused section:

```handlebars
### Part 1: Accomplishments & Business Value
[... existing content ...]

### Part 2: Mentorship & Team Impact

{{#if github_prs}}
Based on PR reviews and descriptions, identify:
- Code review feedback that elevated team standards
- Mentorship of junior developers (code clarity, design patterns)
- Knowledge sharing (documentation, architectural guidance)
{{/if}}

### Part 3: Technical Guidance
[... existing content ...]
```

**Step 3: Save and test**:

```bash
# Copy job description and career goals from examples/ to context/
cp ~/.dcv/examples/job_description.example.md ~/.dcv/context/job_description.md
cp ~/.dcv/examples/career_goals.example.md ~/.dcv/context/career_goals.md

# Edit them to reflect your actual role and goals
nano ~/.dcv/context/job_description.md
nano ~/.dcv/context/career_goals.md

# Optionally, edit templates to customize AI behavior
nano ~/.dcv/templates/system.hbs
nano ~/.dcv/templates/analysis.hbs

# Run analysis — it will use your custom templates and context
dcv analyze --since 2026-01-01 --until 2026-03-31
```

The generated report will now emphasize mentorship and team impact in its analysis.

## Context Files: Job Description & Career Goals

The `~/.dcv/context/` directory holds optional Markdown files that personalize your analysis. These files are **not** work data — they're metadata about *you* that helps the AI evaluate your work against your actual role and aspirations.

### Why These Files Matter

When you run `dcv analyze`, the AI examines your PRs, commits, and cards. Without context, it produces a generic summary. **With context files**, the AI can:

- **Map accomplishments to responsibilities** — "I merged 23 feature PRs" becomes "I delivered on X, Y, Z core responsibilities from my job description"
- **Highlight progress toward goals** — "I led 5 infrastructure PRs" connects to your stated goal of "Lead IaC migration"
- **Assess growth alignment** — "Code review feedback patterns show mentorship of junior developers" aligns with your goal of "increase focus on mentorship"

### job_description.md

This file describes your **actual role**, not aspirational. It should include:

- **Job Title** — Your current position (e.g., "Senior Software Engineer", "Tech Lead")
- **Core Responsibilities** — What you're expected to do daily/weekly
- **Key Expectations** — How success is measured in your role
- **Technical Focus Areas** — Your specialization (e.g., "TypeScript/Node.js backend services")

**Example from a real user:**

```markdown
# Senior Software Engineer

## Core Responsibilities
- Design and implement features for e-commerce backend
- Provide Tier 3 support to operations and customer success
- Review pull requests and mentor team members
- Manage production release process

## Key Expectations
- Ship high-quality features with comprehensive e2e tests
- Maintain expert competency in programming, API design, SaaS security
- Convert vague tickets into well-scoped, implementable feature specifications

## Technical Focus Areas
- TypeScript/Node.js backend services
- SaaS ↔ SaaS integrations
- API design and data modeling
- Site Reliability & DevOps
```

**How it's used in analysis:**

- AI maps your work to these responsibilities: "You merged 3 feature PRs (responsibility: Design and implement features)"
- Validates breadth: "Your commits span all technical focus areas, demonstrating well-rounded expertise"

### career_goals.md

This file describes **where you're heading**, not where you are. It should include:

- **Short-Term Goals** (6–12 months) — Specific, measurable objectives (promotions, launches, migrations)
- **Long-Term Goals** (1–3 years) — Broader career trajectory or specialization
- **Skills I'm Developing** — What you're actively learning
- **How I Want to Be Perceived** — Your professional identity/reputation

**Example from a real user:**

```markdown
# Career Goals

## Short-Term Goals (6–12 months)
- Achieve a release cadence of twice a month
- Lead infrastructure-as-code migration with senior architects
- Demonstrate technical and inter-personal leadership growth

## Long-Term Goals (1–3 years)
- Transition into engineering leadership
- Engage with departmental leadership outside of engineering
- Completely replace all manual steps in our production release process

## Skills I'm Developing
- Integrating AI coding agents into team workflows
- Engineering leadership and delegation
- SaaS systems design and performance optimization

## How I Want to Be Perceived
"Seasoned developer with broad experience in backend systems design. 
Collaborative, competent, courteous, and kind."
```

**How it's used in analysis:**

- AI identifies accomplishments that demonstrate progress: "Your commits to infrastructure migrations align with your short-term goal of leading IaC migration"
- AI suggests growth areas: "No evidence of delegation in code reviews; consider pair programming sessions for leadership development"
- AI connects work to identity: "Your mentorship patterns align with your aspiration to 'increase focus on code review, design, and mentorship'"

### Setting Up Context Files

1. **Copy the examples:**

   ```bash
   cp ~/.dcv/examples/job_description.example.md ~/.dcv/context/job_description.md
   cp ~/.dcv/examples/career_goals.example.md ~/.dcv/context/career_goals.md
   ```

2. **Edit with your actual information:**

   ```bash
   nano ~/.dcv/context/job_description.md
   nano ~/.dcv/context/career_goals.md
   ```

3. **Update periodically** — When you change roles, get promoted, or shift career focus, update these files so future analyses stay accurate.

### Best Practices

- **Be honest, not aspirational** — job_description.md should reflect your actual daily responsibilities, not your dream job
- **Specific goals are better** — Instead of "Get promoted", write "Get promoted to Staff Engineer by Q4" or "Lead the payments team migration"
- **Keep it concise** — 5–10 bullet points per section is ideal; the AI reads everything but focuses better on shorter, well-organized text
- **Use your own words** — Generic role descriptions help less than specifics tailored to *your* context
- **Refresh quarterly** — After performance reviews, promotions, or major project completions, revisit these files

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
| `dcv analyze` | `--category name` | Filters report to matching artifacts only |
| `dcv query` | `--category name` | Filters vector search to matching category |

Omitting `--category` on `analyze` or `query` includes **all** categories.

See the [Context Categorization guide](#category-system) for a step-by-step walkthrough.

## Secret Management

The configuration file contains sensitive API keys. dcv automatically sets file permissions to `600` (owner read/write only) when writing the config file.

**Best practices**:

1. Never commit `config.json` to version control
2. Use environment variables in CI/CD pipelines
3. Rotate API keys periodically
4. Use token scopes minimally (e.g., GitHub tokens only need `repo` scope)

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
