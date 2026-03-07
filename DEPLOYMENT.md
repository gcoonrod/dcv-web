# Deployment Architecture

This document describes how `apps.microcode.io/dcv` is hosted and deployed. It covers the dual-origin CloudFront routing model, S3 bucket layout, CI/CD pipeline, and operational procedures.

---

## Overview

The DCV website and CLI release binaries are served from a **single CloudFront distribution** for `apps.microcode.io`. Path-based routing (CloudFront Behaviors) directs traffic to one of two private S3 origins depending on the URL prefix. No load balancer, reverse proxy, or compute instance is involved — all routing is handled natively by CloudFront.

```text
                        apps.microcode.io
                               │
                    ┌──────────┴──────────┐
                    │  CloudFront Dist.   │
                    │                     │
              Behavior 1            Behavior 2
           /dcv/releases/*           /dcv/*
           (Priority 1 — wins)    (Priority 2)
                    │                     │
                    ▼                     ▼
            Binary S3 Bucket      Website S3 Bucket
         (CLI release artifacts)  (Astro static site)
              OAC (private)           OAC (private)

GitHub Actions Workflow
  │ assumes (OIDC — no long-lived keys)
  ▼
IAM Deploy Role
  │ syncs dist/ to           │ invalidates
  ▼                           ▼
Website S3 Bucket      CloudFront /dcv/*
```

---

## CloudFront Behaviors (Routing Rules)

Behaviors are evaluated in priority order. **More specific paths take priority.**

| Priority    | Path Pattern      | Origin            | Cache Policy               | CloudFront Function                  |
|-------------|-------------------|-------------------|----------------------------|--------------------------------------|
| 1 (highest) | `/dcv/releases/*` | Binary S3 Bucket  | 1 year (immutable)         | None                                 |
| 2           | `/dcv/*`          | Website S3 Bucket | 24 hours + invalidation    | `dcv-index-resolver` (viewer-request)|
| Default     | `*`               | Pre-existing      | Pre-existing               | Pre-existing                         |

**Critical**: The `/dcv/releases/*` behavior MUST have a lower priority number than `/dcv/*`. If they are swapped, binary download requests will be served by the website bucket (returning HTML instead of binaries).

---

## S3 Bucket Layout

### Website Bucket

Populated by the CI/CD pipeline on every push to `main`. Contains the output of `npm run build`.

```text
index.html                      ← Main page (served at /dcv/)
_astro/
├── *.css                       ← Hashed CSS bundles
└── *.js                        ← Hashed JS bundles
docs/
├── quickstart.html             ← /dcv/docs/quickstart
├── installation.html           ← /dcv/docs/installation
├── configuration.html          ← /dcv/docs/configuration
└── changelog.html              ← /dcv/docs/changelog
favicon.svg
```

All files are stored at the **bucket root** (not under a `/dcv/` subfolder). The CloudFront Function strips the `/dcv` URL prefix before forwarding to S3.

### Binary Bucket

Populated by the CLI project's `publish-release.sh` script (external, not this CI pipeline). Contains versioned release artifacts.

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

Each version is stored under a `v{semver}/` prefix. Paths are write-once — a given version is never overwritten, which enables the 1-year immutable CDN cache.

---

## Origin Access Control (OAC)

Both S3 buckets have **all public access blocked**. The only entity that can read objects is the CloudFront distribution, authenticated via Origin Access Control (OAC) using SigV4 signed requests.

Direct S3 URLs (e.g., `https://s3.amazonaws.com/<bucket>/index.html`) return `403 AccessDenied`.

---

## CloudFront Function: `dcv-index-resolver`

Attached to the `/dcv/*` behavior at the **viewer-request** event. Handles path normalizations required because the S3 REST endpoint (used with OAC) cannot auto-serve `index.html` for directory requests:

1. Strips the `/dcv` prefix so `dist/` files (stored at bucket root) are found correctly.
2. Rewrites directory requests (e.g., `/dcv/`) to `/index.html`.
3. Rewrites extensionless paths (e.g., `/dcv/docs/quickstart`) to `.html` (matching `build.format: 'file'` output).

This function is **not** attached to the `/dcv/releases/*` behavior — binary files have explicit extensions.

---

## CI/CD Pipeline

**File**: `.github/workflows/deploy.yml`
**Trigger**: Push to `main` branch only.
**Authentication**: GitHub Actions OIDC → AWS IAM role assumption. No long-lived access keys are stored anywhere.

### Pipeline Steps

| Step | Action                                                   |
|------|----------------------------------------------------------|
| 1    | Checkout repository                                      |
| 2    | Set up Node.js 20                                        |
| 3    | `npm ci` (install dependencies)                          |
| 4    | `npm run build` (produce `dist/`)                        |
| 5    | Assume AWS IAM role via OIDC                             |
| 6    | `aws s3 sync ./dist s3://$WEB_BUCKET --delete`           |
| 7    | `aws cloudfront create-invalidation --paths "/dcv/*"`    |

**Invariants** (always true on a valid run):

- Only `./dist` is synced — no other directories touch S3
- Invalidation path is exactly `/dcv/*` — never `/*` (which would purge other apps on the same distribution)
- Credentials are short-lived OIDC tokens — no `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` ever stored

---

## Required GitHub Configuration

### Secrets (Settings → Secrets and variables → Secrets)

| Secret            | Description                               |
|-------------------|-------------------------------------------|
| `AWS_ROLE_ARN`    | ARN of the IAM role to assume via OIDC    |
| `WEB_BUCKET`      | Name of the website S3 bucket             |
| `DISTRIBUTION_ID` | CloudFront distribution ID                |

### Variables (Settings → Secrets and variables → Variables)

| Variable     | Description                                          | Example       |
|--------------|------------------------------------------------------|---------------|
| `AWS_REGION` | AWS region where the website S3 bucket resides       | `us-east-1`   |

---

## Triggering a Manual Deployment

The pipeline runs automatically on push to `main`. To trigger a redeployment without a code change:

```bash
git commit --allow-empty -m "chore: trigger redeploy"
git push origin main
```

Alternatively, use the GitHub Actions "Re-run all jobs" button on any previous successful workflow run.

---

## Rotating Secrets / Changing Infrastructure

When AWS infrastructure changes (new bucket, new distribution, new IAM role):

1. Provision the new resource in AWS.
2. Update the relevant GitHub Secret or Variable in repository Settings.
3. Push any commit to `main` to trigger a deployment with the new values.
4. Verify the deployment succeeds before decommissioning the old resource.

The pipeline reads secrets at runtime — no code changes are required to update bucket names, role ARNs, or region.

---

## Binary Distribution (CLI Releases)

CLI binary artifacts are published independently by the CLI project's release pipeline. This repository has **no role** in uploading binaries — it only configures the CDN infrastructure to serve them.

After a release is published, binaries are accessible at:

```text
https://apps.microcode.io/dcv/releases/<version>/<binary-name>
```

For example:

```text
https://apps.microcode.io/dcv/releases/v3.2.1/dcv-darwin-arm64
https://apps.microcode.io/dcv/releases/v3.2.1/SHA256SUMS.txt
```

Repeat downloads of the same version are served from CloudFront edge cache (1-year TTL). The `X-Cache: Hit from cloudfront` response header confirms edge cache serving.
