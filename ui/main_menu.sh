#!/bin/bash
# Interactive Gum UI. Business operations are delegated to workflows.

set -u
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MANAGE="$ROOT_DIR/workflows/manage_library.sh"
RECOMMEND="$ROOT_DIR/workflows/get_recommendations.sh"
LIBRARY_SCREEN="$ROOT_DIR/ui/library_screen.sh"
RECOMMENDATIONS_SCREEN="$ROOT_DIR/ui/recommendations_screen.sh"

notice() { gum style --foreground 42 "$1"; }
warning() { gum style --foreground 214 "$1"; }

prompt_identity() {
  identity_title=$(gum input --header 'Book title' --placeholder 'Enter the exact title') || return 1
  [ -n "$identity_title" ] || { warning 'Cancelled: a title is required.'; return 1; }
  identity_author=$(gum input --header 'Author' --placeholder 'Enter the author') || return 1
  [ -n "$identity_author" ] || { warning 'Cancelled: an author is required.'; return 1; }
}

while :; do
  gum style --bold --foreground 99 'Intersections Library'
  choice=$(gum choose --header 'Choose an action' \
    'Browse Library' 'Add Book' 'Search Library' 'Update Status' \
    'Update Rating' 'Recommendations' 'Quit') || { warning 'Menu cancelled.'; exit 0; }

  case $choice in
    'Browse Library') "$MANAGE" list | "$LIBRARY_SCREEN" ;;
    'Add Book')
      prompt_identity || continue
      status=$(gum choose --header 'Reading status' want-to-read reading completed paused) || { warning 'Add cancelled.'; continue; }
      rating=$(gum input --header 'Rating (optional)' --placeholder '1–5, or leave blank') || { warning 'Add cancelled.'; continue; }
      if "$MANAGE" add "$identity_title" "$identity_author" "$status" "$rating"; then notice 'Book added.'; else warning 'Could not add that book.'; fi
      ;;
    'Search Library')
      term=$(gum input --header 'Search' --placeholder 'Title, author, genre, year, or status') || { warning 'Search cancelled.'; continue; }
      [ -n "$term" ] || { warning 'Search cancelled: enter a term.'; continue; }
      "$MANAGE" search "$term" | "$LIBRARY_SCREEN"
      ;;
    'Update Status')
      prompt_identity || continue
      status=$(gum choose --header 'New status' want-to-read reading completed paused) || { warning 'Update cancelled.'; continue; }
      if "$MANAGE" update-status "$identity_title" "$identity_author" "$status"; then notice 'Status updated.'; else warning 'Could not update that book.'; fi
      ;;
    'Update Rating')
      prompt_identity || continue
      rating=$(gum choose --header 'New rating' 1 2 3 4 5) || { warning 'Update cancelled.'; continue; }
      if "$MANAGE" update-rating "$identity_title" "$identity_author" "$rating"; then notice 'Rating updated.'; else warning 'Could not update that book.'; fi
      ;;
    'Recommendations')
      interests=$(gum input --header 'What are you curious about?' --placeholder 'technology, history, psychology, literature...') || { warning 'Recommendations cancelled.'; continue; }
      "$RECOMMEND" "$interests" | "$RECOMMENDATIONS_SCREEN"
      ;;
    Quit) notice 'Happy reading!'; exit 0 ;;
  esac
done
