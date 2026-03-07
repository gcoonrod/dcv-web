---
title: "Installation"
description: "Install the dcv binary on macOS, Linux, or Windows."
order: 1
---

# Installation

## Quick Install (Recommended)

```bash
curl -fsSL https://dcv.dev/install.sh | bash
```

> **Note:** Before running any `curl | bash` installer, you can review the script contents at `https://dcv.dev/install.sh`, or use the manual installation steps below.

## Manual Binary Download

Download the latest binary for your platform from the [releases page](https://github.com/gcoonrod/dcv/releases).

| Platform | Binary |
|---|---|
| macOS (Apple Silicon) | `dcv-macos-arm64` |
| macOS (Intel) | `dcv-macos-x86_64` |
| Linux (x86_64) | `dcv-linux-x86_64` |
| Windows | `dcv-windows-x86_64.exe` |

Place the binary in a directory on your `$PATH` and make it executable:

```bash
chmod +x dcv-macos-arm64
mv dcv-macos-arm64 /usr/local/bin/dcv
```

Verify the install:

```bash
dcv --version
```
