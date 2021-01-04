#!/usr/bin/env sh
if [ -n "$DEBUG" ]; then
    set -x
fi

set -e

PIPES_DIR="$HOME/.local/share/thcon/"
PIPE="$PIPES_DIR/$$"

# shellcheck disable=SC2064
trap "rm -f $PIPE; trap - EXIT; exit" EXIT INT HUP TERM

mkdir -p "$PIPES_DIR"
mkfifo "$PIPE"
tail -f "$PIPE"
