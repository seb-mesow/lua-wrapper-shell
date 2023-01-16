# TODO rename module
# TODO so l_cr___prefix

# complies an user edited string into an associative array
# Note, that the associative array is not ordered.
# 
# arguments:
#  $1  - varname of an associative array to insert the key-value pairs in
# [$2] - user string
#        if not provided: read from stdin
function assoc_array_from_config_str() {
    if [[ "$1" != "l_cr___array" ]] ; then
        local -n l_cr___array="$1"
    fi
    shift
    l_cr___array=()
    __cr___config_read __cr___parse_callback___assoc_array "$@"
}

# $1 - key, $2 - value
function __cr___parse_callback___assoc_array() {
    l_cr___array["$1"]="$2"
}

# complies an user edited string into two indexed arrays
# Thus the keys and values are ordered as they occur in the string.
# 
# arguments:
# $1 - varname of an (indexed) array with the keys
# $2 - varname of an (indexed) array with the values
# [$2] - user string
#        if not provided: read from stdin
function two_arrays_from_config_str() {
    if [[ "$1" != "l_cr___keys" ]] ; then
        local -n l_cr___keys="$1"
    fi
    if [[ "$2" != "l_cr___vals" ]] ; then
        local -n l_cr___vals="$2"
    fi
    shift 2
    l_cr___keys=()
    l_cr___vals=()
    __cr___config_read __cr___parse_callback___two_arrays "$@"
}

# $1 - key, $2 - value
function __cr___parse_callback___two_arrays() {
    l_cr___keys+=("$1")
    l_cr___vals+=("$2")
}

#  $1  - callback for __cr___parse
# [$2] - user string
#        if not provided: read from stdin
function __cr___config_read() {
    local -a l_cr___raw_lines
    l_cr___raw_lines=()
    if [[ -v 2 ]] ; then
        __cr___split_into_raw_lines "$2"
    else
        __cr___mapfile
    fi
    
    # trace_indexed_array_quoted l_cr___raw_lines
    
    local -a l_cr___token_seq=()
    __cr___tokenize
    
    __cr___trace_token_seq
    
    __cr___parse "$1"
}

# ========== Internal Functions ==========

function __cr___mapfile() {
    mapfile l_cr___raw_lines # starts with index 0
    local l_cr___line_num \
          l_cr___line_str
    for l_cr___line_num in "${!l_cr___raw_lines[@]}" ; do
        l_cr___line_str="${l_cr___raw_lines["$l_cr___line_num"]%$'\n'}"
        l_cr___raw_lines["$l_cr___line_num"]="${l_cr___line_str%$'\r'}"$'\n'
    done
}

# $1 - user string
function __cr___split_into_raw_lines() {
    local l_cr___str="$1" \
          l_cr___line_str
    # regex catches Unix- and Windows-style line endings
    while [[ "$l_cr___str" =~ ^([^$'\n']*)$'\n' ]] ; do
        l_cr___line_str="${BASH_REMATCH[1]}"
        l_cr___str="${l_cr___str#"${BASH_REMATCH[0]}"}"
        # normalize to Unix-style endings
        l_cr___raw_lines+=("${l_cr___line_str%$'\r'}"$'\n')
    done
    if [[ "$l_cr___str" ]] ; then
        l_cr___raw_lines+=("${l_cr___str%$'\r'}"$'\n')
    fi
}

# Any control characters, including \r, \v, \f are completely forbidden

# unquoted and unescaped blank chars
#   - can be a prefix of a line
#   - separates any of the following
#   - can be a suffix of a line
# word
#   - see below
# equal sign
#   - the equal sign character
# unquoted, unescaped line feed
#   - the line feed character
#   - separates statements
# comment
#   - introduced by a hash
#   - lasts until the end of the line
#     (thus also separates statements
#
# Currently there are only assignment as statements
#
# A word consists of a /continous/ sequence of word parts
#
# Formats of word parts:
# unquoted string
#   - backslash escapes any following character*
#     The backslash is removed
#     The next character becomes part of the word
#   - can not contain whitespace or control chars
# double quoted string, e.g. "abc \$def \"ghi\""
#   - backslash escapes any following character*
#     The backslash is removed
#     The next character becomes part of the word
#   - can contain whitespace and control chars
# single quoted string, e.g. 'abc $def "ghi"'
#   - can contain whitespace and control chars
#   - can not contain single quotes
#   - no line continuation
# ANSI C escape sequences string, e.g  $'with line\nbreak' ... 
#   - backslash introduces either an escape sequence,
#     or escapes the following character*
#     The backslash is removed
#     If all following characters are part of a known escape sequence,
#     then the special character becomes part of the word
#     If the following character* is not part of a known escape sequence,
#     then this character becomes part of the word.
#   - can contain whitespace and control chars
# 
# *) line continuation:
# If the backslash is the /last non-blank character/ on a line
# (before a comment seperated by white space),
# then the next line is considered as part of the previous line,
# with any leading whitespace ignored.
# 
# IMPORTANT:
# If you want a hash inside a key or value,
# then you must normally quote the key or value or escape it.
# 
# IMPORTANT for double-quoted words and ANSI C escaping:
# If you want some whitespace and then a hash mark inside a key or value,
# then you must not escape any of the whitespace.
# (Else it would be interpreted as a line continuation followed by a comment.
# In general escaping whitespace is odd anyway.)

# sets l_cr___char to the next char
# 
# uses from calling context:
# l_cr___char
# l_cr___col_num
# l_cr___line_len
# l_cr___line_num
# l_cr___lines_cnt
# l_cr___line_str
function __cr___next_char() {
    if (( l_cr___col_num >= l_cr___line_len )) ; then
        if (( l_cr___line_num >= l_cr___lines_cnt )) ; then
            return 1
        fi
        l_cr___line_str="${l_cr___raw_lines[l_cr___line_num++]}"
        l_cr___line_len="${#l_cr___line_str}"
        l_cr___col_num=0
    fi
    l_cr___char="${l_cr___line_str:l_cr___col_num++:1}"
    if (( "${#l_cr___char}" != 1 )) ; then
        internal_err "Assertation failed"
    fi
    if [[    ( "$l_cr___char" != $'\n') \
          && ( "$l_cr___char" == [[:cntrl:]] ) \
    ]] ; then
        local l_cr___bash_char
        bash_word_from_str l_cr___bash_char "$l_cr___char"
        __cr___user_tokenizer_error "forbidden character ${l_cr___bash_char}"
    fi
    
    return 0
}

# tokenizes the lines from l_cr___raw_lines
# into the variable "l_cr___token_seq"
function __cr___tokenize() {
    local -i l_cr___line_num=0 \
             l_cr___lines_cnt="${#l_cr___raw_lines[@]}" \
             l_cr___col_num=0 \
             l_cr___token_start_line_num \
             l_cr___token_start_col_num \
             l_cr___line_len=0
    
    # tokenizer states
    # "f" ... "fresh" (inital state and intial state when a new line)
    # "m" ... "middle of line" (after an equal sign or blank whitespace)
    # "u" ... unquoted string
    # "b" ... unquoted string - after backslash
    # "w" ... unquoted string - after backslash and one or more whitespace
    # "l" ... unquoted string - begin of a continuing line while unquoted (alternative to "fresh")
    
    local l_cr___char \
          l_cr___word \
          l_cr___line_str \
          l_cr___state=f
    while __cr___next_char ; do
        # if (( l_cr___col_num < 2 )) ; then
        #     echo
        # fi
        # local l_cr___bash_char
        # bash_word_from_str l_cr___bash_char "$l_cr___char"
        # printf "%s/%-5s" "$l_cr___state" "$l_cr___bash_char"
        case "$l_cr___state" in
            u) # ===== unquoted (not after backslash) ==========
               # inside some token or at the end of a token
                if __cr___tokenize___u___default ; then
                    break
                fi
                ;;
            m) # ===== middle of line ==========
               # between tokens
                case "$l_cr___char" in
                    [[:blank:]]) # still middle of line
                        # no ending of a word
                        # keep l_cr___state == m
                        ;;
                    *)
                        __cr___start_new_token # a new token starts here
                        if __cr___tokenize___u___default ; then
                            break
                        fi
                        ;;
                esac
                ;;
            f) # ===== fresh / at begin of line ==========
               # no tokens yet
                case "$l_cr___char" in
                    '#') # introduce comment --> next line
                        # without next statement token
                        l_cr___col_num=l_cr___line_len # provoke next line
                        # keep l_cr___state == f
                        ;;
                    [[:blank:]]|$'\n') # still fresh
                        # keep l_cr___state == f
                        ;;
                    *)
                        __cr___start_new_token # a new token starts here
                        if __cr___tokenize___u___default ; then
                            break
                        fi
                        ;;
                esac
                ;;
            # ===== backslash sequences or line continuation (unquoted) ==========
            b) # unquoted backslash sequence (or line continuation)
                case "$l_cr___char" in
                    $'\n')
                        # no next-statement token
                        l_cr___state=l
                        ;;
                    [[:blank:]])
                        l_cr___uneval_chars="$l_cr___char" # for unquoted l_cr___uneval_chars is a single blank
                        l_cr___state=w # contiune in waiting for line continuation
                        ;;
                    *)
                        l_cr___word="$l_cr___word$l_cr___char"
                        l_cr___state=u # continue normal unquoted
                        ;;
                esac
                ;;
            # ===== wait for line continuation (unquoted) ==========
            w) # wait for line continuation, while unquoted
                case "$l_cr___char" in
                    '#')
                        l_cr___col_num=l_cr___line_len # provoke new line
                        ;& # continue with next clause without prior test
                    $'\n')
                        # ignore uneval chars, which is only blank
                        # no next-statement token
                        l_cr___state=l
                        ;;
                    [[:blank:]])
                        # for unquoted l_cr___uneval_chars is a single blank
                        # keep l_cr___state == w
                        ;;
                    *)
                        # was just a normal unquoted backslash sequence
                        # for unquoted l_cr___uneval_chars is a single blank
                        l_cr___word="$l_cr___word$l_cr___uneval_chars"
                        if __cr___tokenize___u___default ; then
                            break
                        fi
                        ;;
                esac
                ;;
            l) # ===== line continuation (unquoted) ==========
                case "$l_cr___char" in
                    '#')
                        l_cr___col_num=l_cr___line_len # provoke new line
                        # keep l_cr___state == l
                        ;;
                    $'\n'|[[:blank:]]) # ignore whitespace
                        # keep l_cr___state == l
                        ;;
                    *)
                        if __cr___tokenize___u___default ; then
                            break
                        fi
                        ;;
                esac
                ;;
            *) # ===== invalid state ==========
                __cr___internal_tokenizer_error "unknown tokenizer state $l_cr___state"
                ;;
        esac
    done
}

# ========== unquoted / normal ====================

# works perfect for the u state
# Usage:
#   if __cr___tokenize___u___default ; then
#       break
#   fi
function __cr___tokenize___u___default() {
    case "$l_cr___char" in
        '"') # introduce double-quoted ...
            __cr___tokenize___d # ... substate
            l_cr___state=u
            ;;
        =) # equal sign
            __cr___append_word_token_if_not_empty
            __cr___append_equal_sign_token
            l_cr___state=m
            ;;
        '\') # introduce unquoted backslash sequence (or line continuation)
            l_cr___state=b
            ;;
        '#') # comment
            __cr___append_word_token_if_not_empty
            __cr___append_next_statement_token # finish statement
            l_cr___col_num=l_cr___line_len # provoke next line ; must come after __cr___append_next_statement_token
            l_cr___state=f
            ;;
        $'\n')# end of line
            __cr___append_word_token_if_not_empty
            __cr___append_next_statement_token # finish statement
            l_cr___state=f
            ;;
        "'") # introduce single quoted ...
            __cr___tokenize___s # ... substate
            l_cr___state=u
            ;;
        '$') # introduce dollar sign state (maybe ANSI C escaping)
            local l_cr___prev_char="$l_cr___char"
            if __cr___next_char ; then # litte "dollar sign substate"
                case "$l_cr___char" in
                    "'") # introduce ANSI C escaping ...
                        __cr___tokenize___ansi_c # ... substate
                        l_cr___state=u
                        ;;
                    *)
                        l_cr___word="${l_cr___word}${l_cr___prev_char}"
                        __cr___tokenize___u___default
                        ;;
                esac
            else
                return 0
            fi
            ;;
        [[:blank:]]) # whitespace --> end word
            __cr___append_word_token_if_not_empty
            l_cr___state=m
            ;;
        [[:graph:]]) # continue unquoted
            l_cr___word="$l_cr___word$l_cr___char"
            l_cr___state=u
            ;;
        *)
            local l_cr___bash_char
            bash_word_from_str l_cr___bash_char "$l_cr___char"
            __cr___internal_tokenizer_error \
                "unknown character ${l_cr___bash_char}\nl_state == ${l_cr___state}"
            ;;
    esac
    return 1
}

# ========== double-quoted string substate ====================

# Usage:
#   if __cr___tokenize___d___default ; then
#       return
#   fi
function __cr___tokenize___d___default() {
    case "$l_cr___char" in
        '"') # end double-quoted
            return 0
            ;;
        '\') # introduce double-quoted backslash sequence (or line continuation)
            l_cr___state=b
            ;;
        *) # continue double-quoted
            l_cr___word="$l_cr___word$l_cr___char"
            l_cr___state=n
            ;;
    esac
    return 1
}

function __cr___tokenize___d() {
    local l_cr___uneval_chars
    # "n" ... normal
    # "b" ... after backslash
    # "w" ... after backslash and one or more whitespace
    # "l" ... begin of a continuing line 
    local l_cr___state=n
    while __cr___next_char ; do
        case "$l_cr___state" in
            n) # ===== normal (not after backslash) ==========
                if __cr___tokenize___d___default ; then
                    return
                fi
                ;;
            b) # ===== backslash sequence or line continuation ==========
                case "$l_cr___char" in
                    $'\n')
                        # no next-statement token
                        l_cr___state=l
                        ;;
                    [[:blank:]])
                        l_cr___uneval_chars="$l_cr___char" # for double-quoted l_cr___uneval_chars can be multiple blanks
                        l_cr___state=w # contiune in waiting for line continuation
                        ;;
                    *)
                        l_cr___word="$l_cr___word$l_cr___char" # simply insert following char
                        l_cr___state=n # continue normal double-quoted
                        ;;
                esac
                ;;
            w) # ========== wait for line continuation ==========
                case "$l_cr___char" in
                    '#')
                        l_cr___col_num=l_cr___line_len # provoke new line
                        ;& # continue with next clause without prior test
                    $'\n')
                        # ignore uneval chars, which is only blank
                        # no next-statement token
                        l_cr___state=l
                        ;;
                    [[:blank:]])
                        # for double-quoted l_cr___uneval_chars can be multiple blanks
                        l_cr___uneval_chars="$l_cr___uneval_chars$l_cr___char"
                        # keep l_cr___state == w
                        ;;
                    *)
                        # was just a normal double-quoted backslash sequence
                        # for double-quoted l_cr___uneval_chars can be multiple blanks
                        l_cr___word="$l_cr___word$l_cr___uneval_chars"
                        if __cr___tokenize___d___default ; then
                            return
                        fi
                        ;;
                esac
                ;;
            l) # ===== line continuation ==========
                case "$l_cr___char" in
                    '#')
                        l_cr___col_num=l_cr___line_len # provoke new line
                        # keep l_cr___state == l
                        ;;
                    $'\n'|[[:blank:]]) # ignore whitespace
                        # keep l_cr___state == l
                        ;;
                    *)
                        if __cr___tokenize___d___default ; then
                            return
                        fi
                        ;;
                esac
                ;;
            *) # ===== invalid state ==========
                __cr___internal_tokenizer_error "unknown double-quoted tokenizer state $l_cr___state"
                ;;
        esac
    done
    __cr___user_tokenizer_error___unfinished_string "double-quoted string"
}

# ========== ANSI C escape sequence string substate ====================

# Usage:
#   if __cr___tokenize___ansi_c___default ; then
#       return
#   fi
function __cr___tokenize___ansi_c___default() {
    case "$l_cr___char" in
        '\') # introduce escape sequence
            l_cr___state=b
            ;;
        "'") # end of ANSI C escape sequences string
            return 0
            ;;
        *) # continue normal
            l_cr___word="$l_cr___word$l_cr___char"
            l_cr___state=n
            ;;
    esac
    return 1
}

# substate for ANSI C escape sequences string
# TODO collect esacape sequences for the whole sub word ($'...')
# TODO and only at the end use an interpret them
# TODO (thus reduces the number of evals)
function __cr___tokenize___ansi_c() {
    local -i l_cr___remaining_counts_of_same_state
    
    local l_cr___state=n \
          l_cr___uneval_chars \
          l_cr___escape_seq # without backslash 
    
    # "n" ... normal
    # "b" ... after backslash
    # "o" ... \nnn, where n is an octal digit
    #          (upon entry: l_cr___remaining_counts_of_same_state:=2)
    # "x" ... \xHH, where H is an hexadecimal digit
    #          (upon entry: l_cr___remaining_counts_of_same_state:=2)
    # "u" ... \uHHHH, where H is an hexadecimal digit
    #          (upon entry: l_cr___remaining_counts_of_same_state:=4)
    # "U" ... \UHHHHHHHH, where H is an hexadecimal digit
    #          (upon entry: l_cr___remaining_counts_of_same_state:=8)
    # "c" ... \cx, where x is any character
    # "w" ... after backslash and one or more whitespace
    # "l" ... begin of a continuing line 
    while __cr___next_char ; do
        case "$l_cr___state" in
            n) # ===== normal ==========
                if __cr___tokenize___ansi_c___default ; then
                    return
                fi
                ;;
            b) # ===== escape sequence ==========
                case "$l_cr___char" in
                    n) # new line
                        l_cr___word="$l_cr___word"$'\n'
                        l_cr___state=n
                        ;;                    
                    e|E) # escape character
                        l_cr___word="$l_cr___word"$'\e'
                        l_cr___state=n
                        ;;                    
                    r) # carriage return
                        l_cr___word="$l_cr___word"$'\r'
                        l_cr___state=n
                        ;;                    
                    b) # backspace
                        l_cr___word="$l_cr___word"$'\b'
                        l_cr___state=n
                        ;;                    
                    t) # horizontal tab
                        l_cr___word="$l_cr___word"$'\t'
                        l_cr___state=n
                        ;;                    
                    f) # form feed
                        l_cr___word="$l_cr___word"$'\f'
                        l_cr___state=n
                        ;;                    
                    v) # vertical tab
                        l_cr___word="$l_cr___word"$'\v'
                        l_cr___state=n
                        ;;                    
                    a) # bell character
                        l_cr___word="$l_cr___word"$'\a'
                        l_cr___state=n
                        ;;                    
                    [0-7]) # \nnn, where n is an octal digit
                        l_cr___escape_seq="$l_cr___char"
                        l_cr___state=o
                        l_cr___remaining_counts_of_same_state=2
                        ;;
                    x) # \xHH, where H is an hexadecimal digit
                        l_cr___escape_seq="x"
                        l_cr___state=x
                        l_cr___remaining_counts_of_same_state=2
                        ;;
                    c) # \cx, where x is any character
                        l_cr___escape_seq="c"
                        l_cr___state=c
                        ;;
                    u) # \uHHHH, where H is an hexadecimal digit
                        l_cr___escape_seq="u"
                        l_cr___state=u
                        l_cr___remaining_counts_of_same_state=4
                        ;;
                    U) # \UHHHHHHHH, where H is an hexadecimal digit
                        l_cr___escape_seq="U"
                        l_cr___state=U
                        l_cr___remaining_counts_of_same_state=8
                        ;;
                    [[:blank:]])
                        l_cr___uneval_chars="$l_cr___char" # for ANSI C escaping l_cr___uneval_chars can be multiple blanks
                        l_cr___state=w
                        ;;
                    *) # unknown escape sequence
                        l_cr___word="${l_cr___word}${l_cr___char}" # simply insert following char
                        l_cr___state=n # continue normal
                        ;;
                esac
                ;;
            x) # ===== \xHH, where H is an hexadecimal digit ==========
                case "$l_cr___char" in
                    [[:xdigit:]])
                        l_cr___escape_seq="$l_cr___escape_seq$l_cr___char"
                        if (( --l_cr___remaining_counts_of_same_state <= 0 )) ; then
                            eval "l_cr___word=\"\$l_cr___word\"\$'\\$l_cr___escape_seq'"
                            l_cr___state=n
                        fi
                        ;;
                    *)
                        # flush what so far
                        eval "l_cr___word=\"\$l_cr___word\"\$'\\$l_cr___escape_seq'"
                        l_cr___word="$l_cr___word$l_cr___char"
                        l_cr___state=n
                        ;;
                esac
                ;;
            o) # ===== \nnn, where n is an octal digit ==========
                case "$l_cr___char" in
                    [0-7])
                        l_cr___escape_seq="$l_cr___escape_seq$l_cr___char"
                        if (( --l_cr___remaining_counts_of_same_state <= 0 )) ; then
                            eval "l_cr___word=\"\$l_cr___word\"\$'\\$l_cr___escape_seq'"
                            l_cr___state=n
                        fi
                        ;;
                    *)
                        # flush what so far
                        eval "l_cr___word=\"\$l_cr___word\"\$'\\$l_cr___escape_seq'"
                        l_cr___word="$l_cr___word$l_cr___char"
                        l_cr___state=n
                        ;;
                esac
                ;;
            c) # ===== \cx, where x is any character ==========
                eval "l_cr___word=\"\$l_cr___word\"\$'\\c$l_cr___char'"
                l_cr___state=n
                ;;
            u|U) # ===== \uHHHH or \UHHHHHHHH, where H is an hexadecimal digit ==========
                case "$l_cr___char" in
                    [[:xdigit:]])
                        l_cr___escape_seq="$l_cr___escape_seq$l_cr___char"
                        if (( --l_cr___remaining_counts_of_same_state <= 0 )) ; then
                            eval "l_cr___word=\"\$l_cr___word\"\$'\\$l_cr___escape_seq'"
                            l_cr___state=n
                        fi
                        ;;
                    *)
                        # flush what so far
                        eval "l_cr___word=\"\$l_cr___word\"\$'\\$l_cr___escape_seq'"
                        l_cr___word="$l_cr___word$l_cr___char"
                        l_cr___state=n
                        ;;
                esac
                ;;
            w) # ===== wait for line continuation ==========
                case "$l_cr___char" in
                    '#')
                        l_cr___col_num=l_cr___line_len # provoke new line
                        ;& # continue with next clause without prior test
                    $'\n')
                        # ignore uneval chars, which is only blank
                        # no next-statement token
                        l_cr___state=l
                        ;;
                    [[:blank:]])
                        # for ANSI C escaping l_cr___uneval_chars can be multiple blanks
                        l_cr___uneval_chars="$l_cr___uneval_chars$l_cr___char"
                        # keep l_cr___state == w
                        ;;
                    *)
                        # was just a normal ANSI C escape sequence
                        # for ANSI C escaping l_cr___uneval_chars can be multiple blanks
                        l_cr___word="$l_cr___word$l_cr___uneval_chars"
                        if __cr___tokenize___ansi_c___default ; then
                            return
                        fi
                        ;;
                esac
                ;;
            l) # ===== line continuation ==========
                case "$l_cr___char" in
                    '#')
                        l_cr___col_num=l_cr___line_len # provoke new line
                        # keep l_cr___state == l
                        ;;
                    $'\n'|[[:blank:]]) # ignore whitespace
                        # keep l_cr___state == l
                        ;;
                    *)
                        if __cr___tokenize___ansi_c___default ; then
                            return
                        fi
                        ;;
                esac
                ;;
            *) # ===== invalid state ==========
                __cr___internal_tokenizer_error "unknown ANSI C escape tokenizer state $l_cr___state"
                ;;
        esac
    done
    __cr___user_tokenizer_error___unfinished_string "ANSI C escape sequence string"
}

# ========== single-quoted string substate ====================

function __cr___tokenize___s() {
    # This substate is very simple.
    while __cr___next_char ; do
        case "$l_cr___char" in
            "'") # end single-quoted
                return
                ;;
            *) # continue single-quoted
                l_cr___word="$l_cr___word$l_cr___char"
                ;;
        esac
    done
    __cr___user_tokenizer_error___unfinished_string "single-quoted string"
}

# ========== Create Tokens ====================

# $1 - kind of string, must ends with "string"
function __cr___user_tokenizer_error___unfinished_string() {
    local l_cr___bash_str
    bash_word_from_str l_cr___bash_str "$l_cr___word"
    __cr___user_tokenizer_error "unfinished ${1} =="$'\n'"${l_cr___bash_str}"
}

# $1 - msg str
function __cr___user_tokenizer_error() {
    local l_cr___show_line_msg
    __cr___show_line_msg \
            "tokenizer error: " "$l_cr___line_num" "$l_cr___col_num"
    user_errf "tokenizer error: %s\n%s" "$1" "$l_cr___show_line_msg"
}

# $1 - msg str
function __cr___internal_tokenizer_error() {
    local l_cr___show_line_msg
    __cr___show_line_msg \
            "tokenizer error: " "$l_cr___line_num" "$l_cr___col_num"
    internal_errf "tokenizer error: %s\n%s" "$1" "$l_cr___show_line_msg"
}

# A token is either a word (with a string value), the equal sign or the "next statement token"
# A token sequence is an indexed array with varnames
# This indexed array of the token sequence must be named l_cr___token_seq
# Each varname points to an associative array with the following keys
# "t" ... type
#         == "w" for words
#         == "e" for equal sign
#         == "n" for next statement
# "v" ... value (only for words)
#         == string of the word

# The line numbers from __cr___split_into_raw_lines() are zero-based,
# But because l_cr___line_num is already ahead by one during the tokenizing loop
# the stored line numbers are one-based.
function __cr___start_new_token() {
    l_cr___token_start_line_num=l_cr___line_num
    l_cr___token_start_col_num=l_cr___col_num
}

function __cr___clear_token_seq() {
    local -i l_cr___token_index=0 \
             l_cr___tokens_cnt="${#l_cr___token_seq[@]}"
    while (( l_cr___token_index < l_cr___tokens_cnt )) ; do
        unset "${l_cr___token_seq[l_cr___token_index++]}"
    done
    unset l_cr___token_seq
}

# sets l_cr___token_n to the array name of the new token
# 
# Side Note:
# in a former version __cr___append_token() was called as in the following snippet
#     local -n l_cr___token_array # UNDEFINED BEHAVIOUR
#     __cr___append_token
#     l_cr___token_array[<further key>]=<further value>
# and __cr___append_token() executes:
#     ...
#     l_cr___token_array=<token_n>
#     ...
# But the behaviour to set the var name a nameref var refers to /later/,
# is undocumented and thus should be avoided.
# 
# uses from calling context:
# l_cr___token_n
function __cr___append_token() {
    l_cr___token_n="l_cr___token_${#l_cr___token_seq[@]}"
    declare -g -A "$l_cr___token_n"
    local -n l_cr___token="$l_cr___token_n"
    l_cr___token[l]="$l_cr___token_start_line_num"
    l_cr___token[c]="$l_cr___token_start_col_num"
    l_cr___token_seq+=("$l_cr___token_n")
}


function __cr___append_word_token_if_not_empty() {
    if [[ "$l_cr___word" ]] ; then
        # no __cr___start_new_token() here!
        local l_cr___token_n
        __cr___append_token
        local -n l_cr___token="$l_cr___token_n"
        l_cr___token[t]=w
        l_cr___token[v]="$l_cr___word"
    fi
    l_cr___word=
}

function __cr___append_equal_sign_token() {
    __cr___start_new_token
    local l_cr___token_n
    __cr___append_token
    local -n l_cr___token="$l_cr___token_n"
    l_cr___token[t]=e
}

function __cr___append_next_statement_token() {
    __cr___start_new_token
    local l_cr___token_n
    __cr___append_token
    local -n l_cr___token="$l_cr___token_n"
    l_cr___token[t]=n
}

function __cr___print_token_seq() {
    echo "l_cr___token_seq =="
    local l_cr___token_n \
          l_cr___token_val \
          l_cr___key
    for l_cr___token_n in "${l_cr___token_seq[@]}" ; do
        printf "    %s ==" "$l_cr___token_n"
        local -n l_cr___token="$l_cr___token_n"
        if [[ -v l_cr___token[t] ]]  ; then
            printf " %s" "${l_cr___token[t]}"
        fi
        if [[ -v l_cr___token[l] ]]  ; then
            printf " %2d" "${l_cr___token[l]}"
        fi
        if [[ -v l_cr___token[c] ]]  ; then
            printf ":%2d" "${l_cr___token[c]}"
        fi
        if [[ -v l_cr___token[v] ]]  ; then
            bash_word_from_str l_cr___token_val "${l_cr___token[v]}"
            printf " %s" "$l_cr___token_val"
        fi
        for l_cr___key in "${!l_cr___token[@]}" ; do
            if [[ "$l_cr___key" != [tlcv] ]]; then
                bash_word_from_str l_cr___token_val "${l_cr___token["$l_cr___key"]}"
                printf " %s=%s" "$l_cr___key" "$l_cr___token_val"
            fi
        done
        echo
    done
}

# declares __cr___log_token_seq(), __cr___debug_token_seq(), __cr___trace_token_seq()
declare_debug_funcs_from_print_func __cr___print_token_seq

# parses the token sequence generated by __cr___tokenize
# into an  associative array
#
# The callback func is called with the key and the value as the only arguments
#
# arguments:
# $1 - callback func
function __cr___parse() {
    local -i l_i=0 \
             l_n="${#l_cr___token_seq[@]}"
    
    # parser states:
    # "f" ... fresh (begin of file or after next statement token)
    # "k" ... scan key
    # "e" ... after equal sign
    # "v" ... scan value
    
    local l_cr___key \
          l_cr___val \
          l_cr___state=f
    while (( l_i < l_n )) ; do
        local -n l_cr___token="${l_cr___token_seq[l_i++]}"
        case "$l_cr___state" in
            f) # fresh
                case "${l_cr___token[t]}" in
                    w) # multiple words are concated by spaces to one key
                        l_cr___key="${l_cr___token[v]}"
                        l_cr___state=k
                        ;;
                    e)
                        __cr___user_parser_error "extra equal sign"
                        ;;
                    n)
                        __cr___internal_parser_error "unexpected double or leading next statement token"
                        ;;
                    *)
                        __cr___internal_parser_error___unknown_token_type
                        ;;
                esac
                ;;
            k) # scan key
                case "${l_cr___token[t]}" in
                    w) # multiple words are concated by spaces to one key
                        l_cr___key="${l_cr___key} ${l_cr___token[v]}"
                        ;;
                    e)
                        l_cr___state=v
                        ;;
                    n)
                        __cr___user_parser_error "unfinished assignment"
                        ;;
                    *)
                        __cr___internal_parser_error___unknown_token_type
                        ;;
                esac
                ;;
            v) # scan value
                case "${l_cr___token[t]}" in
                    w) # multiple words are concated by spaces to one value
                        l_cr___val="${l_cr___val:+${l_cr___val} }${l_cr___token[v]}"
                        ;;
                    e)
                        __cr___user_parser_error "parser error: extra equal sign"
                        ;;
                    n)
                        # Here the values are added to the config are finally added to the config
                        "$1" "$l_cr___key" "$l_cr___val"
                        l_cr___state=f
                        l_cr___key=
                        l_cr___val=
                        ;;
                    *)
                        __cr___internal_parser_error___unknown_token_type
                        ;;
                esac
                ;;
            *)
                __cr___internal_parser_error "unknown state ${l_cr___state}"
                ;;
            esac
    done
    __cr___clear_token_seq # needed, because individual tokens are defined globally
}

function __cr___internal_parser_error___unknown_token_type() {
    __cr___internal_parser_error "unknown token_type ${l_cr___token[t]}"
}

# $1 - msg str
function __cr___user_parser_error() {
    local l_cr___show_line_msg
    __cr___show_line_msg \
            "parser error: " "${l_cr___token[l]}" "${l_cr___token[c]}"
    user_errf "parser error: %s\n%s" "$1" "$l_cr___show_line_msg"
}

# $1 - msg str
function __cr___internal_parser_error() {
    local l_cr___show_line_msg
    __cr___show_line_msg \
            "parser error: " "${l_cr___token[l]}" "${l_cr___token[c]}"
    internal_errf "parser error: %s\n%s" "$1" "$l_cr___show_line_msg"
}

# sets l_cr___show_line_msg
# 
# arguments:
#  $1  - message prefix
#  $2  - line number, one-based
# [$3] - column number, one-based
# 
# uses from calling context:
# l_cr___show_line_msg
function __cr___show_line_msg() {
    printf -v l_cr___show_line_msg \
        "%sin line %d:\n%s" \
            "$1" "$2" \
            "${l_cr___raw_lines["$2" - 1]}"
    if [[ "$3" ]] ; then
        local -i l_cr___i \
                 l_cr___col="$3"
        for (( l_cr___i=1 ; \
               l_cr___i < l_cr___col ; \
               l_cr___i++ ))
        do
            l_cr___show_line_msg="${l_cr___show_line_msg} "
        done
        l_cr___show_line_msg="${l_cr___show_line_msg}^"
    fi
}
