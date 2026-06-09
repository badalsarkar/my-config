#!/usr/bin/env bash
# Laptop layout: zoom the middle (editor) pane to fill the window.
# Other panes are preserved; use prefix+t for a popup terminal.

WINDOW_ID=$(tmux display-message -p '#{window_id}')
PANE_COUNT=$(tmux list-panes -t "$WINDOW_ID" | wc -l)

# Unzoom first so pane switching works
[[ "$(tmux display-message -p '#{window_zoomed_flag}')" == "1" ]] && tmux resize-pane -Z

if [[ $PANE_COUNT -eq 3 ]]; then
    MIDDLE_PANE=$(tmux list-panes -F '#{pane_id} #{pane_left}' | sort -k2 -n | awk 'NR==2 {print $1}')
    # Assign titles left-to-right: agent | editor | terminal
    mapfile -t sorted_panes < <(tmux list-panes -t "$WINDOW_ID" -F '#{pane_id} #{pane_left}' | sort -k2 -n | awk '{print $1}')
    pane_titles=("agent" "editor" "terminal")
    for i in "${!sorted_panes[@]}"; do
        tmux select-pane -t "${sorted_panes[$i]}" -T "${pane_titles[$i]}"
    done
    tmux select-pane -t "$MIDDLE_PANE"
fi

tmux resize-pane -Z
