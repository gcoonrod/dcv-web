# Contract: Deployment Workflow

**Feature**: `004-aws-deployment` | **Date**: 2026-03-07

This contract defines the interface between the `dcv-web` repository and the GitHub Actions CI/CD deployment pipeline. It specifies required inputs, expected outputs, and the invariants that must hold for the pipeline to be considered correct.

---

## Trigger Contract

| Property | Value |
|----------|-------|
| Event | `push` |
| Branch filter | `main` only |
| Path filter | None (all file changes trigger deployment) |

The pipeline MUST NOT trigger on pull requests, other branches, or manual dispatch unless explicitly added in a future feature.

---

## Environment Inputs (GitHub Secrets)

These values MUST be pre-provisioned in the GitHub repository's Actions secrets before the pipeline runs. They are injected as environment variables at runtime.

| Name | Kind | Description | Example |
|------|------|-------------|---------|
| `AWS_ROLE_ARN` | Secret | IAM role to assume via OIDC | `arn:aws:iam::123456789:role/dcv-web-deploy` |
| `WEB_BUCKET` | Secret | Website S3 bucket name (without `s3://` prefix) | `dcv-web-assets-prod` |
| `DISTRIBUTION_ID` | Secret | CloudFront distribution ID for invalidation | `E1A2B3C4D5E6F7` |
| `AWS_REGION` | Variable | AWS region where the S3 website bucket resides | `us-east-1` |

`AWS_REGION` is a **repository variable** (Settings → Secrets and variables → Variables), not a secret — it is not sensitive. The value must match the region of the `WEB_BUCKET`. CloudFront invalidations are global and region-agnostic; only the S3 sync command uses this region.

No AWS access keys (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) are stored. OIDC provides ephemeral credentials.

---

## Pipeline Step Contract

Steps execute sequentially. Any non-zero exit code MUST cause the pipeline to fail immediately (no `continue-on-error`).

| Step | Action | Success Condition | Failure Behavior |
|------|--------|-------------------|-----------------|
| 1. Checkout | `actions/checkout@v4` | Repository files available | Pipeline fails |
| 2. Setup Node.js | `actions/setup-node@v4` with Node 20 | `node --version` matches `20.x` | Pipeline fails |
| 3. Install dependencies | `npm ci` | Exit code 0; `node_modules/` populated | Pipeline fails |
| 4. Build | `npm run build` | Exit code 0; `dist/` directory exists and is non-empty | Pipeline fails |
| 5. Configure AWS credentials | `aws-actions/configure-aws-credentials@v4` | STS token exchange succeeds; `AWS_ACCESS_KEY_ID` env populated | Pipeline fails |
| 6. Sync to S3 | `aws s3 sync ./dist s3://$WEB_BUCKET --delete` | Exit code 0; CloudTrail records `PutObject`/`DeleteObject` events | Pipeline fails |
| 7. Invalidate CloudFront | `aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/dcv/*"` | Exit code 0; invalidation ID returned | Pipeline fails |

---

## Invariants

The following conditions MUST be true at the end of every successful pipeline run:

1. **Sync scope**: Only files in `./dist` were synced. No other directories or files were written to any S3 bucket.
2. **Invalidation scope**: The invalidation path is exactly `"/dcv/*"`. No broader paths (e.g., `"/*"`) are permitted.
3. **Credential type**: The pipeline assumed the OIDC role. No long-lived access keys were used or exposed.
4. **Build artifact**: The `dist/` directory was produced by `npm run build` in this pipeline run. Pre-existing or cached `dist/` directories must not be used.

---

## Workflow File Location

```text
.github/workflows/deploy.yml
```

---

## Reference Workflow Structure

```yaml
name: Deploy to S3

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}

      - name: Sync to S3
        run: aws s3 sync ./dist s3://${{ secrets.WEB_BUCKET }} --delete

      - name: Invalidate CloudFront cache
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.DISTRIBUTION_ID }} \
            --paths "/dcv/*"
```

> **Note**: `aws-region` should match the region of the S3 bucket. CloudFront invalidations are global and region-agnostic.
