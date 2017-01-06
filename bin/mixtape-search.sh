#!/usr/bin/env bash
#
# Searches for matching files in the backup.
#
# Syntax: mixtape-search [--all] <pattern>
#
# Options:
#   --all            Print all matching backups (not only first)

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-common.sh
source ${LIBRARY} || exit 1

# Global vars
PATTERN=""
ALL=false
INDEX_LAST=$(ls ${MIXTAPE_INDEX_DIR}/*.xz | tail -1)

# Parse command-line arguments
parseargs() {
    while [[ $# -gt 0 ]] ; do
        case "$1" in
        -\?|-h|--help)
            usage
            ;;
        --version)
            versioninfo
            ;;
        --all)
            ALL=true
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            usage
            ;;
        *)
            break
            ;;
        esac
    done
    [[ $# -gt 0 ]] || usage
    PATTERN="$*"
}

# Prints files from all indices matching a pattern
index_search_pattern() {
    local PATTERN=$1
    xzcat ${MIXTAPE_INDEX_DIR}/*.xz | cut -f 6 | grep -i -- "${PATTERN}" | sort | uniq
}

# Reads index entries from stdin and prints them
index_print() {
    local INDEX ACCESS USER GROUP DATETIME SIZEKB SIZEMB FILE SHA LOCATION EXTRA
    while IFS=$'\t' read INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION ; do
        if [[ -z ${SHA} ]] ; then
            EXTRA=""
        elif [[ ${SHA} = "->" ]] ; then
            EXTRA="-> ${LOCATION}"
        elif [[ ${SIZEKB} -gt 1024 ]] ; then
            SIZEMB=$(echo ${SIZEKB} | awk '{printf "%.1f",$1/1024}')
            EXTRA="${SIZEMB}M  ${SHA}"
        else
            EXTRA="${SIZEKB}K  ${SHA}"
        fi
        printf "%s: %s  %s %s  %s  %s\n" ${INDEX} ${ACCESS} ${USER} ${GROUP} "${DATETIME}" "${EXTRA}"
    done
}

# Checks if a file has been modified vs last index
file_modified() {
    local FILE=$1 LAST CURRENT INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION
    CURRENT=$(shasum ${FILE} 2>/dev/null | cut -d ' ' -f 1)
    while IFS=$'\t' read INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION ; do
        if [[ ${ACCESS:0:1} != "-" || ${CURRENT} == ${SHA} ]] ; then
            return 1 # false
        fi
    done < <(index_content ${INDEX_LAST} ${FILE})
    return 0 # true
}

# Program start
main() {
    local FILE FILTER
    parseargs "$@"
    if $ALL ; then
        FILTER="cat"
    else
        FILTER="uniq -f 1"
    fi
    for FILE in $(index_search_pattern "${PATTERN}") ; do
        echo -n "${COLOR_WARN}${FILE}"
        if [[ ! -e ${FILE} ]] ; then
            echo -n " ${COLOR_ERR}[deleted]"
        elif file_modified ${FILE} ; then
            echo -n " ${COLOR_ERR}[modified]"
        fi
        echo "${COLOR_RESET}"
        index_all_content ${FILE} | ${FILTER} | index_print
        echo
    done
}

main "$@"
