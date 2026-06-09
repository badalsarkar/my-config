#!/bin/sh
# Maintain the two most-recently-active pane locations so that prefix+L can
# toggle between them. Invoked from the pane-focus-in hook with the id of the
# pane that just gained focus passed as $1 (e.g. "%7").
#
# State lives in two global tmux environment variables:
#   TMUX_LOC_CUR  - the pane we are in now
#   TMUX_LOC_PREV - the pane we were in just before
cur="$1"
[ -n "$cur" ] || exit 0

prev=$(tmux show-environment -g TMUX_LOC_CUR 2>/dev/null | cut -d= -f2-)

# Focus can fire without the active pane actually changing (e.g. the terminal
# regaining focus); ignore those so PREV keeps pointing at a *different* pane.
[ "$cur" = "$prev" ] && exit 0

tmux set-environment -g TMUX_LOC_PREV "$prev"
tmux set-environment -g TMUX_LOC_CUR "$cur"
