# Feature Specification: DCV Web Install Script

**Feature Branch**: `006-install-script`
**Created**: 2026-03-17
**Status**: Draft
**Input**: User description: "The dcv-web application states that users should execute `curl -fsSL https://apps.microcode.io/dcv/install.sh | sh` to install dcv. Implement and deploy this script as part of the dcv-web project. Must work on Linux, macOS, and Windows WSL. Must fetch the latest binary from https://apps.microcode.io/dcv/releases/latest. Must verify checksums and signatures. Should fail early with clear error messages, provide progress output, and work without superuser privileges."

## Overview

The install script is the primary onboarding mechanism for new dcv users. When a user visits the dcv website and sees the one-liner install command (`curl -fsSL https://apps.microcode.io/dcv/install.sh | sh`), running that command should reliably install dcv on their system — from detecting their platform through to a working binary in their PATH — with clear progress feedback and zero need for administrator access.

## Clarifications

### Session 2026-03-17

- Q: Where should the signing public key be stored and distributed? → A: Embed the public key directly in `install.sh` — trust anchored to HTTPS delivery of the script itself (Option A).
- Q: Should the script retry transient network failures automatically? → A: No retries — fail immediately with an actionable message (Option A). The script MUST also be fully idempotent: running it multiple times must always produce the same end state with no leftover artifacts.
- Q: Should users be able to override the install directory? → A: Yes — via the `DCV_INSTALL_PATH` environment variable; defaults to `~/.local/bin` if unset.
- Q: What format does the releases endpoint serve? → A: `/releases/latest` is a folder that always contains the latest binary artifacts and checksums directly — no version metadata fetch required. The script constructs download URLs by appending the platform-specific filename (e.g., `/releases/latest/dcv-linux-x64`).
- Q: What is the minimum shell compatibility target? → A: POSIX `sh` — `#!/bin/sh` with `set -eu`. No bash-specific syntax. Compatible with `dash`, `ash`, `busybox sh`, and stock macOS `sh`.
- Q: Should the Hero component install command snippet be updated to reflect the `sh` target? → A: Yes — the displayed one-liner on the website MUST use `sh` instead of `bash` (i.e., `curl -fsSL https://apps.microcode.io/dcv/install.sh | sh`).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Happy-Path Installation on Supported Platform (Priority: P1)

A developer on a supported platform (macOS, Linux, or Windows WSL) runs the one-liner install command in their terminal for the first time and gets dcv installed and ready to use without any manual steps or elevated privileges.

**Why this priority**: This is the single most important user journey — it is the gateway to every other dcv feature. If this fails, users cannot adopt the product. P1 because it has zero viable fallback; a broken installer blocks all downstream usage.

**Independent Test**: Can be fully tested by running the install command on a clean supported platform and verifying `dcv --version` works afterward — delivers a fully installed, usable tool with no other stories required.

**Acceptance Scenarios**:

1. **Given** a macOS machine (Intel or Apple Silicon) with `curl` available and no prior dcv installation, **When** the user runs `curl -fsSL https://apps.microcode.io/dcv/install.sh | sh`, **Then** the script outputs step-by-step progress, downloads the correct binary for the platform, verifies its integrity, installs it to `~/.local/bin/dcv` (the default install path), and exits with a success message showing how to verify the install.
2. **Given** a Linux (x86_64 or ARM64) machine with `curl` available and no prior dcv installation, **When** the user runs the install command, **Then** the same successful outcome occurs as on macOS.
3. **Given** a Windows machine running WSL2 with `curl` available, **When** the user runs the install command inside the WSL terminal, **Then** dcv installs successfully and is accessible from the WSL shell.
4. **Given** a CI/CD environment where `DCV_INSTALL_PATH=/usr/local/bin` is set, **When** the install command is run, **Then** the binary is installed to the specified path, no default PATH guidance is shown, and the script exits cleanly.
5. **Given** a successful installation where `~/.local/bin` is already in the user's `PATH`, **When** the script completes, **Then** the user is told to run `dcv --version` to confirm, and no PATH modification guidance is shown.
6. **Given** a successful installation where `~/.local/bin` is NOT in the user's `PATH`, **When** the script completes, **Then** the user is shown the exact line to add to their shell configuration file (e.g., `~/.zshrc`, `~/.bashrc`) and told to restart their shell or source the file.

---

### User Story 2 - Checksum and Signature Verification (Priority: P2)

After downloading the dcv binary, the install script automatically verifies that the file has not been tampered with or corrupted — both by comparing its cryptographic checksum and by validating the signature on the checksum file — before installing anything.

**Why this priority**: Security integrity is fundamental to a tool developers trust with their environment. Verification prevents supply-chain attacks and silent download corruption. P2 because it must be present for any production-quality install, but the happy path (P1) defines the structure that P2 adds security to.

**Independent Test**: Can be tested by intercepting the download and providing a binary that does not match the published checksum — the script must abort with a clear error message and not install anything.

**Acceptance Scenarios**:

1. **Given** a successful download where the binary matches the published SHA-256 checksum, **When** verification runs, **Then** the script outputs a "checksum verified" message and continues to installation.
2. **Given** a download where the binary does NOT match the published checksum (e.g., corrupted download), **When** verification runs, **Then** the script aborts immediately, outputs a clear error identifying the mismatch, removes any partially downloaded files, and exits with a non-zero code.
3. **Given** a checksum file whose cryptographic signature does not match the published signing key, **When** signature verification runs, **Then** the script aborts immediately, outputs a warning that the release may have been tampered with, and exits with a non-zero code.
4. **Given** a platform where the verification tool (e.g., `sha256sum`, `shasum`) is not available, **When** the script runs, **Then** it reports the missing dependency clearly and exits with an actionable message.

---

### User Story 3 - Early Failure on Unsupported or Misconfigured Environments (Priority: P3)

On platforms or configurations that dcv does not support, the install script fails immediately with a human-readable explanation and actionable guidance — rather than partially executing and leaving the system in an unknown state.

**Why this priority**: Developer trust depends on predictable tooling. Silent partial installs or cryptic error codes damage confidence. P3 because it is a defensive scenario — the P1 and P2 stories cover the positive path; this story covers what happens when that path is blocked.

**Independent Test**: Can be tested by simulating each unsupported condition (unknown OS, unsupported architecture, missing `curl`) and verifying the script exits immediately with a useful message before any files are downloaded or written.

**Acceptance Scenarios**:

1. **Given** a system running an unsupported OS (e.g., native Windows CMD without WSL), **When** the script is executed, **Then** it detects the unsupported environment, outputs which OSes are supported, and exits immediately without downloading anything.
2. **Given** a system with an unsupported CPU architecture (e.g., 32-bit x86), **When** the script runs, **Then** it exits with a message listing supported architectures.
3. **Given** a system where `curl` is not installed, **When** the script runs, **Then** it outputs a dependency error and suggests how to install `curl` for common package managers.
4. **Given** a network failure during the binary download, **When** the download fails, **Then** the script exits with an error describing what it was trying to fetch and suggests checking connectivity or retrying.
5. **Given** a fetch from `releases/latest/` that returns a 404 or empty response, **When** the script processes the response, **Then** it exits with an error explaining that the release artifact could not be found, and provides the releases base URL for manual inspection.

---

### User Story 4 - Re-Installation / Upgrade on Existing Installation (Priority: P4)

A user who has previously installed dcv runs the install command again to get the latest version. The script detects the existing installation and either upgrades it or informs the user of the outcome.

**Why this priority**: Tool maintainability matters — users should be able to stay current with one repeatable command. P4 because it is an enhancement over the baseline install; an MVP that only supports fresh installs still delivers significant value.

**Independent Test**: Can be tested by installing a prior version and re-running the install command, then verifying `dcv --version` reports the new version.

**Acceptance Scenarios**:

1. **Given** an existing dcv installation whose checksum differs from the latest published checksum, **When** the install command is re-run, **Then** the script downloads the latest binary, verifies its integrity, replaces the existing binary, and reports that dcv was updated.
2. **Given** an existing dcv installation whose checksum matches the latest published checksum, **When** the install command is re-run, **Then** the script reports that dcv is already up to date and exits without making any changes (idempotent — no files written).

---

### Edge Cases

- What happens when the install directory (`DCV_INSTALL_PATH` or `~/.local/bin`) does not exist yet? The script must create it before installing.
- What happens when `DCV_INSTALL_PATH` is set to a path requiring root access? The script must attempt the install and report a clear permission error if it fails — no automatic privilege escalation.
- What happens when the install directory is not writable (e.g., permissions issue)? The script must report a clear error identifying the directory and the permission problem.
- What happens when the releases endpoint returns a redirect? The script must follow redirects correctly.
- What happens when the user interrupts the script mid-download (Ctrl-C)? Partially downloaded files must be cleaned up to avoid leaving artifacts.
- What happens on a system that has `sha256sum` (Linux) vs `shasum` (macOS)? The script must detect and use the appropriate tool.
- What happens when the user's shell is `fish` or another non-POSIX shell? PATH guidance should fall back to a generic instruction.
- What happens when the script is run a second time with no new version available? It must exit cleanly with a "already up to date" message and zero side effects (idempotent — see FR-018).
- What happens when a failed install left a partial binary at `~/.local/bin/dcv`? The script must overwrite it safely, since FR-018 requires the same outcome regardless of prior run count.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The install script MUST be served at `https://apps.microcode.io/dcv/install.sh` as part of the dcv-web static site deployment.
- **FR-002**: The script MUST detect the operating system and CPU architecture of the host system before downloading anything.
- **FR-003**: The script MUST support macOS (Apple Silicon and Intel), Linux (x86_64 and ARM64), and Windows WSL environments.
- **FR-004**: The script MUST construct download URLs by appending the platform-specific binary filename to the base path `https://apps.microcode.io/dcv/releases/latest/` (e.g., `dcv-linux-x64`, `dcv-darwin-arm64`). No separate version-fetch step is required — `/releases/latest/` always serves the current release artifacts.
- **FR-005**: The script MUST download only the binary appropriate for the detected OS and architecture combination.
- **FR-006**: The script MUST verify the SHA-256 checksum of the downloaded binary against a published checksum file for the release.
- **FR-007**: The script MUST verify the cryptographic signature on the checksum file using a public key embedded directly in `install.sh` before trusting the checksum. No secondary network fetch of the public key is permitted.
- **FR-008**: The script MUST abort immediately and clean up any downloaded files if either the checksum or signature verification fails.
- **FR-009**: The script MUST install the binary to the directory specified by the `DCV_INSTALL_PATH` environment variable. If `DCV_INSTALL_PATH` is not set, it MUST default to `~/.local/bin`. Installation MUST NOT require superuser (root/sudo) privileges.
- **FR-010**: The script MUST create the install directory (as resolved from `DCV_INSTALL_PATH` or the default) if it does not already exist.
- **FR-011**: The script MUST detect whether the resolved install directory is present in the user's `PATH` and provide shell-specific instructions to add it if absent. PATH guidance is skipped when `DCV_INSTALL_PATH` is set (assumed intentional custom path).
- **FR-012**: The script MUST print a progress message before each major step (e.g., detecting platform, fetching version, downloading binary, verifying checksum, installing).
- **FR-013**: The script MUST exit immediately with a non-zero exit code and a human-readable error message when any prerequisite is missing (e.g., `curl`, checksum verification tool) or any step fails.
- **FR-014**: Error messages MUST identify what went wrong, why it matters, and what the user can do to resolve it.
- **FR-015**: The script MUST be documented with inline comments explaining the purpose of each major section for transparency and auditability.
- **FR-016**: The script MUST clean up all temporary files on both success and unexpected exit/interruption.
- **FR-017**: The script MUST detect when a prior installation exists by comparing the SHA-256 checksum of the installed binary against the checksum published at `/releases/latest/`. If checksums match, the script MUST report the installation is already current and exit without making changes. If they differ, the script MUST replace the binary and report that dcv was updated.
- **FR-018**: The script MUST be idempotent — running it any number of times MUST always produce the same final installation state with no residual artifacts, partial installs, or duplicate side effects. (The `trap 'rm -rf "${WORK_DIR}"' EXIT INT TERM` mechanism satisfying FR-016 also satisfies the no-residual-artifacts aspect of this requirement.)
- **FR-019**: The script MUST NOT perform any automatic retries on network failures. It MUST fail immediately with a clear, actionable error message and a non-zero exit code, leaving the user to re-run the command.
- **FR-020**: The script MUST be written as a POSIX `sh` script (`#!/bin/sh`, `set -eu`). No bash-specific syntax is permitted. All operations that would require pipes for exit-code safety MUST instead use intermediate temp files so each step's exit code can be checked discretely.
- **FR-021**: The dcv-web Hero component install command snippet MUST display `curl -fsSL https://apps.microcode.io/dcv/install.sh | sh` — using `sh`, not `bash`. All website copy referencing the install one-liner MUST use `sh`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user on any supported platform can go from zero to a working `dcv` install in under 60 seconds on a connection of ≥10 Mbps download speed.
- **SC-002**: 100% of install attempts on supported platforms with healthy network access either succeed or exit with an actionable, human-readable error — no silent failures or undefined states.
- **SC-003**: A tampered or corrupted binary is detected and rejected 100% of the time; no installation proceeds when verification fails.
- **SC-004**: The script works on all three supported platform families (macOS Intel, macOS Apple Silicon, Linux x86_64, Linux ARM64, Windows WSL2) without any manual intervention.
- **SC-005**: No files remain in temporary locations after either a successful install or a failed/interrupted run.
- **SC-006**: Users who do not have `~/.local/bin` in their PATH receive shell-specific, copy-pasteable instructions that resolve the issue in one additional step.
- **SC-007**: Running the install command any number of times on an already-current installation produces no changes, no errors, and no leftover files — the end state is identical to a single fresh install.

## Assumptions

- `https://apps.microcode.io/dcv/releases/latest/` is a folder that always contains the current release artifacts. The script constructs all download URLs by appending the platform-specific filename directly (e.g., `dcv-linux-x64`, `dcv-darwin-arm64`). No version identifier fetch is required. The checksum file and signature file for the release are also served from this same path.
- A SHA-256 checksum file (`SHA256SUMS`) and a corresponding GPG detached signature file (`SHA256SUMS.sig`) are published alongside each release binary. **GPG is the chosen signing mechanism** — it is the community standard for release artifact signing (used by Debian, Alpine, Go, and most GitHub release workflows). The public key is ASCII-armored and embedded directly in `install.sh` via a heredoc; verification uses an isolated temporary keyring so the user's `~/.gnupg` is never touched. `gpg` is a required prerequisite; the script exits with an actionable install message if it is absent.
- The script MUST use `#!/bin/sh` with `set -eu`. No bash-specific syntax is permitted (`[[ ]]`, `pipefail`, bash arrays, etc.). This ensures compatibility with `dash` (Ubuntu/Debian default `/bin/sh`), `ash`, `busybox sh`, and stock macOS `sh` — no bash installation required.
- Users running WSL are assumed to be in a Linux environment from the script's perspective; no special WSL detection is required unless a WSL-specific incompatibility is discovered.
- The script will be committed to the dcv-web `public/` directory so it is served as a static asset at the correct URL path.
- `curl` is assumed to be available on all target platforms; it is a prerequisite, not bundled.
- "≥10 Mbps download speed" (SC-001) is a conservative lower bound for residential broadband in 2026 and is used as the testable definition of "standard broadband" for the 60-second install goal.

## Dependencies

- The dcv build pipeline must publish per-platform binaries, a checksum file, and a signed checksum file to the releases endpoint for each new version.
- The dcv-web deployment pipeline (AWS/CloudFront, per feature 004) must serve the `install.sh` from the correct public URL with appropriate `Content-Type` headers.
- A signing key pair must be created for signing release checksums; the public key MUST be embedded directly in `install.sh`. Trust is anchored to the HTTPS delivery of the script itself — no secondary key-fetch is performed. Key rotation is handled by publishing an updated `install.sh` to the static site.
