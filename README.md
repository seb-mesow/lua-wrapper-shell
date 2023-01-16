# lua-wrapper-shell
A Bash-script for MSYS2 to setup and invoke multiple Lua environments

## Requirements
1. install [MSYS2](https://www.msys2.org/)
2. have a Bash shell for at least one of the following MSYS2 environment available:
    - MSYS2 / UCRT64 (recommended)
    - MSYS2 / MINGW64
3. root rights

## Installation of the script
1. checkout the repositiory
2. copy the contents of the `scripts` subdirectory to the directory in your home directory with your personal scripts (e.g. `~/scripts`)

## Setup a Lua environment
1. download the sources of some [Lua version](https://www.lua.org/ftp/)
2. download the Windows install sources of [LuaRocks](https://www.lua.org/ftp/)
    - This must be a "legacy Windows package".<br>
      Thus the filename ends with **`win32.zip`** !
3. open a Bash shell for a MSYS2 environment
4. navigate to the directory in your home directory with your personal scripts (e.g. `~/scripts`)
5. `# ./lua-wrapper-shell.bash <Lua version> -il -ilr`
    - example: `# ./lua-wrapper-shell.bash 5.4 -il -ilr`

## Invoke / Manage a Lua environment
1. open a Bash shell for a MSYS2 environment
2. navigate to the directory in your home directory with your personal scripts (e.g. `~/scripts`)
3. `$ ./lua-wrapper-shell.bash <Lua version>`
    - example: `# ./lua-wrapper-shell.bash 5.4`
    - You will enter a **subshell** (which is also a Bash shell).
    - Here you can invoke `lua`, which is the specified Lua version.<br>
      Here you can invoke `luarocks`, which depends on the specified Lua version.
    - Also other programs invoked in the subshell will depend on the specified Lua version. (e.g. `lualatex`)
    - Note: For installing rocks you will need root rights.
4. `$ exit`
    - You will get back to the normal shell.

## Help
1. open a Bash shell for a MSYS2 environment
2. navigate to the directory in your home directory with your personal scripts (e.g. `~/scripts`)
3. for normal options: `$ ./lua-wrapper-shell.bash -h`
4. for advanced and debugging options: `$ ./lua-wrapper-shell.bash -h -h`

Else the on errors outputted messages should give you concrete advices.

**Issues are welcome !**