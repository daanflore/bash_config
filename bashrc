#!/usr/bin/env bash

#VARIABLE
PYTHON_VERSION=3.12.3

# ~/.bashrc: executed by bash(1) for non-login shells.
# If not running interactively, don't do anything
# Will prevent the error bind warning line editing not enabled
[ -z "$PS1" ] && return

# Disable bell sound
bind 'set bell-style visible'

# When multiple options list them and add shift support to go backwards
bind 'TAB:menu-complete'
bind '"\e[Z": menu-complete-backward'
# Make it case insensitve
bind 'set completion-ignore-case on'

# Show list of all possible options
bind 'set show-all-if-ambiguous on'

# Will auto complete until options diff on first tab
bind "set menu-complete-display-prefix on"

# Add color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Auto acticate python version version can be set at the top
source ~/venv/$PYTHON_VERSION/bin/activate
