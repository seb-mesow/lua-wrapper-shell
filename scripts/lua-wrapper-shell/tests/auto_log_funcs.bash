#!/usr/bin/env bash

declare -i debug_level=1

source ../modules/auxillary.bash
source ../modules/print.bash

# log_str_var dummy

set +m # disable jobcontrol
shopt -s lastpipe # enable lastpipe in current shell context
declare -p -F | mapfile l___funcs

# print_indexed_array_quoted l___funcs

declare -a l___print_funcs
local -i l___i
for (( l___i=0 ; l_i < "${#l___funcs[@]}" ; l_i++ )) ; do
    declare l___func="${l___funcs[l_i]}"
    if [[ "$l___func" =~ ^"declare -f print_" ]] ; then
        l___func="${l___func#"${BASH_REMATCH[0]}"}"
        l___print_funcs+=("_${l___func%$'\n'}")
    fi
done

# print_indexed_array_quoted l___print_funcs

               log_func_fmt=$'function log%s() {\n'
log_func_fmt="$log_func_fmt"$'    if (( debug_level > 1 )) ; then\n'
log_func_fmt="$log_func_fmt"$'        print%s "$@" >&2\n'
log_func_fmt="$log_func_fmt"$'    fi\n'
log_func_fmt="$log_func_fmt"$'}\n'

assign_long_str log_func_fmt <<__end__
function log\${l___print_func}() {
    if (( debug_level > 0 )) ; then
        print\${l___print_func} \\\"\\\\\$@\\\" >&2
    fi
}
__end__

print_long_str_var log_func_fmt

for l___print_func in "${l___print_funcs[@]}" ; do
    eval "func_decl=\"$log_func_fmt\""
    print_long_str_var func_decl
    eval "$func_decl"
done

# declare -p -f

dummy="DUMMY"

log_str_var dummy

exit 0
