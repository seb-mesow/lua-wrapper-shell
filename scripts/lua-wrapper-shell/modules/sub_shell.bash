exec_module config
exec_module config_env_vars
exec_module CFA
exec_module patch_files
exec_module env_vars

# sets l_ss___tmp_bashrc_filepath
# 
# uses from calling context:
# l_ss___tmp_bashrc_filepath
function __ss___create_tmp_bashrc() {
    if [[ ! -f "$env_bashrc_filepath" ]] ; then
        write_to_file "$env_bashrc_filepath" "<default static .bashrc file>" <<__end__
# To configure the Lua wrapper shell
# for the ${msys2_shell} and for the Lua version ${lua_version}
# you can edit this file.

# Note, that you can not overwrite the aliases for "lua" and "luarocks".

# The following loads your configuration for the normal Bash shell.
if [ -f "\${HOME}/.bashrc" ] ; then
    source "\${HOME}/.bashrc"
fi
__end__
    fi
    
    temp_filepath l_ss___tmp_bashrc_filepath
    cp -T "$env_bashrc_filepath" "$l_ss___tmp_bashrc_filepath"
    
    local l_ss___alias_lua \
          l_ss___alias_luarocks
    cmd_line_from_args l_ss___alias_lua      "$lua_exe"
    cmd_line_from_args l_ss___alias_luarocks "lua" "$luarocks_lua"
    bash_word_from_str l_ss___alias_lua      "$l_ss___alias_lua"
    bash_word_from_str l_ss___alias_luarocks "$l_ss___alias_luarocks"
    append_to_file "$l_ss___tmp_bashrc_filepath" "<fixed aliases for lua and luarocks>" <<__end__
alias lua=${l_ss___alias_lua}
alias luarocks=${l_ss___alias_luarocks}
__end__
    
    debug_file_contents "$l_ss___tmp_bashrc_filepath"
}

# ========== Main Function ====================

# [$@] - arguments for bash
function __ss___sub_bash() {
    # We assume an interactive shell
    
    local l_ss___PS1_additional_prefix="\[\e[34m\]Lua ${lua_version} wrapper shell\[\e[0m\] " \
          l_ss___LUA_PATH \
          l_ss___LUA_CPATH \
          l_ss___PATH \
          l_ss___PATHEXT \
          l_ss___MANPATH
    
    local -A l_ss___cev_opts
    l_ss___cev_opts=( \
        ["from"]="MSYS2" \
        ["path_style"]="unix" \
        ["order"]="prepend" \
    )
    cev___calc_env_LUA_PATH  l_ss___LUA_PATH  l_ss___cev_opts
    cev___calc_env_LUA_CPATH l_ss___LUA_CPATH l_ss___cev_opts
    cev___calc_env_PATH      l_ss___PATH      l_ss___cev_opts
    cev___calc_env_PATHEXT   l_ss___PATHEXT   l_ss___cev_opts
    cev___calc_env_MANPATH   l_ss___MANPATH   l_ss___cev_opts
    
    if (( do_run > 0 )) ; then
        __ss___create_tmp_bashrc
        
        local l_ss___present_PS1 \
              l_ss___LUA_PATH_versioned_var_name \
              l_ss___LUA_CPATH_versioned_var_name
        
        value_of_bash_var l_ss___present_PS1 PS1
        local l_ss___PS1_mainpart="${l_ss___present_PS1#*\\n}" # split at first newline
        local l_ss___PS1_prefix="${l_ss___present_PS1%"$l_ss___PS1_mainpart"}"
        
        EV___set_str_var HISTFILE "${wrapper_envdir}/.bash_history"
        EV___set_str_var BASH_ENV "$l_ss___tmp_bashrc_filepath" # need, when sub bash is not interactive
        EV___set_str_var PS1 "${l_ss___PS1_prefix}${l_ss___PS1_additional_prefix}${l_ss___PS1_mainpart}"
        
        EV___unset_var LUA_PATH
        EV___unset_var LUA_CPATH
        
        cev___determinate_versioned_env_var_name l_ss___LUA_PATH_versioned_var_name  LUA_PATH
        cev___determinate_versioned_env_var_name l_ss___LUA_CPATH_versioned_var_name LUA_CPATH
        
        EV___set_paths_var "$l_ss___LUA_PATH_versioned_var_name"  "$l_ss___LUA_PATH"  ';'
        EV___set_paths_var "$l_ss___LUA_CPATH_versioned_var_name" "$l_ss___LUA_CPATH" ';'
        EV___set_paths_var PATH                                   "$l_ss___PATH"      ':'
        EV___set_paths_var PATHEXT                                "$l_ss___PATHEXT"   ';'
        EV___set_paths_var MANPATH                                "$l_ss___MANPATH"   ':'
        
        EV___log_changed_vars
        debug_trap_cmds
        
        trap___deactivate ERR
        bash --rcfile "$l_ss___tmp_bashrc_filepath" -O expand_aliases "$@"
        # The above must be the OVER ALL LAST COMMAND to execute (except EXIT traps).
        # only then the exit status of this script is the exit status of the sub bash shell
        
        # EV___restore_var MANPATH
        # EV___restore_var PATHEXT
        # EV___restore_var PATH
        # EV___restore_var "$l_ss___LUA_CPATH_versioned_var_name"
        # EV___restore_var "$l_ss___LUA_PATH_versioned_var_name"
        # EV___restore_var LUA_CPATH
        # EV___restore_var LUA_PATH
        # EV___restore_var PS1
        # EV___restore_var BASH_ENV
        # EV___restore_var HISTFILE
    fi
}

# [$@] - arguments for bash
function __ss___main() {
    cfg___define_general_config
    cfg___define_paths_env_vars
    CFA___define_config
    debug_config_vars
    
    trap___no_ERR pf___install_patches sub_shell
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        PFA___exc___busy)
            __ss___PFA___exc___busy
            ;;
        PFA___exc___no_org)
            __ss___PFA___exc___no_org
            ;;
        *) exc___unhandled ;;
    esac
    
    __ss___sub_bash "$@"
}



# ========== Handling Exception / Error Messages ====================

function __ss___PFA___exc___busy() {
    exc___user_err "\
Another subshell can not be run, \
while already a subshell is running." \
        "\
Use the already running subshell or exit the other subshell in before."
}

function __ss___PFA___exc___no_org() {
    local l_ss___err_str \
          l_ss___help_str \
          l_ss___help_str___install_luarocks
    
    printf -v l_ss___err_str "\
The subshell can not be run, \
while Lua %s and Luarocks is not installed." \
        "$lua_version"
    printf -v l_ss___help_str "\
Install Lua %s and LuaRocks for this environment, \
before running the subshell."
    
    exec_module err_help_strs
    
    help_str___install_luarocks l_ss___help_str___install_luarocks
    printf -v l_ss___help_str "%s\n\n%s" \
        "$l_ss___help_str" "$l_ss___help_str___install_luarocks"
    
    exc___user_err "$l_ss___err_str" "$l_ss___help_str"
}


# ========== Calling the Main Function ====================

__ss___main "$@"
