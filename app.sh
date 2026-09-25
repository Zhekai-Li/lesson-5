#!/bin/bash
# Small application entry point: check dependencies and choose a UI mode.

set -u
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ "${1:-}" = '--demo' ]; then
  exec "$ROOT_DIR/demo/run_demo.sh"
fi

if [ "$#" -ne 0 ]; then
  printf 'Usage: ./app.sh [--demo]\n' >&2
  exit 2
fi

if ! command -v gum >/dev/null 2>&1; then
  printf 'Error: Gum is required. Install it with: brew install gum\n' >&2
  exit 1
fi

exec "$ROOT_DIR/ui/main_menu.sh"
