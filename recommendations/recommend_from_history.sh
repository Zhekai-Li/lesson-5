#!/bin/bash
# Recommend catalog books that resemble highly rated or completed reading.

set -u
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DB="$ROOT_DIR/data/book_database.sh"
CATALOG="$ROOT_DIR/books/catalog.tsv"

[ "${TEST_AGENT_DELAY:-0}" = "0" ] || sleep "$TEST_AGENT_DELAY"

favorite_genre=$($DB list | awk -F '\t' '
  $5 == "completed" { weight = ($6 == "" ? 1 : $6); count[tolower($3)] += weight }
  END { for (genre in count) print count[genre] "\t" genre }
' | sort -nr | awk -F '\t' 'NR == 1 { print $2 }')

if [ -z "$favorite_genre" ]; then
  favorite_genre=$($DB list | awk -F '\t' 'NR == 1 { print tolower($3) }')
fi

[ -n "$favorite_genre" ] || exit 0

awk -F '\t' -v genre="$favorite_genre" '
  tolower($3) == genre {
    printf "90\t%s\t%s\t%s\t%s\tMatches your strongest reading genre: %s\t%s\n", $1, $2, $3, $4, $3, $5
  }
' "$CATALOG"
