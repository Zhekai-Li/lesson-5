#!/bin/bash
# Run three recommendation strategies concurrently, then combine and refine.

set -u
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
REC_DIR="$ROOT_DIR/recommendations"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/book-recommend.XXXXXX") || exit 1
trap 'rm -rf "$work_dir"' EXIT HUP INT TERM

if [ "$#" -gt 0 ]; then
  interests=$*
else
  IFS= read -r interests || interests=''
fi

started=$(date +%s)
printf '[recommendations] Starting history, interests, and discovery agents...\n' >&2

"$REC_DIR/recommend_from_history.sh" > "$work_dir/history.tsv" &
history_pid=$!
"$REC_DIR/recommend_from_interests.sh" "$interests" > "$work_dir/interests.tsv" &
interests_pid=$!
"$REC_DIR/recommend_for_discovery.sh" > "$work_dir/discovery.tsv" &
discovery_pid=$!

failures=0
if wait "$history_pid"; then
  printf '[recommendations] History agent complete.\n' >&2
else
  printf '[recommendations] History agent failed.\n' >&2
  failures=$((failures + 1))
fi
if wait "$interests_pid"; then
  printf '[recommendations] Interests agent complete.\n' >&2
else
  printf '[recommendations] Interests agent failed.\n' >&2
  failures=$((failures + 1))
fi
if wait "$discovery_pid"; then
  printf '[recommendations] Discovery agent complete.\n' >&2
else
  printf '[recommendations] Discovery agent failed.\n' >&2
  failures=$((failures + 1))
fi

if [ "$failures" -eq 3 ]; then
  printf '[recommendations] No agent completed successfully.\n' >&2
  exit 1
fi

elapsed=$(( $(date +%s) - started ))
printf '[recommendations] Refining combined candidates after %ss.\n' "$elapsed" >&2
cat "$work_dir/history.tsv" "$work_dir/interests.tsv" "$work_dir/discovery.tsv" |
  "$REC_DIR/refine_recommendations.sh"
