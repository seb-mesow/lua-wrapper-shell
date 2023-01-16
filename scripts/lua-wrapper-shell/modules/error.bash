exec_module trap

function __err___handler() {
    exec_module callstack
    
    local l_err___CS_n
    CS___snapshot l_err___CS_n "$g_trap___extra_nesting_levels" # formerly +1
    CS___show_long "$l_err___CS_n" 1>&2
    
    exit "$EXIT_STATUS"
}

trap___install_cmd ERR __err___handler
