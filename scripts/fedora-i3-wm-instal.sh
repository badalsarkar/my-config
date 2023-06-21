#!/bin/zsh

echo Installing i3 Desktop
dnf groupinstall "i3 desktop"

echo Setting i3 as default GUI
systemctl set-default graphical.target

echo Enabling GDM service
systemctl enable gdm.service

echo Restarting.....
reboot
