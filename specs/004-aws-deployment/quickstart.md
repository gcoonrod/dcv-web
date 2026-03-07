# Quickstart: AWS Multi-Origin Hosting & CI/CD

**Feature**: `004-aws-deployment` | **Date**: 2026-03-07

Developer guide for verifying Astro base-path configuration locally, validating the production build output, and confirming CI/CD pipeline behavior after deployment.

---

## Prerequisites

- Node.js 20 LTS installed (`node --version` → `v20.x.x`)
- AWS CLI v2 installed and configured (for manual smoke tests)
- Access to the GitHub repository's Actions Secrets (for setting CI variables)
- AWS console access to the pre-provisioned CloudFront distribution and S3 buckets

---

## Step 1: Verify Astro Base Path Locally

After `base: '/dcv'` and `build: { format: 'file' }` are set in `astro.config.mjs`:

```bash
npm run dev
```

**Expected**: Dev server starts and the terminal prints:
```
  http://localhost:4321/dcv/
```

Open `http://localhost:4321/dcv/` in a browser — the site should load correctly. `http://localhost:4321/` (root) should return a 404.

---

## Step 2: Verify Production Build Output

```bash
npm run build
```

**Inspect `dist/index.html`** — asset references must include the `/dcv/` prefix:

```bash
grep -o 'href="/dcv[^"]*"' dist/index.html | head -5
grep -o 'src="/dcv[^"]*"' dist/index.html | head -5
```

**Expected output** (example):
```
href="/dcv/_astro/Layout.DaB3gHpK.css"
src="/dcv/_astro/hoisted.Cm9aB3vz.js"
```

**Verify flat file format for doc pages** (if docs are present):
```bash
find dist/docs -name "*.html" | head -10
# Should show: dist/docs/quickstart.html (NOT dist/docs/quickstart/index.html)
```

---

## Step 3: Configure GitHub Secrets

In the GitHub repository → Settings → Secrets and variables → Actions, add:

| Secret Name | Value Source |
|-------------|--------------|
| `AWS_ROLE_ARN` | IAM role ARN from AWS console (pre-provisioned) |
| `WEB_BUCKET` | Website S3 bucket name (pre-provisioned) |
| `DISTRIBUTION_ID` | CloudFront distribution ID (pre-provisioned) |

---

## Step 4: Trigger and Monitor a Deployment

Push a commit to `main`:

```bash
git push origin main
```

Navigate to the repository's **Actions** tab → observe the `Deploy to S3` workflow run.

**Expected step sequence**:
1. ✅ Checkout
2. ✅ Setup Node.js 20
3. ✅ Install dependencies (`npm ci`)
4. ✅ Build (`npm run build`)
5. ✅ Configure AWS credentials (OIDC role assumption)
6. ✅ Sync to S3 (files uploaded, stale files deleted)
7. ✅ Invalidate CloudFront cache (`/dcv/*`)

---

## Step 5: Smoke Test the Live Site

After the deployment completes:

```bash
# Verify the site is accessible
curl -I https://apps.microcode.io/dcv/

# Expected: HTTP/2 200, Content-Type: text/html
```

```bash
# Verify asset references resolve
curl -I https://apps.microcode.io/dcv/_astro/<filename>.css

# Expected: HTTP/2 200, Content-Type: text/css
```

---

## Step 6: Smoke Test Binary Distribution

After a release is published to the binary bucket:

```bash
# Verify a binary is accessible
curl -I https://apps.microcode.io/dcv/releases/v3.2.1/dcv-darwin-arm64

# Expected: HTTP/2 200, Content-Length: <size>
```

```bash
# Verify CDN edge caching (run twice; second request should show cache hit)
curl -I https://apps.microcode.io/dcv/releases/v3.2.1/dcv-darwin-arm64 2>&1 | grep -i "x-cache"

# Expected on second request: x-cache: Hit from cloudfront
```

---

## Troubleshooting

### `403 AccessDenied` on `/dcv/`
- Confirm the CloudFront Function is attached to the `/dcv/*` behavior.
- Confirm `dist/index.html` was synced to the S3 bucket root (not a subfolder).
- Test the CF Function in the CloudFront console using the test event `{ "uri": "/dcv/" }`.

### Assets return 404 after deploy
- Confirm `base: '/dcv'` is set in `astro.config.mjs`.
- Inspect `dist/index.html` for asset references — they should be `/dcv/_astro/...`, not `/_astro/...`.
- Confirm the CloudFront invalidation for `/dcv/*` completed (not just `Created`).

### OIDC role assumption fails in CI
- Verify `permissions: id-token: write` is set in the workflow YAML.
- Confirm the IAM role trust policy includes the correct `sub` condition matching the repo and branch.
- Check that the GitHub OIDC identity provider (`token.actions.githubusercontent.com`) is registered in AWS IAM.

### Binary bucket returns 403
- Confirm the bucket OAC policy references the correct CloudFront distribution ARN.
- Verify the `/dcv/releases/*` behavior has higher priority (lower number) than `/dcv/*` in CloudFront.
- Confirm the binary bucket's "Block Public Access" settings are enabled (this is correct behavior — all direct requests should 403).

### Pipeline took longer than 3 minutes
- Check `npm ci` cache hit — if Node modules were not cached, install takes ~60s.
- Large `dist/` output (many files) increases S3 sync time. Typical static sites sync in < 30s.
- CloudFront invalidation creation is instantaneous; propagation (not measured by pipeline) takes 1–5 minutes.
