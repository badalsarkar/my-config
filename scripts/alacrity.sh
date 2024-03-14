#!/bin/bash
#
echo Updating...
sudo dnf update

echo =====================================
echo Cloning alacritty repository
echo =====================================
./utilities/create-folder-if-not-exists.sh "$BADAL_HOME/code" && cd $BADAL_HOME/code
git clone https://github.com/alacritty/alacritty.git
cd alacritty

echo =====================================
echo Installing rustup 
echo =====================================
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup override set stable
rustup update stable

echo =====================================
echo Installing dependencies 
echo =====================================
sudo dnf install cmake freetype-devel fontconfig-devel libxcb-devel libxkbcommon-devel g++ 


echo =====================================
echo Building and installing alacritty
echo =====================================
cargo build --release

echo =====================================
echo Adding desktop entry 
echo =====================================
sudo cp target/release/alacritty /usr/local/bin
sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
sudo desktop-file-install extra/linux/Alacritty.desktop
sudo update-desktop-database

echo =====================================
echo making alacrity the default terminal
echo =====================================
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/alacritty 50

echo =====================================
echo Configure ZSH shell completion 
echo =====================================
mkdir -p ${ZDOTDIR:-~}/.zsh_functions
echo 'fpath+=${ZDOTDIR:-~}/.zsh_functions' >> ${ZDOTDIR:-~}/.zshrc


echo =====================================
echo Linking config file 
echo =====================================
cd
ln -sf $BADAL_HOME/badal/my-config/config/alacritty/alacritty.toml . 

