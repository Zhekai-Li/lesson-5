#!/bin/bash
# A non-interactive, isolated walkthrough suitable for recording.

set -u
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
demo_dir=$(mktemp -d "${TMPDIR:-/tmp}/book-manager-demo.XXXXXX") || exit 1
trap 'rm -rf "$demo_dir"' EXIT HUP INT TERM
export BOOK_DB_FILE="$demo_dir/demo-library.csv"
pause=${DEMO_PAUSE:-1}

command -v gum >/dev/null 2>&1 || { printf 'Error: Gum is required for the demo.\n' >&2; exit 1; }

heading() {
  printf '\033[2J\033[H'
  gum style --bold --foreground 99 --border rounded --padding '0 2' "$1"
}

DB="$ROOT_DIR/data/book_database.sh"
MANAGE="$ROOT_DIR/workflows/manage_library.sh"

$DB init
$MANAGE add 'The Left Hand of Darkness' 'Ursula K. Le Guin' completed 5
$MANAGE add 'The Design of Everyday Things' 'Don Norman' completed 4
$MANAGE add 'Designing Data-Intensive Applications' 'Martin Kleppmann' reading ''
$MANAGE add 'Pachinko' 'Min Jin Lee' want-to-read ''
$MANAGE add 'The Silk Roads' 'Peter Frankopan' completed 4

heading 'Intersections Library — Browse'
$MANAGE list | "$ROOT_DIR/ui/library_screen.sh"
sleep "$pause"

heading 'Search across every field — “design”'
$MANAGE search design | "$ROOT_DIR/ui/library_screen.sh"
sleep "$pause"

heading 'Three recommendation agents run in parallel'
TEST_AGENT_DELAY=${DEMO_AGENT_DELAY:-2} "$ROOT_DIR/workflows/get_recommendations.sh" 'technology history psychology literature' |
  "$ROOT_DIR/ui/recommendations_screen.sh"
sleep "$pause"

gum style --bold --foreground 42 'Demo complete. The real library was not changed.'
