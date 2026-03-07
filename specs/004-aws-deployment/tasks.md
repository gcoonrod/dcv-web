# Tasks: AWS Multi-Origin Hosting & CI/CD

**Input**: Design documents from `/specs/004-aws-deployment/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Tests**: No test tasks — spec does not request TDD. Verification steps are embedded directly in each user story phase.

**Organization**: Tasks follow the 6 implementation phases defined in `plan.md §Implementation Phases`. Infrastructure (AWS console) tasks are separated from repository (code) tasks. All references point to the exact artifact section that defines the work.

**Note on AWS tasks**: Tasks marked `[AWS]` are AWS console/CLI operations — not code commits. They require AWS console access and produce configuration values used in later tasks.

## Format: `[ID] [P?] [Story?] Description → reference`

- **[P]**: Can run in parallel (independent operations, no shared dependencies)
- **[AWS]**: AWS console or CLI operation (not a code change)
- **[Story]**: Which user story this task belongs to (US1 / US2 / US3)
- Each task references the exact plan/contract/research section defining the work

---

## Phase 1: Setup (Repository Structure)

**Purpose**: Create repository scaffolding needed before any files can be written.

- [x] T001 Create `.github/workflows/` directory structure at repository root

**Checkpoint**: Repository structure ready — code tasks can begin.

---

## Phase 2: User Story 1 — Astro Base Path Compatibility (Priority: P1) 🎯 MVP

**Goal**: The Astro site builds with `base: '/dcv'` and `build.format: 'file'` so all asset references and internal links are correctly prefixed for sub-path CDN hosting, and the local dev server matches the production URL.

**Independent Test**: Can be fully verified locally without any AWS infrastructure. Run `npm run dev` and confirm the terminal shows `http://localhost:4321/dcv/`. Run `npm run build` and confirm `dist/index.html` references assets at `/dcv/_astro/...`. No deployment required.

**Why first**: US1 is the only story with zero cloud dependency. It's the fastest validation cycle and sets the foundation that makes US2's deployment produce correct output.

### Implementation for User Story 1

- [x] T002 [US1] Update `astro.config.mjs`: add `base: '/dcv'` and `build: { format: 'file' }` properties alongside existing `output: 'static'`, `markdown`, and `vite` config → `plan.md §Phase 1`, `research.md §Decision 1`
- [ ] T003 [US1] Run `npm run dev` and verify terminal output shows `http://localhost:4321/dcv/` and the site loads at that URL (root `/` should 404) → `quickstart.md §Step 1`
- [x] T004 [US1] Run `npm run build` and verify: (a) `dist/index.html` asset refs contain `/dcv/_astro/` prefix; (b) doc pages emit as `dist/docs/page.html` not `dist/docs/page/index.html` → `quickstart.md §Step 2`

**Checkpoint**: US1 complete. Astro base path verified. `dist/` output is production-correct for sub-path CDN hosting. Safe to commit and proceed to AWS infra.

---

## Phase 3: Foundational — AWS Infrastructure Provisioning

**Purpose**: All AWS resources that US2 and US3 depend on. Must be fully provisioned before Phase 4 (US2) or Phase 5 (US3) can be validated end-to-end.

**⚠️ CRITICAL**: No AWS-dependent user story validation can occur until this phase is complete. These are AWS console/CLI operations — not code commits. Each step references the exact plan section and detail doc for the full specification.

**Prerequisite**: Existing CloudFront distribution ID and AWS account ID must be known before starting.

### Step 3a — S3 Buckets (parallel)

- [ ] T005 [P] [AWS] Create website S3 bucket: enable all 4 "Block Public Access" settings, disable static website hosting, no public bucket policy → `plan.md §Phase 2 Step 2a`, `data-model.md §Website S3 Bucket`
- [ ] T006 [P] [AWS] Create binary S3 bucket: enable all 4 "Block Public Access" settings, disable static website hosting, no public bucket policy → `plan.md §Phase 2 Step 2a`, `data-model.md §Binary S3 Bucket`

### Step 3b — Origin Access Controls (parallel, independent of bucket creation)

- [ ] T007 [P] [AWS] Create OAC for website bucket in CloudFront console: Signing behavior = "Sign requests", Protocol = "S3", Origin type = "S3" → `plan.md §Phase 2 Step 2b`, `data-model.md §Origin Access Control`
- [ ] T008 [P] [AWS] Create OAC for binary bucket in CloudFront console: same settings as T007 → `plan.md §Phase 2 Step 2b`, `data-model.md §Origin Access Control`

### Step 3c — OAC Bucket Policies (parallel, requires T005–T008)

- [ ] T009 [P] [AWS] Apply OAC bucket policy to website S3 bucket: use JSON pattern from `research.md §Decision 3`; set `AWS:SourceArn` to the existing CloudFront distribution ARN; set `Resource` to website bucket ARN → `plan.md §Phase 2 Step 2c`
- [ ] T010 [P] [AWS] Apply OAC bucket policy to binary S3 bucket: same pattern as T009 using binary bucket ARN and same CloudFront distribution ARN → `plan.md §Phase 2 Step 2c`

### Step 3d — Add Origins to CloudFront Distribution (parallel, requires T009–T010)

- [ ] T011 [P] [AWS] Add website S3 bucket as new origin to the existing CloudFront distribution: use S3 REST API endpoint (not static website endpoint), attach website OAC created in T007 → `plan.md §Phase 2 Step 2d`, `contracts/cdn-routing.md §Origin Definitions`
- [ ] T012 [P] [AWS] Add binary S3 bucket as new origin to the existing CloudFront distribution: use S3 REST API endpoint, attach binary OAC created in T008 → `plan.md §Phase 2 Step 2d`, `contracts/cdn-routing.md §Origin Definitions`

### Step 3e — CloudFront Function (requires nothing — can run parallel with 3a–3d)

- [ ] T013 [P] [AWS] Create CloudFront Function named `dcv-index-resolver` (runtime: `cloudfront-js-2.0`): paste source code verbatim from `plan.md §Phase 2 Step 2f` (also in `research.md §Decision 2`); publish the function → `plan.md §Phase 2 Step 2f`
- [ ] T014 [AWS] Test CloudFront Function using the CloudFront console test tool before attaching: run test events for inputs `/dcv/`, `/dcv`, `/dcv/docs/quickstart`, `/dcv/_astro/main.css` and verify output URIs match the transformation table → `data-model.md §CloudFront Function — Index Resolver`

### Step 3f — CloudFront Behaviors (requires T011–T012, T014; binary behavior first)

- [ ] T015 [AWS] Create CloudFront behavior for `/dcv/releases/*` (Priority 1 — highest): origin = binary bucket origin (T012), cache policy = custom 1-year immutable (MinTTL=MaxTTL=DefaultTTL=31536000s), no CloudFront Function, allowed methods = GET+HEAD, HTTPS only → `plan.md §Phase 2 Step 2e`, `contracts/cdn-routing.md §Behavior 1`
- [ ] T016 [AWS] Create CloudFront behavior for `/dcv/*` (Priority 2): origin = website bucket origin (T011), cache policy = custom 24h (DefaultTTL=86400s), attach `dcv-index-resolver` CF Function at viewer-request event, allowed methods = GET+HEAD, HTTPS only → `plan.md §Phase 2 Step 2e`, `contracts/cdn-routing.md §Behavior 2`

### Step 3g — IAM OIDC (can run parallel with 3a–3f)

- [ ] T017 [P] [AWS] Register `token.actions.githubusercontent.com` as an OpenID Connect Identity Provider in AWS IAM (one-time per account): Provider URL = `https://token.actions.githubusercontent.com`, Audience = `sts.amazonaws.com` → `plan.md §Phase 2 Step 2g`, `research.md §Decision 4`
- [ ] T018 [AWS] Create IAM OIDC Deploy Role: trust policy scoped to `repo:gcoonrod/dcv-web:ref:refs/heads/main`; attach inline policy granting `s3:PutObject`, `s3:DeleteObject`, `s3:ListBucket` on website bucket ARN and `cloudfront:CreateInvalidation` on distribution ARN only; verify binary bucket and `s3:DeleteBucket` are NOT granted → `plan.md §Phase 2 Step 2h`, `data-model.md §IAM Role (OIDC Deploy Role)`, `research.md §Decision 4`

**Checkpoint**: AWS infrastructure complete. Website bucket, binary bucket, OACs, behaviors, CF Function, and IAM role all provisioned. Record: `WEB_BUCKET` name, `DISTRIBUTION_ID`, `AWS_ROLE_ARN` — needed for Phase 4.

---

## Phase 4: User Story 2 — Automated Deployment & Scoped Cache Invalidation (Priority: P1)

**Goal**: Push to `main` triggers a GitHub Actions pipeline that builds the site, syncs `dist/` to the website S3 bucket with `--delete`, and invalidates exactly `/dcv/*` in CloudFront — with no long-lived AWS credentials stored anywhere.

**Independent Test**: Push a commit to `main`. Observe all 7 CI steps complete. Verify `https://apps.microcode.io/dcv/` returns `200 OK`. Confirm the CloudFront invalidation record shows path `/dcv/*` and no other paths. Verify the pipeline used OIDC (no `AWS_ACCESS_KEY_ID` secret exists in the repo).

**Depends on**: Phase 3 fully complete (all infra values known).

### Implementation for User Story 2

- [ ] T019 [US2] Configure GitHub repository secrets and variables (Settings → Secrets and variables): add three **Secrets** — `AWS_ROLE_ARN` (from T018), `WEB_BUCKET` (from T005), `DISTRIBUTION_ID` (existing distribution ID) — and one **Variable** — `AWS_REGION` (the AWS region where the website S3 bucket was created, e.g., `us-east-1`) → `plan.md §Phase 3`, `contracts/deployment-workflow.md §Environment Inputs`, `quickstart.md §Step 3`
- [x] T020 [P] [US2] Create `.github/workflows/deploy.yml`: use the reference YAML from `contracts/deployment-workflow.md §Reference Workflow Structure` as the canonical source; ensure `permissions: id-token: write` and `contents: read` are set at the job level → `plan.md §Phase 4`, `contracts/deployment-workflow.md §Reference Workflow Structure`
- [x] T021 [US2] Verify all 4 workflow invariants in `.github/workflows/deploy.yml` before committing: (1) only `./dist` synced, (2) invalidation path is exactly `"/dcv/*"`, (3) `id-token: write` is present, (4) no `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` in file → `contracts/deployment-workflow.md §Invariants`
- [ ] T022 [US2] Push the `004-aws-deployment` branch changes to `main` (or open PR and merge); monitor GitHub Actions run and confirm all 7 steps succeed in sequence → `quickstart.md §Step 4`, `contracts/deployment-workflow.md §Pipeline Step Contract`
- [ ] T023 [US2] Smoke test the live site: `curl -I https://apps.microcode.io/dcv/` must return `HTTP/2 200` with `Content-Type: text/html`; `curl -I https://apps.microcode.io/dcv/_astro/<filename>.css` must return `HTTP/2 200` → `quickstart.md §Step 5`
- [ ] T024 [US2] Verify scoped invalidation: check CloudFront invalidation history in the AWS console and confirm the invalidation path is `/dcv/*` with no other paths (especially not `/*`) → `contracts/cdn-routing.md §Behavior 2 cache invalidation note`, `spec.md §User Story 2 Acceptance Scenario 4`

**Checkpoint**: US2 complete. Automated deployment pipeline live. Site accessible at `https://apps.microcode.io/dcv/`. Invalidation scope confirmed.

---

## Phase 5: User Story 3 — Secure Binary Distribution via CDN (Priority: P1)

**Goal**: CLI binary artifacts published to the binary S3 bucket are securely downloadable from `https://apps.microcode.io/dcv/releases/<version>/<filename>` over HTTPS, served via the binary behavior with a 1-year edge cache.

**Independent Test**: Make an HTTPS request to `https://apps.microcode.io/dcv/releases/<version>/<binary>` and verify `200 OK`. Make a second request and verify `X-Cache: Hit from cloudfront` in the response headers. Verify a direct S3 URL for the same object returns `403 AccessDenied`.

**Depends on**: Phase 3 (T015 — binary behavior must be provisioned). Requires at least one release artifact to be present in the binary bucket (coordinate with CLI project or upload a test binary manually).

**Note**: The binary publishing pipeline (`publish-release.sh`) is owned by the CLI project (Phase 24) and is out of scope here. Testing US3 may require manually uploading a test binary to `s3://<BIN_BUCKET>/v0.0.0-test/dcv-darwin-arm64` to validate the CDN routing without waiting for a real release.

### Implementation for User Story 3

- [x] T025 [US3] Write `DEPLOYMENT.md` at repository root: include all 6 sections defined in `plan.md §Phase 5` — routing diagram from `data-model.md §Entity Relationship Diagram`, behavior priority table from `data-model.md §CloudFront Distribution`, OAC access pattern, CF Function transformation logic, GitHub Secrets rotation guide, and manual deployment trigger instructions → `plan.md §Phase 5`, `spec.md FR-010`
- [ ] T026 [US3] Upload a placeholder binary to the binary bucket to enable smoke testing without waiting for the CLI project. Use a zero-byte file (sufficient to validate CDN routing): `aws s3 cp /dev/null s3://<BIN_BUCKET>/v0.0.0-test/dcv-darwin-arm64 --region <AWS_REGION>`. Then verify `https://apps.microcode.io/dcv/releases/v0.0.0-test/dcv-darwin-arm64` returns `200 OK` with a binary content-type. If a real release artifact is available from the CLI project, use that instead and clean up the placeholder → `quickstart.md §Step 6`, `contracts/cdn-routing.md §Behavior 1 Routing examples`
- [ ] T027 [US3] Verify binary CDN edge caching: make the same request a second time and confirm `X-Cache: Hit from cloudfront` header is present; verify a direct S3 URL for the binary returns `403 AccessDenied` (OAC enforcement) → `quickstart.md §Step 6`, `spec.md §User Story 3 Acceptance Scenario 3`

**Checkpoint**: US3 complete. All three user stories independently validated. Binary CDN routing and edge caching confirmed.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation sweep across all stories, security confirmation, and documentation review.

- [ ] T028 [P] Run the full `quickstart.md` verification sequence (Steps 1–6) end-to-end and confirm every expected output matches → `quickstart.md`
- [ ] T029 [P] Security audit: confirm both S3 buckets have "Block Public Access" enabled (all 4 settings) by checking the S3 console bucket settings — not just the bucket policy → `data-model.md §Website S3 Bucket`, `data-model.md §Binary S3 Bucket`
- [ ] T030 Verify CloudFront behavior priority ordering in the distribution console: `/dcv/releases/*` must be listed with a lower priority number than `/dcv/*`; swap if wrong and re-test → `contracts/cdn-routing.md §Invariants item 1`, `data-model.md §CloudFront Distribution behaviors table`
- [ ] T031 Verify cross-origin isolation for missing binaries: `curl -I https://apps.microcode.io/dcv/releases/v9.9.9/nonexistent` and confirm the response status is `403` or `404` AND the `Content-Type` header is NOT `text/html` (a `text/html` response would indicate the website behavior incorrectly handled the request instead of the binary behavior) → `spec.md §Edge Cases item 3`, `contracts/cdn-routing.md §HTTP Response Guarantees`

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup)
  └─→ Phase 2 (US1 — Astro config, local only)
  └─→ Phase 3 (AWS Infrastructure — parallel with Phase 2)
        └─→ Phase 4 (US2 — requires Phase 3 complete)
        └─→ Phase 5 (US3 — requires Phase 3 T015 complete)
              └─→ Phase 6 (Polish — requires all phases complete)
```

- **Phase 1**: No dependencies. Start immediately.
- **Phase 2 (US1)**: Depends only on Phase 1. Fully local. Can start immediately alongside Phase 3.
- **Phase 3**: Depends on Phase 1. AWS console work. Can proceed in parallel with Phase 2.
- **Phase 4 (US2)**: Depends on Phase 3 fully complete (all infra values known for secrets).
- **Phase 5 (US3)**: Depends on Phase 3 T015 complete (binary behavior provisioned).
- **Phase 6**: Depends on all prior phases. T031 (cross-origin isolation test) requires T015 and T016 (both behaviors provisioned) and a binary in the bucket (T026).

### Within Phase 3 — Infrastructure Sequencing

```
T005, T006 (S3 buckets)        [parallel]
  └─→ T007, T008 (OACs)        [parallel]
        └─→ T009, T010 (policies) [parallel]
              └─→ T011, T012 (origins) [parallel]
                    └─→ T015 (binary behavior)
                    └─→ T016 (website behavior — also needs T014)

T013 (create CF Function)      [parallel with all above]
  └─→ T014 (test CF Function)
        └─→ T016 (website behavior)

T017 (OIDC provider)           [parallel with all above]
  └─→ T018 (IAM role)
        → value needed for T019 (GitHub Secrets)
```

### User Story Dependencies

- **US1 (Phase 2)**: Independent. No dependency on US2 or US3.
- **US2 (Phase 4)**: Independent of US3. Depends on Phase 3.
- **US3 (Phase 5)**: Independent of US2. Depends on Phase 3 T015.

---

## Parallel Execution Examples

### Running Phase 2 (US1) and Phase 3 (Infra) together

```
Developer A (local machine):
  T002 → T003 → T004   (Astro config + local verification, ~20 min)

Developer B (AWS console):
  T005 + T006 → T007 + T008 → T009 + T010 → T011 + T012   (~45 min)
  T013 → T014 → T016   (CF Function, ~20 min)
  T015   (binary behavior, ~10 min)
  T017 → T018   (IAM, ~15 min)
```

### Phase 4 (US2) — T019 and T020 in parallel

```
T019: Add GitHub Secrets (3 values from Phase 3 notes)
T020: Write .github/workflows/deploy.yml  ← [P], no secrets needed to write the file
  → Both complete → T021 (verify invariants) → T022 (push + monitor CI)
```

---

## Implementation Strategy

### MVP: User Story 1 Only (no AWS required)

1. Complete Phase 1 (T001) — 2 min
2. Complete Phase 2 / US1 (T002–T004) — 20 min
3. **STOP AND VALIDATE**: Local dev + build output confirmed with `/dcv/` prefix
4. Commit `astro.config.mjs` changes — this is a shippable increment

### Full Deployment (all stories)

1. Phase 1 + Phase 2 in parallel → Astro config done + verified (T001–T004)
2. Phase 3 → AWS infra provisioned; record WEB_BUCKET, DISTRIBUTION_ID, AWS_ROLE_ARN (T005–T018)
3. Phase 4 → Secrets added, deploy.yml committed, first deployment live (T019–T024)
4. Phase 5 → DEPLOYMENT.md written, binary routing smoke tested (T025–T027)
5. Phase 6 → Final sweep (T028–T030)

---

## Notes

- **[P]** = genuinely parallel: different AWS resources or different files with no shared state
- **[AWS]** = AWS console or CLI operation; not a git commit; produces values used by later tasks
- **[Story]** label only appears in user story phases (2, 4, 5) — not in Setup, Foundational, or Polish
- Phase 3 tasks have no `[Story]` label because they are prerequisite infrastructure serving multiple stories
- T026 may require coordination with the CLI project team if no real release artifact exists yet
- If the GitHub OIDC Identity Provider already exists in the AWS account (previously registered), T017 can be skipped
- Commit after each Phase checkpoint — not after each individual task
