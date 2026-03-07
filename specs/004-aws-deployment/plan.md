# Implementation Plan: AWS Multi-Origin Hosting & CI/CD

**Branch**: `004-aws-deployment` | **Date**: 2026-03-07 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-aws-deployment/spec.md`

## Summary

Reconfigure the Astro site with `base: '/dcv'` and `build.format: 'file'`, then establish a GitHub Actions CI/CD pipeline that syncs the static build to a private website S3 bucket and invalidates the `/dcv/*` CloudFront path on every `main` push. A separate private S3 binary bucket serves versioned CLI release artifacts via a higher-priority CloudFront Behavior with a 1-year immutable cache policy. Both buckets are locked to CloudFront-only access via Origin Access Control (OAC). A minimal CloudFront Function (viewer-request) handles `index.html` resolution and `.html` extension appending for extensionless paths, eliminating directory-index 403 errors inherent to S3 REST endpoints.

## Technical Context

**Language/Version**: TypeScript + Node.js 20 LTS (Astro 5.18.x)
**Primary Dependencies**: Astro 5.18.x, `@tailwindcss/vite` (v4), AWS CLI v2, GitHub Actions
**Storage**: Two private S3 buckets (website + binaries); CloudFront distribution (pre-provisioned)
**Testing**: Build output inspection (HTML asset paths), HTTPS smoke test, CI run log + CloudFront invalidation log
**Target Platform**: AWS CloudFront + S3 (static hosting); GitHub Actions (CI/CD runner)
**Project Type**: Static web app deployment + CI/CD pipeline configuration
**Performance Goals**: CI pipeline completes full cycle in < 3 minutes (SC-004); binary downloads served from CDN edge cache after first request (SC-007)
**Constraints**: `output: 'static'` must remain set; no SSR adapters; no ALB/EC2; OIDC-only auth; invalidation path strictly `/dcv/*`
**Scale/Scope**: One CloudFront distribution, two S3 buckets, one IAM OIDC role, one GitHub Actions workflow, one CloudFront Function

## Constitution Check

### Principle I — Zero-JavaScript Default (Static First)
**Status**: ✅ PASS

`output: 'static'` remains unchanged in `astro.config.mjs`. `build.format: 'file'` is a static build output variant — it changes file naming (`about.html` vs `about/index.html`) but does not introduce SSR, adapters, or a server runtime.

### Principle III — AWS Native
**Status**: ✅ PASS

Deployment is a flat file sync (`aws s3 sync`) to S3. CloudFront performs all path routing natively via Behaviors. No ALB, API Gateway, EC2, or reverse proxy of any kind.

### Bright-Line Rules I–V
**Status**: ✅ PASS

This feature adds no new UI components, Tailwind deviations, JS frameworks, assets, or semantic HTML changes. Rules I–V are not implicated.

### Branching Convention (Development Workflow)
**Status**: ⚠️ NOTED — Non-blocking

The constitution specifies `feature/<short-description>` branch naming. This project uses `###-name` convention established in Phase 1. This pre-existing deviation is documented here; no remediation required for this feature cycle.

## Project Structure

### Documentation (this feature)

```text
specs/004-aws-deployment/
├── plan.md                        # This file
├── research.md                    # Phase 0: key technical decisions with rationale
├── data-model.md                  # Phase 1: infrastructure entity model
├── quickstart.md                  # Phase 1: developer verification guide
├── contracts/
│   ├── deployment-workflow.md     # CI/CD workflow interface contract
│   └── cdn-routing.md             # CloudFront behavior routing contract
└── tasks.md                       # Phase 2 output (/speckit.tasks — not created here)
```

### Source Code Changes (repository root)

```text
astro.config.mjs                   # Add base: '/dcv', build: { format: 'file' }
.github/
└── workflows/
    └── deploy.yml                 # New: CI/CD pipeline (build → sync → invalidate)
DEPLOYMENT.md                      # New: dual-bucket CloudFront architecture docs (FR-010)
```

**Structure Decision**: Single-project layout. No new source directories. All changes are configuration files and CI/CD infrastructure — no new `src/` subdirectories required.

## Scope Clarification: Repo vs. Infrastructure Tasks

This feature spans two domains with different execution contexts. Tasks MUST NOT be conflated.

### Repository Tasks (code changes in this repo)

These are files committed to `dcv-web` and can be verified locally or via CI:

| Task | File | Can verify locally? |
|------|------|---------------------|
| Configure Astro base path + file format | `astro.config.mjs` | Yes — `npm run dev`, `npm run build` |
| Create CI/CD deployment workflow | `.github/workflows/deploy.yml` | Partial — YAML linting; full test requires AWS infra |
| Write architecture documentation | `DEPLOYMENT.md` | Yes — content review |

### Infrastructure Tasks (AWS Console or CLI — outside the repo)

These must be completed **before** the workflow YAML can be tested end-to-end. They produce values (bucket names, distribution ID, role ARN) that are then stored as GitHub Secrets.

| Task | AWS Service | Produces value needed by |
|------|-------------|--------------------------|
| Create website S3 bucket + block public access | S3 | `WEB_BUCKET` secret |
| Create binary S3 bucket + block public access | S3 | (used by CLI publish script) |
| Create OAC for website bucket | CloudFront | Bucket policy condition |
| Create OAC for binary bucket | CloudFront | Bucket policy condition |
| Apply OAC bucket policies to both buckets | S3 | Enables CDN access |
| Add website + binary origins to CloudFront distribution | CloudFront | Behavior configuration |
| Create binary behavior (`/dcv/releases/*`, priority 1) | CloudFront | `DISTRIBUTION_ID` secret |
| Create website behavior (`/dcv/*`, priority 2) | CloudFront | `DISTRIBUTION_ID` secret |
| Create and publish CloudFront Function (index resolver) | CloudFront | Attached to website behavior |
| Attach CF Function to website behavior (viewer-request) | CloudFront | Enables index.html resolution |
| Register GitHub OIDC Identity Provider in AWS IAM | IAM | IAM role trust policy |
| Create IAM OIDC Deploy Role + attach policy | IAM | `AWS_ROLE_ARN` secret |

### Prerequisite: Pre-existing Infrastructure

The CloudFront **distribution** for `apps.microcode.io` is assumed to already exist with a default behavior serving other application paths. This feature adds two new **behaviors** and two new **origins** to that existing distribution — it does NOT create a new distribution.

---

## Implementation Phases

Phases must be executed in order. Each phase lists its inputs, the exact artifact that defines the work, and its verification method.

### Phase 1 — Astro Base Path Configuration

**Inputs**: None
**Reference**: `research.md` Decision 1 (Astro sub-path configuration)
**Files changed**: `astro.config.mjs`

Add `base` and `build.format` to the existing config:

```js
// astro.config.mjs — add these two properties alongside existing config
export default defineConfig({
  output: 'static',       // unchanged — Constitution Principle I
  base: '/dcv',           // new: prefix all asset refs + internal links
  build: {
    format: 'file',       // new: flat .html files (about.html not about/index.html)
  },
  // ... rest of config unchanged
});
```

**Verification** (before proceeding):
- `npm run dev` → terminal shows `http://localhost:4321/dcv/`
- `npm run build` → `dist/index.html` contains asset refs with `/dcv/_astro/` prefix
- `find dist/docs -name "*.html"` → shows `dist/docs/page.html` not `dist/docs/page/index.html`
- See `quickstart.md` Steps 1–2 for exact verification commands

---

### Phase 2 — AWS Infrastructure Provisioning

**Inputs**: Existing CloudFront distribution ID, AWS account ID
**Reference**: `data-model.md` (all entity specs), `research.md` Decisions 2–4
**Files changed**: None (AWS console/CLI work)
**Produces**: `WEB_BUCKET` name, `DISTRIBUTION_ID`, `AWS_ROLE_ARN` values for Phase 4

Execute the infrastructure tasks in this order (each step depends on the previous):

**Step 2a — S3 Buckets**
Create both buckets with all four "Block Public Access" settings enabled. No static website hosting. No public bucket policies.
→ `data-model.md` §Website S3 Bucket, §Binary S3 Bucket

**Step 2b — Origin Access Controls**
Create two OAC configurations (one per bucket). Signing behavior: Sign requests. Protocol: S3.
→ `data-model.md` §Origin Access Control

**Step 2c — OAC Bucket Policies**
Apply bucket policies to each bucket using the pattern in `research.md` Decision 3. The `AWS:SourceArn` condition must reference the specific CloudFront distribution ARN.
→ `research.md` Decision 3 (OAC bucket policy JSON)

**Step 2d — CloudFront Origins**
Add both S3 buckets as origins to the existing distribution. Use the S3 REST API endpoint (not the static website endpoint). Attach the respective OAC to each origin.
→ `contracts/cdn-routing.md` §Origin Definitions

**Step 2e — CloudFront Behaviors**
Add behaviors in this order (priority matters — binary MUST be priority 1):
1. `/dcv/releases/*` → Binary bucket origin. Cache policy: 1-year immutable (MinTTL=MaxTTL=DefaultTTL=31536000s). No CF Function.
2. `/dcv/*` → Website bucket origin. Cache policy: 24h (DefaultTTL=86400s). CF Function: to be created in Step 2f.

→ `contracts/cdn-routing.md` §Behavior Routing Contract
→ `data-model.md` §CloudFront Distribution behaviors table

**Step 2f — CloudFront Function**
Create a new CloudFront Function (runtime: `cloudfront-js-2.0`), publish it, then attach it to the `/dcv/*` behavior at the viewer-request event. Do NOT attach to the `/dcv/releases/*` behavior.

**Function source** (copy verbatim from `research.md` Decision 2):
```javascript
function handler(event) {
  var uri = event.request.uri;
  var path = uri.replace(/^\/dcv/, '') || '/';
  if (path.endsWith('/')) {
    path = path + 'index.html';
  } else if (!path.split('/').pop().includes('.')) {
    path = path + '.html';
  }
  event.request.uri = path;
  return event.request;
}
```

Test using CloudFront Function test events before attaching:
→ `data-model.md` §CloudFront Function — Index Resolver (transformation table for test inputs)

**Step 2g — IAM OIDC Identity Provider**
Register `token.actions.githubusercontent.com` as an OpenID Connect identity provider in IAM (one-time per AWS account). Audience: `sts.amazonaws.com`.

**Step 2h — IAM OIDC Deploy Role**
Create IAM role with trust policy and permissions scoped to this repo and `main` branch only.
→ `research.md` Decision 4 (trust policy JSON + required permissions list)
→ `data-model.md` §IAM Role (OIDC Deploy Role) (permissions NOT granted — verify these are absent)

---

### Phase 3 — GitHub Secrets

**Inputs**: Values produced by Phase 2
**Reference**: `contracts/deployment-workflow.md` §Environment Inputs
**Files changed**: None (GitHub repository settings)

Add three secrets to the repository (Settings → Secrets and variables → Actions):

| Secret | Value source |
|--------|-------------|
| `AWS_ROLE_ARN` | ARN of role created in Phase 2h |
| `WEB_BUCKET` | Name of website bucket created in Phase 2a |
| `DISTRIBUTION_ID` | ID of the existing CloudFront distribution |

→ `quickstart.md` Step 3

---

### Phase 4 — CI/CD Workflow File

**Inputs**: Phase 3 secrets must exist
**Reference**: `contracts/deployment-workflow.md` §Reference Workflow Structure + §Invariants
**Files changed**: `.github/workflows/deploy.yml` (new file)

Create `.github/workflows/deploy.yml` using the reference YAML in `contracts/deployment-workflow.md`. Verify all four workflow invariants are satisfied before committing:

1. Only `./dist` is synced — no other paths written to S3
2. Invalidation path is exactly `"/dcv/*"` — not `"/*"`
3. `id-token: write` permission is set — OIDC token generation enabled
4. No `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` in the file or secrets

→ `contracts/deployment-workflow.md` §Pipeline Step Contract (step-by-step success conditions)

---

### Phase 5 — Architecture Documentation

**Inputs**: Phases 2–4 complete (infra values known)
**Reference**: `data-model.md` (entity relationship diagram + all entities), `contracts/cdn-routing.md` (routing table + invariants)
**Files changed**: `DEPLOYMENT.md` (new file at repo root)

`DEPLOYMENT.md` must cover (FR-010):
1. Overview of the dual-origin CloudFront routing model (diagram from `data-model.md` §Entity Relationship Diagram)
2. Behavior priority table (from `data-model.md` §CloudFront Distribution behaviors)
3. S3 bucket layout and OAC access pattern
4. CloudFront Function purpose and transformation logic
5. How to add GitHub Secrets when rotating/changing infra
6. How to trigger a manual deployment (push to `main`)

---

### Phase 6 — End-to-End Verification

**Inputs**: All prior phases complete; first `main` push triggered
**Reference**: `quickstart.md` Steps 4–6, `contracts/cdn-routing.md` §HTTP Response Guarantees
**Files changed**: None

Verify in order:
1. CI run completes all 7 steps successfully (`quickstart.md` Step 4)
2. `https://apps.microcode.io/dcv/` returns `200 OK` with HTML (`quickstart.md` Step 5)
3. Asset at `/dcv/_astro/*.css` returns `200 OK` with correct `Content-Type`
4. CloudFront invalidation log shows path `/dcv/*` only — not `/*`
5. Direct S3 URL returns `403 AccessDenied` (OAC is working)
6. Binary at `/dcv/releases/<version>/<binary>` returns `200 OK` (`quickstart.md` Step 6)
7. Second binary request shows `x-cache: Hit from cloudfront`

If any step fails, consult `quickstart.md` §Troubleshooting for the specific error scenario.

---

## Complexity Tracking

> No Bright-Line Rule violations were identified. No entries required.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| CloudFront Function (viewer-request) | S3 REST endpoints do not serve `index.html` for directory requests. Required to rewrite `/dcv/` → `/index.html` and extensionless paths → `.html`. | No CF Function: would require S3 website endpoint, which is incompatible with OAC (Origin Access Control). OAC is required per FR-011 and the security clarification. |
