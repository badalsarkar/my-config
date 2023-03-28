#!/bin/bash

pkg=$1

if rpm -q $pkg
then
    echo "$pkg installed"
else
    echo "$pkg NOT installed"
fi
