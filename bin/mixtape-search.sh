#!/usr/bin/env bash
#
# Searches for matching files in the backup.
#
# Syntax: mixtape-search [--all] <pattern>
#
# Arguments:
#   <pattern>        A regex search pattern (i.e. '.' for any char)
#
# Options:
#   --all            Print all matching backups (not only first)
#

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-common.sh
source ${LIBRARY} || exit 1

# Reads sorted index entries from stdin and prints them (grouped by file)
index_print() {
    local CURRENT="" CURRENT_SHA SIZEMB EXTRA
    local INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION
    while IFS=$'\t' read INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION ; do
        if [[ "${CURRENT}" != "${FILE}" ]] ; then
            [[ -z ${CURRENT} ]] || echo
            CURRENT=${FILE}
            CURRENT_SHA=$(shasum ${FILE} 2>/dev/null | cut -d ' ' -f 1 || true)
            echo -n "${COLOR_WARN}${FILE}"
            if [[ ! -e ${FILE} ]] ; then
                echo -n " ${COLOR_ERR}[deleted]"
            elif [[ ${ACCESS:0:1} == "-" && ${CURRENT_SHA} != ${SHA} ]] ; then
                echo -n " ${COLOR_ERR}[modified]"
            fi
            echo "${COLOR_RESET}"
        fi
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

# Program start
main() {
    local PATTERN FILTER OPT FILE
    [[ ${#PROGARGS[@]} -gt 0 ]] || usage
    PATTERN="${PROGARGS[@]}"
    FILTER="uniq -f 6"
    for OPT in ${PROGOPTS+"${PROGOPTS[@]:-}"} ; do
        case "${OPT}" in
        --all)
            FILTER="cat"
            ;;
        *)
            usage
            ;;
        esac
    done
    index_all_content "${MIXTAPE_DIR}" "${PATTERN}" | \
        sort --field-separator=$'\t' --key=7,7 --key=1,1 | \
        ${FILTER} | \
        sort --field-separator=$'\t' --key=7,7 --key=1,1r | \
        index_print
}

main
