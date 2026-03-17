#!/bin/sh
# =============================================================================
# install.sh — DCV installer
#
# Usage:
#   curl -fsSL https://apps.microcode.io/dcv/install.sh | sh
#
# Supported platforms:
#   macOS Intel (darwin x64) · macOS Apple Silicon (darwin arm64)
#   Linux x86_64 (linux x64) · Linux ARM64 (linux arm64)
#   Windows WSL2 (treated as Linux)
#
# Environment variables:
#   DCV_INSTALL_PATH  Override install directory (default: ~/.local/bin)
#
# Requirements:
#   curl, gpg, sha256sum (Linux) or shasum (macOS)
# =============================================================================
set -eu

BASE_URL="https://apps.microcode.io/dcv/releases/latest"

# =============================================================================
# die — print an error message to stderr and exit with code 1
#
# Usage: die "Error description\nActionable instruction"
#
# The message argument may contain \n escape sequences for multi-line output.
# POSIX %b format specifier interprets backslash escapes, so newlines work
# correctly across dash, ash, busybox sh, and macOS /bin/sh.
# =============================================================================
die() {
  printf 'Error: %b\n' "$1" >&2
  exit 1
}

# =============================================================================
# STEP 1 — Check prerequisites (FR-013)
#
# Verify that curl, openssl, and a SHA-256 checksum tool are all available on
# PATH before attempting any network requests. Exit immediately with actionable
# install instructions if any prerequisite is missing.
#
# SHA256_CMD is set here and reused in the idempotency check (step 4) and
# checksum verification (step 8) — it must be set in this section.
# =============================================================================
printf '==> Checking prerequisites...\n'

if ! command -v curl > /dev/null 2>&1; then
  die "curl is not installed.\nInstall curl:\n  macOS:  brew install curl\n  Ubuntu: sudo apt-get install curl\n  Alpine: apk add curl"
fi

if ! command -v gpg > /dev/null 2>&1; then
  die "gpg is not installed.\nInstall gpg:\n  macOS:  brew install gnupg\n  Ubuntu: sudo apt-get install gnupg\n  Alpine: apk add gnupg"
fi

# Detect SHA-256 tool: sha256sum (Linux/GNU coreutils) or shasum (macOS)
if command -v sha256sum > /dev/null 2>&1; then
  SHA256_CMD="sha256sum"
elif command -v shasum > /dev/null 2>&1; then
  SHA256_CMD="shasum -a 256"
else
  die "Neither sha256sum nor shasum is installed.\nInstall coreutils:\n  macOS:  brew install coreutils\n  Ubuntu: sudo apt-get install coreutils\n  Alpine: apk add coreutils"
fi

# =============================================================================
# STEP 2 — Detect platform (FR-002, FR-003)
#
# Use uname -s (OS) and uname -m (architecture) to identify the host platform.
# Normalize to the binary naming convention: dcv-{os}-{arch}
#   darwin  = macOS (Intel or Apple Silicon)
#   linux   = Linux or Windows WSL2 (WSL reports Linux)
#   arm64   = Apple Silicon / ARM64 Linux (uname reports arm64 or aarch64)
#   x64     = Intel/AMD 64-bit (uname reports x86_64)
# =============================================================================
printf '==> Detecting platform...'

OS_RAW="$(uname -s)"
ARCH_RAW="$(uname -m)"

case "${OS_RAW}" in
  Darwin) OS="darwin" ;;
  Linux)  OS="linux"  ;;
  *)
    die "Unsupported operating system: ${OS_RAW}\nSupported platforms: Darwin (macOS), Linux (including WSL2)"
    ;;
esac

case "${ARCH_RAW}" in
  arm64|aarch64) ARCH="arm64" ;;
  x86_64)        ARCH="x64"   ;;
  *)
    die "Unsupported architecture: ${ARCH_RAW}\nSupported architectures: arm64, aarch64, x86_64"
    ;;
esac

BINARY_NAME="dcv-${OS}-${ARCH}"
printf ' (%s %s)\n' "${OS}" "${ARCH}"

# =============================================================================
# STEP 3 — Resolve install directory (FR-009, FR-010)
#
# Use DCV_INSTALL_PATH if set; otherwise default to ~/.local/bin.
# Create the directory if it does not exist (mkdir -p).
# Verify the directory is writable — fail early with a permission error if not.
# No superuser privileges are required or requested.
# =============================================================================
printf '==> Resolving install directory...'

INSTALL_DIR="${DCV_INSTALL_PATH:-${HOME}/.local/bin}"
INSTALL_PATH="${INSTALL_DIR}/dcv"

mkdir -p "${INSTALL_DIR}"

if [ ! -w "${INSTALL_DIR}" ]; then
  die "Cannot write to install directory: ${INSTALL_DIR}\nCheck permissions or set DCV_INSTALL_PATH to a writable directory."
fi

printf ' (%s)\n' "${INSTALL_DIR}"

# =============================================================================
# STEP 4 — Idempotency check (FR-017, FR-018)
#
# If dcv is already installed at the target path, download only SHA256SUMS and
# compare the installed binary's checksum against the latest published checksum.
# If they match, the installation is already current — exit cleanly with no
# files written (idempotent re-run).
#
# Security note: Signature verification on SHA256SUMS is intentionally skipped
# here. Trust is placed in the already-installed binary — if its hash matches
# the published hash, no new artifacts are being installed and nothing changes
# on disk. Full sig+checksum verification runs in step 7 only when a new
# binary is about to be installed.
# =============================================================================
UPGRADE=0
TMP_SUMS=""

if [ -f "${INSTALL_PATH}" ]; then
  printf '==> Checking installed version...'

  TMP_SUMS="$(mktemp "${TMPDIR:-/tmp}/dcv-sums.XXXXXX")"
  trap 'rm -f "${TMP_SUMS}"' EXIT INT TERM

  if ! curl -fsSL "${BASE_URL}/SHA256SUMS" -o "${TMP_SUMS}"; then
    die "Failed to download ${BASE_URL}/SHA256SUMS\nCheck your network connection and retry."
  fi

  LATEST_HASH="$(grep "${BINARY_NAME}" "${TMP_SUMS}" | awk '{print $1}')"
  INSTALLED_HASH="$(${SHA256_CMD} "${INSTALL_PATH}" | awk '{print $1}')"

  if [ "${LATEST_HASH}" = "${INSTALLED_HASH}" ]; then
    printf '\n\ndcv is already up to date at %s\n' "${INSTALL_PATH}"
    exit 0
  fi

  UPGRADE=1
  printf ' (update available)\n'
fi

# =============================================================================
# STEP 5 — Create working directory with cleanup trap (FR-016, FR-018)
#
# All downloaded artifacts are written to a mktemp directory. The trap is
# registered here and supersedes the TMP_SUMS-only trap (if it was set in
# step 4): the new combined trap removes both the temporary sums file and the
# working directory on EXIT, INT, and TERM — satisfying the no-residual-
# artifacts requirement (FR-018) for all exit paths including Ctrl-C.
# ${TMPDIR:-/tmp} handles macOS where TMPDIR is set to a session-specific path.
# =============================================================================
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dcv-install.XXXXXX")"
# Supersede any prior trap; remove both TMP_SUMS (if created) and WORK_DIR
trap 'rm -f "${TMP_SUMS}"; rm -rf "${WORK_DIR}"' EXIT INT TERM

# =============================================================================
# STEP 6 — Download release artifacts (FR-004, FR-005, FR-006, FR-007)
#
# Download the platform-appropriate binary, SHA256SUMS checksum file, and
# SHA256SUMS.sig signature file from the releases/latest/ folder.
# curl -fsSL: fail on HTTP error (-f), silent (-s), follow redirects (-L).
# Each download is checked individually (POSIX sh: no pipefail — use temp files
# so each curl exit code can be inspected discretely, per FR-020).
# =============================================================================
printf '==> Downloading %s...\n' "${BINARY_NAME}"

if ! curl -fsSL "${BASE_URL}/${BINARY_NAME}" -o "${WORK_DIR}/${BINARY_NAME}"; then
  die "Failed to download ${BASE_URL}/${BINARY_NAME}\nCheck your network connection and retry."
fi

if [ ! -s "${WORK_DIR}/${BINARY_NAME}" ]; then
  die "Release artifact not found at ${BASE_URL}/${BINARY_NAME}\nCheck https://apps.microcode.io/dcv/releases/latest/ manually."
fi

# Download SHA256SUMS and SHA256SUMS.sig for verification (FR-006, FR-007)
if ! curl -fsSL "${BASE_URL}/SHA256SUMS" -o "${WORK_DIR}/SHA256SUMS"; then
  die "Failed to download ${BASE_URL}/SHA256SUMS\nCheck your network connection and retry."
fi

if [ ! -s "${WORK_DIR}/SHA256SUMS" ]; then
  die "SHA256SUMS not found at ${BASE_URL}/SHA256SUMS\nCheck https://apps.microcode.io/dcv/releases/latest/ manually."
fi

if ! curl -fsSL "${BASE_URL}/SHA256SUMS.sig" -o "${WORK_DIR}/SHA256SUMS.sig"; then
  die "Failed to download ${BASE_URL}/SHA256SUMS.sig\nCheck your network connection and retry."
fi

if [ ! -s "${WORK_DIR}/SHA256SUMS.sig" ]; then
  die "SHA256SUMS.sig not found at ${BASE_URL}/SHA256SUMS.sig\nCheck https://apps.microcode.io/dcv/releases/latest/ manually."
fi

# =============================================================================
# STEP 7a — Verify signature on SHA256SUMS (FR-007)
#
# Write the embedded GPG public key to a temp file (POSIX heredoc). Import it
# into an isolated temporary keyring (mode 700 required by gpg) so the key
# never touches the user's real ~/.gnupg. Verify the detached signature on
# SHA256SUMS using that keyring. If verification fails, abort immediately with
# a tamper warning (FR-008).
# =============================================================================
printf '==> Verifying signature...\n'

cat > "${WORK_DIR}/pubkey.gpg" <<'EOF'
-----BEGIN PGP PUBLIC KEY BLOCK-----

mDMEaarvyxYJKwYBBAHaRw8BAQdAMiqxH2plYoeGdjXllPCGMxd8j+oRf+4iF79H
F83D8Uu0N0dyZWcgQ29vbnJvZCAoZGN2LXNpZ25pbmcta2V5KSA8Z3JlZy5jb29u
cm9kQGdtYWlsLmNvbT6IkwQTFgoAOxYhBO3zS9JZYVJ5VLGaUc3PwVQ+naANBQJp
qu/LAhsDBQsJCAcCAiICBhUKCQgLAgQWAgMBAh4HAheAAAoJEM3PwVQ+naANaq0A
/1WPN5vQ8jJ3Uj852OMYt3FyIconqO5qg/WWmHZHlMbxAP9zLzlEvNUEv0+zWZ9+
v18f116v0h4UV+pxHHaAhTsVAbg4BGmq78sSCisGAQQBl1UBBQEBB0ByvtlYWZSK
MjMbd0fIvT5MUrHX0ALaJtGKA9wiD6xdIwMBCAeIeAQYFgoAIBYhBO3zS9JZYVJ5
VLGaUc3PwVQ+naANBQJpqu/LAhsMAAoJEM3PwVQ+naAN9ZYA/2K3ggpzjUeargSe
/PkAIrRbHdsoIRNDmIHPT0zsvd7mAQDjFbyNoyNfFrArMwvvxBngnoal3VxuqV0H
7AT/ClIiDA==
=APqK
-----END PGP PUBLIC KEY BLOCK-----
EOF

GNUPGHOME="${WORK_DIR}/gnupg"
mkdir -m 700 "${GNUPGHOME}"

if ! gpg --homedir "${GNUPGHOME}" --quiet --import "${WORK_DIR}/pubkey.gpg" 2>/dev/null; then
  die "Failed to import signing public key.\nThe install script may be corrupted. Please report this at:\n  https://github.com/gcoonrod/dcv/issues"
fi

if ! gpg --homedir "${GNUPGHOME}" --quiet \
    --verify "${WORK_DIR}/SHA256SUMS.sig" "${WORK_DIR}/SHA256SUMS" 2>/dev/null; then
  die "Signature verification failed. The release may have been tampered with.\nDo not install this binary. Please report this at:\n  https://github.com/gcoonrod/dcv/issues"
fi

# =============================================================================
# STEP 7b — Verify SHA-256 checksum of downloaded binary (FR-006)
#
# Step 1: Extract the expected hash for this platform's binary from the now-
#         trusted SHA256SUMS file (grep by binary name, awk for first field).
# Step 2: Compute the actual SHA-256 hash of the downloaded binary.
# Step 3: Compare — abort with an error if they differ (FR-008).
#
# SHA256_CMD was detected in step 1 (either "sha256sum" or "shasum -a 256").
# Both produce "hexhash  filename" output — awk '{print $1}' extracts the hash.
# =============================================================================
printf '==> Verifying checksum...\n'

EXPECTED_HASH="$(grep "${BINARY_NAME}" "${WORK_DIR}/SHA256SUMS" | awk '{print $1}')"
ACTUAL_HASH="$(${SHA256_CMD} "${WORK_DIR}/${BINARY_NAME}" | awk '{print $1}')"

if [ "${EXPECTED_HASH}" != "${ACTUAL_HASH}" ]; then
  die "Checksum mismatch for ${BINARY_NAME}.\nExpected: ${EXPECTED_HASH}\nGot:      ${ACTUAL_HASH}\nThis may indicate a corrupted download. Re-run the install command to try again."
fi

# =============================================================================
# STEP 8 — Atomic install (FR-009)
#
# chmod +x makes the binary executable. mv is atomic on the same filesystem
# (rename syscall) — the binary is either fully present at the install path or
# absent; there is no partial-write state visible to the user.
# WORK_DIR is under TMPDIR which is typically on the same volume as HOME.
# =============================================================================
printf '==> Installing to %s...\n' "${INSTALL_PATH}"

chmod +x "${WORK_DIR}/${BINARY_NAME}"
mv "${WORK_DIR}/${BINARY_NAME}" "${INSTALL_PATH}"

# =============================================================================
# STEP 9 — PATH guidance (FR-011)
#
# Only emit PATH guidance when using the default install directory (i.e., when
# DCV_INSTALL_PATH was not set by the user — they chose the path intentionally).
# Uses POSIX case-in-string membership check: ":${PATH}:" wrapping ensures
# exact directory boundary matching (no false positives from substring matches).
# fish shell does not support "export PATH="; use fish_add_path instead.
# =============================================================================
if [ -z "${DCV_INSTALL_PATH:-}" ]; then
  case ":${PATH}:" in
    *":${INSTALL_DIR}:"*)
      : ;;  # already in PATH — no guidance needed
    *)
      printf '\nNote: %s is not in your PATH.\n' "${INSTALL_DIR}"
      case "${SHELL:-}" in
        */zsh)
          printf 'Add to ~/.zshrc:\n'
          printf "  export PATH=\"\$HOME/.local/bin:\$PATH\"\n"
          printf 'Then restart your shell or run: source ~/.zshrc\n'
          ;;
        */bash)
          printf 'Add to ~/.bashrc:\n'
          printf "  export PATH=\"\$HOME/.local/bin:\$PATH\"\n"
          printf 'Then restart your shell or run: source ~/.bashrc\n'
          ;;
        */fish)
          # fish does not support `export PATH=`; use fish_add_path instead
          printf 'Run:\n'
          printf "  fish_add_path \$HOME/.local/bin\n"
          printf 'Then restart your shell.\n'
          ;;
        *)
          printf 'Add this line to your shell configuration file:\n'
          printf "  export PATH=\"\$HOME/.local/bin:\$PATH\"\n"
          printf 'Then restart your shell.\n'
          ;;
      esac
      ;;
  esac
fi

# =============================================================================
# STEP 10 — Success message
#
# Three variants per contracts/install-sh-interface.md §Stdout:
#   "dcv installed successfully!"  — fresh install (UPGRADE=0, no prior binary)
#   "dcv updated successfully!"    — upgrade (UPGRADE=1, prior binary replaced)
#   "dcv is already up to date"    — idempotent re-run (exited in step 4)
# All active variants are followed by the verify hint.
# =============================================================================
if [ "${UPGRADE}" = "1" ]; then
  printf '\ndcv updated successfully!\n\nTo verify: dcv --version\n'
else
  printf '\ndcv installed successfully!\n\nTo verify: dcv --version\n'
fi
