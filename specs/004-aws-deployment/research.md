# Research: AWS Multi-Origin Hosting & CI/CD

**Feature**: `004-aws-deployment` | **Date**: 2026-03-07

---

## Decision 1: Astro Sub-Path Configuration

**Decision**: Use `base: '/dcv'` + `build: { format: 'file' }` in `astro.config.mjs`.

**Rationale**:
- `base: '/dcv'` instructs Astro to prefix all generated asset references (`/dcv/_astro/...`) and internal `href` values, making them production-correct for sub-path CDN hosting without requiring path rewriting at the CDN layer for assets.
- `build.format: 'file'` emits flat `.html` files (e.g., `docs/quickstart.html`) instead of directory-scoped `index.html` files (e.g., `docs/quickstart/index.html`). This eliminates the need for the CloudFront Function to handle nested directory-index rewrites — only the root `/dcv/` case and extensionless paths need normalization.
- The `output: 'static'` directive (required by Constitution Principle I) is unchanged and fully compatible with both options.

**Key behavior**:

| Page | `format: 'directory'` (default) | `format: 'file'` (chosen) |
|------|----------------------------------|----------------------------|
| `src/pages/index.astro` | `dist/index.html` | `dist/index.html` |
| `src/pages/docs/[slug].astro` | `dist/docs/quickstart/index.html` | `dist/docs/quickstart.html` |

**Alternatives considered**:
- `format: 'directory'` (default): Requires the CloudFront Function to rewrite every nested directory path (e.g., `/dcv/docs/quickstart/` → `/docs/quickstart/index.html`). More complex function logic.
- S3 static website endpoint: Auto-appends `index.html` for directory requests natively, but is incompatible with Origin Access Control (OAC). Eliminated by the security clarification (FR-011).

---

## Decision 2: Directory URL Resolution (CloudFront Function)

**Decision**: Deploy a minimal CloudFront Function (viewer-request event) on the `/dcv/*` behavior to handle `index.html` resolution.

**Rationale**: S3 accessed via its REST API endpoint (required for OAC) does not serve `index.html` for directory-style requests — it returns `403 AccessDenied`. This is a well-documented limitation with no workaround on the S3/CloudFront side without a function. The function is minimal (< 15 lines) and has negligible overhead: CloudFront Functions execute in microseconds at edge, with no cold-start penalty.

**Function logic**:
```javascript
// CloudFront Function — Viewer Request
// Attached to the /dcv/* behavior (website origin only)
function handler(event) {
  var uri = event.request.uri;

  // Strip /dcv prefix; forward bare path to S3 bucket root
  var path = uri.replace(/^\/dcv/, '') || '/';

  // Trailing slash → index.html
  if (path.endsWith('/')) {
    path = path + 'index.html';
  }
  // Extensionless path → append .html (build.format: 'file' convention)
  else if (!path.split('/').pop().includes('.')) {
    path = path + '.html';
  }

  event.request.uri = path;
  return event.request;
}
```

**S3 key mapping examples** (with `dist/` synced to bucket root):

| Request URL | CF Function rewrites to | S3 key fetched |
|-------------|------------------------|----------------|
| `/dcv/` | `/index.html` | `index.html` |
| `/dcv` | `/index.html` | `index.html` |
| `/dcv/docs/quickstart` | `/docs/quickstart.html` | `docs/quickstart.html` |
| `/dcv/_astro/main.css` | `/_astro/main.css` | `_astro/main.css` |

**Why this does NOT apply to the binary behavior**: The `/dcv/releases/*` behavior routes to the binary bucket, where all files have explicit extensions (e.g., `dcv-darwin-arm64`, `SHA256SUMS.txt`, `.sig`). No CloudFront Function is needed on that behavior.

**Alternatives considered**:
- S3 static website endpoint: Eliminated — incompatible with OAC (see Decision 1).
- Sync to `s3://WEB_BUCKET/dcv/` subfolder: Eliminates need to strip prefix in CF Function, but complicates the sync command (requires path prefix in `aws s3 sync`), and creates a naming mismatch between the spec's FR-003 (`sync ./dist s3://<WEB_BUCKET>`) and the actual bucket layout. Rejected for spec alignment.
- `format: 'preserve'` in Astro: Mirrors source file structure exactly, does not help with the index document problem.

---

## Decision 3: S3 Origin Access Control (OAC)

**Decision**: Use **Origin Access Control (OAC)** to restrict S3 bucket access to the CloudFront distribution. Both buckets use S3-managed signing (SigV4).

**Rationale**: OAC is AWS's current recommended mechanism for CloudFront → S3 authentication. Key advantages over the legacy Origin Access Identity (OAI):
- Supports SSE-KMS encrypted buckets (future-proofing).
- Supports cross-region bucket access.
- Uses SigV4 signing with automatic key rotation (no manual credential rotation).
- Compatible with all S3 APIs, including `PUT` object metadata manipulation.

**Required bucket policy pattern** (applied to each bucket):
```json
{
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "cloudfront.amazonaws.com" },
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::<BUCKET_NAME>/*",
    "Condition": {
      "StringEquals": {
        "AWS:SourceArn": "arn:aws:cloudfront::<ACCOUNT_ID>:distribution/<DISTRIBUTION_ID>"
      }
    }
  }]
}
```

**Bucket public access**: All four S3 "Block Public Access" settings MUST be enabled on both buckets. Direct S3 URL requests return `403 Access Denied`.

**Alternatives considered**:
- OAI (Origin Access Identity): Legacy; AWS no longer recommends for new distributions. Lacks SSE-KMS support and cross-account capabilities.
- Public bucket + CDN caching: Eliminated — bucket objects are publicly enumerable and downloadable directly, bypassing CloudFront. Unacceptable for a security-focused CLI tool distribution channel.

---

## Decision 4: GitHub Actions OIDC Authentication

**Decision**: Use GitHub Actions' native OIDC integration to assume an AWS IAM role with short-lived STS credentials. No long-lived access keys stored in GitHub Secrets.

**How it works**:
1. GitHub Actions generates a signed OIDC token for the running workflow.
2. The workflow calls `aws sts assume-role-with-web-identity` (abstracted by `aws-actions/configure-aws-credentials@v4`).
3. AWS IAM validates the token against the GitHub OIDC provider (`https://token.actions.githubusercontent.com`).
4. AWS returns a temporary credential set (15 min duration by default, extendable to session max).

**Required AWS-side setup** (one-time, pre-provisioned):
- IAM Identity Provider for `token.actions.githubusercontent.com` (type: OpenID Connect)
- IAM Role with trust policy scoped to the specific GitHub org/repo and `main` branch:
```json
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:sub": "repo:gcoonrod/dcv-web:ref:refs/heads/main",
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    }
  }
}
```
- IAM Policy attached to the role: `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`, `s3:ListBucket` on `WEB_BUCKET`; `cloudfront:CreateInvalidation` on the specific distribution ARN.

**GitHub Actions workflow permissions required**:
```yaml
permissions:
  id-token: write   # Required for OIDC token request
  contents: read    # Required for checkout
```

**Required GitHub Secrets** (configuration values, not credentials):
- `AWS_ROLE_ARN`: ARN of the IAM role to assume
- `WEB_BUCKET`: Name of the website S3 bucket
- `DISTRIBUTION_ID`: CloudFront distribution ID

**Alternatives considered**:
- Long-lived IAM access keys stored as GitHub Secrets: Eliminated by FR-003 and SC-006 — keys require manual rotation, are a standing credential theft risk, and cannot be scoped to a specific branch.
- GitHub Environment with required reviewers: Not sufficient alone — still needs authentication mechanism.

---

## Decision 5: Binary Cache Policy (1-Year Immutable TTL)

**Decision**: Create a CloudFront Cache Policy for the `/dcv/releases/*` behavior with `max-age=31536000` (1 year) and set `Cache-Control: public, max-age=31536000, immutable` on uploaded binary objects.

**Rationale**: Release binaries are identified by semantic version in their URL path (e.g., `/dcv/releases/v3.2.1/dcv-darwin-arm64`). A given version path is write-once — once published, the object at that path is never modified or deleted. This makes them safe for maximum CDN caching:
- First download: CDN edge fetches from S3 origin (one-time cost per edge location).
- All subsequent downloads: Served directly from CDN edge cache. No origin requests, no egress cost beyond the first.
- No invalidation ever needed for binary objects (new version = new path).

**CloudFront Cache Policy settings**:
```
MinTTL:     31536000  (1 year)
DefaultTTL: 31536000  (1 year)
MaxTTL:     31536000  (1 year)
```

**Object-level `Cache-Control` header** (set during `aws s3 sync` of binary artifacts):
```
Cache-Control: public, max-age=31536000, immutable
```

The `immutable` directive signals to intermediate caches (browser, ISP) that the content will not change for the max-age duration, preventing conditional GET requests.

**For the website behavior** (`/dcv/*`): Use CloudFront's managed `CachingDisabled` policy or a short TTL (e.g., 24h), relying on explicit CloudFront invalidations (`/dcv/*`) on each deployment to refresh content. The pipeline already executes this invalidation (FR-005).

**Alternatives considered**:
- Short TTL for binaries (1h): Unnecessary origin round-trips for immutable objects. Wastes S3 GET request budget.
- No `immutable` directive: Browsers and intermediate caches will issue conditional requests (If-None-Match) even within max-age. `immutable` eliminates this overhead.
- Per-binary invalidation on release: Unnecessary and redundant — new releases use new version paths, so old cached paths are never wrong.
