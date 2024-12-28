#! /usr/bin/env -S bash -e

target="$1"

ls .

pandoc \
  --output "$target.html" \
  --standalone \
  --embed-resources \
  --css "peri-a6.css" \
  "$target"
