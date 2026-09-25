#!/bin/bash
# Dependency-free integration tests for the Bash application.

set -u
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/book-manager-tests.XXXXXX") || exit 1
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM
export BOOK_DB_FILE="$test_dir/library.csv"

passed=0
failed=0

pass() { passed=$((passed + 1)); printf 'ok %d - %s\n' "$passed" "$1"; }
fail() { failed=$((failed + 1)); printf 'not ok - %s\n' "$1" >&2; }
assert_eq() {
  if [ "$1" = "$2" ]; then pass "$3"; else fail "$3 (expected: $2; actual: $1)"; fi
}
assert_contains() {
  case $1 in *"$2"*) pass "$3" ;; *) fail "$3 (missing: $2)" ;; esac
}

DB="$ROOT_DIR/data/book_database.sh"
MANAGE="$ROOT_DIR/workflows/manage_library.sh"
METADATA="$ROOT_DIR/books/fetch_book_metadata.sh"
SEARCH="$ROOT_DIR/books/search_books.sh"
REFINE="$ROOT_DIR/recommendations/refine_recommendations.sh"
RECOMMEND="$ROOT_DIR/workflows/get_recommendations.sh"

printf '1..23\n'

$DB init
assert_eq "$(sed -n '1p' "$BOOK_DB_FILE")" 'title,author,genre,year,status,rating,link' 'init creates the seven-column schema'

$DB add 'A "Quoted", Book' 'Doe, Jane' 'Literature' 2024 reading 5 'https://example.test/a,b'
row=$($DB list)
assert_contains "$row" $'A "Quoted", Book\tDoe, Jane\tLiterature\t2024\treading\t5\thttps://example.test/a,b' 'CSV commas and quotes round-trip'

if $DB exists 'a "quoted", book' 'doe, jane'; then pass 'exists is case-insensitive'; else fail 'exists is case-insensitive'; fi
if $DB exists Missing Nobody; then fail 'exists returns nonzero for a missing book'; else pass 'exists returns nonzero for a missing book'; fi

if $DB add 'A "Quoted", Book' 'Doe, Jane' Literature 2024 reading 5 link >/dev/null 2>&1; then fail 'duplicate add is rejected'; else pass 'duplicate add is rejected'; fi
if $DB add Invalid Author Genre 2024 someday '' link >/dev/null 2>&1; then fail 'invalid status is rejected'; else pass 'invalid status is rejected'; fi
if $DB add Invalid Author Genre 2024 reading 9 link >/dev/null 2>&1; then fail 'invalid rating is rejected'; else pass 'invalid rating is rejected'; fi

inode_before=$(ls -i "$BOOK_DB_FILE" | awk '{print $1}')
$DB update-status 'A "Quoted", Book' 'Doe, Jane' completed
inode_after=$(ls -i "$BOOK_DB_FILE" | awk '{print $1}')
[ "$inode_before" != "$inode_after" ] && pass 'updates atomically replace the database file' || fail 'updates atomically replace the database file'
$DB update-rating 'A "Quoted", Book' 'Doe, Jane' 4
assert_contains "$($DB list)" $'\tcompleted\t4\t' 'status and rating updates persist'

known=$($METADATA 'The Gene' 'Siddhartha Mukherjee')
assert_contains "$known" $'Science\t2016\t' 'known metadata is enriched offline'
unknown=$($METADATA 'Uncatalogued Work' 'A. Writer')
assert_eq "$unknown" $'Uncatalogued Work\tA. Writer\tOther\tUnknown\tN/A' 'unknown metadata has explicit defaults'

assert_contains "$($SEARCH literature)" 'A "Quoted", Book' 'search accepts a command-line term'
assert_contains "$(printf 'DOE\n' | $SEARCH)" 'Doe, Jane' 'search accepts stdin and ignores case'
assert_eq "$($SEARCH no-such-value)" '' 'search returns no rows for no match'

$MANAGE add 'The Gene' 'Siddhartha Mukherjee' want-to-read ''
assert_contains "$($MANAGE list)" $'The Gene\tSiddhartha Mukherjee\tScience\t2016' 'add workflow composes metadata and database'

refined=$(printf '%s\n' \
  $'99\tThe Gene\tSiddhartha Mukherjee\tScience\t2016\tAlready owned\tlink' \
  $'70\tKindred\tOctavia E. Butler\tLiterature\t1979\tLower duplicate\tlink' \
  $'91\tKindred\tOctavia E. Butler\tLiterature\t1979\tHigher duplicate\tlink' \
  $'90\tSPQR\tMary Beard\tHistory\t2015\tReason\tlink' \
  $'89\tRange\tDavid Epstein\tPsychology\t2019\tReason\tlink' \
  $'88\tExhalation\tTed Chiang\tScience Fiction\t2019\tReason\tlink' \
  $'87\tWays of Seeing\tJohn Berger\tArt\t1972\tReason\tlink' \
  $'86\tSapiens\tYuval Noah Harari\tHistory\t2011\tReason\tlink' | $REFINE)
assert_eq "$(printf '%s\n' "$refined" | wc -l | tr -d ' ')" 5 'refinement limits output to five'
assert_eq "$(printf '%s\n' "$refined" | head -1 | cut -f1-2)" $'91\tKindred' 'refinement keeps the best duplicate and sorts scores'
case $refined in *'The Gene'*) fail 'refinement excludes owned books' ;; *) pass 'refinement excludes owned books' ;; esac

start=$(date +%s)
TEST_AGENT_DELAY=1 $RECOMMEND 'technology psychology' > "$test_dir/recommendations.tsv" 2> "$test_dir/progress.log"
elapsed=$(( $(date +%s) - start ))
[ "$elapsed" -lt 3 ] && pass 'recommendation agents run concurrently' || fail 'recommendation agents run concurrently'
if grep -q '^\[recommendations\]' "$test_dir/recommendations.tsv"; then fail 'progress stays off stdout'; else pass 'progress stays off stdout'; fi
if grep -q 'History agent complete' "$test_dir/progress.log" && grep -q 'Refining combined' "$test_dir/progress.log"; then pass 'workflow reports agent progress on stderr'; else fail 'workflow reports agent progress on stderr'; fi

syntax_failures=0
while IFS= read -r script; do
  bash -n "$script" || syntax_failures=$((syntax_failures + 1))
done <<EOF
$(find "$ROOT_DIR" -name '*.sh' -type f)
EOF
[ "$syntax_failures" -eq 0 ] && pass 'all shell scripts pass bash -n' || fail 'all shell scripts pass bash -n'

direct_access=$(grep -R -l 'books\.csv' "$ROOT_DIR/app.sh" "$ROOT_DIR/ui" "$ROOT_DIR/workflows" "$ROOT_DIR/books" "$ROOT_DIR/recommendations" 2>/dev/null || true)
assert_eq "$direct_access" '' 'only the data layer names the production CSV'

printf '# %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
