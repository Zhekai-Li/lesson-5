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
    link = ($7 == "N/A" ? "N/A" : "openlibrary.org")
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $1, clip($2, 28), clip($3, 25), clip($4, 16), $5, clip($6, 48), link
  }
' "$input" > "$display"

gum table --print --separator $'\t' \
  --columns 'Score,Title,Author,Genre,Year,Why,Link' \
  --widths '6,27,24,16,6,47,15' < "$display"
