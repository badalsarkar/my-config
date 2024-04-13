#!/bin/zsh
#
#
noteType=$1
export NOTE_BASE_DIR="$HOME/Documents/notes"

case $noteType in
    m)
        dir="$NOTE_BASE_DIR/meeting"
        ;;

    s)
        dir="$NOTE_BASE_DIR/scratch"
        ;;
    i)
        dir="$NOTE_BASE_DIR/idea"
        ;;
    l)
        dir="$NOTE_BASE_DIR/learning"
        ;;
    *)
        dir="$NOTE_BASE_DIR/notes"
        ;;
esac

echo $dir


noteFileName="$dir/note-$(date +%Y-%m-%d).md"

if [[ ! -f $noteFileName ]]; then
    echo "# Notes for $(date +%Y-%m-%d)" > $noteFileName
fi

nvim -c "norm Go"\
    -c "norm Go## $(date +%H:%M)" \
    -c "norm G2o" \
    -c "norm zz" \
    -c "startinsert" $noteFileName
