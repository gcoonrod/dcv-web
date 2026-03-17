# Implementation Plan: DCV Web Install Script

**Branch**: `006-install-script` | **Date**: 2026-03-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/006-install-script/spec.md`

## Summary

Implement and deploy `public/install.sh` — a POSIX sh (`#!/bin/sh`, `set -eu`) one-liner install script served at `https://apps.microcode.io/dcv/install.sh`. The script downloads the platform-appropriate dcv binary from `https://apps.microcode.io/dcv/releases/latest/`, verifies the release signature (OpenSSL, embedded public key) and SHA-256 checksum, and installs to `~/.local/bin` (or `$DCV_INSTALL_PATH`) without superuser privileges. The script is idempotent, cleans up temp files on all exit paths, and provides shell-specific PATH guidance when needed. The `Hero.astro` install snippet and `installation.md` doc are already updated from `bash` to `sh`.

## Technical Context

**Language/Version**: POSIX sh (`#!/bin/sh`, `set -eu`) — no bash-specific syntax
**Primary Dependencies**: `curl` (download), `openssl` (signature verification — LibreSSL on macOS, openssl on Linux), `sha256sum`/`shasum` (checksum — detected at runtime)
**Storage**: Local filesystem — `$DCV_INSTALL_PATH` (default `$HOME/.local/bin`); ephemeral `mktemp -d` working directory
**Testing**: Manual cross-platform testing (macOS Apple Silicon/Intel, Linux x86_64/ARM64, WSL2); `shellcheck --shell=sh` for linting
**Target Platform**: Script runs on macOS 12+ (Darwin), Linux (Ubuntu 22.04, Debian 12, Alpine), Windows WSL2. Script is HOSTED as a static asset on Astro/S3/CloudFront.
**Project Type**: Shell script (single-file static web asset)
**Performance Goals**: Install completes in under 60 seconds on standard broadband (SC-001)
**Constraints**: POSIX sh only, no sudo, idempotent, no automatic retries, embedded public key (no secondary key fetch), temp dir cleaned up on all exit paths
**Scale/Scope**: Single script file (~150-250 lines); no npm dependencies added

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Rule | Status | Notes |
|------|--------|-------|
| **Core I** — Static output (`output: 'static'`) | ✅ Pass | `install.sh` is a static file in `public/`; no SSR adapter introduced |
| **Core II** — Developer-centric aesthetic | ✅ Pass | No UI changes beyond text fix in Hero.astro (bash → sh) |
| **Core III** — AWS Native / S3+CloudFront | ✅ Pass | Script served as static asset; no Node.js server in production |
| **Rule I** — Tailwind CSS only | ✅ Pass | No new CSS of any kind |
| **Rule II** — Island Architecture | ✅ Pass | No new Astro components or islands |
| **Rule III** — Vanilla JS preference | ✅ Pass | No JavaScript added |
| **Rule IV** — Asset optimization | ✅ Pass | No images; `.sh` is plain text |
| **Rule V** — Accessibility & semantics | ✅ Pass | No HTML changes except text content in existing semantic elements |

**Post-design re-check**: All rules continue to pass. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/006-install-script/
├── plan.md              # This file
├── research.md          # Phase 0: signing tool, checksum format, execution flow
├── data-model.md        # Phase 1: platform matrix, entities, state transitions
├── quickstart.md        # Phase 1: dev workflow, testing, acceptance checklist
├── contracts/
│   ├── install-sh-interface.md      # Script inputs/outputs/exit codes
│   └── releases-folder-structure.md # Build pipeline contract
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
public/
└── install.sh           # NEW: POSIX sh install script (~200 lines)

src/
├── components/
│   └── Hero.astro       # UPDATED: bash → sh (done)
└── content/
    └── docs/
        └── installation.md  # UPDATED: bash → sh (done)
```

**Structure Decision**: Single-file addition to `public/` — the simplest possible structure. The script is a static text file with no build-time transformation. All existing directories are preserved; no new directories in `src/` are required.

## Complexity Tracking

No Constitution violations. No complexity justification required.

---

## Phase 0 Research Summary

All research complete. See [research.md](./research.md) for full decisions and rationale.

| Decision | Resolution |
|----------|------------|
| Signing tool | **OpenSSL** — universally available (LibreSSL on macOS, openssl on Linux); GPG rejected (not on stock macOS) |
| Checksum tool | **Runtime detection** — `sha256sum` (Linux) or `shasum -a 256` (macOS) |
| Checksum file format | **`SHA256SUMS`** — GNU coreutils multi-binary format |
| Signature file | **`SHA256SUMS.sig`** — OpenSSL detached signature |
| Public key distribution | **Embedded heredoc** in `install.sh` → written to temp file at runtime |
| Execution flow | Prerequisites → platform detect → install dir → upgrade check → download → verify sig → verify checksum → atomic install → PATH guidance |
| Temp dir cleanup | `mktemp -d` + `trap 'rm -rf "${WORK_DIR}"' EXIT INT TERM` |
| Script hosting | `public/install.sh` → served at `https://apps.microcode.io/dcv/install.sh` via existing S3/CloudFront pipeline |

---

## tasks.md Status

`tasks.md` generated 2026-03-17 via `/speckit.tasks`. Implementation completed same date.

**Deviations from plan discovered during implementation:**
- Step numbering in plan.md (steps 1–10) does not perfectly align with task comment labels (STEP 1–10) due to US2 verification being split into two sub-steps (7a signature, 7b checksum) and later merged into a single STEP 7 label. No functional impact.
- STEP 6 download comment originally referenced a US2 placeholder comment; this stale reference was cleaned up during T021.
- `TMP_SUMS` and `UPGRADE` variables initialized to empty string / 0 before the idempotency check block to satisfy `set -u` (unbound variable strictness) — not explicitly called out in plan.md step 4, but consistent with the intent.

---

## Phase 1 Design Artifacts

All Phase 1 artifacts are complete:

- **[data-model.md](./data-model.md)**: Platform identity, installation target, release artifact set, embedded public key, ephemeral working directory, existing installation state, environment variables, state transition diagram
- **[contracts/install-sh-interface.md](./contracts/install-sh-interface.md)**: Script inputs (env vars, system state), stdout progress format, stderr error format, exit codes, side effects, prerequisites, idempotency guarantee
- **[contracts/releases-folder-structure.md](./contracts/releases-folder-structure.md)**: Required files, `SHA256SUMS` format, signing/verification commands, HTTP requirements, key rotation procedure
- **[quickstart.md](./quickstart.md)**: Key implementation patterns (heredoc key embedding, platform detection with `case`, `trap` cleanup), signing key generation, mock artifact creation, local testing options, cross-platform test matrix, acceptance checklist

---

## Implementation Notes

### Step 0: Lint Gate

Before committing, run:

```sh
shellcheck --shell=sh public/install.sh
```

Zero warnings or errors required — this is a hard gate. See `quickstart.md` §Lint for install instructions (`brew install shellcheck` / `apt-get install shellcheck`).

---

### Script Execution Order

Each step cross-references the artifact(s) that provide full implementation detail.

**1. Check prerequisites** — verify `curl`, `openssl`, and `sha256sum`/`shasum` are on `PATH`

- Detection pattern: `research.md` Decision 2 (`command -v`, not `which`)
- Error message format for each missing tool: `contracts/install-sh-interface.md` §Prerequisites
- Exit immediately before any network requests if any prerequisite is missing (FR-013)

**2. Detect platform** — `uname -s` and `uname -m`; normalize to `darwin`/`linux` × `arm64`/`x64`

- Platform matrix and normalization rules: `data-model.md` §Platform Identity
- Arch aliases: `aarch64` → `arm64`, `x86_64` → `x64`
- Error message for unsupported OS/arch: `contracts/install-sh-interface.md` §Stderr

**3. Resolve install directory** — `$DCV_INSTALL_PATH` or default `$HOME/.local/bin`; `mkdir -p`; writability check

- Entity spec: `data-model.md` §Installation Target
- Environment variable contract: `contracts/install-sh-interface.md` §Environment Variables
- If directory is not writable after creation: exit 1 with a permission error identifying the path

**4. Idempotency check** — if binary exists at install path, compare checksums; exit 0 if already current

- Entity: `data-model.md` §Existing Installation State
- Download only `SHA256SUMS` to a plain temp file (not `WORK_DIR` — that is not created yet):
  ```sh
  TMP_SUMS="$(mktemp "${TMPDIR:-/tmp}/dcv-sums.XXXXXX")"
  trap 'rm -f "${TMP_SUMS}"' EXIT INT TERM
  curl -fsSL "${BASE_URL}/SHA256SUMS" -o "${TMP_SUMS}"
  LATEST_HASH="$(grep "dcv-${OS}-${ARCH}" "${TMP_SUMS}" | awk '{print $1}')"
  INSTALLED_HASH="$(${SHA256_CMD} "${INSTALL_PATH}" | awk '{print $1}')"
  if [ "${LATEST_HASH}" = "${INSTALLED_HASH}" ]; then
      echo "dcv is already up to date at ${INSTALL_PATH}"
      exit 0
  fi
  ```
- **Security decision**: Signature verification on `SHA256SUMS` is intentionally skipped during the idempotency check. The trust basis is the already-installed binary — if its hash matches the published hash, no new artifacts are being installed and nothing changes on disk. Full sig+checksum verification runs only when a new binary is about to be installed (steps 7–8). Verifying the signature before even knowing whether a download is needed would require creating `WORK_DIR` early for no benefit.

**5. Create `WORK_DIR`** with cleanup trap

- Pattern: `research.md` Decision 6
- Entity: `data-model.md` §Working Directory
- `WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dcv-install.XXXXXX")"` then `trap 'rm -rf "${WORK_DIR}"' EXIT INT TERM`
- The trap from step 4 (`TMP_SUMS`) should be superseded: replace with a single trap that removes both, or restructure so `WORK_DIR` handles all cleanup from this point

**6. Download binary + `SHA256SUMS` + `SHA256SUMS.sig`** to `WORK_DIR`

- URL construction: `contracts/releases-folder-structure.md` §Required Files
  - `${BASE_URL}/dcv-${OS}-${ARCH}` — binary
  - `${BASE_URL}/SHA256SUMS` — checksum file
  - `${BASE_URL}/SHA256SUMS.sig` — signature file
- Use `curl -fsSL` for each download (follow redirects; fail on HTTP error)
- Download each to a named file in `WORK_DIR`; check exit code individually (no pipes — FR-020 POSIX sh)
- Network failure error format: `contracts/install-sh-interface.md` §Stderr

**7. Verify signature** — write embedded public key heredoc → `openssl dgst -sha256 -verify`

- Exact command: `research.md` Decision 1
- Error message: `contracts/install-sh-interface.md` §Stderr ("Signature verification failed. The release may have been tampered with.")
- **Public key placeholder**: Until the build pipeline generates the signing key, use a clearly-marked placeholder:
  ```sh
  # TODO(build-pipeline): Replace <PUBLIC_KEY_PLACEHOLDER> with the actual RSA/Ed25519
  # public key PEM before the first release. See:
  #   specs/006-install-script/contracts/releases-folder-structure.md §Key Rotation
  cat > "${WORK_DIR}/pubkey.pem" <<'EOF'
  -----BEGIN PUBLIC KEY-----
  <PUBLIC_KEY_PLACEHOLDER>
  -----END PUBLIC KEY-----
  EOF
  ```
  The script with the placeholder can be committed and linted. Key replacement is a separate task performed once the build pipeline is ready.

**8. Verify checksum** — 3-step comparison assembled from `research.md` Decisions 2–3

```sh
# Step 1: Extract expected hash from the (now-trusted) SHA256SUMS
EXPECTED_HASH="$(grep "dcv-${OS}-${ARCH}" "${WORK_DIR}/SHA256SUMS" | awk '{print $1}')"

# Step 2: Compute actual hash of the downloaded binary
ACTUAL_HASH="$(${SHA256_CMD} "${WORK_DIR}/dcv-${OS}-${ARCH}" | awk '{print $1}')"

# Step 3: Compare
if [ "${EXPECTED_HASH}" != "${ACTUAL_HASH}" ]; then
    echo "Error: Checksum mismatch for dcv-${OS}-${ARCH}." >&2
    echo "Expected: ${EXPECTED_HASH}" >&2
    echo "Got:      ${ACTUAL_HASH}" >&2
    echo "This may indicate a corrupted download. Re-run the install command to try again." >&2
    exit 1
fi
```

- Error message format (exact wording): `contracts/install-sh-interface.md` §Stderr ("Checksum mismatch")
- `SHA256_CMD` is set in step 1 via runtime detection: `research.md` Decision 2

**9. Atomic install** — `chmod +x`; `mv`

- `chmod +x "${WORK_DIR}/dcv-${OS}-${ARCH}"`
- `mv "${WORK_DIR}/dcv-${OS}-${ARCH}" "${INSTALL_DIR}/dcv"`
- `mv` on the same filesystem is atomic; the `WORK_DIR` is under `$TMPDIR` which is typically on the same filesystem as `$HOME` on macOS (session temp dir) and Linux (both under the OS volume)
- Mode after install: `0755` (FR-009)

**10. PATH guidance** — check `$PATH`; emit shell-specific guidance if install dir is absent; skip if `DCV_INSTALL_PATH` is set

- Stdout format for guidance: `contracts/install-sh-interface.md` §Stdout
- POSIX-safe PATH membership check and shell-to-RC-file mapping:
  ```sh
  # Only emit PATH guidance when using the default install dir (DCV_INSTALL_PATH not set)
  if [ -z "${DCV_INSTALL_PATH:-}" ]; then
      case ":${PATH}:" in
          *":${INSTALL_DIR}:"*)
              : ;;  # already in PATH — no guidance needed
          *)
              echo ""
              echo "Note: ${INSTALL_DIR} is not in your PATH."
              case "${SHELL:-}" in
                  */zsh)
                      echo "Add to ~/.zshrc:"
                      echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
                      echo "Then restart your shell or run: source ~/.zshrc"
                      ;;
                  */bash)
                      echo "Add to ~/.bashrc:"
                      echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
                      echo "Then restart your shell or run: source ~/.bashrc"
                      ;;
                  */fish)
                      # fish does not support `export PATH=`; use fish_add_path instead
                      echo "Run:"
                      echo "  fish_add_path \$HOME/.local/bin"
                      echo "Then restart your shell."
                      ;;
                  *)
                      echo "Add this line to your shell configuration file:"
                      echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
                      echo "Then restart your shell."
                      ;;
              esac
              ;;
      esac
  fi
  ```

**11. Success message**

- Exact format: `contracts/install-sh-interface.md` §Stdout
- Three variants: "dcv installed successfully!", "dcv updated successfully!", "dcv is already up to date at \<path\>"
- All variants followed by: `To verify: dcv --version`

---

### Key POSIX sh Patterns

```sh
# Embedded public key (no bash process substitution needed)
cat > "${PUBKEY_FILE}" <<'EOF'
-----BEGIN PUBLIC KEY-----
...
-----END PUBLIC KEY-----
EOF

# Platform detection (case, not [[ ]])
case "$(uname -s)" in
  Darwin) OS="darwin" ;;
  Linux)  OS="linux"  ;;
  *) echo "Error: Unsupported OS" >&2; exit 1 ;;
esac

# Checksum tool detection (command -v, not which)
if command -v sha256sum > /dev/null 2>&1; then
    SHA256_CMD="sha256sum"
elif command -v shasum > /dev/null 2>&1; then
    SHA256_CMD="shasum -a 256"
else
    echo "Error: sha256sum or shasum required" >&2; exit 1
fi

# Atomic install
chmod +x "${WORK_DIR}/dcv-${OS}-${ARCH}"
mv "${WORK_DIR}/dcv-${OS}-${ARCH}" "${INSTALL_DIR}/dcv"
```

---

### External Dependencies (not in dcv-web repo)

The following must be provided by the dcv build pipeline before the install script can be fully tested end-to-end:
1. Release binaries at `https://apps.microcode.io/dcv/releases/latest/`
2. `SHA256SUMS` + `SHA256SUMS.sig` at the same path
3. The RSA/Ed25519 **public key** to embed in `install.sh`

These are build pipeline concerns, not dcv-web concerns. The install script can be written and linted without them; the public key placeholder (step 7) is replaced once the pipeline is ready. End-to-end testing requires all three.
