# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

pa6e is a toolset for printing to Peripage A6 thermal printers via Bluetooth. It converts markdown to HTML, renders to PDF, rasterizes to PNG, and sends to the printer. The printer uses Bluetooth Serial Port Profile (BTSPP/RFCOMM), not ESC/POS.

## Architecture

Two-stage pipeline: nix flake builds the image, then a separate script sends it to the printer.

**Stage 1 — Image generation** (`markdown-to-html.bash`, wrapped as `pa6e-markdown-to-html` by the nix flake):
1. pandoc: markdown → standalone HTML (embeds `peri-a6.css` which only applies via `@media print`)
2. html-to-pdf: HTML → PDF (chromium headless, 57mm/2.2409in paper width, zero side margins)
3. imagemagick: PDF → PNG at 300dpi, then trim whitespace via North-gravity splice+chop trick
4. Outputs `<input>-trimmed.html.pdf.png`

**Stage 2 — Printing** (`print_label.bash`):
- Runs `nix run . label.md`, moves output to `old/`, invokes `uv run peripage` from there
- Optional QR code printing via second `peripage` invocation (pass URL as first arg)
- Uses `peri_secondary` MAC address; 10s sleep between label and QR prints

**Supporting files:**
- `peri-a6.css` — Print stylesheet (Azuro TF font, `@media print` only)
- `label.md` — Source content for labels
- `pp/` — Python sub-package (uv workspace member) with PyBluez, Pillow, qrcode, tqdm
- `old/` — Previous iteration; also used as working directory by `print_label.bash`

## Build & Run

Uses nix flakes + direnv. The dev shell provides: `uv`, `bluez`, `imagemagick`, `pandoc`, `chromium-html-to-pdf`.

```bash
direnv allow                      # enter dev environment

nix run . label.md                # build image only (stage 1)
./print_label.bash                # build + print label (stages 1+2)
./print_label.bash "https://..."  # build + print label + QR code
```

## Justfile Commands

```bash
just secret-edit    # Reveal, edit, and re-hide .env secrets (git-secret)
just deploy         # Build and publish with uv
just version-edit   # Bump version in pyproject.toml and commit
just release        # version-edit + deploy + push
```

## Key Details

- Printer MAC addresses exported in `.envrc` (`peri_primary`, `peri_secondary`)
- Secrets managed with `git-secret`; `.env` must be revealed for deployments
- The nix flake wraps `markdown-to-html.bash` via `writeScriptBin` + `symlinkJoin` + `wrapProgram` so all dependencies are on PATH
- `chromium-html-to-pdf` comes from `github:friedenberg/chromium-html-to-pdf` flake input
- Printer native X resolution is 384 pixels
- Python workspace defined in root `pyproject.toml` with members `peripage` and `pp`; PyBluez pinned to a specific git rev
