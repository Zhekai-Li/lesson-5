#!/bin/bash
# Display seven-column TSV recommendation records received on stdin.

set -u
input=$(mktemp "${TMPDIR:-/tmp}/book-recommendation-screen.XXXXXX") || exit 1
display=$(mktemp "${TMPDIR:-/tmp}/book-recommendation-display.XXXXXX") || { rm -f "$input"; exit 1; }
trap 'rm -f "$input" "$display"' EXIT HUP INT TERM
cat > "$input"

if [ ! -s "$input" ]; then
  gum style --foreground 214 'No new recommendations matched yet.'
  exit 0
fi

# Keep the terminal table readable while preserving full links in component output.
awk -F '\t' '
  function clip(value, limit) {
    return length(value) > limit ? substr(value, 1, limit - 3) "..." : value
  }
  {
    link = ($7 == "N/A" ? "N/A" : "OpenLibrary")
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $1, clip($2, 23), clip($3, 19), clip($4, 15), $5, clip($6, 32), link
  }
' "$input" > "$display"

gum table --print --separator $'\t' \
  --columns 'Score,Title,Author,Genre,Year,Why,Link' \
  --widths '5,22,18,14,6,31,12' < "$display"
