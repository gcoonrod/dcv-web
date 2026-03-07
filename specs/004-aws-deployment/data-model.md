# Data Model: AWS Multi-Origin Hosting & CI/CD

**Feature**: `004-aws-deployment` | **Date**: 2026-03-07

This feature is an infrastructure and CI/CD configuration feature. The "data model" describes the infrastructure entities, their properties, and the relationships between them — not application data.

---

## Entity: Website S3 Bucket

The private object store holding the Astro static site build output.

| Property | Value |
|----------|-------|
| Contents | `index.html`, `_astro/*.css`, `_astro/*.js`, `docs/*.html`, `favicon.svg` |
| Access | CloudFront OAC only. All public access blocked. |
| Population | CI/CD pipeline on every `main` push (`aws s3 sync ./dist s3://$WEB_BUCKET --delete`) |
| Deletion | `--delete` flag removes objects absent from the current `dist/` build |
| S3 key root | Bucket root (`/`) — `dist/index.html` → `s3://bucket/index.html` |
| Encryption | S3-managed (SSE-S3) default |
| Versioning | Not enabled (CI sync is the source of truth) |

**Object structure** (after `dist/` sync):
```text
index.html
_astro/
├── *.css
└── *.js
docs/
└── *.html          (Content Collection pages, build.format: 'file')
favicon.svg
```

---

## Entity: Binary S3 Bucket

The private object store holding versioned CLI release artifacts.

| Property | Value |
|----------|-------|
| Contents | Versioned binaries, checksum files, signature files |
| Access | CloudFront OAC only. All public access blocked. |
| Population | External `publish-release.sh` script (CLI project, Phase 24) — out of scope for this feature |
| S3 key structure | `v{semver}/` prefix per release (e.g., `v3.2.1/dcv-darwin-arm64`) |
| Encryption | S3-managed (SSE-S3) default |
| Versioning | Implicit by path prefix — no S3 versioning needed |
| `Cache-Control` | `public, max-age=31536000, immutable` (set at upload time) |

**Object structure** (per release):
```text
v3.2.1/
├── dcv-darwin-arm64
├── dcv-darwin-amd64
├── dcv-linux-amd64
├── dcv-linux-arm64
├── dcv-windows-amd64.exe
├── SHA256SUMS.txt
└── SHA256SUMS.txt.sig
```

---

## Entity: CloudFront Distribution

The single CDN endpoint for `apps.microcode.io`. Routes requests to origins via ordered Behavior rules.

| Property | Value |
|----------|-------|
| Domain alias | `apps.microcode.io` |
| TLS | Required — HTTPS only. HTTP redirected to HTTPS. |
| Origins | 2: Website Bucket (OAC), Binary Bucket (OAC) |
| Default root object | Not used (sub-path routing handles index resolution) |
| Logging | CloudFront access logs recommended (pre-provisioned, out of scope) |

### Behaviors (evaluated in priority order)

| Priority | Path Pattern | Origin | Cache Policy | CloudFront Function |
|----------|-------------|--------|--------------|---------------------|
| 1 (highest) | `/dcv/releases/*` | Binary Bucket (OAC) | 1-year immutable | None |
| 2 | `/dcv/*` | Website Bucket (OAC) | 24h + invalidation on deploy | Viewer-request: index resolver |
| Default (`*`) | All other paths | (pre-existing, out of scope) | (pre-existing) | (pre-existing) |

**Behavior ordering is critical**: `/dcv/releases/*` must have higher numeric priority than `/dcv/*`. CloudFront evaluates behaviors most-specific-first; if ordering were reversed, binary requests would be incorrectly routed to the website bucket.

---

## Entity: Origin Access Control (OAC)

Two OAC configurations — one per bucket. Each restricts the respective S3 bucket to accepting GET requests only from this CloudFront distribution.

| Property | Value |
|----------|-------|
| Signing behavior | Sign requests (SigV4) |
| Signing protocol | S3 |
| Origin type | S3 |
| Scope | One OAC per bucket; OAC ARN embedded in bucket policy `Condition` |

---

## Entity: CloudFront Function — Index Resolver

A lightweight viewer-request function attached to the `/dcv/*` behavior only.

| Property | Value |
|----------|-------|
| Event type | Viewer-request |
| Attached to | `/dcv/*` behavior (website bucket) |
| Runtime | CloudFront Functions JavaScript (ES5.1) |
| Purpose | Strip `/dcv` prefix; resolve directory requests to `index.html`; resolve extensionless paths to `.html` |
| NOT attached to | `/dcv/releases/*` behavior (binaries have explicit extensions) |

**Transformation table**:

| Incoming URI | Transformed URI | S3 Object Fetched |
|---|---|---|
| `/dcv` | `/index.html` | `index.html` |
| `/dcv/` | `/index.html` | `index.html` |
| `/dcv/docs/quickstart` | `/docs/quickstart.html` | `docs/quickstart.html` |
| `/dcv/_astro/main.css` | `/_astro/main.css` | `_astro/main.css` |
| `/dcv/favicon.svg` | `/favicon.svg` | `favicon.svg` |

---

## Entity: Cache Policy — Binary (Immutable)

A named CloudFront Cache Policy for the `/dcv/releases/*` behavior.

| Property | Value |
|----------|-------|
| MinTTL | 31,536,000 seconds (1 year) |
| DefaultTTL | 31,536,000 seconds (1 year) |
| MaxTTL | 31,536,000 seconds (1 year) |
| Cache key | URI path only (no query strings, no headers) |
| Invalidation | Never required — versioned paths are write-once |

---

## Entity: Cache Policy — Website

A named CloudFront Cache Policy for the `/dcv/*` behavior.

| Property | Value |
|----------|-------|
| MinTTL | 0 seconds |
| DefaultTTL | 86,400 seconds (24 hours) |
| MaxTTL | 86,400 seconds (24 hours) |
| Cache key | URI path only |
| Invalidation | On every deployment (`/dcv/*` path) |

---

## Entity: IAM Role (OIDC Deploy Role)

The cloud identity assumed by the GitHub Actions CI pipeline during deployment.

| Property | Value |
|----------|-------|
| Trust principal | `token.actions.githubusercontent.com` (GitHub OIDC) |
| Condition | `sub` = `repo:gcoonrod/dcv-web:ref:refs/heads/main` (main branch only) |
| Permissions | `s3:PutObject`, `s3:DeleteObject`, `s3:ListBucket` on `WEB_BUCKET`; `cloudfront:CreateInvalidation` on distribution ARN |
| Permissions (NOT granted) | No access to binary bucket; no `s3:DeleteBucket`; no IAM write |
| Credential lifetime | 15 minutes (STS default); refreshed per workflow run |

---

## Entity: GitHub Actions Workflow

The CI/CD pipeline definition stored at `.github/workflows/deploy.yml`.

| Property | Value |
|----------|-------|
| Trigger | `push` to `main` branch |
| Runner | `ubuntu-latest` |
| Node.js version | 20 (matches project LTS requirement) |
| Steps | checkout → install → build → configure-aws-credentials → s3 sync → cloudfront invalidation |
| Required secrets | `AWS_ROLE_ARN`, `WEB_BUCKET`, `DISTRIBUTION_ID` |
| Required permissions | `id-token: write`, `contents: read` |

---

## Entity Relationship Diagram

```text
GitHub Actions Workflow
  │ assumes (OIDC)
  ▼
IAM Role (Deploy)
  │ writes to          │ creates invalidation on
  ▼                    ▼
Website S3 Bucket    CloudFront Distribution
  │                    │  behaviors (ordered):
  │ ◄── OAC ─────────┤  1. /dcv/releases/* → Binary S3 Bucket (OAC)
  │                   │  2. /dcv/*          → Website S3 Bucket (OAC) + CF Function
  │                   │
  └───────────────────┘
                       │
Binary S3 Bucket ──────┘
  (populated by CLI publish-release.sh, out of scope)
```
