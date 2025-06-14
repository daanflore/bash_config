#!/usr/bin/env bash

# set PATH so it includes personal bin if it exists
declare -a paths=("$HOME/bin", "$HOME/.local/bin")

# Go though all path that have been declared and only add them in case they have not yet been found in the path variable
for path_to_add in "${paths[@]}" ; do 
	if [ -d "$path_to_add" ] ; then
		# Check if the "$path_to_add" dir exists    		
		if [[ ":$PATH:" != *":$path_to_add:"* ]]; then
			PATH="$path_to_add:$PATH"
		fi
 	fi
done

if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
fi
