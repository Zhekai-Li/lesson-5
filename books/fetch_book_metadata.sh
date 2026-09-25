#!/bin/bash
# Enrich TITLE and AUTHOR from the bundled offline catalog.

set -u
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CATALOG="$SCRIPT_DIR/catalog.tsv"

if [ "$#" -eq 2 ]; then
  title=$1
  author=$2
elif [ "$#" -eq 0 ]; then
  IFS=$'\t' read -r title author || exit 1
else
  printf 'Usage: fetch_book_metadata.sh TITLE AUTHOR\n' >&2
  exit 2
fi

[ -n "${title:-}" ] && [ -n "${author:-}" ] || { printf 'Error: title and author are required\n' >&2; exit 1; }

match=$(awk -F '\t' -v title="$title" -v author="$author" '
  tolower($1) == tolower(title) && tolower($2) == tolower(author) {
    printf "%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5
    exit
  }
' "$CATALOG")

if [ -n "$match" ]; then
  printf '%s\n' "$match"
else
  printf '%s\t%s\tOther\tUnknown\tN/A\n' "$title" "$author"
fi
