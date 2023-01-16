#!/usr/bin/env -S bash -i

# splits a filepath in the dirname and a filename
# returns a zero exit status, if the file_path is valid
#
# arguments:
# $1 - varname for dirpath
# $2 - varname for filename
# $3 - filepath
function split_filepath() {
    if [[ "$3" =~ ^((.*)[/\\])?([^/\\]+)$ ]] ; then
        local -n l_split_filepath___dir="$1" l_split_filepath___filename="$2"
        l_split_filepath___dir="${BASH_REMATCH[2]}"
        l_split_filepath___filename="${BASH_REMATCH[3]}"
        return 0
    fi
    return 1
}

set +m -o pipefail
# disable job control,
# abort on first non-zero exiting command of a pipeline
shopt -s lastpipe
# execute last command of a pipe always in the current shell context

declare TIMEFORMAT=$'%R\n'

# $1 - filename
function timing_source() {
    printf "%s\n" "$1" 
    time source "$1"
}

timing_source "../modules/auxillary.bash"
timing_source "../modules/print.bash"
timing_source "../modules/log.bash"
timing_source "../modules/trap.bash"
timing_source "../modules/error.bash"

timing_source "../modules/env_vars.bash"
timing_source "../modules/ext_cmds.bash"

timing_source "../modules/find_file.bash"

timing_source "../modules/config_read.bash"
timing_source "../modules/config_write.bash"
timing_source "../modules/config.bash"
timing_source "../modules/CFA.bash"

timing_source "../modules/PFA.bash"

timing_source "../modules/patch_files.bash"
timing_source "../modules/sub_shell.bash"
timing_source "../modules/build_install_lua.bash"
timing_source "../modules/install_luarocks.bash"

exit 0
