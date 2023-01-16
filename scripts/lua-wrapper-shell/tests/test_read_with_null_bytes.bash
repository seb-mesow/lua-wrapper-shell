#!/usr/bin/env bash

declare wrapper_modules_dir="../modules"

declare -i debug_level=3

source "${wrapper_modules_dir}/main_init.bash"

# exec_module ext_cmds
# exec_module md5sum

# declare m_test___temp_filepath
# temp_filepath m_test___temp_filepath

# $1 - filename
function test_case() {
    # echo "${#1}"
    local -a my_array=()
    local -i index
    LANG=C
    IFS= # needed for correctly reading newlines as the last char
    while read -r -d "" my_null_terminated_str ; do
        echo "my_null_terminated_str == ${my_null_terminated_str@Q}"
        local -i l_index=0
        # echo 
        for (( l_index=0 ; l_index < "${#my_null_terminated_str}" ; l_index++ )) ; do
            printf " %d" "$(( ++index ))"
            my_array+=("${my_null_terminated_str:l_index:1}")
        done
        printf " %d" "$(( ++index ))"
        echo
        my_array+=("")
    done < "$1"
    echo "my_null_terminated_str == ${my_null_terminated_str@Q}"
    # echo 
    for (( l_index=0 ; l_index < "${#my_null_terminated_str}" ; l_index++ )) ; do
        printf " %d" "$(( ++index ))"
        my_array+=("${my_null_terminated_str:l_index:1}")
    done
    echo
    
    # <<< "$1" # here string ALWAYS appends a line feed; no matter if yet trailing
    local -i my_array_len="${#my_array[@]}"
    printf "my_array_len == %d\n" "$my_array_len"
}

test_case test_md5sum.txt

exit 0
