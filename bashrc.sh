#!/usr/bin/env bash

# VARIABLE
PYTHON_VERSION=3.12.3
[[ -x "$(which git 2>&1)" ]] && GIT_AVAILABLE=1 || GIT_AVAILABLE=0 # TEST if git is installed

# Git auto-fetch interval in seconds (default: 5 minutes)
GIT_FETCH_INTERVAL=300

# Timer variables for command execution
CMD_START_TIME=0
CMD_DURATION=""

# Function to start the command timer
function timer_start {
    CMD_START_TIME=$(date +%s%N)
    CMD_DURATION=""
}

# Function to stop the timer and format the duration
function timer_stop {
    if [ $CMD_START_TIME -gt 0 ]; then
        local end_time=$(date +%s%N)
        local duration_ns=$((end_time - CMD_START_TIME))
        local duration_ms=$((duration_ns/1000000))
        
        # Format duration based on length
        if [ $duration_ms -lt 1000 ]; then
            CMD_DURATION="${duration_ms}ms"
        else
            local duration_s=$((duration_ms/1000))
            if [ $duration_s -lt 60 ]; then
                CMD_DURATION="${duration_s}s"
            else
                local duration_m=$((duration_s/60))
                duration_s=$((duration_s%60))
                if [ $duration_m -lt 60 ]; then
                    CMD_DURATION="${duration_m}m${duration_s}s"
                else
                    local duration_h=$((duration_m/60))
                    duration_m=$((duration_m%60))
                    CMD_DURATION="${duration_h}h${duration_m}m"
                fi
            fi
        fi
    fi
    CMD_START_TIME=0
}

# Add the timer hooks
trap 'timer_start' DEBUG
PROMPT_COMMAND='timer_stop; _maybe_fetch_prompt'

# Color variable
# Reset
Color_Off='\[\e[0m\]'       # Stop color

# Normal Color
Red='\[\e[0;31m\]'         # Red
Green='\[\e[0;32m\]'       # Green
Yellow='\[\e[0;33m\]'       # Yellow
Cyan='\[\e[0;36m\]'        # Cyan

# Bold
BBlack='\[\e[1;30m\]'       # Black
BRed='\[\e[1;31m\]'         # Red
BGreen='\[\e[1;32m\]'       # Green
BYellow='\[\e[1;33m\]'      # Yellow
BBlue='\[\e[1;34m\]'        # Blue
BPurple='\[\e[1;35m\]'      # Purple
BCyan='\[\e[1;36m\]'        # Cyan
BWhite='\[\e[1;37m\]'       # White


# ~/.bashrc: executed by bash(1) for non-login shells.
# If not running interactively, don't do anything
# Will prevent the error bind warning line editing not enabled
[ -z "$PS1" ] && return

function _get_git_status() {
    if [ "$GIT_AVAILABLE" -ne 1 ]; then
        return
    fi

    local branch
    branch="$(git branch 2>/dev/null | grep '^*' | colrm 1 2)"
    
    if [ -z "${branch}" ]; then
        return
    fi

    local git_status
    local status_output=""
    local remote_status=""
    
    # Get ahead/behind status
    local ahead behind
    ahead=$(git rev-list --count "@{upstream}..HEAD" 2>/dev/null)
    behind=$(git rev-list --count "HEAD..@{upstream}" 2>/dev/null)
    
    if [ -n "$ahead" ] && [ "$ahead" -gt 0 ]; then
        remote_status+="${Green}↑${ahead}${Color_Off}"
    fi
    if [ -n "$behind" ] && [ "$behind" -gt 0 ]; then
        remote_status+="${Red}↓${behind}${Color_Off}"
    fi
    
    git_status="$(git status --porcelain 2>/dev/null)"
    local staged_output=""
    
    # Check for staged modifications
    if echo "$git_status" | grep "^M" > /dev/null; then
        staged_output+="${Green}M ${Color_Off}"
    fi
    
    # Check for staged deletions
    if echo "$git_status" | grep "^D" > /dev/null; then
        staged_output+="${Green}D ${Color_Off}"
    fi
    
    # Check for staged additions
    if echo "$git_status" | grep "^A" > /dev/null; then
        staged_output+="${Green}A ${Color_Off}"
    fi
    
    # Check for unstaged modifications
    if echo "$git_status" | grep "^.M" > /dev/null; then
        status_output+="${Yellow}M ${Color_Off}"
    fi
    
    # Check for unstaged deletions
    if echo "$git_status" | grep "^.D" > /dev/null; then
        status_output+="${Red}D ${Color_Off}"
    fi
    
    # Check for untracked files
    if echo "$git_status" | grep "^??" > /dev/null; then
        status_output+="${BBlue}U ${Color_Off}"
    fi
    
    # Combine staged and unstaged changes with a separator if both exist
    if [ -n "$staged_output" ] && [ -n "$status_output" ]; then
        status_output="${staged_output}| ${status_output}"
    elif [ -n "$staged_output" ]; then
        status_output="${staged_output}"
    fi
    
    # Add colon if there are any local changes
    local branch_separator=""
    if [ -n "$status_output" ]; then
        branch_separator=":"
    fi
    
    # Position remote status right after branch name, before the colon and local changes
    local all_status="${status_output}"
    
    echo -n " ${Cyan}(${branch}${remote_status}${branch_separator}${all_status}${Cyan})${Color_Off}"
}

function _buildPS1(){
    local previousCommandResult="$?"

    local buildCommand=''
    
    # Add current time
    buildCommand+="${BPurple}[\$(date +%H:%M:%S)]${Color_Off}"
    
    # If venv is active display it
    if [[ -v VIRTUAL_ENV ]]; then
        buildCommand+=" ${Yellow}(${VIRTUAL_ENV##*/})${Color_Off}"
    fi

    buildCommand+=":\[\033[38;5;111m\]\w${Color_Off}" # working directory

    # Add git status
    buildCommand+="$(_get_git_status)"

    # Add username with status code and $ with appropriate colors
    if [ "${USER}" == root ]; then
        buildCommand+=" ${BRed}${USER}${Color_Off}"
    elif [ "${USER}" != "$(logname)" ]; then
        buildCommand+=" ${BBlue}${USER}${Color_Off}"
    else
        buildCommand+=" ${BGreen}${USER}${Color_Off}"
    fi

    # Add status code and execution time with color based on success/failure
    if [ $previousCommandResult -eq 0 ]; then
        buildCommand+="${BBlack}(${previousCommandResult}"
    else
        buildCommand+="${BRed}(${previousCommandResult}"
    fi
    
    # Add execution time if available
    if [ -n "$CMD_DURATION" ]; then
        if [ $previousCommandResult -eq 0 ]; then
            buildCommand+="|${CMD_DURATION}"
        else
            buildCommand+="|${CMD_DURATION}"
        fi
    fi
    
    # Close the parentheses
    if [ $previousCommandResult -eq 0 ]; then
        buildCommand+=")${Color_Off}"
    else
        buildCommand+=")${Color_Off}"
    fi

    # Add the $ symbol
    if [ "${USER}" == root ]; then
        buildCommand+=" ${BRed}\\$ ${Color_Off} "
    elif [ "${USER}" != "$(logname)" ]; then
        buildCommand+=" ${BBlue}\\$ ${Color_Off} "
    else
        buildCommand+=" ${BGreen}\\$ ${Color_Off} "
    fi

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
source "$HOME/venv/$PYTHON_VERSION/bin/activate"

if [ -f "$HOME/.bash_aliases" ]; then
    . "$HOME/.bash_aliases"
    
fi

# Function to perform git fetch in the background for the current repository
function _periodic_git_fetch() {
    if [ "$GIT_AVAILABLE" -ne 1 ]; then
        return
    fi

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        return
    fi

    # Get the last fetch time from our marker file
    local git_dir=$(git rev-parse --git-dir)
    local last_fetch_file="${git_dir}/FETCH_HEAD"
    
    # If the file doesn't exist or it's older than our interval, do a fetch
    if [ ! -f "$last_fetch_file" ] || [ $(($(date +%s) - $(stat -c %Y "$last_fetch_file"))) -gt "$GIT_FETCH_INTERVAL" ]; then
        (git fetch --quiet &) # Run fetch in background
    fi
}

# Add the periodic fetch to PROMPT_COMMAND, but only run it occasionally
function _maybe_fetch_prompt() {
    # Only run fetch check roughly every 60 seconds
    if [ -z "$LAST_FETCH_CHECK" ] || [ $(($(date +%s) - LAST_FETCH_CHECK)) -gt 60 ]; then
        LAST_FETCH_CHECK=$(date +%s)
        _periodic_git_fetch
    fi
    
    # Always run the normal prompt command
    _buildPS1
}
