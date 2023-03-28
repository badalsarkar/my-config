#!/bin/bash 

echo Removing existing GO installation
 rm -rf /usr/local/go 
 echo Installing from ~/Downloads directory
 sudo tar -C /usr/local -xzf ~/Downloads/go1.20.2.linux-amd64.tar.gz
 echo Updating path to include /usr/local/go/bin
 export PATH=$PATH:/usr/local/go/bin &&  source $HOME/.profile
 go version
