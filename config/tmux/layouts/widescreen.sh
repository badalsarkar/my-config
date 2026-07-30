#!/usr/bin/env zsh
# Widescreen layout: side | editor | side  (~22% | 56% | 22%)

emulate -L zsh

TOTAL_W=$(tmux display-message -p '#{window_width}')
PANE_ID=$(tmux display-message -p '#{pane_id}')
WINDOW_ID=$(tmux display-message -p '#{window_id}')
PANE_DIR=$(tmux display-message -p '#{pane_current_path}')

# Unzoom first if needed
[[ "$(tmux display-message -p '#{window_zoomed_flag}')" == "1" ]] && tmux resize-pane -Z

SIDE_W=$(( TOTAL_W * 22 / 100 ))

# Fills $panes with the pane ids left-to-right: ${(f)} gives one element per
# output line, ${...%% *} drops the pane_left field that was only there to sort
# on. Pane count comes off the array — ${#${(f)...}} on single-line output
# measures characters, not lines.
sorted_by_pos() {
    panes=(${${(f)"$(tmux list-panes -t $WINDOW_ID -F '#{pane_id} #{pane_left}' | sort -k2 -n)"}%% *})
}

sorted_by_pos
case $#panes in
    1)
        tmux split-window -h -l $SIDE_W -c "$PANE_DIR" -t $PANE_ID
        tmux split-window -h -b -l $SIDE_W -c "$PANE_DIR" -t $PANE_ID
        ;;
    2)
        tmux split-window -h -b -l $SIDE_W -c "$PANE_DIR" -t $PANE_ID
        ;;
    3)
        # Reset to equal widths first, then resize side panes by position —
        # never by current focus, which may be a side pane.
        tmux select-layout even-horizontal
        sorted_by_pos
        tmux resize-pane -t $panes[1] -x $SIDE_W
        tmux resize-pane -t $panes[3] -x $SIDE_W
        ;;
    *)
        tmux select-layout even-horizontal
        ;;
esac

# Assign titles left-to-right: agent | editor | terminal
sorted_by_pos
pane_titles=(agent editor terminal)
for i in {1..$#pane_titles}; do
    (( i <= $#panes )) || break
    tmux select-pane -t $panes[i] -T $pane_titles[i]
done

# Always land on the editor (middle pane)
(( $#panes >= 3 )) && tmux select-pane -t $panes[2] || tmux select-pane -t $PANE_ID
