exec_module log
exec_module ANSI

# $1 - exception ID
# $2 - description of barrier
function exc___raise() {
    if [[ -z "$1" ]] ; then
        internal_err "missing exception ID"
    fi
    if [[ -z "$2" ]] ; then
        internal_err "missing description of barrier for exception $1"
    fi
    
    declare -g EXCEPTION_ID="$1" \
               EXCEPTION_CALLSTACK
    
    declare -g -A EXCEPTION
    EXCEPTION["barrier"]="$2"
    
    exec_module callstack
    
    # if (( debug_level > 2 )) ; then
        CS___snapshot EXCEPTION_CALLSTACK
    # fi
    
    logf "raise exception %s\n    barrier:\n%s" "$1" "$2"
    if (( debug_level > 2 )) ; then
        CS___show_compact "$EXCEPTION_CALLSTACK" 1>&2
    fi
}

# ========== Functions to Use in Catch Blocks ====================

function exc___ignore() {
    logf "ignore exception %s" "$EXCEPTION_ID"
    
    CS___delete "$EXCEPTION_CALLSTACK"
    
    unset EXCEPTION_ID \
          EXCEPTION \
          EXCEPTION_CALLSTACK
}

function exc___unhandled() {
    internal_err "unhandled exception ${EXCEPTION_ID}"
}

function exc___assert_no_unhandled() {
    if [[ -v EXCEPTION_ID ]] ; then
        exc___unhandled
    fi
}

# $1 - description of context/command and reason
# $2 - help
function exc___user_err() {
    if [[ -z "$1" ]] ; then
        internal_err \
"missing or empty description of context/command and reason for exc___user_err()"
    fi
    if [[ -z "$2" ]] ; then
        internal_err \
"missing or empty help for exc___user_err()"
    fi
    
    if ((debug_level > 0 )) ; then
        user_errf_no_abort "${ANSI___seq___warning}context/command and reason:\n%s${ANSI___seq___end}" "$1"
        logf "barrier:\n%s" "${EXCEPTION["barrier"]}"
        user_errf "help:\n$2"
    else
        user_errf "${ANSI___seq___warning}%s${ANSI___seq___end}\n\n%s" "$1" "$2"
    fi
    
    exc___ignore
}

# $1 - description of context/command and reason
# $2 - help
function exc___user_msg() {
    if [[ -z "$1" ]] ; then
        internal_err \
"missing or empty description of context/command and reason for exc___user_msg()"
    fi
    if [[ -z "$2" ]] ; then
        internal_err \
"missing or empty help for exc___user_msg()"
    fi
    
    if (( debug_level > 0 )) ; then
        user_msgf "${ANSI___seq___warning}context/command and reason:\n%s${ANSI___seq___end}" "$1"
        logf "barrier:\n%s" "${EXCEPTION["barrier"]}"
        user_msgf "help:\n%s" "$2"
    else
        user_msgf "${ANSI___seq___warning}%s${ANSI___seq___end}\n\n%s" "$1" "$2"
    fi
    
    exc___ignore
}
