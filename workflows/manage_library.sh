#!/bin/bash
# Coordinate book components and the database without owning either concern.

set -u
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DB="$ROOT_DIR/data/book_database.sh"
METADATA="$ROOT_DIR/books/fetch_book_metadata.sh"
SEARCH="$ROOT_DIR/books/search_books.sh"

command_name=${1:-}
[ -n "$command_name" ] || { printf 'Usage: manage_library.sh <list|add|search|update-status|update-rating> ...\n' >&2; exit 2; }
shift

case $command_name in
  list)
    [ "$#" -eq 0 ] || exit 2
    exec "$DB" list
    ;;
  add)
    [ "$#" -ge 2 ] && [ "$#" -le 4 ] || { printf 'Usage: manage_library.sh add TITLE AUTHOR [STATUS] [RATING]\n' >&2; exit 2; }
    title=$1; author=$2; status=${3:-want-to-read}; rating=${4:-}
    metadata=$($METADATA "$title" "$author") || exit $?
    old_ifs=$IFS
    IFS=$'\t'
    read -r canonical_title canonical_author genre year link <<EOF
$metadata
EOF
    IFS=$old_ifs
    "$DB" add "$canonical_title" "$canonical_author" "$genre" "$year" "$status" "$rating" "$link"
    ;;
  search)
    [ "$#" -eq 1 ] || { printf 'Usage: manage_library.sh search TERM\n' >&2; exit 2; }
    exec "$SEARCH" "$1"
    ;;
  update-status)
    [ "$#" -eq 3 ] || { printf 'Usage: manage_library.sh update-status TITLE AUTHOR STATUS\n' >&2; exit 2; }
    exec "$DB" update-status "$1" "$2" "$3"
    ;;
  update-rating)
    [ "$#" -eq 3 ] || { printf 'Usage: manage_library.sh update-rating TITLE AUTHOR RATING\n' >&2; exit 2; }
    exec "$DB" update-rating "$1" "$2" "$3"
    ;;
  *) printf 'Error: unknown library command: %s\n' "$command_name" >&2; exit 2 ;;
esac
