# AWS Infrastructure Setup Guide

Step-by-step walkthrough for provisioning everything needed to serve `apps.microcode.io/dcv`. Complete these steps once before the first CI/CD deployment.

**Time estimate**: 60–90 minutes

**Prerequisites**:

- AWS account with console access and IAM admin privileges
- DNS control over `microcode.io` (Route 53 or any DNS provider)
- GitHub repository: `gcoonrod/dcv-web`

---

## Overview of What You're Building

```text
apps.microcode.io  (CNAME/Alias → CloudFront)
       │
CloudFront Distribution (apps.microcode.io, TLS via ACM)
       │
       ├── Behavior 1: /dcv/releases/*  ──► Binary S3 Bucket  (OAC, 1-year cache)
       └── Behavior 2: /dcv/*           ──► Website S3 Bucket (OAC, 24h cache + CF Function)
```

---

## Step 1 — Request an ACM SSL Certificate

CloudFront requires the TLS certificate to be in the **us-east-1** region (N. Virginia), regardless of where your S3 buckets are located. This is an AWS requirement and not configurable.

1. Open the **AWS Console** and switch the region to **US East (N. Virginia) — us-east-1** using the top-right region selector
2. Open **Certificate Manager (ACM)** → **Request** → **Request a public certificate** → **Next**
3. Under **Fully qualified domain name**, enter `apps.microcode.io`
4. Under **Validation method**, select **DNS validation (recommended)**
5. Click **Request**
6. Click the pending certificate to open its details — you will see a **CNAME record** to add to your DNS (format: `_abc123.apps.microcode.io CNAME _xyz456.acm-validations.aws`)

Record the **CNAME name** and **CNAME value** — you need them in Step 2.

---

## Step 2 — Validate the Certificate via DNS

ACM must confirm you own the domain before CloudFront can use the certificate.

**If you use Route 53** and `microcode.io` is a hosted zone:

1. Return to the ACM certificate detail page
2. Click **Create records in Route 53** — ACM adds the CNAME automatically
3. Wait 1–5 minutes for the certificate status to change from **Pending validation** to **Issued**

**If you use another DNS provider**:

1. Log in to your DNS provider's control panel
2. Create a CNAME record using the name and value from Step 1
3. Wait up to 30 minutes for the certificate to show **Issued** in ACM

Do not proceed past this step until the certificate shows **Issued**.

---

## Step 3 — Create the Website S3 Bucket

This bucket holds the Astro static site build output synced by CI. Record the bucket name — you will need it throughout this guide.

1. Open **S3** → **Create bucket**
2. Set **Bucket name** to a globally unique name (e.g., `dcv-web-assets-prod`)
3. Set **AWS Region** to your preferred region (e.g., `us-east-1`) — record this value, it becomes `AWS_REGION` in GitHub
4. Under **Object Ownership**, select **ACLs disabled (recommended)**
5. Under **Block Public Access settings**, leave all four checkboxes **checked**
6. Leave **Bucket Versioning** as **Disabled**
7. Leave **Default encryption** as **SSE-S3**
8. Click **Create bucket**

---

## Step 4 — Create the Binary S3 Bucket

This bucket holds versioned CLI release artifacts. It is populated by the external `publish-release.sh` script, not by the CI pipeline in this repository. Record the bucket name separately from the website bucket.

1. Open **S3** → **Create bucket**
2. Set **Bucket name** to a unique name (e.g., `dcv-releases-prod`)
3. Set **AWS Region** — any region; recommend the same region as the website bucket
4. Under **Block Public Access settings**, leave all four checkboxes **checked**
5. Leave **Bucket Versioning** as **Disabled**
6. Click **Create bucket**

---

## Step 5 — Create Origin Access Control for the Website Bucket

OAC allows CloudFront to securely fetch objects from private S3 buckets using SigV4 signing.

1. Open **CloudFront** → **Origin access** (left sidebar) → **Create control setting**
2. Set **Name** to `dcv-website-oac`
3. Set **Signing behavior** to `Sign requests (recommended)`
4. Set **Origin type** to `S3`
5. Click **Create**

Record the **OAC ID** shown on the confirmation screen.

---

## Step 6 — Create Origin Access Control for the Binary Bucket

1. Open **CloudFront** → **Origin access** → **Create control setting**
2. Set **Name** to `dcv-binaries-oac`
3. Set **Signing behavior** to `Sign requests (recommended)`
4. Set **Origin type** to `S3`
5. Click **Create**

Record the **OAC ID**.

---

## Step 7 — Configure the CloudFront Distribution

> **If a distribution for `apps.microcode.io` already exists**: skip sub-steps 7a–7c entirely. Do **not** create a second distribution and do **not** modify the existing default behavior (doing so risks breaking other apps on the shared distribution). Go directly to **Step 7d** to record the existing distribution's details, then continue to Step 8.

You will add the website bucket as an origin to the distribution. The binary bucket is added as a second origin in Step 9. Sub-steps 7a–7c apply only when creating a brand-new distribution.

### 7a. Configure the origin (new distribution only)

1. Open **CloudFront** → **Create a CloudFront distribution**
1. Under **Origin domain**, select the website S3 bucket from the dropdown (shown as `<bucket>.s3.<region>.amazonaws.com`)
1. Set **Name** to `dcv-website-s3`
1. Under **Origin access**, select **Origin access control settings (recommended)**
1. Under **Origin access control**, select `dcv-website-oac`
1. Leave **Origin path** empty (CI syncs files to the bucket root)

### 7b. Configure the default cache behavior (new distribution only)

1. Under **Viewer protocol policy**, select **Redirect HTTP to HTTPS**
1. Under **Allowed HTTP methods**, select **GET, HEAD**
1. Under **Cache key and origin requests**, select **Cache policy and origin request policy**
1. Under **Cache policy**, select **CachingDisabled** — the default behavior is a catch-all; the /dcv/* behaviors created later handle real caching

### 7c. Configure distribution settings (new distribution only)

1. Under **Price class**, select your preferred option (e.g., **Use only North America and Europe** to reduce costs, or **Use all edge locations** for global performance)
1. Under **Alternate domain name (CNAME)**, click **Add item** and enter `apps.microcode.io`
1. Under **Custom SSL certificate**, select the certificate you requested in Step 1 (must show **Issued**)
1. Leave **Default root object** empty — the CloudFront Function handles root resolution
1. Under **IPv6**, leave **Enabled**
1. Click **Create distribution**

### 7d. Record the distribution details

Open the distribution (existing or newly created) and record:

- **Distribution ID** (e.g., `E1ABCDEF2GHIJK`) — used in bucket policies and GitHub secrets
- **Distribution domain name** (e.g., `d1234567890abcde.cloudfront.net`) — used for DNS in Step 13
- Your **AWS Account ID** (12-digit number, shown in the top-right account menu)

> CloudFront may prompt you to copy an updated bucket policy. Dismiss this — you will apply the policy manually in Step 8.

---

## Step 8 — Apply Bucket Policies

Each bucket policy grants the CloudFront distribution exclusive read access via OAC. Direct S3 URL requests will return `403 Access Denied`.

### Website bucket policy

Replace the three placeholders, then apply to the website bucket:

- `<YOUR_WEBSITE_BUCKET_NAME>` — website bucket name from Step 3
- `<YOUR_ACCOUNT_ID>` — 12-digit AWS account ID from Step 7d
- `<YOUR_DISTRIBUTION_ID>` — distribution ID from Step 7d

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontOAC",
      "Effect": "Allow",
      "Principal": { "Service": "cloudfront.amazonaws.com" },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::<YOUR_WEBSITE_BUCKET_NAME>/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::<YOUR_ACCOUNT_ID>:distribution/<YOUR_DISTRIBUTION_ID>"
        }
      }
    }
  ]
}
```

To apply:

1. Open **S3** → select the **website bucket** → **Permissions** tab → **Bucket policy** → **Edit**
1. Paste the policy JSON with your values substituted
1. Click **Save changes**

### Binary bucket policy

Use the same JSON template, replacing `<YOUR_WEBSITE_BUCKET_NAME>` with the **binary** bucket name from Step 4. The account ID and distribution ID are the same.

To apply:

1. Open **S3** → select the **binary bucket** → **Permissions** → **Bucket policy** → **Edit**
1. Paste the adjusted JSON
1. Click **Save changes**

---

## Step 9 — Add S3 Buckets as CloudFront Origins

Both the website bucket and the binary bucket must exist as origins on the distribution before behaviors can reference them.

### 9a. Ensure the website bucket origin exists

1. Open **CloudFront** → select your distribution → **Origins** tab
1. Look for an origin whose domain matches your website S3 bucket (e.g., `dcv-web-assets-prod.s3.us-east-1.amazonaws.com`)
1. **If it already exists** (you created a new distribution in Step 7 and named it `dcv-website-s3`), proceed to Step 9b
1. **If it does not exist** (you are using a pre-existing distribution):
   1. Click **Create origin**
   1. Under **Origin domain**, select the website S3 bucket
   1. Set **Name** to `dcv-website-s3`
   1. Under **Origin access**, select **Origin access control settings (recommended)**
   1. Under **Origin access control**, select `dcv-website-oac`
   1. Click **Create origin**

### 9b. Add the binary bucket origin

1. On the **Origins** tab, click **Create origin**
1. Under **Origin domain**, select the binary S3 bucket
1. Set **Name** to `dcv-binaries-s3`
1. Under **Origin access**, select **Origin access control settings (recommended)**
1. Under **Origin access control**, select `dcv-binaries-oac`
1. Click **Create origin**

---

## Step 10 — Create and Deploy the CloudFront Function

This function handles index document resolution for the website behavior. It strips the `/dcv` prefix from request URIs and rewrites directory and extensionless paths to the correct `.html` filenames.

### 10a. Create the function

1. Open **CloudFront** → **Functions** (left sidebar) → **Create function**
1. Set **Name** to `dcv-index-resolver`
1. Set **Comment** to `Strips /dcv prefix; resolves directory requests to index.html`
1. In the **Function code** editor, replace the default content with:

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

1. Click **Save changes**

### 10b. Test the function

Click the **Test** tab and verify the following transformations before publishing:

| Test input URI           | Expected output URI     |
| ------------------------ | ----------------------- |
| `/dcv/`                  | `/index.html`           |
| `/dcv`                   | `/index.html`           |
| `/dcv/docs/quickstart`   | `/docs/quickstart.html` |
| `/dcv/_astro/main.css`   | `/_astro/main.css`      |
| `/dcv/favicon.svg`       | `/favicon.svg`          |

All five tests must pass before publishing.

### 10c. Publish the function

1. Click the **Publish** tab
1. Click **Publish function**

The function is now live at all CloudFront edge locations.

---

## Step 11 — Create the Binary Release Behavior

**Important**: Create the binary behavior first. It must be assigned a lower priority number (evaluated first) than the website behavior. Creating it first ensures the correct default ordering.

### 11a. Create the 1-year immutable cache policy

Open a new tab for this sub-step, then return:

1. Open **CloudFront** → **Policies** → **Cache** → **Create cache policy**
1. Set **Name** to `dcv-immutable-1yr`
1. Set all three TTL fields (**Minimum**, **Default**, **Maximum**) to `31536000`
1. Under **Cache key settings**, leave **Headers**, **Query strings**, and **Cookies** all set to **None**
1. Click **Create**

### 11b. Create the behavior

1. Open **CloudFront** → your distribution → **Behaviors** tab → **Create behavior**
1. Set **Path pattern** to `/dcv/releases/*`
1. Set **Origin and origin groups** to `dcv-binaries-s3`
1. Set **Compress objects automatically** to **Yes**
1. Set **Viewer protocol policy** to **Redirect HTTP to HTTPS**
1. Set **Allowed HTTP methods** to **GET, HEAD**
1. Under **Cache key and origin requests**, select **Cache policy and origin request policy**
1. Set **Cache policy** to `dcv-immutable-1yr`
1. Leave **Function associations** empty — binary files have explicit extensions and need no URI rewriting
1. Click **Create behavior**

---

## Step 12 — Create the Website Behavior

### 12a. Create the website cache policy

1. Open **CloudFront** → **Policies** → **Cache** → **Create cache policy**
1. Set **Name** to `dcv-website-24h`
1. Set **Minimum TTL** to `0`, **Default TTL** to `86400`, **Maximum TTL** to `86400`
1. Under **Cache key settings**, leave all forwarding options set to **None**
1. Click **Create**

### 12b. Create the `/dcv/*` behavior

1. Open **CloudFront** → your distribution → **Behaviors** → **Create behavior**
1. Set **Path pattern** to `/dcv/*`
1. Set **Origin and origin groups** to `dcv-website-s3`
1. Set **Compress objects automatically** to **Yes**
1. Set **Viewer protocol policy** to **Redirect HTTP to HTTPS**
1. Set **Allowed HTTP methods** to **GET, HEAD**
1. Under **Cache key and origin requests**, select **Cache policy and origin request policy**
1. Set **Cache policy** to `dcv-website-24h`
1. Under **Function associations** → **Viewer request**, set **Function type** to `CloudFront Functions` and set **Function ARN/Name** to `dcv-index-resolver`
1. Click **Create behavior**

### 12c. Create the `/dcv` exact-path behavior

CloudFront's `/dcv/*` path pattern does **not** match the bare path `/dcv` (no trailing slash). Without a dedicated behavior, a request to `https://apps.microcode.io/dcv` falls through to the default behavior and returns an error. Add a third behavior to handle this case:

1. Click **Create behavior**
1. Set **Path pattern** to `/dcv`
1. Set **Origin and origin groups** to `dcv-website-s3`
1. Set **Compress objects automatically** to **Yes**
1. Set **Viewer protocol policy** to **Redirect HTTP to HTTPS**
1. Set **Allowed HTTP methods** to **GET, HEAD**
1. Set **Cache policy** to `dcv-website-24h`
1. Under **Function associations** → **Viewer request**, set **Function type** to `CloudFront Functions` and set **Function ARN/Name** to `dcv-index-resolver`
1. Click **Create behavior**

The CloudFront Function rewrites `/dcv` → `/index.html`, so this behavior correctly serves the homepage.

### 12d. Verify behavior priority ordering

Open the **Behaviors** tab and confirm the order is exactly:

| Priority | Path Pattern      |
| -------- | ----------------- |
| 1        | `/dcv/releases/*` |
| 2        | `/dcv/*`          |
| 3        | `/dcv`            |
| Default  | `*`               |

If the ordering is wrong, select a behavior and use the **Edit** button to adjust. `/dcv/releases/*` **must** have the lowest priority number (evaluated first). Reversed order causes binary download requests to be routed to the website bucket, returning HTML instead of the binary file.

---

## Step 13 — Point apps.microcode.io to CloudFront

Use the **Distribution domain name** recorded in Step 7d (e.g., `d1234567890abcde.cloudfront.net`).

**If you use Route 53**:

1. Open **Route 53** → **Hosted zones** → select the `microcode.io` hosted zone
1. Click **Create record**
1. Set **Record name** to `apps`
1. Set **Record type** to **A**
1. Enable **Alias** and set the alias target to the CloudFront distribution domain
1. Click **Create records**

**If you use another DNS provider**:

1. Log in to your DNS provider
1. Create a **CNAME** record: `apps.microcode.io` → `d1234567890abcde.cloudfront.net`

DNS propagation typically takes 1–10 minutes for Route 53, up to 60 minutes for other providers. You can continue with the remaining steps while propagation completes.

---

## Step 14 — Register GitHub as an IAM OIDC Identity Provider

This is a one-time account-level setup. Skip this step if your AWS account already has `token.actions.githubusercontent.com` registered as an OIDC provider (check under **IAM** → **Identity providers**).

1. Open **IAM** → **Identity providers** → **Add provider**
1. Set **Provider type** to **OpenID Connect**
1. Set **Provider URL** to `https://token.actions.githubusercontent.com`
1. Click **Get thumbprint**
1. Set **Audience** to `sts.amazonaws.com`
1. Click **Add provider**

---

## Step 15 — Create the IAM Deploy Role

This role is assumed by GitHub Actions on every push to `main` using short-lived OIDC credentials. No long-lived access keys are stored anywhere.

### 15a. Create the role

1. Open **IAM** → **Roles** → **Create role**
1. Set **Trusted entity type** to **Web identity**
1. Set **Identity provider** to `token.actions.githubusercontent.com`
1. Set **Audience** to `sts.amazonaws.com`
1. Set **GitHub organization** to `gcoonrod`
1. Set **GitHub repository** to `dcv-web`
1. Set **GitHub branch** to `main`
1. Click **Next**

### 15b. Attach permissions

On the **Add permissions** screen, click **Create inline policy** and paste the following JSON.

Replace `<YOUR_WEBSITE_BUCKET_NAME>`, `<YOUR_ACCOUNT_ID>`, and `<YOUR_DISTRIBUTION_ID>` with the values recorded in Steps 3 and 7d.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3WebsiteSync",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:DeleteObject", "s3:GetObject"],
      "Resource": "arn:aws:s3:::<YOUR_WEBSITE_BUCKET_NAME>/*"
    },
    {
      "Sid": "S3WebsiteBucketList",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::<YOUR_WEBSITE_BUCKET_NAME>"
    },
    {
      "Sid": "CloudFrontInvalidation",
      "Effect": "Allow",
      "Action": "cloudfront:CreateInvalidation",
      "Resource": "arn:aws:cloudfront::<YOUR_ACCOUNT_ID>:distribution/<YOUR_DISTRIBUTION_ID>"
    }
  ]
}
```

This role grants **no access** to the binary bucket — that bucket is managed exclusively by the external CLI release pipeline.

### 15c. Name and save the role

1. Set **Role name** to `dcv-web-deploy`
1. Review the settings and click **Create role**
1. Open the role detail page and copy the full **ARN** (e.g., `arn:aws:iam::123456789012:role/dcv-web-deploy`) — this is `AWS_ROLE_ARN`

### 15d. Verify the trust policy

Open the role → **Trust relationships** → **Edit trust policy** and confirm the `Condition` block is scoped to the `main` branch:

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

---

## Step 16 — Configure GitHub Secrets and Variables

Open the GitHub repository → **Settings** → **Secrets and variables** → **Actions**.

### Secrets

Click **New repository secret** for each of the following:

| Secret name | Value |
| --- | --- |
| `AWS_ROLE_ARN` | Role ARN from Step 15c |
| `WEB_BUCKET` | Website bucket name from Step 3 (no `s3://` prefix) |
| `DISTRIBUTION_ID` | CloudFront distribution ID from Step 7d |

### Variables

Click the **Variables** tab, then **New repository variable**:

| Variable name | Value |
| --- | --- |
| `AWS_REGION` | AWS region of the website S3 bucket (e.g., `us-east-1`) |

`AWS_REGION` is a repository **Variable**, not a Secret — it is not sensitive. CloudFront invalidations are global; only the S3 sync command uses this region value.

---

## Step 17 — Trigger the First Deployment

With infrastructure provisioned and GitHub configured, trigger the first deployment:

```bash
git checkout main
git commit --allow-empty -m "chore: trigger initial deployment"
git push origin main
```

Then open **GitHub** → **Actions** → **Deploy to S3** and watch the run.

### Expected pipeline output

| Step                      | What to look for                                     |
| ------------------------- | ---------------------------------------------------- |
| Build                     | `dist/` created; `index.html` at root                |
| Configure AWS credentials | Step completes without error (OIDC handshake)        |
| Sync to S3                | `upload:` lines for each file in `dist/`             |
| Invalidate CloudFront     | Step outputs an invalidation ID                      |

---

## Step 18 — Smoke Test the Live Site

After the CloudFront invalidation completes (typically 30–60 seconds):

| URL to test | Expected result |
| --- | --- |
| `https://apps.microcode.io/dcv/` | DCV homepage loads |
| `https://apps.microcode.io/dcv/docs/quickstart` | Quickstart doc page loads |
| `https://apps.microcode.io/dcv/_astro/*.css` | CSS file downloads; second request has `X-Cache: Hit from cloudfront` |
| Direct S3 URL (any bucket) | Returns `403 AccessDenied` |

---

## Troubleshooting

### Certificate not issuing (stuck at Pending validation)

- Confirm the DNS CNAME record is correct — the name must include a trailing dot on some DNS providers
- Check propagation with `dig _abc123.apps.microcode.io CNAME`
- ACM checks DNS periodically; wait up to 30 minutes after adding the record

### `403 AccessDenied` on the live CloudFront URL

- Confirm the bucket policy `Condition` uses the correct distribution ARN (Step 8)
- Confirm **Block Public Access** is enabled on the bucket
- Confirm the OAC is selected on the CloudFront origin (not left as "Public")

### `NoSuchKey` or blank page for sub-pages

- The CloudFront Function may not be attached — check the `/dcv/*` behavior's **Function associations** (Step 12b)
- Retest the function using the **Test** tab (Step 10b) with the failing path

### Binary URL returns HTML instead of the binary file

- Check behavior priority in the **Behaviors** tab — `/dcv/releases/*` must be priority 1
- If the ordering is wrong, edit each behavior and correct the priority number

### OIDC token exchange fails in GitHub Actions

- Confirm the IAM Identity Provider URL is exactly `https://token.actions.githubusercontent.com` (with `https://`)
- Confirm the trust policy `sub` field is `repo:gcoonrod/dcv-web:ref:refs/heads/main` exactly
- Confirm the workflow `permissions` block includes `id-token: write`

### `aws s3 sync` fails with `AccessDenied`

- Confirm the IAM role policy covers `s3:PutObject`, `s3:DeleteObject`, and `s3:ListBucket` on the correct bucket ARN
- Confirm the `WEB_BUCKET` secret value does not include the `s3://` prefix
