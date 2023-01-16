exec_module ext_cmds

# searches the given directory for the install.bat
# or an appropriate named zipfile containing it
# and saves the resulting direct parent dirpath into the provided variable.
#
# The ret str var is set to the found filepath, if a file was found.
# If no file could be found, then the ret str var name is set to the empty string.
#
# arguments:
#  $1  - ret str var name for the filepath
#  $2  - either: filepath of the file to search 
#                can also be an compressed archive (see $4)
#            or: dirpath to search in Unix style
#                can also contain an compressed archive (see $4)
#  $3  - filepath trailing portion regex in Unix style
#        Thus must match with file extensions.
#        The begin of this must match the full filename or the full dirname of a parent dir.
# [$4] - compressed archive filepath stem trailing portion regex
#        Must match without file extensions.
#        The begin of this must match the full filename stem or the full dirname of a parent dir.
#
# exceptions:
# FF___exc___search_path_not_exists
#       The provided filepath resp. dirpath to search in, does not exist.
function find_file() {
    debug << __end__
start find_file()
    filepath or dirpath to search in == (\$2)
        $2
    filepath trailing portion regex == (\$3)
        $3
__end__
    local -n l_ff___found_filepath="$1"
    local l_ff___search_path="$2" \
          l_ff___abs_filepath_trailing_portion_regex="$3"
    if [[ -v 4 ]] ; then
        local l_ff___compressed_archive_filepath_stem_trailing_portion_regex="$4" \
              l_ff___compressed_archive_filepath_trailing_portion_regex="$4\\.(zip|tar\\.gz)"
        debug_plain <<__end__
    compressed archive filepath trailing portion stem regex == (\$4)
        $4
    
    l_ff___compressed_archive_filepath_trailing_portion_regex == (local var)
        $l_ff___compressed_archive_filepath_trailing_portion_regex
__end__
    fi
    
    l_ff___found_filepath=
    # By default the file to search for is considered to be not found.
    
    if [[ -f "$l_ff___search_path" ]] ; then
        # Argument is a file.
        debug_plain "Argument is existing file"
        
        realpath "$l_ff___search_path"
        local l_ff___abs_filepath="${g_cmd_out[0]}"
        
        debug_str_var_quoted l_ff___abs_filepath
        
        if [[ "$l_ff___abs_filepath" =~ '/'$l_ff___abs_filepath_trailing_portion_regex$ ]] ; then
            l_ff___found_filepath="$l_ff___abs_filepath"
            debug_plain "argument is directly the file to find (return success)"
            return 0
        fi
        
        # Else it is assumed, that the filepath is a compressed archive
        debug "argument is considered the filepath of a compressed archive"
        
        # if $4 is provided, then the filepath must also match the regex + a commen extension for a compressed archive
        if [[  ( -v l_ff___compressed_archive_filepath_trailing_portion_regex ) \
            && ( ! ( "$l_ff___abs_filepath" =~ $l_ff___compressed_archive_filepath_trailing_portion_regex ) ) \
        ]] ; then
            debug_plain "4th arg was provided and filepath of archive does not match this regex (return fail)"
            return 0
        fi
        
        local l_ff___uncompressed_archive_parent_dirpath
        if ! __ff___uncompress_archive "$l_ff___abs_filepath" ; then
            debug_plain "uncompressing archive failed (return fail)"
            return 0
        fi
        debug_plain "uncompressing archive succeeded"
        
        # search the uncompressed archive in a recursive manner
        debug_plain "search in archive in a recursive manner"
        find_file "${!l_ff___found_filepath}" \
            "$l_ff___uncompressed_archive_parent_dirpath" \
            "$l_ff___abs_filepath_trailing_portion_regex" \
            ${l_ff___compressed_archive_filepath_stem_trailing_portion_regex:+\
"$l_ff___compressed_archive_filepath_stem_trailing_portion_regex"}
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
        if [[ -z "$l_ff___found_filepath" ]] ; then
            debug_plainf "not found file in archive\n%s(return fail)" "$2"
            return 0
        fi
        
        debugf "found file\n%s\nin archive\n%s\n (return fail)" \
            "$l_ff___found_filepath"
            "$l_ff___search_path"
        return 0
        
    elif [[ -d "$l_ff___search_path" ]] ; then 
        # Argument is a directory.
        debug_plain "argument is existing directory"
        
        __ff___find_file_plain "${!l_ff___found_filepath}" \
            "$l_ff___search_path" \
            "$l_ff___abs_filepath_trailing_portion_regex"
        if [[ "$l_ff___found_filepath" ]] ; then
            debug "more or less directly found file in directory (return success)"
            return 0
        fi
        
        # Else for a compressed archive is searched.
        debug "file not more or less directly found in directory"
        
        if [[ ! -v l_ff___compressed_archive_filepath_stem_trailing_portion_regex ]] ; then
            debug_plain "4th arg not provided"
            debug_plain "thus not search for a compressed archive (return fail)"
            return 0
        fi
        debug_plain "4th arg provided"
        debug_plain "thus search for compressed archive"
        
        local l_ff___compressed_archive_filepath
        __ff___find_file_plain l_ff___compressed_archive_filepath \
            "$l_ff___search_path" \
            "$l_ff___compressed_archive_filepath_trailing_portion_regex"
        if [[ -z "$l_ff___compressed_archive_filepath" ]] ; then
            debug "not found an archive (return fail)"
            return 0
        fi
        debug_plain "found archive '$l_ff___compressed_archive_filepath'"
        
        local l_ff___uncompressed_archive_parent_dirpath
        if ! __ff___uncompress_archive "$l_ff___compressed_archive_filepath" ; then
            debug "uncompressing archive failed (return fail)"
            return 0
        fi
        debug "uncompressing archive succeeded"
         
        # search the uncompressed archive in a recursive manner
        debug_plain "search in archive in a recursive manner"
        find_file "${!l_ff___found_filepath}" \
            "$l_ff___uncompressed_archive_parent_dirpath" \
            "$l_ff___abs_filepath_trailing_portion_regex" \
            ${l_ff___compressed_archive_filepath_stem_trailing_portion_regex:+\
"$l_ff___compressed_archive_filepath_stem_trailing_portion_regex"}
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) return 0 ;; # not handle here
        esac
        if [[ -z "$l_ff___found_filepath" ]] ; then
            debugf "not found file in archive\n%s\n(return fail)" "$l_ff___compressed_archive_filepath"
            return 0
        fi
        
        debug_plainf "found file\n%s\nin archive\n%s\n(return success)" \
            "$l_ff___found_filepath" \
            "$l_ff___compressed_archive_filepath"
        return 0
        
    else
        # Argument is neither a file nor a directory.
#         local l_ff___win_path
#         convert_path_to_win l_ff___win_path "$2"
#         user_err <<__end__
# The provided directory or file
# $l_ff___win_path
# does not exist
# __end__
        local l_ff___barrier_str
        printf -v l_ff___barrier_str \
            "The provided directory or file\n%s\ndoes not exist." \
            "$l_ff___search_path"
        exc___raise FF___exc___search_path_not_exists \
            "$l_ff___barrier_str"
        return 0
    fi
}

# tries to find a file in a directory
# and retrieves its filepath if found
# 
# The ret str var is set to the found filepath, if a file was found.
# If no file could be found, then the ret str var name is set to the empty string.
#
# arguments:
# $1 - ret str var name for the direct parent dirpath of the install.bat
# $2 - dirpath to search in
# $3 - filepath trailing portion regex in Unix style
#      Thus must match with file extensions.
#      The begin of this must match the full filename or the full dirname of a parent dir.
function __ff___find_file_plain() {
    local -n l_ff___found_filepath="$1"
    l_ff___found_filepath=
    # By default the file to search for is considered to be not found.
    
    # pipeline does not work
    
    # note that the command substitution removes the trailing new line
    # note that a here string always appends a newline
    find "${2%/}" \
        -regextype posix-extended \
        -type f \
        -regex "${2%/}(/.)*/$3" \
        -print
    
    if (( "${#g_cmd_out[@]}" < 1 )) ; then
        # The provided directory contains no files matching the regex
        return 0
    fi
    
    # Currently only the first result when sorted is returned
    
    # l_ff___found="$(sort <<< "$l_ff___found")"
    local l_ff___IFS_backup="$IFS"
    IFS=$'\n'
    sort <<< "${g_cmd_out[*]}"
    IFS="$l_ff___IFS_backup"
    
    l_ff___found_filepath="${g_cmd_out[0]}"
    
    return 0
}

# unzips "$1"
# and sets
# l_ff___uncompressed_archive_parent_dirpath
#  to the direct parent of the uncompressed archive
#
# returns a zero exit status if the uncompression is successful
# 
# arguments:
# $1 - ret str var name for the dirpath, which contains whatever the archive contains
# $2 - compressed archive filepath
function __ff___uncompress_archive() {
    ec___temp_dirpath l_ff___uncompressed_archive_parent_dirpath
    
    if [[ "$1" =~ \.zip[^/]* ]] ; then
        unzip -q "$1" -d "$l_ff___uncompressed_archive_parent_dirpath"
    else
        mkdir "$l_ff___uncompressed_archive_parent_dirpath"
        tar -C "$l_ff___uncompressed_archive_parent_dirpath" -xaf "$1"
    fi
}
