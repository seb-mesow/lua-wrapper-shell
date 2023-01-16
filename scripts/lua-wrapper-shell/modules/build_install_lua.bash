exec_module config
exec_module ext_cmds
exec_module find_file

# [$1] - one of the following:
#      1. dirpath of the unpacked Lual sources .tar.gz file with the Makefiles
#      2. filepath of the packaed Lual sources .tar.gz file with the Makefiles
#      3. a (grand) parent directory of 1.
#      4. a (grand) parent directory of 2.
#      default: $lua_sources_dir
function __il___main() {
    cfg___define_general_config
    debug_config_vars
    
    if main___actions___is_registered "installation" "-ilr" ; then
        main___actions___user_msg___header "build & install Lua ${lua_version}"
    fi
    
    __il___check_dirs
    
    local l_il___src_path="$1"
     # assigns the empty string == null, if 1 not provided
    
    local l_il___makefile_filepath \
          l_il___makefile_dirpath l_il___makefile_filename
    __il___find_makefile l_il___makefile_filepath
    
    split_filepath  l_il___makefile_dirpath l_il___makefile_filename \
                    "$l_il___makefile_filepath"
    
    debug_str_var l_il___makefile_dirpath
    debug_str_var l_il___makefile_filename
    
    command cd "$l_il___makefile_dirpath"
    
    user_msg_plain ""
    local -i l_ec___do_print_stdin=1
    make    -f "$l_il___makefile_filename" \
            "MYCFLAGS=-fdiagnostics-color" \
            mingw
    
    local l_il___dll_filepath l_il___dll_dirpath l_il___dll_filename
    __il___find_dll l_il___dll_filepath
    
    debug_str_var l_il___dll_filepath
    
    split_filepath l_il___dll_dirpath l_il___dll_filename "$l_il___dll_filepath"
    
    debug_str_var l_il___dll_filename
    
    make    -f "$l_il___makefile_filename" \
            "INSTALL_TOP=\"${lua_envdir}\"" \
            'INSTALL_LIB=$(INSTALL_TOP)/bin' \
            "TO_LIB=\"${l_il___dll_filename}\"" \
            install
    
    if ! main___actions___is_registered "installation" "-ilr" ; then
        local l_il___cmdline
        cmd_line_from_args l_il___cmdline \
                "$0" "${lua_version}" -ilr
        user_msg <<__end__
Now you should install LuaRocks for Lua ${lua_version} .
Therefore execute the following with root privileges (#):
# ${l_il___cmdline}
__end__
    fi
}

function __il___check_dirs() {
    if (( do_run > 0 )) ; then
        
        if [[ ! -d "$lua_maindir" ]] ; then
            if [[ -e "$lua_maindir" ]] ; then
                user_err <<__end__
Lua main directory
${lua_maindir_win}
exists, but is not a directory
__end__
            fi
            # The Lua Makefile will make the install directory == lua_envdir ,
            # which includes lua_maindir .
        fi
        
        if [[ ! -d "$lua_envdir" ]] ; then
            if [[ -e "$lua_envdir" ]] ; then
                user_err <<__end__
Lua environment directory
${lua_envdir_win}
exists, but is not a directory
__end__
            fi
            # The Lua Makefile will make the install directory == lua_envdir .
        elif (( do_force > 0 )) ; then
            rm -rf "$lua_envdir"
        else
            local l_il___cmdline
            cmd_line_from_args l_il___cmdline \
                    rm -r "$lua_envdir"
            user_err <<__end__
install/environment directory for Lua ${lua_version}
${lua_envdir_win}
already exists

If you want to install Lua ${lua_version} "fresh" \
(== overwriting everything already existing), \
then beforehand you must remove this existing directory.
Therefore execute the following with root privileges (#):
# ${l_il___cmdline}
__end__
        fi
        
    fi # end if do_run
}

# $1 - ret str var name for filepath
function __il___find_makefile() {
    local -n l_il___found_filepath="$1"
    
    local l_il___src_subdir_regex=\
"lua-(${lua_version//./\.}(\.[[:digit:]]+)?)[^/]*"
    
    find_file "${!l_il___found_filepath}" \
            "${l_il___src_path:-$lua_sources_dir}" \
            "${l_il___src_subdir_regex}/Makefile" \
            "${l_il___src_subdir_regex}"
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        FF___exc___search_path_not_exists)
            __il___find_makefile___FF___exc___search_path_not_exists ;;
        *) exc___unhandled ;;
    esac
        
    if [[ -z "$l_il___found_filepath" ]] ; then
        __il___find_makefile___not_found
    fi
}

# uses from calling context:
# l_il___src_path
function __il___find_makefile___FF___exc___search_path_not_exists() {
    exec_module err_help_strs
        
    local l_il___err_str l_il___help_str
    if [[ "$l_il___src_path" ]] ; then
        local l_il___src_path_win \
              l_il___help_str___explicit_dir_not_exists \
              l_il___help_str___empty_args
        convert_path_to_win l_il___src_path_win "$l_il___src_path"
        printf -v l_il___err_str \
            "Could not build and install Lua, \
because the explicitly provided directory resp. filepath \
to search for Lua sources in
%s
does not exist." \
        "$l_il___src_path_win"
        help_str___explicit_dir_not_exists \
            l_il___help_str___explicit_dir_not_exists
        help_str___install_lua_and_luarocks___empty_args \
            l_il___help_str___empty_args
        printf -v l_il___help_str "%s\n\n%s" \
            "$l_il___help_str___explicit_dir_not_exists" \
            "$l_il___help_str___empty_args"
        
    else
        local l_il___err_str___in_main_config_file
        err_str___in_main_config_file___dir_not_exists \
            l_il___err_str___in_main_config_file lua_sources_dir
        printf -v l_il___err_str \
            "Could not build and install Lua, because:\n%s" \
            "$l_il___err_str___in_main_config_file"
        help_str___in_main_config_file___dir_not_exists \
            l_il___help_str lua_sources_dir
        
    fi
    exc___user_err "$l_il___err_str" "$l_il___help_str"
}

# uses from calling context:
# l_il___src_path
function __il___find_makefile___not_found() {
    exec_module err_help_strs
    
    local l_il___err_str l_il___help_str
    
    if [[ "$l_il___src_path" ]] ; then
        local l_il___src_path_win \
            l_il__help_str___dir_as_arg
        convert_path_to_win l_il___src_path_win "$l_il___src_path"
        printf -v l_il___err_str \
            "Could not build and install Lua %s, because
the explicitly provided directory resp. filepath to search for Lua %s sources in
%s
does not contain Lua %s sources" \
            "$lua_version" "$lua_version" \
            "$l_il___src_path_win" "$lua_version"
        printf -v l_il___help_str \
            "Please ensure, that the explicitly provided directory resp. filepath \
contains Lua %s sources.
The Lua %s sources must be an archive file named like
%s
or its decompressed contents." \
            "$lua_version" "$lua_version" \
            "$g_ehs___lua_sources_archive_filename_pattern"
        
    else
        local -a l_il___paths_win l_il___paths_unix
        l_il___paths_unix=("$main_config_filepath" "$lua_sources_dir")
        convert_paths_to_win l_il___paths_win l_il___paths_unix
        local l_il___help_str___download_lua_sources \
              l_il___help_str___dir_as_arg
        printf -v l_il___err_str \
            "Could not build and install Lua %s, because:
In the main config file
%s
for the variable
%s
the directory
%s
was provided.

This directory does not contain Lua %s sources.
The Lua %s sources must be an archive file named like
%s
or its decompressed contents." \
            "$lua_version" "${l_il___paths_win[0]}" "lua_sources_dir" \
            "${l_il___paths_win[1]}" "$lua_version" "$lua_version" \
            "$g_ehs___lua_sources_archive_filename_pattern"
        help_str___download_lua_sources l_il___help_str___download_lua_sources
        printf -v l_il___help_str___dir_as_arg \
            "Or you can provide a directory or filepath \
which contains Lua %s sources explicitly as an argument to the -il option" \
            "$lua_version"
        printf -v l_il___help_str "%s\n\n%s" \
            "$l_il___help_str___download_lua_sources" \
            "$l_il___help_str___dir_as_arg"
        
    fi
    exc___user_err "$l_il___err_str" "$l_il___help_str"
}

# $1 - ret str var name for filepath
function __il___find_dll() {
    local -n l_il___found_filepath="$1"
    
    find_file "${!l_il___found_filepath}" \
        "." \
        "src/lua[[:digit:]][[:digit:]][[:digit:]]?\.dll"
    
    if [[ -z "$l_il___found_filepath" ]] ; then
        internal_err "Could not find compiled lua*.dll"
    fi
}

__il___main "$@"
