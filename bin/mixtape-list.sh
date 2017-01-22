#!/usr/bin/env bash
#
# Lists indices in the backup, and optionally their content files.
#
# Syntax: mixtape-list [--long] [<index>] [<path>]
#
# Arguments:
#   <index>          The optional index id (e.g. "@586efbc4"), named search
#                    (e.g. "all", "first", "last") or partial timestamp (e.g.
#                    "2017-01") with optional glob matching (e.g. "20??-*-01").
#                    If no file path is specified, "all" is assumed. Otherwise
#                    "last" is used.
#   <path>           The optional file path for listing index content. Use "/"
#                    to show all files. An initial "/" char will be added if
#                    missing.
#
# Options:
#   --long           Prints content files in a longer format
#

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-common.sh
source ${LIBRARY} || exit 1

# Prints index information
index_info() {
    local FILE="$1"
    echo -n "${COLOR_WARN}$(index_epoch ${FILE})${COLOR_RESET}: ${FILE}"
    xzcat ${FILE} | wc -l | awk '{printf " (%s entries, ",$1}'
    file_size_human ${FILE}
    printf ")\n"
}

# Reads index entries from stdin and prints them
index_content_print() {
    local FORMAT=${1:-short} COUNT=0 SIZE EXTRA
    local INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION
    while IFS=$'\t' read INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION ; do
        SIZE=""
        EXTRA=""
        if [[ ${ACCESS:0:1} == "-" ]] ; then
            SIZE=$(file_size_human ${SIZEKB})
        elif [[ ${ACCESS:0:1} == "l" ]] ; then
            EXTRA=" -> ${LOCATION}"
        fi
        if [[ ${FORMAT} == "long" ]] ; then
            printf "%s  %s  %6s  %s%s\n" ${ACCESS} "${DATETIME}" "${SIZE}" "${FILE}" "${EXTRA}"
        else
            printf "%s\n" "${FILE}"
        fi
        COUNT=$((COUNT+1))
    done
    if [[ ${COUNT} -eq 0 ]] ; then
        printf -- "-- No matched files --\n"
    else
        printf -- "-- Total: ${COUNT} files --\n"
    fi
}

# Program start
main() {
    local FORMAT="short" INDEX="" FILEPATH="" FIRST=true OPT INDEX_FILE
    checkopts --long
    if parseopt --long ; then
        FORMAT="long"
    fi
    [[ ${#ARGS[@]} -le 2 ]] || usage "too many arguments"
    if [[ ${#ARGS[@]} -eq 1 && ${ARGS[0]:0:1} == "/" ]] ; then
        INDEX="last"
        FILEPATH="${ARGS[0]:-}"
    else
        INDEX="${ARGS[0]:-all}"
        FILEPATH="${ARGS[1]:-}"
    fi
    if [[ -n "${FILEPATH}" && "${FILEPATH:0:1}" != "/" ]] ; then
        FILEPATH="/${FILEPATH}"
    fi
    for INDEX_FILE in $(index_files "${MIXTAPE_DIR}" "${INDEX}") ; do
        ${FIRST} || [[ -z "${FILEPATH}" ]] || echo
        index_info "${INDEX_FILE}"
        if [[ -n "${FILEPATH}" ]] ; then
            index_content "${MIXTAPE_DIR}" "${INDEX_FILE}" "${FILEPATH}" | index_content_print ${FORMAT}
        fi
        FIRST=false
    done
    if [[ -z "${INDEX_FILE:-}" && ${INDEX} != "all" ]] ; then
        warn "no matching index was found: ${INDEX}"
    fi
}

main