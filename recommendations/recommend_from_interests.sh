#!/bin/bash
# Match free-form interests against the offline catalog's topic tags.

set -u
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CATALOG="$SCRIPT_DIR/../books/catalog.tsv"

if [ "$#" -gt 0 ]; then
  interests=$*
else
  IFS= read -r interests || interests=''
fi

[ "${TEST_AGENT_DELAY:-0}" = "0" ] || sleep "$TEST_AGENT_DELAY"
[ -n "$interests" ] || exit 0

awk -F '\t' -v interests="$interests" '
  BEGIN {
    interests = tolower(interests)
    count = split(interests, word, /[ ,;:]+/)
  }
  {
    haystack = tolower($1 " " $3 " " $6)
    matches = 0
    matched = ""
    delete seen
    for (i = 1; i <= count; i++) {
      if (length(word[i]) > 2 && !seen[word[i]] && index(haystack, word[i]) > 0) {
        matches++
        seen[word[i]] = 1
        matched = (matched == "" ? word[i] : matched ", " word[i])
      }
    }
    if (matches > 0) {
      score = 78 + (matches * 4)
      if (score > 96) score = 96
      printf "%d\t%s\t%s\t%s\t%s\tMatches your interests in %s\t%s\n", score, $1, $2, $3, $4, matched, $5
    }
  }
' "$CATALOG"
