# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

pa6e is a toolset for printing to Peripage A6 thermal printers via Bluetooth. It converts markdown to HTML, renders to PDF, rasterizes to PNG, and sends to the printer. The printer uses Bluetooth Serial Port Profile (BTSPP/RFCOMM), not ESC/POS.

## Architecture

- **`markdown-to-html.bash`** — Main pipeline script: markdown -> HTML (pandoc) -> PDF (chromium-html-to-pdf) -> PNG (imagemagick), then trims whitespace
- **`print_label.bash`** — End-to-end: runs the nix flake to build the label, then sends to printer via `peripage` CLI, optionally prints a QR code
- **`peri-a6.css`** — Print stylesheet for 57mm thermal paper (Azuro TF font, print media query only)
- **`label.md`** — Source content for labels (markdown with pipe-delimited lines)
- **`pp/`** — Python sub-package (uv workspace member) with PyBluez, Pillow, qrcode, tqdm dependencies for direct printer communication
- **`old/`** — Previous iteration with its own flake and venv

## Build & Run

Uses nix flakes + direnv. The dev shell provides: `uv`, `bluez`, `imagemagick`, `pandoc`, `chromium-html-to-pdf`.

```bash
# Enter dev environment (automatic with direnv)
direnv allow

# Build and run the markdown-to-html pipeline
nix run . label.md

# Print a label (requires printer BT connection)
./print_label.bash              # label only
./print_label.bash "https://..."  # label + QR code
```

## Justfile Commands

```bash
just secret-edit    # Reveal, edit, and re-hide .env secrets (git-secret)
just deploy         # Build and publish with uv
just version-edit   # Bump version in pyproject.toml and commit
just release        # version-edit + deploy + push
```

## Key Details

- Printer MAC addresses are exported in `.envrc` (`peri_primary`, `peri_secondary`)
- Secrets managed with `git-secret`; `.env` must be revealed for deployments
- The nix flake wraps `markdown-to-html.bash` as `pa6e-markdown-to-html` with all dependencies on PATH
- Paper width is set to 2.2409 inches (57mm) with zero side margins
- Printer native X resolution is 384 pixels
- Python dependencies managed with `uv`; workspace defined in root `pyproject.toml` with member `pp`
