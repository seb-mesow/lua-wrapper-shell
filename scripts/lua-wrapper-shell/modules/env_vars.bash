# This module define functions for setting new values of environment variables
# and restoring the previous values, if it was previously set.


# ===== Bookkeeping of Changed Environment Variables ====================

# type of variable | meaning
# -----------------|--------------------------
# u                | unset
# s                | string
# .+               | PATH-like, seperated by .+

declare -g -a m_EV___EV_ns_order
# empty entries

function EV___print_changed_vars() {
    local l_EV___EV_n
    for l_EV___EV_n in "${m_EV___EV_ns_order[@]}" ; do
        if [[ "$l_EV___EV_n" ]] ; then
            local -n l_EV___EV="$l_EV___EV_n"
            case "${l_EV___EV[t]}" in
                s)
                    print_str_var "${l_EV___EV[n]}"
                    ;;
                i)
                    print_int_var "${l_EV___EV[n]}"
                    ;;
                u)
                    echo "${l_EV___EV[n]} is unset."
                    ;;
                '')
                    internal_errf "at EV___print_changed_vars():\ntype is empty"
                    ;;
                *)
                    print_paths_var "${l_EV___EV[n]}" "${l_EV___EV[t]}"
                    ;;
            esac
        fi
    done
}
# declares EV___log_changed_vars(), EV___debug_changed_vars(), EV___trace_changed_vars()
declare_debug_funcs_from_print_func EV___print_changed_vars

# ===== Change Environment Variables ====================

# sets l_EV___EV_n
# 
# arguments:
# $1 - var_n
# 
# uses from calling context:
# l_EV___EV_n
function __EV___get_EV_n_from_var_n() {
    l_EV___EV_n="m_EV___EV_${1}"
}

# $1 - var_n
# $2 - env var type
function __EV___backup() {
    local l_EV___EV_n
    __EV___get_EV_n_from_var_n "$1"
    if is_var_defined "$l_EV___EV_n" ; then
        internal_errf "Cannot set env var %s, while already set or unset by EV module." "$1"
    fi
    declare -g -A "$l_EV___EV_n"
    local -n l_EV___EV="$l_EV___EV_n"
    
    l_EV___EV=( \
        [n]="$1" \
        [t]="$2" \
        [o]="${#m_EV___EV_ns_order[@]}" \
    )
    m_EV___EV_ns_order+=("$l_EV___EV_n")
    if is_var_defined "$1" ; then
        local -n l_EV___org_var="$1"
        l_EV___EV[b]="$l_EV___org_var" 
    fi
    
}

# $1 - var_n
# $2 - str
function EV___set_str_var() {
    __EV___backup "$1" "s"
    
    export "$1"="$2"
}

# $1 - var_n
# $2 - str
# $3 - sep (must not be "u", "s", "i")
function EV___set_paths_var() {
    if [[ "$3" == "" ]] ; then
        internal_err "seperator is empty"
    fi
    
    if [[ "$3" =~ ^[usi]$ ]] ; then
        internal_err <<__end__
seperator must not be "u", "s", "i"
seperator == "$3"
__end__
    fi
    
    __EV___backup "$1" "$3"
    
    export "$1"="$2"
}

# $1 - var_n
function EV___unset_var() {
    __EV___backup "$1" "u"
    
    unset -v "$1"
}

# $1 - var_n
function EV___restore_var() {
    local l_EV___EV_n
    __EV___get_EV_n_from_var_n "$1"
    local -n l_EV___EV="$l_EV___EV_n"
    
    export "$1"="${l_EV___EV[b]}"
    
    m_EV___EV_ns_order["${l_EV___EV[o]}"]=
    
    unset -v "$l_EV___EV_n"
}
