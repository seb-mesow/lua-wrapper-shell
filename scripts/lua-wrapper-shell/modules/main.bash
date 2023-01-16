# TODO harmonize exit codes

# ========== Version Information ====================

function __main___version() {
    exec_module config
    
    cfg___define_msystem
    
    log_config_vars
    
    if [[ -v lua_version ]] ; then
        local l_main___lua_vers=" $lua_version" # Note the leading space
    else
        local l_main___lua_vers= # set to null resp. the empty string
    fi
    user_msg << __end__
This script setups a shell environment, \
with the provided Lua version${l_main___lua_vers} as the default.
This script also tries to setup things such, that Lua and LuaRocks is executed \
in a way expected in the (current) ${msys2_shell} shell \
and for the provided Lua version${l_main___lua_vers}${l_main___lua_vers:+ }.

This script also helps to build and install Lua${l_main___lua_vers} \
and to install LuaRocks for that environment.

Version: 1.0
Author: Sebastian Mesow

License: Public Domain
__end__
    exit 0
}

# ========== Initalization and Load Modules ====================

# declare -g wrapper_name="lua-wrapper-shell"

source "${wrapper_modules_dir}/main_init.bash"

# Not executed, when only usage to show
# But executed, when version information is shown
function __main___init() {
    exec_module config
    
    declare_config_str_var           wrapper_name        "$wrapper_name"
    declare_config_str_var_important wrapper_dir         "$wrapper_dir"
    declare_config_str_var           wrapper_modules_dir "$wrapper_modules_dir"
    
    # main___assert_environment_defined
    declare_config_str_var lua_version "$lua_version"
}

# function to execute, if one -d resp. --debug option is given
function __main___debug() {
    debug_level+=1
    
    # unset dos2unix_opts[quiet]
    # unset unix2dos_opts[quiet]
    # unset patch_opts[quiet]
    # unset unzip_opts[quiet]
}

# ========== Usage Information ====================

function __main___usage() {
    __main___usage_CLI
    __main___usage_options_user
    if (( m_main___usage_level > 1 )) ; then
        __main___usage_options_advanced
    fi
    
    exit 0
}

function __main___usage_CLI() {
    if (( m_main___usage_level < 2 )) ; then
        user_msg <<__end__
Usage:
wrapper shell:
    $0 <lua_version> [<bash_arg>...] [--] [<bash_arg>...]
build and install Lua:
    $0 <lua_version> -il  [<lua_sources_dir>]
install LuaRocks:
    $0 <lua_version> -ilr [<luarocks_sources_dir>]
miscellaneous:
    $0 -h [-h]
    $0 [<lua_version>] -v
__end__
    else
        user_msg <<__end__
Usage:
wrapper shell:
    $0 [debug_options] <lua_version> [<bash_arg>...] [--] [<bash_arg>...]
installation:
    $0 [debug_options] <lua_version> [-f] (-il  [<lua_sources_dir>] | -ilr [<luarocks_sources_dir>] )
    $0 [debug_options] <lua_version> [-f] (-il  <lua_sources_dir> | -ilr <luarocks_sources_dir> )...
list files:
    $0 [debug_options] <lua_version> -l [<FK/GK>...]
begin building patches:
    $0 [debug_options] <lua_version> (-ebp|-sbp) [<FK/GK>...]
end building patches:
    $0 [debug_options] <lua_version> (-fbp|-abp) [<FK/GK>...]
show files:
    $0 [debug_options] <lua_version> (-so|-sd|-sp) [<FK/GK>...]
show configuration:
    $0 [debug_options] <lua_version> -c
show configuration filepaths:
    $0 [debug_options] <lua_version> -cfp
show instructions to set as default environment
    $0 [debug_options] <lua_version> -ide
repair files:
    $0 [debug_options] <lua_version> -r [<FK/GK>...]
miscellaneous:
    $0 [debug_options] -h [-h]
    $0 [debug_options] [<lua_version>] -v
__end__
    fi
    user_msg <<__end__
examples for mandatory <lua_version>: 5.4 , 5.4.4
__end__
}

function __main___usage_options_user() {
    if (( m_main___usage_level > 1 )) ; then
        assign_long_str l_main___force_option_usage <<__end__

  -f,  --force
        do not complain about existing installation directories,
        just remove them entirely in before,
        do not pause, do not give explanations
        Use with care!
__end__
    fi
    user_msg <<__end__
Options:
  -il, --install-lua [<lua_sources_dir>]
        installs Lua with the Makefiles in the <lua_sources_dir>
        If the <lua_sources_dir> is not provided or the empty string,
        then the path lua_sources_dir from the config file is taken.
  
  -ilr, --install-luarocks [<luarocks_sources_dir>]
        installs LuaRocks with the install.bat in the <luarocks_sources_dir>
        If the <luarocks_sources_dir> is not provided or the empty string,
        then the path luarocks_install_sources_dir from the config file is taken.
${l_main___force_option_usage}
Miscellaneous Options:
  -h, --help, /? ...
        display this help
        provide multiple times for advanced and developing options
  
  -v, --version
        display general information about this script
        If also a Lua Version is provided, it also shows the location \
of the config file.

All these options must be given as seperate arguments.
(counter example: -hv is invalid and does not substitute -h -v)

All arguments not interpreted by the Lua Wrapper Shell
and all arguments after -- are passed to bash.
Example:
The following command line only executes
luarocks config
in the wrapper shell and then immediately exits with its exit status:
\$ $0 <lua_version> -- -c 'luarocks config'
__end__
}

function __main___usage_options_advanced() {
    user_msg <<__end__
Advanced and Developing Options:
  
  An FK is a key, which stands for a file to patch and its related stuff.
  An GK is a key for a group of files.
  If no FK or GK is provided, then all available files to patch are meant.
  
  -c, --show-config
        display current variables used for actions
  
  -cfp, --show-config-filepaths
        display the filepaths of configuration files for this environment.
  
  -ide, --instructions-default-env
        display instructions to set this environment as the default Lua environment
        This includes new values for PATH-like environment variables.
        Recommended usage:
        $0 <lua_version> -ide > temp_instructions_set_Lua_<lua_version>_as_default.txt
        
  -l, --list-files [<FK/GK>...]
        show some information and related filepaths
        Provide this option with no argument to obtain all available FKs and GKs.
  
  -ebp, --edit-build-patches [<FK/GK>...]
        copies the patched version of the file to patch to the current directory \
for further editing the patch

  -sbp, --start-building-patches [<FK/GK>...]
        copies the original version of the file to patch to the current directory \
for rewriting the patch from scratch
  
  -fbp, --finish-building-patches [<FK/GK>...]
        creates everything needed for a patch
        removes the rewritten/edited version of the file to patch from the current directory
  
  -abp, --abort-building-patches [<FK/GK>...]
        removes the rewritten/edited version of the file to patch from the current directory
        without creating or overwriting a new patch,
        clears internal stuff
   
  -so, --show-original [<FK/GK>...]
        show the file to patch as currently saved and not used as
  
  -sd, --show-diff [<FK/GK>...]
        show the difference between the original file to patch \
and its patched version, which will be used
  
  -sp, --show-patched [<FK/GK>...]
        show the patched version of the file to patch, which will be used
  
  -r, --repair [<FK/GK>...]
        try to repair the original file

Debug Options:
  -d, --debug
        show debug information
        provide multiple times to increase debug level
        (thus more messages)

  -n, --dry-run
        do not write any files or open the shell,
        but do all "around" this
__end__
}

declare -g m_main___please_consider_usage
assign_long_str_no_trailing_linefeed m_main___please_consider_usage <<__end__
please consider the usage information:
$ $0 -h
__end__
# m_main___please_consider_usage=$'\n'"${m_main___please_consider_usage%$'\n'}"

# ========== Actions ====================

# AA   ... action array
# AAn  ... action array name
# AaA  ... action arguments array
# AaAn ... action arguments array name

# Similar kinds of actions are grouped by an action mode.
# Once an action mode is established, it can never change again.

declare -g -a m_main___AAns
declare -g m_main___action_mode

#  $1     - ret str var for AAn
#  $2     - action mode ID
#  $3     - action kind ID
#           should be the short option
#  $4     - option that causes this action
#           also acts as an ID for this kind of action
# [$5...] - args to module or func
function __main___actions___new_AA() {
    local -n l_main___AAn_="$1"
    local l_main___action_mode="$2" \
          l_main___action_kind="$3"
          l_main___opt="$4"
    shift 4
    
    if [[ -v m_main___action_mode ]] ; then
        if [[ "$m_main___action_mode" != "$l_main___action_mode" ]] ; then
            local l_main___opt_with_args
            cmd_line_from_args l_main___opt_with_args "$l_main___opt" "$@"
            user_err <<__end__
You cannot provide the option
${l_main___opt_with_args}
in the mode
${m_main___action_mode}

Instead this option can only be provided in the mode
${l_main___action_mode}
__end__
        fi
    else
        m_main___action_mode="$l_main___action_mode"
    fi
    
    l_main___AAn_="l_main___AA_${#m_main___AAns[@]}"
    declare -g -A "$l_main___AAn_"
    local -n l_main___AA="$l_main___AAn_"
    l_main___AA["kind"]="$l_main___action_kind"
    l_main___AA["opt"]="$l_main___opt"
    if (( "$#" > 0 )) ; then
        local l_main___AaAn="l_main___AaA_${#m_main___AAns[@]}"
        declare -g -a "$l_main___AaAn"
        local -n l_main___AaA="$l_main___AaAn"
        l_main___AaA=("$@")
        l_main___AA["AaAn"]="$l_main___AaAn"
    fi
    m_main___AAns+=("$l_main___AAn_")
}

#  $1     - action mode ID
#  $2     - action kind ID
#           should be the short option
#  $3     - module to load
#  $4     - option that caused this action
#           also acts as an ID for this kind of action
# [$5...] - arguments to the module
function __main___actions___register_module() {
    local l_main___action_mode="$1" \
          l_main___action_kind="$2" \
          l_main___module="$3" \
          l_main___AAn
    shift 3
    __main___actions___new_AA l_main___AAn \
            "$l_main___action_mode" "$l_main___action_kind" \
            "$@"
    local -n l_main___AA="$l_main___AAn"
    l_main___AA["module"]="$l_main___module"
}

#  $1     - action mode ID
#  $2     - action kind ID
#           should be the short option
#  $3     - a module to execute in before
#           can be empty to not load a module
#           always loaded without arguments
#  $4     - funcname name
#  $5     - actual option that caused this action
#           also acts as an ID for this kind of action
# [$6...] - arguments to the func
function __main___actions___register_func() {
    local l_main___action_mode="$1" \
          l_main___action_kind="$2" \
          l_main___exec_module="$3" \
          l_main___func="$4" \
          l_main___AAn
    shift 4
    __main___actions___new_AA l_main___AAn \
            "$l_main___action_mode" "$l_main___action_kind" \
            "$@"
    local -n l_main___AA="$l_main___AAn"
    if [[ "$l_main___exec_module" ]] ; then
        l_main___AA["exec_module"]="$l_main___exec_module"
    fi
    l_main___AA["func"]="$l_main___func"
}

#  $1  - action mode ID
# [$2] - action kind ID
#        should be the short option
function main___actions___is_registered() {
    trace "start main___actions___is_registered() $1 $2"
    trace_str_var m_main___action_mode
    if [[ "$1" == "$m_main___action_mode" ]] ; then
        if [[ -v 2 ]] ; then
            for l_main___AAn in "${m_main___AAns[@]}" ; do
                trace_assoc_array "$l_main___AAn"
                local -n l_main___AA="$l_main___AAn"
                if [[ "${l_main___AA["kind"]}" == "$2" ]] ; then
                    trace "end successfully main___actions___is_registered() 1"
                    return 0
                fi
            done
        else
            trace "end successfully main___actions___is_registered() 2"
            return 0
        fi
    fi
    trace "end failing main___actions___is_registered()"
    return 1
}

function __main___actions___execute_all() {
    for l_main___AAn in "${m_main___AAns[@]}" ; do
        local -n l_main___AA="$l_main___AAn"
        trace_assoc_array "$l_main___AAn"
        if [[ -v l_main___AA["func"] ]] ; then
            if [[ -v l_main___AA["exec_module"] ]] ; then
                exec_module "${l_main___AA["exec_module"]}"
            fi
            local l_main___AaAn="${l_main___AA["AaAn"]}"
            if [[ -v "$l_main___AaAn" ]] ; then
                local -n l_main___AaA="$l_main___AaAn"
                "${l_main___AA["func"]}" "${l_main___AaA[@]}"
            else
                "${l_main___AA["func"]}"
            fi
        else
            local l_main___AaAn="${l_main___AA["AaAn"]}"
            if [[ -v "$l_main___AaAn" ]] ; then
                local -n l_main___AaA="$l_main___AaAn"
                exec_module "${l_main___AA["module"]}" "${l_main___AaA[@]}"
            else
                exec_module "${l_main___AA["module"]}"
            fi
        fi
        exc___assert_no_unhandled
    done
}

# $1 - string
function main___actions___user_msg___header() {
    local -i l_main___avail_columns="$(( "$COLUMNS" - "${#1}" - 2 ))"
    local l_main___msg_str
    if (( l_main___avail_columns > 0 )) ; then
        local -i l_main___columns="$(( l_main___avail_columns / 4 ))" \
                 l_main___i
        for (( l_main___i = 0 ; l_main___i < l_main___columns ; l_main___i++ )) ; do
            l_main___msg_str="${l_main___msg_str}="
        done
        l_main___msg_str="${l_main___msg_str} ${1} "
        l_main___columns="$(( l_main___avail_columns - l_main___columns ))"
        for (( l_main___i = 0 ; l_main___i < l_main___columns ; l_main___i++ )) ; do
            l_main___msg_str="${l_main___msg_str}="
        done
    else
        l_main___msg_str="$1"
    fi
    user_msg "$l_main___msg_str"
}

# ========== Argument Evaluation ====================

declare -g -a m_main___non_arg_opts m_main___bash_args

declare -g m_main___lua_version_regex="^[[:blank:]]*[[:digit:]]+\.[[:digit:]]+"

function __main___parse_args() {
    while (( $# > 0 )) ; do
        if [[ "$1" =~ $m_main___lua_version_regex ]] ; then
            __main___parse_args___lua_version "$1"
        else
            m_main___non_arg_opts+=("$1")
            case "$1" in
                # normal options
                -il|--build-install-lua)
                    __main___actions___register_module "installation" -il \
                            build_install_lua "$1" ${2:+"$2"}
                    shift 1
                    ;;
                -ilr|--install-luarocks)
                    __main___actions___register_module "installation" -ilr \
                            install_luarocks "$1" ${2:+"$2"}
                    shift 1
                    ;;
                -sbp|--start-building-patches)
                    __main___actions___register_func "begin building patches" -sbp \
                            patch_files pf___start_building_patches "$@"
                    shift "$#"
                    ;;
                -ebp|--edit-build-patches)
                    __main___actions___register_func "begin building patches" -ebp \
                            patch_files pf___edit_builded_patches "$@"
                    shift "$#"
                    ;;
                -fbp|--finish-building-patches)
                    __main___actions___register_func "end building patches" -fbp \
                            patch_files pf___finish_building_patches "$@"
                    shift "$#"
                    ;;
                -abp|--abort-building-patches)
                    __main___actions___register_func "end building patches" -abp \
                            patch_files pf___abort_building_patches "$@"
                    shift "$#"
                    ;;
                -l|--list-files)
                    # __main___actions___register_func "list files" -l \
                    #         patch_files pf___list_files_to_patch "$@"
                    # TODO only temporary
                    __main___actions___register_func "list files" -l \
                            list_files lf___list_files "$@"
                    shift "$#"
                    ;;
                -so|--show-original)
                    __main___actions___register_func "show files" -so \
                            patch_files pf___register_original_file_to_show "$@"
                    shift "$#"
                    ;;
                -sd|--show-diff)
                    __main___actions___register_func "show files" -sd \
                            patch_files pf___register_diff_to_show "$@"
                    shift "$#"
                    ;;
                -sp|--show-patched)
                    __main___actions___register_func "show files" -sp \
                            patch_files pf___register_patched_file_to_show "$@"
                    shift "$#"
                    ;;
                -r|--repair)
                    __main___actions___register_func "repair files" -r \
                            patch_files pf___repair "$@"
                    shift "$#"
                    ;;
                -c|--show-config)
                    __main___actions___register_func "show configuration" -c \
                            config cfg___print_config "$1"
                    ;;
                -cfp|--show-config-filepaths)
                    __main___actions___register_func "show configuration files" -cf \
                            config cfg___print_config_filepaths "$1"
                    ;;
                -ide|--instructions-default-env)
                    __main___actions___register_func "instructions default env" -ide \
                            print_instructions pi___print_instructions_to_set_this_env_as_default_env "$1"
                    ;;
                -f|--force)
                    do_force+=1
                    ;;
                # debug options
                -d|--debug)
                    __main___debug
                    ;;
                -n|--dry-run)
                    do_run=0
                    ;;
                -h|--help|/\?)
                    m_main___usage_level+=1
                    ;;
                -v|--version)
                    __main___version
                    ;;
                --)
                    shift
                    m_main___bash_args+=("$@")
                    return
                    ;;
                # all other options
                *)
                    # if [[ ( -z "$1" ) || ( "$1" =~ [[:blank:]]+ ) ]] ; then
                    #     local l_main___unknown_opt="'$1'"
                    # else
                    #     local l_main___unknown_opt="$1"
                    # fi
                    # user_errf "unknown option %s\n%s" "$l_main___unknown_opt" "$m_main___please_consider_usage"
                    m_main___bash_args+=("$1")
                    ;;
            esac
        fi
        if ! shift ; then
            return
        fi
    done
}

# $1 - user provided Lua version
function __main___parse_args___lua_version() {
    if [[ -v lua_version ]] ; then
        user_err "You must not provide two arguments for the Lua version."
    fi
    declare -g lua_version
    strip_surrounding_whitespace lua_version "$1"
}

# required only by config module
function main___assert_environment_defined() {
    trace_str_var_quoted lua_version
    if [[ ! -v lua_version ]] ; then
        user_err_no_abort "Missing argument for Lua version"
        if (( "${#m_main___non_arg_opts[@]}" > 0 )) ; then
            local l_main___non_arg_opts_concated
            for l_main___non_arg_opt in "${m_main___non_arg_opts[@]}" ; do
                if [[ ! "$l_main___non_arg_opt" =~ ^[-[:alnum:]_./+]+$ ]] ; then
                    bash_word_from_str l_main___non_arg_opt "$l_main___non_arg_opt"
                fi
                l_main___non_arg_opts_concated="\
${l_main___non_arg_opts_concated}\
${l_main___non_arg_opts_concated:+, }\
${l_main___non_arg_opt}"
            done
            user_err_no_abort <<__end__
You must provide a Lua version (e.g. 5.4) \
BEFORE providing a normal option like ${l_main___non_arg_opts_concated} .
__end__
        else
            user_err_no_abort <<__end__
You must provide a Lua version (e.g. 5.4) \
if you want to start the wrapper shell.
__end__
        fi
        user_err "$m_main___please_consider_usage"
    fi
}

function __main___main() {
    __main___parse_args "$@"
    
    if (( m_main___usage_level > 0 )) ; then
        __main___usage
    fi
    
    # __main___init
    __main___actions___execute_all
    
    if [[ ( "$m_main___action_mode" ) \
       && ( "$m_main___action_mode" != "show files" ) ]]
    then
        exit
    fi
    
    if main___actions___is_registered "show files" ; then
        pf___show_registered_files_to_show
        exc___assert_no_unhandled
    fi
    
    exec_module sub_shell "${m_main___bash_args[@]}"
    exc___assert_no_unhandled
}

__main___main "$@"
