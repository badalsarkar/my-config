#!/bin/bash

# Source alias files
aliases_folder="$1"
zshrc_path="$HOME/.zshrc"

# Find all alias files in the folder and append them to the .zshrc file
if [ -d "$aliases_folder" ]; then
    for alias_file in "$aliases_folder"/*; do
        echo "source $alias_file" >> "$zshrc_path"
    done

    echo "Alias files sourced in .zshrc."
else
    echo "Aliases folder not found. Skipping alias sourcing."
fi

