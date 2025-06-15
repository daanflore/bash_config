#!/usr/bin/env bash

# ======================
# CONFIGURATION SECTION
# ======================

# Python version to activate
PYTHON_VERSION=3.12.3

# Git fetch interval (in seconds)
GIT_FETCH_INTERVAL=300

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
        echo -e "[DEBUG] $*" >&2
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

function _get_git_status() {
    _debug_log "Running _get_git_status"

    if [ "$GIT_AVAILABLE" -ne 1 ]; then
        _debug_log "Git not available"
        return
    fi

    local branch
    branch="$(git branch 2>/dev/null | grep '^*' | colrm 1 2)"
    _debug_log "Git branch: $branch"

    if [ -z "${branch}" ]; then
        return
    fi

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

    if echo "$git_status" | grep "^M" > /dev/null; then
        staged_output+="${Green}M ${Color_Off}"
    fi
    if echo "$git_status" | grep "^D" > /dev/null; then
        staged_output+="${Green}D ${Color_Off}"
    fi
    if echo "$git_status" | grep "^A" > /dev/null; then
        staged_output+="${Green}A ${Color_Off}"
    fi
    if echo "$git_status" | grep "^.M" > /dev/null; then
        status_output+="${Yellow}M ${Color_Off}"
    fi
    if echo "$git_status" | grep "^.D" > /dev/null; then
        status_output+="${Red}D ${Color_Off}"
    fi
    if echo "$git_status" | grep "^??" > /dev/null; then
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

    echo -n " ${Cyan}(${branch}${remote_status}${branch_separator}${status_output}${Cyan})${Color_Off}"
}

# ======================
# PROMPT BUILDER
# ======================

function _buildPS1(){
    _debug_log "Building PS1 prompt"

    local buildCommand=''
    buildCommand+="${BPurple}[\$(date +%H:%M:%S)]${Color_Off}"

    if [[ -v VIRTUAL_ENV ]]; then
        buildCommand+=" ${Yellow}(${VIRTUAL_ENV##*/})${Color_Off}"
    fi

    buildCommand+=":\[\033[38;5;111m\]\w${Color_Off}" # working directory
    buildCommand+="$(_get_git_status)"

    if [ "${USER}" == root ]; then
        buildCommand+=" ${BRed}${USER}${Color_Off}"
    elif [ "${USER}" != "$(logname)" ]; then
        buildCommand+=" ${BBlue}${USER}${Color_Off}"
    else
        buildCommand+=" ${BGreen}${USER}${Color_Off}"
    fi

    if [ $previousCommandResult -eq 0 ]; then
        buildCommand+="${BBlack}(${previousCommandResult}"
    else
        buildCommand+="${BRed}(${previousCommandResult}"
    fi

    if [ -n "$CMD_DURATION" ]; then
        buildCommand+="|${CMD_DURATION}"
    fi

    buildCommand+=")${Color_Off}"

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
# AUTOCOMPLETE + STYLING
# ======================

bind 'set bell-style visible'
bind 'TAB:menu-complete'
bind '"\e[Z": menu-complete-backward'
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind "set menu-complete-display-prefix on"

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
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

source "$HOME/venv/$PYTHON_VERSION/bin/activate"

# ======================
# CUSTOM ALIASES
# ======================

if [ -f "$HOME/.bash_aliases" ]; then
    . "$HOME/.bash_aliases"
fi

# ======================
# PERIODIC GIT FETCH
# ======================

function _periodic_git_fetch() {
    _debug_log "Checking if git fetch is needed"

    if [ "$GIT_AVAILABLE" -ne 1 ]; then
        return
    fi

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        _debug_log "Not a Git repository, skipping fetch"
        return
    fi

    local git_dir=$(git rev-parse --git-dir)
    local last_fetch_file="${git_dir}/FETCH_HEAD"

    if [ ! -f "$last_fetch_file" ] || [ $(($(date +%s) - $(stat -c %Y "$last_fetch_file"))) -gt "$GIT_FETCH_INTERVAL" ]; then
        _debug_log "Fetching in background..."
        (git fetch --quiet &)
    fi
}

function _maybe_fetch_prompt() {
    previousCommandResult="$?"

    _debug_log "Executing _maybe_fetch_prompt"
    _debug_log "Previous command result: $previousCommandResult"
	_debug_log "Current time: $(date '+%Y-%m-%d %H:%M:%S')"

	if [ -n "$LAST_FETCH_CHECK" ]; then
		human_time="$(date -d "@$LAST_FETCH_CHECK" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "$LAST_FETCH_CHECK" '+%Y-%m-%d %H:%M:%S')"
		_debug_log "Last fetch check: $human_time"
	else
		_debug_log "Last fetch check: not set"
	fi

    if [ -z "$LAST_FETCH_CHECK" ] || [ $(($(date +%s) - LAST_FETCH_CHECK)) -gt 60 ]; then
        LAST_FETCH_CHECK=$(date +%s)
        _periodic_git_fetch
    fi

    _buildPS1
}

PROMPT_COMMAND=_maybe_fetch_prompt
