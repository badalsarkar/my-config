#!/usr/bin/env zsh
# Laptop layout: zoom the middle (editor) pane to fill the window.
# Other panes are preserved; use prefix+t for a popup terminal.

emulate -L zsh

WINDOW_ID=$(tmux display-message -p '#{window_id}')

# Unzoom first so pane switching works
[[ "$(tmux display-message -p '#{window_zoomed_flag}')" == "1" ]] && tmux resize-pane -Z

# Pane ids left-to-right: ${(f)} gives one element per output line, ${...%% *}
# drops the pane_left field that was only there to sort on. Count panes off the
# array — ${#${(f)...}} on single-line output measures characters, not lines.
sorted_panes=(${${(f)"$(tmux list-panes -t $WINDOW_ID -F '#{pane_id} #{pane_left}' | sort -k2 -n)"}%% *})

if (( $#sorted_panes == 3 )); then
    # Assign titles left-to-right: agent | editor | terminal
    pane_titles=(agent editor terminal)
    for i in {1..$#pane_titles}; do
        tmux select-pane -t $sorted_panes[i] -T $pane_titles[i]
    done
    tmux select-pane -t $sorted_panes[2]   # zsh arrays are 1-indexed
fi

tmux resize-pane -Z
