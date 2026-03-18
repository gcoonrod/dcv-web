# Research: DCV Web Install Script

**Feature**: 006-install-script
**Date**: 2026-03-17
**Status**: Complete — all open questions resolved

---

## Decision 1: Signing Tool — GPG

**Decision**: Use **GPG** (`gpg --verify`) for cryptographic signature verification of the `SHA256SUMS` file. The public key (ASCII-armored, exported with `gpg --armor --export`) is embedded directly in `install.sh` using a POSIX-compatible heredoc. Verification uses an isolated temporary keyring (`--homedir`) so the user's `~/.gnupg` is never touched.

> **Post-spec change (2026-03-17)**: The original spec targeted OpenSSL based on a zero-dependency goal for macOS. This was revised during implementation: dcv targets developers, who are expected to have GPG available or be able to install it. GPG is the community standard for signing release artifacts and produces a more conventional, auditable trust chain.

**Rationale**:
- GPG is the industry standard for signing release artifacts (used by Debian, Alpine, Go, most GitHub release workflows)
- `gpg` is available by default on Linux; macOS developers are expected to have it via Homebrew (`brew install gnupg`)
- The script fails early with a clear, actionable install message if `gpg` is absent — dcv targets developers, not general consumers
- GPG detached signature verification is POSIX sh compatible: write the armored public key to a temp file via heredoc, import into an isolated `--homedir` keyring, then run `gpg --homedir "$GNUPGHOME" --verify SHA256SUMS.sig SHA256SUMS`
- The isolated keyring approach (`mkdir -m 700 "$GNUPGHOME"`) means the embedded key never touches the user's real `~/.gnupg`

**Alternatives considered**:
- **OpenSSL** (`openssl dgst -sha256 -verify`): Available on stock macOS (LibreSSL) and Linux. Rejected post-spec — less conventional for release signing, GPG is the community expectation.
- **minisign**: Simple, modern; not pre-installed on any stock platform. Rejected.
- **HTTPS-only (no signature verification)**: The approach used by Homebrew, Rustup, and Deno. Rejected — FR-007 explicitly requires signature verification.
- **SSH key signing** (`ssh-keygen -Y verify`): Available in OpenSSH 8.0+ but not universally present. Rejected.

**POSIX sh pattern**:
```sh
# Write embedded GPG public key to temp file (POSIX heredoc — no process substitution)
cat > "${WORK_DIR}/pubkey.gpg" <<'EOF'
-----BEGIN PGP PUBLIC KEY BLOCK-----
<ascii-armored-gpg-public-key>
-----END PGP PUBLIC KEY BLOCK-----
EOF

# Import into isolated keyring (mode 700 required by gpg)
GNUPGHOME="${WORK_DIR}/gnupg"
mkdir -m 700 "${GNUPGHOME}"
gpg --homedir "${GNUPGHOME}" --quiet --import "${WORK_DIR}/pubkey.gpg" 2>/dev/null

# Verify detached signature
gpg --homedir "${GNUPGHOME}" --quiet \
    --verify "${WORK_DIR}/SHA256SUMS.sig" "${WORK_DIR}/SHA256SUMS" 2>/dev/null
```

**Alpine note**: Alpine Linux minimal images may not include `gpg` by default. The script treats `gpg` as a prerequisite (FR-013) and exits with an actionable error if missing: `"gpg is not installed. Install gpg: apk add gnupg"`.

---

## Decision 2: Checksum Tool Detection — sha256sum / shasum

**Decision**: Detect the available SHA-256 checksum tool at runtime. Try `sha256sum` first (Linux/GNU coreutils); fall back to `shasum -a 256` (macOS stock).

**Rationale**:
- Linux ships `sha256sum` (GNU coreutils)
- macOS ships `shasum` (Perl-based; `shasum -a 256` computes SHA-256)
- Both produce the same output format: `<hex_hash>  <filename>` — compatible with `-c` / `--check` mode

**Detection pattern**:
```sh
if command -v sha256sum > /dev/null 2>&1; then
    SHA256_CMD="sha256sum"
elif command -v shasum > /dev/null 2>&1; then
    SHA256_CMD="shasum -a 256"
else
    die "Neither sha256sum nor shasum found. Install coreutils."
fi
```

**Alternatives considered**:
- Require only `openssl dgst -sha256` for hashing (avoids the detection step): Possible, but using the dedicated checksum tool is more conventional and the output is directly usable with `grep`/`awk` parsing against the `SHA256SUMS` file.

---

## Decision 3: Checksum File Convention — SHA256SUMS + SHA256SUMS.sig

**Decision**: The releases folder publishes:
- `SHA256SUMS` — multi-binary GNU coreutils checksum format, one entry per platform binary
- `SHA256SUMS.sig` — OpenSSL detached RSA (or Ed25519) signature of `SHA256SUMS`

**Format of `SHA256SUMS`**:
```
<sha256hex>  dcv-darwin-arm64
<sha256hex>  dcv-darwin-x64
<sha256hex>  dcv-linux-arm64
<sha256hex>  dcv-linux-x64
```

**Rationale**: The multi-binary single-file convention (`SHA256SUMS`) is the industry standard (used by GitHub Releases, Alpine packages, Go releases, Debian). Extracting the expected hash for a specific binary is trivial: `grep "dcv-${OS}-${ARCH}" SHA256SUMS | awk '{print $1}'`. Signing a single file is simpler than signing per-binary files.

**Alternatives considered**:
- Per-binary `.sha256` files (e.g., `dcv-darwin-arm64.sha256`): Would require downloading a separate checksum file per binary; no advantage over a single `SHA256SUMS` file.

---

## Decision 4: Binary Naming Convention — Confirmed

**Decision**: Confirmed from existing local install script and `installation.md` documentation. Binary names follow the pattern `dcv-{os}-{arch}`:

| Platform | Binary Name |
|----------|-------------|
| macOS Apple Silicon | `dcv-darwin-arm64` |
| macOS Intel | `dcv-darwin-x64` |
| Linux x86_64 | `dcv-linux-x64` |
| Linux ARM64 | `dcv-linux-arm64` |

OS detection: `uname -s` → `Darwin` → `darwin`, `Linux` → `linux`
Arch detection: `uname -m` → `arm64`/`aarch64` → `arm64`, `x86_64` → `x64`

---

## Decision 5: Install Script Execution Flow

**Decision**: The script follows this ordered sequence:

1. **Prerequisite check** — verify `curl`, `openssl`, and `sha256sum`/`shasum` are available; exit immediately with actionable errors if any are missing
2. **Platform detection** — `uname -s` and `uname -m`; map to supported OS/arch pairs; exit on unsupported platform
3. **Resolve install directory** — `DCV_INSTALL_PATH` or default `~/.local/bin`; create if needed
4. **Upgrade detection (idempotency check)** — if binary already exists at install path, download `SHA256SUMS` and compare installed binary's checksum; skip download if already current
5. **Download to temp dir** — `mktemp -d` temp directory; `trap 'rm -rf "$WORK_DIR"' EXIT INT TERM` for cleanup; download binary + `SHA256SUMS` + `SHA256SUMS.sig`
6. **Verify signature** — write embedded public key to temp file; `openssl dgst -verify`; exit on failure
7. **Verify checksum** — extract expected hash from `SHA256SUMS`; compute actual hash; compare; exit on mismatch
8. **Atomic install** — `chmod +x` binary; `mv` to final path (atomic rename on same filesystem)
9. **PATH guidance** — check if install dir is in `$PATH`; emit shell-specific guidance if not (skipped when `DCV_INSTALL_PATH` is set)
10. **Success message** — print confirmation and `dcv --version` verification hint

**Rationale**: Upgrade check (step 4) happens before downloading to make idempotent re-runs fast. Signature verification (step 6) runs before checksum (step 7) because a valid signature means the `SHA256SUMS` file itself is trusted; without that, a compromised checksum file is meaningless.

---

## Decision 6: Temp Directory Pattern

**Decision**: Use a single `mktemp -d` working directory per run, cleaned up on EXIT, INT, and TERM via `trap`.

```sh
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dcv-install.XXXXXX")"
trap 'rm -rf "${WORK_DIR}"' EXIT INT TERM
```

**Rationale**: POSIX `mktemp -d` is available on all target platforms. `${TMPDIR:-/tmp}` handles macOS where `TMPDIR` is set to a session-specific directory. The EXIT trap ensures cleanup on normal exit, error exit, and Ctrl-C interrupt — satisfying FR-016 and FR-018 (idempotency / no leftover artifacts).

---

## Decision 7: Script Deployment Path

**Decision**: The script is committed to `public/install.sh` in the dcv-web Astro project. With `base: '/dcv'` in `astro.config.mjs`, files in `public/` are served at `https://apps.microcode.io/dcv/<filename>`. So `public/install.sh` → `https://apps.microcode.io/dcv/install.sh` ✓.

The S3/CloudFront deployment pipeline (feature 004) syncs `dist/` to the target bucket. Since `public/` files are copied verbatim to `dist/`, no special handling is needed.

---

## Industry Context

Major one-liner installers surveyed:
- **Homebrew**: Relies on HTTPS TLS only; no checksum or signature verification in `install.sh`
- **Rustup**: Downloads a pre-compiled binary via HTTPS; verifies SHA256 checksum only (no signature)
- **Deno**: Downloads via GitHub Releases with HTTPS; no embedded signature verification

**Conclusion**: Our approach (checksum + OpenSSL signature) is *more* security-rigorous than these industry examples. It is justified by FR-007 and the supply-chain threat model (signed checksums protect against CDN compromise even when TLS is intact).
