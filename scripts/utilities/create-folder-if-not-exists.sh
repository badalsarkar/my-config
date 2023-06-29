
#!/bin/bash
#
folder_path="$1"

    # Check if the folder exists
    if [ -d "$folder_path" ]; then
	    echo "Folder already exists."
    else
	    # Create the folder
	    mkdir "$folder_path"
	    echo "Folder created."
    fi

# Usage: create_folder_if_not_exists "/path/to/folder"

