# ===== Auxillary ====================

# $1 - ret str var name
# $2 - bash var name
function value_of_bash_var() {
    local -n l_aux___str="$1"
    if [[ -v "$2" ]] ; then
        l_aux___str="$2"
    else
        l_aux___str="$(command bash -i -c "echo \"\$$2\"")"
    fi
}

# ========== Integer Arithmetic / Shell Arithmetic ====================

# read -N <int> only excepts 32-bit signed integers

declare -g -i g_aux___max_int="0x7FFFFFFF"
declare -g -i g_aux___min_int="0x80000000"
if (( g_aux___min_int >= 0 )) ; then
    g_aux___min_int=-g_aux___min_int
fi

# ========== Assigments ====================

# reads from stdin and assigns this to a str var
# $1 - str var name
function assign_long_str() {
    ! read -r -N "$g_aux___max_int" "$1"
}

# reads from stdin and assigns this to a str var
# $1 - str var name
function assign_long_str_no_trailing_linefeed() {
    assign_long_str "$1"
    local -n l_aux___str="$1"
    l_aux___str="${l_aux___str%$'\n'}"
}

# creates a unique varname from a stem
# $1 - ret str var name for unique var name
# $2 - stem str ; used as prefix
function unique_varname() {
    if [[ "$1" != "l_aux___varname" ]] ; then
        local -n l_aux___varname="$1"
    fi
    l_aux___varname="${2}${SRANDOM}"
    while is_var_defined "$l_aux___varname" ; do
        l_aux___varname="${2}${SRANDOM}"
    done
}

# returns with the zero exit status, if the variable is defined
# returns with a non-zero exit status if the variable is not defined
# 
# argument:
# $1 - var name
function is_var_defined() {
    [[ "$1" ]] && declare -p "$1" &> /dev/null
}

# returns with the zero exit status, if the variable is not defined
# returns with a non-zero exit status if the variable is defined
# 
# argument:
# $1 - var name
function is_var_undefined() {
    [[ -z "$1" ]] || ! declare -p "$1" &> /dev/null
}

# ========== Strings ====================

# $1 - varname for output
# $2 - input_str
function strip_surrounding_whitespace() {
    if [[ "$1" != "l_aux___ret_str" ]] ; then
        local -n l_aux___ret_str="$1"
    fi
    local l_aux___arg_str="$2"
    # Because we must be able to match multiple [:blank:] chars,
    # we can not use simple bash pattern matching, unless we would
    # set the shell option to enable extended bash pattern matching
    # Thus we use regex.
    if [[ "$l_aux___arg_str" =~ ^[[:blank:]]+ ]] ; then # strip leading whitespace
        l_aux___arg_str="${l_aux___arg_str#"${BASH_REMATCH[0]}"}"
    fi
    if [[ "$l_aux___arg_str" =~ [[:blank:]]+$ ]] ; then # strip trailing whitespace
        l_aux___arg_str="${l_aux___arg_str%"${BASH_REMATCH[0]}"}"
    fi
    l_aux___ret_str="$l_aux___arg_str"
}

# prefixes each line in a string with a provided prefix
# Each line in the argument string must be terminated by a line feed.
#
# arguments:
#  $1  - ret str var name
#  $2  - string
# [$3] - prefix (mostly a tab like sequence)
#        default: 2 spaces
function intend_long_str() {
    if [[ "$1" != "l_aux___ret_str" ]] ; then
        local -n l_aux___ret_str="$1"
    fi
    local l_aux___prefix="${3:-  }"
    
    if [[ "$2" == *$'\n' ]] ; then
        l_aux___ret_str="${2%$'\n'}"
        l_aux___ret_str="\
${l_aux___prefix}\
${l_aux___ret_str//$'\n'/$'\n'"$l_aux___prefix"}"\
$'\n'
    else
        l_aux___ret_str="\
${l_aux___prefix}\
${l_aux___ret_str//$'\n'/$'\n'"$l_aux___prefix"}"
    fi
}

# prefixes the first line with the formatted number
# and all following lines with the same amout of spaces
# $1  - ret str var name
# $2  - first line prefix
# $3  - long string
function intend_long_str_with_first_line_prefix() {
    if [[ "$1" != "l_aux___ret_str" ]] ; then
        local -n l_aux___ret_str="$1"
    fi
    if [[ "$2" =~ \n([^\n]*)$ ]] ; then
        local -i l_aux___intend_spaces="${#BASH_REMATCH[1]}"
    else
        local -i l_aux___intend_spaces="${#2}"
    fi
    
    [[ "$3" =~ ^$'\n'* ]]
    local l_aux___leading_linefeeds="${BASH_REMATCH[0]}"
    [[ "$3" =~ $'\n'*$ ]]
    local l_aux___trailing_linefeeds="${BASH_REMATCH[0]}" \
          l_aux___spaces_prefix
    
    printf -v l_aux___spaces_prefix "%*s" "$l_aux___intend_spaces" ""
    
    if [[ "$l_aux___trailing_linefeeds" ]] ; then
        l_aux___ret_str="${3:${#l_aux___leading_linefeeds}:-${#l_aux___trailing_linefeeds}}"
    else
        l_aux___ret_str="${3:${#l_aux___leading_linefeeds}}"
    fi
    
    l_aux___ret_str="\
${2}\
${l_aux___leading_linefeeds}\
${l_aux___ret_str//$'\n'/$'\n'"$l_aux___spaces_prefix"}\
${l_aux___trailing_linefeeds}"
}

# $1 - ret str var name
# $2 - number of spaces
# $3 - long string
function intend_long_str_with_spaces() {
    if [[ "$1" != "l_aux___ret_str" ]] ; then
        local -n l_aux___ret_str="$1"
    fi
    
    [[ "$3" =~ ^$'\n'* ]]
    local l_aux___leading_linefeeds="${BASH_REMATCH[0]}"
    [[ "$3" =~ $'\n'*$ ]]
    local l_aux___trailing_linefeeds="${BASH_REMATCH[0]}" \
          l_aux___spaces_prefix
    printf -v l_aux___spaces_prefix "%*s" "$2" ""
    
    if [[ "$l_aux___trailing_linefeeds" ]] ; then
        l_aux___ret_str="${3:${#l_aux___leading_linefeeds}:-${#l_aux___trailing_linefeeds}}"
    else
        l_aux___ret_str="${3:${#l_aux___leading_linefeeds}}"
    fi
    
    l_aux___ret_str="\
${l_aux___leading_linefeeds}\
${l_aux___spaces_prefix}\
${l_aux___ret_str//$'\n'/$'\n'"$l_aux___spaces_prefix"}\
${l_aux___trailing_linefeeds}"
}


# concats the values of an indexed or associative array
# If the array has no elements, that the target string variable is unset.
#
# arguments:
#  $1  - ret str var name
#  $2  - input array var name (better an indexed array)
# [$3] - sep
# [$4] - per-item prefix
# [$5] - per-item suffix
function concat_str_from_array() {
    if [[ "$1" != "l_aux___concated_str" ]] ; then
        local -n l_aux___concated_str="$1"
    fi
    if [[ "$2" != "l_aux___array" ]] ; then
        local -n l_aux___array="$2"
    fi
    l_aux___concated_str=""
    local l_aux___item_str
    for l_aux___item_str in "${l_aux___array[@]}" ; do
        l_aux___concated_str="\
${l_aux___concated_str:+\
${l_aux___concated_str}\
${3}\
}\
${4}${l_aux___item_str}${5}"
    done
}

# splits a string at each occurence of a string
# 
# arguments:
# $1 - name of target variable as indexed array
# $2 - string
# $3 - substring to split at
function split_str() {
    if [[ -z "$3" ]] ; then
        internal_err "string to split at is empty"
    fi
    
    if [[ "$1" != "l_aux___ret_array" ]] ; then
        local -n l_aux___ret_array="$1"
    fi
    l_aux___ret_array=()
    if [[ "$2" ]] ; then
        local l_aux___temp="$2"
        while [[ "$l_aux___temp" =~ ^(.*)"$3"(.*)$ ]] ; do
            # The above pattern tries to find the /longest/ match for the 1st group
            # Only the rest can match the 2nd group
            l_aux___temp="${BASH_REMATCH[1]}"
            # thus prepend (and not append)
            l_aux___ret_array=("${BASH_REMATCH[2]}" "${l_aux___ret_array[@]}")
        done
        # prepend remaining
        l_aux___ret_array=("$l_aux___temp" "${l_aux___ret_array[@]}")
    fi
}

# calculates the global, internal name from a user provided file to patch key
# $1 - ret str var name
# $2 - user provided file to patch key
function key_from_user_provided() {
    if [[ "$1" != "l_aux___ret_key" ]] ; then
        local -n l_aux___ret_key="$1"
    fi
    l_aux___ret_key="${2//[^[:alnum:]]/_}"
    
    # strip surrounding underscores
    if [[ "$l_aux___ret_key" =~ ^_*([^_](.*[^_])?)_*$ ]] ; then # empty string is not allowed
        l_aux___ret_key="${BASH_REMATCH[1]}"
    else
        internal_errf "malformed uFK or uGK '%s'" "$2"
    fi
}

# ========== Formatting ====================

# function better_printf() {
#     if [[ "$1" == "-v" ]] ; then
#         local -n l_aux___str="$2"
#         shift 2
#         l_aux___str="$(env printf "$@")"
#     else
#         env printf "$@"
#     fi
# }

# formats a string such, that it could be reused for a bash assignement.
# (If you do not care about the complexness of the formatted string,
# or you want to guarantee, that it could be reused for input,
# then you should use printf with the %q placeholder)
# 
# arguments:
# $1 - ret str var name
# $2 - str to format
function bash_word_from_str() {
    if [[ "$1" != "l_aux___ret_str" ]] ; then
        local -n l_aux___ret_str="$1"
    fi
    if [[ "$2" =~ [[:cntrl:]] ]] ; then
        # includes newline and tab, but excludes space
        # provoke ANSI C escaping
        printf -v l_aux___ret_str "%q" "$2"$'\a' #
        l_aux___ret_str="${l_aux___ret_str:0:-3}'"
    elif [[ "$2" =~ "'" ]] ; then
        # double quotes with escaping
        # in double quotes the following four (five) chars must be escaped: \ $ ` " (!)
        l_aux___ret_str="${2//'\'/'\\'}" # escape backslash
        l_aux___ret_str="${l_aux___ret_str//'$'/'\$'}" # escape dollar sign
        l_aux___ret_str="${l_aux___ret_str//"\`"/'\`'}" # escape backtick
        l_aux___ret_str="\"${l_aux___ret_str//"\""/'\"'}\"" # escape double quotes
    elif [[ "$2" =~ ^[[:alnum:]_./]+$ ]] ; then
        # unquoted
        l_aux___ret_str="$2"
    else # includes the empty string
        # single quoted
        l_aux___ret_str="'$2'"
    fi
}

function __cmd_line_from_array() {
    # We do not use echo, because echo -n would not work.
    # Note, that -n is an option to unix2dos resp. dos2unix
    if [[ "$1" =~ [[:space:]] ]] ; then
        printf "'%s'" "$1"
    else
        printf "%s" "$1"
    fi
}

# concats the values of an indexed array
# such that it can be evaluated by eval
# The result is stored in the given variable
# 
# arguments:
# $1 - varname of the result string variable
# $2 - varname of source indexed array variable
function cmd_line_from_array() {
    if [[ "$1" != "l_aux___cmd_line" ]] ; then
        local -n l_aux___cmd_line="$1"
    fi
    if [[ "$2" != "l_aux___array" ]] ; then
        local -n l_aux___array="$2"
    fi
    l_aux___cmd_line= # set to null resp. the empty str
    local l_aux___word
    for l_aux___word in "${l_aux___array[@]}" ; do
        # here are more characters allowed in an unquoted word
        # than bash_word_from_str() allows.
        if [[ ! "$l_aux___word" =~ ^[-[:alnum:]_./+]+$ ]] ; then # includes the empty string
            bash_word_from_str l_aux___word "$l_aux___word"
        fi
        l_aux___cmd_line="${l_aux___cmd_line:+"${l_aux___cmd_line} "}${l_aux___word}"
    done
}

#  $1     - ret str var name
# [$2...] - arguments
function cmd_line_from_args() {
    if [[ "$1" != "l_aux___cmd_line" ]] ; then
        local -n l_aux___cmd_line="$1"
    fi
    shift
    l_aux___cmd_line= # set to null resp. the empty str
    local l_aux___word
    for l_aux___word in "$@" ; do
        # here are more characters allowed in an unquoted word
        # than bash_word_from_str() allows.
        if [[ ! "$l_aux___word" =~ ^[-[:alnum:]_./+]+$ ]] ; then # includes the empty string
            bash_word_from_str l_aux___word "$l_aux___word"
        fi
        l_aux___cmd_line="${l_aux___cmd_line:+"${l_aux___cmd_line} "}${l_aux___word}"
    done
}

# ========== Path Conversion ====================

# splits a filepath in the dirname and a filename
# returns a zero exit status, if the file_path is valid
#
# arguments:
# $1 - ret str var name for dirpath
# $2 - ret str var name for filename
# $3 - filepath
function split_filepath() {
    if [[ "$3" =~ ^((.*)[/\\])?([^/\\]+)$ ]] ; then
        if [[ "$1" != "l_aux___dirpath" ]] ; then
            local -n l_aux___dirpath="$1"
        fi
        if [[ "$2" != "l_aux___filename" ]] ; then
            local -n l_aux___filename="$2"
        fi
        
        l_aux___dirpath="${BASH_REMATCH[2]}"
        l_aux___filename="${BASH_REMATCH[3]}"
    else
        internal_errf "invalid filepath\n%s" "$3"
    fi
}

function __aux___declare___m_aux____root_path_win() {
    declare -g m_aux____root_path_win="$(cygpath -w '/')"
}

# faster than cygpath
# $1 - ret str var name
# $2 - absolute path in unix style to convert
function convert_path_to_win() {
    if [[ "$1" != "l_aux___ret_path" ]] ; then
        local -n l_aux___ret_path="$1"
    fi
    if [[ "$2" =~ ^'/' ]] ; then
        if [[ "$2" =~ ^'/'([a-zA-Z])'/' ]] ; then
            l_aux___ret_path="${BASH_REMATCH[1]@U}:${2:2}"
        elif [[ "$2" =~ ^'/'([a-zA-Z])$ ]] ; then
            l_aux___ret_path="${BASH_REMATCH[1]@U}:"
        else
            if [[ ! -v m_aux____root_path_win ]] ; then
                __aux___declare___m_aux____root_path_win
            fi
            l_aux___ret_path="${m_aux____root_path_win}${2:1}"
        fi
    else
        l_aux___ret_path="$2"
    fi
    l_aux___ret_path="${l_aux___ret_path//'/'/'\'}"
}

# faster than cygpath
# $1 - ret str var name
# $2 - absolute path in windows style to convert
function convert_path_to_unix() {
    if [[ "$1" != "l_aux___ret_path" ]] ; then
        local -n l_aux___ret_path="$1"
    fi
    if [[ "$2" =~ ^"$HOMEPATH"(.*)$ ]] ; then
        l_aux___ret_path="${USERPROFILE}${BASH_REMATCH[1]}"
    else
        l_aux___ret_path="$2"
    fi
    if [[ ! -v m_aux____root_path_win ]] ; then
        __aux___declare___m_aux____root_path_win
    fi
    if [[ "$l_aux___ret_path" =~ ^"$m_aux____root_path_win" ]] ; then
        l_aux___ret_path="/${l_aux___ret_path#"$m_aux____root_path_win"}"
    elif [[ "$l_aux___ret_path" =~ ^([a-zA-Z])':' ]] ; then
        l_aux___ret_path="/${BASH_REMATCH[1]@L}${l_aux___ret_path:2}"
    fi
    l_aux___ret_path="${l_aux___ret_path//'\'/'/'}"
}

function __aux___init_win_env_vars() {
    declare -g -a m_aux____win_env_vars___vals \
               m_aux____win_env_vars___names=( \
        OneDrive \
        APPDATA \
        LOCALAPPDATA \
        USERPROFILE \
        "ProgramFiles(x86)" \
        ProgramFiles \
        ProgramData \
        "CommonProgramFiles(x86)" \
        CommonProgramFiles \
        PUBLIC \
        ALLUSERSPROFILE \
        SystemRoot \
        DriverData \
        windir \
        SystemDrive
    ) # sorted by "longest value"
    
    local l_aux___var_name \
          l_aux___init_cmds="@echo off" \
          l_aux___temp_win_cmd_filepath \
          l_aux___cr=$'\r' \
          l_aux___var_val
    
    # writes to stdout the values of the variables
    for l_aux___var_name in "${m_aux____win_env_vars___names[@]}" ; do
        printf -v l_aux___init_cmds \
            "%s\r\necho %%%s%%" \
            "$l_aux___init_cmds" \
            "$l_aux___var_name"
    done
    l_aux___init_cmds="${l_aux___init_cmds}"$'\r\n'"exit 0"
    
    trace_long_str_var l_aux___init_cmds
    
    temp_filepath l_aux___temp_win_cmd_filepath ".bat"
    
    write_to_file "$l_aux___temp_win_cmd_filepath" \
        "<abbreviate_win_path() init CMD script>" \
        "$l_aux___init_cmds"
    
    convert_path_to_win l_aux___temp_win_cmd_filepath "$l_aux___temp_win_cmd_filepath"
    
    win_cmd_exe '//C' "$l_aux___temp_win_cmd_filepath"
    
    for l_aux___var_val in "${g_cmd_out[@]}" ; do
        m_aux____win_env_vars___vals+=("${l_aux___var_val%$l_aux___cr}")
    done
    
    trace_two_arrays_quoted m_aux____win_env_vars___names m_aux____win_env_vars___vals
}

# replaces a trailing part matching the value of a Windows env var
# with the syntax for its expansion
# 
# arguments:
# $1 - ret str var name
# $2 - absolute path in windows style to abbreviate
function abbreviate_win_path() {
    if is_var_undefined m_aux____win_env_vars___vals ; then
        __aux___init_win_env_vars
    fi
    
    if [[ "$1" != "l_aux___ret_path" ]] ; then
        local -n l_aux___ret_path="$1"
    fi
    
    # log "\$2 == '$2'"
    
    local l_aux___var_name \
          l_aux___var_val \
          l_aux___subscript # needed for correct usage with abbreviate_win_paths
    for l_aux___subscript in "${!m_aux____win_env_vars___names[@]}" ; do
        l_aux___var_name="${m_aux____win_env_vars___names["$l_aux___subscript"]}"
         l_aux___var_val="${m_aux____win_env_vars___vals["$l_aux___subscript"]}"
        if [[ "$2" =~ "$l_aux___var_val"* ]] ; then
            l_aux___ret_path="%${l_aux___var_name}%${2#"$l_aux___var_val"}"
            # log_str_var_quoted l_aux___ret_path
            return
        fi
    done
    l_aux___ret_path="$2"
    # log_str_var_quoted l_aux___ret_path
}

# ========== Convert Arrays of Paths ====================

# arguments:
# $1 - ret   indexed array var name
# $2 - input indexed array var name
function convert_paths_to_win() {
    if [[ "$1" != l_aux___ret_paths ]] ; then
        local -n l_aux___ret_paths="$1"
    fi
    if [[ "$2" != l_aux___in_paths ]] ; then
        local -n l_aux___in_paths="$2"
    fi
    if [[ "$1" != "$2" ]] ; then
        l_aux___ret_paths=()
    fi # if equal, then the values at all subscripts are overwritten
    local l_aux___ret_path \
          l_aux___subscript
    for l_aux___subscript in "${!l_aux___in_paths[@]}" ; do
        convert_path_to_win l_aux___ret_path \
            "${l_aux___in_paths["$l_aux___subscript"]}"
        l_aux___ret_paths["$l_aux___subscript"]="$l_aux___ret_path"
    done
}

# arguments:
# $1 - ret   indexed array var name
# $2 - input indexed array var name
function convert_paths_to_unix() {
    if [[ "$1" != l_aux___ret_paths ]] ; then
        local -n l_aux___ret_paths="$1"
    fi
    if [[ "$2" != l_aux___in_paths ]] ; then
        local -n l_aux___in_paths="$2"
    fi
    if [[ "$1" != "$2" ]] ; then
        l_aux___ret_paths=()
    fi # if equal, then the values at all subscripts are overwritten
    local l_aux___ret_path \
          l_aux___subscript
    for l_aux___subscript in "${!l_aux___in_paths[@]}" ; do
        convert_path_to_unix l_aux___ret_path \
            "${l_aux___in_paths["$l_aux___subscript"]}"
        l_aux___ret_paths["$l_aux___subscript"]="$l_aux___ret_path"
    done
}

# replaces a trailing part matching the value of a Windows env var
# with the syntax for its expansion
# 
# arguments:
# $1 - ret   indexed array var name
# $2 - input indexed array var name
function abbreviate_win_paths() {
    if [[ "$1" != l_aux___ret_paths ]] ; then
        local -n l_aux___ret_paths="$1"
    fi
    if [[ "$2" != l_aux___in_paths ]] ; then
        local -n l_aux___in_paths="$2"
    fi
    if [[ "$1" != "$2" ]] ; then
        l_aux___ret_paths=()
    fi # if equal, then the values at all subscripts are overwritten
    local l_aux___ret_path \
          l_aux___subscript
    for l_aux___subscript in "${!l_aux___in_paths[@]}" ; do
        abbreviate_win_path l_aux___ret_path \
            "${l_aux___in_paths["$l_aux___subscript"]}"
        l_aux___ret_paths["$l_aux___subscript"]="$l_aux___ret_path"
    done
}

# ========== Convert PATH-like strings ====================

# Output path sep is always ';' (semicolon).
# Input path sep is adaptable.
# 
# arguments:
#  $1  - ret str var name
#  $2  - input PATH-like str in Unix-style
# [$3] - input path sep
#        default: ':' (colon)
function convert_PATH_like_str_to_win() {
    local -a l_aux___paths
    split_str l_aux___paths "$2" "${3:-":"}"
    convert_paths_to_win l_aux___paths l_aux___paths
    concat_str_from_array "$1" l_aux___paths ';'
}

# Output path sep is adaptable.
# Input path sep is adaptable.
#
# arguments:
#  $1  - ret str var name
#  $2  - input PATH-like str in Windows-style
# [$3] - ret path sep
#        default: ':' (colon)
# [$4] - input path sep
#        default: ';' (semicolon)
function convert_PATH_like_str_to_unix() {
    local -a l_aux___paths
    split_str l_aux___paths "$2" "${4:-";"}"
    convert_paths_to_unix l_aux___paths l_aux___paths
    concat_str_from_array "$1" l_aux___paths "${3:-":"}"
}

# replaces a trailing part matching the value of a Windows env var
# with the syntax for its expansion
# 
# arguments:
# $1 - ret str var name
# $2 - input PATH-like str in Windows-style
function abbreviate_win_PATH_like_str() {
    local -a l_aux___paths
    split_str l_aux___paths "$2" ";"
    abbreviate_win_paths l_aux___paths l_aux___paths
    concat_str_from_array "$1" l_aux___paths ";" 
}
