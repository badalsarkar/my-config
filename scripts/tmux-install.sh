#!/bin/bash
sudo dnf install tmux
cd
ln -sf $BADAL_HOME/badal/my-config/config/tmux/.tmux.conf .

# install tpm
mkdir -p .tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
