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
| `SHA256SUMS.sig` | `application/octet-stream` | OpenSSL detached signature of `SHA256SUMS` |

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

The `SHA256SUMS.sig` file is a detached OpenSSL binary signature of the `SHA256SUMS` file contents.

**Signing command** (build pipeline):
```sh
openssl dgst -sha256 -sign private.pem -out SHA256SUMS.sig SHA256SUMS
```

**Verification command** (install script):
```sh
openssl dgst -sha256 -verify pubkey.pem -signature SHA256SUMS.sig SHA256SUMS
```

The corresponding `pubkey.pem` (RSA or Ed25519 public key in PEM format) MUST be embedded in `install.sh`.

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
1. Generate new key pair
2. Update `install.sh` with the new public key PEM
3. Re-sign `SHA256SUMS` with the new private key → new `SHA256SUMS.sig`
4. Deploy updated `install.sh` and `SHA256SUMS.sig` atomically
5. Old installs using the previous public key will fail signature verification and must re-fetch the updated `install.sh`
