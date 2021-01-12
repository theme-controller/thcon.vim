#!/usr/bin/env sh
if [ -n "$DEBUG" ]; then
    set -x
fi

set -e

CALLING_VIM=$(basename "$VIM")
if [ -z "$CALLING_VIM" ]; then
    >&2 echo "thcon-vim.sh must be called from a vim/neovim instance (or with \$VIM set for development)"
    exit 1;
fi

PIPES_DIR="$HOME/.local/share/thcon/$CALLING_VIM"
PIPE="$PIPES_DIR/$$"

# shellcheck disable=SC2064
trap "rm -f $PIPE; trap - EXIT; exit" EXIT INT HUP TERM

if [ ! -d "$PIPES_DIR" ]; then
    mkdir -p "$PIPES_DIR"
fi
mkfifo "$PIPE"
chmod 600 "$PIPE"

tail -f "$PIPE"
