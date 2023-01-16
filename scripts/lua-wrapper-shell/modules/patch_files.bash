# ========== Configuration for Files to Patch ====================

# uFK ... user-provided file key
#  FK ... internal file key
# uGK ... user-provided group key
#  GK ... internal group key

# module: CFA
#   CFA___provide_CFAn_from_FK(), FK_to_CFAn_map 
#   CFA
#       assoc array for a file provided by the config module
#   CFA___provide_CGAn_from_GK(), GK_to_CGAn_map
#   CGA
#       assoc array for a group of files provided by the config module
#       maps each contained FK to its CFAn
#
# module PFA:
#   PFA
#       assoc array for a file, which stores intermediate values and filepaths
#       especially it contains all /real/, absolute filepaths
#
# module patch_files - Show Files
#   m_pf___FK_to_SFAn_map___FKs, m_pf___FK_to_SFAn_map___SFAns
#   SFA
#       assoc array for a file, which stated what kind of file is requested to show.
# 
# module patch_files - List Files 
#   l_pf___FK_to_LFAn_map___FKs, l_pf___FK_to_LFAn_map___LFAns
#   LFA
#       assoc array for a file, which contains infos to list
#   l_pf___GK_to_LGAn_map
#   LGA
#       assoc array for a group of files to list infos about
#       corresponds to an CGA
#       maps each contained /and requested/ FK to its LFAn 
#
# CFAn, CGAn, PFAn, SFAn, LFAn, LGAn
#       full variable name of such an array
#       normally contains the FK resp. GK

exec_module config
exec_module CFA
exec_module PFA

#  $1     - ret indexed array var name for the PFAns
#  $2     - ret indexed array var name for the FKs
# [$3...] - uFKs or uGKs, default: show all
function __pf___PFAns_and_FKs_from_uFKs_or_uGKs() {
    local -n l_pf___PFAns__="$1"
    shift
    
    CFA___FKs_from_uFKs_or_uGKs "$@"
    
    local -n l_pf___FKs__="$1"
    local l_pf___PFAn
    for l_pf___FK in "${l_pf___FKs__[@]}" ; do
        
        PFA___new_from_FK l_pf___PFAn "$l_pf___FK"
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
    
        l_pf___PFAns__+=("$l_pf___PFAn")
    done
}

# ========== Querying PFAs ====================

# An LFA is a record with the information to print for each mentioned FK
# LFA ... list file array
# An LGA maps each /mentioned/ FK of the corresponding CGA to its LFAn
# LGA ... list group array

# $1 - l_pf___FK_to_LFAn_map___FKs   (indexed array, part of two arrays)
# $2 - l_pf___FK_to_LFAn_map___LFAns (indexed array, part of two arrays)
# $3 - l_pf___GK_to_LGAn_map         (assoc array)
# $4 - l_pf___FKs                    (indexed array, same subscripts as l_pf___PFAns)
# $5 - l_pf___PFAns                  (indexed array, same subscripts as l_pf___FKs)
# $6 - l_pf___PFA_query              (assoc array)
#      what information to query from each PFA
function __pf___query_FKs_and_PFAs() {
    local -n l_pf___FKs_="$4" \
             l_pf___PFAns_="$5"
    
    local l_pf___FK l_pf___PFAn l_pf___LFAn
    for l_pf___subscript in "${!l_pf___FKs_[@]}" ; do
        l_pf___FK="${l_pf___FKs_["${l_pf___subscript}"]}"
        l_pf___PFAn="${l_pf___PFAns_["${l_pf___subscript}"]}"
        
        __pf___augment_FK_to_LFAn_map_with_PFA_infos_about_FK_and_PFA \
                l_pf___LFAn "$1" "$2" "$l_pf___FK" "$l_pf___PFAn" "$6"
        
        __pf___augment_GK_to_LGAn_map_with_groups_of_FK \
                "$3" "$l_pf___FK" "$l_pf___LFAn"
    done
}

# also implicitly creates the LFA as needed
#
# arguments:
# $1 - ret var name for LFAn
# $2 - l_pf___FK_to_LFAn_map___FKs   (indexed array, part of two arrays)
# $3 - l_pf___FK_to_LFAn_map___LFAns (indexed array, part of two arrays)
# $4 - $l_pf___FK
# $5 - $l_pf___PFAn
# $6 - l_pf___PFA_query              (assoc array)
#      what information to query from each PFA
function __pf___augment_FK_to_LFAn_map_with_PFA_infos_about_FK_and_PFA() {
    local -n l_pf___LFAn_="$1"
    l_pf___LFAn_="l_pf___LFA___$4"
    
    if [[ ! -v "$l_pf___LFAn_" ]] ; then
        declare -g -A "$l_pf___LFAn_"
    fi
    
    PFA___query "$l_pf___LFAn_" "$5" "$6"
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) exc___unhandled ;;
    esac
        
    # get uFK
    local l_pf___PFA_query_="$6"
    if [[ -v l_pf___PFA_query_["uFK"] ]] ; then
        local -n l_pf___LFA="$l_pf___LFAn_" \
                 l_pf___CFA="${FK_to_CFAn_map["$4"]}"
        l_pf___LFA["uFK"]="${l_pf___CFA["uFK"]}"
    else
        unset l_pf___PFA_query_["uFK"]
    fi
    
    local -n l_pf___FK_to_LFAn_map___FKs_="$2" \
             l_pf___FK_to_LFAn_map___LFAns_="$3"
    l_pf___FK_to_LFAn_map___FKs_+=("$4")
    l_pf___FK_to_LFAn_map___LFAns_+=("$l_pf___LFAn_")
}

# also implicitly creates the LGA as needed
# 
# arguments:
# $1 - l_pf___GK_to_LGAn_map
# $2 - $l_pf___FK
# $3 - $l_pf___LFAn
function __pf___augment_GK_to_LGAn_map_with_groups_of_FK() {
    local -n l_pf___GK_to_LGAn_map_="$1"
    
    local l_pf___LGAn
    for l_pf___GK in "${!GK_to_CGAn_map[@]}" ; do
        local -n l_pf___CGA="${GK_to_CGAn_map["$l_pf___GK"]}"
        
        l_pf___LGAn="l_pf___LGA___${l_pf___GK}"
        for l_pf___CGA_FK in "${!l_pf___CGA[@]}" ; do
            if [[ "$l_pf___CGA_FK" == "$2" ]] ; then
                
                if [[ ! -v "$l_pf___LGAn" ]] ; then
                    declare -g -A "$l_pf___LGAn"
                fi
                local -n l_pf___LGA="$l_pf___LGAn"
                
                l_pf___LGA["$2"]="$3"
                l_pf___GK_to_LGAn_map_["$l_pf___GK"]="$l_pf___LGAn"
                
            fi
        done
    done
}

# uses from calling context:
# l_pf___sub_GK_to_CGAn_map
# l_pf___org_filename
# l_pf___FK
# l_pf___PFAn
function __pf___sub_GK_to_LGAn_map_and_org_filename_from_FK_and_PFAn() {
    CFA___sub_GK_to_CGAn_map_from_FK l_pf___sub_GK_to_CGAn_map "$l_pf___FK"
    
    local l_pf___org_dirpath
    
    PFA___get_org_filepath_components \
        l_pf___org_dirpath l_pf___org_filename "$l_pf___PFAn"
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) exc___unhandled ;; # not handle here
    esac
    
    log_str_var l_pf___org_filename
}

# ========== Functions related to Files to Patch ====================

# These functions deal with the patching and backuping of /multiple/ files.

function __pf___define_config() {
    cfg___define_general_config
    CFA___define_config
    debug_config_vars
}

function usage_building_patches() {
    user_msg <<__end__
to create a patch file, do the following with root privileges (#):
1. # $0 ${lua_version} -pp
2. edit the file ${hardcoded_lua[patched_edit]}
3. edit the file ${system_config_lua[patched_edit]}
4. # $0 ${lua_version} -fbp
__end__
}

# TODO In which module this function should be placed
# TODO is it used anyway
# $1 - filepath
function error_file_to_patch_does_not_exist() {
    user_msg <<__end__
file to patch
$1
does not exist
__end__
}

function pf___install_patches() {
    local -a l_pf___FKs l_pf___PFAns
    __pf___PFAns_and_FKs_from_uFKs_or_uGKs l_pf___PFAns l_pf___FKs "$@"
    
    trace_two_arrays l_pf___FKs l_pf___PFAns
    
    for l_pf___PFAn in "${l_pf___PFAns[@]}" ; do
        
        PFA___install "$l_pf___PFAn"
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
    
    done
}

# ========== Building Patches (for CLI) ====================

#  $1     - PFA method name to call on each PFAn
# [$2...] - uFKs or uGKs
function __pf___start_building___edit_build___patches() {
    __pf___define_config
    
    local l_pf___PFA_method="$1"
    shift
    
    local -a l_pf___FKs l_pf___PFAns
    __pf___PFAns_and_FKs_from_uFKs_or_uGKs l_pf___PFAns l_pf___FKs "$@"
    
    trace_two_arrays l_pf___FKs l_pf___PFAns
    
    local l_pf___FK l_pf___PFAn
    for l_pf___subscript in "${!l_pf___PFAns[@]}" ; do
        l_pf___FK="${l_pf___FKs["$l_pf___subscript"]}"
        # needed in a much deeper function inside __pf___PFA___exc___busy()
        
        l_pf___PFAn="${l_pf___PFAns["$l_pf___subscript"]}"
        
        trap___no_ERR "$l_pf___PFA_method" "$l_pf___PFAn"
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            PFA___exc___busy)
                __pf___PFA___exc___busy "$l_pf___PFA_method"
                ;;
            PFA___exc___no_org)
                __pf___PFA___exc___no_org "$l_pf___PFA_method"
                ;;
            *) exc___unhandled ;;
        esac
        
    done
    
    user_msg "Now do the following with root privileges (#):"
    
    local -i l_pf___i=0
    
    local -A l_pf___LFA \
             l_pf___PFA_query
    l_pf___PFA_query["patched_edit_filepath"]=
    for l_pf___PFA_n in "${l_pf___PFAns[@]}" ; do
        
        PFA___query l_pf___LFA "$l_pf___PFA_n" l_pf___PFA_query
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) exc___unhandled ;;
        esac
        
        user_msg_plainf \
            "%d. edit the file %s" \
            "$(( ++l_pf___i ))" \
            "${l_pf___LFA["patched_edit_filepath"]}"
    done
    
    local l_pf___cmd_line
    cmd_line_from_args l_pf___cmd_line \
            "$0" "${lua_version}" -fbp "$@"
    user_msg_plain "$(( l_pf___i + 1 )). # ${l_pf___cmd_line}"
    
    if (( l_pf___i > 1 )) ; then
        user_msg <<__end__
Please do not be irritated, because the files to edit have Unix-style line endings.
(Every line ends with a line feed control character (LF).)

The files to edit were converted from and will be converted to Windows-style line endings.
(Lines are seperated by a carriage return and line feed character (CR-LF).)
__end__
    else
        user_msg <<__end__
Please do not be irritated, because the file to edit has Unix-style line endings.
(Every line ends with a line feed control character (LF).)

The file to edit was converted from and will be converted to Windows-style line endings.
(Lines are seperated by a carriage return and line feed character (CR-LF).)
__end__
    fi
    
    exit 0
}

# [$@] - uFKs or uGKs
function pf___start_building_patches() {
    __pf___start_building___edit_build___patches \
            "PFA___start_building" \
            "$@"
}
function pf___edit_builded_patches() {
    __pf___start_building___edit_build___patches \
            "PFA___edit_build" \
            "$@"
}

# [$@] - uFKs or uGKs
function pf___abort_building_patches() {
    __pf___define_config
    
    local -a l_pf___FKs
    
    CFA___FKs_from_uFKs_or_uGKs l_pf___FKs "$@"
    
    trace_indexed_array l_pf___FK
    
    local l_pf___PFAn
    for l_pf___FK in "${l_pf___FKs[@]}" ; do
        PFA___new_from_FK l_pf___PFAn "$l_pf___FK"
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) exc___unhandled ;;
        esac
        
        PFA___abort_building "$l_pf___PFAn"
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) exc___unhandled ;;
        esac
    done
    
    exit 0
}

# [$@] - uFKs or uGKs
function pf___repair() {
    __pf___define_config
    
    local -a l_pf___FKs
    
    CFA___FKs_from_uFKs_or_uGKs l_pf___FKs "$@"
    
    trace_indexed_array l_pf___FK
    
    local l_pf___PFAn
    for l_pf___FK in "${l_pf___FKs[@]}" ; do
        PFA___new_from_FK l_pf___PFAn "$l_pf___FK"
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) exc___unhandled ;;
        esac
        
        PFA___repair "$l_pf___PFAn"
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            PFA___exc___not_any_backup)
                __pf___PFA___not_any_backup PFA___repair
                ;;
            *) exc___unhandled ;;
        esac
    done
    
    exit 0
}

 # [$@] - uFKs or uGKs
function pf___finish_building_patches() {
    
    # ----- execution --------------------
    
    __pf___define_config
    
    local -a l_pf___FKs l_pf___PFAns
    __pf___PFAns_and_FKs_from_uFKs_or_uGKs l_pf___PFAns l_pf___FKs "$@"
    
    trace_two_arrays l_pf___FKs l_pf___PFAns
    
    local l_pf___cmd_line \
          l_pf___formatted_files_info \
          l_pf___FL_n \
          l_pf___FK l_pf___PFAn
    
    for l_pf___subscript in "${!l_pf___PFAns[@]}" ; do
        l_pf___FK="${l_pf___FKs["$l_pf___subscript"]}"
        # needed in a much deeper function inside __pf___PFA___exc___busy()
        
        l_pf___PFAn="${l_pf___PFAns["$l_pf___subscript"]}"
        
        PFA___finish_building "$l_pf___PFAn"
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            PFA___exc___busy)
                __pf___PFA___exc___busy PFA___finish_building
                ;;
            PFA___exc___no_org)
                __pf___PFA___exc___no_org PFA___finish_building
                ;;
            *) exc___unhandled ;;
        esac
    done
    
    # ----- message --------------------
    
    local -A  l_pf___formating_callbacks \
              l_pf___PFA_query=( \
                  ["uFK"]= \
                  ["patched_filepath"]= \
                  ["patch_filepath"]= \
              )
    
    # exec_module ANSI
    # TODO There should be no color output, if the ANSI module is not loaded.
    
    exec_module files_listing
    
    FL___new_FL_from_FKs l_pf___FL_n l_pf___PFA_query l_pf___FKs
    
    exec_module list_files
    
    l_pf___formating_callbacks=( \
        ["group"]=lf___list_files___group \
         ["file"]=__pf___finish_building_patches___format_file \
    )
    
    FL___format_as_groups l_pf___formatted_files_info "$l_pf___FL_n" \
        l_pf___formating_callbacks
    
    user_msg "created patches for the following files:"
    user_msg "${l_pf___formatted_files_info%$'\n'}"
    
    if (( "${#l_pf___FKs[@]}" > 1 )) ; then
        user_msg "To review your patches, execute the following:"
    else
        user_msg "To review your patch, execute the following:"
    fi
    cmd_line_from_args l_pf___cmd_line \
            "$0" "$lua_version" -sd "$@"
    user_msg_plain "\$ ${l_pf___cmd_line}"
    
    exit 0
}

# $1 - ret str var name
# $2 - LFA_n
# $3 - already_printed?
function __pf___finish_building_patches___format_file() {
    if (( "$3" )) ; then
        return
    fi
    
    lf___format_file___desc_info_str "$1" "$2" \
        "patched_filepath" \
        "patched filepath"
    
    lf___format_file___desc_info_str "$1" "$2" \
        "patch_filepath" \
        "patch filepath"
    
    lf___format_file___prepend_uFK "$1" "$2"
}



# ========== Show Files (for CLI) ====================

declare -g -a m_pf___FK_to_SFAn_map___FKs \
              m_pf___FK_to_SFAn_map___SFAns

# We maintain an array for each known file with the following keys set or not set
# [org], [diff], [patched]
#
# arguments:
#  $1     - SFA key
# [$2...] - uFKs of uGKs
function __pf___register_file_to_show() {
    cfg___define_general_config
    CFA___define_config
    
    local l_pf___SFA_key="$1"
    
    shift
    
    local -a l_pf___FKs
    CFA___FKs_from_uFKs_or_uGKs l_pf___FKs "$@"
    
    trace_indexed_array l_pf___FKs
    
    for l_pf___FK in "${l_pf___FKs[@]}" ; do
        local l_pf___SFAn="m_pf___SFA___$l_pf___FK"
        if [[ ! -v "$l_pf___SFAn" ]] ; then
            declare -g -A "$l_pf___SFAn"
            m_pf___FK_to_SFAn_map___FKs+=("$l_pf___FK")
            m_pf___FK_to_SFAn_map___SFAns+=("$l_pf___SFAn")
        fi
        local -n l_pf___SFA="$l_pf___SFAn"
        l_pf___SFA["$l_pf___SFA_key"]=1 # may overwrite with same value
    done
}

# [$@] - uFKs or uGKs
function pf___register_original_file_to_show() {
    __pf___register_file_to_show "org" "$@"
}
function pf___register_diff_to_show() {
    __pf___register_file_to_show "diff" "$@"
}
function pf___register_patched_file_to_show() {
    __pf___register_file_to_show "patched" "$@"
}

function pf___show_registered_files_to_show() {
    if (( "${#m_pf___FK_to_SFAn_map___FKs[@]}" > 0 )) ; then
        debug_config_vars
        
        trace_two_arrays m_pf___FK_to_SFAn_map___FKs m_pf___FK_to_SFAn_map___SFAns
        
        local l_pf___FK l_pf___PFAn
        for l_pf___subscript in "${!m_pf___FK_to_SFAn_map___FKs[@]}" ; do
            l_pf___FK="${m_pf___FK_to_SFAn_map___FKs["$l_pf___subscript"]}"
            local -n l_pf___SFA="${m_pf___FK_to_SFAn_map___SFAns["$l_pf___subscript"]}"
            
            trace_assoc_array "${m_pf___FK_to_SFAn_map___SFAns["$l_pf___subscript"]}"
            
            PFA___new_from_FK l_pf___PFAn "$l_pf___FK"
            case "$EXCEPTION_ID" in
                '') ;; # no exception
                *) exc___unhandled ;; # not handle here
            esac
    
            if [[ -v l_pf___SFA["org"] ]] ; then
                __pf___show PFA___show_original
            fi
            if [[ -v l_pf___SFA["diff"] ]] ; then
                __pf___show PFA___show_diff
            fi
            if [[ -v l_pf___SFA["patched"] ]] ; then
                __pf___show PFA___show_patched
            fi
        done
        
        exit 0
    fi
}

# $1 - PFA method name
# 
# uses from calling context:
# l_pf___FK
# l_pf___PFAn 
function __pf___show() {
    trap___no_ERR "$1" "$l_pf___PFAn"
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        PFA___exc___busy)
            __pf___PFA___exc___busy "$1"
            ;;
        PFA___exc___no_org)
            __pf___PFA___exc___no_org "$1"
            ;;
        *) exc___unhandled ;;
    esac
}

# ========== Handling Exception / Error Messages ====================

# $1 - PFA method name
# 
# uses from calling context:
# l_pf___FK
# l_pf___PFAn
function __pf___PFA___exc___busy() {
    exc___ignore
    
    local -A l_pf___sub_GK_to_CGAn_map
    local l_pf___org_filename
    __pf___sub_GK_to_LGAn_map_and_org_filename_from_FK_and_PFAn
    
    log_str_var l_pf___FK
    log_str_var l_pf___PFAn
    log_assoc_array l_pf___sub_GK_to_CGAn_map
    
    if [[ -v l_pf___sub_GK_to_CGAn_map["sub_shell"] ]] ; then
        __pf___PFA___exc___busy___group_subshell "$1"
    elif [[ -v l_pf___sub_GK_to_CGAn_map["luarocks_install"] ]] ; then
        __pf___PFA___exc___busy___group_luarocks_install "$1"
    else
        internal_errf "\
The file\n%s\nbelongs to a group unknown to __pf___PFA___exc___busy() \
or belongs to no group at all." \
            "$l_pf___org_filename"
    fi
}

# $1 - PFA method name
# 
# uses from calling context:
# l_pf___FK
# l_pf___PFAn
function __pf___PFA___exc___no_org() {
    exc___ignore
    
    local -A l_pf___sub_GK_to_CGAn_map
    local l_pf___org_filename
    __pf___sub_GK_to_LGAn_map_and_org_filename_from_FK_and_PFAn
    
    log_str_var l_pf___FK
    log_str_var l_pf___PFAn
    log_assoc_array l_pf___sub_GK_to_CGAn_map
    
    if [[ -v l_pf___sub_GK_to_CGAn_map["sub_shell"] ]] ; then
        __pf___PFA___exc___no_org___group_subshell "$1"
    elif [[ -v l_pf___sub_GK_to_CGAn_map["luarocks_install"] ]] ; then
        __pf___PFA___exc___no_org___group_luarocks_install "$1"
    else
        internal_errf "\
The file\n%s\nbelongs to a group unknown to __pf___PFA___exc___no_org() \
or belongs to no group at all." \
            "$l_pf___org_filename"
    fi
}

# $1 - PFA method name
# 
# uses from calling context:
# l_pf___FK
# l_pf___PFAn
function __pf___PFA___not_any_backup() {
    exc___ignore
    
    local -A l_pf___sub_GK_to_CGAn_map
    local l_pf___org_filename
    __pf___sub_GK_to_LGAn_map_and_org_filename_from_FK_and_PFAn
    
    log_str_var l_pf___FK
    log_str_var l_pf___PFAn
    log_assoc_array l_pf___sub_GK_to_CGAn_map
    
    if [[ -v l_pf___sub_GK_to_CGAn_map["sub_shell"] ]] ; then
        __pf___PFA___not_any_backup___group_subshell "$1"
    elif [[ -v l_pf___sub_GK_to_CGAn_map["luarocks_install"] ]] ; then
        __pf___PFA___not_any_backup___group_luarocks_install "$1"
    else
        internal_errf "\
The file\n%s\nbelongs to a group unknown to __pf___PFA___not_any_backup() \
or belongs to no group at all." \
            "$l_pf___org_filename"
    fi
}

# $1 - PFA method name
# 
# uses from calling context:
# l_pf___org_filename
function __pf___PFA___exc___busy___group_subshell() {
    local l_pf___err_str
    
    case "$1" in
                
        PFA___edit_build)
            printf -v l_pf___err_str "\
The build patch for\n%s\ncan not be edited, \
while a subshell is running." \
                "$l_pf___org_filename"
            exc___user_err "$l_pf___err_str" "\
Exit the running subshell, \
before editing the build patch for this file."
            ;;
        
        PFA___finish_building)
            printf -v l_pf___err_str "\
Building the patch for\n%s\ncan not be finished, \
while a subshell is running." \
                "$l_pf___org_filename"
            exc___user_err "$l_pf___err_str" "\
Exit the running subshell, \
before finishing building the patch for this file." \
            ;;
        
        PFA___start_building)
            printf -v l_pf___err_str "\
Building the patch for\n%s\ncan not be started, \
while a subshell is running." \
                "$l_pf___org_filename"
            exc___user_err "$l_pf___err_str" "\
Exit the running subshell, \
before starting building the patch for this file." \
            ;;
        
        PFA___show_diff)
            printf -v l_pf___err_str "\
The diff between the original file\n%s\nand its patched version can not be shown, \
while a subshell is running." \
                "$l_pf___org_filename"
            exc___user_msg "$l_pf___err_str" "\
Exit the running subshell, \
before showing the diff for this file."
            ;;
        
        PFA___show_patched)
            printf -v l_pf___err_str "\
The patched version of the file\n%s\ncan not be shown, \
while a subshell is running." \
                "$l_pf___org_filename"
            exc___user_msg "$l_pf___err_str" "\
Exit the running subshell, \
before showing the patched version of this file."
            ;;
        
        PFA___show_original)
            printf -v l_pf___err_str "\
The original file\n%s\ncan not be shown, \
while a subshell is running." \
                "$l_pf___org_filename"
            exc___user_msg "$l_pf___err_str" "\
Exit the running subshell, \
before showing this original file"
            ;;
        
        *) internal_errf "\
__pf___PFA___exc___busy___group_subshell() \
was called with the PFA method\n%s\nunknown to it." \
                "$1"
            ;;
    esac
}

# $1 - PFA method name
# 
# uses from calling context:
# l_pf___org_filename
function __pf___PFA___exc___busy___group_luarocks_install() {
    local l_pf___err_str
    
    case "$1" in
        
        PFA___edit_build)
            printf -v l_pf___err_str "\
The build patch for\n%s\ncan not be edited, \
during an ongoing installation of LuaRocks." \
                "$l_pf___org_filename"
            exc___user_err "$l_pf___err_str" "\
Finish (or abort) the ongoing installation of LuaRocks, \
before editing the build patch for this file."
            ;;
        
        PFA___finish_building)
            printf -v l_pf___err_str "\
Building the patch for\n%s\ncan not be finished, \
during an ongoing installation of LuaRocks." \
                "$l_pf___org_filename"
            exc___user_err "$l_pf___err_str" "\
Finish (or abort) the ongoing installation of LuaRocks, \
before finishing building the patch for this file."
            ;;
        
        PFA___start_building)
            printf -v l_pf___err_str "\
Building the patch for\n%s\ncan not be started, \
during an ongoing installation of LuaRocks." \
                "$l_pf___org_filename"
            exc___user_err "$l_pf___err_str" "\
Finish (or abort) the ongoing installation of LuaRocks, \
before starting building the patch for this file."
            ;;
        
        PFA___show_diff)
            printf -v l_pf___err_str "\
The diff between the original file\n%s\nand its patched version can not be shown, \
during an ongoing installation of LuaRocks." \
                "$l_pf___org_filename"
            exc___user_msg "$l_pf___err_str" "\
Finish (or abort) the ongoing installation of LuaRocks, \
before showing the diff for this file."
            ;;
        
        PFA___show_patched)
            printf -v l_pf___err_str "\
The patched version of the file\n%s\ncan not be shown, \
during an ongoing installation of LuaRocks." \
                "$l_pf___org_filename"
            exc___user_msg "$l_pf___err_str" "\
Finish (or abort) the ongoing installation of LuaRocks, \
before showing the patched version of this file."
            ;;
        
        PFA___show_original)
            printf -v l_pf___err_str "\
The original file\n%s\ncan not be shown, \
during an ongoing installation of LuaRocks." \
                "$l_pf___org_filename"
            exc___user_msg "$l_pf___err_str" "\
Finish (or abort) the ongoing installation of LuaRocks, \
before showing this original file."
            ;;
        
        *) internal_errf "\
__pf___PFA___exc___busy___group_luarocks_install() \
was called with the PFA method\n%s\nunknown to it." \
                "$1"
            ;;
    esac
}

# $1 - PFA method name
# 
# uses from calling context:
# l_pf___org_filename
function __pf___PFA___exc___no_org___group_subshell() {
    local l_pf___err_str \
          l_pf___help_str \
          l_pf___help_str___install_luarocks
    
    case "$1" in
        
        PFA___edit_build)
            printf -v l_pf___err_str "\
The build patch for\n%s\ncan not be edited, \
while Luarocks is not installed." \
                "$l_pf___org_filename"
            printf -v l_pf___help_str "\
Install Lua %s and LuaRocks for this environment, \
before editing the build patch for this file." \
                "$lua_version"
            ;;
        
        PFA___finish_building)
            printf -v l_pf___err_str "\
Building the patch for\n%s\ncan not be finished, \
while Luarocks is not installed." \
                "$l_pf___org_filename"
            printf -v l_pf___help_str "\
Install Lua %s and LuaRocks for this environment, \
before finishing building the patch for this file." \
                "$lua_version"
            ;;
        
        PFA___start_building)
            printf -v l_pf___err_str "\
Building the patch for\n%s\ncan not be started, \
while Luarocks is not installed." \
                "$l_pf___org_filename"
            printf -v l_pf___help_str "\
Install Lua %s and LuaRocks for this environment, \
before starting building the patch for this file." \
                "$lua_version"
            ;;
        
        PFA___show_diff)
            printf -v l_pf___err_str "\
The diff between the original file\n%s\nand its patched version can not be shown, \
while Luarocks is not installed." \
                "$l_pf___org_filename"
            printf -v l_pf___help_str "\
Install Lua %s and LuaRocks for this environment, \
before showing the diff for this file." \
                "$lua_version"
            ;;
        
        PFA___show_patched)
            printf -v l_pf___err_str "\
The patched version of the file\n%s\ncan not be shown, \
while Luarocks is not installed." \
                "$l_pf___org_filename"
            printf -v l_pf___help_str "\
Install Lua %s and LuaRocks for this environment, \
before showing the patched version of this file." \
                "$lua_version"
            ;;
        
        PFA___show_original)
            printf -v l_pf___err_str "\
The original file\n%s\ncan not be shown, \
while Luarocks is not installed." \
                "$l_pf___org_filename"
            printf -v l_pf___help_str "\
Install Lua %s and LuaRocks for this environment, \
before showing this original file." \
                "$lua_version"
            ;;
        
        *) internal_errf "\
__pf___PFA___exc___no_org___group_subshell() \
was called with the PFA method\n%s\nunknown to it." \
                "$1"
            ;;
    esac
    
    exec_module err_help_strs
    
    help_str___install_luarocks l_pf___help_str___install_luarocks
    printf -v l_pf___help_str "%s\n\n%s" \
        "$l_pf___help_str" "$l_pf___help_str___install_luarocks"
    
    if [[ "$1" == *"show"* ]] ; then
        exc___user_msg "$l_pf___err_str" "$l_pf___help_str"
    else
        exc___user_err "$l_pf___err_str" "$l_pf___help_str"
    fi
}

# $1 - PFA method name
# 
# uses from calling context:
# l_pf___org_filename
function __pf___PFA___exc___no_org___group_luarocks_install() {
    local l_pf___err_str \
          l_pf___help_str \
          l_pf___help_str___download_luarocks
    
    case "$1" in
        
        PFA___edit_build)
            printf -v l_pf___err_str "\
The build patch for\n%s\ncan not be edited, \
while this script can not find LuaRocks install sources for Windows." \
                "$l_pf___org_filename"
            printf -v l_pf___help_str "\
Download the LuaRocks install sources for Windows, \
before editing the build patch for this file."
            ;;
        
        PFA___finish_building)
            printf -v l_pf___err_str "\
Building the patch for\n%s\ncan not be finished, \
while this script can not find LuaRocks install sources for Windows." \
                "$l_pf___org_filename"
            printf -v l_pf___help_str "\
Download the LuaRocks install sources for Windows, \
before finishing building the patch for this file."
            ;;
        
        PFA___start_building)
            printf -v l_pf___err_str "\
Building the patch for\n%s\ncan not be started, \
while this script can not find LuaRocks install sources for Windows." \
                "$l_pf___org_filename"
            printf -v l_pf___help_str "\
Download the LuaRocks install sources for Windows, \
before starting building the patch for this file."
            ;;
        
        PFA___show_diff)
            printf -v l_pf___err_str "\
The diff between the original file\n%s\nand its patched version can not be shown, \
while this script can not find LuaRocks install sources for Windows." \
                "$l_pf___org_filename"
            printf -v l_pf___help_str "\
Download the LuaRocks install sources for Windows, \
before showing the diff for this file."
            ;;
        
        PFA___show_patched)
            printf -v l_pf___err_str "\
The patched version of the file\n%s\ncan not be shown, \
while this script can not find LuaRocks install sources for Windows." \
                "$l_pf___org_filename"
            printf -v l_pf___help_str "\
Download the LuaRocks install sources for Windows, \
before showing the patched version of this file."
            ;;
        
        PFA___show_original)
            printf -v l_pf___err_str "\
The original file\n%s\ncan not be shown, \
while this script can not find LuaRocks install sources for Windows." \
                "$l_pf___org_filename"
            printf -v l_pf___help_str "\
Download the LuaRocks install sources for Windows, \
before showing this original file."
            ;;
        
        *) internal_errf "\
__pf___PFA___exc___no_org___group_luarocks_install() \
was called with the PFA method\n%s\nunknown to it." \
                "$1"
            ;;
    esac
    
    exec_module err_help_strs
    
    help_str___download_luarocks_sources l_pf___help_str___download_luarocks
    printf -v l_pf___help_str "%s\n\n%s" \
        "$l_pf___help_str" "$l_pf___help_str___download_luarocks"
    
    if [[ "$1" == *"show"* ]] ; then
        exc___user_msg "$l_pf___err_str" "$l_pf___help_str"
    else
        exc___user_err "$l_pf___err_str" "$l_pf___help_str"
    fi
}

# $1 - PFA method name
# 
# uses from calling context:
# l_pf___org_filename
function __pf___PFA___not_any_backup___group_subshell() {
    local l_pf___err_str \
          l_pf___help_str \
          l_pf___help_str___install_luarocks
    
    case "$1" in
        
        PFA___repair)
            printf -v l_pf___err_str "\
The original file\n%s\ncould not be repaired,
because neither its backup file nor its last resort backup file exists." \
                "$l_pf___org_filename"
            printf -v l_pf___help_str "\
Install Lua %s and LuaRocks for this environment, \
instead of repairing this file." \
                "$lua_version"
            ;;
        *) internal_errf "\
__pf___PFA___not_any_backup___group_subshell() \
was called with the PFA method\n%s\nunknown to it." \
                "$1"
            ;;
    esac
    
    exec_module err_help_strs
    
    help_str___install_luarocks l_pf___help_str___install_luarocks
    printf -v l_pf___help_str "%s\n\n%s" \
        "$l_pf___help_str" "$l_pf___help_str___install_luarocks"
    
    exc___user_msg "$l_pf___err_str" "$l_pf___help_str"
}

# $1 - PFA method name
# 
# uses from calling context:
# l_pf___org_filename
function __pf___PFA___not_any_backup___group_luarocks_install() {
    local l_pf___err_str \
          l_pf___help_str \
          l_pf___help_str___download_luarocks
    
    case "$1" in
        
        PFA___repair)
            printf -v l_pf___err_str "\
The original file\n%s\ncould not be repaired,
because neither its backup file nor its last resort backup file exists." \
                "$l_pf___org_filename"
            # TODO show location of found LuaRocks install sources.
            printf -v l_pf___help_str "\
Remove the found LuaRocks install sources for Windows \
and download new LuaRocks install sources, \
instead of repairing this file."
            ;;
        *) internal_errf "\
__pf___PFA___not_any_backup___group_luarocks_install() \
was called with the PFA method\n%s\nunknown to it." \
                "$1"
            ;;
    esac
    
    exec_module err_help_strs
    
    help_str___download_luarocks_sources l_pf___help_str___download_luarocks
    printf -v l_pf___help_str "%s\n\n%s" \
        "$l_pf___help_str" "$l_pf___help_str___download_luarocks"
    
    exc___user_msg "$l_pf___err_str" "$l_pf___help_str"
}
