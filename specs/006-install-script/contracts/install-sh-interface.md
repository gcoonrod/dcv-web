# Contract: install.sh Interface

**Feature**: 006-install-script
**Date**: 2026-03-17
**Type**: Shell script user-facing interface

---

## Overview

`install.sh` is a POSIX sh script served as a static asset. Its interface is defined by:
- **Inputs**: Environment variables and the host system's runtime state
- **Outputs**: Stdout progress/result messages, stderr errors
- **Exit codes**: Defined codes for each failure mode
- **Side effects**: Binary installed to `install_dir`; temp files cleaned up

---

## Inputs

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DCV_INSTALL_PATH` | No | `$HOME/.local/bin` | Override install directory. When set, PATH guidance is suppressed. |

### Implicit Inputs (System State)

| Input | Source | Used For |
|-------|--------|---------|
| OS type | `uname -s` | Platform detection |
| CPU arch | `uname -m` | Platform detection |
| `curl` availability | `command -v curl` | Prerequisite check |
| `gpg` availability | `command -v gpg` | Prerequisite check |
| `sha256sum`/`shasum` availability | `command -v sha256sum` / `command -v shasum` | Prerequisite check |
| Existing binary at install path | `[ -f "${install_path}" ]` | Idempotency / upgrade detection |
| `$PATH` contents | `$PATH` env var | Post-install PATH guidance |
| `$SHELL` value | `$SHELL` env var | Shell-specific RC file guidance |

---

## Outputs

### Stdout (progress + results)

All progress output goes to stdout. Format: plain text, one line per step.

**Successful fresh install**:
```
==> Checking prerequisites...
==> Detecting platform... (darwin arm64)
==> Resolving install directory... (/Users/user/.local/bin)
==> Downloading dcv-darwin-arm64...
==> Verifying signature...
==> Verifying checksum...
==> Installing to /Users/user/.local/bin/dcv...

dcv installed successfully!

To verify: dcv --version

Note: /Users/user/.local/bin is not in your PATH.
Add to ~/.zshrc:
  export PATH="$HOME/.local/bin:$PATH"
Then restart your shell or run: source ~/.zshrc
```

**Already up to date**:
```
==> Checking prerequisites...
==> Detecting platform... (darwin arm64)
==> Resolving install directory... (/Users/user/.local/bin)
==> Checking installed version...

dcv is already up to date at /Users/user/.local/bin/dcv
```

**Successful upgrade**:
```
==> Checking prerequisites...
==> Detecting platform... (darwin arm64)
==> Resolving install directory... (/Users/user/.local/bin)
==> Checking installed version... (update available)
==> Downloading dcv-darwin-arm64...
==> Verifying signature...
==> Verifying checksum...
==> Installing to /Users/user/.local/bin/dcv...

dcv updated successfully!

To verify: dcv --version
```

### Stderr (errors only)

All error messages go to stderr. Format: `Error: <description>\n<action>\n`.

**Examples**:
```
Error: curl is not installed.
Install curl:
  macOS:  brew install curl
  Ubuntu: sudo apt-get install curl
  Alpine: apk add curl
```

```
Error: Unsupported architecture: i686
Supported architectures: arm64, aarch64, x86_64
```

```
Error: Signature verification failed. The release may have been tampered with.
Do not install this binary. Please report this at:
  https://github.com/gcoonrod/dcv/issues
```

```
Error: Checksum mismatch for dcv-darwin-arm64.
Expected: <hex>
Got:      <hex>
This may indicate a corrupted download. Re-run the install command to try again.
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success (installed, upgraded, or already up to date) |
| `1` | Any failure (missing prerequisite, unsupported platform, download failure, verification failure, permission error) |

All exit-1 conditions are accompanied by a human-readable error message on stderr.

---

## Side Effects

**On success**:
- Binary installed to `${DCV_INSTALL_PATH:-$HOME/.local/bin}/dcv` with mode `0755`
- Install directory created if it did not exist (mode `0755`)
- All temp files removed

**On any failure**:
- No files written to `${install_dir}` (temp dir only, cleaned up by trap)
- All temp files removed

**Idempotency guarantee** (FR-018):
- Running the script any number of times produces the same result as running it once
- If already current: no files written, no errors
- If updated: binary replaced atomically via `mv`

---

## Prerequisites

The following must be available on `PATH` before the script is invoked:

| Tool | Purpose | Platform availability |
|------|---------|----------------------|
| `curl` | Download binaries and checksum files | Universally available |
| `gpg` | Verify `SHA256SUMS.sig` signature | Linux (default); macOS via `brew install gnupg`; Alpine via `apk add gnupg` |
| `sha256sum` OR `shasum` | Verify binary checksum | Linux (`sha256sum`); macOS (`shasum`) |

If any prerequisite is missing, the script exits immediately with code 1 and an actionable install message before attempting any network requests.
