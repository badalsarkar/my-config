#!/bin/bash

# Update package repositories
sudo dnf update

# Install Zsh
sudo dnf install zsh

# Change the default shell to Zsh
chsh -s /bin/zsh $USER

# Print a message to restart the shell
echo "Zsh has been installed. Please restart your shell."

./utilities/create-zsh-symlink.sh

