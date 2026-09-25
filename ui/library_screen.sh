#!/bin/bash
# Display seven-column TSV library records received on stdin.

set -u
input=$(mktemp "${TMPDIR:-/tmp}/book-library-screen.XXXXXX") || exit 1
trap 'rm -f "$input"' EXIT HUP INT TERM
cat > "$input"

if [ ! -s "$input" ]; then
  gum style --foreground 214 'No books found.'
  exit 0
fi

gum table --print --separator $'\t' \
  --columns 'Title,Author,Genre,Year,Status,Rating,Link' \
  --widths '28,20,16,6,13,6,26' < "$input"
