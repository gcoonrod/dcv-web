# Contributor Guide: Adding or Updating a Docs Page

**Feature**: `001-update-docs` | **Date**: 2026-03-14

This guide explains how to add a new docs page or update an existing one in the `dcv-web` project.

## Adding a New Docs Page

1. Create a new `.md` file in `src/content/docs/`:

   ```bash
   touch src/content/docs/my-new-page.md
   ```

2. Add the required frontmatter:

   ```yaml
   ---
   title: "My New Page"
   description: "One sentence describing this page."
   order: 6
   ---
   ```

   - `title`: Shown in `<title>` tag and `<h1>` — must match your first heading
   - `description`: Used for SEO meta and sidebar subtitle
   - `order`: Integer controlling sidebar position; must be unique; shift other pages if inserting

3. Write your Markdown content below the frontmatter.

4. If inserting between existing pages (e.g., adding order: 4 between 3 and 4), update the displaced page's `order` value:

   ```yaml
   # changelog.md — was order: 4, now order: 5
   order: 5
   ```

5. Run `npm run build` to confirm Zod schema validation passes.

6. Run `npm run preview` to verify the page appears in the sidebar nav at the correct position.

## Updating Existing Content

Edit the Markdown file directly. Frontmatter changes (title, description, order) take effect on next build. Content changes (headings, code blocks, paragraphs) are rendered via `@tailwindcss/typography` `prose prose-invert` classes — standard Markdown formatting is all you need.

## Code Block Conventions

- Use fenced code blocks with language identifiers: ` ```bash `, ` ```json `, ` ```text `
- Shell commands are styled with `bash`; config file examples use `json`; terminal output uses `text`

## Routing

Pages are automatically routed to `/dcv/docs/{slug}` where `{slug}` is the filename without `.md`. No routing config required.

## No JS Required

Docs pages are statically rendered. Do not add `<script>` tags or interactive components to docs content files.
