#! /usr/bin/env -S bash -ex

qr="$1"
nix run . label.md
img="$(realpath "label.md-trimmed.html.pdf.png")"
mv "$img" old/label.png
pushd old
pa6e -p A6p -m "$peri_secondary" -i "label.png" -c 2
