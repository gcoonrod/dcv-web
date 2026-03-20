---
title: "Installation"
description: "Install the dcv binary on macOS, Linux, or Windows."
order: 1
---

# Installation

## Quick Install (Recommended)

```sh
curl -fsSL https://apps.microcode.io/dcv/install.sh | sh
```

> **Note:** Before running any `curl | sh` installer, you can review the script contents at `https://apps.microcode.io/dcv/install.sh`, or use the manual installation steps below.

## Manual Installation

Download the latest binary for your platform using:

```bash
curl -fsSL https://apps.microcode.io/dcv/releases/latest/BINARY_NAME -o dcv
```

Replace `BINARY_NAME` with the appropriate binary for your platform:

| Platform | Binary Name |
|---|---|
| macOS (Apple Silicon) | `dcv-darwin-arm64` |
| macOS (Intel) | `dcv-darwin-x64` |
| Linux (x86_64) | `dcv-linux-x64` |
| Linux (Arm) | `dcv-linux-arm64` |

Verify the binary checksum:

```bash
# Download the checksum file
curl -fsSL https://apps.microcode.io/dcv/releases/latest/SHA256SUMS -o SHA256SUMS

# Verify your downloaded binary
sha256sum -c SHA256SUMS          # Linux
# or on macOS:
shasum -a 256 -c SHA256SUMS
```

Copy the binary into your PATH:

```bash
chmod +x dcv && mv dcv /usr/local/bin/dcv
```

Verify the install:

```bash
dcv --version
```
