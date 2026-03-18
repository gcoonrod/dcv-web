# Tasks: DCV Web Install Script

**Input**: Design documents from `/specs/006-install-script/`
**Branch**: `006-install-script`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/install-sh-interface.md, contracts/releases-folder-structure.md, quickstart.md

**Tests**: No automated test tasks — this feature uses manual cross-platform validation per `quickstart.md` §Cross-Platform Verification. Each phase checkpoint defines the manual test to run.

**Single-file note**: All implementation tasks target `public/install.sh`. Tasks represent sections or layers of the script, not separate files. Each completed phase leaves the script in a runnable state. TODO comments inserted in early phases serve as integration points for later phases.

## Format: `[ID] [P?] [Story] Description with file path`

- **[P]**: Can run in parallel (no shared-state dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- All tasks target `public/install.sh` unless a different path is stated

---

## Phase 1: Setup (Script Skeleton)

**Purpose**: Create the script file with shebang, constants, and the shared `die()` helper before any section-level work begins.

- [x] T001 Create `public/install.sh` with `#!/bin/sh`, `set -eu`, a top-of-file banner comment block (script name, one-line purpose, usage: `curl -fsSL https://apps.microcode.io/dcv/install.sh | sh`, supported platforms: macOS Intel/Apple Silicon · Linux x86_64/ARM64 · WSL2), and define `BASE_URL="https://apps.microcode.io/dcv/releases/latest"` as the only constant
- [x] T002 Implement `die()` helper function in `public/install.sh` — accepts a message string argument (may contain `\n` escape sequences for multi-line output); write to stderr using `printf 'Error: %b\n' "$1" >&2` so `\n` escapes are interpreted as newlines (POSIX `%b` behavior); exit 1; this is the single error-exit mechanism used by all failure paths throughout the script

**Checkpoint**: `sh -n public/install.sh` passes (syntax check); file exists and has correct shebang.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared infrastructure that MUST exist before any user story section can be implemented. The `SHA256_CMD` variable set here is consumed by both the idempotency check (US4, step 4) and the checksum verification (US2, step 8).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T003 Implement the prerequisite checker section in `public/install.sh` — print `==> Checking prerequisites...`; using `command -v` (not `which`), verify `curl` and `openssl` are on PATH; for each missing tool, call `die()` with the exact message format from `contracts/install-sh-interface.md` §Prerequisites including per-platform install hints (macOS: `brew install <tool>`, Ubuntu: `sudo apt-get install <tool>`, Alpine: `apk add <tool>`)
- [x] T004 Implement SHA-256 tool detection within the prerequisite checker section in `public/install.sh` — set `SHA256_CMD` by trying `command -v sha256sum` first (Linux/GNU coreutils), then `command -v shasum` (macOS, will be called as `shasum -a 256`); if neither is found, call `die()` with an actionable message; integrate this as the third check in T003's section, not as a standalone section — see `research.md` Decision 2 for the full detection pattern

**Checkpoint**: Script exits 1 with actionable messages when `curl`, `openssl`, or a SHA-256 tool is absent. `sh -n public/install.sh` passes.

---

## Phase 3: User Story 1 — Happy-Path Installation (Priority: P1) 🎯 MVP

**Goal**: A user on macOS or Linux runs the one-liner and gets a working `dcv` binary installed to `~/.local/bin` with step-by-step progress output and shell-specific PATH guidance if needed.

**Independent Test**: Serve mock artifacts locally (`npx serve /tmp/test-releases -l 3000`, see `quickstart.md` §5 Option B). Temporarily set `BASE_URL` to `http://localhost:3000` in the script. Run `sh public/install.sh`. Verify `~/.local/bin/dcv` is installed and executable. Signature and checksum verification are skipped at this phase — T013/T014 add them. Confirm the progress output matches `contracts/install-sh-interface.md` §Stdout exactly.

> **Implementation note**: US1 tasks insert TODO comments at the two points where US2 and US4 will later inject code. These comments are load-bearing — do not remove them until the corresponding phase tasks do so.

- [x] T005 [US1] Implement platform detection section in `public/install.sh` — print `==> Detecting platform...`; run `uname -s` into `OS_RAW` and `uname -m` into `ARCH_RAW`; use `case` (not `[[ ]]`) to normalize: `Darwin` → `OS=darwin`, `Linux` → `OS=linux`, anything else → `die()` with supported-OS list; normalize arch: `arm64`/`aarch64` → `ARCH=arm64`, `x86_64` → `ARCH=x64`, anything else → `die()` with supported-arch list; print `(${OS} ${ARCH})` inline with the progress line; set `BINARY_NAME="dcv-${OS}-${ARCH}"` — see `data-model.md` §Platform Identity for the full matrix and error message wording
- [x] T006 [US1] Implement install directory resolution section in `public/install.sh` — print `==> Resolving install directory...`; set `INSTALL_DIR` from `${DCV_INSTALL_PATH:-$HOME/.local/bin}` and `INSTALL_PATH="${INSTALL_DIR}/dcv"`; run `mkdir -p "${INSTALL_DIR}"`; verify writability with `[ -w "${INSTALL_DIR}" ]`, call `die()` with a permission error identifying the path if not writable; print `(${INSTALL_DIR})` inline with the progress line — see `data-model.md` §Installation Target and `contracts/install-sh-interface.md` §Environment Variables
- [x] T007 [US1] Insert the idempotency check placeholder and implement WORK_DIR creation in `public/install.sh` — first insert a clearly-marked comment block `# ── Idempotency check (implemented in US4) ─────────────────────────────` as a placeholder at the correct position (after install dir resolution, per `plan.md` step 4); then below it, implement WORK_DIR: `WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dcv-install.XXXXXX")"` immediately followed by `trap 'rm -rf "${WORK_DIR}"' EXIT INT TERM` — see `research.md` Decision 6
- [x] T008 [US1] Implement binary download section in `public/install.sh` — print `==> Downloading ${BINARY_NAME}...`; run `curl -fsSL "${BASE_URL}/${BINARY_NAME}" -o "${WORK_DIR}/${BINARY_NAME}"`; on curl failure call `die()` with the URL and a "check your network connection and retry" instruction; after download, verify the file is non-empty with `[ -s "${WORK_DIR}/${BINARY_NAME}" ]` and call `die()` with `"Release artifact not found at ${BASE_URL}/${BINARY_NAME}. Check https://apps.microcode.io/dcv/releases/latest/ manually."` if empty — see `contracts/releases-folder-structure.md` §Required Files
- [x] T009 [US1] Insert the verification placeholder and implement atomic install in `public/install.sh` — first insert a clearly-marked comment block `# ── Signature and checksum verification (implemented in US2) ──────────────` as a placeholder between the downloads and the install; then below it, implement atomic install: `chmod +x "${WORK_DIR}/${BINARY_NAME}"` followed by `mv "${WORK_DIR}/${BINARY_NAME}" "${INSTALL_PATH}"`; print `==> Installing to ${INSTALL_PATH}...` before the chmod — see `plan.md` step 9
- [x] T010 [US1] Implement PATH guidance section in `public/install.sh` — only execute when `DCV_INSTALL_PATH` is unset (`[ -z "${DCV_INSTALL_PATH:-}" ]`); check membership with `case ":${PATH}:"` in `*":${INSTALL_DIR}:"*)`; when absent, map `$SHELL` to an RC file using `case`: `*/zsh` → `~/.zshrc`, `*/bash` → `~/.bashrc`, `*/fish` → use `fish_add_path "$HOME/.local/bin"` (not export syntax — fish does not support `export PATH=`), `*` → generic export instruction without a specific filename; emit the guidance format from `contracts/install-sh-interface.md` §Stdout — see `plan.md` step 10 for the complete POSIX-safe pattern
- [x] T011 [US1] Implement success message in `public/install.sh` — print blank line, `dcv installed successfully!`, blank line, `To verify: dcv --version` per `contracts/install-sh-interface.md` §Stdout; confirm the full US1 script flow (T005 through T011) is in the correct order and `sh -n public/install.sh` passes

**Checkpoint**: On a test machine with mock binary artifacts (sig/checksum not yet verified), `sh public/install.sh` produces the correct progress output and installs the binary to `~/.local/bin/dcv`. PATH guidance appears only when the directory is absent from `$PATH`.

---

## Phase 4: User Story 2 — Checksum and Signature Verification (Priority: P2)

**Goal**: The script verifies the cryptographic signature on `SHA256SUMS` and the SHA-256 checksum on the downloaded binary before installing anything, rejecting tampered or corrupted artifacts.

**Independent Test**: Using the key pair from `quickstart.md` §2, create signed mock artifacts per §3. Run the script — it should verify and install. Then corrupt the mock binary (change one byte) and re-run — should abort with a checksum mismatch error. Then sign `SHA256SUMS` with a different private key and re-run — should abort with a tamper warning. In all failure cases, confirm `~/.local/bin/dcv` is NOT written and no temp files remain.

- [x] T012 [US2] Extend the download section (T008) in `public/install.sh` — after the binary download, add two additional `curl -fsSL` calls: `"${BASE_URL}/SHA256SUMS"` → `"${WORK_DIR}/SHA256SUMS"` and `"${BASE_URL}/SHA256SUMS.sig"` → `"${WORK_DIR}/SHA256SUMS.sig"`; call `die()` on any curl failure with the specific URL that failed; verify each file is non-empty with `[ -s ]` as with the binary download — see `contracts/releases-folder-structure.md` §Required Files
- [x] T013 [US2] Implement embedded public key and signature verification in `public/install.sh`, replacing the `# ── Signature and checksum verification` placeholder comment (inserted in T009) — add a heredoc that writes the public key to `${WORK_DIR}/pubkey.pem` using the exact placeholder block from `plan.md` step 7 (with `# TODO(build-pipeline): Replace <PUBLIC_KEY_PLACEHOLDER>...` comment); run `openssl dgst -sha256 -verify "${WORK_DIR}/pubkey.pem" -signature "${WORK_DIR}/SHA256SUMS.sig" "${WORK_DIR}/SHA256SUMS"`; on failure call `die()` with the tamper-warning message from `contracts/install-sh-interface.md` §Stderr; print `==> Verifying signature...` before the openssl call — see `research.md` Decision 1 for the exact command syntax
- [x] T014 [US2] Implement the 3-step checksum comparison in `public/install.sh`, immediately after the signature verification (T013) — step 1: `EXPECTED_HASH="$(grep "${BINARY_NAME}" "${WORK_DIR}/SHA256SUMS" | awk '{print $1}')"`, step 2: `ACTUAL_HASH="$(${SHA256_CMD} "${WORK_DIR}/${BINARY_NAME}" | awk '{print $1}')"`, step 3: compare with `[ "${EXPECTED_HASH}" != "${ACTUAL_HASH}" ]` and call `die()` with `"Checksum mismatch for ${BINARY_NAME}.\nExpected: ${EXPECTED_HASH}\nGot:      ${ACTUAL_HASH}\nThis may indicate a corrupted download. Re-run the install command to try again."`; print `==> Verifying checksum...` before step 1 — see `plan.md` step 8 for the fully assembled pattern and `contracts/install-sh-interface.md` §Stderr for exact wording
- [x] T015 [US2] Remove the `# ── Signature and checksum verification` placeholder comment (it is now replaced by T013 and T014) and confirm the complete flow in `public/install.sh` is: downloads (T008+T012) → sig verify (T013) → checksum verify (T014) → atomic install (T009); run `sh -n public/install.sh` to confirm syntax

**Checkpoint**: With properly signed mock artifacts (`quickstart.md` §2–3), the script verifies both signature and checksum and installs. A bad signature or corrupted binary produces the correct error message, no binary is installed, and no temp files remain.

---

## Phase 5: User Story 3 — Early Failure on Unsupported / Misconfigured Environments (Priority: P3)

**Goal**: Every failure mode exits immediately with a human-readable `Error:` message and an actionable resolution step — no silent failures, no partial installs.

**Independent Test**: Verify each condition from `quickstart.md` acceptance checklist items 7–11: missing curl, missing openssl, unsupported OS (mock via `PATH` override), unsupported arch (mock with a wrapper script), network failure (point `BASE_URL` at a non-existent host). Each must exit 1 with a message matching the format in `contracts/install-sh-interface.md` §Stderr before any file is downloaded.

- [x] T016 [US3] Audit every `die()` call site in `public/install.sh` against the exact two-line format from `contracts/install-sh-interface.md` §Stderr — format is `Error: <description>` followed by `<action>` (e.g., `Install curl:` followed by package manager commands); update any messages that have only one line, use a different prefix, or lack an actionable instruction; ensure the unsupported-arch and unsupported-OS messages list the supported values
- [x] T017 [US3] Add inline comment blocks above each major section in `public/install.sh` per FR-015 — one multi-line comment per execution step (prerequisite check, platform detection, install directory resolution, idempotency check placeholder, WORK_DIR setup, binary download, SHA256SUMS download, signature verification, checksum verification, atomic install, PATH guidance, success message); comments must explain what the section does and reference the relevant requirement (e.g., `# FR-007: Verify SHA256SUMS signature using embedded public key`)

**Checkpoint**: Running the script with each simulated failure condition (removed tool from PATH, unsupported uname output) produces a `Error:` message before any curl call is made. The `sh -n` check passes.

---

## Phase 6: User Story 4 — Re-Installation / Upgrade on Existing Installation (Priority: P4)

**Goal**: Re-running the script on a machine with dcv already installed either exits cleanly with "already up to date" (no files written) or replaces the binary and reports the upgrade.

**Independent Test**: Install a mock binary. Re-run the script with the same mock artifacts — should print `==> Checking installed version...` then "dcv is already up to date at \<path\>" and exit 0. Replace the mock binary in the releases folder with a different file (different checksum). Re-run — should replace `~/.local/bin/dcv` and print "dcv updated successfully!". After each run, confirm no temp files remain under `/tmp/dcv-*` or `$TMPDIR`.

- [x] T018 [US4] Implement the idempotency check in `public/install.sh`, replacing the `# ── Idempotency check` placeholder comment (T007) — check `[ -f "${INSTALL_PATH}" ]`; if true, print `==> Checking installed version...`; download only `SHA256SUMS` to `TMP_SUMS="$(mktemp "${TMPDIR:-/tmp}/dcv-sums.XXXXXX")"` with `trap 'rm -f "${TMP_SUMS}"' EXIT INT TERM`; extract `LATEST_HASH` via `grep "${BINARY_NAME}" "${TMP_SUMS}" | awk '{print $1}'`; compute `INSTALLED_HASH` via `${SHA256_CMD} "${INSTALL_PATH}" | awk '{print $1}'`; if equal, print "dcv is already up to date at ${INSTALL_PATH}" and exit 0; see `plan.md` step 4 for the complete code pattern and the security decision rationale for why sig verification is intentionally skipped here
- [x] T019 [US4] Supersede the TMP_SUMS cleanup trap in `public/install.sh` — when WORK_DIR is created (the section from T007, now executed only when the idempotency check finds an outdated or absent binary), register a new combined trap that removes both: `trap 'rm -f "${TMP_SUMS:-}"; rm -rf "${WORK_DIR}"' EXIT INT TERM`; this supersedes the earlier `TMP_SUMS`-only trap; add a comment explaining the supersession — see `plan.md` step 5 trap-superseding note
- [x] T020 [US4] Add upgrade-detection messaging in `public/install.sh` — when the idempotency check finds the binary exists but hashes differ, print `==> Checking installed version... (update available)` before continuing to WORK_DIR creation; after the atomic install (T009), branch on whether this was a fresh install or an upgrade to print either "dcv installed successfully!" or "dcv updated successfully!" per `contracts/install-sh-interface.md` §Stdout; use a flag variable (e.g., `UPGRADE=1`) set in the idempotency check block to distinguish the two cases
- [x] T021 [US4] Remove the `# ── Idempotency check` placeholder comment (now replaced by T018) and confirm the complete top-to-bottom script flow in `public/install.sh` is: prereq check → platform detect → install dir resolve → idempotency check (exit 0 or continue) → WORK_DIR + trap → download binary + SHA256SUMS + SHA256SUMS.sig → sig verify → checksum verify → atomic install → PATH guidance → success message; run `sh -n public/install.sh`

**Checkpoint**: Second run with identical mock artifacts exits 0, prints "already up to date", writes no files. A swapped mock release triggers the upgrade path. No temp files under `$TMPDIR` after either run.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Lint gate, acceptance checklist validation, and any remaining documentation.

- [x] T022 Run `shellcheck --shell=sh public/install.sh` (install via `brew install shellcheck` or `apt-get install shellcheck` — see `quickstart.md` §4); fix every warning and error until the command exits 0 with no output; this is the hard gate from `plan.md` §Step 0 Lint Gate — the script MUST NOT be merged with any shellcheck warnings
- [x] T023 [P] Validate `public/install.sh` against all 15 items in the `quickstart.md` §Acceptance Checklist — run each scenario manually and mark each item pass/fail; document any failures as issues before merging
- [x] T024 [P] Update `specs/006-install-script/plan.md` to note `tasks.md` is generated and record any deviations from the plan discovered during implementation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — blocks all user story phases
- **US1 (Phase 3)**: Depends on Phase 2 — sequential within phase (T005 → T006 → T007 → T008 → T009 → T010 → T011)
- **US2 (Phase 4)**: Depends on Phase 3 — adds downloads and verification between T008 and T009
- **US3 (Phase 5)**: Depends on Phase 3 — audits `die()` call sites that US1 creates
- **US4 (Phase 6)**: Depends on Phase 3 — inserts idempotency check before the WORK_DIR created in T007
- **Polish (Final Phase)**: Depends on all desired user stories complete

### User Story Dependencies

Single-file constraint: because all stories target `public/install.sh`, they cannot run in parallel on the same branch without merge conflicts. Sequencing recommendation:

- **US1** first — establishes the complete install flow; all other stories extend it
- **US2, US3, US4** — can be worked simultaneously on separate branches after US1 merges, since they target different sections of the file:
  - US2 inserts into the download section (between T008 and T009)
  - US3 edits error messages and adds comments throughout
  - US4 inserts before the WORK_DIR creation (T007)

### Within Each User Story

- US1: T005 → T006 → T007 → T008 → T009 → T010 → T011 (each section depends on the prior)
- US2: T012 → T013 → T014 → T015 (download extensions → sig → checksum → integrate)
- US3: T016 → T017 (audit errors → add comments)
- US4: T018 → T019 → T020 → T021 (implement check → fix trap → add messaging → integrate)
- Polish: T022 first (lint must pass); T023 and T024 in parallel after T022

### Parallel Opportunities

- T023 and T024 (Polish phase) can run simultaneously
- US2, US3, US4 can each be developed on parallel branches after US1 is merged

---

## Parallel Example: Polish Phase

```bash
# These two run simultaneously after T022 (shellcheck) passes:
Task: "Validate public/install.sh against quickstart.md acceptance checklist"
Task: "Update specs/006-install-script/plan.md to mark tasks.md generated"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup — script skeleton
2. Complete Phase 2: Foundational — prereq checking + SHA256_CMD
3. Complete Phase 3: User Story 1 — full happy-path flow (no security verification)
4. **STOP and VALIDATE**: Run against mock artifacts, confirm binary installs, progress output matches contract
5. Proceed to US2 to add security verification

### Incremental Delivery

1. Setup + Foundational → skeleton with prereq checking in place
2. + US1 → working install flow (no sig/checksum verification yet)
3. + US2 → full cryptographic verification (sig + checksum)
4. + US3 → all error paths hardened and comment-documented
5. + US4 → idempotency / upgrade detection
6. + Polish → shellcheck clean, 15-item acceptance checklist verified

### Notes on TODO Comment Integration Points

Two TODO comments inserted in Phase 3 (US1) act as precise integration targets for later phases:

| Comment | Inserted by | Replaced by |
|---------|-------------|-------------|
| `# ── Idempotency check` | T007 | T018+T021 (US4) |
| `# ── Signature and checksum verification` | T009 | T013+T015 (US2) |

When working on US2 or US4 on a parallel branch, search for these comments to find the exact insertion point. Do not remove them until the corresponding integration task (T015, T021) does so.
