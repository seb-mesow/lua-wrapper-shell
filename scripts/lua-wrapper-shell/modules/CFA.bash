# defines an associative array of some filepaths for a file to patch
# with the following keys/subscripts
#   org_filename       ... basename of the file to patch
#   org                ... filepath of the file to patch
#                          Is eval-ed before actual use, thus can contain parameter expansions
#   kept_files_dirpath ... directory to store files generated during starting and finishing build patch
#                          Is eval-ed before actual use, thus can contain parameter expansions

#  $1  - ret var name for CFAn
#  $2  - FK
function CFA___provide_CFAn_from_FK() {
    local -n l_CFA___CFAn__="$1"
    l_CFA___CFAn__="g_CFA___CFA___$2"
    if is_var_undefined "$l_CFA___CFAn__" ; then
        declare_config_assoc_array "$l_CFA___CFAn__"
    fi
    if [[ ! -v FK_to_CFAn_map["$2"] ]] ; then
        FK_to_CFAn_map["$2"]="$l_CFA___CFAn__"
    fi
}
#  $1  - ret var name for GKn
#  $2  - GK
function CFA___provide_CGAn_from_GK() {
    local -n l_CFA___CGAn_="$1"
    l_CFA___CGAn_="g_CFA___CGA___$2"
    if is_var_undefined "$l_CFA___CGAn_" ; then
        declare_config_assoc_array "$l_CFA___CGAn_"
    fi
    if [[ ! -v GK_to_CGAn_map["$2"] ]] ; then
        GK_to_CGAn_map["$2"]="$l_CFA___CGAn_"
    fi
}

# # $1 - ret var name for file to patch array name
# # $2 - user provided file to patch key
# function CFA___provide_CFAn_from_uFK() {
#     local l_CFA___FK
#     key_from_user_provided l_CFA___FK "$2"
#     CFA___provide_CFAn_from_FK "$1" "$l_CFA___FK"
# }
# $1 - ret var name for file to patch array name
# $2 - user provided file to patch key
function CFA___provide_CGAn_from_uGK() {
    local l_CFA___GK
    key_from_user_provided l_CFA___GK "$2"
    CFA___provide_CGAn_from_GK "$1" "$l_CFA___GK"
}

# compiles an indexed array of FKs from the provided uFKs and uGKs
# 
# arguments:
#  $1     - ret array var name
# [$2...] - uFKs or uGKs, default: show all
function CFA___FKs_from_uFKs_or_uGKs() {
    local -n l_CFA___FKs_="$1"
    
    shift
    
    if (( $# > 0 )) ; then
        l_CFA___FKs_=()
        local l_pf___u \
              l_pf___key \
              l_pf___FK
        for l_pf___u in "$@" ; do
            # this FK or GK
            key_from_user_provided l_pf___key "$l_pf___u"
            # search for equal FK
            if [[ -v FK_to_CFAn_map["$l_pf___key"] ]] ; then
                l_CFA___FKs_+=("$l_pf___key")
            # else search for equal GK
            elif [[ -v GK_to_CGAn_map["$l_pf___key"] ]] ; then
                local -n l_pf___CGA="${GK_to_CGAn_map["$l_pf___key"]}"
                for l_pf___FK in "${!l_pf___CGA[@]}" ; do
                    l_CFA___FKs_+=("$l_pf___FK")
                done
            else
                local l_pf___u_fmt l_pf___cmd_line
                bash_word_from_str l_pf___u_fmt "$l_pf___u"
                cmd_line_from_args l_pf___cmd_line \
                        "$0" "$lua_version" -l
                user_errf_stdin "$l_pf___u" <<__end__
unknown key for a file to patch resp.
unknown key for a group of files to patch:
${l_pf___u_fmt}

Execute the following to get a list of all files to patch
\$ ${l_pf___cmd_line}
__end__
            fi
        done
    else
        # all FKs  
        l_CFA___FKs_=("${!FK_to_CFAn_map[@]}")
    fi
}


# The 2nd argument for the org filepath can also be a function call.
# This argument is considered a function call,
# if the first word is a declared function.
# This function is then called with a ret str var name 
# to store the original filepath in and all remaining words as further arguments
# 
# (first word == the substring before the first blank char,
# while ignoring leading blank chars)
# 
# arguments:
#  $1     - ret str var name for CFAn
#  $2     - uFK
# [$3...] - uGKs
function __CFA___new() {
    local l_CFA___FK \
          l_CFA___uGK \
          l_CFA___CGAn
    
    key_from_user_provided l_CFA___FK "$2"
    local -n l_CFA___CFAn_="$1"
    CFA___provide_CFAn_from_FK l_CFA___CFAn_ "$l_CFA___FK"
    local -n l_CFA___CFA="$l_CFA___CFAn_"
    
    l_CFA___CFA["uFK"]="$2"
    
    shift 2
    
    for l_CFA___uGK in "$@" ; do
        CFA___provide_CGAn_from_uGK l_CFA___CGAn "$l_CFA___uGK"
        local -n l_CFA___CGA="$l_CFA___CGAn"
        # CGA store the FK and CFAn of each file in that group
        l_CFA___CGA["$l_CFA___FK"]="$l_CFA___CFAn_" # may overwrites with same value
    done
}

function __CFA___define_config___init() {
    # This function can indirectly be called multiple times
    # from the multiple register_*_file_to_show() functions.
    if [[ -v FK_to_CFAn_map ]] ; then
        return
    fi
    
    exec_module config
    
    # maps FK to CFAn
    declare_config_assoc_array FK_to_CFAn_map
    # maps GK to CGAn
    declare_config_assoc_array GK_to_CGAn_map
    
    local l_CFA___CFAn \
          l_CFA___CGAn
    
    # no CFA for the Makefile of the Lua Source, because we do not need to patch it
    
    #                        uFK                groups
    __CFA___new l_CFA___CFAn "install.bat"      "luarocks_install"
    __CFA___new l_CFA___CFAn "hardcoded.lua"    "sub_shell"
    __CFA___new l_CFA___CFAn "config.lua"       "sub_shell"
    
    cfg___close_var FK_to_CFAn_map
    cfg___close_var GK_to_CGAn_map
    for l_CFA___CGAn in "${GK_to_CGAn_map[@]}" ; do
        cfg___close_var "$l_CFA___CGAn"
    done
}

# uses l_CFA___CFA from calling context
# [$1] - LuaRocks install sources dir
#        default: $luarocks_install_sources_dir
function __CFA___augment___install_bat() {
    exec_module config
    cfg___define_general_config
    
    trace "__CFA___augment___install_bat() \$1 == $1"
    
          l_CFA___CFA["org_filename"]="install.bat"
    # l_CFA___CFA["kept_files_dirpath"]="$wrapper_envdir"
    # l_CFA___CFA["not_found_err_str_func_name"]="__CFA___org_file_not_found_err___obtain_luarocks_win_install_src"
    
    local l_CFA___cmd_line
    cmd_line_from_args l_CFA___cmd_line \
            __CFA___find___install_bat "${1:-$luarocks_install_sources_dir}"
    l_CFA___CFA["org"]="$l_CFA___cmd_line"
}

# $1 - ret str var name for filepath
# $2 - actual LuaRocks install sources dir to search in
function __CFA___find___install_bat() {
    exec_module find_file
    
    local l_CFA___install_src_subdir_regex=\
"luarocks-([[:digit:]]+\.[[:digit:]]+(\.[[:digit:]]+)?)-win32[^/]*"
    
    find_file "$1" \
            "$2" \
            "${l_CFA___install_src_subdir_regex}/install.bat" \
            "${l_CFA___install_src_subdir_regex}"
}

# uses l_CFA___CFA from calling context
function __CFA___augment___hardcoded_lua() {
    exec_module config
    cfg___define_general_config
    
    trace "__CFA___augment___hardcoded_lua()"
    
      l_CFA___CFA["org_filename"]="hardcoded.lua"
               l_CFA___CFA["org"]="${luarocks_envdir}/lua/luarocks/core/${l_CFA___CFA["org_filename"]}"
    # l_CFA___CFA["kept_files_dirpath"]="$wrapper_envdir"
    # l_CFA___CFA["not_found_err_str_func_name"]="__CFA___org_file_not_found_err___install_luarocks"
}

# uses l_CFA___CFA from calling context
function __CFA___augment___config_lua() {
    exec_module config
    cfg___define_general_config
    
    trace "__CFA___augment___config_lua()"
    
      l_CFA___CFA["org_filename"]="config-${lua_version}.lua"
               l_CFA___CFA["org"]="${luarocks_envdir}/${l_CFA___CFA["org_filename"]}"
    # l_CFA___CFA["kept_files_dirpath"]="$wrapper_envdir"
    # l_CFA___CFA["not_found_err_str_func_name"]="__CFA___org_file_not_found_err___install_luarocks"
}

# Does not allow to pass arguments to the __CFA___augment___* functions
# [$@...] - uFKs or uGKs, default: all
function CFA___define_config() {
    # This function can indirectly be called multiple times
    # from the multiple register_*_file_to_show() functions.
    __CFA___define_config___init
    
    local -a l_CFA___FKs
    CFA___FKs_from_uFKs_or_uGKs l_CFA___FKs "$@"
    
    local l_CFA___FK \
          l_CFA___CFAn
    for l_CFA___FK in "${l_CFA___FKs[@]}" ; do
        
        CFA___provide_CFAn_from_FK l_CFA___CFAn "$l_CFA___FK"
        
        local -n l_CFA___CFA="$l_CFA___CFAn"
        if [[ ! -v l_CFA___CFA["org_filename"] ]] ; then
            "__CFA___augment___${l_CFA___FK}"
        fi
        
        cfg___close_var "$l_CFA___CFAn"
    done
    
}

# Does allow to pass arguments to the __CFA___augment___* functions
#  $1     - uFK
# [$2...] - args to __CFA___augment___${FK}
function CFA___define_config_of_single_with_args_to_augment_func() {
    # This function can indirectly be called multiple times
    # from the multiple register_*_file_to_show() functions.
    __CFA___define_config___init
    
    local l_CFA___FK l_CFA___CFAn
    key_from_user_provided l_CFA___FK "$1"
    CFA___provide_CFAn_from_FK l_CFA___CFAn "$l_CFA___FK"
    local -n l_CFA___CFA="$l_CFA___CFAn"
    
    if [[ ! -v l_CFA___CFA["org_filename"] ]] ; then
        shift
        "__CFA___augment___${l_CFA___FK}" "$@"
    fi
    
    cfg___close_var "$l_CFA___CFAn"
}

# TODO obsolete
# $1 - ret str var name
function __CFA___org_file_not_found_err___obtain_lua_src() {
    local l_CFA___lua_sources_dir_win
    convert_path_to_win l_CFA___lua_sources_dir_win "$lua_sources_dir"
    assign_long_str_no_trailing_linefeed "$1" <<__end__
Please ensure, that you have downloaded a Lua sources .tar.gz archive.
It is the easiest to store this .tar.gz archive in
${l_CFA___lua_sources_dir_win}
The Lua Wrapper Shell will find it there.

Or you can provide it as an argument to the -il option.
__end__
}

# TODO obsolete
# $1 - ret str var name
function __CFA___org_file_not_found_err___obtain_luarocks_win_install_src() {
    local l_CFA___luarocks_install_sources_dir_win
    convert_path_to_win l_CFA___luarocks_install_sources_dir_win "$luarocks_install_sources_dir"
    assign_long_str_no_trailing_linefeed "$1" <<__end__
Please ensure, that you have downloaded a LuaRocks Windows install sources zip archive.
It is the easiest to store this zip archive in
${l_CFA___luarocks_install_sources_dir_win}
The Lua Wrapper Shell will find it there.

Or you can provide it as an argument to the -ilr option.
__end__
}

# TODO obsolete
# $1 - ret str var name
function __CFA___org_file_not_found_err___install_luarocks() {
    local l_CFA___cmd_line
    cmd_line_from_args l_CFA___cmd_line "$0" "$lua_version" -ilr
    assign_long_str_no_trailing_linefeed "$1" <<__end__
Maybe you have not yet installed LuaRocks.
To do that execute the following with root privileges (#):
# ${l_CFA___cmd_line}
__end__
}

# compiles a subset of the GK_to_CGAn_map
# with the groups an FK belongs to
# 
# arguments:
# #1 - ret assoc array var name
# #2 - FK
function CFA___sub_GK_to_CGAn_map_from_FK() {
    local -n l_CFA___sub_GK_to_CGAn_map_="$1"
    l_CFA___sub_GK_to_CGAn_map_=()
    local l_CFA___GK \
          l_CFA___CGAn \
          l_CFA___FK
    for l_CFA___GK in "${!GK_to_CGAn_map[@]}" ; do
        l_CFA___CGAn="${GK_to_CGAn_map["$l_CFA___GK"]}"
        local -n l_CFA___CGA="$l_CFA___CGAn"
        for l_CFA___FK in "${!l_CFA___CGA[@]}" ; do
            if [[ "$l_CFA___FK" == "$2" ]] ; then
                l_CFA___sub_GK_to_CGAn_map_["$l_CFA___GK"]="$l_CFA___CGAn"
                break
            fi
        done
    done
}
