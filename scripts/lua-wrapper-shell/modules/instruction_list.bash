# ========== Instruction List ====================

# sets l_IL___instrs_cnt_n
# 
# uses from calling context:
# l_IL___IL_n
function __IL___get_instrs_cnt_n() {
    l_IL___instrs_cnt_n="${l_IL___IL_n}___instrs_cnt"
}

# sets l_IL___instr_n
# 
# $1 - instr number
# 
# uses from calling context:
# l_IL___IL_n
function __IL___get_instr_n() {
    l_IL___instr_n="${l_IL___IL_n}___instr_${1}"
}

# sets l_IL___instr_n
#
# $1 - IL_n_n
# 
# uses from calling context:
# l_IL___IL_n
function __IL___append_new_empty_instr() {
    if [[ "$1" != "l_IL___IL_n" ]] ; then
        local -n l_IL___IL_n="$1"
    fi
    local l_IL___instrs_cnt_n
    __IL___get_instrs_cnt_n
    __IL___get_instr_n "$(( "$l_IL___instrs_cnt_n"++ ))"
    declare -g -A "$l_IL___instr_n"
}

# $1 - IL_n_n
function IL___new() {
    unique_varname "$1" "m_IL___IL_"
    if [[ "$1" != "l_IL___IL_n" ]] ; then
        local -n l_IL___IL_n="$1"
    fi
    local l_IL___instrs_cnt_n
    __IL___get_instrs_cnt_n
    # trace_str_var l_IL___instrs_cnt_n
    declare -g -i "$l_IL___instrs_cnt_n"=0
}

# $1 - ret int var name
# $2 - IL_n_n
function IL___get_instructions_count_except_other() {
    if [[ "$1" != "l_IL___ret_instrs_cnt" ]] ; then
        local -n l_IL___ret_instrs_cnt="$1"
    fi
    local -n l_IL___IL_n="$2"
    local l_IL___instrs_cnt_n \
          l_IL___instr_n
    __IL___get_instrs_cnt_n
    local -n l_IL___instrs_cnt="$l_IL___instrs_cnt_n"
    
    l_IL___ret_instrs_cnt=0
    
    local -i l_IL___index=0
    while (( l_IL___index < l_IL___instrs_cnt )) ; do
        __IL___get_instr_n "$(( l_IL___index++ ))"
        local -n l_IL___instr="$l_IL___instr_n"
        if [[ "${l_IL___instr_n["kind"]}" != "other" ]] ; then
            l_IL___ret_instrs_cnt+=1
        fi
    done
}

# Should be numbered / other instrs to really do something
# $1 - IL_n_n
# $2 - string
function IL___append___raw() {
    local l_IL___instr_n
    __IL___append_new_empty_instr "$1"
    local -n l_IL___instr="$l_IL___instr_n"
    l_IL___instr=( \
        ["kind"]="raw" \
        ["str"]="$2" \
    )
}

# Should not numbered / comments
# $1 - IL_n_n
# $2 - string
function IL___append___other() {
    local l_IL___instr_n
    __IL___append_new_empty_instr "$1"
    local -n l_IL___instr="$l_IL___instr_n"
    l_IL___instr=( \
        ["kind"]="other" \
        ["str"]="$2" \
    )
}


# $1 - IL_n_n
# $2 - env var name
function IL___append___delete() {
    local l_IL___instr_n
    __IL___append_new_empty_instr "$1"
    local -n l_IL___instr="$l_IL___instr_n"
    l_IL___instr=( \
        ["kind"]="delete" \
        ["var_n"]="$2" \
    )
}

#  $1  - IL_n_n
#  $2  - env var name
#  $3  - value to set to
# [$4] - string describing why this instruction is optional
# [$5] - indexed array name with the removed entries
# [$6] - indexed array name with the new entries
#        The arrays must still be defined,
#        when executing IL___format() and its silibings.
function IL___append___set() {
    local l_IL___instr_n
    __IL___append_new_empty_instr "$1"
    local -n l_IL___instr="$l_IL___instr_n"
    l_IL___instr=( \
        ["kind"]="set" \
        ["var_n"]="$2" \
        ["val"]="$3" \
    )
    if [[ "$4" ]] ; then
        l_IL___instr["opt_desc_str"]="$4"
    fi
    if is_var_defined "$5" ; then
        l_IL___instr["removed_entries_n"]="$5"
    fi
    if is_var_defined "$6" ; then
        l_IL___instr["add_entries_n"]="$6"
    fi
}

# $1 - ret str var name
# $2 - IL_n_n
# $3 - callbacks array name
#          ["set"] <ret str var name> <var_n> <val> [<opt_desc_str>] [<removed_entries_n>] [<new_entries_n>]
#       ["delete"] <ret str var name> <var_n>
#          ["raw"] <ret str var name> <string>
#        ["other"] <ret str var name> <string>
#       The variable <ret str var name> is always preset to the empty string
#       Optional arguments to the callbacks are provided, but empty if not set.
function IL___format() {
    if [[ "$1" != "l_IL___str" ]] ; then
        local -n l_IL___str="$1"
    fi
    
    if [[ "$2" != "l_IL___IL_n" ]] ; then
        local -n l_IL___IL_n="$2"
    fi
    if [[ "$3" != "l_IL___callbacks" ]] ; then
        local -n l_IL___callbacks="$3"
    fi
    
    local l_IL___callback___delete="${l_IL___callbacks["delete"]}" \
          l_IL___callback___set="${l_IL___callbacks["set"]}" \
          l_IL___callback___raw="${l_IL___callbacks["raw"]}" \
          l_IL___callback___other="${l_IL___callbacks["other"]}" \
          l_IL___instrs_cnt_n \
          l_IL___instr_n \
          l_IL___instr_str
    
    # trace_str_var l_IL___IL_n
    
    __IL___get_instrs_cnt_n
    local -n l_IL___instrs_cnt="$l_IL___instrs_cnt_n"
    
    l_IL___str=
    
    local -i l_IL___index=0
    while (( l_IL___index < l_IL___instrs_cnt )) ; do
        l_IL___instr_str=
        
        __IL___get_instr_n "$(( l_IL___index++ ))"
        local -n l_IL___instr="$l_IL___instr_n"
        
        trace_assoc_array "$l_IL___instr_n"
        
        case "${l_IL___instr["kind"]}" in
            delete)
                "$l_IL___callback___delete" l_IL___instr_str \
                    "${l_IL___instr["var_n"]}"
                ;;
            set)
                "$l_IL___callback___set" l_IL___instr_str \
                    "${l_IL___instr["var_n"]}" \
                    "${l_IL___instr["val"]}" \
                    "${l_IL___instr["opt_desc_str"]}" \
                    "${l_IL___instr["removed_entries_n"]}" \
                    "${l_IL___instr["add_entries_n"]}"
                ;;
            raw)
                "$l_IL___callback___raw" l_IL___instr_str \
                    "${l_IL___instr["str"]}"
                ;;
            other)
                "$l_IL___callback___other" l_IL___instr_str \
                    "${l_IL___instr["str"]}"
                ;;
        esac
        l_IL___str="${l_IL___str}${l_IL___instr_str}"
    done
}

# ========== Manually Format ===================

# $1 - ret str var name
# $2 - IL_n_n
function IL___format_manual() {
    local -A l_IL___callbacks=( \
           ["raw"]=__IL___format_manual___raw \
         ["other"]=__IL___format_manual___other \
        ["delete"]=__IL___format_manual___delete \
           ["set"]=__IL___format_manual___set \
    )
    
    local l_IL___instr_num_fmt="%d. " \
          l_IL___fmt_instr_num \
          l_IL___prev_instr_kind
    
    local -i l_IL___instr_num=0 \
             l_IL___highest_instr_num
    IL___get_instructions_count_except_other l_IL___highest_instr_num "$2"
    
    printf -v l_IL___fmt_instr_num "$l_IL___instr_num_fmt" "$l_IL___highest_instr_num"
    if [[ "$l_IL___fmt_instr_num" =~ \n[^\n]*$ ]] ; then
        local -i l_IL___intend_spaces_cnt="${#BASH_REMATCH[0]}"
    else
        local -i l_IL___intend_spaces_cnt="${#l_IL___fmt_instr_num}"
    fi
    
    IL___format "$1" "$2" l_IL___callbacks
}

# sets l_IL___fmt_instr_num
# 
# uses from calling comtext:
# l_IL___instr_num
# l_IL___intend_spaces_cnt
# l_IL___instr_num_fmt
function __IL___format_manual___instr_num() {
    printf -v l_IL___fmt_instr_num "$l_IL___instr_num_fmt" "$(( ++l_IL___instr_num ))"
    printf -v l_IL___fmt_instr_num "%*s" "$l_IL___intend_spaces_cnt" "$l_IL___fmt_instr_num"
}

# $1 - ret str var name
# $2 - string
#
# uses from calling context:
# l_IL___instr_num   (which must be incremented)
# l_IL___highest_instr_num
function __IL___format_manual___raw() {
    __IL___format_manual___instr_num
    
    intend_long_str_with_first_line_prefix "$1" \
        "$l_IL___fmt_instr_num" \
        "$2"$'\n'
    
    if [[ ( "$l_IL___prev_instr_kind" ) \
       && ( "$l_IL___prev_instr_kind" != "raw" ) ]]
    then
        if [[ "$1" != "l_IL___str" ]] ; then
            local -n l_IL___str="$1"
        fi
        l_IL___str=$'\n'"$l_IL___str"
    fi
    
    l_IL___prev_instr_kind="raw"
}

# $1 - ret str var name
# $2 - string
function __IL___format_manual___other() {
    printf -v "$1" "%s\n" "$2"
    
    if [[ "$l_IL___prev_instr_kind" ]] ; then
        if [[ "$1" != "l_IL___str" ]] ; then
            local -n l_IL___str="$1"
        fi
        l_IL___str=$'\n'"$l_IL___str"
    fi
    
    l_IL___prev_instr_kind="other"
}

# $1 - ret str var name
# $2 - var_n
#
# uses from calling context:
# l_IL___instr_num   (which must be incremented)
# l_IL___highest_instr_num
function __IL___format_manual___delete() {
    __IL___format_manual___instr_num
    
    local l_IL___str_1
    printf -v l_IL___str_1 "\
Check whether the environment variable %s exists.
If so, delete it." \
        "$2"
    
    intend_long_str_with_first_line_prefix "$1" \
        "$l_IL___fmt_instr_num" \
        "$l_IL___str_1"$'\n'
        
    if [[ "$l_IL___prev_instr_kind" ]] ; then
        if [[ "$1" != "l_IL___str" ]] ; then
            local -n l_IL___str="$1"
        fi
        l_IL___str=$'\n'"$l_IL___str"
    fi
    
    l_IL___prev_instr_kind="delete"
}

#  $1  - ret str var name
#  $2  - var_n
#  $3  - val
# [$4] - string describing why this instruction is optional
# [$5] - removed_entries_n
# [$6] - new_entries_n
#
# uses from calling context:
# l_IL___instr_num   (which must be incremented)
# l_IL___highest_instr_num
function __IL___format_manual___set() {
    __IL___format_manual___instr_num
    
    if [[ "$1" != "l_IL___str" ]] ; then
        local -n l_IL___str="$1"
    fi
    
    local l_IL___str_opt \
          l_IL___str_create \
          l_IL___str_set
    
    # optional describing string
    if [[ "$4" ]] ; then
        printf -v l_IL___str_opt \
            "Optional:\n%s\n" \
            "$4"
    fi
    
    # instruction string
    printf -v l_IL___str_create "\
If the environment variable %s does not yet exist, then create it." \
        "$2"
    printf -v l_IL___str_set "\
Set the environment variable %s to the following value:" \
        "$2"
    
    if [[ "$4" ]] ; then
        l_IL___str_create="${l_IL___str_opt}"$'\n'"${l_IL___str_create}"
    fi
    
    intend_long_str_with_first_line_prefix l_IL___str_set \
        "$l_IL___fmt_instr_num" \
        "$l_IL___str_create"$'\n'"$l_IL___str_set"$'\n'
    
    l_IL___str="${l_IL___str_set}"$'\n'"${3}"$'\n'
    
    # removed entries
    __IL___format_manual___set___vals "$5" "$2" "\
This new value for %s will remove the following yet existing entry:" "\
This new value for %s will remove the following %d yet existing entries:" "\
This new value will not remove any yet existing entries in %s ."
    
    # new entries
    __IL___format_manual___set___vals "$6" "$2" "\
This new value for %s will add the following new entry:" "\
This new value for %s will add the following %d new entries:" "\
This new value will not add further entries to %s ."
    
    if [[ "$l_IL___prev_instr_kind" ]] ; then
        l_IL___str=$'\n'"$l_IL___str"
    fi
    
    l_IL___prev_instr_kind="set"
}

# for removed or added vals
# 
# $1 - indexed array name
# $2 - var_n
# $3 - one entry string format <var_n>
# $4 - multiple entries format <var_n> <entries_cnt>
# $5 - no entries format <var_n>
# 
# uses from calling context:
# l_IL___str
# l_IL___intend_spaces_cnt
function __IL___format_manual___set___vals() {
    if is_var_undefined "$1" ; then
        return
    fi
    
    local -n l_IL___entries="$1"
    
    if (( "${#l_IL___entries[@]}" > 0 )) ; then
        local l_IL___str_vals \
              l_IL___IFS_backup="$IFS" \
              l_IL___concated_vals
        
        if (( "${#l_IL___entries[@]}" > 1 )) ; then
            printf -v l_IL___str_vals "$4" "$2" "${#l_IL___entries[@]}"
        else
            printf -v l_IL___str_vals "$3" "$2"
        fi
        
        IFS=$'\n'
        l_IL___concated_vals="${l_IL___entries[*]}"
        IFS="$l_IL___IFS_backup"
        
        intend_long_str l_IL___concated_vals "$l_IL___concated_vals"
        
        l_IL___str_vals="${l_IL___str_vals}"$'\n'"${l_IL___concated_vals}"
    else
        printf -v l_IL___str_vals "\
This new value will not remove any yet existing entries in %s ." \
            "$2"
    fi
    
    intend_long_str_with_spaces l_IL___str_vals \
        "$l_IL___intend_spaces_cnt" \
        "$l_IL___str_vals"$'\n'
        
    l_IL___str="${l_IL___str}"$'\n'"${l_IL___str_vals}"
}
