#!/bin/zsh

# Check if Java is already installed
if command -v java &>/dev/null; then
  echo "Java is already installed."
else
  # Check if SDKMAN is installed
  if command -v sdk &>/dev/null; then
    echo "SDKMAN is already installed."
  else
    # Install SDKMAN
    curl -s "https://get.sdkman.io" | bash

    # Reload the shell
    source "${HOME}/.sdkman/bin/sdkman-init.sh"
  fi

  # Install Java
  sdk install java

  echo "Java has been installed."
fi
