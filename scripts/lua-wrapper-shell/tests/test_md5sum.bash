#!/usr/bin/env bash

declare wrapper_modules_dir="../modules"

declare -i debug_level=0

source "${wrapper_modules_dir}/main_init.bash"

exec_module ext_cmds
exec_module md5sum


# $1 - filename
function test_case_file() {
    printf "\ntest_case_file %s\n" "$1"
    
    local l_test___res_md5sum
    time md5___calc_sum_of_file l_test___res_md5sum "$1"
    
    local l_test___exp_md5sum="$(time command md5sum "$1")"
    # strip the longest suffix beginning with a space
    l_test___exp_md5sum="${l_test___exp_md5sum%% *}"
    
    printf "l_test___res_md5sum == %s
l_test___exp_md5sum == %s
" "$l_test___res_md5sum" "$l_test___exp_md5sum"
}

# $1 - string
function test_case_str() {
    printf "\ntest_case_str %s\n" "${1@Q}"
    
    local l_test___res_md5sum
    md5___calc_sum_of_str l_test___res_md5sum "$1"
    
    local l_test___exp_md5sum="$(printf "%s" "$1" | command md5sum)"
    # strip the longest suffix beginning with a space
    l_test___exp_md5sum="${l_test___exp_md5sum%% *}"
    
    printf "l_test___res_md5sum == %s
l_test___exp_md5sum == %s
" "$l_test___res_md5sum" "$l_test___exp_md5sum"
}

test_case_str ""
test_case_str "abc"
test_case_str "Hello"$'\n'"World!"$'\n'
test_case_str "ÄäÜüÖößµ€§``´´"

test_case_file <(echo -n)
test_case_file <(printf "\x00") # Our implementation seems to be more correct than the md5sum utility.
                                # If compared to the reference implementation from RFC 1321
test_case_file test_md5sum.txt
test_case_file <(echo "
abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
") # This is approximately the amount of chars where our implementation is as fast as the md5sum utility.
test_case_file test_md5sum.bash

exit 0
