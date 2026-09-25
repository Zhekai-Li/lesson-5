#!/bin/bash
# Keep the best version of each candidate, exclude owned books, and return five.

set -u
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DB="$ROOT_DIR/data/book_database.sh"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/book-refine.XXXXXX") || exit 1
trap 'rm -rf "$work_dir"' EXIT HUP INT TERM

cat > "$work_dir/candidates.tsv"
$DB list > "$work_dir/library.tsv"

awk -F '\t' '
  FNR == NR {
    owned[tolower($1) SUBSEP tolower($2)] = 1
    next
  }
  NF >= 7 {
    key = tolower($2) SUBSEP tolower($3)
    if (!owned[key] && (!seen[key] || ($1 + 0) > best[key])) {
      seen[key] = 1
      best[key] = $1 + 0
      row[key] = $0
    }
  }
  END { for (key in row) print row[key] }
' "$work_dir/library.tsv" "$work_dir/candidates.tsv" |
  sort -t $'\t' -k1,1nr -k2,2 | awk 'NR <= 5'
