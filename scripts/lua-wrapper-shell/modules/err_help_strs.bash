declare -g g_ehs___lua_sources_archive_filename_pattern=\
"lua-${lua_version}.D.tar.gz    (where 'D' is a placeholder for a digit 0-9)"

declare -g g_ehs___luarocks_install_sources_archive_filename_pattern=\
"luarocks-D.D.D-win32.zip    (where 'D' is a placeholder for a digit 0-9)"

# $1 - ret str var name
function help_str___download_lua_sources() {
    exec_module config
    cfg___define_general_config
    
    local l_ehs___lua_sources_dir_win
    convert_path_to_win l_ehs___lua_sources_dir_win "$lua_sources_dir"
    printf -v "$1" \
        "Please ensure, that you have downloaded the latest file\n%s\n\
from\n%s\nto the directory\n%s" \
        "$g_ehs___lua_sources_archive_filename_pattern" \
        "https://www.lua.org/ftp/" \
        "$l_ehs___lua_sources_dir_win"
}

# $1 - ret str var name
function help_str___download_luarocks_sources() {
    exec_module config
    cfg___define_general_config
    
    local l_ehs___luarocks_install_sources_dir_win
    convert_path_to_win l_ehs___luarocks_install_sources_dir_win "$luarocks_install_sources_dir"
    printf -v "$1" \
        "Please ensure, that you have downloaded the latest file\n%s\n\
from\n%s\nto the directory\n%s" \
        "$g_ehs___luarocks_install_sources_archive_filename_pattern" \
        "https://luarocks.github.io/luarocks/releases/" \
        "$l_ehs___luarocks_install_sources_dir_win"
}

# $1 - ret str var name
# $2 - if provided:
#      remove LuaRocks envdir in before
function help_str___install_luarocks() {
    exec_module config
    cfg___define_general_config
    
    if [[ "$2" ]] ; then
        local l_ehs___cmdline___rm_luarocks_envdir
        cmd_line_from_args l_ehs___cmdline___rm_luarocks_envdir \
                rm -r "$luarocks_envdir"
    fi
    
    local l_ehs___cmd_line___install_luarocks \
          l_ehs___cmd_lines
    cmd_line_from_args l_ehs___cmd_line___install_luarocks \
        "$0" "$lua_version" -ilr
    
    if [[ "$2" ]] ; then
        printf -v l_ehs___cmd_lines "\
1. # %s
2. # %s" \
            "$l_ehs___cmdline___rm_luarocks_envdir" \
            "$l_ehs___cmd_line___install_luarocks"
    else
        printf -v l_ehs___cmd_lines "# %s" \
            "$l_ehs___cmd_line___install_luarocks"
    fi
    
    printf -v "$1" "\
To do that execute the following with root privileges (#):
%s" \
        "$l_ehs___cmd_lines"
}

# $1 - ret str var name
function help_str___explicit_dir_not_exists() {
    printf -v "$1" \
        "Please ensure to correctly pass the directory as a single argument.\n\
You should try to enclose the directory in single quotes."
}

# $1 - ret str var name
function help_str___install_lua_and_luarocks___empty_args() {
    local l_ehs___cmd_line
    cmd_line_from_args l_ehs___cmd_line "$0" -il '' -ilr
    printf -v "$1" \
        "If you want to install Lua and LuaRocks in a single command, \
while relying on the directories with the sources provided in the main config file,\n\
then you must provide an empty argument for the directory with the Lua sources.\n\
Thereafter you should execute the following command line with root privileges (#)\n\
# %s" \
        "$l_ehs___cmd_line"
}

# $1 - ret str var name
# $2 - config var name
function err_str___in_main_config_file___dir_not_exists() {
    local -n l_ehs___path="$2"
    local -a l_ehs___paths_unix l_ehs___paths_win
    l_ehs___paths_unix=("$main_config_filepath" "$l_ehs___path")
    convert_paths_to_win l_ehs___paths_win l_ehs___paths_unix
    printf -v "$1" \
        "In the main config file\n%s\nfor the variable\n%s\n\
the directory\n%s\nwas provided, which does not exist." \
        "${l_ehs___paths_win[0]}" \
        "$2" \
        "${l_ehs___paths_win[1]}"
}

# $1 - ret str var name
# $2 - config var name
function help_str___in_main_config_file___dir_not_exists() {
    printf -v "$1" \
        "Please edit the main config file.\n\
Ensure, that the directory path provided as value for the variable %s exists.\n\
You should try to enclose the directory path in single quotes." \
        "$2"
}