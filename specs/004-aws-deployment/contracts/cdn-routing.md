# Contract: CloudFront CDN Routing

**Feature**: `004-aws-deployment` | **Date**: 2026-03-07

This contract defines the expected request routing behavior of the CloudFront distribution for `apps.microcode.io`. It specifies how each URL path prefix maps to an origin, what cache policies apply, and what response headers and status codes a client should expect.

---

## Origin Definitions

| Origin ID | Type | Source | Access Control |
|-----------|------|--------|----------------|
| `WebsiteBucketOrigin` | S3 (REST endpoint) | Website S3 bucket | OAC (SigV4 signed requests) |
| `BinaryBucketOrigin` | S3 (REST endpoint) | Binary S3 bucket | OAC (SigV4 signed requests) |

Both origins use S3 REST API endpoints (not static website endpoints). Public access is blocked on both buckets.

---

## Behavior Routing Contract

Behaviors are evaluated in **priority order** (lower number = evaluated first). CloudFront matches the first behavior whose path pattern applies — it does not automatically prefer the most specific pattern.

> **Important**: CloudFront path pattern `/dcv/*` does **not** match the bare path `/dcv`. A dedicated behavior for the exact path `/dcv` (Priority 3) is required to serve the homepage when users navigate to the root without a trailing slash.

### Behavior 1 — Binary Distribution (Priority: 1, highest)

| Property | Value |
|----------|-------|
| Path pattern | `/dcv/releases/*` |
| Origin | `BinaryBucketOrigin` |
| Cache policy | Custom: 1-year immutable (MinTTL=MaxTTL=DefaultTTL=31536000s) |
| CloudFront Function | None |
| Allowed HTTP methods | `GET`, `HEAD` |
| HTTPS | Required (redirect HTTP → HTTPS) |
| Compress objects | Yes |

**Routing examples**:

| Request | Origin key fetched | Expected response |
|---------|-------------------|-------------------|
| `GET /dcv/releases/v3.2.1/dcv-darwin-arm64` | `v3.2.1/dcv-darwin-arm64` | `200 OK`, binary content |
| `GET /dcv/releases/v3.2.1/SHA256SUMS.txt` | `v3.2.1/SHA256SUMS.txt` | `200 OK`, text content |
| `GET /dcv/releases/v9.9.9/dcv-linux-amd64` (missing) | `v9.9.9/dcv-linux-amd64` | `404 NoSuchKey` (from S3) |

**Cache behavior**: After the first request at an edge location, subsequent requests for the same URI are served from cache for up to 1 year. `X-Cache: Hit from cloudfront` header present on cached responses.

---

### Behavior 2 — Website (Priority: 2)

| Property | Value |
|----------|-------|
| Path pattern | `/dcv/*` |
| Origin | `WebsiteBucketOrigin` |
| Cache policy | Custom: 24h website (DefaultTTL=86400s) |
| CloudFront Function | Viewer-request: Index Resolver |
| Allowed HTTP methods | `GET`, `HEAD` |
| HTTPS | Required (redirect HTTP → HTTPS) |
| Compress objects | Yes |

**URL resolution** (after CloudFront Function transformation):

| Incoming request URI | Transformed URI | S3 object | Expected response |
|---------------------|-----------------|-----------|-------------------|
| `/dcv` | `/index.html` | `index.html` | `200 OK`, HTML (matched by the `/dcv` exact-path behavior, Priority 3) |
| `/dcv/` | `/index.html` | `index.html` | `200 OK`, HTML |
| `/dcv/docs/quickstart` | `/docs/quickstart.html` | `docs/quickstart.html` | `200 OK`, HTML |
| `/dcv/_astro/main.css` | `/_astro/main.css` | `_astro/main.css` | `200 OK`, CSS |
| `/dcv/favicon.svg` | `/favicon.svg` | `favicon.svg` | `200 OK`, SVG |
| `/dcv/nonexistent` | `/nonexistent.html` | (missing) | `404 NoSuchKey` (from S3 via CloudFront; `403 AccessDenied` indicates misconfiguration) |

**Cache invalidation**: On every deployment, the pipeline issues:
```
aws cloudfront create-invalidation --paths "/dcv/*"
```
This invalidation MUST cover only the `/dcv/*` prefix and MUST NOT include `/dcv/releases/*` (binary objects are immutable and never require invalidation).

---

### Default Behavior (Priority: lowest, catch-all)

| Property | Value |
|----------|-------|
| Path pattern | `*` (default) |
| Scope | Pre-existing; may route to other application origins |
| Governed by | Pre-existing infrastructure configuration — out of scope for this feature |

**IMPORTANT**: This feature MUST NOT modify the default behavior. Any modifications risk breaking other applications on the shared distribution.

---

## HTTP Response Guarantees

| Scenario | Expected Status | Notes |
|----------|-----------------|-------|
| Valid page request (`/dcv/`) | `200 OK` | Served by website bucket via CF Function |
| Valid binary request | `200 OK` | Served by binary bucket |
| Missing binary version | `404 Not Found` (expected) or `403 AccessDenied` (misconfiguration) | S3 normally returns `404 NoSuchKey` for missing keys; a `403 AccessDenied` indicates an OAC/bucket policy issue and MUST be investigated |
| Direct S3 URL request (bypassing CDN) | `403 AccessDenied` | OAC bucket policy blocks all non-CF requests |
| HTTP request to any `/dcv/*` path | `301 Moved Permanently` | CloudFront HTTPS redirect policy |

---

## Invariants

1. `/dcv/releases/*` requests MUST NEVER be routed to the website bucket.
2. `/dcv/*` requests (excluding the releases sub-path) MUST NEVER be routed to the binary bucket.
3. Cache invalidations MUST NEVER include the `/dcv/releases/*` path.
4. Both S3 buckets MUST reject all requests not originating from the CloudFront distribution (validated by OAC bucket policy).
5. TLS 1.2+ MUST be enforced on the distribution viewer protocol; SSLv3 and TLS 1.0/1.1 are prohibited.
