#!/usr/bin/env bash
#
# Searches for matching files in the backup.
#
# Syntax: mixtape-search <pattern>
#

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-functions.sh
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

# Prints matching files
matching_files() {
    xzcat ${MIXTAPE_INDEX_DIR}/*.xz | cut -f 6 | grep -i -- "$@" | sort | uniq
}

# Prints all unique index entries for a file
index_entries() {
    FILE="$1"
    xzcat ${MIXTAPE_INDEX_DIR}/*.xz | grep $'\t'"${FILE}"$'\t' | uniq
}

# Reads index entries from stdin and prints them
print_index_entries() {
    while IFS=$'\t' read ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION ; do
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
        printf "%s  %s %s  %s  %s\n" ${ACCESS} ${USER} ${GROUP} "${DATETIME}" "${EXTRA}"
    done
}

# Main function
main() {
    parseargs "$@"
    for FILE in $(matching_files "${PATTERN}") ; do
        echo -n "${COLOR_WARN}${FILE}"
        [[ -e ${FILE} ]] || echo -n " ${COLOR_ERR}[deleted]"
        echo "${COLOR_RESET}"
        index_entries ${FILE} | print_index_entries
        echo
    done
}

main "$@"
