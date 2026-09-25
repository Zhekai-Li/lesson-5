#!/bin/bash
# Display seven-column TSV library records received on stdin.

set -u
input=$(mktemp "${TMPDIR:-/tmp}/book-library-screen.XXXXXX") || exit 1
display=$(mktemp "${TMPDIR:-/tmp}/book-library-display.XXXXXX") || { rm -f "$input"; exit 1; }
trap 'rm -f "$input" "$display"' EXIT HUP INT TERM
cat > "$input"

if [ ! -s "$input" ]; then
  gum style --foreground 214 'No books found.'
  exit 0
fi

# Keep full links in component output while using a compact label in the UI.
awk -F '\t' '
  function clip(value, limit) {
    return length(value) > limit ? substr(value, 1, limit - 3) "..." : value
  }
  {
    link = ($7 == "N/A" ? "N/A" : "OpenLibrary")
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", clip($1, 28), clip($2, 21), clip($3, 17), $4, $5, $6, link
  }
' "$input" > "$display"

gum table --print --separator $'\t' \
  --columns 'Title,Author,Genre,Year,Status,Rating,Link' \
  --widths '27,20,16,6,13,6,12' < "$display"
