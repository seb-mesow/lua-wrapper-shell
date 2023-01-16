
function __ec___init() {
    # echo "__ec___init(): debug_level == ${debug_level}"
    
    # by default silence commands
    
    # declare_config_assoc_array dos2unix_opts
    # declare_config_assoc_array unix2dos_opts
    # declare_config_assoc_array patch_opts
    # declare_config_assoc_array unzip_opts
    
    if (( debug_level > 0 )) ; then
        __ext_cmds___set_PS1
    else
        declare -g -A dos2unix_opts \
                      unix2dos_opts \
                      patch_opts \
                      unzip_opts
        
        dos2unix_opts[quiet]="-q"
        unix2dos_opts[quiet]="-q"
        patch_opts[quiet]="-s"
        unzip_opts[quiet]="-q"
    fi
}

function __ext_cmds___set_PS1() {
    local l_ec___PS1
    value_of_bash_var l_ec___PS1 PS1
    
    # print_str_var l_ec___PS1
    if [[ "$l_ec___PS1" =~ '\[\e['([[:digit:];]*)'m\]\w\[\e['([[:digit:];]*)'m\]' ]] ; then
        # echo "PS1 matches pattern"
        declare -g m_ec___PS1="\[\e[${BASH_REMATCH[1]}m\]\w\[\e[${BASH_REMATCH[2]}m\]"
    else
        # echo "PS1 NOT matches pattern"
        declare -g m_ec___PS1="\[\e[33m\]\w\[\e[0m\]"
    fi
    # MSYS2 uses an hardcoded # instead of \$
    if [[ ( ! "$l_ec___PS1" =~ '\#' ) && ( "$l_ec___PS1" =~ '#' ) ]] ; then
        # echo "PS1 matches pattern"
        m_ec___PS1="${m_ec___PS1}\n# "
    else
        # echo "PS1 NOT matches pattern"
        m_ec___PS1="${m_ec___PS1}\n"'\$ '
    fi
}

function print_informal_cmd() {
    log "${m_ec___PS1@P}$1"
}

# function log_informal_cmd() {
#     if (( debug_level > 0 )) ; then
#         print_informal_cmd "$@"
#     fi
# }

function print_failed_cmd() {
    internal_err <<__end__
Internal Error: The following external command failed \
with exit status ${l_cmd_exit_status} :
$g_cmd_line
__end__

}

# If the command fails, then g_cmd_line is set
# 
# arguments:
#  $1     - command to execute
# [$2...] - (further) arguments to command
function ext_cmd_fast() {
    # A bit optimized for speed
    unset g_cmd_line g_cmd_out
    local -n l_opts_array="$1_opts"
    local -a l_words=("$1" "${l_opts_array[@]}")
    shift
    if (( debug_level > 0 )) ; then
        l_words+=("$@")
        shift $# # clear all remaining arguments
        local l_cmd_line
        cmd_line_from_array l_cmd_line l_words
        log "${m_ec___PS1@P}${l_cmd_line}"
    fi
    if (( do_run > 0 )) ; then
        if (( "${l_ec___do_abort_on_non_zero_exit_status:-1}" )) ; then
            command "${l_words[@]}" "$@"
            local -i l_cmd_exit_status=$?
        else
            trap___deactivate ERR
            command "${l_words[@]}" "$@"
            local -i l_cmd_exit_status=$?
            trap___activate ERR
        fi
        # if command "${l_words[@]}" "$@" ; then
        #     :
        # fi
        # trace_int_var l_cmd_exit_status
        # if (( ${l_ec___do_abort_on_non_zero_exit_status:+l_ec___do_abort_on_non_zero_exit_status &&} \
        #       l_cmd_exit_status ))
        # then
        #     l_words+=("$@")
        #     declare -g g_cmd_line
        #     cmd_line_from_array g_cmd_line l_words
        #     print_failed_cmd
        # fi
        return "$l_cmd_exit_status"
    fi
    return 0 # fake success of command
}

# Normally command's stdout is not passed to script's stdout
# Instead command's stdout is is stored in the variable g_cmd_stdout
# stderr remains connected to script's stderr
# command's stdin will be connected to script's stdin
# 
# arguments:
#  $1     - command to execute
# [$2...] - (further) arguments to command
function ext_cmd_fast2() {
    # A bit optimized for speed
    unset g_cmd_line
    declare -g -a g_cmd_out=()
    local -n l_opts_array="${l_ec___internal_cmd_name:-$1}_opts"
    local -a l_words=("$1" "${l_opts_array[@]}")
    shift
    if (( debug_level > 0 )) ; then
        l_words+=("$@")
        shift $# # clear all remaining arguments
        local l_cmd_line
        cmd_line_from_array l_cmd_line l_words
        log "${m_ec___PS1@P}$l_cmd_line"
    fi
    if (( do_run > 0 )) ; then
        local -i l_ec___do_print_stdin="${l_ec___do_print_stdin:-0}"
        local -i l_ec___do_log_stdout="$(( ! l_ec___do_print_stdin ))"
        
        local l_ec___IFS_backup="$IFS"
        IFS=
        
        { # Here we are in a subshell (anyway)
            if (( "${l_ec___do_abort_on_non_zero_exit_status:-1}" )) ; then
                trap___deactivate ERR
            fi
            command "${l_words[@]}" "$@"
        } |&  while read -r ; do # Note lastpipe option, thus no subshell
                    if (( l_ec___do_print_stdin )) ; then 
                        printf "%s\n" "$REPLY"
                    fi
                    g_cmd_out+=("$REPLY")
                    if (( l_ec___do_log_stdout )) ; then
                        log_plain "$REPLY"
                    fi
                done
        
        local -i l_cmd_exit_status=$? # Note pipefail option
        
        IFS="$l_ec___IFS_backup"
        
        # if (( ${l_ec___do_abort_on_non_zero_exit_status:+l_ec___do_abort_on_non_zero_exit_status &&} \
        #       l_cmd_exit_status ))
        # then
        #     l_words+=("$@")
        #     declare -g g_cmd_line
        #     cmd_line_from_array g_cmd_line l_words
        #     print_failed_cmd
        # fi
        return "$l_cmd_exit_status"
    fi
    return 0 # fake success of command
}


function unix2dos() {
    ext_cmd_fast unix2dos "$@"
}
function dos2unix() {
    ext_cmd_fast dos2unix "$@"
}
function patch() {
    ext_cmd_fast patch "$@"
}
function diff() {
    # hide before ERR trap, because diff returns with exit status 1,
    # if both files are different, which is a normal use case
    local -i l_ec___do_abort_on_non_zero_exit_status=0
    if ext_cmd_fast diff "$@"; then
        :
    fi
    return 0
}
function mv() {
    ext_cmd_fast mv "$@"
}
function cp() {
    ext_cmd_fast cp "$@"
}
function rm() {
    ext_cmd_fast rm "$@"
}
# function cd() {
#     ext_cmd_fast cd "$@"
# }
function mkdir() {
    ext_cmd_fast mkdir "$@"
}
function bash() {
    ext_cmd_fast bash "$@"
}
function unzip() {
    ext_cmd_fast unzip "$@"
}
function tar() {
    ext_cmd_fast tar "$@"
}
function win_cmd_exe() {
    # ext_cmd_special win_cmd_exe "$COMSPEC" "$@"
    local l_ec___internal_cmd_name="win_cmd_exe"
    ext_cmd_fast2 "$COMSPEC" "$@"
}
function make() {
    ext_cmd_fast2 "make" "$@"
}
function realpath() {
    ext_cmd_fast2 realpath "$@"
}
function find() {
    ext_cmd_fast2 find "$@"
}
function sort() {
    ext_cmd_fast2 sort "$@"
}
function md5sum() {
    ext_cmd_fast2 md5sum "$@"
}

# $1  - function name
# $2  - filepath
# $3  - description of content
function __ext_cmds___write_to_file___pre() {
    unset g_cmd_line g_cmd_out
    if (( debug_level > 0 )) ; then
        local -a l_words=("$2")
        local l_cmd_line
        cmd_line_from_array l_cmd_line l_words
        print_informal_cmd "${1} ${l_cmd_line} ${3}"
    fi
}

# $1  - function name
# $2  - filepath
# $3  - description of content
function __ext_cmds___write_to_file___post() {
    local -i l_cmd_exit_status=$?
    if (( l_cmd_exit_status )) ; then
        local -a l_words=("$2")
        declare -g g_cmd_line
        cmd_line_from_array g_cmd_line l_words
        g_cmd_line="${1} ${g_cmd_line} ${3}"
        print_failed_cmd
    fi
}

# $1 - function name
# $2 - description of content
function __ext_cmds___write_to_file___assert_dirpath_exists() {
    local l_ec___dirpath l_ec___filename
    split_filepath l_ec___dirpath l_ec___filename "$1"
    if [[ ( "$l_ec___dirpath" ) && ( ! -d "$l_ec___dirpath" ) ]] ; then
        if [[ -e "$l_ec___dirpath" ]] ; then
            internal_err <<__end__
The Lua Wrapper Shell wants to write
$2
to the file
$1

The directory
${l_ec___dirpath}
that should contain the file exists, but is not a directory.
__end__
        fi
        mkdir -p "$l_ec___dirpath"
    fi
}

# writes a string or the stdin to a file
# Thus the original content of the file is discarded.
#
# arguments:
#  $1  - filepath
#  $2  - description of content,
#        By convention the description should be enclosed in <...> ,
#        if the description is not the string to write.
# [$3] - string
#        if not provided: read file content from stdin
function write_to_file() {
    __ext_cmds___write_to_file___pre "write_to_file" "$1" "$2"
    if (( do_run > 0 )) ; then
        __ext_cmds___write_to_file___assert_dirpath_exists "$1" "$2"
        if [[ -v 3 ]] ; then
            # The here string unconditionally appends a newline
            if [[ "$3" =~ $'\n'$ ]] ; then
                cat > "$1" <<< "${3:0:-1}"
            else
                cat > "$1" <<< "$3"
            fi
        else
            cat > "$1"
        fi
        __ext_cmds___write_to_file___post "write_to_file" "$1" "$2"
    fi
}

# appends a string or the stdin to a file
# Thus the original content of the file is retained.
#
# arguments:
#  $1  - filepath
#  $2  - description of content
#        By convention the description should be enclosed in <...> ,
#        if the description is not itself the string to write.
# [$3] - string
#        if not provided: read file content from stdin
function append_to_file() {
    __ext_cmds___write_to_file___pre "append_to_file" "$1" "$2"
    if (( do_run > 0 )) ; then
        __ext_cmds___write_to_file___assert_dirpath_exists "$1" "$2"
        if [[ -v 3 ]] ; then
            # The here string unconditionally appends a newline
            if [[ "$3" =~ $'\n'$ ]] ; then
                cat >> "$1" <<< "${3:0:-1}"
            else
                cat >> "$1" <<< "$3"
            fi
        else
            cat >> "$1"
        fi
        __ext_cmds___write_to_file___post "append_to_file" "$1" "$2"
    fi
}

# reads a file and stores its contents in the provided var
# 
# arguments:
# $1 - str var name
# $2 - filepath
function read_file_to_str_var() {
    unset g_cmd_line g_cmd_out
    if (( debug_level > 0 )) ; then
        local -a l_words=("$1" "$2")
        local l_cmd_line
        cmd_line_from_array l_cmd_line l_words
        print_informal_cmd "read_file_to_str_var ${l_cmd_line}"
    fi
    if [[ (( do_run < 1 )) && ( ! -e "$2" ) ]] ; then
        # do not read if dry run and file not exists
        return
    fi
    # avoid ERR trap
    if read -r -N "2147483647" "$1" < "$2" ; then # constant == 2^31-1
        echo -n
    fi
}

# TODO read_file_to_array()



# ===== Temporary Files and Directories ==========

declare -g -i m_ec___remove_temp_dir_trap_not_installed=1

function __ec___ensure_remove_temp_dir_trap_is_installed() {
    if (( m_ec___remove_temp_dir_trap_not_installed )) ; then
        trap___install_cmd EXIT "rm -rf '${temp_dirpath}'"
        m_ec___remove_temp_dir_trap_not_installed=0
        mkdir "${temp_dirpath}"
    fi
}

# faster variant of mktemp, because it does not call an external command
# The file at the returned filepath is automatically removed, when the script exits.
# (normally or with an error.)
# 
# Implementation Note:
# hopefully SRANDOM is secure enough
# 
# arguments:
#  $1  - ret str var name
# [$2] - file extension, can be empty
#        default: .txt
#        Only set the optional argument, if really necessary,
#        to avoid unintended execution of temporary script files.
function temp_filepath() {
    if [[ "$1" != "l_ec___temp_filepath" ]] ; then
        local -n l_ec___temp_filepath="$1"
    fi
    if (( "$#" > 1 )) ; then
        local l_ec___fileext="$2"
    else
        local l_ec___fileext=".txt"
    fi
    __ec___get_temp_filepath "$l_ec___fileext"
    while [[ -e "$l_ec___temp_filepath" ]] ; do
        __ec___get_temp_filepath "$l_ec___fileext"
    done
    __ec___ensure_remove_temp_dir_trap_is_installed
}

# used by abbr_path_from_long_path() in config.bash
declare -g -a g_aux___temp_dirs

# The directory at the returned dirpath is automatically removed, when the scripts exits.
# (normally or with an error.)
# 
# Implementation Note:
# hopefully SRANDOM is secure enough
# 
# argument:
# $1 - ret str var name
function ec___temp_dirpath() {
    if [[ "$1" != "l_ec___temp_dirpath" ]] ; then
        local -n l_ec___temp_dirpath="$1"
    fi
    __ec___get_temp_dirpath
    while [[ -e "$l_ec___temp_dirpath" ]] ; do
        __ec___get_temp_dirpath
    done
    __ec___ensure_remove_temp_dir_trap_is_installed
    g_aux___temp_dirs+=("$l_ec___temp_dirpath")
}

# $1 - file extension, including the dot
# 
# uses from calling context:
# l_ec___temp_filepath
function __ec___get_temp_filepath() {
    l_ec___temp_filepath="${temp_dirpath}/${FUNCNAME[2]}___${SRANDOM}${1}"
}

# uses from calling context:
# l_ec___temp_dirpath
function __ec___get_temp_dirpath() {
    l_ec___temp_dirpath="${temp_dirpath}/${FUNCNAME[2]}___${SRANDOM}"
}

# ========== Checksums ====================

# $1 - ret str var name
# $2 - filepath
function calc_md5sum() {
    if [[ "$1" != "l_ec___md5sum" ]] ; then
        local -n l_ec___md5sum="$1"
    fi
   
    md5sum "$2"
    # strip the longest suffix beginning with a space
    l_ec___md5sum="${g_cmd_out[0]%% *}"
    
    if [[ "$l_ec___md5sum" =~ [^[:xdigit:]] ]] ; then
        local l_ec___bash_word
        bash_word_from_str l_ec___bash_word "$l_ec___md5sum"
        internal_err "malformed MD5sum ${l_ec___bash_word}"
    fi
}

__ec___init "$@"
