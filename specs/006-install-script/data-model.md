# Data Model: DCV Web Install Script

**Feature**: 006-install-script
**Date**: 2026-03-17

---

## Overview

This feature has no persistent data store. All entities are either runtime values computed during script execution, files on the local filesystem, or static artifacts published to the releases CDN. The data model documents the structural contracts that the install script depends on.

---

## Entities

### 1. Platform Identity

Computed at runtime from `uname` output. Determines which binary to download.

| Attribute | Source | Values |
|-----------|--------|--------|
| `raw_os` | `uname -s` | `Darwin`, `Linux` |
| `os` | Normalized from `raw_os` | `darwin`, `linux` |
| `raw_arch` | `uname -m` | `arm64`, `aarch64`, `x86_64` |
| `arch` | Normalized from `raw_arch` | `arm64` (covers arm64+aarch64), `x64` (covers x86_64) |
| `binary_name` | Constructed: `dcv-${os}-${arch}` | `dcv-darwin-arm64`, `dcv-darwin-x64`, `dcv-linux-arm64`, `dcv-linux-x64` |

**Validation rules**:
- If `raw_os` is not `Darwin` or `Linux` → exit with unsupported OS error
- If `raw_arch` is not `arm64`, `aarch64`, or `x86_64` → exit with unsupported arch error

**Platform matrix** (supported combinations):

| OS | Arch | Binary |
|----|------|--------|
| macOS (Apple Silicon) | arm64 / aarch64 | `dcv-darwin-arm64` |
| macOS (Intel) | x86_64 | `dcv-darwin-x64` |
| Linux / WSL (x86_64) | x86_64 | `dcv-linux-x64` |
| Linux / WSL (ARM64) | arm64 / aarch64 | `dcv-linux-arm64` |

---

### 2. Installation Target

Computed at runtime. Specifies where the binary will be installed.

| Attribute | Source | Default |
|-----------|--------|---------|
| `install_dir` | `$DCV_INSTALL_PATH` env var | `$HOME/.local/bin` |
| `install_path` | `${install_dir}/dcv` | `$HOME/.local/bin/dcv` |

**Validation rules**:
- `install_dir` must be created if it does not exist (`mkdir -p`)
- If `install_dir` is not writable after creation → exit with permission error
- If `DCV_INSTALL_PATH` is set, PATH guidance is suppressed (intentional custom path assumed)

---

### 3. Release Artifact Set

Static files published to `https://apps.microcode.io/dcv/releases/latest/` for each release. The install script downloads from this folder.

| File | Description | Format |
|------|-------------|--------|
| `dcv-darwin-arm64` | Binary for macOS Apple Silicon | ELF/Mach-O executable |
| `dcv-darwin-x64` | Binary for macOS Intel | ELF/Mach-O executable |
| `dcv-linux-arm64` | Binary for Linux ARM64 | ELF executable |
| `dcv-linux-x64` | Binary for Linux x86_64 | ELF executable |
| `SHA256SUMS` | Checksums for all binaries | GNU coreutils format (see below) |
| `SHA256SUMS.sig` | OpenSSL detached signature of `SHA256SUMS` | Binary DER or base64 signature |

**`SHA256SUMS` format** (GNU coreutils, two spaces between hash and filename):
```
<64-char hex hash>  dcv-darwin-arm64
<64-char hex hash>  dcv-darwin-x64
<64-char hex hash>  dcv-linux-arm64
<64-char hex hash>  dcv-linux-x64
```

**Validation rules** (enforced by build pipeline, not install script):
- All four platform binaries MUST be present in `releases/latest/`
- `SHA256SUMS` MUST contain entries for all four binaries
- `SHA256SUMS.sig` MUST be a valid OpenSSL signature of `SHA256SUMS` using the release signing key

---

### 4. Embedded Signing Public Key

Static value embedded in `install.sh` at the time the script is published. Not fetched at runtime.

| Attribute | Description |
|-----------|-------------|
| Format | PEM-encoded RSA or Ed25519 public key |
| Location | Heredoc within `install.sh`, written to `${WORK_DIR}/pubkey.pem` at runtime |
| Rotation | Requires publishing an updated `install.sh` to `public/` |
| Trust anchor | HTTPS delivery of `install.sh` from `apps.microcode.io` |

---

### 5. Working Directory (Ephemeral)

Temporary directory created per script invocation. Destroyed on EXIT, INT, TERM.

| Attribute | Value |
|-----------|-------|
| Path | `$(mktemp -d "${TMPDIR:-/tmp}/dcv-install.XXXXXX")` |
| Contents | Downloaded binary, `SHA256SUMS`, `SHA256SUMS.sig`, `pubkey.pem` |
| Lifetime | Single script invocation |
| Cleanup | `trap 'rm -rf "${WORK_DIR}"' EXIT INT TERM` |

---

### 6. Existing Installation State

Checked before downloading to enable idempotent upgrades (FR-017, FR-018).

| Attribute | Check method |
|-----------|-------------|
| Binary exists | `[ -f "${install_path}" ]` |
| Installed checksum | `sha256sum "${install_path}"` or `shasum -a 256 "${install_path}"` |
| Latest checksum | Extracted from freshly-downloaded `SHA256SUMS` |
| Up-to-date | `installed_hash = latest_hash` → skip download, exit success |

---

## State Transitions

```
Script starts
  └─► Check prerequisites (curl, openssl, sha256sum/shasum)
        ├─► Missing → exit 1 with install instructions
        └─► OK → detect platform
              ├─► Unsupported → exit 1 with supported list
              └─► OK → resolve install directory
                    ├─► Not writable → exit 1 with permission info
                    └─► OK → check existing installation
                          ├─► Already current → exit 0 "up to date"
                          └─► New/outdated → create WORK_DIR + trap
                                └─► Download binary + SHA256SUMS + SHA256SUMS.sig
                                      ├─► Network fail → exit 1 with URL + retry hint
                                      └─► OK → verify signature (SHA256SUMS.sig)
                                            ├─► Bad sig → exit 1 "tampered" warning
                                            └─► OK → verify checksum (binary vs SHA256SUMS)
                                                  ├─► Mismatch → exit 1 with hash details
                                                  └─► OK → chmod +x + mv (atomic)
                                                        └─► PATH check → guidance if needed
                                                              └─► exit 0 "installed" message
```

---

## Environment Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DCV_INSTALL_PATH` | string | `$HOME/.local/bin` | Override install directory |
| `TMPDIR` | string | `/tmp` | System temp dir (used for working directory) |
| `HOME` | string | *(required)* | Used for default install path |
| `PATH` | string | *(required)* | Checked for install dir presence; used for PATH guidance |
| `SHELL` | string | *(optional)* | Used to determine RC file for PATH guidance |
