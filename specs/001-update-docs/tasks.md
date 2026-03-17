# Tasks: Sync Website Documentation to App v3.0.1

**Input**: Design documents from `/specs/001-update-docs/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: Not applicable — this feature is pure content authoring. Validation is manual (build + visual) and grep-based.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: Which user story this task belongs to ([US1], [US2], [US3], [US4])
- Exact file paths and source references included in every description

---

## Phase 1: Setup (Baseline Verification)

**Purpose**: Confirm the project builds cleanly before any changes are made. All subsequent tasks assume this passes.

- [x] T001 Run `npm run build` from repo root and confirm exit code 0; if it fails, diagnose and fix before proceeding — no content work starts until baseline build is green

**Checkpoint**: Build is green → content work can begin

---

## Phase 2: Foundational (installation.md Verification)

**Purpose**: Verify the install page — the very first page a new user reads — is accurate for v3.0.1 before updating the rest of the docs. No user story work is blocked by this phase; it can be worked alongside US4 immediately after the checkpoint above.

**What is currently in the file**: install script URL `https://apps.microcode.io/dcv/install.sh`; binary table: `dcv-macos-arm64`, `dcv-macos-x86_64`, `dcv-linux-x86_64`, `dcv-windows-x86_64.exe`; verification command `dcv --version`. See `plan.md` Phase 1 for the full verification checklist.

- [x] T002 Fetch `https://github.com/gcoonrod/dcv/releases` (or `https://github.com/gcoonrod/dcv/releases/tag/v3.0.1` directly) and record the exact names of all binary release assets for v3.0.1 — needed by T003
- [x] T003 Read `src/content/docs/installation.md`; compare binary names and install script URL against v3.0.1 assets found in T002; update only fields that differ from the release — preserve all other content and page structure; no frontmatter changes (order: 1 is already correct)

**Checkpoint**: Installation page reflects verified v3.0.1 assets → spec SC-001 (install commands work), SC-006 (page renders)

---

## Phase 3: User Story 1 — Accurate Quickstart Guide (Priority: P1) 🎯 MVP

**Goal**: Replace the current 3-step V1 guide with the full v3.0.1 init→fetch→curate→view→analyze workflow so a new user can follow the page and produce a report without consulting any other resource.

**Independent Test**: Read only the rewritten `quickstart.md` and manually execute each command against a dcv v3.0.1 installation in order; the final `dcv analyze` command produces a report file without errors.

### Implementation for User Story 1

- [x] T004 [P] [US1] Rewrite `src/content/docs/quickstart.md` — full replacement of current 3-step guide; keep frontmatter (title: "Quickstart", description: "Run your first dcv report in under 5 minutes.", order: 2); follow content structure from `plan.md` Phase 2 (Prerequisites, Step 1: init, Step 2: fetch with required --since/--until, Step 3: curate, Step 4: view, Step 5: analyze, Next Steps) — this order matches the canonical workflow in `dev-review-prep/docs/dcv.1` DESCRIPTION section and spec FR-001; use exact command signatures from `research.md` Decision 3; scope based on `research.md` Decision 6 (compare and query in Next Steps only); add links to /dcv/docs/configuration and /dcv/docs/categorization in Next Steps section

**Checkpoint**: A user following only the new Quickstart can run all 5 steps and generate a performance review → spec SC-004, SC-001

---

## Phase 4: User Story 2 — Accurate Configuration Reference (Priority: P2)

**Goal**: Replace the outdated V1/OpenAI configuration page with a complete V2 reference covering the multi-source schema, Anthropic provider, all 10 source types with correct tier labels, the category system, environment variables, migration path, and troubleshooting.

**Independent Test**: Copy every JSON snippet from the rewritten `configuration.md` into `~/.dcv/config.json` and run `dcv fetch --since ... --until ...`; dcv must accept the config without schema errors. Grep for "openai" — zero active references. Grep for V1 schema patterns — zero matches.

**Note**: Tasks T005–T007 write to the same file in sequence and must be done in order. The full source content is in `dev-review-prep/docs/configuration.md`.

### Implementation for User Story 2

- [x] T005 [US2] Rewrite `src/content/docs/configuration.md` — sections 1–3 only: (1) Quick Start (dcv init wizard intro), (2) Configuration File Structure (V2 schema with schema_version:2, sources[], providers[] — use the minimal example from dev-review-prep/docs/configuration.md lines 22–63), (3) Category System (optional category field on sources, default "professional", naming rules from `data-model.md` Category System Rules table, usage matrix showing --category flag across fetch/journal/analyze/query); keep frontmatter (title: "Configuration", description: "Configure dcv with ~/.dcv/config.json.", order: 3)
- [x] T006 [US2] Add Data Sources section to `src/content/docs/configuration.md` — document all 10 source types as subsections with required and optional fields; JSON configs drawn verbatim from `dev-review-prep/docs/configuration.md`; apply tier labels exactly per `research.md` Decision 2 table: GitHub (none), GitHub Enterprise (none), Local Git (none), Trello (none), Bitbucket `(Pro)`, Jira `(Pro)`, Linear `(Pro)`, Asana `(Pro)`, GitLab `(Pro) (Coming Soon)`, Azure DevOps `(Pro) (Coming Soon)`
- [x] T007 [US2] Add remaining sections to `src/content/docs/configuration.md` — in order: (5) LLM Providers: Anthropic only, with JSON from `research.md` Decision 4 (model IDs: claude-opus-4-6, claude-sonnet-4-6, claude-haiku-4-5); note OpenAI as `(Coming Soon)`; (6) Embedding Providers: Voyage AI, note required for dcv query and dcv index; (7) Environment Variables: all DCV_* overrides from `dev-review-prep/docs/configuration.md` Environment Variables section; (8) Secret Management: file permissions 600, best practices; (9) Migration V1→V2: dcv init wizard migration, backup to config.json.v1.bak, before/after JSON example from `dev-review-prep/docs/configuration.md` Migration section; (10) Troubleshooting: invalid category error, reserved keyword error, file permissions fix

**Checkpoint**: Zero OpenAI references as active provider; zero V1 schema patterns; all JSON snippets are valid V2 → spec SC-002, SC-003, SC-001

---

## Phase 5: User Story 3 — Context Categorization Guide (Priority: P3)

**Goal**: Create a new page that teaches users how to segregate professional and personal work using the category system, enabling them to generate a professional-only report without needing to consult any other page.

**Independent Test**: Follow only `categorization.md` steps 1–4 and produce a `dcv analyze --category professional` report from a config with two sources (one professional, one personal).

**⚠️ Dependency**: US2 (T005–T007) must be complete before this phase — `categorization.md` links to `/dcv/docs/configuration#category-system` for naming rules, which must already exist.

### Implementation for User Story 3

- [x] T008 [US3] Create `src/content/docs/categorization.md` — new file; frontmatter from `contracts/docs-frontmatter.md` (title: "Context Categorization", description: "Segregate work contexts and generate category-specific performance reviews.", order: 4); write sections: Overview, Prerequisites, Step 1 (configure source categories with JSON example), Step 2 (dcv fetch with categories — show artifact inheritance and mismatch detection prompt), Step 3 (journal with categories — show dcv journal -e "...", dcv journal --personal -e "...", dcv journal --category open-source -e "...", and resulting directory structure); primary content source: `dev-review-prep/docs/quickstart.md`; for category naming rules: link to /dcv/docs/configuration#category-system — do NOT restate the rules table
- [x] T009 [US3] Complete `src/content/docs/categorization.md` — remaining sections: Step 4 (dcv analyze --category professional --since ... --until ..., note omitting --category includes all), Step 5 (dcv query --category professional "..." and --category personal "..."), Common Workflows (quarterly work review, personal showcase, combined --category professional,open-source), Category Naming Guidelines (include valid and invalid naming examples inline from the "Category Naming Guidelines" section of `dev-review-prep/docs/quickstart.md` — these are practical examples and MAY be included here; they are distinct from the authoritative rules table in configuration.md which must NOT be duplicated), Troubleshooting (existing artifacts all "professional", recategorizing journal entries, listing categories via SQLite), Advanced section (comma-separated filters, shell aliases); all command signatures from `research.md` Decision 3; show --personal shorthand alongside --category personal in all relevant examples

**Checkpoint**: New page appears in nav at position 4 (between Configuration and Changelog); user can complete steps 1–4 and produce a professional-only report → spec SC-005, SC-006

---

## Phase 6: User Story 4 — Updated Changelog (Priority: P4)

**Goal**: Add a v3.0.1 changelog entry documenting all commands added since v1.0.0, the V2 schema change, and the migration path. Shift changelog to nav position 5.

**Independent Test**: Read the changelog and locate the v3.0.1 entry above the v1.0.0 entry; confirm all 9 new commands are listed, the V2 schema change is documented, and model IDs use the `claude-` prefix.

**Note**: This task is fully independent of US1, US2, and US3 and may be worked in parallel with any of them.

### Implementation for User Story 4

- [x] T010 [P] [US4] Update `src/content/docs/changelog.md` — two changes: (1) update frontmatter order from 4 to 5; (2) insert the v3.0.1 entry above the existing `## v1.0.0` entry (newest-first order); exact entry text is in `plan.md` Phase 5; verify model IDs use claude- prefix: claude-opus-4-6, claude-sonnet-4-6, claude-haiku-4-5; release date is 2026-03-07 per man page header in dev-review-prep/docs/dcv.1

**Checkpoint**: Changelog at nav position 5; v3.0.1 entry lists all 9 new commands with correct model IDs → spec FR-010, SC-006

---

## Phase 7: Polish & Cross-Cutting Verification

**Purpose**: End-to-end build verification and content accuracy checks against spec success criteria. Complete plan.md post-implementation checklist.

- [x] T011 Run `npm run build` from repo root — must exit 0; if Zod schema errors appear, fix the frontmatter field identified in the error message
- [ ] T012 Run `npm run preview` and open each docs page; verify sidebar nav order is exactly: Installation(1) → Quickstart(2) → Configuration(3) → Context Categorization(4) → Changelog(5)
- [x] T013 [P] Run `grep -ri "openai" src/content/docs/` — confirm zero matches that present OpenAI as an active/working provider (SC-002); any "(Coming Soon)" reference is acceptable
- [x] T014 [P] Run `grep -n '"github":' src/content/docs/configuration.md` and `grep -n '"providers": {' src/content/docs/configuration.md` — confirm zero matches (SC-003 — V1 schema patterns eliminated)
- [x] T015 [P] Run `grep -n "opus-4-6\|sonnet-4-6\|haiku-4-5" src/content/docs/` recursively — confirm every match uses the `claude-` prefix (e.g., `claude-opus-4-6`, not bare `opus-4-6`)
- [x] T016 Review and check off all items in `specs/001-update-docs/plan.md` Post-Implementation Verification section; additionally cross-check every `dcv` flag used in any code block across all 5 docs pages against `research.md` Decision 3 command signatures table — confirm no renamed or removed flags remain (addresses spec edge case: "What happens when a documentation page references a command flag that has been renamed or removed?"); mark the spec SC sign-off table complete

- [x] T017 [P] Audit FR-011: for each of the 5 docs pages (`installation.md`, `quickstart.md`, `configuration.md`, `categorization.md`, `changelog.md`), extract every `dcv` command example from code blocks and verify its flags and syntax match the corresponding entry in `research.md` Decision 3 command signatures table; flag any mismatch as a bug and fix it before marking complete
- [ ] T018 Manually execute the full Quickstart workflow against a real dcv v3.0.1 installation: run `dcv init`, `dcv fetch --since ... --until ...`, `dcv curate`, `dcv view`, `dcv analyze --since ... --until ...` in the order written on the updated `src/content/docs/quickstart.md` page; confirm each command succeeds and the final output is a generated report (spec SC-001, SC-004)

**Checkpoint**: All 6 success criteria from spec.md (SC-001 through SC-006) are satisfied → branch ready for PR

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T001) — can overlap with US4 (T010) in practice
- **US1 (Phase 3)**: Depends on Phase 1 only — independent of US2, US3, US4
- **US2 (Phase 4)**: Depends on Phase 1 only — independent of US1, US4; **US3 depends on US2**
- **US3 (Phase 5)**: Depends on US2 completion (T007 must be done before T008)
- **US4 (Phase 6)**: Depends on Phase 1 only — fully independent of all user stories
- **Polish (Phase 7)**: Depends on all phases complete

### User Story Dependencies

- **US1 (P1)**: No story dependencies — can start after Phase 1
- **US2 (P2)**: No story dependencies — can start after Phase 1 (in parallel with US1)
- **US3 (P3)**: Depends on US2 complete — categorization.md links into configuration.md#category-system
- **US4 (P4)**: No story dependencies — can start after Phase 1 (in parallel with US1 and US2)

### Within Each User Story

- US2: T005 → T006 → T007 (sequential — all write to same file, building the page section by section)
- US3: T008 → T009 (sequential — both write to same file)
- All others: single tasks per story

---

## Parallel Opportunities

### After Phase 1 (T001 complete), these tasks can run simultaneously

```text
Track A: T002 → T003  (installation.md verification)
Track B: T004         (US1 quickstart rewrite)
Track C: T005 → T006 → T007  (US2 configuration rewrite)
Track D: T010         (US4 changelog update)
```

Then once Track C (US2) is complete:
```text
Track E: T008 → T009  (US3 categorization guide — depends on US2)
```

### Polish phase (parallel group A — grep/audit tasks)
```text
T013, T014, T015, T017  (grep/audit verification tasks — independent, different search patterns/pages)
```

### Polish phase (sequential after content is stable)
```text
T018  (manual command execution — depends on T004 content being final)
```

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. Complete Phase 1: T001 (build verification)
2. Complete Phase 3: T004 (quickstart rewrite)
3. **STOP and VALIDATE**: Run `npm run build`; walk through quickstart steps manually
4. The most critical user-facing gap (broken quickstart) is fixed

### Incremental Delivery

1. Phase 1 (T001) → baseline confirmed
2. Phase 3 (T004) → US1 complete, Quickstart accurate *(highest impact, do first)*
3. Phase 6 (T010) → US4 complete, Changelog updated *(fastest task, can pair with any phase)*
4. Phase 2 (T002→T003) → installation verified
5. Phase 4 (T005→T006→T007) → US2 complete, Configuration accurate
6. Phase 5 (T008→T009) → US3 complete, Categorization guide live
7. Phase 7 (T011→T018) → all success criteria verified

### Parallel Strategy (Two Implementers)

With two implementers after Phase 1:
- **Implementer A**: US1 (T004) → US2 (T005, T006, T007) → US3 (T008, T009)
- **Implementer B**: Foundational (T002, T003) → US4 (T010) → Polish (T011–T018)

---

## Notes

- [P] tasks operate on different files or are independent grep commands — safe to parallelize
- US3 (T008–T009) has a hard dependency on US2 completing first — do not start T008 before T007 is committed
- The `dev-review-prep/docs/` directory at `/Users/greg.coonrod/dev/personal/claude/dev-review-prep/docs/` is the authoritative source for all content; pull JSON examples verbatim from there rather than reconstructing from memory
- `research.md` Decision 3 is the single source of truth for command signatures — verify every command against it before writing
- Category naming rules live in `data-model.md` Category System Rules table — both configuration.md and categorization.md draw from this table; do not let the two pages diverge
- Commit after each task or logical group; each story phase produces a standalone deliverable
