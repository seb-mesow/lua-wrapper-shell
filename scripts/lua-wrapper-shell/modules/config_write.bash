# takes an associative array and assigns a string to the provided variable
# which can be read with assoc_array_from_config_str()
# (or two_arrays_from_config_str() )
# to reproduce the associative array.
# The order of the key-value pairs in the generated string
# is arbitrary.
#
# arguments:
# $1 - varname to assign the formatted str to
# $2 - varname of an associative array
function config_str_from_assoc_array() {
    if [[ "$1" != "l_cw___cfg_str" ]] ; then
        local -n l_cw___cfg_str="$1"
    fi
    if [[ "$2" != "l_cw___array" ]] ; then
        local -n l_cw___array="$2"
    fi
    local l_cw___key \
          l_cw___val
    for l_cw___key in "${!l_cw___array[@]}" ; do
        config_word_from_str l_cw___val "${l_cw___array["$l_cw___key"]}"
        config_word_from_str l_cw___key "$l_cw___key"
        # assoc_array_from_config_str() is tough enough to read ANSI C escaping strings from bash
        printf -v l_cw___cfg_str "%s%s=%s\n" \
            "$l_cw___cfg_str" "$l_cw___key" "$l_cw___val"
    done
}

# takes two (indexed) arrays and assigns a string to the provided variable
# which can be read with two_arrays_from_config_str()
# (or assoc_array_from_config_str() )
# to reproduce the two arrays.
# The order of the key-value pairs in the generated string
# is the order of the keys in the first indexed array,
# if the first indexed array is an indexed array.
#
# arguments:
# $1 - varname to assign the formatted str to
# $2 - varname of an (indexed) array with the keys
# $3 - varname of an (indexed) array with the values
function config_str_from_two_arrays() {
    if [[ "$1" != "l_cw___cfg_str" ]] ; then
        local -n l_cw___cfg_str="$1"
    fi
    if [[ "$2" != "l_cw___keys" ]] ; then
        local -n l_cw___keys="$2"
    fi
    if [[ "$3" != "l_cw___vals" ]] ; then
        local -n l_cw___vals="$3"
    fi
    local l_cw___key \
          l_cw___val
    for l_cw___key in "${!l_cw___keys[@]}" ; do
        config_word_from_str l_cw___val "${l_cw___vals["$l_cw___key"]}"
        config_word_from_str l_cw___key "${l_cw___keys["$l_cw___key"]}"
        # assoc_array_from_config_str() is tough enough to read ANSI C escaping strings from bash
        printf -v l_cw___cfg_str "%s%s=%s\n" \
            "$l_cw___cfg_str" "$l_cw___key" "$l_cw___val"
    done
}

# $1 - ret str var name
# $2 - string
function config_word_from_str() {
    if [[ "$1" != "l_cw___cfg_word" ]] ; then
        local -n l_cw___cfg_word="$1"
    fi
    if [[ "$2" =~ [[:cntrl:]] ]] ; then
        # includes newline and tab, but excludes space
        # provoke ANSI C escaping
        printf -v l_cw___cfg_word "%q" "$2"$'\n'
        l_cw___cfg_word="${l_cw___cfg_word:0:-3}'"
    elif [[ "$2" =~ "'" ]] ; then
        # double quotes with escaping
        # in double quotes the following two chars must be escaped: \ "
        l_cw___cfg_word="${2//'\'/'\\'}"
        l_cw___cfg_word="\"${l_cw___cfg_word//"\""/'\"'}\""
    elif [[ ( "$2" =~ [[:blank:]'"\=#'] ) ]] ; then
        # single quotes with no escaping
        l_cw___cfg_word="'$2'"
    elif [[ -z "$2" ]] ; then
        l_cw___cfg_word="''"
    else
        l_cw___cfg_word="$2"
    fi
}
