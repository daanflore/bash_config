#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

rm ~/.bash_profile
ln -s "$SCRIPT_DIR/bash_profile.sh" ~/.bash_profile

rm ~/.bashrc
ln -s "$SCRIPT_DIR/bashrc.sh" ~/.bashrc

rm ~/.dircolors
ln -s "$SCRIPT_DIR/dircolors.sh" ~/.dircolors

if [ -f ~/.bash_aliases ] ; then
	rm ~/.bash_aliases
fi

ln -s "$SCRIPT_DIR/bash_aliases.sh" ~/.bash_aliases
