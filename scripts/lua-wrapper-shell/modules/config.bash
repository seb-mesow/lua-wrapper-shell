# ===== Bookkeeping of Config Variables ====================

# TODO make config vars read-only

declare -g -A m_cfg___vars_type
# key = varname, value = type of variable
# type of variable | meaning
# -----------------|--------
# s                | string
# i                | integer
# a                | indexed array
# A                | associative array
# .+               | path-like with .+ == <sep>

declare -g -a m_cfg___vars_order \
              m_cfg___important_vars # for __cfg___print_vars_short

# $1 - config var name
function __cfg___is_var_defined() {
    [[ -v m_cfg___vars_type["$1"] ]]
}

# $1 - var name
# $2 - str
function declare_config_str_var() {
    if (( "$#" < 2 )) ; then
        internal_errf "No value provided for config str var %s to declare" "$1"
    fi
    declare -g -r "$1"="$2"
    m_cfg___vars_type["$1"]="s"
    m_cfg___vars_order+=("$1")
}

# $1 - var name
# $2 - str
function declare_config_str_var_important() {
    declare_config_str_var "$@"
    m_cfg___important_vars+=("$1")
}

# Do not forget to use cfg___close_var() !
# 
# $1 - var name
# $2 - sep
# $3 - PATH-like str
function declare_config_paths_var() {
    if [[ "$2" == "" ]] ; then
        internal_err "seperator is empty"
    fi
    if [[ "$2" =~ ^[siaA]$ ]] ; then
        internal_err <<__end__
seperator must not be "s", "i", "a", "A"
seperator == "$2"
__end__
    fi
    
    if (( "$#" < 3 )) ; then
        internal_errf "No value provided for config PATH-like str var %s to declare" "$1"
    fi
    
    declare -g "$1"="$3"
    m_cfg___vars_type["$1"]="$2"
    m_cfg___vars_order+=("$1")
}

# $1 - var name
function cfg___close_var() {
    if ! __cfg___is_var_defined "$1" ; then
        internal_errf "config var %s to close is undefined." "$1"
    fi
    readonly "$1"
}

# $1 - var name
# $2 - integer value
function declare_config_int_var() {
    if (( "$#" < 3 )) ; then
        internal_errf "No value provided for confgi int var %s to declare" "$1"
    fi
    
    declare -g -r -i "$1"="$2"
    m_cfg___vars_type["$1"]="i"
    m_cfg___vars_order+=("$1")
}

# # Do not forget to use cfg___close_var() !
# # 
# # $1 - var name
# function declare_config_indexed_array() {
#     declare -g -a "$1"
#     m_cfg___vars_type["$1"]="a"
#     m_cfg___vars_order+=("$1")
# }

# Do not forget to use cfg___close_var() !
# 
# $1 - var name
function declare_config_assoc_array() {
    declare -g -A "$1"
    m_cfg___vars_type["$1"]="A"
    m_cfg___vars_order+=("$1")
}

function print_config_vars() {
    if (( show_config_long )) ; then
        __cfg___print_vars_long
    else
        __cfg___print_vars_short
    fi
}

function __cfg___print_vars_long() {
    local l_cfg___var_name
    for l_cfg___var_name in "${m_cfg___vars_order[@]}" ; do
        case "${m_cfg___vars_type["$l_cfg___var_name"]}" in
            s)  print_str_var       "$l_cfg___var_name" ;;
            i)  print_int_var       "$l_cfg___var_name" ;;
            a)  print_indexed_array "$l_cfg___var_name" ;;
            A)  print_assoc_array   "$l_cfg___var_name" ;;
            '') internal_err "config var $l_cfg___var_name has an empty type"                   ;;
            *)  print_paths_var "$l_cfg___var_name" "${m_cfg___vars_type["$l_cfg___var_name"]}" ;;
        esac
    done
}

function __cfg___print_vars_short() {
    local l_cfg___var_name
    for l_cfg___var_name in "${m_cfg___vars_order[@]}" ; do
        case "${m_cfg___vars_type["$l_cfg___var_name"]}" in
            s)  print_str_var_custom abbr_path_from_long_path___no_self_substitution \
                        "$l_cfg___var_name" ;;
            i)  print_int_var "$l_cfg___var_name" ;;
            a)  print_indexed_array_custom abbr_path_from_long_path "$l_cfg___var_name" ;;
            A)  print_assoc_array_custom   abbr_path_from_long_path "$l_cfg___var_name" ;;
            '') internal_errf "config var %s has an empty type"     "$l_cfg___var_name" ;;
            *)  print_paths_var_custom abbr_path_from_long_path "$l_cfg___var_name" \
                        "${m_cfg___vars_type["$l_cfg___var_name"]}" ;;
        esac
    done
}

# replaces the longest prefix equal to an important str config var
# by a parameter expansion of the important str config var
# Note: It is assumed, that the value of all important config vars is distinct.
# 
# arguments:
# $1 - var name for formatted str val
# $2 - input str val
function abbr_path_from_long_path() {
    local l_cfg___abbr_path_from_long_path___regex_suffix=''
    __cfg___abbr_path_from_long_path "$@"
}
function abbr_path_from_long_path___no_self_substitution() {
    local l_cfg___abbr_path_from_long_path___regex_suffix='.'
    __cfg___abbr_path_from_long_path "$@"
}
# $1 - var name for formatted str val
# $2 - input str val
function __cfg___abbr_path_from_long_path() {
    local l_cfg___temp_dirpath \
          l_cfg___most_substituting_prefix \
          l_cfg___important_varname
    
    local -i l_cfg___substituted_chars_max_cnt=0 \
             l_cfg___substituted_chars_cnt
    
    # test on a prefix equal to an tempdir
    for l_cfg___temp_dirpath in "${g_aux___temp_dirs[@]}" ; do
        if [[ "$2" =~ ^"$l_cfg___temp_dirpath"$l_cfg___abbr_path_from_long_path___regex_suffix ]]
        then
            l_cfg___substituted_chars_cnt="${#l_cfg___temp_dirpath}"
            if (( l_cfg___substituted_chars_cnt > l_cfg___substituted_chars_max_cnt )) ; then
                l_cfg___substituted_chars_max_cnt=l_cfg___substituted_chars_cnt
                l_cfg___most_substituting_prefix='$(temp_dirpath)'
            fi
        fi
    done
    
    # test on a prefix equal to an expanded important cfg var
    for l_cfg___important_varname in "${m_cfg___important_vars[@]}" ; do
        local -n l_cfg___important_var="$l_cfg___important_varname"
        if [[ "$2" =~ ^"$l_cfg___important_var"$l_cfg___abbr_path_from_long_path___regex_suffix ]]
        then
            l_cfg___substituted_chars_cnt="${#l_cfg___important_var}"
            if (( l_cfg___substituted_chars_cnt > l_cfg___substituted_chars_max_cnt )) ; then
                l_cfg___substituted_chars_max_cnt=l_cfg___substituted_chars_cnt
                l_cfg___most_substituting_prefix="\${$l_cfg___important_varname}"
            fi
        fi
    done
    
    if [[ "$1" != "l_cfg___ret_str" ]]; then
        local -n l_cfg___ret_str="$1"
    fi
    if [[ -v l_cfg___most_substituting_prefix ]] ; then
        l_cfg___ret_str="${l_cfg___most_substituting_prefix}${2:l_cfg___substituted_chars_max_cnt}"
    else
        l_cfg___ret_str="$2"
    fi
}

# declares log_config_vars(), debug_config_vars(), trace_config_vars()
declare_debug_funcs_from_print_func print_config_vars



# ===== Loading of "static" Config Variables from the Config File ====================

# uses main_config_filepath from calling context
function __cfg___write_default_config_file() {
    local l_cfg___lua_maindir_win \
          l_cfg___luarocks_maindir_win \
          l_cfg___downloads_dir_win
    config_word_from_str l_cfg___lua_maindir_win      "${PROGRAMFILES}\\Lua"
    config_word_from_str l_cfg___luarocks_maindir_win "${PROGRAMFILES}\\LuaRocks"
    config_word_from_str l_cfg___downloads_dir_win    "${USERPROFILE}\\Downloads"
    
    write_to_file "$main_config_filepath" "<default main config file>" <<__end__
# This is the main config file for all environments of the Lua wrapper shell.

# This config file must be stored with one linefeed (LF, \n, Unix-style) as line end.
# This config file must contain only simple varname-value assignments.
# One assignment per line.
# Similar to bash an assignment can have one of the following forms
# varname='value', varname="value" , varname=$'value', varname=value

# You can continue a line with a backslash at the end.

# Paths of directories should NOT end with the appropriate directory seperator \ or // .

# directory for all Lua installations
lua_maindir=${l_cfg___lua_maindir_win}

# directory for all LuaRocks installations
luarocks_maindir=${l_cfg___luarocks_maindir_win}

# In the following 'D' stands for one or more decimal digits 0-9,
# which compose a version number.

# default directory with the lua-D.D.D.tar.gz with the Makefile to compile Lua
lua_sources_dir=${l_cfg___downloads_dir_win}

# default directory with the luarocks-D.D.D-win32.zip with the install.bat
luarocks_install_sources_dir=${l_cfg___downloads_dir_win}
__end__
}

function __cfg___load_main_config_file() {
    exec_module ext_cmds
    exec_module config_read

    if [[ ! -e "$main_config_filepath" ]] ; then
        __cfg___write_default_config_file
    fi
    
    if [[ ! -f "$main_config_filepath" ]] ; then
        user_errf "config file\n%s\nis not a regular file" "$main_config_filepath"
    fi
    if [[ ! -r "$main_config_filepath" ]] ; then
        user_errf "config file\n%s\nis not readable" "$main_config_filepath"
    fi
    
    local l_cfg___config_filecontents
    read_file_to_str_var l_cfg___config_filecontents "$main_config_filepath"
    
    local -A l_cfg___main_dirpaths_config
    assoc_array_from_config_str l_cfg___main_dirpaths_config "$l_cfg___config_filecontents"
    
    # log_assoc_array_quoted l_cfg___main_dirpaths_config
    
    __cfg___declare_path_var_from_config_file___unix lua_maindir                  "lua_maindir"
    __cfg___declare_path_var_from_config_file___win  lua_maindir_win              "lua_maindir"
    __cfg___declare_path_var_from_config_file___unix luarocks_maindir             "luarocks_maindir"
    __cfg___declare_path_var_from_config_file___win  luarocks_maindir_win         "luarocks_maindir"
    __cfg___declare_path_var_from_config_file___unix lua_sources_dir              "lua_sources_dir"
    __cfg___declare_path_var_from_config_file___unix luarocks_install_sources_dir "luarocks_install_sources_dir"
}

# declares a config variable holding a Unix-style path
# 
# arguments:
# $1 - var name
# $2 - var name in config file
# 
# uses from calling context:
# l_cfg___main_dirpaths_config
function __cfg___declare_path_var_from_config_file___unix() {
    __cfg___assert_config_file_defines_var "$2"
    local l_cfg___path
    convert_path_to_unix l_cfg___path "${l_cfg___main_dirpaths_config["$2"]}"
    declare_config_str_var "$1" "$l_cfg___path"
}

# declares a config variable holding a Windows-style path
# 
# arguments:
# $1 - var name
# $2 - var name in config file
# 
# uses from calling context:
# l_cfg___main_dirpaths_config
function __cfg___declare_path_var_from_config_file___win() {
    __cfg___assert_config_file_defines_var "$2"
    local l_cfg___path
    convert_path_to_win l_cfg___path "${l_cfg___main_dirpaths_config["$2"]}"
    declare_config_str_var "$1" "$l_cfg___path"
}

# $1 - var name in config file
# 
# uses from calling context:
# l_cfg___main_dirpaths_config
function __cfg___assert_config_file_defines_var() {
    if [[ ! -v l_cfg___main_dirpaths_config["$1"] ]] ; then
        local l_cfg___bash_word
        bash_word_from_str l_cfg___bash_word "$1"
        user_errf "config file\n%s\nmisses value for key\n%s" \
                "$main_config_filepath" "$l_cfg___bash_word"
    fi
}


# ========== Config Auxillary ====================

function cfg___assert_vars_are_set() {
    local l_cfg___var_name
    for l_cfg___var_name in "$@" ; do
        if [[ ! -v "$l_cfg___var_name" ]] ; then
            internal_err "config variable ${l_cfg___var_name} is not pre-set."
        fi
        if [[ -z "$l_cfg___var_name" ]] ; then
            internal_err "config variable ${l_cfg___var_name} is pre-set, but empty."
        fi
    done
}

# ===== Definition of "dynamic" Config Variables ====================

# 0. __main___init()
#       always essential variables
# 
# 1. cfg___define_msystem()
#       obtain MSYSTEM for almost all actions
# 
# 2. cfg___define_env_IDs()
#       define lua_version and msystem and related config variables
# 
# 3. cfg___define_wrapper_excl_env_config()
#       define variables which point to things
#       exclusively managed by the Lua Wrapper Shell
# 
# 4. cfg___define_general_config()
#       general variables for almost all actions
#       also defines variables which point to things,
#       managed by other programs (esp. LuaRocks)
#       loads the config file !
# 
# 5. cfg___define_paths_env_vars()
#       obtain additions to PATH-like env vars

function cfg___define_msystem() {
    # This function can indirectly be called multiple times
    # from the multiple register_*_file_to_show() functions.
    if __cfg___is_var_defined msystem ; then
        return
    fi
    
    local l_cfg___msystem
    strip_surrounding_whitespace l_cfg___msystem "${MSYSTEM@L}" # convert to lowercase
    declare_config_str_var msystem "$l_cfg___msystem"
    
    declare_config_str_var msys2_shell "MSYS2 / ${MSYSTEM}"
}

function cfg___define_env_IDs() {
    # This function can indirectly be called multiple times
    # from the multiple register_*_file_to_show() functions.
    if __cfg___is_var_defined lua_version ; then
        return
    fi
    
    main___assert_environment_defined
    
    cfg___define_msystem
    
    cfg___assert_vars_are_set "lua_version"
    
    declare_config_str_var lua_version "$lua_version"
}

function cfg___define_wrapper_excl_env_config() {
    # This function can indirectly be called multiple times
    # from the multiple register_*_file_to_show() functions.
    if __cfg___is_var_defined wrapper_envdir ; then
        return
    fi
    
    cfg___define_env_IDs
    
    cfg___assert_vars_are_set \
            "lua_version" "msystem" \
            "wrapper_name" "wrapper_dir" "wrapper_modules_dir"
    
    # TODO declare less variables as config variables
    
    declare_config_str_var           wrapper_name        "$wrapper_name"
    declare_config_str_var_important wrapper_dir         "$wrapper_dir"
    declare_config_str_var           wrapper_modules_dir "$wrapper_modules_dir"
    
    declare -g m_cfg___env_id_short="${lua_version}-${msystem}"
    declare -g m_cfg___env_id_long="lua-${m_cfg___env_id_short}"
    declare -g m_cfg___env_subdir_short="/${m_cfg___env_id_short}" \
               m_cfg___env_subdir_short_win="\\${m_cfg___env_id_short}" \
               m_cfg___env_subdir_long="/Lua ${m_cfg___env_id_short}" \
               m_cfg___env_subdir_long_win="\\Lua ${m_cfg___env_id_short}"
    
    declare_config_str_var wrapper_name_for_filenames "${wrapper_name}___${m_cfg___env_id_short}"
    declare_config_str_var temp_dirpath "${TEMP}/${wrapper_name_for_filenames}"
    
    declare_config_str_var_important wrapper_envdir "${wrapper_dir}${m_cfg___env_subdir_long}"
    
    # if [[ ! -d "$wrapper_envdir" ]] ; then
    #     exec_module ext_cmds
    #     mkdir -p "$wrapper_envdir"
    # fi
    
    # ----- Config Files ----------
    declare_config_str_var main_config_filepath "${wrapper_dir}/config.conf"
    declare_config_str_var env_bashrc_filepath  "${wrapper_envdir}/.bashrc"
    declare_config_str_var path_env_vars_config_filepath "${wrapper_envdir}/path_env_vars.conf"
}

function cfg___define_general_config() {
    # This function can indirectly be called multiple times
    # from the multiple register_*_file_to_show() functions.
    if __cfg___is_var_defined lua_envdir ; then
        return
    fi
    
    cfg___define_wrapper_excl_env_config
   
    # ----- Load Main Config File ----------
    __cfg___load_main_config_file
        
    # ----- Lua ----------
    declare_config_str_var_important lua_envdir     "${lua_maindir}${m_cfg___env_subdir_short}"
    declare_config_str_var_important lua_envdir_win "${lua_maindir_win}${m_cfg___env_subdir_short_win}"
    
    declare_config_str_var lua_bin_dir      "${lua_envdir}/bin"
    # declare_config_str_var lua_bin_dir_win "${lua_envdir_win}\\bin"
    declare_config_str_var lua_man_dir      "${lua_envdir}/man"
    declare_config_str_var lua_exe "${lua_bin_dir}/lua.exe"
    
    # ----- LuaRocks ----------
    declare_config_str_var_important luarocks_envdir     "${luarocks_maindir}${m_cfg___env_subdir_long}"
    declare_config_str_var_important luarocks_envdir_win "${luarocks_maindir_win}${m_cfg___env_subdir_long_win}"
    
    declare_config_str_var luarocks_lua "${luarocks_envdir}/luarocks.lua"
}

function cfg___define_paths_env_vars() {
    if __cfg___is_var_defined lua_path_additional ; then
        return
    fi
    
    cfg___define_wrapper_excl_env_config
    
    if [[ ! -f "$path_env_vars_config_filepath" ]] ; then
        local l_cfg___cmdline___build_install_lua \
              l_cfg___cmdline___install_luarocks
        cmd_line_from_args l_cfg___cmdline___build_install_lua \
                "$0" "$lua_version" -il
        cmd_line_from_args l_cfg___cmdline___install_luarocks \
                "$0" "$lua_version" -ilr
        user_err <<__end__
generated PATH environment variables config file
${path_env_vars_config_filepath}
does not exist

You must first install Lua and then LuaRocks.
This config file is generated while installing LuaRocks.
Therefore execute the following with root privileges (#):
1. # ${l_cfg___cmdline___build_install_lua}
2. # ${l_cfg___cmdline___install_luarocks}
__end__
    fi
    
    exec_module ext_cmds
    
    local l_cfg___path_env_vars_config_file_contents \
          l_cfg___subscript \
          l_cfg___key \
          l_cfg___val \
          l_cfg___env_varname \
          l_cfg___config_var_name \
          l_cfg___paths_sep
    
    read_file_to_str_var \
            l_cfg___path_env_vars_config_file_contents \
            "$path_env_vars_config_filepath"
    
    exec_module config_read
    
    local -a l_cfg___gen_cfg_keys \
             l_cfg___gen_cfg_vals
    two_arrays_from_config_str \
            l_cfg___gen_cfg_keys l_cfg___gen_cfg_vals \
            "$l_cfg___path_env_vars_config_file_contents"
    
    debug_two_arrays l_cfg___gen_cfg_keys l_cfg___gen_cfg_vals
    
    for l_cfg___subscript in "${!l_cfg___gen_cfg_keys[@]}" ; do
        l_cfg___key="${l_cfg___gen_cfg_keys["$l_cfg___subscript"]}"
        l_cfg___val="${l_cfg___gen_cfg_vals["$l_cfg___subscript"]}"
        # log_str_var l_cfg___key
        # log_str_var l_cfg___val
        
        if [[ "$l_cfg___key" =~ 'user rocktree' ]] ; then
            continue
        fi
        
        # At first we do not want let an ordinary user to install LuaRocks rocks,
        # in his*her home directory.
        
        if [[ ! "$l_cfg___key" =~ ^([^.]+)\.([^.]+)$ ]] ; then
            bash_word_from_str l_cfg___key "$l_cfg___key"
            internal_errf "malformed key in\n%s\nl_cfg___key == %s" \
                "$path_env_vars_config_filepath" \
                "$l_cfg___key"
        fi
        
        l_cfg___env_varname="${BASH_REMATCH[2]}"
        # parameter@L expands to lowercase
        l_cfg___config_var_name="${l_cfg___env_varname@L}_additional"
        
        # compare with __ilr___parse_suggested_paths()
        if [[ ( "$l_cfg___env_varname" =~ "PATH".*"EXT" ) \
           || ( "$l_cfg___env_varname" =~ "LUA".*"PATH" ) ]]
        then
            l_cfg___paths_sep=';'
        else
            l_cfg___paths_sep=':'
        fi
        
        if [[ -v "$l_cfg___config_var_name" ]] ; then
            local -n l_cfg___config_var="$l_cfg___config_var_name"
            l_cfg___config_var=\
"${l_cfg___config_var:+"${l_cfg___config_var}${l_cfg___paths_sep}"}${l_cfg___val}"
        else
                declare_config_paths_var "$l_cfg___config_var_name" "$l_cfg___paths_sep" "$l_cfg___val"
        fi
        
    done
    
    cfg___close_var path_additional
    cfg___close_var pathext_additional
    cfg___close_var lua_path_additional
    cfg___close_var lua_cpath_additional
}

# ========== Display Config ====================

function cfg___print_config() {
    cfg___define_general_config
    
    if [[ -e "$path_env_vars_config_filepath" ]] ; then
        cfg___define_paths_env_vars
    else
        user_msg <<__end__
generated PATH environment variables config file
${path_env_vars_config_filepath}
does not exist

__end__
    fi
    
    exec_module CFA
    
    CFA___define_config
    
    print_config_vars
    
    exit 0
}

function cfg___print_config_filepaths() {
    cfg___define_wrapper_excl_env_config
    debug_config_vars
    
    printf "main config file\n    %s\n" "$main_config_filepath"
    printf "environment bash startup file\n    %s\n" "$env_bashrc_filepath"
    
    exit 0
}
