# ========== Printing Auxillary ====================

# determinates the max len of all its args
#  $1     - res int var name
# [$2...] - args
function __print___max_len() {
    if [[ "$1" != "l_print___max_len" ]] ; then
        local -n l_print___max_len="$1"
    fi
    shift
    l_print___max_len=0
    local l_print___arg
    for l_print___arg in "$@" ; do
        if (( "${#l_print___arg}" > l_print___max_len )) ; then
            l_print___max_len="${#l_print___arg}"
        fi
    done
}

# default callback:
# $1 - res str var name
# $2 -  str val
function __print___format_str_default() {
    if [[ "$1" != "l_print___ret_str" ]] ; then
        local -n l_print___ret_str="$1"
    fi
    l_print___ret_str="$2"
}

# ========== Printing Values ====================

# The print_*_custom functions take a callback, which formats a str value.
# These callback is called with a name for a variable,
# the formatted value must be stored into, and the string value

# ========== Integers ====================

# $1 - int var name
function print_int_var() {
    if [[ "$1" != "l_print___int_var" ]]; then
        local -n l_print___int_var="$1"
    fi
    echo "$1 == $l_print___int_var"
}

# ========== Strings ====================

# $1 - callback func name to format a str val
# $2 - str var name
function print_str_var_custom() {
    if [[ "$2" != "l_print___str_var" ]]; then
        local -n l_print___str_var="$2"
    fi
    local l_print___str
    "$1" l_print___str "$l_print___str_var"
    echo "$2 == $l_print___str"
}

# $1 - str var name
function print_str_var() {
    print_str_var_custom __print___format_str_default "$@"
}
function print_str_var_quoted() {
    print_str_var_custom bash_word_from_str "$@"
}


# ========== PATH-like strings ====================

# $1 - callback func name to format a str val
# $2 - PATH-like var name
# $3 - path sep in $2
function print_paths_var_custom() {
    local l_print___path_sep_fmt \
          l_print___path
    bash_word_from_str l_print___path_sep_fmt "$3"
    printf "%s ==        (PATH-like var with %s as sep)\n" \
            "$2" "$l_print___path_sep_fmt"
    if [[ "$2" != "l_print___paths_like_var" ]] ; then
        local -n l_print___paths_like_var="$2"
    fi
    local -a l_print___paths
    split_str l_print___paths "$l_print___paths_like_var" "$3"
    if (( show_additonal_paths_as_win )) ; then
        convert_paths_to_win l_print___paths l_print___paths
    fi
    for l_print___path in "${l_print___paths[@]}" ; do
        "$1" l_print___path "$l_print___path"
        echo "    $l_print___path"
    done
}

# $1 - PATH-like var name
# $2 - path sep in $1
function print_paths_var() {
    print_paths_var_custom __print___format_str_default "$@"
}

# ========== Indexed Arrays ====================

#  $1  - callback func name to format a str val
#  $2  - var name of an assoc (thus not indexed) array
# [$3] - actual var name to print
function print_indexed_array_custom() {
    echo "${3:-$2} =="
    if [[ "$2" != "l_print___array" ]] ; then
        local -n l_print___array="$2"
    fi
    local -i l_print___max_len
    __print___max_len l_print___max_len "${!l_print___array[@]}"
    local l_print___subscript \
          l_print___val
    for l_print___subscript in "${!l_print___array[@]}" ; do
        "$1" l_print___val "${l_print___array["$l_print___subscript"]}"
        printf "   [%*s] == %s\n" "$l_print___max_len" "$l_print___subscript" "$l_print___val"
    done
}

#  $1  - var name of an indexed (thus not associative) array
# [$2] - actual var name to print
function print_indexed_array() {
    print_indexed_array_custom __print___format_str_default "$@"
}
function print_indexed_array_quoted() {
    print_indexed_array_custom bash_word_from_str "$@"
}

# ========== Arrays Common ====================

#  $1  - callback func name to format the subscripts, keys and vals
#        <callback> <ret str var name> <str>
#  $2  - callback func name to format a key-value pair of two assoc   arrays on one line
#  $3  - callback func name to format a key-value pair of two assoc   arrays with wrapping
#        <callback> <ret str var name> \
#               <subscripts max len> <subscript> \
#               <fmt keys max len>   <fmt key> \
#                                    <fmt val>
#  $4  - callback func name to format a key-value pair of two indexed arrays on one line
#  $5  - callback func name to format a key-value pair of two indexed arrays with wrapping
#        <callback> <ret str var name> \
#               <fmt subscripts max len> <fmt subscript> \
#               <fmt keys max len>       <fmt key> \
#                                        <fmt val>
#  $6  - var name of indexed array with unformatted keys
#  $7  - var name of indexed array with unformatted values
# [$8] - callback func name to print a leading line
#        <callback>
#        can use l_print___are_assoc_arrays from calling context
function __print___two_arrays_pairs() {
    if [[ "$6" != "l_print___keys" ]] ; then
        local -n l_print___keys="$6"
    fi
    if [[ "$7" != "l_print___vals" ]] ; then
        local -n l_print___vals="$7"
    fi
    
    local -i l_print___max_subscript_len=0 \
             l_print___max_key_len=0 \
             l_print___are_assoc_arrays=0
    
    local -A l_print___fmt_subscripts \
             l_print___fmt_keys \
             l_print___fmt_vals
    
    local l_print___subscript\
          l_print___fmt_subscript \
          l_print___fmt_key \
          l_print___fmt_val \
          l_print___fmt_pair
    
    for l_print___subscript in "${!l_print___keys[@]}" ; do
        "$1" l_print___fmt_subscript "$l_print___subscript"
        "$1" l_print___fmt_key       "${l_print___keys["$l_print___subscript"]}"
        "$1" l_print___fmt_val       "${l_print___vals["$l_print___subscript"]}"
        l_print___fmt_subscripts["$l_print___subscript"]="$l_print___fmt_subscript"
              l_print___fmt_keys["$l_print___subscript"]="$l_print___fmt_key"
              l_print___fmt_vals["$l_print___subscript"]="$l_print___fmt_val"
        if (( "${#l_print___fmt_subscript}" > l_print___max_subscript_len )) ; then
            l_print___max_subscript_len="${#l_print___fmt_subscript}"
        fi
        if (( "${#l_print___fmt_key}" > l_print___max_key_len )) ; then
            l_print___max_key_len="${#l_print___fmt_key}"
        fi
        if (( ! l_print___are_assoc_arrays )) \
        && [[ "$l_print___fmt_subscript" =~ [^[:digit:]] ]]
        then
            l_print___are_assoc_arrays=1
        fi
    done
    
    if [[ -v 8 ]] ; then
        "$8"
    fi
    
    if (( l_print___are_assoc_arrays )) ; then
        
        declare -A l_print___fmt_pairs
        for l_print___subscript in "${!l_print___fmt_keys[@]}" ; do
            "$2" l_print___fmt_pair \
                "$l_print___max_subscript_len"  "${l_print___fmt_subscripts["$l_print___subscript"]}" \
                "$l_print___max_key_len"              "${l_print___fmt_keys["$l_print___subscript"]}" \
                                                      "${l_print___fmt_vals["$l_print___subscript"]}"
            l_print___fmt_pairs["$l_print___subscript"]="$l_print___fmt_pair"
            
            if (( "${#l_print___fmt_pair}" > "$COLUMNS" )) ; then
                l_print___fmt_pairs=()
                for l_print___subscript in "${!l_print___fmt_keys[@]}" ; do
                    "$3" l_print___fmt_pair \
                        "$l_print___max_subscript_len"  "${l_print___fmt_subscripts["$l_print___subscript"]}" \
                        "$l_print___max_key_len"              "${l_print___fmt_keys["$l_print___subscript"]}" \
                                                              "${l_print___fmt_vals["$l_print___subscript"]}"
                    l_print___fmt_pairs["$l_print___subscript"]="$l_print___fmt_pair"
                done
                break
            fi
            
        done
        
    else # indexed arrays
        
        declare -a l_print___fmt_pairs
        for l_print___subscript in "${!l_print___fmt_keys[@]}" ; do
            "$4" l_print___fmt_pair \
                "$l_print___max_subscript_len"  "$l_print___subscript" \
                "$l_print___max_key_len"        "${l_print___fmt_keys["$l_print___subscript"]}" \
                                                "${l_print___fmt_vals["$l_print___subscript"]}"
            l_print___fmt_pairs["$l_print___subscript"]="$l_print___fmt_pair"
            
            if (( "${#l_print___fmt_pair}" > "$COLUMNS" )) ; then
                l_print___fmt_pairs=()
                for l_print___subscript in "${!l_print___fmt_keys[@]}" ; do
                    "$5" l_print___fmt_pair \
                        "$l_print___max_subscript_len"  "$l_print___subscript" \
                        "$l_print___max_key_len"        "${l_print___fmt_keys["$l_print___subscript"]}" \
                                                        "${l_print___fmt_vals["$l_print___subscript"]}"
                    l_print___fmt_pairs["$l_print___subscript"]="$l_print___fmt_pair"
                done
                break
            fi
            
        done

    fi
    
    for l_print___fmt_pair in "${l_print___fmt_pairs[@]}" ; do
        printf "%s\n" "$l_print___fmt_pair"
    done
}


# ========== Associative Arrays ====================

#  $1  - callback func name to format a str val
#  $2  - var name of an assoc (thus not indexed) array
# [$3] - actual var name to print
function print_assoc_array_custom() {
    echo "${3:-$2}"
    
    if [[ "$2" != "l_print___array" ]] ; then
        local -n l_print___array="$2"
    fi
    
    local -a l_print___keys=("${!l_print___array[@]}") \
             l_print___vals=("${l_print___array[@]}")
    
    __print___two_arrays_pairs "$1" \
        __print___THIS_CALLBACK_SHOULD_NOT_BE_CALLED \
        __print___THIS_CALLBACK_SHOULD_NOT_BE_CALLED \
        __print___assoc_array___key_value_pair___not_wrap \
        __print___assoc_array___key_value_pair___wrap \
        l_print___keys l_print___vals
}
# $1 - ret str var name
# $2 - subscripts max len
# $3 - subscript
# $4 - fmt keys max len
# $5 - fmt key
# $6 - fmt val
function __print___assoc_array___key_value_pair___not_wrap() {
    printf -v "$1" "    [%*s] == %s" "$4" "$5" "$6"
}
function __print___assoc_array___key_value_pair___wrap() {
    printf -v "$1" "    [%s] ==\n        %s" "$5" "$6"
}

#  $1  - var name of an assoc (thus not indexed) array
# [$2] - actual var name to print
function print_assoc_array() {
    print_assoc_array_custom __print___format_str_default "$@"
}
function print_assoc_array_quoted() {
    print_assoc_array_custom bash_word_from_str "$@"
}

# ========== Two Arrays ====================

#  $1  - callback func name to format a str val
#  $2  - var name of an (indexed) array with the keys
#  $3  - var name of an (indexed) array with the vals
# [$4] - actual var name to print for the array with the keys
# [$5] - actual var name to print for the array with the vals
function print_two_arrays_custom() {
    printf "%s / %s ==        " "${4:-$2}" "${5:-$3}"
    
    __print___two_arrays_pairs "$1" \
        __print___two_arrays___key_value_pair___assoc_array___not_wrap \
        __print___two_arrays___key_value_pair___assoc_array___wrap \
        __print___two_arrays___key_value_pair___indexed_array___not_wrap \
        __print___two_arrays___key_value_pair___indexed_array___wrap \
        "$2" "$3" \
        __print___two_arrays___leading_line
}
# uses l_print___are_assoc_arrays from calling context
function __print___two_arrays___leading_line() {
    if (( l_print___are_assoc_arrays)) ; then
        echo "(one assoc array as two assoc arrays)"
    else
        echo "(assoc array as two indexed arrays)"
    fi
}
# $1 - ret str var name
# $2 - fmt subscripts max len
# $3 - fmt subscript
# $4 - fmt keys max len
# $5 - fmt key
# $6 - fmt val
function __print___two_arrays___key_value_pair___assoc_array___not_wrap() {
    printf -v "$1" "  (%*s) [%*s] == %s" "$2" "$3" "$4" "$5" "$6"
}
function __print___two_arrays___key_value_pair___assoc_array___wrap() {
    printf -v "$1" "  (%*s) [%s] ==\n        %s" "$2" "$3" "$5" "$6"
}
# $1 - ret str var name
# $2 - subscripts max len
# $3 - subscript
# $4 - fmt keys max len
# $5 - fmt key
# $6 - fmt val
function __print___two_arrays___key_value_pair___indexed_array___not_wrap() {
    printf -v "$1" "  (%*d) [%*s] == %s" "$2" "$3" "$4" "$5" "$6"
}
function __print___two_arrays___key_value_pair___indexed_array___wrap() {
    printf -v "$1" "  (%*d) [%s] ==\n        %s" "$2" "$3" "$5" "$6"
}

#  $1  - var name of an (indexed) array with the keys
#  $2  - var name of an (indexed) array with the vals
# [$3] - actual var name to print for the array with the keys
# [$4] - actual var name to print for the array with the vals
function print_two_arrays() {
    print_two_arrays_custom __print___format_str_default "$@"
}
function print_two_arrays_quoted() {
    print_two_arrays_custom bash_word_from_str "$@"
}

# ========== File Contents ====================

#  $1  - filepath
# [$2] - filepath to show
function print_file_contents() {
    if [[ -e "$1" ]] ; then
        echo "========== ${2:-$1} =========="
        cat "$1"
        echo "=================================================="
    else
        echo "file ${2:-$1} does not exist"
    fi
}

# ========== Long Strings ====================

#  $1  - var name
# [$2] - var name to show
function print_long_str_var() {
    if [[ "$1" != "l_print___long_str" ]] ; then
        local -n l_print___long_str="$1"
    fi
    local -a l_print___lines
    split_str l_print___lines "$l_print___long_str" $'\n'
    local -i l_print___index \
             l_print___lines_cnt="${#l_print___lines[@]}"
    
    echo "========== ${2:-$1} =========="
    echo "==================== (special characters escaped) =========="
    if (( l_print___lines_cnt > 0 )) ; then
        local l_print___line
        l_print___line="${l_print___lines[0]}"
        printf -v l_print___line "%q" "${l_print___lines[0]}"$'\a' # provoke ANSI C escaping
        printf "%s" "${l_print___line:2:-3}" # $'...\a'
        for (( l_print___index=1 ; \
               l_print___index < l_print___lines_cnt ; \
               l_print___index++ ))
        do
            printf -v l_print___line "%q" "${l_print___lines[l_print___index]}"$'\a'
            printf "\n%s" "${l_print___line:2:-3}" # $'...\a'
        done
        if [[ "${l_print___lines[l_print___lines_cnt-1]}" ]] ; then
            echo "# STRING DOES NOT END WITH A LINE FEED"
        fi
    fi
    echo "============================================================"
}
