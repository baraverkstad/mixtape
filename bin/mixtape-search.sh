#!/usr/bin/env bash
#
# Searches for matching files in the backup.
#
# Syntax: mixtape-search <pattern>
#

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-common.sh
source ${LIBRARY} || exit 1

# Global vars
PATTERN=""

# Prints command-line usage info and exits
usage() {
    echo "Searches for matching files in the backup."
    echo
    echo "Syntax: mixtape-search <pattern>"
    exit 1
}

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

# Prints all index entries for a file
index_list_all_by_file() {
    local FILE=$1 INDEX PREFIX
    for INDEX in ${MIXTAPE_INDEX_DIR}/*.xz ; do
        index_list ${INDEX} ${FILE}
    done
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
    if [[ -r ${FILE} ]] ; then
        LAST=$(ls ${MIXTAPE_INDEX_DIR}/*.xz | tail -1)
        CURRENT=$(shasum ${FILE} | cut -d ' ' -f 1)
        while IFS=$'\t' read INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION ; do
            if [[ ${ACCESS:0:1} != "-" || ${CURRENT} == ${SHA} ]] ; then
                return 1 # false
            fi
        done < <(index_list ${LAST} ${FILE})
    fi
    return 0 # true
}

# Program start
main() {
    parseargs "$@"
    for FILE in $(index_search_pattern "${PATTERN}") ; do
        echo -n "${COLOR_WARN}${FILE}"
        if [[ ! -e ${FILE} ]] ; then
            echo -n " ${COLOR_ERR}[deleted]"
        elif file_modified ${FILE} ; then
            echo -n " ${COLOR_ERR}[modified]"
        fi
        echo "${COLOR_RESET}"
        index_list_all_by_file ${FILE} | uniq -f 1 | index_print
        echo
    done
}

main "$@"
