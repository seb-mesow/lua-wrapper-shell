#!/usr/bin/env bash

# ========== Auxillary Functions needed for Initalization ====================

# splits a filepath in the dirname and a filename
# returns a zero exit status, if the file_path is valid
#
# arguments:
# $1 - varname for dirpath
# $2 - varname for filename
# $3 - filepath
function split_filepath() {
    if [[ "$3" =~ ^((.*)[/\\])?([^/\\]+)$ ]] ; then
        if [[ "$1" != "l_split_filepath___dir" ]] ; then
            local -n l_split_filepath___dir="$1"
        fi
        if [[ "$2" != "l_split_filepath___filename" ]] ; then
            local -n l_split_filepath___filename="$2"
        fi
        
        l_split_filepath___dir="${BASH_REMATCH[2]}"
        l_split_filepath___filename="${BASH_REMATCH[3]}"
    else
        echo "
Internal Error: at split_filepath():
Internal Error: invalid filepath
Internal Error: '$3'"
        exit 1
    fi
}

declare wrapper_modules_dir="../modules"

declare -i debug_level=0

source "${wrapper_modules_dir}/main_init.bash"

exec_module config_read


function column_numbers() {
    local -i l_i
    for (( l_i=0 ; l_i <= l_lines_width ; l_i++ )) ; do
        echo -n " "
    done
    for (( l_i=1 ; l_i < 50 ; l_i++ )) ; do
        printf "%d" $(( l_i % 10 ))
    done
    echo
}
    

# $1 - test case name
function test_case() {
    echo
    echo "========== $1 ===================="
    mapfile -O 1
    local l_test_file_contents=
    local -i l_line_num=1
    local -i l_lines=${#MAPFILE[@]}
    if (( l_lines >= 10 )) ; then
        local -i l_lines_width=2
    else
        local -i l_lines_width=1
    fi
    column_numbers
    while (( l_line_num <= l_lines )) ; do
        l_test_file_contents="$l_test_file_contents${MAPFILE[l_line_num]}"
        printf "%*d %s" $l_lines_width $l_line_num "${MAPFILE[l_line_num++]}"
    done
    MAPFILE=()
    column_numbers
    printf "==============================\n"
    
    local -a l_config_keys l_config_vals
    two_arrays_from_config_str \
            l_config_keys l_config_vals \
            "$l_test_file_contents"
    
    echo
    printf "%s\n" "------------------------------"
    print_two_arrays_quoted l_config_keys l_config_vals
    printf "%s\n" "------------------------------"
}

function test_case___simple() {
    test_case "simple" <<'__end__'
# comment
key00=value_00# comment
             # comment
key 11 = value 11# comment
                 # comment
# comment

'key 22' = 'value 22'# comment


"key 33" = "value 33"# comment
$'key 44' = $'value 44'# comment

key 55 = "value with #comment"
key 66 = $'value with #comment'

# comment


__end__
}

function test_case___backslash() {
    test_case "backslash sequences" <<'__end__'
key0\ 0=value_0\"0\##comment
key\ 1\\1 = value\ 1\$''1
'key 2\2' = 'value 22$$$#'
"key 3\"3" = "value 3\$'#3it follows 4 spaces\    end"
"key 4\"4" = "value 4\$'#4 with two trailing spaces\  "
"key 5\"5" = "value 5$$$5 with three dollar signs"
$'key 6\e6' = $'value 6\n6#'
$'key 7\e7' = $'value 7\n7# with two trailing spaces\  '
__end__
}

function test_case___ansi_c_escaping() {
    test_case___ansi_c_escaping___common_sequences
    test_case___ansi_c_escaping___octal
    test_case___ansi_c_escaping___hexadecimal
    test_case___ansi_c_escaping___short_unicode
    test_case___ansi_c_escaping___long_unicode
    test_case___ansi_c_escaping___control_chars
}
function test_case___ansi_c_escaping___common_sequences() {
    test_case "ANSI C escaping - common sequences" <<'__end__'
alert_bell=$'-\a-'
back_space=$'-\b-'
escape=$'-\e-'
Escape=$'-\E-'
form_feed=$'-\f-'
linefeed=$'-\n-'
carrige_return=$'-\r-'
horizontal_tab=$'-\t-'
vertical_tab=$'-\v-'
backslash=$'-\\-'
single_quote=$'-\'-'
double_quote=$'-\"-'
question_mark=$'-\?-'
# relevant for line continuation implemenation
space=$'\ '
space_a=$'\ a'
spaces_2=$'\  '
__end__
}

function test_case___ansi_c_escaping___octal() {
    test_case "ANSI C escaping - octal" <<'__end__'
octal_1_004=$'-\4-'
octal_2_procent_mark=$'-\45-' # \45 gives procent mark
octal_3_procent_mark=$'-\045-' # \045 gives procent mark
octal_4_lowercase_e=$'-\1456-' # \145 gives lowercase e
                               # last '6' does not belong to codepoint
__end__
}

function test_case___ansi_c_escaping___hexadecimal() {
    test_case "ANSI C escaping - hexadecimal" <<'__end__'
hexadecimal_1_backspace=$'-\x8-' # \x8 gives backspace
hexadecimal_2_uppercase_Q=$'-\x51-' # \x81 gives uppercase Q 
hexadecimal_3_uppercase_Q=$'-\x511-' # \x81 gives uppercase Q
                                     # last '1' does not belong to codepoint
__end__
}

function test_case___ansi_c_escaping___short_unicode() {
    test_case "ANSI C escaping - short Unicode" <<'__end__'
short_unicode_1_linefeed=$'-\uA-' # \uA gives line feed
short_unicode_2_latin_small_letter_a_with_diaeresis=$'-\uE4-' # \uE4 gives 'ä'
short_unicode_4_trademark_sign=$'-\u2122-' # \u2122 gives trademark sign
short_unicode_5_trademark_sign=$'-\u2122A-' # \u2122 gives trademark sign
                                           # last 'A' does not belong to codepoint
__end__
}

function test_case___ansi_c_escaping___long_unicode() {
    test_case "ANIS C escaping - long Unicode" <<'__end__'
long_unicode_1_linefeed=$'-\UA-' # \uA gives line feed
long_unicode_2_latin_small_letter_a_with_diaeresis=$'-\UE4-' # \UE4 gives 'ä'
long_unicode_4_trademark_sign=$'-\U2122-' # \U2122 gives trademark sign
long_unicode_7_360_237_236_205=$'-\U001F785-'   #  \U001F785 gives medium bold white circle
long_unicode_8_360_237_236_205=$'-\U0001F785-'  # \U0001F785 gives medium bold white circle
long_unicode_9_360_237_236_205=$'-\U0001F785D-' # \U0001F785 gives medium bold white circle
                                                # which is 360 237 236 205 in octal UTF-8
__end__
}

function test_case___ansi_c_escaping___control_chars() {
    test_case "ANSI C escaping - control chars" <<'__end__'
control_char_1_line_feed=$'\cJ' # \cJ gives line feed
control_char_2_line_feed=$'\cJJ' # \cJ gives line feed
                                 # last 'J' does not belong to control_char
__end__
}

function test_case___line_continuation() {
    test_case___line_continuation___unquoted
    test_case___line_continuation___double_quoted
    test_case___line_continuation___ansi_c_escaping
}

function test_case___line_continuation___unquoted() {
    test_case "line continuation - unquoted" <<'__end__'
# The next line must not contain trailing whitespace !!
key1 = very_very_\
    very_very_long_value1
# The next line must contain trailing whitespace !!
key2 = very_very_\    
    very_very_long_value2
# The next line must contain trailing comments seperated by whitespace
key3 = very_very_\ # comment
    very_very_long_value3
# The next line must not contain trailing whitespace !!
very_very_long_key4 = \
    very_very_very_very_long_value4
# The next line must contain trailing whitespace !!
very_very_long_key5 = \    
    very_very_very_very_long_value5
# The next line must contain trailing comments seperated by whitespace
very_very_long_key6 = \ # comment
    very_very_very_very_long_value6
# multiple line continuation test
key7 = many1 many2 ma\ # comment
    ny3 many4 many5 \ # comment
many6 many7 values7
__end__
}

function test_case___line_continuation___double_quoted() {
    test_case "line continuation - double quoted" <<'__end__'
# line continuation in double quoted test
key8 = "This is o\ # comment
        ne value." # comment
key 9 = "This value is\ #choped"
        "
key 10 = "This value is\ \#not choped"
__end__
}

function test_case___line_continuation___ansi_c_escaping() {
    test_case "line continuation - ANSI C escaping" <<'__end__'
# line continuation in ANSI C escaping test
key8 = $'This is o\ # comment
         ne value.' # comment
key 9 = $'This value is\ #choped'
        '
key 10 = $'This value is\ \#not choped'
__end__
}

function test_case___error___unfinished_assignent() {
    test_case "error - unfinished assignment" <<'__end__'
key # comment
__end__
}

function test_case___error___extra_equal_sign() {
    test_case "error - extra equal sign" <<'__end__'
key=value \  # comment
        val=ue2
__end__
}

function test_case___error___line_begins_with_equal_sign() {
    test_case "error - extra equal sign" <<'__end__'
=value # comment
__end__
}

test_case___simple
test_case___backslash
test_case___ansi_c_escaping
test_case___line_continuation

# test_case___error___unfinished_assignent
# test_case___error___extra_equal_sign
# test_case___error___line_begins_with_equal_sign

exit 0