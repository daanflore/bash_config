#!/usr/bin/env bash

# ======================
# CONFIGURATION SECTION
# ======================
# Python version to activate
PYTHON_VERSION=3.12.3

# Git fetch interval (in seconds)
GIT_FETCH_INTERVAL=30

# Enable debug logging: 1 = enabled, 0 = disabled
DEBUG_PROMPT=0

# ======================
# COLOR DEFINITIONS
# ======================
# Reset
Color_Off='\[\e[0m\]'

# Normal Color
Red='\[\e[0;31m\]'
Green='\[\e[0;32m\]'
Yellow='\[\e[0;33m\]'
Cyan='\[\e[0;36m\]'

# Bold
BBlack='\[\e[1;30m\]'
BRed='\[\e[1;31m\]'
BGreen='\[\e[1;32m\]'
BYellow='\[\e[1;33m\]'
BBlue='\[\e[1;34m\]'
BPurple='\[\e[1;35m\]'
BCyan='\[\e[1;36m\]'
BWhite='\[\e[1;37m\]'

# ======================
# DEBUG HELPER
# ======================
function _debug_log() {
    if [ "$DEBUG_PROMPT" -eq 1 ]; then
		echo -e "\033[3;90m[DEBUG] $*\033[0m" >&2    
	fi
}

# ======================
# DETECT GIT AVAILABILITY
# ======================
[[ -x "$(which git 2>&1)" ]] && GIT_AVAILABLE=1 || GIT_AVAILABLE=0

# ======================
# INTERACTIVE SHELL CHECK
# ======================
if [[ "$-" != *i* ]]; then
    return
fi

# ======================
# GIT STATUS PROMPT
# ======================
function _git_fetch_if_past_timeout(){
    # TODO: Add option to disable git fetch
    # TODO: Add logic to handle repo switching
    _debug_log "Executing _git_fetch_if_past_timeout"

    local current_time
    local time_since_last_fetch
    current_time=$(date +%s)
    _debug_log "Current time: $(date -d "@$current_time" '+%Y-%m-%d %H:%M:%S')"
    _debug_log "Last fetch check: $(date -d "@$LAST_FETCH_CHECK" '+%Y-%m-%d %H:%M:%S')"
    
    time_since_last_fetch=$((current_time - LAST_FETCH_CHECK))
    _debug_log "Time since last fetch: ${time_since_last_fetch}s (interval: ${GIT_FETCH_INTERVAL}s)"

    if [ -z "$LAST_FETCH_CHECK" ] || [ "$time_since_last_fetch" -ge "$GIT_FETCH_INTERVAL" ]; then
        _debug_log "Time interval exceeded, performing git fetch check"
         _debug_log "Fetching in background..."
        (git fetch --quiet &)
        LAST_FETCH_CHECK=$current_time
    else
        _debug_log "No need to fetch, time interval not exceeded"
    fi
}

function _append_git_status() {
    _debug_log "Executing _append_git_status"
    local -n cmd=$1  # Create a nameref to the buildCommand variable

    if [ "$GIT_AVAILABLE" -ne 1 ]; then
        _debug_log "Git not available"
        return
    fi

    local branch
    branch="$(git branch 2>/dev/null | grep '^.*' | colrm 1 2)"
    
    if [ -z "${branch}" ]; then
        _debug_log "Not in a git repository or no branch found"
        return
    fi

    _debug_log "Git branch: $branch"
    _git_fetch_if_past_timeout

    local git_status status_output="" remote_status=""
    local ahead behind

    ahead=$(git rev-list --count "@{upstream}..HEAD" 2>/dev/null)
    behind=$(git rev-list --count "HEAD..@{upstream}" 2>/dev/null)

    _debug_log "Ahead: $ahead, Behind: $behind"

    if [ -n "$behind" ] && [ "$behind" -gt 0 ]; then
        remote_status+="${Red}↓${behind}${Color_Off}"
    fi
    if [ -n "$ahead" ] && [ "$ahead" -gt 0 ]; then
        remote_status+="${Green}↑${ahead}${Color_Off}"
    fi

    git_status="$(git status --porcelain 2>/dev/null)"
    local staged_output=""

    if echo "$git_status" | grep "^M" -q; then
        staged_output+="${Green}M ${Color_Off}"
    fi

    if echo "$git_status" | grep "^D" -q; then
        staged_output+="${Green}D ${Color_Off}"
    fi

    if echo "$git_status" | grep "^A" -q; then
        staged_output+="${Green}A ${Color_Off}"
    fi

    if echo "$git_status" | grep "^.M" -q; then
        status_output+="${Yellow}M ${Color_Off}"
    fi

    if echo "$git_status" | grep "^.D" -q; then
        status_output+="${Red}D ${Color_Off}"
    fi

    if echo "$git_status" | grep "^??" -q; then
        status_output+="${BBlue}U ${Color_Off}"
    fi

    _debug_log "Staged changes: $staged_output"
    _debug_log "Unstaged changes: $status_output"

    if [ -n "$staged_output" ] && [ -n "$status_output" ]; then
        status_output="${staged_output}| ${status_output}"
    elif [ -n "$staged_output" ]; then
        status_output="${staged_output}"
    fi

    local branch_separator=""
    if [ -n "$status_output" ]; then
        branch_separator=":"
    fi

    cmd+=" ${Cyan}(${branch}${remote_status}${branch_separator}${status_output}${Cyan})${Color_Off}"
}

# ======================
# PROMPT BUILDER
# ======================
function _buildPS1(){
    previousCommandResult="$?"
    _debug_log "Building PS1 prompt"

    local buildCommand=''
    buildCommand+="${BPurple}[\$(date +%H:%M:%S)]${Color_Off}"

    if [[ -v VIRTUAL_ENV ]]; then
        buildCommand+=" ${Yellow}(${VIRTUAL_ENV##*/})${Color_Off}"
    fi

    if [ "${USER}" == root ]; then
        buildCommand+=" ${BRed}${USER}${Color_Off}"
    elif [ "${USER}" != "$(logname)" ]; then
        buildCommand+=" ${BBlue}${USER}${Color_Off}"
    else
        buildCommand+=" ${BGreen}${USER}${Color_Off}"
    fi

    buildCommand+=":\[\033[38;5;111m\]\w${Color_Off}" # working directory
    _append_git_status buildCommand

    if [ "$previousCommandResult" -ne 0 ]; then
        buildCommand+="${BRed}(${previousCommandResult})${Color_Off}"
    fi

    if [ -n "$CMD_DURATION" ]; then
        buildCommand+="|${CMD_DURATION}"
    fi

    if [ "${USER}" == root ]; then
        buildCommand+=" ${BRed}\\$ ${Color_Off} "
    elif [ "${USER}" != "$(logname)" ]; then
        buildCommand+=" ${BBlue}\\$ ${Color_Off} "
    else
        buildCommand+=" ${BGreen}\\$ ${Color_Off} "
    fi

    PS1="${buildCommand}"
}

# ======================
# HISTORY SETTINGS
# ======================
HISTCONTROL=ignoreboth
HISTIGNORE='ls:cd:pwd:exit:clear:history'

# ======================
# AUTOCOMPLETE + STYLING
# ======================
bind 'set bell-style visible'
bind 'TAB:menu-complete'
bind '"\e[Z": menu-complete-backward'
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind "set menu-complete-display-prefix on"

if [ -x /usr/bin/dircolors ]; then
    ( test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" ) || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# ======================
# PYTHON ENVIRONMENT
# ======================
# shellcheck disable=SC1090
source "$HOME/venv/$PYTHON_VERSION/bin/activate"

# ======================
# CUSTOM ALIASES
# ======================
if [ -f "$HOME/.bash_aliases" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.bash_aliases"
fi

# ======================
# PROMPT COMMAND
# ======================
# This command is executed before each prompt
PROMPT_COMMAND=_buildPS1  

