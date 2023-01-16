#!/usr/bin/env bash

debug_level=2

source "../modules/auxillary.bash"
source "../modules/print.bash"
source "../modules/log.bash"
source "../modules/config_read.bash"
source "../modules/config_write.bash"
source "../modules/install_luarocks.bash"

mapfile g_cmd_out <<'__end__'
Other output
Other output
Other output

You may want to add the following elements to your paths
Lua interpreter;
  PATH     :   C:\Program Files\Lua\5.3-ucrt64\bin
  PATHEXT  :   .LUA
LuaRocks;
  PATH     :   C:\Program Files\LuaRocks\Lua 5.3-ucrt64
  LUA_PATH :   C:\Program Files\LuaRocks\Lua 5.3-ucrt64\lua\?.lua;C:\Program Files\LuaRocks\Lua 5.3-ucrt64\lua\?\init.lua
Local user rocktree (Note: %APPDATA% is user dependent);
  PATH     :   %APPDATA%\LuaRocks\bin
  LUA_PATH :   %APPDATA%\LuaRocks\share\lua\5.3\?.lua;%APPDATA%\LuaRocks\share\lua\5.3\?\init.lua
  LUA_CPATH:   %APPDATA%\LuaRocks\lib\lua\5.3\?.dll
System rocktree
  PATH     :   C:\Program Files\LuaRocks\Lua 5.3-ucrt64\bin
  LUA_PATH :   C:\Program Files\LuaRocks\Lua 5.3-ucrt64\share\lua\5.3\?.lua;C:\Program Files\LuaRocks\Lua 5.3-ucrt64\share\lua\5.3\?\init.lua
  LUA_CPATH:   C:\Program Files\LuaRocks\Lua 5.3-ucrt64\lib\lua\5.3\?.dll

Note that the %APPDATA% element in the paths above is user specific and it MUST be replaced by its actual value.
For the current user that value is: C:\Users\Administrator\AppData\Roaming.


__end__

# parses the suggested paths from LuaRocks install.bat
# into an associative array.
# The keys will be of the form "<section>.<env varname>"
# 
# arguments:
# $1 - varname of an associative array to store the config in
# $2 - varname of an indexed array to read the lines from
function __parse_suggested_paths() {
    local -n l_parse___config="$1" l_parse___lines="$2"
    
    local -i l_i=0
    local -i l_n=${#l_parse___lines[@]}
    local l_line
    while (( l_i < l_n )) ; do
        if [[ "${l_parse___lines[l_i++]}" =~ "You may want to add the following elements to your paths" ]] ; then
            break
        fi
    done
    if (( l_i >= l_n )) ; then
        internal_err "Could not parse suggested paths from install.bat"
    fi
    
    if (( debug_level > 0 )) ; then
        local -i l_ii=l_i
        echo
        echo "===== output with relevance for suggested paths ===================="
        local l_line
        while (( l_ii < l_n  )) ; do
            l_line="${l_parse___lines[l_ii++]%$'\r'}"
            printf "%s\n" "${l_line%$'\n'}"
        done
        echo "=============================="
    fi
    
    local l_line l_env_var l_val l_sec l_BASH_REMATCH_1
    while (( l_i < l_n )) ; do
        l_line="${l_parse___lines[l_i]%$'\r'}"
        l_line="${l_parse___lines[l_i++]%$'\n'}"
        # printf "l_line = \"%q\"\n" "$l_line"
        if [[ (   "$l_line" =~ [[:graph:]]    )\
           && ( ! "$l_line" =~ "be replaced"  ) \
           && ( ! "$l_line" =~ "current user" ) ]] ; then
        log_str_var_quoted l_line
            if [[ "$l_line" =~ ^[[:blank:]]*([[:upper:][:digit:]_]+)[[:blank:]]*: ]] ; then
                # env var with suggested path
                log_plain "--- parse ENV VAR"$'\n'
                l_env_var="${BASH_REMATCH[1]}"
                strip_surrounding_whitespace l_val "${l_line#${BASH_REMATCH[0]}}"
                log_str_var_quoted l_env_var
                log_str_var_quoted l_val
                if [[ ! -v l_sec ]] ; then
                    internal_err "__parse_suggested_paths(): no initial section"
                fi
                l_parse___config["${l_sec}.${l_env_var}"]="$l_val"
            else # section
                log_plain "--- parse SECTION"$'\n'
                if [[ "$l_line" =~ ^([^'(']*)'(' ]] ; then
                    strip_surrounding_whitespace l_sec "${BASH_REMATCH[1]}"
                else
                    strip_surrounding_whitespace l_sec "$l_line"
                fi
                if [[ "$l_sec" =~ ';'*$ ]] ; then
                    l_sec="${l_sec%%"${BASH_REMATCH[0]}"}"
                fi
                log_str_var_quoted l_sec
            fi
        fi
    done
    
    return 0
}

declare -a l_suggested_paths_keys l_suggested_paths_vals
__ilr___parse_suggested_paths l_suggested_paths_keys l_suggested_paths_vals g_cmd_out

echo
print_two_arrays_quoted l_suggested_paths_keys l_suggested_paths_vals

# convert_PATH_like_strs_to_unix l_suggested_paths_vals l_suggested_paths_vals
# 
# echo
# print_two_arrays_quoted l_suggested_paths_keys l_suggested_paths_vals

echo
echo "========== l_suggested_paths__formatted_str ===================="
declare l_suggested_paths__formatted_str
config_str_from_two_arrays l_suggested_paths__formatted_str l_suggested_paths_keys l_suggested_paths_vals
# print_long_str_var l_suggested_paths__formatted_str
echo -n "$l_suggested_paths__formatted_str"
echo "================================================================"

echo
declare -a l_suggested_paths_keys_reread l_suggested_paths_vals_reread
two_arrays_from_config_str l_suggested_paths_keys_reread l_suggested_paths_vals_reread "$l_suggested_paths__formatted_str"
print_two_arrays_quoted l_suggested_paths_keys_reread l_suggested_paths_vals_reread

exit 0
