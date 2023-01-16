exec_module config
exec_module ext_cmds
exec_module config_write
exec_module PFA
exec_module patch_files

# [$1] - one of the following:
#      1. dirpath of the unpacked LuaRocks install sources .zip file with the install.bat
#      2. filepath of the packaed LuaRocks install sources .zip file with the install.bat
#      3. a (grand) parent directory of 1.
#      4. a (grand) parent directory of 2.
#      default: $luarocks_install_sources_dir
function __ilr___main() {
    cfg___define_general_config
    CFA___define_config_of_single_with_args_to_augment_func "install.bat" "$1"
    debug_config_vars
    
    if main___actions___is_registered "installation" "-il" ; then
        main___actions___user_msg___header "install LuaRocks for Lua ${lua_version}"
    fi
    
    __ilr___check_dirs
    
    # The following inserts an io.flush() lines before the io.read()
    # It turned out, that this is needed, to display all stdout of install.bat
    # before the io.read(), when duplicating the stdout not just the terminal,
    # but also to a variable. The latter is necessary to parse the suggested paths.
    pf___install_patches luarocks_install
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        FF___exc___search_path_not_exists)
            __ilr___main___FF___exc___search_path_not_exists "$1" ;;
        PFA___exc___no_org)
            __ilr___main___PFA___exc___no_org "$1" ;;
        *) exc___unhandled ;;
    esac
    
    local l_ilr___FK l_ilr___PFAn
    key_from_user_provided l_ilr___FK "install.bat"
    PFA___new_from_FK l_ilr___PFAn "$l_ilr___FK"
    
    local l_ilr___install_bat_dirpath l_ilr___install_bat_filename
    PFA___get_org_filepath_components \
        l_ilr___install_bat_dirpath l_ilr___install_bat_filename \
        "$l_ilr___PFAn"
    
    debug_str_var l_ilr___install_bat_dirpath
    
    # trap___install_cmd EXIT "command cd '$(pwd)'"
    command cd "$l_ilr___install_bat_dirpath"
    
    local -a l_ilr___install_cmd_line_words
    l_ilr___install_cmd_line_words+=("$l_ilr___install_bat_filename")
    l_ilr___install_cmd_line_words+=('/NOADMIN')
    l_ilr___install_cmd_line_words+=('/LUA'  "$lua_envdir_win"     )
    l_ilr___install_cmd_line_words+=('/P'    "$luarocks_envdir_win")
    l_ilr___install_cmd_line_words+=('/TREE' "$luarocks_envdir_win")
    l_ilr___install_cmd_line_words+=('/MW')
    if (( do_force > 0 )) ; then
        l_ilr___install_cmd_line_words+=('/F' '/Q')
    fi
    
    # use PATH with appropriate MSYS2 env
    local l_ilr___PATH_win
    convert_PATH_like_str_to_win l_ilr___PATH_win "${lua_bin_dir}${PATH:+":${PATH}"}"
    debug_paths_var l_ilr___PATH_win ";"
    
    concat_str_from_array l_ilr___install_cmd_line l_ilr___install_cmd_line_words ' ' '"' '"'
    
    local l_calling_bat_filename="${wrapper_name_for_filenames}___calling.bat"
    trap___install_cmd EXIT "rm -f '${l_ilr___install_bat_dirpath}/${l_calling_bat_filename}'"
    
    write_to_file "$l_calling_bat_filename" \
            "<calling batch script with proper PATH>" \
            <<__end__
@echo off
REM value for PATH must not be quoted
set PATH=${l_ilr___PATH_win}
${l_ilr___install_cmd_line}
__end__
    
    log_file_contents "$l_calling_bat_filename"
    
    if [[ "$msystem" =~ "ucrt" ]] && (( do_force < 1 )) ; then
        user_msg <<__end__
You will maybe note the following:
The script to install LuaRocks on Windows (install.bat) \
can not correctly determinate the C Runtime of the Lua executable and Lua library DLL. \
It probably will set the older Microsoft Visual C++ Runtime (an msvcr*.dll) as the fallback. \
(as of December 2022)

But you are in the ${msys2_shell} shell. \
It is intended, that all binaries (executables and libraries) for this ${msys2_shell} \
link against Microsoft's newer Universial C Runtime (ucrtbase.dll).

You should have no need to take any action about this.

When you run the sub shell, the Lua Wrapper Shell will previously patch \
the relevant configuration file of LuaRocks. \
Thus binaries of rocks (LuaRocks packages) will link against ucrtbase.dll .
__end__
        local l_ilr___input_char
        user_msg "Press the Enter key to proceed."
        while [[ "$l_ilr___input_char" != $'\n' ]] ; do
            read -r -s -N 1 l_ilr___input_char
        done
    fi
    local -i l_ec___do_print_stdin=1
    win_cmd_exe '//C' "$l_calling_bat_filename"
    
    __ilr___write_suggested_paths_to_path_env_vars_config_file
}

# $1 - explicitly provided argument for lua sources dir
#      not recognized if the empty string
function __ilr___main___FF___exc___search_path_not_exists() {
    exec_module err_help_strs
        
    local l_ilr___src_path="$1" \
          l_ilr___err_str l_ilr___help_str
    if [[ "$l_ilr___src_path" ]] ; then
        local l_ilr___src_path_win \
              l_ilr___help_str___explicit_dir_not_exists \
              l_ilr___help_str___empty_args
        convert_path_to_win l_ilr___src_path_win "$l_ilr___src_path"
        printf -v l_ilr___err_str \
            "Could not install LuaRocks, because \
the explicitly provided directory resp. filepath \
to search for LuaRocks Windows install sources in
%s
does not exist." \
            "$l_ilr___src_path_win"
        help_str___explicit_dir_not_exists \
            l_ilr___help_str___explicit_dir_not_exists
        help_str___install_lua_and_luarocks___empty_args \
            l_ilr___help_str___empty_args
        printf -v l_ilr___help_str "%s\n\n%s" \
            "$l_ilr___help_str___explicit_dir_not_exists" \
            "$l_ilr___help_str___empty_args"
        
    else
        local l_ilr___err_str___in_main_config_file
        err_str___in_main_config_file___dir_not_exists \
            l_ilr___err_str___in_main_config_file luarocks_install_sources_dir
        printf -v l_ilr___err_str \
            "Could not install LuaRocks, because:\n%s" \
            "$l_ilr___err_str___in_main_config_file"
        help_str___in_main_config_file___dir_not_exists \
            l_ilr___help_str luarocks_install_sources_dir
        
    fi
    exc___user_err "$l_ilr___err_str" "$l_ilr___help_str"

}

# $1 - explicitly provided argument for lua sources dir
#      not recognized if the empty string
function __ilr___main___PFA___exc___no_org() {
    exec_module err_help_strs
    
    local l_ilr___src_path="$1" \
          l_ilr___err_str l_ilr___help_str
    
    if [[ "$l_ilr___src_path" ]] ; then
        local l_ilr___src_path_win \
            l_il__help_str___dir_as_arg
        convert_path_to_win l_ilr___src_path_win "$l_ilr___src_path"
        printf -v l_ilr___err_str \
            "Could not install LuaRocks, because \
the explicitly provided directory or filepath \
to search for LuaRocks install sources for Windows in
%s
does not contain those." \
            "$l_ilr___src_path_win"
        printf -v l_ilr___help_str \
            "Please ensure, that the explicitly provided directory resp. filepath \
contains LuaRocks install sources for Windows.
The LuaRocks install sources for Windows must be an archive file named like
%s
or its decompressed contents." \
            "$g_ehs___luarocks_install_sources_archive_filename_pattern"
        
    else
        local -a l_ilr___paths_win l_ilr___paths_unix
        l_ilr___paths_unix=("$main_config_filepath" "$luarocks_install_sources_dir")
        convert_paths_to_win l_ilr___paths_win l_ilr___paths_unix
        local l_ilr___help_str___download_luarocks_sources \
              l_ilr___help_str___dir_as_arg
        printf -v l_ilr___err_str \
            "Could not build and install LuaRocks, because:
In the main config file
%s
for the variable
%s
the directory
%s
was provided.

This directory does not contain LuaRocks install sources for Windows.
These sources must be an archive file named like
%s
or its decompressed contents." \
            "${l_ilr___paths_win[0]}" "luarocks_install_sources_dir" \
            "${l_ilr___paths_win[1]}" \
            "$g_ehs___luarocks_install_sources_archive_filename_pattern"
        help_str___download_luarocks_sources l_ilr___help_str___download_luarocks_sources
        printf -v l_ilr___help_str___dir_as_arg \
            "Or you can provide a directory or filepath \
which contains LuaRocks install sources for windows \
explicitly as an argument to the -ilr option"
        printf -v l_ilr___help_str "%s\n\n%s" \
            "$l_ilr___help_str___download_luarocks_sources" \
            "$l_ilr___help_str___dir_as_arg"
        
    fi
    exc___user_err "$l_ilr___err_str" "$l_ilr___help_str"
}

function __ilr___check_dirs() {
    if (( do_run > 0 )) ; then
        
        if [[ ! -d "$luarocks_maindir" ]] ; then
            if [[ -e "$luarocks_maindir" ]] ; then
                user_err <<__end__
LuaRocks main directory
${luarocks_maindir_win}
exists, but is not a directory
__end__
            fi
            # The LuaRocks install.bat will make the install directory == luarocks_envdir ,
            # which includes luarocks_maindir .
        fi
        
        if [[ ! -d "$luarocks_envdir" ]] ; then
            if [[ -e "$luarocks_envdir" ]] ; then
                user_err <<__end__
LuaRocks environment directory
${luarocks_envdir_win}
exists, but is not a directory
__end__
            fi
            # The LuaRocks install.bat will make the install directory == luarocks_envdir .
        elif (( do_force > 0 )) ; then
            
            rm -rf "$luarocks_envdir"
        else
            local l_ilr___cmdline
            cmd_line_from_args l_ilr___cmdline \
                    rm -r "$luarocks_envdir"
            user_err <<__end__
install/environment directory for LuaRocks for Lua ${lua_version}
${luarocks_envdir_win}
already exists

If you want to install LuaRocks for Lua ${lua_version} "fresh" \
(== overwriting everything already existing), \
then beforehand you must remove this existing directory.
Therefore execute the following with root privileges (#):
# ${l_ilr___cmdline}
__end__
        fi
        
        if [[ ! -d "$lua_maindir" ]] ; then
            if [[ -e "$lua_maindir" ]] ; then
                user_err <<__end__
Lua main directory
${lua_maindir_win}
exists, but is not a directory
__end__
            fi
            user_err_no_abort <<__end__
Lua main directory
$lua_maindir_win
does not exist
__end__
            __ilr___user_err___install_lua
        fi
        
        if [[ ! -d "$lua_envdir" ]] ; then
            if [[ -e "$lua_envdir" ]] ; then
                user_err <<__end__
Lua environment directory
${lua_envdir_win}
exists, but is not a directory
__end__
            fi
            user_err_no_abort <<__end__
Lua environment directory
${lua_envdir_win}
does not exist
__end__
            __ilr___user_err___install_lua
        fi
        
    fi # end if do_run
}

function __ilr___user_err___install_lua() {
    local l_ilr___cmdline
    cmd_line_from_args l_ilr___cmdline \
            "$0" "$lua_version" -il
    user_err <<__end__
Before installing LuaRocks for Lua ${lua_version} you must build and install Lua ${lua_version} .
Therefore execute the following with root privileges (#):
# ${l_ilr___cmdline}
__end__
}

function __ilr___write_suggested_paths_to_path_env_vars_config_file() {
    local -a l_ilr___suggested_paths_keys l_ilr___suggested_paths_vals
    
    __ilr___parse_suggested_paths \
            l_ilr___suggested_paths_keys l_ilr___suggested_paths_vals g_cmd_out
    
    log_two_arrays l_ilr___suggested_paths_keys l_ilr___suggested_paths_vals
    
    local l_ilr___suggested_paths_config_str
    
    config_str_from_two_arrays l_ilr___suggested_paths_config_str \
            l_ilr___suggested_paths_keys l_ilr___suggested_paths_vals
    
    write_to_file "$path_env_vars_config_filepath" "<introducing comments>" <<__end__
# This file was automatically generated during the installation of LuaRocks at \
$(printf "%(%F %T %z)T") .
# It contains the suggested additions to PATH-like environment variables.
# EDITING THIS FILE IS NOT RECOMMENDED !
# Instead the author recommends to reinstall LuaRocks via the Lua Wrapper Shell with the proper configuration.

__end__
    
    append_to_file "$path_env_vars_config_filepath" \
        "<suggested paths from stdout of install.bat>" \
        "$l_ilr___suggested_paths_config_str"
    
    trace_file_contents "$path_env_vars_config_filepath"
}

# parses the suggested paths from LuaRocks install.bat
# into an associative array.
# The keys will be of the form "<section>.<env varname>"
# 
# arguments:
# $1 - varname of an indexed array to store the keys in
# $2 - varname of an indexed array to store the values in
# $3 - varname of an indexed array to read the lines from
function __ilr___parse_suggested_paths() {
    local -n l_ilr___keys="$1" l_ilr___vals="$2" l_ilr____lines="$3"
    
    l_ilr___keys=()
    l_ilr___vals=()
    
    local -i l_i=0
    local -i l_n=${#l_ilr____lines[@]}
    local l_line
    while (( l_i < l_n )) ; do
        if [[ "${l_ilr____lines[l_i++]}" =~ "You may want to add the following elements to your paths" ]] ; then
            break
        fi
    done
    if (( l_i >= l_n )) ; then
        internal_err "Could not parse suggested paths from install.bat"
    fi
    
    if (( debug_level > 2 )) ; then
        local -i l_ii=l_i
        trace "===== output with relevance for suggested paths ===================="
        local l_line
        while (( l_ii < l_n  )) ; do
            l_line="${l_ilr____lines[l_ii++]%$'\r'}"
            trace_plain "${l_line%$'\n'}"
        done
        trace_plain "=============================="
    fi
    
    local l_env_var l_val l_sec
    while (( l_i < l_n )) ; do
        l_line="${l_ilr____lines[l_i++]%$'\n'}"
        l_line="${l_line%$'\r'}"
        trace_str_var_quoted l_line
        if [[ (   "$l_line" =~ [[:graph:]]    )\
           && ( ! "$l_line" =~ "be replaced"  ) \
           && ( ! "$l_line" =~ "current user" ) ]] ; then
            if [[ "$l_line" =~ ^[[:blank:]]*([[:upper:][:digit:]_]+)[[:blank:]]*: ]] ; then
                # env var with suggested path
                trace_plain "--- parse ENV VAR"
                l_env_var="${BASH_REMATCH[1]}"
                strip_surrounding_whitespace l_val "${l_line#${BASH_REMATCH[0]}}"
                trace_str_var_quoted l_env_var
                trace_str_var_quoted l_val
                if [[ ! -v l_sec ]] ; then
                    internal_err "__parse_suggested_paths(): no initial section"
                fi
                l_ilr___keys+=("${l_sec}.${l_env_var}")
                
                # compare with cfg___define_paths_env_vars
                if [[ ! "$l_env_var" =~ PATH.*EXT ]] ; then
                    if [[ ! "$l_env_var" =~ LUA.*PATH ]] ; then
                    #     convert_PATH_like_str_to_win l_val "$l_val" ";"
                    # else
                        convert_PATH_like_str_to_unix l_val "$l_val"
                    fi
                fi
                
                trace_str_var_quoted l_val
                l_ilr___vals+=("$l_val")
            else # section
                trace_plain "--- parse SECTION"
                if [[ "$l_line" =~ ^([^'(']*)'(' ]] ; then
                    strip_surrounding_whitespace l_sec "${BASH_REMATCH[1]}"
                else
                    strip_surrounding_whitespace l_sec "$l_line"
                fi
                if [[ "$l_sec" =~ ';'*$ ]] ; then
                    l_sec="${l_sec%%"${BASH_REMATCH[0]}"}"
                fi
                trace_str_var_quoted l_sec
            fi
        else
            trace_plain "ignore this line"
        fi
    done
    
    return 0
}

__ilr___main "$@"
