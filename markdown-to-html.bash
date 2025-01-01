#! /usr/bin/env -S bash -xe

dir_nix_store="$(realpath "$(dirname "$0")/../")"

target="$1"

pandoc \
  --output "$target.html" \
  --standalone \
  --embed-resources \
  --css "$dir_nix_store/peri-a6.css" \
  "$target"

html-to-pdf "$target.html" '"paperWidth": 2.2409, "marginLeft": 0, "marginRight": 0'
# TODO
# crop PDF
# convert to PNG
# use uv run pa6e
