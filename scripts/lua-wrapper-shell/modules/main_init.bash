set +m -o pipefail
# disable job control,
# abort on first non-zero exiting command of a pipeline
shopt -s lastpipe
# execute last command of a pipe always in the current shell context

declare -g -i do_force=0 \
              do_run=1 \
              show_additonal_paths_as_win=0 \
              show_config_long=0 \
              m_main___usage_level=0

if ! declare -p debug_level &> /dev/null ; then
    declare -g -i debug_level=0
fi

# to show_additonal_paths_as_win:
# would print the full paths of config values
# Normally prefixes of paths, that are common to selected important config vars
# are abbreviated as a parameter expansion of these

declare -g -A g_main___loaded_modules

#  $1     - module name
# [$2...] - positional parameters for module
function exec_module() {
    if [[ ! -v g_main___loaded_modules["$1"] ]] ; then
        local -r l_main___module="$1"
        shift
        local -a l_main___args=("$@")
        set --
        
        # only debug
        # if declare -p -F cmd_line_from_array > /dev/null 2>&1 ; then
        #     local l_main___args_concated
        #     cmd_line_from_array l_main___args_concated l_main___args
        # else
        #     local l_main___args_concated="${l_main___args[*]}"
        # fi
        # if [[ "$l_main___args_concated" ]] ; then
        #     printf "LOAD MODULE %s with args: %s\n" "$l_main___module" "$l_main___args_concated"
        # else
        #     printf "LOAD MODULE %s\n" "$l_main___module"
        # fi
        
        source "${wrapper_modules_dir}/${l_main___module}.bash" "${l_main___args[@]}"
        g_main___loaded_modules["$l_main___module"]=
    fi
}

exec_module error
exec_module log
exec_module exception
