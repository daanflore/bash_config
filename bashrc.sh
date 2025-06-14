#!/usr/bin/env bash

# VARIABLE
PYTHON_VERSION=3.12.3
[[ -x "$(which git 2>&1)" ]] && GIT_AVAILABLE=1 || GIT_AVAILABLE=0 # TEST if git is installed

# Color variable
# Reset
Color_Off='\e[0m'       # Stop color

# Normal Color
Yellow='\e[0;33m'       # Yellow
Cyan='\e[0;36m'        # Cyan

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White


# ~/.bashrc: executed by bash(1) for non-login shells.
# If not running interactively, don't do anything
# Will prevent the error bind warning line editing not enabled
[ -z "$PS1" ] && return


function _buildPS1(){
	local previousCommandResult="$?"

	local buildCommand=''
	# If venv is active display it
	if [[ -v VIRTUAL_ENV ]]; then
		buildCommand+=" ${Yellow}(${VIRTUAL_ENV##*/})${Color_Off}"
	fi

	buildCommand+=":\[\033[38;5;111m\]\w${Color_Off}" # working directory

	# git branch
	if [ $GIT_AVAILABLE -eq 1 ] ; then
		# local branch="$(git name-rev --name-only HEAD 2>/dev/null)"
		local branch="$(git branch 2>/dev/null | grep '^*' | colrm 1 2)"

		if [ -n "${branch}" ]; then
			local git_status="$(git status --porcelain -b 2>/dev/null)"
			local letters="$( echo "${git_status}" | grep --regexp=' \w ' | sed -e 's/^\s\?\(\w\)\s.*$/\1/' )"
			local untracked="$( echo "${git_status}" | grep -F '?? ' | sed -e 's/^\?\(\?\)\s.*$/\1/' )"
			local status_line="$( echo -e "${letters}\n${untracked}" | sort | uniq | tr -d '[:space:]' )"
			buildCommand+=" \[${Cyan}\](${branch}"
			
			if [ -n "${status_line}" ]; then
				buidCommand+=" ${status_line}"
			fi

			buildCommand+=")\[${Color_Off}\]"
		fi
	fi

	# Based on user type display $ sympol in differen color
	if [ ${USER} == root ]; then
        	buildCommand+=" \[${BRed}\]\\$\[${Color_Off}\] "
	elif [ ${USER} != $(logname) ]; then
		echo "${USER} != $(logname)}"
		buildCommand+=" \[${BBlue}\]\\$\[${Color_Off}\] "
	else
	    buildCommand+=" \[${BGreen}\]\\$\[${Color_Off}\] "
 	fi

	echo "${buildCommand}"
	PS1="${buildCommand}"
}



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

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

_buildPS1
