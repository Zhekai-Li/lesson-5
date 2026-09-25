#!/bin/bash
# Favor catalog genres that do not yet appear in the user's library.

set -u
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DB="$ROOT_DIR/data/book_database.sh"
CATALOG="$ROOT_DIR/books/catalog.tsv"

[ "${TEST_AGENT_DELAY:-0}" = "0" ] || sleep "$TEST_AGENT_DELAY"

covered=$($DB list | awk -F '\t' '{ printf "|%s", tolower($3) } END { print "|" }')

awk -F '\t' -v covered="$covered" '
  index(covered, "|" tolower($3) "|") == 0 {
    printf "74\t%s\t%s\t%s\t%s\tOpens a path into an underexplored genre: %s\t%s\n", $1, $2, $3, $4, $3, $5
  }
' "$CATALOG"
