#!/usr/bin/env bash
# Widescreen layout: side | editor | side  (~22% | 56% | 22%)
# Run while focused on the editor pane.

TOTAL_W=$(tmux display-message -p '#{window_width}')
PANE_ID=$(tmux display-message -p '#{pane_id}')
WINDOW_ID=$(tmux display-message -p '#{window_id}')
PANE_DIR=$(tmux display-message -p '#{pane_current_path}')

# Unzoom first if needed
[[ "$(tmux display-message -p '#{window_zoomed_flag}')" == "1" ]] && tmux resize-pane -Z

SIDE_W=$((TOTAL_W * 22 / 100))
PANE_COUNT=$(tmux list-panes -t "$WINDOW_ID" | wc -l)

case $PANE_COUNT in
    1)
        tmux split-window -h -l "$SIDE_W" -c "$PANE_DIR" -t "$PANE_ID"
        tmux split-window -h -b -l "$SIDE_W" -c "$PANE_DIR" -t "$PANE_ID"
        ;;
    2)
        tmux split-window -h -b -l "$SIDE_W" -c "$PANE_DIR" -t "$PANE_ID"
        ;;
    3)
        tmux select-layout even-horizontal
        while IFS= read -r pane; do
            [[ "$pane" != "$PANE_ID" ]] && tmux resize-pane -t "$pane" -x "$SIDE_W"
        done < <(tmux list-panes -F '#{pane_id}')
        ;;
    *)
        tmux select-layout even-horizontal
        ;;
esac

# Assign titles left-to-right: agent | editor | terminal
mapfile -t sorted_panes < <(tmux list-panes -t "$WINDOW_ID" -F '#{pane_id} #{pane_left}' | sort -k2 -n | awk '{print $1}')
pane_titles=("agent" "editor" "terminal")
for i in "${!sorted_panes[@]}"; do
    [[ $i -lt ${#pane_titles[@]} ]] && tmux select-pane -t "${sorted_panes[$i]}" -T "${pane_titles[$i]}"
done
tmux select-pane -t "$PANE_ID"
