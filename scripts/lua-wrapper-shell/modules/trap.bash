# This file defines an interface for installing multiple functions for a single SIGNAL.
# These functions are hold in a list.
# A new function is installed at the beginning of the list.
# Thus when the functions of this list are executed in order,
# then the last installed function is executed first

# All installed commands must not execute the exit statement
# Inside the execute statement
# ${FUNCNAME[2]}    refers to the function that conatins the failed command
# ${BASH_SOURCE[2]} refers to the script file, where the failed command is
# ${BASH_LINENO[0]} refers to the line of this file, where the failed command is

# The ERR trap is executed when a bash statement returns a non-zero exit status,
# except if it is part of a conditional expression.
# 
# The EXIT trap is executed when ever the the shell script exits
# (regardless of the exit status).
# 
# We introduce two further pseudo signals:
# Installed commands to the NORMAL_EXIT signal are executed,
# when ever the EXIT trap is executed with a zero exit status.
# Installed commands to the ERR_EXIT signal are executed,
# when ever the EXIT trap is executed with a non-zero exit status.

# Implementation Notes:
# 
# This is implemented in providing the integer variable EXIT_STATUS
# when executing the ERR, EXIT, RETURN, DEBUG trap cmds.
# 
# On the pseudo signals ERR, EXIT, RETURN, DEBUG the following command is executed:
#     __trap___execute_cmds_with_EXIT_STATUS <signal name>
# On all other real signals the following command line is executed:
#     __trap___execute_cmds <signal name>

exec_module log

declare -g -a m_trap___signals_with_installed_traps

# $1 - (pseudo) signal name
# $2 ... - statements to eval in that order
#          words, which belong to the same statement, must be quoted together
function trap___install_cmd() {
    case "$1" in
        ERR|EXIT|DEBUG|RETURN)
            local l_trap___internal_sig_spec="$1"
            local l_trap___execute_func="__trap___execute_cmds_with_EXIT_STATUS"
            ;;
        NORMAL_EXIT)
            shift
            local -a l_trap___cmds=()
            for l_trap___cmd in "$@" ; do
                l_trap___cmds+=("if (( ! EXIT_STATUS )) ; then $l_trap___cmd ; fi")
            done
            trap___install_cmd "EXIT" "${l_trap___cmds[@]}"
            return
            ;;
        ERR_EXIT)
            shift
            local -a l_trap___cmds=()
            for l_trap___cmd in "$@" ; do
                l_trap___cmds+=("if (( EXIT_STATUS )) ; then $l_trap___cmd ; fi")
            done
            trap___install_cmd "EXIT" "${l_trap___cmds[@]}"
            return
            ;;
        SIG*)
            local l_trap___internal_sig_spec="${1//+/_plus_}"
            l_trap___internal_sig_spec="${l_trap___internal_sig_spec//-/_minus_}"
            local l_trap___execute_func="__trap___execute_cmds"
            ;;
        *)
            local l_trap___bash_word
            bash_word_from_str l_trap___bash_word "$1"
            internal_err "invalid signal specification ${l_trap___bash_word}"
            ;;
    esac
    local l_trap___cmds_array_name="m_trap___cmds_${l_trap___internal_sig_spec}"
    if [[ ! -v "$l_trap___cmds_array_name" ]] ; then
        # faster than [[ -z "$(trap -p "$1")" ]]
        # saves about 0.2 seconds an startup
        
        declare -g -a "$l_trap___cmds_array_name"
        # l_trap___cmds=()
        # case "$l_trap___execute_func" in
        #     "__trap___execute_cmds_with_EXIT_STATUS")
        #         trap "$l_trap___execute_func $l_trap___internal_sig_spec" "$1"
        #         ;;
        #     "__trap___execute_cmds")
        #         trap "$l_trap___execute_func $l_trap___internal_sig_spec 1" "$1"
        #         ;;
        # esac
        trap "$l_trap___execute_func $l_trap___internal_sig_spec" "$1"
        m_trap___signals_with_installed_traps+=("$l_trap___internal_sig_spec")
    fi
    local -n l_trap___cmds="$l_trap___cmds_array_name"
        
    case "$1" in
        ERR)
            set -E
            # "If set, any trap on ERR is inherited by shell functions,
            # command substitutions, and commands executed in a subshell environment.
            # The ERR trap is normally not inherited in such cases."
            # (from Bash reference)
            ;; 
        DEBUG|RETURN)
            set -T
            # "If set, any trap on DEBUG and RETURN are inherited by shell functions,
            # command substitutions, and commands executed in a subshell environment.
            # The DEBUG and RETURN traps are normally not inherited in such cases. "
            # (from Bash reference)
            ;;
    esac
    shift
    # To execute the cmds in the opposite order, as they were installed,
    # further cmds are /prepended/ before the already installed cmds.
    l_trap___cmds=("$@" "${l_trap___cmds[@]}")
}

#  $1  - internal signal name
# [$2] - value for g_trap___extra_nesting_levels
#        default: 1 (for __trap___execute_cmds() itself )
function __trap___execute_cmds() {
    local l_trap___reinstall_ERR_trap="$(trap -p ERR)"
    trap ERR
    
    local -i g_trap___extra_nesting_levels="${2:-1}"
    local -n l_trap___cmds="m_trap___cmds_$1"
    for l_trap___cmd in "${l_trap___cmds[@]}" ; do
        eval "$l_trap___cmd"
    done
    
    eval "$l_trap___reinstall_ERR_trap"
}

# $1 - internal signal name
function __trap___execute_cmds_with_EXIT_STATUS() {
    local -i EXIT_STATUS="$?"
    __trap___execute_cmds "$1" 2
    # unset EXIT_STATUS
}

# also asserts. that the provided signal specification is
# a vaild bash (pseudo) signal specification.
# This excludes NORMAL_EXIT and ERR_EXIT.
# $1 - ret str var name
# $2 - user provided signal specification
function __trap___derive_internal_signal_spec() {
    local -n l_trap___internal_sig_spec_="$1"
    case "$2" in
        ERR|EXIT|DEBUG|RETURN)
            l_trap___internal_sig_spec_="$2"
            ;;
        SIG*)
            l_trap___internal_sig_spec_="${2//+/_plus_}"
            l_trap___internal_sig_spec_="${l_trap___internal_sig_spec_//-/_minus_}"
            ;;
        NORMAL_EXIT|ERR_EXIT)
            internal_err "You can not activate resp. deactivate the pseudo signal $1"
            ;;
        *)
            local l_trap___bash_word
            bash_word_from_str l_trap___bash_word "$2"
            internal_err "invalid (pseudo) signal specification ${l_trap___bash_word}"
            ;;
    esac
}

# It is strongly recommended, to deactivate and activate
# with in the same function and at the same syntactic nesting level
# 
# optimized for speed
# 
# arguments:
# $1 - (pseudo) signal name
function trap___deactivate() {
    # declare -g 
    
    # keep for debugging!
    # local l_trap___internal_sig_spec
    # __trap___derive_internal_signal_spec l_trap___internal_sig_spec "$1"
    # declare -g "g_trap___reinstall_cmd_line_${l_trap___internal_sig_spec}"="$(trap -p "$1")"
    
    trap "$1"
}
function trap___activate() {
    # local l_trap___internal_sig_spec
    
    # keep for debugging!
    # __trap___derive_internal_signal_spec l_trap___internal_sig_spec "$1"
    # local g_trap___reinstall_cmd_line_var_name="g_trap___reinstall_cmd_line_${l_trap___internal_sig_spec}"
    
    # local -n l_trap___reinstall_cmd_line="$g_trap___reinstall_cmd_line_var_name"
    # log_str_var "$g_trap___reinstall_cmd_line_var_name"
    # log_str_var l_trap___reinstall_cmd_line
    # eval "$l_trap___reinstall_cmd_line"
    # unset "$g_trap___reinstall_cmd_line_var_name"
    
    if [[ "$1" == SIG* ]] ; then
        local l_trap___internal_sig_spec="${1//+/_plus_}"
        trap "__trap___execute_cmds ${l_trap___internal_sig_spec//-/_minus_}" "$1"
    else
        trap "__trap___execute_cmds_with_EXIT_STATUS $1" "$1"
    fi
}

function trap___no_ERR() {
    if "$@" ; then
        return "$?"
    fi
    return "$?"
}

# $@ - signal names
function __print_trap_cmds() {
    for l_trap___internal_sig_spec in "$@" ; do
        l_trap___internal_sig_spec="${l_trap___internal_sig_spec//+/_plus_}"
        l_trap___internal_sig_spec="${l_trap___internal_sig_spec//-/_minus_}"
        echo "installed cmds for ${l_trap___internal_sig_spec} signal:"
        local -n l_trap___cmds="m_trap___cmds_${l_trap___internal_sig_spec}"
        local -i l_i=0
        for l_trap___cmd in "${l_trap___cmds[@]}" ; do
            printf "%d. %s\n" "$(( ++l_i ))" "$l_trap___cmd"
        done
    done
}

# $@ - signal names
# if absent, prints the cmds for all signals, with installed traps
function print_trap_cmds() {
    if (( $# > 0 )) ; then
        __print_trap_cmds "$@"
    else
        __print_trap_cmds "${m_trap___signals_with_installed_traps[@]}"
    fi
}
# declares log_trap_cmds(), debug_trap_cmds(), trace_trap_cmds()
declare_debug_funcs_from_print_func print_trap_cmds

# ===== Install Informative Traps for Important Real Signals ====================

function __trap___default_sigtstp() {
    if [[ ! "$-" =~ "i" ]] ; then
        echo # extra line to seperate in mixing output from multiple processes
        user_msg <<__end__
${wrapper_name}: halting, because SIGTSTP received
${wrapper_name}: thus waiting for SIGCONT
${wrapper_name}: Do not forget to continue this process !
${wrapper_name}: e.g. by the following
${wrapper_name}: $ kill -s SIGCONT $BASHPID
__end__
        echo # extra line to seperate in mixing output from multiple processes
        suspend -f
    fi
}

function __trap___default_sigcont() {
    # if [[ ! "$-" =~ "i" ]] ; then
        echo # extra line to seperate in mixing output from multiple processes
        user_msg <<__end__
${wrapper_name}: continue, because SIGCONT received
__end__
        echo # extra line to seperate in mixing output from multiple processes
    # fi
}

function __trap___default_sigterm() {
    user_msg <<__end__
${wrapper_name}: SIGTERM received
${wrapper_name}: I will also execute the ERR_EXIT and EXIT trap.
__end__
    exit 1
}

function __trap___default_sigint() {
    user_msg <<__end__
${wrapper_name}: SIGINT received
${wrapper_name}: I will also execute the ERR_EXIT and EXIT trap.
__end__
    exit 1
}

function __trap___default_sigquit() {
    user_msg <<__end__
${wrapper_name}: SIGQUIT received
${wrapper_name}: I will also execute the ERR_EXIT and EXIT trap.
__end__
    exit 1
}

function __trap___default_sighup() {
    user_msg <<__end__
${wrapper_name}: SIGHUP received
${wrapper_name}: I will also execute the ERR_EXIT and EXIT trap.
__end__
    exit 1
}


function install_default_traps_for_jobcontrol_signals() {
    trap___install_cmd SIGTSTP "__trap___default_sigtstp"
    trap___install_cmd SIGCONT "__trap___default_sigcont"
    # It does not seems so, that bash executes the SIGCONT trap
    trap___install_cmd SIGINT  "__trap___default_sigint"
    trap___install_cmd SIGTERM "__trap___default_sigterm"
    trap___install_cmd SIGQUIT "__trap___default_sigquit"
    trap___install_cmd SIGHUP  "__trap___default_sighup"
}

install_default_traps_for_jobcontrol_signals
