# A files listing is represents the requested information about PFAs.
# 
# LFA
#     assoc array for a file, which contains infos to list
# LGA
#     assoc array for a group of files to list infos about
#     corresponds to an CGA
#     maps each contained /and requested/ FK to its LFAn 

exec_module CFA
exec_module PFA

# creates a new FL object
# from user input
# 
# arguments:
#  $1     - ret var name for FL_n
#  $2     - PFA_query (name of an assoc array with the infos to query)
# [$3...] - uFKs and/or uGKs
function FL___new_FL_from_uFKs_or_uGKs() {
    local l_FL___FL_n="$1" \
          l_FL___query_n="$2"
    shift 2
    local -a l_FL___uFKs_or_uGKs=("$@")
    
    __FL___new "$l_FL___FL_n" "$l_FL___query_n" \
        __FL___new_FL_from_uFKs_or_uGKs___provide_FKs
}
# $1 - FKs_n
function __FL___new_FL_from_uFKs_or_uGKs___provide_FKs() {
    CFA___FKs_from_uFKs_or_uGKs "$1" "${l_FL___uFKs_or_uGKs[@]}"
}

# creates a new FL object
# from a precompiled indexed array of FKs
# 
# arguments:
# $1 - ret var name for FL_n
# $2 - PFA_query (name of an assoc array with the infos to query)
# $3 - FKs_n
function FL___new_FL_from_FKs() {
    local -n l_FL___arg_FKs="$3"
    
    __FL___new "$1" "$2" \
        __FL___new_FL_from_FKs___provide_FKs
}
# $1 - FKs_n
function __FL___new_FL_from_FKs___provide_FKs() {
    local -n l_FL___FKs="$1"
    l_FL___FKs=("${l_FL___arg_FKs[@]}")
}

# $1 - ret var name for FL_n
# $2 - PFA_query (name of an assoc array with the infos to query)
# $3 - callback
#           stores the FKs in the indexed array named $1
#           (which is guaranteed, to be empty before invoking the callback)
function __FL___new() {
    local -n l_FL___FL_n="$1" \
             l_FL___query___arg="$2"
    
    unique_varname "$1" "m_FL___FL_"
    
    local         l_FL___query_n="${l_FL___FL_n}___query" \
                    l_FL___FKs_n="${l_FL___FL_n}___FKs" \
                 l_FL___PFA_ns_n="${l_FL___FL_n}___PFA_ns" \
                 l_FL___LFA_ns_n="${l_FL___FL_n}___LFA_ns" \
                    l_FL___GKs_n="${l_FL___FL_n}___GKs" \
           l_FL___LGA___FKs_ns_n="${l_FL___FL_n}___LGA___FKs_ns" \
        l_FL___LGA___LFA_ns_ns_n="${l_FL___FL_n}___LGA___LFA_ns_ns" \
                     l_FL___info \
                     l_FL___FK \
                     l_FL___GK \
                     l_FL___CGA_FK \
                     l_FL___subscript
    
    declare -g -A "$l_FL___FL_n" \
                  "$l_FL___query_n"
    declare -g -a "$l_FL___FKs_n" \
                  "$l_FL___PFA_ns_n" \
                  "$l_FL___LFA_ns_n" \
                  "$l_FL___GKs_n" \
                  "$l_FL___LGA___FKs_ns_n" \
                  "$l_FL___LGA___LFA_ns_ns_n"
    
    local -n l_FL___FL="$l_FL___FL_n" \
             l_FL___query="$l_FL___query_n" \
             l_FL___FKs="$l_FL___FKs_n" \
             l_FL___PFA_ns="$l_FL___PFA_ns_n" \
             l_FL___LFA_ns="$l_FL___LFA_ns_n" \
             l_FL___GKs="$l_FL___GKs_n" \
             l_FL___LGA___FKs_ns="$l_FL___LGA___FKs_ns_n" \
             l_FL___LGA___LFA_ns_ns="$l_FL___LGA___LFA_ns_ns_n"
    
    l_FL___FL["query_n"]="$l_FL___query_n"
    l_FL___FL["FKs_n"]="$l_FL___FKs_n"
    l_FL___FL["PFA_ns_n"]="$l_FL___PFA_ns_n"
    l_FL___FL["LFA_ns_n"]="$l_FL___LFA_ns_n"
    l_FL___FL["GKs_n"]="$l_FL___GKs_n"
    l_FL___FL["LGA___FKs_ns_n"]="$l_FL___LGA___FKs_ns_n"
    l_FL___FL["LGA___LFA_ns_ns_n"]="$l_FL___LGA___LFA_ns_ns_n"
    
    for l_FL___info in "${!l_FL___query___arg[@]}" ; do
        l_FL___query["$l_FL___info"]=
    done
    
    log_assoc_array l_FL___query
    
    "$3" "$l_FL___FKs_n"
    
    local l_FL___PFA_n l_FL___LGA___FKs_n l_FL___LGA___LFA_ns_n
    for l_FL___FK in "${l_FL___FKs[@]}" ; do
        PFA___new_from_FK l_FL___PFA_n "$l_FL___FK"
        l_FL___PFA_ns+=("$l_FL___PFA_n")
        
        l_FL___LFA_n="${l_FL___FL_n}___LFA___${l_FL___FK}"
        declare -g -A "$l_FL___LFA_n"
        
        PFA___query "$l_FL___LFA_n" "$l_FL___PFA_n" "$l_FL___query_n"
        case "$EXCEPTION_ID" in
            '') ;; # no exception
            *) exc___unhandled ;;
        esac
        
        l_FL___LFA_ns+=("$l_FL___LFA_n")
        
        # calculates l_FL___GKs / l_FL___LGA___FKs_ns / l_FL___LGA___LFA_ns_ns
        # as subset of GK_to_CGAn_map
        for l_FL___GK in "${!GK_to_CGAn_map[@]}" ; do
            local -n l_FL___CGA="${GK_to_CGAn_map["$l_FL___GK"]}"
            for l_FL___CGA_FK in "${!l_FL___CGA[@]}" ; do
                if [[ "$l_FL___CGA_FK" == "$l_FL___FK" ]] ; then
                       l_FL___LGA___FKs_n="${l_FL___FL_n}___LGA___${l_FL___GK}___FKs"
                    l_FL___LGA___LFA_ns_n="${l_FL___FL_n}___LGA___${l_FL___GK}___LFA_ns"
                    if [[ ! -v "$l_FL___LGA___FKs_n" ]] ; then
                        declare -g -a "$l_FL___LGA___FKs_n" "$l_FL___LGA___LFA_ns_n"
                        l_FL___GKs+=("$l_FL___GK")
                        l_FL___LGA___FKs_ns+=("$l_FL___LGA___FKs_n")
                        l_FL___LGA___LFA_ns_ns+=("$l_FL___LGA___LFA_ns_n")
                    fi
                    local -n l_FL___LGA___FKs="$l_FL___LGA___FKs_n" \
                             l_FL___LGA___LFA_ns="$l_FL___LGA___LFA_ns_n"
                    l_FL___LGA___FKs+=("$l_FL___FK")
                    l_FL___LGA___LFA_ns+=("$l_FL___LFA_n")
                fi
            done
        done
        
    done
    
    # get uFK
    if [[ -v l_FL___query["uFK"] ]] ; then
        for l_FL___subscript in "${!l_FL___FKs[@]}" ; do
            l_FL___FK="${l_FL___FKs["$l_FL___subscript"]}"
            local -n l_FL___LFA="${l_FL___LFA_ns["$l_FL___subscript"]}" \
                     l_FL___CFA="${FK_to_CFAn_map["$l_FL___FK"]}"
            l_FL___LFA["uFK"]="${l_FL___CFA["uFK"]}"
        done
    fi
}

# formats the represention of the information
# Files are not grouped.
# 
# arguments:
# $1 - ret str var name
# $2 - FL_n
# $3 - callback <ret str var name> <LFA_n>
function FL___format_as_files() {
    local -n l_FL___str="$1" \
             l_FL___FL="$2"
    
    local -n l_FL___LFA_ns="${l_FL___FL["LFA_ns_n"]}"
    
    local l_FL___LFA_n \
          l_FL___str___event
    
    l_FL___str=
    
    for l_FL___LFA_n in "${l_FL___LFA_ns[@]}" ; do
        trace_assoc_array "$l_FL___LFA_n"
        
        l_FL___str___event=
        "$3" l_FL___str___event \
            "$l_FL___LFA_n"
        
        l_FL___str="${l_FL___str}${l_FL___str___event}"
    done
}

# formats the represention of the information
# All files are grouped.
# 
# arguments:
# $1 - ret str var name
# $2 - FL_n
# $3 - assoc array with callbacks:
#        ["file"] <ret str var name> <LFA_n> <already_printed?>
#       ["group"] <ret str var name> <uGK> <formatted files str>
#                 (Recommendation: use intend_long_str() from the aux module)
function FL___format_as_groups() {
    local -n l_FL___str="$1" \
             l_FL___FL="$2" \
             l_FL___callbacks="$3"
    
    local l_FL___callback___file="${l_FL___callbacks["file"]}" \
         l_FL___callback___group="${l_FL___callbacks["group"]}" \
        l_FL___FK \
        l_FL___GK \
        l_FL___subscript \
        l_FL___LGA___subscript \
        l_FL___str___event \
        l_FL___str___files
    
    local -n    l_FL___FKs="${l_FL___FL["FKs_n"]}" \
                l_FL___GKs="${l_FL___FL["GKs_n"]}" \
       l_FL___LGA___FKs_ns="${l_FL___FL["LGA___FKs_ns_n"]}" \
    l_FL___LGA___LFA_ns_ns="${l_FL___FL["LGA___LFA_ns_ns_n"]}"
    
    trace_two_arrays "${!l_FL___GKs}" "${!l_FL___LGA___FKs_ns}"
    trace_two_arrays "${!l_FL___GKs}" "${!l_FL___LGA___LFA_ns_ns}"
    
    local -A l_FL___is_FK_already_printed # maps from FK to bool
    for l_FL___FK in "${l_FL___FKs[@]}" ; do
        l_FL___is_FK_already_printed["$l_FL___FK"]=0
    done
    
    
    l_FL___str=
    
    for l_FL___subscript in "${!l_FL___GKs[@]}" ; do
        l_FL___GK="${l_FL___GKs["$l_FL___subscript"]}"
        
        local -n    l_FL___LGA___FKs="${l_FL___LGA___FKs_ns["$l_FL___subscript"]}" \
                 l_FL___LGA___LFA_ns="${l_FL___LGA___LFA_ns_ns["$l_FL___subscript"]}"
        
        trace_two_arrays "${!l_FL___LGA___FKs}" "${!l_FL___LGA___LFA_ns}"
        
        l_FL___str___files=
        
        for l_FL___LGA___subscript in "${!l_FL___LGA___FKs[@]}" ; do
            l_FL___FK="${l_FL___LGA___FKs["$l_FL___LGA___subscript"]}"
            
            trace_assoc_array "${l_FL___LGA___LFA_ns["$l_FL___LGA___subscript"]}"
            
            l_FL___str___event=
            "$l_FL___callback___file" l_FL___str___event \
                "${l_FL___LGA___LFA_ns["$l_FL___LGA___subscript"]}" \
                "${l_FL___is_FK_already_printed["$l_FL___FK"]}"
            
            if [[ "$l_FL___str___event" ]] ; then
                l_FL___is_FK_already_printed["$l_FL___FK"]=1
                l_FL___str___files="${l_FL___str___files}${l_FL___str___event}"
            fi
        done
        
        l_FL___str___event=
        "$l_FL___callback___group" l_FL___str___event \
            "$l_FL___GK" \
            "$l_FL___str___files"
        l_FL___str="${l_FL___str}${l_FL___str___event}"
        
    done
}
