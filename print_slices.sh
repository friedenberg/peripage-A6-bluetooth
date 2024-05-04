#! /bin/bash -e

function egress {
  rm -rf build
  exit
}

trap egress EXIT

wait_user () {
  echo
  read -n 1 -s -r -p "Press any key to continue"
  echo
}

make_slices () {
  file="$1"
  slices="${2:-1x4@}"

  echo "making slices"
  convert "$file" -crop "$slices" +repage +adjoin build/to_print_%02d.png \
    2>/dev/null

  for unrotated in build/to_print_*.png; do
    echo "rotating slice $unrotated"
    convert "$unrotated" -rotate 90 "$unrotated" 2>/dev/null
  done
}

print_slice () {
  slice="$1"
  echo "printing slice $slice"
  ./ppa6-print.py -i "$slice" "c8-47-8c-00-d9-89"
}

print_slices () {
  for slice in build/to_print_*.png; do
    print_slice "$slice"
    wait_user
  done
}

mkdir -p build
make_slices "$1" "$2"
echo "Confirm slices look correct"
open -gW build/to_print_*.png
wait_user
print_slices

