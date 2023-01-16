exec_module config

# returns the name of the versioned corressponding environment variable
# to a given environment variable
# 
# arguments:
# $1 - ret str var name
# $2 - unversioned env var name
function cev___determinate_versioned_env_var_name() {
    if [[ ! "$lua_version" =~ ^[[:digit:]]+\.[[:digit:]] ]] ; then
        local l_cev___lua_version_bash_word
        bash_word_from_str l_cev___lua_version_bash_word "$lua_version"
        internal_errf "Internal Lua Version does not match regex:\nlua_version == %s" \
            "$l_cev___lua_version_bash_word"
    fi
    local -n l_cev___versioned_var_name="$1"
    strip_surrounding_whitespace l_cev___versioned_var_name "$2"
    l_cev___versioned_var_name="${l_cev___versioned_var_name}_${lua_version}"
    l_cev___versioned_var_name="${l_cev___versioned_var_name//[^a-zA-Z0-9_]/_}"
}

# ========== Clear Environment Variables ====================

# The Arguments should still be in the from path style

# arguments:
#  $1  - ret str var name
# [$2] - indexed array varname for the removed entries
function __cev___cleared_PATHEXT() {
    __cev___cleared_env_var___impl "$1" \
        "$PATHEXT" ";" \
        __cev___is_dot_LUA \
        "$2"
}

function __cev___is_dot_LUA() {
    [[ "$1" == ".LUA" ]]
}

# arguments:
#  $1  - ret str var name
#  $2  - input env var val to clear
# [$3] - indexed array var name for the removed entries
function __cev___cleared_env_var___default___unix() {
    __cev___cleared_env_var___impl "$1" \
        "$2" ":" \
        __cev___is_luarocks_main_dir___or___lua_main_dir \
        "$3"
}
function __cev___cleared_env_var___default___win() {
    __cev___cleared_env_var___impl "$1" \
        "$2" ";" \
        __cev___is_luarocks_main_dir_win___or___lua_main_dir_win \
        "$3"
}

# clears all entries fulfilling a given predicate
# 
# arguments:
#  $1  - ret str var name
#  $2  - input env var val to clear
#  $3  - entry sep to work in
#  $4  - predicate func an entry must fulfill to be removed
# [$5] - indexed array var name for the removed entries
# 
# uses from calling context:
# l_cev___to_clear_predicate_func <entry>
function __cev___cleared_env_var___impl() {
    local -a l_cev___existing_entries \
             l_cev___remaining_entries
    
    split_str l_cev___existing_entries "$2" "$3"
    
    l_cev___remaining_entries=()
    if is_var_defined "$5" ; then
        if [[ "$5" != "l_cev___removed_entries" ]] ; then
            local -n l_cev___removed_entries="$5"
        fi
        l_cev___removed_entries=()
        for l_cev___existing_entry in "${l_cev___existing_entries[@]}" ; do
            if "$4" "$l_cev___existing_entry" ; then
                l_cev___removed_entries+=("$l_cev___existing_entry")
            else
                l_cev___remaining_entries+=("$l_cev___existing_entry")
            fi
        done
    else
        for l_cev___existing_entry in "${l_cev___existing_entries[@]}" ; do
            if ! "$4" "$l_cev___existing_entry" ; then
                l_cev___remaining_entries+=("$l_cev___existing_entry")
            fi
        done
    fi
    
    concat_str_from_array "$1" l_cev___remaining_entries "$3"
}

# uses from calling context:
# l_cev___prev_path
function __cev___is_luarocks_main_dir___or___lua_main_dir() {
    [[ ( "$1" == "$luarocks_maindir"* ) \
    || ( "$1" == "$lua_maindir"*      ) ]]
}

# uses from calling context:
# l_cev___prev_path
function __cev___is_luarocks_main_dir_win___or___lua_main_dir_win() {
    [[ ( "$1" == "$luarocks_maindir_win"* ) \
    || ( "$1" == "$lua_maindir_win"*      ) ]]
}

# ========== Set Environment Variables ====================

#  $1  - ret str var name
#  $2  - options array name:
#           ["order"] - "append" or "prepend"
# [$3] - indexed array varname for the removed entries
# [$4] - indexed array varname for the additional entries
function cev___calc_env_PATHEXT() {
    cfg___assert_vars_are_set pathext_additional
    
    if [[ "$2" != "l_cev___opts" ]] ; then # no circular nameref
        local -n l_cev___opts="$2"
    fi
    
    # PATHEXT uses ';' (semicolon) as entry sep.
    # PATHEXT is only needed on Windows.
    
    # should be executed in the from path style
    __cev___cleared_PATHEXT "$1" "$3"
    
    # should be executed in the return path style
    __cev___exec_opt___order "$1" \
        "$1" pathext_additional ";" "$4"
}

#  $1 - ret str var name
#  $2 - options array name:
#                 ["from"] - "Windows" or "MSYS2"
#                ["order"] - "append" or "prepend"
#           ["path_style"] - "win" or "unix"
# [$3] - additional env var value
#        default: $lua_man_dir
# [$4] - indexed array varname for the removed entries
# [$5] - indexed array varname for the additional entries
function cev___calc_env_MANPATH() {
    cfg___assert_vars_are_set lua_man_dir
    
    if [[ "$2" != "l_cev___opts" ]] ; then # no circular nameref
        local -n l_cev___opts="$2"
    fi
    
    local l_cev___path_additional="${3:-$lua_man_dir}"
    
    case "${l_cev___opts["from"]}" in
        MSYS2)
            # must be executed in the from path style
            __cev___cleared_env_var___default___unix "$1" \
                "$MANPATH" "$4"
            ;;
        Windows)
            # must be executed in the from path style
            __cev___cleared_env_var___default___win "$1" \
                "$ORIGINAL_MANPATH" "$4"
            ;;
        *)
            __cev___unknown_opt___from
            ;;
    esac
    
    case "${l_cev___opts["path_style"]}" in
        unix)
            local l_cev___ret_sep=":"
            if [[ "${l_cev___opts["from"]}" == "Windows" ]] ; then
                # existing entries
                if [[ "$1" != "l_cev___ret_paths" ]] ; then
                    local -n l_cev___ret_paths="$1"
                fi
                convert_PATH_like_str_to_unix "$1" "$l_cev___ret_paths" ";" ";"
                # removed entries
                if is_var_defined "$4" ; then
                    convert_paths_to_unix "$4" "$4"
                fi
            fi
            ;;
        win)
            local l_cev___ret_sep=";"
            # to add str
            convert_PATH_like_str_to_win l_cev___path_additional "$l_cev___path_additional"
            if [[ "${l_cev___opts["from"]}" == "MSYS2" ]] ; then
                # existing entries
                if [[ "$1" != "l_cev___ret_paths" ]] ; then
                    local -n l_cev___ret_paths="$1"
                fi
                convert_PATH_like_str_to_win "$1" "$l_cev___ret_paths" ";" ";"
                # removed entries
                if is_var_defined "$4" ; then
                    convert_paths_to_win "$4" "$4"
                fi
            fi
            ;;
        *)
            __cev___unknown_opt___ret_style
            ;;
    esac
    
    # must be executed in the return path style
    __cev___exec_opt___order "$1" \
        "$1" l_cev___path_additional "$l_cev___ret_sep" "$5"
}

#  $1  - ret str var name
#  $2  - options array name:
#           ["path_style"] - "win" or "unix"
#                ["order"] - "append" or "prepend"
# [$3] - additional env var value
#        default:       $lua_path_additional
#                 resp. $lua_cpath_additional
# [$4] - indexed array varname for the removed entries
# [$5] - indexed array varname for the additional entries
function cev___calc_env_LUA_PATH() {
    __cev___calc_env_LUA_PATH___LUA_CPATH "$1" \
        "$2" \
        LUA_PATH "${3:-$lua_path_additional}" \
        "$4" "$5"
}
function cev___calc_env_LUA_CPATH() {
    __cev___calc_env_LUA_PATH___LUA_CPATH "$1" \
        "$2" \
        LUA_CPATH "${3:-$lua_cpath_additional}" \
        "$4" "$5"
}

#  $1  - ret str var name
#  $2  - options array name:
#           ["path_style"] - "win" or "unix"
#                ["order"] - "append" or "prepend"
#           LUA_PATH and LUA_CPATH can only be obtained from Windows
#  $3  - "LUA_PATH"            or "LUA_CPATH"
#  $4  - expansion of lua_path_additional or lua_cpath_additional
#        must be in Windows style
# [$5] - indexed array varname for the removed entries
# [$6] - indexed array varname for the additional entries
function __cev___calc_env_LUA_PATH___LUA_CPATH() {
    if [[ "$2" != "l_cev___opts" ]] ; then # no circular nameref
        local -n l_cev___opts="$2"
    fi
    
    # "lua_path_additional" and "lua_cpath_additional" are yet in Windows style
    # (So the additional entries)
    # LUA_PATH and LUA_CPATH are yet in Windows style
    # (So the removed entries)
    # LUA_PATH and LUA_CPATH use ';' (semicolon) as entry sep on Unix and Windows.
    
    local l_cev___env_var_name
    cev___determinate_versioned_env_var_name l_cev___env_var_name "$3"
    
    if is_var_defined "$l_cev___env_var_name" ; then
        local -n l_cev___input_env_var="$l_cev___env_var_name"
    else
        local -n l_cev___input_env_var="$3"
    fi
    
    trace "\${!l_cev___input_env_var} == ${!l_cev___input_env_var}"
    
    # must be executed in the from path style
    __cev___cleared_env_var___default___win "$1" \
        "$l_cev___input_env_var" "$5"
    
    case "${l_cev___opts["path_style"]}" in
        "win")
            local l_cev___path_additional="$4"
            ;;
        "unix")
            # existing entries
            if [[ "$1" != "l_cev___ret_paths" ]] ; then
                local -n l_cev___ret_paths="$1"
            fi
            convert_PATH_like_str_to_unix "$1" "$l_cev___ret_paths" ";" ";"
            # to add str
            local l_cev___path_additional
            convert_PATH_like_str_to_unix l_cev___path_additional "$4" ";" ";"
            # removed entries
            if is_var_defined "$5" ; then
                convert_paths_to_unix "$5" "$5"
            fi
            ;;
        *)
            __cev___unknown_opt___ret_style
            ;;
    esac
    
    # must be executed in the return path style
    __cev___exec_opt___order "$1" \
        "$1" l_cev___path_additional ";" "$6"
}

#  $1  - ret str var name
#  $2  - options array name:
#           ["path_style"] - "win" or "unix"
#                 ["from"] - "Windows" or "MSYS2"
#                ["order"] - "append" or "prepend"
# [$3] - additional env var value
#        default: $path_additional
# [$4] - indexed array varname for the removed entries
# [$5] - indexed array varname for the additional entries
function cev___calc_env_PATH() {
   cfg___assert_vars_are_set path_additional
    
    if [[ "$2" != "l_cev___opts" ]] ; then # no circular nameref
        local -n l_cev___opts="$2"
    fi
    
    local l_cev___path_additional="${3:-$path_additional}"
    
    # path_additional is yet in Unix style
    # EXCEPT if the optional argument is set by
    # cev___append_to_IL___instrs_to_set_this_env_as_default_env()
    # 
    # (So the additional entries)
    # PATH is yet in Unix style
    # ORIGINAL_PATH is yet in Unix style
    # (So the removed entries)
    
    case "${l_cev___opts["from"]}" in
        MSYS2)
            # must be executed in the from path style
            __cev___cleared_env_var___default___unix "$1" \
                "$PATH" "$4"
            ;;
        Windows)
            # must be executed in the from path style
            __cev___cleared_env_var___default___unix "$1" \
                "$ORIGINAL_PATH" "$4"
            ;;
        *)
            __cev___unknown_opt___from
            ;;
    esac
    
    case "${l_cev___opts["path_style"]}" in
        unix)
            local l_cev___ret_sep=":"
            ;;
        win)
            local l_cev___ret_sep=";"
            # existing entries
            if [[ "$1" != "l_cev___ret_paths" ]] ; then
                local -n l_cev___ret_paths="$1"
            fi
            convert_PATH_like_str_to_win "$1" "$l_cev___ret_paths"
            # to add entries
            convert_PATH_like_str_to_win l_cev___path_additional "$l_cev___path_additional"
            # removed entries
            if is_var_defined "$4" ; then
                convert_paths_to_win "$4" "$4"
            fi
            ;;
        *)
            __cev___unknown_opt___ret_style
            ;;
    esac
    
    # must be executed in the return path style
    __cev___exec_opt___order "$1" \
        "$1" l_cev___path_additional "$l_cev___ret_sep" "$5"
}

# The arguments should already by in the return path style
# 
# arguments:
#  $1  - ret str var name
#  $2  - existing str var name
#  $3  - additional str var name
#  $4  - entry sep
# [$5] - indexed array var name for the new entries
# 
# uses from calling context:
# l_cev___opts
function __cev___exec_opt___order() {
    local -n l_cev___ret_str="$1" \
             l_cev___existing_str="$2" \
             l_cev___additional_str="$3"
    
    case "${l_cev___opts["order"]}" in
        prepend)
            l_cev___ret_str="\
${l_cev___additional_str}\
${l_cev___existing_str:+"${4}${l_cev___existing_str}"}"
            ;;
        append) 
            l_cev___ret_str="\
${l_cev___existing_str:+"${l_cev___existing_str}${4}"}\
${l_cev___additional_str}"
            ;;
        *)
            __cev___unknown_opt___order
            ;;
    esac
    
    # additional entries
    if is_var_defined "$5" ; then
        split_str "$5" "$l_cev___additional_str" "$4"
    fi
}

# uses from calling context:
# l_cev___opts
function __cev___unknown_opt___from() {
    local l_cev___opt_bash_word
    bash_word_from_str l_cev___opt_bash_word "${l_cev___opts["from"]}"
    internal_errf "unknown from option %s" "$l_cev___opt_bash_word"
}
function __cev___unknown_opt___ret_style() {
    local l_cev___opt_bash_word
    bash_word_from_str l_cev___opt_bash_word "${l_cev___opts["path_style"]}"
    internal_errf "unknown path return style %s" "$l_cev___opt_bash_word"
}
function __cev___unknown_opt___order() {
    local l_cev___opt_bash_word
    bash_word_from_str l_cev___opt_bash_word "${l_cev___opts["order"]}"
    internal_errf "unknown order option %s" "$l_cev___opt_bash_word"
}

# ========== Set this Environment as the Default Environment ====================

# $1 - IL_n_n
function cev___append_to_IL___instrs_to_set_this_env_as_default_env() {
    cfg___define_general_config
    cfg___define_paths_env_vars
    debug_config_vars
    
    local l_cev___lua_path_additional \
          l_cev___lua_cpath_additional \
          l_cev___path_additional \
          l_cev___manpath_additional \
          l_cev___LUA_PATH \
          l_cev___LUA_CPATH \
          l_cev___PATH \
          l_cev___PATHEXT \
          l_cev___MANPATH \
          l_cev___LUA_PATH_versioned_var_name \
          l_cev___LUA_CPATH_versioned_var_name
    
    abbreviate_win_PATH_like_str l_cev___lua_path_additional  "$lua_path_additional"
    abbreviate_win_PATH_like_str l_cev___lua_cpath_additional "$lua_cpath_additional"
    convert_PATH_like_str_to_win l_cev___path_additional "$path_additional"
    abbreviate_win_PATH_like_str l_cev___path_additional "$l_cev___path_additional"
    convert_path_to_win l_cev___manpath_additional "$lua_man_dir"
    abbreviate_win_path l_cev___manpath_additional "$l_cev___manpath_additional"
    
    declare -g -a m_cev___LUA_PATH_removed \
                  m_cev___LUA_PATH_additional \
                  m_cev___LUA_CPATH_removed \
                  m_cev___LUA_CPATH_additional \
                  m_cev___PATH_removed \
                  m_cev___PATH_additional \
                  m_cev___PATHEXT_removed \
                  m_cev___PATHEXT_additional \
                  m_cev___MANPATH_removed \
                  m_cev___MANPATH_additional
    
    # # test values:
    # unset LUA_PATH  LUA_PATH_5_3  LUA_PATH_5_4 \
    #       LUA_CPATH LUA_CPATH_5_3 LUA_CPATH_5_4 \
    #       MANPATH ORIGINAL_MANPATH
    # local      LUA_PATH='C:\Program Files\Lua\generic\?.lua;C:\Program Files\Lua\generic\init.lua;C:\extra_lua_path\?.lua;C:\extra_lua_path\?\init.lua'
    # local  LUA_PATH_5_3='C:\Program Files\Lua\generic\?.lua;C:\Program Files\Lua\generic\init.lua;C:\extra_lua_path_5_3\?.lua;C:\extra_lua_path_5_3\?\init.lua'
    # local  LUA_PATH_5_4='C:\Program Files\Lua\generic\?.lua;C:\Program Files\Lua\generic\init.lua;C:\extra_lua_path_5_4\?.lua;C:\extra_lua_path_5_4\?\init.lua'
    # local     LUA_CPATH='C:\Program Files\Lua\generic\?.dll;C:\extra_lua_cpath\?.dll'
    # local LUA_CPATH_5_3='C:\Program Files\Lua\generic\?.dll;C:\extra_lua_cpath_5_3\?.dll'
    # local LUA_CPATH_5_4='C:\Program Files\Lua\generic\?.dll;C:\extra_lua_cpath_5_4\?.dll'
    # local MANPATH="/c/Program Files/Lua/generic_lua_man___MANPATH"
    # local ORIGINAL_MANPATH='C:\mingw\mingw_man;C:\msys2\msys2_man;C:\Program Files\Lua\generic_lua_man___ORIGINAL_MANPATH'
    
    local -A l_cev___opts=( \
        ["from"]="Windows" \
        ["path_style"]="win" \
        ["order"]="append" \
    )
    
    cev___calc_env_LUA_PATH          l_cev___LUA_PATH  l_cev___opts \
           "$l_cev___lua_path_additional" \
           m_cev___LUA_PATH_removed  m_cev___LUA_PATH_additional
    
    cev___calc_env_LUA_CPATH         l_cev___LUA_CPATH l_cev___opts \
           "$l_cev___lua_cpath_additional" \
           m_cev___LUA_CPATH_removed m_cev___LUA_CPATH_additional
    
    cev___calc_env_PATH              l_cev___PATH      l_cev___opts \
           "$l_cev___path_additional" \
           m_cev___PATH_removed      m_cev___PATH_additional
    
    cev___calc_env_PATHEXT           l_cev___PATHEXT   l_cev___opts \
           m_cev___PATHEXT_removed   m_cev___PATHEXT_additional
    
    cev___calc_env_MANPATH           l_cev___MANPATH   l_cev___opts \
           "$l_cev___manpath_additional" \
           m_cev___MANPATH_removed   m_cev___MANPATH_additional
    
    # if [[ "${l_cev___opts["path_style"]}" == "win" ]] ; then
    #     local l_cev___trace_sep=";"
    # else
    #     local l_cev___trace_sep=":"
    # fi
    # trace_paths_var l_cev___LUA_PATH  ";" # fixed to semicolon
    # trace_indexed_array m_cev___LUA_PATH_removed
    # trace_indexed_array m_cev___LUA_PATH_additional
    # trace_paths_var l_cev___LUA_CPATH ";" # fixed to semicolon
    # trace_indexed_array m_cev___LUA_CPATH_removed
    # trace_indexed_array m_cev___LUA_CPATH_additional
    # trace_paths_var l_cev___PATH      "$l_cev___trace_sep"
    # trace_indexed_array m_cev___PATH_removed
    # trace_indexed_array m_cev___PATH_additional
    # trace_paths_var l_cev___PATHEXT   ";" # fixed to semicolon
    # trace_indexed_array m_cev___PATHEXT_removed
    # trace_indexed_array m_cev___PATHEXT_additional
    # trace_paths_var l_cev___MANPATH   "$l_cev___trace_sep"
    # trace_indexed_array m_cev___MANPATH_removed
    # trace_indexed_array m_cev___MANPATH_additional
    # exit 0
    
    cev___determinate_versioned_env_var_name l_cev___LUA_PATH_versioned_var_name  LUA_PATH
    cev___determinate_versioned_env_var_name l_cev___LUA_CPATH_versioned_var_name LUA_CPATH
    
    IL___append___delete "$1" LUA_PATH
    
    IL___append___delete "$1" LUA_CPATH
    
    IL___append___set "$1" \
        "$l_cev___LUA_PATH_versioned_var_name" \
        "$l_cev___LUA_PATH" \
        "" \
        m_cev___LUA_PATH_removed \
        m_cev___LUA_PATH_additional
    
    IL___append___set "$1" \
        "$l_cev___LUA_CPATH_versioned_var_name" \
        "$l_cev___LUA_CPATH" \
        "" \
        m_cev___LUA_CPATH_removed \
        m_cev___LUA_CPATH_additional
    
    IL___append___set "$1" \
        PATH "$l_cev___PATH" \
        "" \
        m_cev___PATH_removed \
        m_cev___PATH_additional
    
    IL___append___set "$1" \
        PATHEXT "$l_cev___PATHEXT" \
        "" \
        m_cev___PATHEXT_removed \
        m_cev___PATHEXT_additional
    
    IL___append___set "$1" \
        MANPATH "$l_cev___MANPATH" "\
If you want be able to view the correct man page for Lua %s outside a MSYS2 environment,
then you can also set the environment variable MANPATH :" \
        m_cev___MANPATH_removed \
        m_cev___MANPATH_additional
}
