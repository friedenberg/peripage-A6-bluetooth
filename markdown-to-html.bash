#! /usr/bin/env -S bash -e

target="$1"

pandoc \
  --output "$target.html" \
  --standalone \
  --embed-resources \
  --css "peri-a6.css" \
  "$target"

# TODO rename to markdown-to-pa6e and do the following
# html-to-pdf "$target.html" '"paperWidth": 2.2409, "marginLeft": 0, "marginRight": 0'
# crop PDF
# convert to PNG
# use uv run pa6e
