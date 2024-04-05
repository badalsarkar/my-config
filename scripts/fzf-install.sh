#!/bin/zsh

echo Clonning fzf into ~/.fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf

echo Installing fzf
~/.fzf/install
