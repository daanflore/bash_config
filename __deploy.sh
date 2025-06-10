#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

rm ~/.bash_profile
ln -s $SCRIPT_DIR/bash_profile ~/.bash_profile

rm ~/.bashrc
ln -s $SCRIPT_DIR/bashrc ~/.bashrc

rm ~/.dircolors
ln -s $SCRIPT_DIR/dircolors ~/.dircolors
