#!/bin/bash
#
echo Updating...
sudo dnf update
sudo dnf install cmake freetype-devel fontconfig-devel libxcb-devel xcb-util-devel xcb-util-image-devel xcb-util-wm-devel

echo =====================================
echo Cloning alacritty repository
echo =====================================
./utilities/create-folder-if-not-exists.sh "/home/bsarkar/code" && cd ~/code
git clone https://github.com/alacritty/alacritty.git

echo =====================================
echo Building and installing alacritty
echo =====================================
cargo build --release
sudo cp target/release/alacritty /usr/local/bin
sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
sudo desktop-file-install extra/linux/Alacritty.desktop
sudo update-desktop-database

echo =====================================
echo making alacrity the default terminal
echo =====================================
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/alacritty 50


echo =====================================
echo making alacrity the default terminal
echo =====================================
cd
ln -sf $HOME/badal/my-config/config/alacritty/alacritty.toml . 

