# A Callstack is set of consecutively named stack frame assoc arrays
# and a last stack frame number.

declare -g -i m_CS___show_long___context_line_cnt=3

# sets l_CS___stack_frames_cnt_n
# 
# uses from calling context:
# l_CS___CS_n
function __CS___set___l_CS___stack_frames_cnt_n() {
    l_CS___stack_frames_cnt_n="${l_CS___CS_n}___stack_frames_cnt"
}


# sets l_CS___stack_frame_n
# 
# $1 - stack frame number
# 
# uses from calling context:
# l_CS___CS_n
function __CS___set___l_CS___stack_frame_n() {
    l_CS___stack_frame_n="${l_CS___CS_n}___stack_frame_${1}"
}

#  $1  - ret str var for name of Callstack object
# [$2] - if 0, then first shown stack frame == func which called CS___snapshot
#        if 1, then first shown stack frame == func which called the func which called CS___snapshot
#        ... and so one
#        default: 0
function CS___snapshot() {
    unique_varname "$1" "m_CS___CS_"
    local -n l_CS___CS_n="$1"
    
    local l_CS___stack_frames_cnt_n \
          l_CS___stack_frame_n
    
    __CS___set___l_CS___stack_frames_cnt_n
    declare -g -i "$l_CS___stack_frames_cnt_n"=0
    local -n l_CS___stack_frames_cnt="$l_CS___stack_frames_cnt_n"
    
    local -i l_CS___index \
             l_CS___FUNCNAME_cnt="${#FUNCNAME[@]}"
    
    for (( l_CS___index="$(( "${2:-0}" + 2 ))" ; \
           l_CS___index < l_CS___FUNCNAME_cnt ; \
           l_CS___index++ ))
    do
        __CS___set___l_CS___stack_frame_n "$(( l_CS___stack_frames_cnt++ ))"
        declare -g -A "$l_CS___stack_frame_n"
        local -n l_CS___stack_frame="$l_CS___stack_frame_n"
        l_CS___stack_frame=( \
            ["funcname"]="${FUNCNAME[l_CS___index]}" \
            ["filepath"]="${BASH_SOURCE[l_CS___index]}" \
            ["lineno"]="${BASH_LINENO[l_CS___index-1]}" \
            ["num"]="$l_CS___index" \
        )
    done
}

# $1 - name of Callstack object
function CS___delete() {
    local l_CS___CS_n="$1" \
          l_CS___stack_frames_cnt_n \
          l_CS___stack_frame_n
    
    __CS___set___l_CS___stack_frames_cnt_n
    local -n l_CS___stack_frames_cnt="$l_CS___stack_frames_cnt_n"
    
    local -i l_CS___index
    for (( l_CS___index=0 ; \
           l_CS___index < l_CS___stack_frames_cnt ; \
           l_CS___index++ ))
    do
        __CS___set___l_CS___stack_frames_cnt_n "$l_CS___index"
        unset "$l_CS___stack_frame_n"
    done
}

# $1  - name of Callstack object
function CS___show_minimal() {
    local l_CS___CS_n="$1" \
          l_CS___stack_frames_cnt_n \
          l_CS___stack_frame_n \
          l_CS___dirpath \
          l_CS___filename \
          l_CS___filepath
    
    __CS___set___l_CS___stack_frames_cnt_n
    local -n l_CS___stack_frames_cnt="$l_CS___stack_frames_cnt_n"
    
    local -i l_CS___index \
             l_CS___funcname_max_len=0
    
    for (( l_CS___index=0 ; \
           l_CS___index < l_CS___stack_frames_cnt ; \
           l_CS___index++ ))
    do
        __CS___set___l_CS___stack_frame_n "$l_CS___index"
        local -n l_CS___stack_frame="$l_CS___stack_frame_n"
        
        if (( "${#l_CS___stack_frame["funcname"]}" > l_CS___funcname_max_len ))
        then
            l_CS___funcname_max_len="${#l_CS___stack_frame["funcname"]}"
        fi
    done
    
    for (( l_CS___index=0 ; \
           l_CS___index < l_CS___stack_frames_cnt ; \
           l_CS___index++ ))
    do
        __CS___set___l_CS___stack_frame_n "$l_CS___index"
        local -n l_CS___stack_frame="$l_CS___stack_frame_n"
        l_CS___filepath="${l_CS___stack_frame["filepath"]}"
        
        split_filepath l_CS___dirpath l_CS___filename "$l_CS___filepath"
        
        printf "%*s()    in file %s\n" \
            "$l_CS___funcname_max_len" "${l_CS___stack_frame["funcname"]}" \
            "$l_CS___filename"
        
        "$__CS___show_stack_frame___minimal___extra_callback"
    done
}

# $1  - name of Callstack object
function CS___show_compact() {
    local l_CS___CS_n="$1" \
          l_CS___stack_frames_cnt_n \
          l_CS___stack_frame_n \
          l_CS___dirpath \
          l_CS___filename \
          l_CS___filepath \
          l_CS___file_line
    
    __CS___set___l_CS___stack_frames_cnt_n
    local -n l_CS___stack_frames_cnt="$l_CS___stack_frames_cnt_n"
    
    exec_module ANSI
    
    local -i l_CS___index \
             l_CS___file_lineno
    
    local -a l_CS___file_lines
    
    for (( l_CS___index=0 ; \
           l_CS___index < l_CS___stack_frames_cnt ; \
           l_CS___index++ ))
    do
        __CS___set___l_CS___stack_frame_n "$l_CS___index"
        local -n l_CS___stack_frame="$l_CS___stack_frame_n"
        l_CS___filepath="${l_CS___stack_frame["filepath"]}"
        
        split_filepath l_CS___dirpath l_CS___filename "$l_CS___filepath"
        
        l_CS___file_lines=()
        mapfile -O 1 l_CS___file_lines < "$l_CS___filepath"
        l_CS___file_lineno="${l_CS___stack_frame["lineno"]}"
        l_CS___file_line="${l_CS___file_lines[l_CS___file_lineno]}"
        
        printf "\
${ANSI___seq___warning_markup}%d %s${ANSI___seq___end}\
%s()    in file %s\n" \
            "$l_CS___file_lineno" \
            "$l_CS___file_line" \
            "${l_CS___stack_frame["funcname"]}" \
            "$l_CS___filename"
    done
}

# $1 - name of Callstack object
# $2 - funcname to show a stack frame
function CS___show_long() {
    local l_CS___CS_n="$1" \
          l_CS___msg_category="${2:-"Internal Error"}" \
          l_CS___stack_frames_cnt_n \
          l_CS___stack_frame_n
    
    __CS___set___l_CS___stack_frames_cnt_n
    local -n l_CS___stack_frames_cnt="$l_CS___stack_frames_cnt_n"
    
    exec_module ANSI
    
    local -i l_CS___index
    for (( l_CS___index=0 ; \
           l_CS___index < l_CS___stack_frames_cnt ; \
           l_CS___index++ ))
    do
        __CS___set___l_CS___stack_frame_n "$l_CS___index"
        __CS___show_stack_frame___long "$l_CS___stack_frame_n"
    done
}

# $1 - stack_frame_n
# 
# used from calling context:
# l_CS___msg_category
function __CS___show_stack_frame___long() {
    local -n l_CS___stack_frame="$1"
    
    local l_CS___filepath="${l_CS___stack_frame["filepath"]}"
    local -i l_CS___lineno="${l_CS___stack_frame["lineno"]}"
    
    local l_CS___dirpath \
          l_CS___filename
    split_filepath l_CS___dirpath l_CS___filename "$l_CS___filepath"
    
    log___msgf_stdin_custom_category "$l_CS___msg_category" \
            "${l_CS___stack_frame["funcname"]}" \
            "${l_CS___stack_frame["num"]}" \
            "$l_CS___dirpath" "$l_CS___filename" \
            <<__end__
in function ${ANSI___seq___error_markup}%s()${ANSI___seq___end}    (stack frame #%d)
in file %s/${ANSI___seq___error_markup}%s${ANSI___seq___end}
__end__
# at line $l_CS___lineno"
    
    if (( m_CS___show_long___context_line_cnt >= 0 )) ; then
        local -a l_err___file_lines=()
        mapfile -O 1 l_err___file_lines < "$l_CS___filepath"
        
        # start line
        local -i l_err___lineno="$((l_CS___lineno - m_CS___show_long___context_line_cnt))"
        if (( l_err___lineno < 1 )) ; then
            l_err___lineno=1
        fi
        # end line
        local -i l_err___end="$((l_CS___lineno + m_CS___show_long___context_line_cnt))"
        if (( l_err___end > "${#l_err___file_lines[@]}" )) ; then
            l_err___end="${#l_err___file_lines[@]}"
        fi
        
        # digits of line numbers
        local l_err___lineno_size="${#l_err___end}"
        
        # leading context
        while (( l_err___lineno < l_CS___lineno )) ; do
            printf "%*d %s" \
                    "$l_err___lineno_size" "$l_err___lineno" \
                    "${l_err___file_lines[l_err___lineno++]}"
        done
        # error line
        local l_err___last_str
        printf -v l_err___last_str "%*d %s" \
                "$l_err___lineno_size" "$l_err___lineno" \
                "${l_err___file_lines[l_err___lineno++]}"
        printf "${ANSI___seq___error_markup}%s${ANSI___seq___end}" "$l_err___last_str"
        # trailing context
        while (( l_err___lineno <= l_err___end )) ; do
            printf -v l_err___last_str "%*d %s" \
                "$l_err___lineno_size" "$l_err___lineno" \
                "${l_err___file_lines[l_err___lineno++]}"
            printf "%s" "$l_err___last_str"
        done
        
        if [[ ! "$l_err___last_str" =~ $'\n'$ ]] ; then
            echo
        fi
    fi
}
