# Quickstart: DCV Install Script Development

**Feature**: 006-install-script
**Date**: 2026-03-17

---

## What This Feature Delivers

A POSIX sh install script (`public/install.sh`) served as a static asset at `https://apps.microcode.io/dcv/install.sh`. Users run it with `curl -fsSL https://apps.microcode.io/dcv/install.sh | sh`.

## Files Changed / Created

| File | Change |
|------|--------|
| `public/install.sh` | **New** — the install script |
| `src/components/Hero.astro` | **Updated** — `bash` → `sh` in install snippet (done) |
| `src/content/docs/installation.md` | **Updated** — `bash` → `sh` in code block (done) |

---

## Development Workflow

### 1. Write the Install Script

Create `public/install.sh`. Key implementation notes:

```sh
#!/bin/sh
set -eu

# Temp dir with cleanup trap (POSIX sh compatible)
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dcv-install.XXXXXX")"
trap 'rm -rf "${WORK_DIR}"' EXIT INT TERM

# Platform detection using case (no bash [[ ]])
OS_RAW="$(uname -s)"
case "$OS_RAW" in
  Darwin) OS="darwin" ;;
  Linux)  OS="linux" ;;
  *)
    echo "Error: Unsupported OS: $OS_RAW" >&2
    echo "Supported: Darwin (macOS), Linux" >&2
    exit 1
    ;;
esac

# Write embedded public key (heredoc is POSIX sh compatible)
PUBKEY_FILE="${WORK_DIR}/pubkey.pem"
cat > "${PUBKEY_FILE}" <<'EOF'
-----BEGIN PUBLIC KEY-----
<public key goes here>
-----END PUBLIC KEY-----
EOF
```

### 2. Generate a Signing Key Pair

Before testing signature verification, generate a key pair:

```sh
# Generate RSA 4096 key pair
openssl genrsa -out dcv-release-private.pem 4096
openssl rsa -in dcv-release-private.pem -pubout -out dcv-release-public.pem

# Embed the public key contents in install.sh
cat dcv-release-public.pem
```

**Security**: Keep `dcv-release-private.pem` secret. Store it in a secrets manager, not the repository. Only `dcv-release-public.pem` goes into `install.sh`.

### 3. Create Mock Release Artifacts for Testing

```sh
# Create a fake binary
echo "mock dcv binary" > /tmp/test-releases/dcv-darwin-arm64
echo "mock dcv binary" > /tmp/test-releases/dcv-linux-x64

# Generate checksums
cd /tmp/test-releases
sha256sum dcv-darwin-arm64 dcv-linux-x64 > SHA256SUMS
# macOS: shasum -a 256 ... > SHA256SUMS

# Sign the checksum file
openssl dgst -sha256 -sign dcv-release-private.pem -out SHA256SUMS.sig SHA256SUMS
```

### 4. Lint with ShellCheck

```sh
# Install shellcheck
brew install shellcheck       # macOS
apt-get install shellcheck    # Ubuntu/Debian

# Lint the install script
shellcheck public/install.sh
```

ShellCheck in default mode targets bash but detects many POSIX issues. Use `--shell=sh` to target POSIX sh specifically.

### 5. Test Locally

The script downloads from `https://apps.microcode.io/dcv/releases/latest/` — this URL is hardcoded. To test locally:

**Option A: Override via env in test script** — modify the script to accept a `DCV_RELEASES_URL` override for testing only. Remove before shipping.

**Option B: Serve locally with `npx serve`**:
```sh
# Serve /tmp/test-releases on localhost:3000
npx serve /tmp/test-releases -l 3000
# Then manually run sections of the script against localhost
```

**Option C: Point to real releases** — once the build pipeline publishes real artifacts, test the script end-to-end.

### 6. Cross-Platform Verification

Test against each target before merging:

| Platform | How to test |
|----------|-------------|
| macOS Apple Silicon | Run directly on macOS (arm64) |
| macOS Intel | Run on Intel Mac or Rosetta terminal |
| Linux x86_64 | Docker: `docker run --rm -it ubuntu:22.04 bash` → install `curl`, test |
| Linux ARM64 | Docker: `docker run --rm -it --platform linux/arm64 ubuntu:22.04 bash` |
| WSL2 | Windows machine with WSL2 Ubuntu |

Docker one-liner for Linux testing:
```sh
docker run --rm -it ubuntu:22.04 bash -c "apt-get update -q && apt-get install -y curl openssl && curl -fsSL https://apps.microcode.io/dcv/install.sh | sh"
```

### 7. Deploy

The install script is deployed automatically as part of the dcv-web Astro build:
```sh
npm run build   # outputs dist/ including dist/install.sh
```

The existing AWS deployment pipeline (feature 004) syncs `dist/` to S3, serving `install.sh` at the correct URL.

---

## Key Constraints

1. **POSIX sh only** — no `[[ ]]`, no `pipefail`, no bash arrays, no `local` (or use with caution — it's technically non-POSIX but supported everywhere)
2. **No sudo** — all installs to `$DCV_INSTALL_PATH` or `$HOME/.local/bin`
3. **Idempotent** — safe to run multiple times
4. **Cleanup** — temp files removed on all exit paths
5. **Fail fast** — all prerequisites checked before any network requests

---

## Acceptance Checklist

- [ ] `shellcheck --shell=sh public/install.sh` passes with no errors
- [ ] Fresh install works on macOS Apple Silicon
- [ ] Fresh install works on macOS Intel
- [ ] Fresh install works on Linux x86_64 (Ubuntu 22.04)
- [ ] Fresh install works on Linux ARM64
- [ ] Fresh install works on WSL2
- [ ] Re-run on current install exits "already up to date" with no changes
- [ ] Corrupted binary fails checksum verification with clear error
- [ ] Bad signature file fails signature verification with tamper warning
- [ ] Missing `curl` exits with actionable install instructions
- [ ] Missing `openssl` exits with actionable install instructions
- [ ] `DCV_INSTALL_PATH=/custom/path` installs to custom path
- [ ] Ctrl-C during download leaves no temp files
- [ ] `~/.local/bin` not in PATH → shell-specific guidance shown
- [ ] `~/.local/bin` in PATH → no PATH guidance shown
- [ ] `DCV_INSTALL_PATH` set → no PATH guidance shown
- [ ] Hero.astro install command displays `sh` not `bash` (FR-021)
- [ ] Fresh install on ≥10 Mbps connection completes in under 60 seconds (SC-001)
