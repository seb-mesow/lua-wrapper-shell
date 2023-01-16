exec_module print
exec_module auxillary

function DEBUG_pause() {
    if (( debug_level > 0 )) ; then
        { 
            echo
            read -n 1 -s -p "DEBUG pause: Press any key to proceed" l_char
            #if [[ "$l_char" != $'\n' ]] ; then
            echo 
            #fi
        } >&2
    fi
}

# ========== Messages ====================

# uses l_log___prefix   from calling context
# uses l_log___category_str from calling context
# uses l_log___leader   from calling context
# uses l_log___str      from calling context
# uses l_log___trailer  from calling context
# uses l_log___suffix   from calling context
# It is required, that l_log___str does not contain a "trailing newline",
# if not an extra, trailing, empty line is intended.
function __log___print_with_category() {
    if [[ "$l_log___category_str" ]] ; then
        local l_log___line_prefix="${l_log___category_str}: "
    fi
    l_log___str="${l_log___leader}${l_log___leader:+$'\n'}${l_log___str}${l_log___trailer:+$'\n'}${l_log___trailer}"
    printf "%s%s%s" \
            "$l_log___prefix" \
            "${l_log___line_prefix}${l_log___str//$'\n'/$'\n'"$l_log___line_prefix"}" \
            "$l_log___suffix"
    unset l_log___category_str l_log___str \
          l_log___prefix   l_log___suffix \
          l_log___leader   l_log___trailer
}

#  $1     - log category
# [$2...] - lines, will be concated by a line feed (should not contain line feeds)
#           if not provided: read lines from stdin
function log___plain_custom_category() {
    local l_log___category_str="$1"
    shift
    if [[ -v 1 ]] ; then
        l_log___old_IFS="$IFS"
        IFS=$'\n'
        local l_log___str="$*"
        IFS="$l_log___old_IFS"
    else
        local l_log___str
        assign_long_str l_log___str
        l_log___str="${l_log___str%$'\n'}" # strip trailing newline
    fi
    local l_log___suffix=$'\n'
    __log___print_with_category
}

#   $1     - log category
#   $2     - fmt with place holders (may contain \n for a line break)
#  [$3...] - replacements for placeholders (should not contain line feeds)
function log___plainf_custom_category() {
    local l_log___category_str="$1" l_log___str
    shift
    printf -v l_log___str "$@"
    local l_log___suffix=$'\n'
    __log___print_with_category
}

#  $1     - log category
# [$2...] - replacements for placeholders (should not contain line feeds)
# The format with the placeholders is read from stdin
function log___plainf_stdin_custom_category() {
    local l_log___category_str="$1" l_log___fmt l_log___str
    shift 1
    assign_long_str l_log___fmt
    # strip trailing newline from l_log___fmt
    printf -v l_log___str "${l_log___fmt%$'\n'}" "$@"
    local l_log___suffix=$'\n'
    __log___print_with_category
}

#  $1     - log category
#  $2     - func name to call,
#           prints something to stdout
# [$3...] - arguments to that func
function log___plain_func_custom_category() {
    local l_log___category_str="$1"
    shift
    local l_log___str="$("$@")" # command substitution automatically strips a trailing line feed
    local l_log___suffix=$'\n'
    __log___print_with_category
}

#  $1     - log category
# [$2...] - lines (should not contain line feeds)
function log___msg_custom_category() {
    local l_log___prefix=$'\n' l_log___suffix=$'\n'
    log___plain_custom_category "$@"
}
#  $1     - log category
#  $2     - fmt with place holders (may contain \n for a line break)
# [$3...] - replacements for placeholders (should not contain line feeds)
function log___msgf_custom_category() {
    local l_log___prefix=$'\n' l_log___suffix=$'\n'
    log___plainf_custom_category "$@"
}
#  $1     - log category
# [$2...] - replacements for placeholders (should not contain line feeds)
# The format with the placeholders is read from stdin
function log___msgf_stdin_custom_category() {
    local l_log___prefix=$'\n' l_log___suffix=$'\n'
    log___plainf_stdin_custom_category "$@"
}
#  $1     - log category
#  $2     - func name to call,
#           prints something to stdout
# [$3...] - arguments to that func
function log___msg_func_custom_category() {
    local l_log___prefix=$'\n' l_log___suffix=$'\n'
    log___plain_func_custom_category "$@"
}

# ========== Declare Logging Messages ====================

# $1 - value of ${l_log___to_decl_func_name_stem}
# $2 - value of ${l_log___to_call_func_name}
# $3 - bash statement format
function __log___exec_bash_statement_per_log_func__() {
    local l_log___to_decl_func_name_stem="$1" l_log___to_call_func_name="$2"
    eval "eval \"$3\""
}

function __log___exec_bash_statement_per_log_func() {
    __log___exec_bash_statement_per_log_func__ '_plain'        'log___plain_custom_category'        "$@"
    __log___exec_bash_statement_per_log_func__ '_plainf'       'log___plainf_custom_category'       "$@"
    __log___exec_bash_statement_per_log_func__ '_plainf_stdin' 'log___plainf_stdin_custom_category' "$@"
    __log___exec_bash_statement_per_log_func__ ''              'log___msg_custom_category'          "$@"
    __log___exec_bash_statement_per_log_func__ 'f'             'log___msgf_custom_category'         "$@"
    __log___exec_bash_statement_per_log_func__ 'f_stdin'       'log___msgf_stdin_custom_category'   "$@"
}

# $1 - format, can use
#      ${l_log___to_decl_func_name_stem}
#      ${l_log___to_call_func_name}
# $2 - name of print function, must begin with "print_"
function __log___exec_bash_statement_on_print_func() {
    if [[ "$2" =~ ^([[:alnum:]_]*)'print'([[:alnum:]_]*)$ ]] ; then
        local l_log___to_call_func_name="$2" \
              l_log___to_decl_func_name_module_prefix="${BASH_REMATCH[1]}" \
              l_log___to_decl_func_name_stem="${BASH_REMATCH[2]}"
        eval "eval \"$1\""
    else
        internal_err "provided func name $2 to derive from does contain 'print'"
    fi
}

declare -g -a m_log___print_funcs___to_call_func_name \
              m_log___print_funcs___to_decl_func_name_module_prefix \
              m_log___print_funcs___to_decl_func_name_stem

function __log___setup_print_func_arrays() {
    local l_log___dummy1 l_log___dummy2 l_log___funcname
    # Note active lastpipe option
    declare -pF \
    | while read -r l_log___dummy1 l_log___dummy2 l_log___funcname ; do
         if [[ ( "$l_log___funcname" =~ ^(([[:alnum:]_]*)'print'([[:alnum:]_]*))$ ) \
            && ( "$l_log___funcname" != __* ) ]]
         then
             m_log___print_funcs___to_call_func_name+=("${BASH_REMATCH[1]}")
             m_log___print_funcs___to_decl_func_name_module_prefix+=("${BASH_REMATCH[2]}")
             m_log___print_funcs___to_decl_func_name_stem+=("${BASH_REMATCH[3]}")
         fi
     done
}

__log___setup_print_func_arrays
# saves about 0.1 seconds,
# in contrast to a command substitution $(declare -p -F)
# for every __log___exec_bash_statement_on_all_print_funcs

# print_indexed_array m_log___print_funcs___to_call_func_name

# $1 - bash statement fmt
#      expanded twice ! Thus e.g a dollar sign in the code must be escaped with two backslashes
#      can use \${l_log___to_call_func_name} and \${l_log___to_decl_func_name_stem}
function __log___exec_bash_statement_on_all_print_funcs() {
    local l_log___to_call_func_name \
          l_log___to_decl_func_name_module_prefix \
          l_log___to_decl_func_name_stem
    local -i l_log___i l_log___n="${#m_log___print_funcs___to_call_func_name[@]}"
    for (( l_log___i=0 ; l_log___i < l_log___n ; l_log___i++ )) ; do
        l_log___to_call_func_name="${m_log___print_funcs___to_call_func_name[l_log___i]}"
        l_log___to_decl_func_name_module_prefix="${m_log___print_funcs___to_decl_func_name_module_prefix[l_log___i]}"
        l_log___to_decl_func_name_stem="${m_log___print_funcs___to_decl_func_name_stem[l_log___i]}"
        eval "eval \"$1\""
    done
}

# ========== Log Messages ====================

# are printed to stderr

declare m_log___log_func_decl_fmt
assign_long_str m_log___log_func_decl_fmt <<'__end__'
function ${l_log___to_decl_func_name_module_prefix}${l_log___to_decl_func_name_prefix}${l_log___to_decl_func_name_stem}() {
    if (( debug_level > ${l_log___required_debug_level_minus_one} )) ; then
        ${l_log___to_call_func_name} \"${l_log___category_str}\" \"\$@\" >&2
    fi
}
__end__


declare -g m_log___log_print_func_decl_fmt
assign_long_str m_log___log_print_func_decl_fmt <<'__end__'
function ${l_log___to_decl_func_name_module_prefix}${l_log___to_decl_func_name_prefix}${l_log___to_decl_func_name_stem}() {
    if (( debug_level > ${l_log___required_debug_level_minus_one} )) ; then
        log___msg_func_custom_category \"${l_log___category_str}\" ${l_log___to_call_func_name} \"\$@\" >&2
    fi
}
__end__

# $1 - value for ${l_log___to_decl_func_name_prefix"}
# $2 - value for ${l_log___required_debug_level_minus_one}
# $3 - value for ${l_log___category_str}
function __log___declare_debug_funcs() {
    local l_log___to_decl_func_name_prefix="$1" \
          l_log___category_str="$3"
    local -i l_log___required_debug_level_minus_one="$2"
    
    __log___exec_bash_statement_per_log_func       "$m_log___log_func_decl_fmt"
    __log___exec_bash_statement_on_all_print_funcs "$m_log___log_print_func_decl_fmt"
}

__log___declare_debug_funcs "log"   "0" "Log"
__log___declare_debug_funcs "debug" "1" "Debug"
__log___declare_debug_funcs "trace" "2" "Trace"

# $1 - name of print function, must contain with "print"
function declare_debug_funcs_from_print_func() {
    local l_log___to_decl_func_name_prefix="log" l_log___category_str="Log"
    local -i l_log___required_debug_level_minus_one="0"
    __log___exec_bash_statement_on_print_func "$m_log___log_print_func_decl_fmt" "$1"
    
    l_log___to_decl_func_name_prefix="debug" l_log___category_str="Debug"
    l_log___required_debug_level_minus_one="1"
    __log___exec_bash_statement_on_print_func "$m_log___log_print_func_decl_fmt" "$1"
    
    l_log___to_decl_func_name_prefix="trace" l_log___category_str="Trace"
    l_log___required_debug_level_minus_one="2"
    __log___exec_bash_statement_on_print_func "$m_log___log_print_func_decl_fmt" "$1"
}

# function log_empty_line() {
#     if (( debug_level > 0 )) ; then
#         echo >&2
#     fi
# }

# ========== Internal Error Messages ====================

# are printed to stderr

declare m_log___internal_err_func_decl_fmt
assign_long_str m_log___internal_err_func_decl_fmt <<'__end__'
function ${l_log___to_decl_func_name_module_prefix}internal_err${l_log___to_decl_func_name_stem}() {
    {
        local l_log___leader
        printf -v l_log___leader \"in function \\e[31m%s()\\e[0m:\\n\" "\${FUNCNAME[1]}"
        local l_log___trailer=$'\nThus aborting with exit status 2 .'
        ${l_log___to_call_func_name} \"Internal Error\" \"\$@\"
        
        exec_module callstack
        local l_log___CS_n
        CS___snapshot l_log___CS_n 1
        CS___show_long \"\$l_log___CS_n\"
    } >&2
    exit 2
}
__end__

__log___exec_bash_statement_per_log_func "$m_log___internal_err_func_decl_fmt"

declare m_log___internal_err_func_decl_fmt_no_abort
assign_long_str m_log___internal_err_func_decl_fmt_no_abort <<'__end__'
function ${l_log___to_decl_func_name_module_prefix}internal_err${l_log___to_decl_func_name_stem}_no_abort() {
    {
        local l_log___leader
        printf -v l_log___leader \"in function \\e[31m%s()\\e[0m:\\n\" "\${FUNCNAME[1]}"
        ${l_log___to_call_func_name} \"Internal Error\" \"\$@\"
        
        exec_module callstack
        local l_log___CS_n
        CS___snapshot l_log___CS_n 1
        CS___show_long \"\$l_log___CS_n\"
        CS___delete \"\$l_log___CS_n\"
    } >&2
}
__end__

__log___exec_bash_statement_per_log_func "$m_log___internal_err_func_decl_fmt_no_abort"

# ========== User Error Messages ====================

# Are printed to stdout

declare m_log___user_err_func_decl_fmt
assign_long_str m_log___user_err_func_decl_fmt <<'__end__'
function ${l_log___to_decl_func_name_module_prefix}user_err${l_log___to_decl_func_name_stem}() {
    local l_log___trailer="\${l_log___trailer}\${l_log___trailer:+\$'\\n'}"\$'\\nThus aborting with exit status 1 .'
    ${l_log___to_call_func_name} \"\" \"\$@\"
    exit 1
}
__end__

__log___exec_bash_statement_per_log_func "$m_log___user_err_func_decl_fmt"

declare m_log___user_err_func_decl_fmt___no_abort
assign_long_str m_log___user_err_func_decl_fmt___no_abort <<'__end__'
function ${l_log___to_decl_func_name_module_prefix}user_err${l_log___to_decl_func_name_stem}_no_abort() {
    ${l_log___to_call_func_name} \"\" \"\$@\"
}
__end__

__log___exec_bash_statement_per_log_func "$m_log___user_err_func_decl_fmt___no_abort"

# ========== User / Info Messages ====================

declare m_log___user_info_func_decl_fmt
assign_long_str m_log___user_info_func_decl_fmt <<'__end__'
function ${l_log___to_decl_func_name_module_prefix}user_msg${l_log___to_decl_func_name_stem}() {
    ${l_log___to_call_func_name} \"\" \"\$@\"
}
__end__

__log___exec_bash_statement_per_log_func "$m_log___user_info_func_decl_fmt"

# declare -p -F
# return
# 
# declare -p -f log_plain
# declare -p -f log_plainf
# declare -p -f log_plainf_stdin
# declare -p -f log
# declare -p -f logf
# declare -p -f logf_stdin
# declare -p -f debug
# declare -p -f debug_plain
# 
# declare -p -f log_str_var
# declare -p -f debug_str_var
# declare -p -f trace_str_var
# declare -p -f log_file_contents
# 
# 
# declare -p -f internal_err_plain
# declare -p -f internal_err_plainf
# declare -p -f internal_err_plainf_stdin
# declare -p -f internal_err
# declare -p -f internal_errf
# declare -p -f internal_errf_stdin
# 
# declare -p -f user_err

# exit 0
