# Contract: Releases Folder Structure

**Feature**: 006-install-script
**Date**: 2026-03-17
**Type**: Build pipeline / CDN contract
**Consumers**: `install.sh`
**Producers**: dcv build pipeline

---

## Overview

The install script depends on a set of files being available at the `/releases/latest/` path on `apps.microcode.io`. This document defines what the dcv build pipeline MUST publish to that location for the install script to function correctly.

---

## Required Files

All files MUST be available at `https://apps.microcode.io/dcv/releases/latest/<filename>`:

| File | MIME Type | Description |
|------|-----------|-------------|
| `dcv-darwin-arm64` | `application/octet-stream` | macOS Apple Silicon binary |
| `dcv-darwin-x64` | `application/octet-stream` | macOS Intel binary |
| `dcv-linux-arm64` | `application/octet-stream` | Linux ARM64 binary |
| `dcv-linux-x64` | `application/octet-stream` | Linux x86_64 binary |
| `SHA256SUMS` | `text/plain` | SHA-256 checksums for all binaries |
| `SHA256SUMS.sig` | `application/octet-stream` | GPG detached signature of `SHA256SUMS` |

---

## SHA256SUMS Format

The `SHA256SUMS` file MUST use GNU coreutils format: **two spaces** between the hash and filename, one entry per line, Unix line endings (`\n`).

```
<64-char lowercase hex SHA-256>  dcv-darwin-arm64
<64-char lowercase hex SHA-256>  dcv-darwin-x64
<64-char lowercase hex SHA-256>  dcv-linux-arm64
<64-char lowercase hex SHA-256>  dcv-linux-x64
```

**Validation**: Entries MUST match the filenames listed above exactly (no path prefix, no trailing whitespace). The install script extracts the expected hash using:
```sh
grep "dcv-${OS}-${ARCH}" SHA256SUMS | awk '{print $1}'
```

---

## SHA256SUMS.sig Format

The `SHA256SUMS.sig` file is a GPG detached binary signature of the `SHA256SUMS` file contents.

> **Note (2026-03-17)**: The original spec targeted OpenSSL signing. This was changed post-implementation to GPG, which is the community standard for signing release artifacts (used by Debian, Alpine, Go, most GitHub release workflows). See `research.md` Decision 1 for full rationale.

**Signing command** (build pipeline):
```sh
gpg --detach-sign SHA256SUMS
# Produces SHA256SUMS.sig (binary format)
```

**Verification command** (install script — isolated keyring):
```sh
GNUPGHOME="$(mktemp -d)"
mkdir -m 700 "${GNUPGHOME}"
gpg --homedir "${GNUPGHOME}" --quiet --import pubkey.gpg 2>/dev/null
gpg --homedir "${GNUPGHOME}" --quiet --verify SHA256SUMS.sig SHA256SUMS 2>/dev/null
```

The corresponding ASCII-armored GPG public key MUST be embedded in `install.sh` via a heredoc. The embedded key is imported into an isolated temporary keyring (`--homedir`) at runtime so the user's `~/.gnupg` is never touched.

---

## Atomicity Requirement

The build pipeline MUST update all six files atomically. The install script MUST never encounter a state where the binary files and `SHA256SUMS`/`SHA256SUMS.sig` are mismatched (e.g., new binaries with old checksums). Recommended pattern: write files to a staging path, then perform a single rename/copy to `releases/latest/`.

---

## HTTP Response Requirements

The CloudFront distribution MUST serve these files with:
- **HTTP 200** for all six files (no 404s)
- **Follow redirects**: `curl -fsSL` (used in the install command) follows redirects automatically; the CDN may redirect without issue
- **No caching issues**: `releases/latest/` MUST not be cached with a TTL that prevents the install script from seeing the current release. Recommended: `Cache-Control: no-cache` or short TTL (≤60s) for `releases/latest/*`

---

## Key Rotation

When the signing key pair is rotated:
1. Generate a new GPG key pair: `gpg --full-generate-key` (Ed25519 recommended)
2. Export the new ASCII-armored public key: `gpg --armor --export <KEY_ID>`
3. Update `install.sh` with the new public key (replace the embedded heredoc block)
4. Re-sign `SHA256SUMS` with the new private key: `gpg --detach-sign SHA256SUMS` → new `SHA256SUMS.sig`
5. Deploy updated `install.sh` and `SHA256SUMS.sig` atomically
6. Old installs using the previous public key will fail signature verification and must re-fetch the updated `install.sh`
