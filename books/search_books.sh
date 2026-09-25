#!/bin/bash
# Search the library by argument or a term read from stdin.

set -u
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if [ "$#" -eq 1 ]; then
  term=$1
elif [ "$#" -eq 0 ]; then
  IFS= read -r term || exit 1
else
  printf 'Usage: search_books.sh [TERM]\n' >&2
  exit 2
fi

[ -n "$term" ] || { printf 'Error: search term is required\n' >&2; exit 1; }
exec "$ROOT_DIR/data/book_database.sh" search "$term"
