#!/bin/bash
# The application's only interface to the CSV book database.

set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DB_FILE=${BOOK_DB_FILE:-"$SCRIPT_DIR/books.csv"}
HEADER='title,author,genre,year,status,rating,link'

usage() {
  cat >&2 <<'EOF'
Usage: book_database.sh init
       book_database.sh list
       book_database.sh search TERM
       book_database.sh exists TITLE AUTHOR
       book_database.sh add TITLE AUTHOR GENRE YEAR STATUS RATING LINK
       book_database.sh update-status TITLE AUTHOR STATUS
       book_database.sh update-rating TITLE AUTHOR RATING
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

valid_text() {
  case $1 in
    *$'\n'*|*$'\r'*|*$'\t'*) return 1 ;;
  esac
  return 0
}

valid_status() {
  case $1 in
    want-to-read|reading|completed|paused) return 0 ;;
    *) return 1 ;;
  esac
}

valid_rating() {
  case $1 in
    ''|1|2|3|4|5) return 0 ;;
    *) return 1 ;;
  esac
}

check_identity() {
  [ -n "$1" ] || fail "title is required"
  [ -n "$2" ] || fail "author is required"
  valid_text "$1" || fail "title cannot contain tabs or newlines"
  valid_text "$2" || fail "author cannot contain tabs or newlines"
}

csv_quote() {
  local value=$1
  value=${value//\"/\"\"}
  printf '"%s"' "$value"
}

write_row() {
  local first=1 value
  for value in "$@"; do
    if [ "$first" -eq 0 ]; then printf ','; fi
    csv_quote "$value"
    first=0
  done
  printf '\n'
}

ensure_database() {
  if [ ! -s "$DB_FILE" ]; then
    mkdir -p "$(dirname -- "$DB_FILE")" || fail "cannot create database directory"
    printf '%s\n' "$HEADER" > "$DB_FILE" || fail "cannot initialize database"
  fi
}

# Parse RFC 4180-style quoted CSV and emit the seven application fields as TSV.
read_rows() {
  awk '
    function splitcsv(line, out,    i, c, count, field, quoted) {
      count = 0; field = ""; quoted = 0
      for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        if (quoted) {
          if (c == "\"") {
            if (substr(line, i + 1, 1) == "\"") { field = field "\""; i++ }
            else { quoted = 0 }
          } else { field = field c }
        } else if (c == "\"") { quoted = 1 }
        else if (c == ",") { out[++count] = field; field = "" }
        else { field = field c }
      }
      out[++count] = field
      return count
    }
    NR == 1 { next }
    {
      delete f
      if (splitcsv($0, f) >= 7) {
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", f[1], f[2], f[3], f[4], f[5], f[6], f[7]
      }
    }
  ' "$DB_FILE"
}

rewrite_field() {
  local title=$1 author=$2 field_number=$3 replacement=$4 temp rc
  temp=$(mktemp "${DB_FILE}.tmp.XXXXXX") || fail "cannot create temporary database"
  awk -v wanted_title="$title" -v wanted_author="$author" -v field_number="$field_number" -v replacement="$replacement" '
    function splitcsv(line, out,    i, c, count, field, quoted) {
      count = 0; field = ""; quoted = 0
      for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        if (quoted) {
          if (c == "\"") {
            if (substr(line, i + 1, 1) == "\"") { field = field "\""; i++ }
            else { quoted = 0 }
          } else { field = field c }
        } else if (c == "\"") { quoted = 1 }
        else if (c == ",") { out[++count] = field; field = "" }
        else { field = field c }
      }
      out[++count] = field
      return count
    }
    function quote(value, escaped) {
      escaped = value
      gsub(/"/, "\"\"", escaped)
      return "\"" escaped "\""
    }
    NR == 1 { print "title,author,genre,year,status,rating,link"; next }
    {
      delete f
      splitcsv($0, f)
      if (tolower(f[1]) == tolower(wanted_title) && tolower(f[2]) == tolower(wanted_author)) {
        f[field_number] = replacement
        found = 1
      }
      print quote(f[1]) "," quote(f[2]) "," quote(f[3]) "," quote(f[4]) "," quote(f[5]) "," quote(f[6]) "," quote(f[7])
    }
    END { if (!found) exit 3 }
  ' "$DB_FILE" > "$temp"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    rm -f "$temp"
    [ "$rc" -eq 3 ] && fail "book not found"
    fail "database update failed"
  fi
  mv "$temp" "$DB_FILE" || { rm -f "$temp"; fail "cannot replace database"; }
}

command_name=${1:-}
[ -n "$command_name" ] || { usage; exit 2; }
shift

case $command_name in
  init)
    [ "$#" -eq 0 ] || { usage; exit 2; }
    ensure_database
    ;;
  list)
    [ "$#" -eq 0 ] || { usage; exit 2; }
    ensure_database
    read_rows
    ;;
  search)
    [ "$#" -eq 1 ] || { usage; exit 2; }
    ensure_database
    read_rows | awk -F '\t' -v term="$1" 'BEGIN { term = tolower(term) } index(tolower($0), term) > 0'
    ;;
  exists)
    [ "$#" -eq 2 ] || { usage; exit 2; }
    ensure_database
    check_identity "$1" "$2"
    read_rows | awk -F '\t' -v title="$1" -v author="$2" '
      tolower($1) == tolower(title) && tolower($2) == tolower(author) { found = 1; exit }
      END { exit(found ? 0 : 1) }
    '
    ;;
  add)
    [ "$#" -eq 7 ] || { usage; exit 2; }
    ensure_database
    check_identity "$1" "$2"
    valid_status "$5" || fail "status must be want-to-read, reading, completed, or paused"
    valid_rating "$6" || fail "rating must be blank or an integer from 1 to 5"
    for value in "$3" "$4" "$7"; do valid_text "$value" || fail "fields cannot contain tabs or newlines"; done
    if "$0" exists "$1" "$2"; then fail "book already exists"; fi
    temp=$(mktemp "${DB_FILE}.tmp.XXXXXX") || fail "cannot create temporary database"
    cp "$DB_FILE" "$temp" || { rm -f "$temp"; fail "cannot copy database"; }
    write_row "$1" "$2" "$3" "$4" "$5" "$6" "$7" >> "$temp" || { rm -f "$temp"; fail "cannot write database"; }
    mv "$temp" "$DB_FILE" || { rm -f "$temp"; fail "cannot replace database"; }
    ;;
  update-status)
    [ "$#" -eq 3 ] || { usage; exit 2; }
    ensure_database
    check_identity "$1" "$2"
    valid_status "$3" || fail "status must be want-to-read, reading, completed, or paused"
    rewrite_field "$1" "$2" 5 "$3"
    ;;
  update-rating)
    [ "$#" -eq 3 ] || { usage; exit 2; }
    ensure_database
    check_identity "$1" "$2"
    valid_rating "$3" || fail "rating must be blank or an integer from 1 to 5"
    rewrite_field "$1" "$2" 6 "$3"
    ;;
  *) usage; exit 2 ;;
esac
