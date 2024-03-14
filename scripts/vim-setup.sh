#!/bin/zsh
#
# Download vim
sudo dnf install vim -y
# Download vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

ln -sf $BADAL_HOME/badal/my-config/config/vim/.vimrc $HOME

