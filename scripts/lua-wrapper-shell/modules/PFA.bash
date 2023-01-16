# These functions deal with the patching and backuping of /single/ files.

# By convention only a patch for one version (MD5sum) of every original file
# can be build by the user in the current directory at a time.
# 
# It is assumed, that the patch file could be applied
# to every version (MD5sum) of the original file.


# ========== Use Cases ====================

# start building patch (formerly: prepare patch)
#     1. calculate MD5sum of the original file
#     2. persistently save the MD5sum of the original file for finishing the patch
#     3. copy the patched file to the current dir for editing by the user
# 
# finish building patch (formerly: finish patch)
#     1. copy the patched file from the current dir to the wrapper env dir
#        with the previously saved MD5sum attached
#     2. delete the persistently saved MD5sum
#     3. create the patch file as the fallback
# 
# use patch
#     I. install patch (formerly: apply patch)
#         1. create master backup if not yet existing
#         2. create normal backup
#         3. calculate MD5sum of the original file
#         4. if MD5sum is equal to a patched file in the wrapper env dir,
#             4a. then
#                 4aa. replace the original file with this patched file,
#             4b else
#                 4ba patch the original file with the patch file.
#         5. create the used file
#     II. <use the patched file>
#     III. uninstall patch (formerly: recover backup)
#         1. replace the patched file by the normal backup
# 
# list infos
#     # TODO
# 
# show original file
#     1. print the original file to terminal
# 
# show patch file
#     1. calculate MD5sum of the original file
#     2. if MD5sum is equal to a patched file in the wrapper env dir,
#        2a. then
#             2aa. create a temp diff file of the difference
#                  between the original file and the patched file in the wrapper env dir
#             2ab. specifed file := temp diff file
#        2b. else
#             2ba. specifed file := patch file
#     3. print the specifed file to the terminal
# 
# show patched file
#     1. calculate MD5sum of the original file
#     2. if MD5sum is equal to a patched file in the wrapper env dir,
#        2a. then
#             2aa. specifed file := patched file in the wrapper env dir
#        2b. else
#             2ba. create a temp copy of the original patch
#             2bb. patch the temp copy
#             2bc. specifed file := temp file
#     3. print the specifed file to the terminal

# ======== Notes on Meaningful User Error Messages ====================
# 
# - Why should the PFA do something ? (context/command)
#       (helpful for the user)
#       - to connect the error to his/her commands, also this is maybe repetitive
# - Which uFK or filename does the operating PFA represent ? (object)
#       (in /some/ contexts relevant for the user)
#       - can expose internals
# - What should the PFA do? (operation)
#       (less relevant for the user)
#       - can expose internals
# - What problem did the operating PFA encountered? (barrier)
#       (not relevant for the user)
#       - can expose internals
#       - technically this is the main information, which an exception carries.
# - Why did the barrier probably encountered ? (reason)
#       (very helpful for the user)
#       - What did /the user/ did wrong?
#       - Altough this uses "negative language"
#         it trains the user to correctly give commands.
#       - Can be manually derived from context/command and barrier (sometimes also operation)
# - What /can/ be done to probably solve the problem (help)
#       (most helpful for the user)
#       - What should the user do now?
#       - especially further commands
#       - Can be derived from either barrier (How to solve the problem?)
#         or context/command + reason (What to do instead?)
# 
# 1. part: short sentence describing the context/command and reason
#          - What could not be done (context/command)
#            while/because of some condition? (reason, maybe also a part of the context)
# Optional; if low debugging level: object, operation, barrier (in this order)
# 2. part: help
# Optional; if high debugging level: callstack

# The author decided to write the type of exception to a well known global variable.
# As soon as the barrier encountered, the function writes to the global variable
# and must return as early as possible (Therefore the return status can be used.
# But it is not mandatory to set the return status.), same for all calling functions ...
# ... Until some function detects the non-zero exit status, reads the global variable
# and prints an oppropriate error message.
# This style resembles a try-catch-blocks at most.

# The barrier and other information (e.g. object) are placed in the global variable EXCEPTION.
# The barrier is an ID string placed at EXCEPTION["ID"].
# The Callstack at the time of the barrier is named EXCEPTION_CALLSTACK
# If there is no exception the EXCEPTION object must not be defined.
#
# (The alternative would be to print the error message as soon as the barrier was detected.
# This would require to have a more ore less global context object with callbacks for each exception to handle.)


# ======== Keys of an PFA ====================
#   
#   filename
#       basename of the original file to patch
#   
#   org
#       filepath of the original file to patch
#    
#   backup
#       filepath of the backup
#       of the original version of the file to patch
#   
#   master_backup
#       filepath of the backup
#       of the original version of the file as it was saved,
#       when no master backup of it yet existed
#   
#   patched_edit 
#       filepath of the patched version of the file to patch
#       for editing by the user in the current directory
#   
#   patched_edit_md5sum
#       filepath to persistently store the MD5sum of the
#       original file, that will be attached to the patched file
#       when finishing building the patch
#   
#   patched_stem
#       stem of the filepath of the patched version of the file to patch
#       for keeping
#   
#   patch
#       filepath of the patchfile, which, when applied to the
#       original version of the file to patch, edits it, that it
#       is equivalent to the patched version of the file to patch
#   
#   used
#       filepath of that version of the file to patch,
#       that was actually used by LuaRocks

# ========== Exceptions ====================
#
# PFA___exc___no_org
#       not any original file exists
# PFA___exc___org_not_readable
#       The "element" at the original filepath is not a readable file
# PFA___exc___busy
#       propably the file at the original filepath is not the original file,
#       but rather the patched file or the original file patched with the patch file
# PFA___exc___no_patched_no_patch
#       neither patch file nor patched file exists
# PFA___exc___no_MD5sum
#       the temporary file with the MD5sum from start building the patch does not exist
# PFA___exc___no_patched_edit
#       the file for editing the patched file does not exists
# PFA___exc___patched_edit_not_readable
#       the "element" at the patched_edit filepath is not a readable file
# PFA___exc___not_any_backup
#       neither the backup file nor the last resort backup exists

exec_module ext_cmds

# $1 - key
#
# uses from calling context:
# l_PFA___CFA
# l_PFA___CFAn
function __PFA___assert_CFA_has_key() {
    if [[ ! -v l_PFA___CFA["$1"] ]] ; then
        local l_PFA___key_bash_word
        bash_word_from_str l_PFA___key_bash_word "$1"
        internal_errf "%s misses key %s" \
            "$l_PFA___CFAn"
            "$l_PFA___key_bash_word"
    fi
    if [[ -z "${l_PFA___CFA["$1"]}" ]] ; then
        local l_PFA___key_bash_word
        bash_word_from_str l_PFA___key_bash_word "$1"
        internal_errf "%s has empty key %s" \
            "$l_PFA___CFAn"
            "$l_PFA___key_bash_word"
    fi
}

# defines a PFA from an CFA via the provided FK
# 
# arguments 
#  $1  - ret var name for PFAn of just created PFA
#  $2  - FK
function PFA___new_from_FK() {
    local -n l_PFA___PFAn="$1"
    
    l_PFA___PFAn="m_PFA___PFA___$2"
    if is_var_undefined "$l_PFA___PFAn" ; then
        declare -g -A "$l_PFA___PFAn"
    fi
    local -n l_PFA___PFA="$l_PFA___PFAn"
    
    if [[ -v l_PFA___PFA["org"] ]] ; then
        return
    fi
    
    local l_PFA___CFAn
    CFA___provide_CFAn_from_FK l_PFA___CFAn "$2"
    debug_assoc_array "$l_PFA___CFAn"
    local -n l_PFA___CFA="$l_PFA___CFAn"
    
    # check for correct CFA
    __PFA___assert_CFA_has_key "org"
    __PFA___assert_CFA_has_key "org_filename"
    __PFA___assert_CFA_has_key "uFK"
    
    exec_module config
    cfg___define_wrapper_excl_env_config
    debug_config_vars
    
                      l_PFA___PFA["org"]="${l_PFA___CFA["org"]}"
                      l_PFA___PFA["uFK"]="${l_PFA___CFA["uFK"]}"
    l_PFA___PFA["org_filename___preset"]="${l_PFA___CFA["org_filename"]}"
    
    debug_assoc_array "$l_PFA___PFAn"
}

# ========== Getters for Filenames ====================

# $1 - varname
function __PFA___assert_var_is_defined() {
    if is_var_undefined "$1" ; then
        internal_errf "%s is not yet defined." "$1"
    fi
}

# uses from calling context:
# l_PFA___PFA

# ---------- miscellaneous getters --------------------

# sets l_PFA___uFK
function __PFA___get_uFK() {
    __PFA___assert_var_is_defined l_PFA___uFK
    l_PFA___uFK="${l_PFA___PFA["uFK"]}"
    if [[ -z "$l_PFA___uFK" ]] ; then
        internal_errf "value at key \"uFK\" of %s is empty" \
            "${!l_PFA___PFA}"
    fi
}

# ---------- kept filepaths --------------------

# sets l_PFA___kept_filepath
function __PFA___get_kept_filepath() {
    __PFA___assert_var_is_defined l_PFA___kept_filepath
    l_PFA___kept_filepath="${l_PFA___PFA["kept_filepath"]}"
    if [[ -z "$l_PFA___kept_filepath" ]] ; then
        local l_PFA___org_filename
        __PFA___get_org_filename
        l_PFA___kept_filepath=\
"${wrapper_envdir}/${l_PFA___org_filename}"
        l_PFA___PFA["kept_filepath"]="$l_PFA___kept_filepath"
    fi
}
# sets l_PFA___patch_filepath
function __PFA___get_patch_filepath() {
    __PFA___assert_var_is_defined l_PFA___patch_filepath
    l_PFA___patch_filepath="${l_PFA___PFA["patch_filepath"]}"
    if [[ -z "$l_PFA___patch_filepath" ]] ; then
        local l_PFA___kept_filepath
        __PFA___get_kept_filepath
        l_PFA___patch_filepath=\
"${l_PFA___kept_filepath}.patch"
        l_PFA___PFA["patch_filepath"]="$l_PFA___patch_filepath"
    fi
}
# sets l_PFA___patched_edit_md5sum_filepath
function __PFA___get_patched_edit_md5sum_filepath() {
    __PFA___assert_var_is_defined l_PFA___patched_edit_md5sum_filepath
    l_PFA___patched_edit_md5sum_filepath="${l_PFA___PFA["patched_edit_md5sum"]}"
    if [[ -z "$l_PFA___patched_edit_md5sum_filepath" ]] ; then
        local l_PFA___kept_filepath
        __PFA___get_kept_filepath
        l_PFA___patched_edit_md5sum_filepath=\
"${l_PFA___kept_filepath}.patched_edit.md5sum"
        l_PFA___PFA["patched_edit_md5sum"]="$l_PFA___patched_edit_md5sum_filepath"
    fi
}
# ---------- filepaths in users working directory --------------------

# sets l_PFA___patched_edit_filepath
function __PFA___get_patched_edit_filepath() {
    __PFA___assert_var_is_defined l_PFA___patched_edit_filepath
    l_PFA___patched_edit_filepath="${l_PFA___PFA["patched_edit_filepath"]}"
    if [[ -z "$l_PFA___patched_edit_filepath" ]] ; then
        local l_PFA___org_filename
        __PFA___get_org_filename
        l_PFA___patched_edit_filepath=\
"./${l_PFA___org_filename}.${wrapper_name_for_filenames}.patched"
        l_PFA___PFA["patched_edit_filepath"]="$l_PFA___patched_edit_filepath"
    fi
}

# ---------- org derived filepaths --------------------

# sets l_PFA___org_derived_filepath
function __PFA___get_org_derived_filepath() {
    __PFA___assert_var_is_defined l_PFA___org_derived_filepath
    l_PFA___org_derived_filepath="${l_PFA___PFA["org_derived_filepath"]}"
    if [[ -z "$l_PFA___org_derived_filepath" ]] ; then
        local l_PFA___org_filepath
        
        __PFA___get_org_filepath___impl
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
        
        l_PFA___org_derived_filepath=\
"${l_PFA___org_filepath}.${wrapper_name_for_filenames}"
        l_PFA___PFA["org_derived_filepath"]="$l_PFA___org_derived_filepath"
    fi
}
# sets l_PFA___backup_filepath
function __PFA___get_backup_filepath() {
    __PFA___assert_var_is_defined l_PFA___backup_filepath
    l_PFA___backup_filepath="${l_PFA___PFA["backup_filepath"]}"
    if [[ -z "$l_PFA___backup_filepath" ]] ; then
        local l_PFA___org_derived_filepath
        
        __PFA___get_org_derived_filepath
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
        
        l_PFA___backup_filepath=\
"${l_PFA___org_derived_filepath}.backup"
        l_PFA___PFA["backup_filepath"]="$l_PFA___backup_filepath"
    fi
}
# sets l_PFA___last_resort_backup_filepath
# (formerly "master backup")
function __PFA___get_last_resort_backup_filepath() {
    __PFA___assert_var_is_defined l_PFA___last_resort_backup_filepath
    l_PFA___last_resort_backup_filepath="${l_PFA___PFA["last_resort_backup_filepath"]}"
    if [[ -z "$l_PFA___last_resort_backup_filepath" ]] ; then
        local l_PFA___org_derived_filepath
        
        __PFA___get_org_derived_filepath
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
        
        l_PFA___last_resort_backup_filepath=\
"${l_PFA___org_derived_filepath}.last_resort.backup"
        l_PFA___PFA["last_resort_backup_filepath"]="$l_PFA___last_resort_backup_filepath"
    fi
}
# sets l_PFA___used_filepath
# (formerly "master backup")
function __PFA___get_used_filepath() {
    __PFA___assert_var_is_defined l_PFA___used_filepath
    l_PFA___used_filepath="${l_PFA___PFA["used_filepath"]}"
    if [[ -z "$l_PFA___used_filepath" ]] ; then
        local l_PFA___org_derived_filepath
        
        __PFA___get_org_derived_filepath
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
        
        l_PFA___used_filepath=\
"${l_PFA___org_derived_filepath}.used"
        l_PFA___PFA["used_filepath"]="$l_PFA___used_filepath"
    fi
}

# ---------- org filepath --------------------

# sets l_PFA___org_filename
# WITHOUT CHECKS IF IT EXISTS !
function __PFA___get_org_filename() {
    __PFA___assert_var_is_defined l_PFA___org_filename
    l_PFA___org_filename="${l_PFA___PFA["org_filename"]}"
    if [[ "$l_PFA___org_filename" ]] ; then
        return
    fi
    
    local l_PFA___org_filepath
    __PFA___get_org_filepath___impl
    case "$EXCEPTION_ID" in
        '') # no exception
            
            local l_PFA___org_dirpath
            split_filepath l_PFA___org_dirpath l_PFA___org_filename \
                        "$l_PFA___org_filepath"
            ;;
            
        PFA___exc___no_org)
            
            l_PFA___org_filename="${l_PFA___PFA["org_filename___preset"]}"
            exc___ignore
            ;;
            
        *) exc___unhandled ;; # not handle here
    esac
    
    l_PFA___PFA["org_filename"]="$l_PFA___org_filename"
}

# sets l_PFA___org_filepath
# WITHOUT CHECKS IF IT EXISTS !
# 
# Note the special evaluation of the value at the "org" subscript of the CFA:
# 
# If the original file yet exists, then the value can be the ordinary filepath.
# This value is eval-ed once. Thus it can contain parameter expansions
# 
# But the value can also be a special function call.
# This function is then called with a ret str var name 
# to store the original filepath in and all remaining words as further arguments
# If the function can not find the file, it must set the ret str var to the empty string.
# 
# If the first word of the value is a declared function,
# then this function is called to obtain the original filepath.
# Else the value is directly considered as the original filepath
# (word == a largest substring with no blanks or a quoted substring)
# 
# exceptions:
#   PFA___exc___no_org
# 
# uses from calling context:
#   l_PFA___PFA
#   l_PFA___org_filepath
function __PFA___get_org_filepath___impl() {
    __PFA___assert_var_is_defined l_PFA___org_filepath
    l_PFA___org_filepath="${l_PFA___PFA["org_filepath"]}"
    if [[ "$l_PFA___org_filepath" ]] ; then
        return 0
    fi
    
    if [[ "${l_PFA___PFA["org_filepath___PFA___exc___no_org"]}" ]] ; then
        exc___raise "PFA___exc___no_org" \
            "This exception was raised before."
        return 0
    fi
    
    trace "start __PFA___get_org_filepath___impl"
    
    if [[ ! -v l_PFA___PFA["org"] ]] ; then
        internal_errf "%s misses key '%s'" "${!l_PFA___PFA}" "org"
    fi
    local l_PFA___org="${l_PFA___PFA["org"]}"
    
    __PFA___get_org_filepath___impl___try_call_func
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        PFA___exc___no_org)
            # memoize the failure
            l_PFA___PFA["org_filepath___PFA___exc___no_org"]=1
            # but not ignore the exception
            return 0
            ;;
        *) return 0 ;; # not handle here
    esac
    
    if [[ -z "$l_PFA___org_filepath" ]] ; then
        l_PFA___org_filepath="$l_PFA___org"
    fi
    
    l_PFA___PFA["org_filepath"]="$l_PFA___org_filepath"
    
    log_assoc_array "${!l_PFA___PFA}"
    
    trace "end __PFA___get_org_filepath___impl"
}

# uses from calling context:
# l_PFA___PFA
# l_PFA___org_filepath
# l_PFA___org
# 
# If l_PFA___org is not a function call, 
# then l_PFA___org_filepath is set to the empty string
# If l_PFA___org is a function call and this call successfully returns a filepath,
# then l_PFA___org_filepath is set to this filepath.
# (If the call is not sucessful, then the exception PFA___exc___no_org is raised.)
# 
# exceptions:
#   PFA___exc___no_org
function __PFA___get_org_filepath___impl___try_call_func() {
    trace_plain "start __PFA___get_org_filepath___impl___try_call_func"
    
    l_PFA___org_filepath=
    # By default the original file is considered to be not found.
    
    if [[ ! "$l_PFA___org" =~ ^[[:alnum:]_]+ ]] ; then
        trace_plain <<__end__
l_PFA___PFA["org"] does not start with alphanumeric chars
l_PFA___PFA["org"] == ${l_PFA___PFA["org"]}
(return fail)
__end__
        return 0
    fi
    local l_PFA___funcname="${BASH_REMATCH[0]}" \
          l_PFA___args="${l_PFA___org#"${BASH_REMATCH[0]}"}"
    
    if ! declare -p -F "$l_PFA___funcname" > /dev/null 2>&1 ; then
        trace_plainf "${l_PFA___funcname} is not defined (return fail)"
        return 0
    fi
    
    local l_PFA___cmd_line="\"${l_PFA___funcname}\" l_PFA___org_filepath${l_PFA___args}"
    trace_plainf "going to execute:\n${l_PFA___cmd_line}"
    
    "${l_PFA___funcname}" l_PFA___org_filepath${l_PFA___args}
    # To not quote the expansion of ${l_PFA___args} is required.
    
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    if [[ -z "$l_PFA___org_filepath" ]] ; then
        local l_PFA___exc___barrier
        printf -v l_PFA___exc___barrier \
            "The command line\n%s\nto find\n%s\nsets l_PFA___org_filepath to the empty string." \
            "$l_PFA___cmd_line" \
            "${l_PFA___PFA["uFK"]}"
        exc___raise "PFA___exc___no_org" "$l_PFA___exc___barrier"
        return 0
    fi
    
    trace "successfully end __PFA___get_org_filepath___impl___try_call_func"
    return 0
}

# sets l_PFA___org_filepath to the filepath
# of the existing, not busy and readable original file
# 
# exceptions:
#   PFA___exc___no_org
#   PFA___exc___org_not_readable
#   PFA___exc___busy
#   
# uses from calling context:
#   l_PFA___PFA
#   l_PFA___org_filepath
function __PFA___get_org_filepath() {
    __PFA___get_org_filepath___impl
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    local l_PFA___is_org_file_normal="${l_PFA___PFA["is_org_file_normal"]}"
    if [[ "$l_PFA___is_org_file_normal" ]] ; then
        return 0
    fi
    
    local -i l_PFA___temp_bool
    
    __PFA___does_org_file_exist l_PFA___temp_bool
    if (( ! l_PFA___temp_bool )) ; then
        local l_PFA___barrier_str
        printf -v l_PFA___barrier_str \
            "The original file\n%s\ndoes not exist." \
            "$l_PFA___org_filepath"
        exc___raise "PFA___exc___no_org" "$l_PFA___barrier_str"
        return 0
    fi
    
    __PFA___is_org_file_readable l_PFA___temp_bool
    if (( ! l_PFA___temp_bool )) ; then
        local l_PFA___barrier_str
        printf -v l_PFA___barrier_str \
            "The original file\n%s\nis not readable." \
            "$l_PFA___org_filepath"
        exc___raise "PFA___exc___org_not_readable" "$l_PFA___barrier_str"
        return 0
    fi
    
    __PFA___is_org_file_busy l_PFA___temp_bool
    if (( l_PFA___temp_bool )) ; then
        local l_PFA___barrier_str \
              l_PFA___backup_filepath
        
        __PFA___get_backup_filepath
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
        
        printf -v l_PFA___barrier_str \
            "The backup file\n%s\nexists." \
            "$l_PFA___backup_filepath"
        exc___raise "PFA___exc___busy" "$l_PFA___barrier_str"
        return 0
    fi
    
    l_PFA___PFA["is_org_file_normal"]=1
}

# ========== Boolean Predicates ====================

# sets the provided integer variable to a value greater than zero,
# if the original file exists
# if the original file not exists, the integer variable is set to zero.
# 
# arguments:
# $1 - ret int var name
# 
# uses from calling context:
# l_PFA___PFA
function __PFA___does_org_file_exist() {
    local -n l_PFA___bool="$1"
    
    local l_PFA___org_filepath
    
    __PFA___get_org_filepath___impl
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        PFA___exc___no_org)
            l_PFA___bool=0
            exc___ignore
            return
            ;;
        *) exc___unhandled ;;
    esac
    
    if [[ ( "$l_PFA___org_filepath" ) \
       && ( -f "$l_PFA___org_filepath" ) ]]
    then
        l_PFA___bool=1
    else
        l_PFA___bool=0
    fi
}

# sets the provided integer variable to a value greater than zero,
# if the original file exists and is readable
# if the original file not so, the integer variable is set to zero.
# 
# arguments:
# $1 - ret int var name
# 
# uses from calling context:
# l_PFA___PFA
function __PFA___is_org_file_readable() {
    local -n l_PFA___bool="$1"
    
    local l_PFA___org_filepath
    
    __PFA___get_org_filepath___impl
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        PFA___exc___no_org)
            l_PFA___bool=0
            exc___ignore
            return
            ;;
        *) exc___unhandled ;;
    esac
    
    if [[ ( "$l_PFA___org_filepath" ) \
       && ( -f "$l_PFA___org_filepath" ) \
       && ( -r "$l_PFA___org_filepath" ) ]]
    then
        l_PFA___bool=1
    else
        l_PFA___bool=0
    fi
}

# sets the provided integer variable to a value greater than zero,
# if the original file is not already changed, because of some other action.
# if the original file is not "busy", the integer variable is set to zero.
# 
# arguments:
# $1 - ret int var name
# 
# uses from calling context:
# l_PFA___PFA
function __PFA___is_org_file_busy() {
    local -n l_PFA___bool="$1"
    
    local l_PFA___backup_filepath
    
    __PFA___get_backup_filepath
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        PFA___exc___no_org)
            l_PFA___bool=0
            exc___ignore
            return
            ;;
        *) exc___unhandled ;;
    esac
    
    if [[ -e "$l_PFA___backup_filepath" ]] ; then
        l_PFA___bool=1
    else
        l_PFA___bool=0
    fi
}

# ========== Errors Messages =====================

# TODO obsolete

# # $1 - description of task:
# #      "You can not $1 for <filename> while running a subshell."
# # uses l_PFA___PFA from calling context
# function __PFA___assert_not_busy() {
#     if [[ -e "${l_PFA___PFA["backup"]}" ]] ; then
#         exc___raise "PFA___exc___busy" \
#             "The backup file"$'\n'"${l_PFA___PFA["backup"]}"$'\n'"exists"
#         return 1
#     fi
#     return 0
# }

# Usage: if __PFA___warn_if_org_file_not_exists ; then return fi
# $1 - description of task
#      "You can not $1 for <filename> while running a subshell."
# uses l_PFA___PFA and l_PFA___org_filepath from calling context
# function __PFA___warn_if_backup_exists() {
#     if [[ -e "${l_PFA___PFA["backup"]}" ]] ; then
#         exc___raise "PFA___exc___busy" \
#             "The backup file"$'\n'"${l_PFA___PFA["backup"]}"$'\n'"exists"
#         return 1
#     fi
#     return 0
# }

# $1 - ret str var name
# $2 - description of task
# uses l_PFA___PFA from calling context
# TODO obsolete
function __PFA___compose_err_str___backup_exists() {
    assign_long_str_no_trailing_linefeed "$1" <<__end__
${ANSI___seq___warning}You can not
${2}
for
${l_PFA___PFA["filename"]}
while running a subshell.${ANSI___seq___end}

In before you must exit the active subshell.
__end__
}

# $1 - description of task
# uses l_PFA___PFA and l_PFA___org_filepath from calling context
# function __PFA___assert_org_file_exists() {
#     if [[ ! -e "$l_PFA___org_filepath" ]] ; then
#         local l_PFA___barrier_str
#         printf -v l_PFA___barrier_str \
#             "The original file\n%s\ndoes not exist." \
#             "$l_PFA___org_filepath"
#         exc___raise "PFA___exc___no_org" "$l_PFA___barrier_str"
#         return 1
#     fi
#     if ! __PFA___assert_not_busy "$1" ; then
#         return 1
#     fi
#     return 0
# }

# Usage: if __PFA___warn_if_org_file_not_exists ; then return fi
# $1 - description of task
# 
# uses from calling context:
# l_PFA___PFA
# l_PFA___org_filepath 
# function __PFA___warn_if_org_file_not_exists() {
#     if [[ ! -e "$l_PFA___org_filepath" ]] ; then
#         exc___raise "PFA___exc___no_org" \
#             "The original file"$'\n'"$l_PFA___org_filepath"$'\n'"does not exist."
#         return 1
#     elif __PFA___assert_not_busy ; then
#         return 1
#     fi
#     return 0
# }

# $1 - ret str var name
# uses l_PFA___PFA and l_PFA___org_filepath from calling context
# TODO obsolete
function __PFA___compose_err_str___org_file_to_exists() {
    if declare -p -F "$l_PFA___org_filepath" > /dev/null 2>&1 ; then
        l_PFA___org_filepath="${l_PFA___PFA["filename"]}"
    fi
    
    assign_long_str_no_trailing_linefeed "$1" <<__end__
${ANSI___seq___warning}file to patch
${l_PFA___org_filepath}
does not exist${ANSI___seq___end}
__end__
    
    if [[ -v l_PFA___PFA["not_found_err_str_func_name"] ]] ; then
        local l_PFA___not_found_err_msg
        "${l_PFA___PFA["not_found_err_str_func_name"]}" l_PFA___not_found_err_msg
        l_PFA___not_found_err_msg="${l_PFA___not_found_err_msg#$'\n'}"
        l_PFA___not_found_err_msg="${l_PFA___not_found_err_msg#$'\n'}"
        l_PFA___not_found_err_msg="${l_PFA___not_found_err_msg%$'\n'}"
        l_PFA___not_found_err_msg="${l_PFA___not_found_err_msg%$'\n'}"
        local -n l_PFA___err_str_="$1"
        l_PFA___err_str_="${l_PFA___err_str_}"$'\n\n'"${l_PFA___not_found_err_msg}"
    fi
}

# $1 - ret str var name
# uses l_PFA___PFA from calling context
# TODO obsolete
function __PFA___compose_err_str___neither_patched_nor_patch_file() {
    local l_PFA___usage_str___building_patch
    __PFA___compose_usage_str___building_patch l_PFA___usage_str___building_patch
    assign_long_str_no_trailing_linefeed "$1" <<__end__
${ANSI___seq___warning}neither a patched file nor a patch file exists for 
${l_PFA___PFA["uFK"]}${ANSI___seq___end}

${l_PFA___usage_str___building_patch}
__end__
}

# $1 - ret str var name
# uses l_PFA___PFA from calling context
# TODO obsolete
function __PFA___compose_usage_str___building_patch() {
    local l_PFA___cmd_line_start_building_patch \
          l_PFA___cmd_line_finish_building_patch
    cmd_line_from_args l_PFA___cmd_line_start_building_patch \
        "$0" "$lua_version" -sbp "${l_PFA___PFA["uFK"]}"
    cmd_line_from_args l_PFA___cmd_line_finish_building_patch \
        "$0" "$lua_version" -fbp "${l_PFA___PFA["uFK"]}"
    assign_long_str_no_trailing_linefeed "$1" <<__end__
to create this patch, do the following with root privileges (#):
1. \$ ${l_PFA___cmd_line_start_building_patch}
2. edit the file ${l_PFA___PFA["patched_edit"]}
3. # ${l_PFA___cmd_line_finish_building_patch}
__end__
}

# ========== Internal Methods ====================

# sets l_PFA___org_current_md5sum
# 
# uses from calling context:
# l_PFA___PFA
#
# exceptions:
#   from deeper:
#   PFA___exc___no_org
#   PFA___exc___org_not_readable
#   PFA___exc___busy
function __PFA___get_org_current_md5sum() {
    __PFA___assert_var_is_defined l_PFA___org_current_md5sum
    l_PFA___org_current_md5sum="${l_PFA___PFA["org_current_md5sum"]}"
    if [[ -z "$l_PFA___org_current_md5sum" ]]; then
        local l_PFA___org_filepath
        
        __PFA___get_org_filepath
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
        
        calc_md5sum l_PFA___org_current_md5sum "$l_PFA___org_filepath"
        
        # practical tests showed, that md5___calc_sum_of_file does not outperform calc_md5sum.
        # 
        # exec_module md5sum
        # md5___calc_sum_of_file l_PFA___org_current_md5sum "$l_PFA___org_filepath"
        
        l_PFA___PFA["org_current_md5sum"]="$l_PFA___org_current_md5sum"
    fi
}

# sets l_PFA___patched_filepath
# DOES NOT set l_PFA___PFA["patched_filepath"] !
# 
# arguments:
# $1 - MD5sum
function __PFA___determinate_patched_filepath() {
    __PFA___assert_var_is_defined l_PFA___patched_filepath
    l_PFA___patched_filepath="${l_PFA___PFA["patched_filepath"]}"
    if [[ "$l_PFA___patched_filepath" ]] ; then
        return
    fi
    
    if [[ ! "$1" =~ ^[[:xdigit:]]+$ ]]; then
        local l_PFA___MD5sum_bash_word
        bash_word_from_str l_PFA___MD5sum_bash_word "$1"
        internal_err "malformed precomputed MD5sum $l_PFA___MD5sum_bash_word"
        # actually could also be a warning,
        # but it should be assured, to call this function correctly
    fi
    
    local l_PFA___kept_filepath
    __PFA___get_kept_filepath
    l_PFA___patched_filepath=\
"${l_PFA___kept_filepath}.${1}.patched"
}


# saves the excepted filepath of the patched file in the predeclared variable
# l_PFA___patched_filepath
# and
# if the patched file exists,
# sets the predefined integer variable l_PFA___does_patched_file_exist to non-zero;
# if the patched file does not exist,
# sets the predefined integer variable l_PFA___does_patched_file_exist to zero.
# 
# exceptions:
#   from deeper
#   PFA___exc___no_org
#   PFA___exc___org_not_readable
#   PFA___exc___busy
# 
# uses from calling context:
# l_PFA___PFA
# l_PFA___patched_filepath
# l_PFA___does_patched_file_exist
function __PFA___find_patched_file_for_md5sum() {
    __PFA___assert_var_is_defined l_PFA___patched_filepath
    __PFA___assert_var_is_defined l_PFA___does_patched_file_exist
    
    l_PFA___does_patched_file_exist=0
    # By default the patched file is considered to be not found.
    
    l_PFA___patched_filepath="${l_PFA___PFA["patched_filepath"]}"
    if [[ -z "$l_PFA___patched_filepath" ]] ; then
        l_PFA___patched_filepath=
        
        # 1. calculate MD5sum of the original file
        local l_PFA___org_current_md5sum
        
        __PFA___get_org_current_md5sum
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
    
        # 2. if MD5sum is equal to a patched file in the wrapper env dir,
        __PFA___determinate_patched_filepath "$l_PFA___org_current_md5sum"
    fi
    
    if [[ -v l_PFA___PFA["does_patched_file_exist"] ]] ; then
        l_PFA___does_patched_file_exist="${l_PFA___PFA["does_patched_file_exist"]}"
    else
        if [[ -f "$l_PFA___patched_filepath" ]] ; then
            l_PFA___does_patched_file_exist=1
        fi
        l_PFA___PFA["does_patched_file_exist"]="$l_PFA___does_patched_file_exist"
    fi
}

# returns a filepaths to a patched version of the file to patch
# with Unix-style line endings
# 
# This file could be obtained by the patched file (according to the current MD5sum)
# or by patching the original file with the patch file
# 
# arguments:
#  $1  - str var name for the filename
#        If undefined or null/empty string,
#        then a temporary file is created and this filepath stored in the var.
#        Else the provided value of the var is assumed
#        to be the filepath to store the patched version at.
# 
# uses from calling context:
# l_PFA___PFA
#
# exceptions:
#   PFA___exc___no_patched_no_patch
#   from deeper:
#   PFA___exc___no_org
#   PFA___exc___org_not_readable
#   PFA___exc___busy
function __PFA___filepath_of_patched___unix_line_endings() {
    local -n l_PFA___patched_filepath_unix="$1"
    
    if [[ -z "$l_PFA___patched_filepath_unix" ]] ; then
        temp_filepath l_PFA___patched_filepath_unix
    elif [[ -e "$l_PFA___patched_filepath_unix" ]] ; then
        internal_err <<__end__ 
There is already a file at the following filepath
${l_PFA___patched_filepath_unix}
It was asked, to place a patched version of the file to patch
${l_PFA___PFA["uFK"]}
there.
__end__
    fi
    
    # in order of first usage
    local l_PFA___patched_filepath
    local -i l_PFA___does_patched_file_exist
    
    __PFA___find_patched_file_for_md5sum
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    if (( l_PFA___does_patched_file_exist )) ; then
        
        dos2unix -n "$l_PFA___patched_filepath" "$l_PFA___patched_filepath_unix"
        return 0
        
    else
        
        # in order of first usage
        local l_PFA___patch_filepath \
              l_PFA___org_filepath
        
        __PFA___get_patch_filepath
        
        if [[ ! -f "$l_PFA___patch_filepath" ]] ; then
            local l_PFA___barrier_str
            printf -v l_PFA___barrier_str \
                "Neither the patched file\n%s\nnor the patch file\n%s\nexists." \
                "$l_PFA___patched_filepath" \
                "$l_PFA___patch_filepath"
            exc___raise PFA___exc___no_patched_no_patch "$l_PFA___barrier_str"
            return 0
        fi
        
        __PFA___get_org_filepath
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
        
        dos2unix -n "$l_PFA___org_filepath" "$l_PFA___patched_filepath_unix"
        patch -f "$l_PFA___patched_filepath_unix" "$l_PFA___patch_filepath"
        # The -f option to patch is a force option (do not complain on suspicious cirumstances)
        return 0
    fi
}

# sets
# l_PFA___patched_edit_filepath
# 
# uses from calling context:
# l_PFA___PFA
# l_PFA___patched_edit_filepath
function __PFA___start_building___edit_build___pre() {
    # l_PFA___patched_edit_filepath="${l_PFA___PFA["patched_edit"]}"
    __PFA___get_patched_edit_filepath
    
    if [[ -e "$l_PFA___patched_edit_filepath" ]] ; then
        local l_PFA___cmd_line_finish_building_patch \
              l_PFA___cmd_line_abort_building_patch \
              l_PFA___cmd_line_start_building_patch
        cmd_line_from_args l_PFA___cmd_line_finish_building_patch \
                "$0" "$lua_version" -fbp "${l_PFA___PFA["uFK"]}"
        cmd_line_from_args l_PFA___cmd_line_abort_building_patch \
                "$0" "$lua_version" -abp "${l_PFA___PFA["uFK"]}"
        cmd_line_from_args l_PFA___cmd_line_start_building_patch \
                "$0" "$lua_version" -sbp "${l_PFA___PFA["uFK"]}"
        user_err <<__end__
The file for editing the patch
${l_PFA___patched_edit_filepath}
already exists and this script will not overwrite it.

If you have yet patched this file, \
then execute the following, to finish building the patch:
\$ ${l_PFA___cmd_line_finish_building_patch}

If you have not yet patched this file, \
then execute the following, to start building a new patch from scratch:
1. \$ ${l_PFA___cmd_line_abort_building_patch}
2. \$ ${l_PFA___cmd_line_start_building_patch}
__end__
    fi
    
    # in order of first usage
    local l_PFA___org_current_md5sum \
          l_PFA___patched_edit_md5sum_filepath \
    
    # 1. calculate MD5sum of the original file
    __PFA___get_org_current_md5sum
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    # 2. persistently save the MD5sum of the original file for finishing the patch
    __PFA___get_patched_edit_md5sum_filepath
    write_to_file "$l_PFA___patched_edit_md5sum_filepath" \
        "<org current MD5sum>" \
        "$l_PFA___org_current_md5sum"
}

# $1 - PFAn
function PFA___start_building() {
    local -n l_PFA___PFA="$1"
    
    # in order of first usage
    local l_PFA___patched_edit_filepath \
          l_PFA___org_filepath
    
    __PFA___start_building___edit_build___pre
    
    __PFA___get_org_filepath
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    # 3. copy the patched file to the current dir for editing by the user 
    dos2unix -n "$l_PFA___org_filepath" "$l_PFA___patched_edit_filepath"
}

# $1 - PFAn
function PFA___edit_build() {
    local -n l_PFA___PFA="$1"
    
    # in order of first usage
    local l_PFA___patched_edit_filepath
    
    __PFA___start_building___edit_build___pre
    
    __PFA___filepath_of_patched___unix_line_endings l_PFA___patched_edit_filepath
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
}

# $1 - PFAn
function PFA___abort_building() {
    local -n l_PFA___PFA="$1"
    
    local l_PFA___patched_edit_filepath \
          l_PFA___patched_edit_md5sum_filepath
    __PFA___get_patched_edit_filepath
    __PFA___get_patched_edit_md5sum_filepath
    
    rm -f "$l_PFA___patched_edit_filepath" \
          "$l_PFA___patched_edit_md5sum_filepath"
}

# $1 - PFAn
function PFA___finish_building() {
    local -n l_PFA___PFA="$1"
    
    # in order of first usage
    local l_PFA___org_filepath \
          l_PFA___patched_edit_filepath \
          l_PFA___temp_org_filepath_unix \
          l_PFA___org_filename \
          l_PFA___patch_filepath \
          l_PFA___patched_edit_md5sum_filepath \
          l_PFA___former_org_md5sum \
          l_PFA___patched_filepath \
    
    __PFA___get_org_filepath
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    __PFA___get_patched_edit_filepath
    
    if [[ ! -e "$l_PFA___patched_edit_filepath" ]] ; then
        local l_PFA___usage_str___building_patch
        __PFA___compose_usage_str___building_patch l_PFA___usage_str___building_patch
        user_errf "patched file\n%s\ndoes not exist\n\n%s" \
            "$l_PFA___patched_edit_filepath" \
            "$l_PFA___usage_str___building_patch"
    fi
    if [[ ! -f "$l_PFA___patched_edit_filepath" ]] ; then
        local l_PFA___usage_str___building_patch
        __PFA___compose_usage_str___building_patch l_PFA___usage_str___building_patch
        user_errf "patched file\n%s\nis not a regular file\n\n%s" \
            "$l_PFA___patched_edit_filepath" \
            "$l_PFA___usage_str___building_patch"
    fi
    if [[ ! -r "$l_PFA___patched_edit_filepath" ]] ; then
        local l_PFA___usage_str___building_patch
        __PFA___compose_usage_str___building_patch l_PFA___usage_str___building_patch
        user_errf "patched file\n%s\nis not readable\n\n%s" \
            "$l_PFA___patched_edit_filepath" \
            "$l_PFA___usage_str___building_patch"
    fi
    
    # 3. create the patch file as the fallback
    temp_filepath l_PFA___temp_org_filepath_unix
    
    dos2unix -n "$l_PFA___org_filepath" "$l_PFA___temp_org_filepath_unix"
    
    __PFA___get_org_filename
    __PFA___get_patch_filepath
    
    # The -u options stand for "unifed context"
    # 3 lines above and 3 lines below a difference.
    # Thus patch utility has a greater chance to correcty apply a patch.
    diff --label "$l_PFA___org_filename" --label "${l_PFA___org_filename}.patched" \
        -u "$l_PFA___temp_org_filepath_unix" "$l_PFA___patched_edit_filepath" \
        > "$l_PFA___patch_filepath"
    
    log_file_contents "$l_PFA___patch_filepath" "$l_PFA___patch_filepath"
    
    # 1. copy the patched file from the current dir to the wrapper env dir
    #    with the previously saved MD5sum attached
    __PFA___get_patched_edit_md5sum_filepath
    if [[ ! -f "$l_PFA___patched_edit_md5sum_filepath" ]] ; then
        internal_err <<__end__
file with the MD5sum of the original file as of when building the patch was started
${l_PFA___patched_edit_md5sum_filepath}
does not exist
__end__
    fi
    
    read_file_to_str_var l_PFA___former_org_md5sum "$l_PFA___patched_edit_md5sum_filepath"
    l_PFA___former_org_md5sum="${l_PFA___former_org_md5sum%$'\n'}"
    if [[ ! "$l_PFA___former_org_md5sum" =~ ^[[:xdigit:]]+$ ]] ; then
        local l_PFA___md5sum_bash_word
        bash_word_from_str l_PFA___md5sum_bash_word "$l_PFA___former_org_md5sum"
        internal_err <<__end__
No MD5sum saved in
${l_PFA___patched_edit_md5sum_filepath}
only got ${l_PFA___md5sum_bash_word}
__end__
    fi
    # 2. delete the persistently saved MD5sum
    trap___install_cmd NORMAL_EXIT "rm -f '$l_PFA___patched_edit_md5sum_filepath'"
    
    __PFA___determinate_patched_filepath "$l_PFA___former_org_md5sum"
    
    unix2dos -n "$l_PFA___patched_edit_filepath" "$l_PFA___patched_filepath"
    # Lua (but maybe not cmd.exe) is able to read files in Windows- and Unix-Style
    # cp -Tf "$l_PFA___patched_edit_filepath" "$l_PFA___patched_filepath"
    # -f option to cp forces overwriting
    
    trap___install_cmd NORMAL_EXIT "rm -f '$l_PFA___patched_edit_filepath'"
}

# $1 - PFAn
function PFA___install() {
    local -n l_PFA___PFA="$1"
    
    # in order of first usage
    local l_PFA___org_filepath \
          l_PFA___last_resort_backup_filepath \
          l_PFA___backup_filepath \
          l_PFA___patched_filepath \
          l_PFA___used_filepath
    
    __PFA___get_org_filepath
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    # optionally: create last_resort backup
    __PFA___get_last_resort_backup_filepath
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
        
    if [[ ! -e  "$l_PFA___last_resort_backup_filepath" ]] ; then
        cp -Tn "$l_PFA___org_filepath" "$l_PFA___last_resort_backup_filepath"
        # -n option to cp does not overwrite
    fi
    
    # create normal backups
    trap___install_cmd EXIT "__PFA___uninstall $1"
    # installs the recovering of the backup as a trap handler 
    # for the bash-specific pseudo signal EXIT
    # Thus we can be sure, whenever the scripts exits
    # (with or without the exit statement)
    # that the backups are recovered.
    __PFA___get_backup_filepath
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
        
    cp -Tf "$l_PFA___org_filepath" "$l_PFA___backup_filepath"
    # -f option to cp forces overwriting
    
    local -i l_PFA___does_patched_file_exist
    
    __PFA___find_patched_file_for_md5sum
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    if (( l_PFA___does_patched_file_exist )) ; then
        __PFA___install_with_patched_file
    else
        __PFA___install_with_patch_file
    fi
    
    # 5. create the used file
    __PFA___get_used_filepath
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
        
    cp -Tf "$l_PFA___org_filepath" "$l_PFA___used_filepath"
    # -f option to cp forces overwriting
}

# uses the following vars from calling context
# l_PFA___PFA
# l_PFA___org_filepath
# l_PFA___patched_filepath
function __PFA___install_with_patched_file() {
    logf "patch\n%s\nby replacing with patched file\n%s" \
        "$l_PFA___org_filepath" "$l_PFA___patched_filepath"
    
    cp -Tf "$l_PFA___patched_filepath" "$l_PFA___org_filepath"
    # -f option to cp forces overwriting
}

# uses the following vars from calling context
# l_PFA___PFA
# l_PFA___org_filepath
function __PFA___install_with_patch_file() {
    local l_PFA___patch_filepath
    __PFA___get_patch_filepath
    
    logf "patch\n%s\nby patching with patch file\n%s" \
        "$l_PFA___org_filepath" "$l_PFA___patch_filepath"
    
    if [[ ! -e "$l_PFA___patch_filepath" ]] ; then
        local l_PFA___err_str
            __PFA___compose_err_str___neither_patched_nor_patch_file l_PFA___err_str
            user_err "$l_PFA___err_str"
    fi
    
    # The patch untility only works unannoying,
    # if the patch file and the file-to-path
    # have Unix-style endings
    # $l_PFA___patch_filepath is has UNIX-style line endings
    # $l_PFA___org_filepath is in DOS-style line-endings
    #                         and must get Unix-style line-endings
    dos2unix "$l_PFA___org_filepath"
    declare patch_cmd="patch -f '$l_PFA___org_filepath' '$l_PFA___patch_filepath'"
    # The -f option to patch is a force option (do not complain on suspicious cirumstances)
    eval "$patch_cmd"
    # TODO check possibilities of ext_cmd module to get rid of
    # TODO eval "$patch_cmd"
    declare -g -i patch_exit_status=$?
    if (( patch_exit_status )) ; then
        __PFA___uninstall "$1"
        internal_err <<__end__
The following command to patch $l_PFA___filename failed:
${patch_cmd}

Recovered original
${l_PFA___filename}

Maybe the patch utility created a reject file ${l_PFA___filename}.rej
and a further backup file ${l_PFA___filename}.orig
__end__
    fi
    unix2dos "$l_PFA___org_filepath"
}

# This function should be used in a trap handler
# Thus do not care, if a backup file really exists
#
# $1 - PFAn
function __PFA___uninstall() {
    local -n l_PFA___PFA="$1"
    
    # in order of first usage
    local l_PFA___org_filepath \
          l_PFA___backup_filepath
    
    __PFA___get_backup_filepath
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    __PFA___get_org_filepath___impl
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    # 1. replace the patched file by the normal backup
    if [[ -f "$l_PFA___backup_filepath" ]] ; then
        mv -Tf "$l_PFA___backup_filepath" "$l_PFA___org_filepath"
        # -f option to mv forces overwriting
    else
        exec_module ANSI
        
        local l_PFA___backup_filepath_win \
              l_PFA___last_resort_backup_filepath
        
        convert_path_to_win l_PFA___backup_filepath_win \
            "$l_PFA___backup_filepath"
        local l_PFA___warn_str
        printf -v l_PFA___warn_str "\
Warning:
backup file
%s
does not exist" \
            "$l_PFA___backup_filepath_win"
        user_msgf "${ANSI___seq___warning}%s${ANSI___seq___end}" \
            "$l_PFA___warn_str"
        
        __PFA___get_last_resort_backup_filepath
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
        
        if [[ -f "$l_PFA___last_resort_backup_filepath" ]] ; then
            mv -Tf "$l_PFA___last_resort_backup_filepath" "$l_PFA___org_filepath"
            # -f option to mv forces overwriting
            user_msg "\
Info:
But could restore from last resort backup file."
        else
            local l_PFA___last_resort_backup_filepath_win \
                  l_PFA___org_filepath_win \
                  l_PFA___help_str___install_luarocks
                  
            convert_path_to_win l_PFA___last_resort_backup_filepath \
                "$l_PFA___last_resort_backup_filepath"
            convert_path_to_win l_PFA___org_filepath_win \
                "$l_PFA___org_filepath"
            help_str___install_luarocks l_PFA___help_str___install_luarocks \
                --with-rm-luarocks-envdir
            
            printf -v l_PFA___warn_str "\
Error:
also last resort backup file
%s
does not exist

Now the file at the original filepath
%s
is not in its original version anymore." \
                "$l_PFA___last_resort_backup_filepath_win" \
                "$l_PFA___org_filepath_win"
            user_msgf "${ANSI___seq___warning}%s${ANSI___seq___end}" \
                "$l_PFA___warn_str"
            user_msgf "\
Help:
If further errors occur, LuaRocks should be reinstalled.
%s" \
                "$l_PFA___help_str___install_luarocks"
        fi
    fi
}

# tries to repair the original file, such that it can be used for further processing.
# 
# arguments:
# $1 - PFAn
# 
# exceptions:
#   PFA___exc___not_any_backup
function PFA___repair() {
    local -n l_PFA___PFA="$1"
    
    local l_PFA___org_filepath \
          l_PFA___backup_filepath \
          l_PFA___org_filename \
          l_PFA___used_filepath
    
    __PFA___get_org_filepath___impl
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    # ---------- restore from backups --------------------
    __PFA___get_backup_filepath
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    __PFA___get_org_filename
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    if [[ -f "$l_PFA___backup_filepath" ]] ; then
        mv -Tf "$l_PFA___backup_filepath" "$l_PFA___org_filepath"
        # -f option to mv forces overwriting
        user_msg "Restored original version of\n%s\nfrom the backup file" \
            "$l_PFA___org_filename"
    else
        user_msgf "Backup file of\n%s\ndoes not exist" \
            "$l_PFA___org_filename"
        
        local l_PFA___last_resort_backup_filepath
        
        __PFA___get_last_resort_backup_filepath
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
        
        if [[ -f "$l_PFA___last_resort_backup_filepath" ]] ; then
            mv -Tf "$l_PFA___last_resort_backup_filepath" "$l_PFA___org_filepath"
            # -f option to mv forces overwriting
            user_msgf "\
But could restore original version of\n%s\nfrom the last resort backup file." \
                "$l_PFA___org_filename"
        else
            local l_PFA___barrier_str
            printf -v l_PFA___barrier_str "\
Neither the backup file
%s
nor the last resort backup file
%s
exists." \
                "$l_PFA___backup_filepath" \
                "$l_PFA___last_resort_backup_filepath"
            exc___raise PFA___exc___not_any_backup "$l_PFA___barrier_str"
            return 0
        fi
    fi
    
    # ---------- remove extra files -------------------- 
    __PFA___get_used_filepath
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    local l_PFA___failed_patch_orig_filepath="${l_PFA___org_filepath}.orig" \
           l_PFA___failed_patch_rej_filepath="${l_PFA___org_filepath}.rej"
    
    rm -f "$l_PFA___backup_filepath" \
          "$l_PFA___used_filepath" \
          "$l_PFA___failed_patch_orig_filepath" \
          "$l_PFA___failed_patch_rej_filepath"
}

# places some infos inside the provided array
# ["org_filepath"]
#       real original filepath
#       only set if exists
# 
# ["org___is_busy"]
#       if org file is in use
#       "1" if busy
#       "0" if not busy
# 
# ["org___current_md5sum"]
#       current MD5sum
#       only set if org file exists, not busy and readable
# 
# ["patched_filepath"]
#       filepath of patched file to current MD5sum
#       only set if exists
#       Note:
#       This key is never set,
#       if also the key org___current_md5sum is not set
# 
# ["patch_filepath"]
#       filepath of the patch file
#       only set if exists
# 
# [*patched_edit_filepath"]
#       filepath of the patched version of the file to patch
#       only set if exists and readable
#       for editing by the user
# 
# ["last_resort_backup_filepath"]
#       filepath of the mast backup of the file to patch
#       only set if exists
# 
# arguments:
# $1 - ret assoc array name
#      only those keys are set, that are present in the query ($3)
# $2 - PFAn
# $3 - query
#      assoc array with keys as described above
function PFA___query() {
    local -n l_PFA___infos="$1" \
             l_PFA___PFA="$2" \
             l_PFA___query="$3"
    
    local -i l_PFA___does_org_file_exists \
             l_PFA___is_org_file_readable \
             l_PFA___is_org_file_busy
    __PFA___does_org_file_exist  l_PFA___does_org_file_exists
    __PFA___is_org_file_readable l_PFA___is_org_file_readable
    __PFA___is_org_file_busy     l_PFA___is_org_file_busy
    local -i l_PFA___is_org_file_normal="$(( l_PFA___does_org_file_exists \
                                          && l_PFA___is_org_file_readable \
                                          && ( ! l_PFA___is_org_file_busy ) ))"
    
    unset l_PFA___infos["org_filepath"]
    unset l_PFA___infos["org___is_busy"]
    unset l_PFA___infos["backup_filepath"]
    unset l_PFA___infos["org___current_md5sum"]
    unset l_PFA___infos["last_resort_backup_filepath"]
    unset l_PFA___infos["patch_filepath"]
    unset l_PFA___infos["patched_filepath"]
    unset l_PFA___infos["patched_edit_filepath"]
    
    local l_PFA___org_filepath
    
    __PFA___get_org_filepath___impl
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        PFA___exc___no_org)
            exc___ignore
            ;;
        *) exc___unhandled ;;
    esac
    
    # real original filepath
    if [[ -v l_PFA___query["org_filepath"] ]] \
    && (( l_PFA___does_org_file_exists ))
    then
        l_PFA___infos["org_filepath"]="$l_PFA___org_filepath"
    fi
    
    # is org file busy?
    if [[ -v l_PFA___query["org___is_busy"] ]] ; then
        l_PFA___infos["org___is_busy"]="$l_PFA___is_org_file_busy"
    fi
    
    # backup filepath
    if [[ -v l_PFA___query["backup_filepath"] ]] ; then
        local l_PFA___backup_filepath
        
        __PFA___get_backup_filepath
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
        
        if [[ -f "$l_PFA___backup_filepath" ]] ; then
            l_PFA___infos["backup_filepath"]="$l_PFA___backup_filepath"
        fi
    fi
    
    # current MD5sum
    if [[ -v l_PFA___query["org___current_md5sum"] ]] ; then
        local l_PFA___org_current_md5sum
        
        __PFA___get_org_current_md5sum
        case "$EXCEPTION_ID" in
            '') # no exception
                
                l_PFA___infos["org___current_md5sum"]="$l_PFA___org_current_md5sum"
                ;;
                
            PFA___exc___no_org)
                exc___ignore ;;
            PFA___exc___org_not_readable)
                exc___ignore ;;
            PFA___exc___busy)
                exc___ignore ;;
            *) exc___unhandled ;;
        esac
    fi
    
    # patched filepath for the current MD5sum
    if [[ -v l_PFA___query["patched_filepath"] ]] ; then
        local l_PFA___patched_filepath
        local -i l_PFA___does_patched_file_exist
        
        __PFA___find_patched_file_for_md5sum
        case "$EXCEPTION_ID" in
            '') # no exception
                
                if (( l_PFA___does_patched_file_exist )) ; then
                    l_PFA___infos["patched_filepath"]="$l_PFA___patched_filepath"
                fi
                ;;
            
            PFA___exc___no_org)
                exc___ignore ;;
            PFA___exc___org_not_readable)
                exc___ignore ;;
            PFA___exc___busy)
                exc___ignore ;;
            *) exc___unhandled ;; # not handle here
        esac
        
    fi
    
    # patch filepath
    if [[ -v l_PFA___query["patch_filepath"] ]] ; then
        local l_PFA___patch_filepath
        __PFA___get_patch_filepath
        if [[ -f "$l_PFA___patch_filepath" ]] ; then
            l_PFA___infos["patch_filepath"]="$l_PFA___patch_filepath"
        fi
    fi
    
    # patched_edit filepath
    if [[ -v l_PFA___query["patched_edit_filepath"] ]] ; then
        local l_PFA___patched_edit_filepath
        __PFA___get_patched_edit_filepath
        if [[ ( -f "$l_PFA___patched_edit_filepath" ) \
           && ( -r "$l_PFA___patched_edit_filepath" ) ]]
        then
            l_PFA___infos["patched_edit_filepath"]="$l_PFA___patched_edit_filepath"
        fi
    fi
    
    # master_backup filepath
    # TODO finsih renaming to last resort backup
    if [[ -v l_PFA___query["last_resort_backup_filepath"] ]] ; then
        local l_PFA___last_resort_backup_filepath
        
        __PFA___get_last_resort_backup_filepath
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
        
        if [[ -f "$l_PFA___last_resort_backup_filepath" ]] ; then
            l_PFA___infos["last_resort_backup_filepath"]="$l_PFA___last_resort_backup_filepath"
        fi
    fi
    
    # assert, that PFA___query does not raise any exceptions
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) exc___unhandled ;;
    esac
}

# $1 - ret str var name for dirpath
# $2 - ret str var name for filename
# $3 - PFAn
function PFA___get_org_filepath_components() {
    local -n l_PFA___PFA="$3"
    
    if [[ -v EXCEPTION_ID ]] ; then
        local EXCEPTION_ID_backup="$EXCEPTION_ID"
        unset EXCEPTION_ID
    fi
    
    local l_PFA___org_filepath
    
    __PFA___get_org_filepath___impl
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        PFA___exc___no_org)
            local -n  l_PFA___org_dirpath="$1" \
                     l_PFA___org_filename="$2"
            __PFA___get_org_filename
            return 0
            ;;
        *) exc___unhandled ;; # not handle here
    esac
    
    if [[ -v EXCEPTION_ID_backup ]] ; then
        declare -g EXCEPTION_ID="$EXCEPTION_ID_backup"
    fi
    
    log_str_var l_PFA___org_filepath
    split_filepath "$1" "$2" "$l_PFA___org_filepath"
}

# $1 - PFAn
function PFA___show_original() {
    exec_module ANSI
    
    local -n l_PFA___PFA="$1"
    local l_PFA___org_filepath
    
    __PFA___get_org_filepath
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    # 1. print the original file to terminal
    __PFA___print_file_contents "$l_PFA___org_filepath" \
        "original"
}

# $1 - PFAn
function PFA___show_diff() {
    exec_module ANSI
    
    local -n l_PFA___PFA="$1"
    
    # in order of first usage
    local l_PFA___temp_patched_filepath_unix \
          l_PFA___org_filepath
    
    __PFA___filepath_of_patched___unix_line_endings l_PFA___temp_patched_filepath_unix
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    local l_PFA___temp_org_filepath_unix \
          l_PFA___temp_diff_filepath \
          l_PFA___org_filename
    temp_filepath l_PFA___temp_org_filepath_unix
    temp_filepath l_PFA___temp_diff_filepath
    
    __PFA___get_org_filepath
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    dos2unix -n "$l_PFA___org_filepath" "$l_PFA___temp_org_filepath_unix"
    
    __PFA___get_org_filename
    
    diff --color=always \
        --label "$l_PFA___org_filename" --label "${l_PFA___org_filename}.patched" \
        -u "$l_PFA___temp_org_filepath_unix" "$l_PFA___temp_patched_filepath_unix" \
        > "$l_PFA___temp_diff_filepath"
    
    __PFA___print_file_contents "$l_PFA___temp_diff_filepath" \
        "$l_PFA___org_filename" \
        "diff"
}

# $1 - PFAn
function PFA___show_patched() {
    exec_module ANSI
    
    local -n l_PFA___PFA="$1"
    
    # in order of first usage
    local l_PFA___patched_filepath \
          l_PFA___org_filename
    
    # 2. if MD5sum is equal to a patched file in the wrapper env dir,
    # 2a. then
    #       2aa. specifed file := patched file in the wrapper env dir
    local -i l_PFA___does_patched_file_exist
    
    __PFA___find_patched_file_for_md5sum
    case "$EXCEPTION_ID" in
        '') ;; # no exception
        *) return 0 ;; # not handle here
    esac
    
    if (( l_PFA___does_patched_file_exist )) ; then # 2b. else
        
        # in order of first usage
        local l_PFA___patch_filepath \
              l_PFA___org_filepath
        
        __PFA___get_patch_filepath
        
        if [[ ! -f "$l_PFA___patch_filepath" ]] ; then
            local l_PFA___err_str
            __PFA___compose_err_str___neither_patched_nor_patch_file l_PFA___err_str
            user_msg "$l_PFA___err_str"
            return
        fi
        
        __PFA___get_org_filepath
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
        
        # 2bc. specifed file := temp file
        temp_filepath l_PFA___patched_filepath
        # 2ba. create a temp copy of the original patch
        dos2unix -n "$l_PFA___org_filepath" "$l_PFA___patched_filepath"
        # 2bb. patch the temp copy
        patch -f "$l_PFA___patched_filepath" "$l_PFA___patch_filepath"
         # The -f option to patch is a force option (do not complain on suspicious cirumstances)
    fi
    
    # 3. print the specifed file to the terminal
    __PFA___get_org_filename
    __PFA___print_file_contents "$l_PFA___patched_filepath" "$l_PFA___org_filename" \
        "patched"
}

#  $1  - filepath
# [$2] - forced filepath to show
#  $3  - short description
function __PFA___print_file_contents() {
    local l_PFA___filepath="$1"
    if (( "$#" > 2 )) ; then
        local l_PFA___filepath_to_show="$2"
        shift
    else
        local l_PFA___filepath_to_show
        abbr_path_from_long_path l_PFA___filepath_to_show "$l_PFA___filepath"
    fi
    local l_PFA___description="($2)"
    
    
    echo
    
    if (( "${#l_PFA___filepath_to_show}" > "${#l_PFA___description}" )) ; then
        local -i l_PFA___max_header_len="${#l_PFA___filepath_to_show}"
    else
        local -i l_PFA___max_header_len="${#l_PFA___description}"
    fi
    
    __PFA___print_file_contents___header_line "$l_PFA___filepath_to_show"
    __PFA___print_file_contents___header_line "$l_PFA___description"
    
    cat "$l_PFA___filepath"
    
    local -i l_PFA___i
    for (( l_PFA___i=0 ; \
           l_PFA___i < l_PFA___max_header_len ; \
           l_PFA___i++ ))
    do
        echo -n "="
    done
    echo '======================' # 22 equal signs
}

# $1 - string
# 
# uses from calling context:
# l_PFA___max_header_len
function __PFA___print_file_contents___header_line() {
    echo -n "========== $1 " # 10 equal signs
    local -i l_PFA___i \
             l_PFA___header_len="${#1}" 
    for (( l_PFA___i=l_PFA___header_len ; \
           l_PFA___i < l_PFA___max_header_len ; \
           l_PFA___i++ ))
    do
        echo -n '='
    done
    echo '==========' # # 10 equal signs
}
