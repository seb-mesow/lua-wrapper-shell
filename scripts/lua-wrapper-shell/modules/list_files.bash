exec_module files_listing

# prints a grouped list of all files, that can be patched with their:
# - uFK
# - original filepath
# - current md5sum
# - if an equal patched file with for this md5sum is available
# - if a patch file is available
# 
# arguments:
# [$@] - uFKs or uGKs, if no are given "all" is assumed
function lf___list_files() {
    CFA___define_config
    debug_config_vars
    
    local -A l_lf___query \
             l_lf___callbacks
    
    l_lf___query["uFK"]=
    l_lf___query["org_filepath"]=
    l_lf___query["org___is_busy"]=
    l_lf___query["org___current_md5sum"]=
    l_lf___query["backup_filepath"]=
    l_lf___query["patch_filepath"]=
    l_lf___query["patched_filepath"]=
    l_lf___query["patched_edit_filepath"]=
    l_lf___query["last_resort_backup_filepath"]=
    
    local l_lf___FL_n
    FL___new_FL_from_uFKs_or_uGKs l_lf___FL_n l_lf___query "$@"
    
    l_lf___callbacks["group"]=lf___list_files___group
    l_lf___callbacks["file"]=__lf___list_files___file
    
    local l_lf___str
    FL___format_as_groups l_lf___str "$l_lf___FL_n" l_lf___callbacks
    printf "%s" "$l_lf___str"
    
    exit 0
}

# $1 - ret str var name
# $2 - uGK of a group
# $3 - formatted files str of the files in this group
function lf___list_files___group() {
    local l_lf___files_str
    intend_long_str l_lf___files_str "$3"
    
    printf -v "$1" \
        "group ${ANSI___seq___GK}%s${ANSI___seq___end}\n%s" \
        "$2" \
        "$l_lf___files_str"
}

# $1 - ret str var name
# $2 - LFA_n
# $3 - already_printed?
function __lf___list_files___file() {
    if (( "$3" )) ; then
        return
    fi
    
    local -n l_lf___LFA="$2"
    
    local -A l_lf___customization_array
    
    # original filepath
    l_lf___customization_array=( \
        ["format_value_callback"]=convert_path_to_win \
    )
    if ! lf___format_file___desc_info_str "$1" "$2" \
        "org_filepath" \
        "original filepath" \
        l_lf___customization_array
    then
        lf___format_file___desc_info_str___warn "$1" \
            "original file missing!"
    fi
    
    # is org file busy
    if (( "${l_lf___LFA["org___is_busy"]}" )) ; then
        lf___format_file___desc_info_str___warn "$1" \
            "The original file is currently in use and thus patched."
    fi
    
    # md5sum
    if ! lf___format_file___desc_info_str "$1" "$2" \
        "org___current_md5sum" \
        "current MD5sum of original file"
    then
        lf___format_file___desc_info_str___warn "$1" \
            "Thus no reliable MD5sum can be calculated !"
    fi
    
    # backup filepath
    l_lf___customization_array=( \
        ["ANSI_esc_seq"]="$ANSI___seq___warning" \
        ["format_value_callback"]=convert_path_to_win \
    )
    trap___no_ERR lf___format_file___desc_info_str "$1" "$2" \
        "backup_filepath" \
        "backup filepath" \
        l_lf___customization_array
    
    # patched filepath
    # if (( "${l_lf___LFA["org___is_busy"]}" )) ; then
    #     lf___format_file___desc_info_str___warn "$1" \
    #         "With no MD5sum no patched file can be selected !"
    # else
        if ! lf___format_file___desc_info_str "$1" "$2" \
            "patched_filepath" \
            "patched filepath"
        then
            local l_lf___warn_str
            if (( "${l_lf___LFA["org___is_busy"]}" )) ; then
                l_lf___warn_str="With no reliable MD5sum no patched file can be selected !"
            elif [[ -v l_lf___LFA["org_filepath"] ]] ; then
                l_lf___warn_str="patched file missing !"
            else
                l_lf___warn_str="Thus no patched file can be selected !"
            fi
            lf___format_file___desc_info_str___warn "$1" "$l_lf___warn_str"
        fi
    # fi
    
    # patch filepath
    if ! lf___format_file___desc_info_str "$1" "$2" \
        "patch_filepath" \
        "patch filepath"
    then
        lf___format_file___desc_info_str___warn "$1" \
            "patch file missing !"
    fi
    
    # patched_edit filepath
    l_lf___customization_array=( \
        ["ANSI_esc_seq"]="$ANSI___seq___hint"
        ["format_value_callback"]=__lf___list_files___format_patched_edit_filepath \
    )
    trap___no_ERR lf___format_file___desc_info_str "$1" "$2" \
        "patched_edit_filepath" \
        "patched edit filepath" \
        l_lf___customization_array
    
    # last resort filepath
    l_lf___customization_array=( \
        ["format_value_callback"]=convert_path_to_win \
    )
    if ! lf___format_file___desc_info_str "$1" "$2" \
        "last_resort_backup_filepath" \
        "last resort backup filepath" \
        l_lf___customization_array
    then
        lf___format_file___desc_info_str___warn "$1" \
            "last resort backup file missing!"
    fi
    
    # uFK
    lf___format_file___prepend_uFK "$1" "$2"
}

# prepends the uFK to the string
# and intends the existing string
# requires, that the LFA contains an entry "uFK"
#
# arguments:
# $1  - string var name to prepend to
function lf___format_file___prepend_uFK() {
    local -n l_lf___str_="$1" \
             l_lf___LFA_="$2"
    
    if [[ ! -v l_lf___LFA_["uFK"] ]] ; then
        internal_err "LFA misses uFK field"
    fi
    
    intend_long_str l_lf___str_ "$l_lf___str_"
    
    printf -v "$1" \
        "file ${ANSI___seq___FK}%s${ANSI___seq___end}\n%s" \
        "${l_lf___LFA_["uFK"]}" \
        "${l_lf___str_}"
}

# formats the description and info (for a particular value of the query)
# and appends it to a string.
# 
# arguments:
#  $1  - string var name to append to
#  $2  - LFA_n
#  $3  - info (key of query assoc array)
#  $4  - description
# [$5] - customization array name:
#        ["ANSI_esc_seq"]
#           - styles the whole desc_info_str
#           - automatically closed with ANSI___seq___end
#        ["format_value_callback"]
#           - <format_value_callback> <ret str var name> <value str>
function lf___format_file___desc_info_str() {
    local -n l_lf___str_="$1" \
             l_lf___LFA_="$2"
    
    if [[ ! -v l_lf___LFA_["$3"] ]] ; then
        return 1
    fi
    
    local l_lf___val="${l_lf___LFA_["$3"]}" \
          l_lf___info_str \
          l_lf___desc_info_str
    
    if [[ -v 5 ]] ; then
        local -n l_lf___customization_array_="$5"
        local l_lf___ANSI_seq___start="${l_lf___customization_array_["ANSI_esc_seq"]}"
        if [[ "${l_lf___customization_array_["format_value_callback"]}" ]]
        then
            "${l_lf___customization_array_["format_value_callback"]}" \
                l_lf___val "$l_lf___val"
        fi
    else
        local l_lf___ANSI_seq___start=
    fi
    
    intend_long_str l_lf___info_str \
        "${l_lf___val}${l_lf___ANSI_seq___start:+$ANSI___seq___end}"$'\n'
    
    printf -v l_lf___desc_info_str \
        "${l_lf___ANSI_seq___start}%s:\n%s" \
        "$4" "$l_lf___info_str"
    
    l_lf___str_="${l_lf___str_}${l_lf___desc_info_str}"
}

# appends a warning string to a string
# 
# arguments:
# $1 - string var name to append description and info to
# $2 - message
function lf___format_file___desc_info_str___warn() {
    local -n l_lf___str_="$1" \
    
    local l_lf___desc_info_str
    
    printf -v l_lf___desc_info_str \
        "${ANSI___seq___warning}%s${ANSI___seq___end}\n" \
        "$2"
    
    l_lf___str_="${l_lf___str_}${l_lf___desc_info_str}"
}

# $1 - ret str var name
# $2 - value
function __lf___list_files___format_patched_edit_filepath() {
    if [[ "$2" =~ ^"$PWD" ]] ; then
        local -n l_lf___val_="$1"
        l_lf___val_=".${2#"$PWD"}"
    fi
}
