#!/bin/sh
# Maintain the two most-recently-active windows so that prefix+L can toggle
# between them. Invoked from the pane-focus-in hook with the id of the window
# that just gained focus passed as $1 (e.g. "@3").
#
# State lives in two global tmux environment variables:
#   TMUX_WIN_CUR  - the window we are in now
#   TMUX_WIN_PREV - the window we were in just before
cur="$1"
[ -n "$cur" ] || exit 0

prev=$(tmux show-environment -g TMUX_WIN_CUR 2>/dev/null | cut -d= -f2-)

# Moving between panes inside the same window keeps the window id unchanged;
# ignore those so PREV always points at a *different* window.
[ "$cur" = "$prev" ] && exit 0

tmux set-environment -g TMUX_WIN_PREV "$prev"
tmux set-environment -g TMUX_WIN_CUR "$cur"
