#!/usr/bin/env bash

# We use a seperate array for the CLI arguments
# to not pass them to sourced modules
# declare -a g_main___args=("$@")
# set -- # unset all positional parameters

# ========== Auxillary Functions needed for Initalization ====================

# splits a filepath in the dirname and a filename
# returns a zero exit status, if the file_path is valid
#
# arguments:
# $1 - varname for dirpath
# $2 - varname for filename
# $3 - filepath
function split_filepath() {
    if [[ "$3" =~ ^((.*)[/\\])?([^/\\]+)$ ]] ; then
        if [[ "$1" != "l_split_filepath___dir" ]] ; then
            local -n l_split_filepath___dir="$1"
        fi
        if [[ "$2" != "l_split_filepath___filename" ]] ; then
            local -n l_split_filepath___filename="$2"
        fi
        
        l_split_filepath___dir="${BASH_REMATCH[2]}"
        l_split_filepath___filename="${BASH_REMATCH[3]}"
    else
        echo "
Internal Error: at split_filepath():
Internal Error: invalid filepath
Internal Error: '$3'"
        exit 1
    fi
}

# ========== Initalization and Load Modules ====================

declare -g wrapper_name="lua-wrapper-shell"

declare l_script_dir l_script_filename
split_filepath l_script_dir l_script_filename "$0"

wrapper_dir="$(realpath "$l_script_dir")/${wrapper_name}"
wrapper_modules_dir="${wrapper_dir}/modules"

source "${wrapper_modules_dir}/main.bash" "$@"
