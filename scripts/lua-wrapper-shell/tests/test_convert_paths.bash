#!/usr/bin/env bash

declare wrapper_modules_dir="../modules"

source "${wrapper_modules_dir}/main_init.bash"

exec_module config_read

debug_level=2

# $1 - path in Unix style
function test_case___convert_path_to_win() {
    local l_tcp___path_win___res \
          l_tcp___path_win___exp="$(cygpath -w -f - <<< "$1")"
    convert_path_to_win l_tcp___path_win___res "$1"
    if [[ "$l_tcp___path_win___res" != "$l_tcp___path_win___exp" ]] ; then
        echo
        printf "test case convert_path_to_win() FAILED\n"
        printf "input                : %s\n" "$1"
        printf "convert_path_to_win(): %s\n" "$l_tcp___path_win___res"
        printf "cygpath -w           : %s\n" "$l_tcp___path_win___exp"
    fi
}

# $1 - path in Windows style
function test_case___convert_path_to_unix() {
    local l_tcp___path_unix___res \
          l_tcp___path_unix___exp="$(cygpath -u -f - <<< "$1")"
    convert_path_to_unix l_tcp___path_unix___res "$1"
    if [[ "$l_tcp___path_unix___res" != "$l_tcp___path_unix___exp" ]] ; then
        echo
        printf "test case convert_path_to_unix() FAILED\n"
        printf "input                 : %s\n" "$1"
        printf "convert_path_to_unix(): %s\n" "$l_tcp___path_unix___res"
        printf "cygpath -u            : %s\n" "$l_tcp___path_unix___exp"
    fi
}

declare -a l_tcp___paths_win
mapfile -t l_tcp___paths_win <<'__end__'
C:\Users\Administrator\Downloads\luarocks-3.9.1-win32
C:\Users\Administrator\Downloads\luarocks-3.9.1-win32\install.bat
C:\Program Files\msys2\home\Administrator
C:\Program Files\msys2\home\Administrator\
C:\Program Files\Lua\5.3-ucrt64
C:\Program Files\Lua\5.3-ucrt64\
C:\Program Files\Lua\5.3-ucrt64\share\QM.lua
C:\Program Files\Lua\5.3-ucrt64\share\QM\init.lua
C:
C:\
Users
Users\Administrator
\Users\Administrator
\Users\Administrator\Downloads
Users\Administrator\Downloads
usr\bin\make
Downloads\subdir
C:\msys2\usr\bin\make
C:\msys2\ucrt64\bin\gcc
.
.\
..
..\
__end__

declare -a l_tcp___paths_unix
mapfile -t l_tcp___paths_unix <<'__end__'
/home/Administrator/scripts/lua-wrapper-shell/Lua 5.3-ucrt64
/home/Administrator/scripts/lua-wrapper-shell/Lua 5.3-ucrt64/
/home/Administrator/scripts/lua-wrapper-shell/Lua 5.3-ucrt64/hardcoded.lua.patch
/c/Program Files/Lua/5.3-ucrt64/share/QM.lua
/c/Program Files/Lua/5.3-ucrt64/share/QM/init.lua
./lua-wrapper-shell/Lua 5.3-ucrt64/hardcoded.lua.patch
/usr/bin/make
/ucrt64/bin/gcc
/
c
c/
/c
/c/
/c/Users/Administrator/Downloads
/C/Users/Administrator/Downloads
c/Users/Administrator/Downloads
/Users/Administrator/Downloads
Users/Administrator/Downloads
.
./
..
../
__end__

for l_tcp___path_unix in "${l_tcp___paths_unix[@]}" ; do
    test_case___convert_path_to_win "$l_tcp___path_unix"
done

for l_tcp___path_win in "${l_tcp___paths_win[@]}" ; do
    test_case___convert_path_to_unix "$l_tcp___path_win"
done

declare l_tcp___str_to_split="split:me:here"
declare -a l_tcp___str_splited
split_str l_tcp___str_splited "$l_tcp___str_to_split" ':'
print_indexed_array l_tcp___str_splited

exit 0
