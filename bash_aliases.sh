# function checks if the application is installed
function __add_command_replace_alias() {
    if [ -x "$(which $2 2>&1)" ]; then
        alias $1="$2"
    fi
}

__add_command_replace_alias 'vim' 'nvim'
