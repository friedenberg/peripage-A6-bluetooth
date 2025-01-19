#! /usr/bin/env -S bash -e

dir_nix_store="$(realpath "$(dirname "$0")/../")"

target="$1"

pandoc \
  --output "$target.html" \
  --standalone \
  --embed-resources \
  --css "$dir_nix_store/peri-a6.css" \
  "$target"

html-to-pdf "$target.html" '"paperWidth": 2.2409, "marginLeft": 0, "marginRight": 0'
magick -density 300 "$target.html.pdf" -background white -flatten -resize 50% "$target.html.pdf.png"
magick "$target.html.pdf.png" -gravity North \
  -background white -splice 0x1 \
  -background black -splice 0x1 \
  -trim +repage -chop 0x1 \
  "$target-trimmed.html.pdf.png"

uv run pa6e "$target-trimmed.html.pdf.png"
