#!/bin/zsh

#check if NOTE_BASE_DIR doesn't exists
# ask user to input directory
if [[ -z "$NOTE_BASE_DIR" ]];then
    echo "NOTE_BASE_DIR env doesn't exist"
    exit 1  # Exit script with error code
fi

noteType=$1

case $noteType in
    m)
        dir="$NOTE_BASE_DIR/meeting"
        $BADAL_HOME/badal/my-config/scripts/utilities/create-folder-if-not-exists.sh $dir 1> /dev/null
        ;;

    s)
        dir="$NOTE_BASE_DIR/scratch"
        $BADAL_HOME/badal/my-config/scripts/utilities/create-folder-if-not-exists.sh $dir 1> /dev/null
        ;;
    i)
        dir="$NOTE_BASE_DIR/idea"
        $BADAL_HOME/badal/my-config/scripts/utilities/create-folder-if-not-exists.sh $dir 1> /dev/null
        ;;
    l)
        dir="$NOTE_BASE_DIR/learning"
        $BADAL_HOME/badal/my-config/scripts/utilities/create-folder-if-not-exists.sh $dir 1> /dev/null
        ;;
    *)
        dir="$NOTE_BASE_DIR/notes"
        $BADAL_HOME/badal/my-config/scripts/utilities/create-folder-if-not-exists.sh $dir 1> /dev/null
        ;;
esac

noteFileName="$dir/note-$(date +%Y-%m-%d).md"

if [[ ! -f $noteFileName ]]; then
    echo "# Notes for $(date +%Y-%m-%d)" > $noteFileName
fi

nvim -c "norm Go"\
    -c "norm Go## $(date +%H:%M)" \
    -c "norm G2o" \
    -c "norm zz" \
    -c "startinsert" $noteFileName
