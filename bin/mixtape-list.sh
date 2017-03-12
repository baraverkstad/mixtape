#!/usr/bin/env bash
#
# Lists indices in the backup, and optionally their content files.
#
# Syntax: mixtape-list [--long] [<index>] [<path>]
#
# Arguments:
#   <index>           The optional index id (e.g. "@586efbc4"), named search
#                     (e.g. "all", "first", "last") or partial timestamp (e.g.
#                     "2017-01") with optional glob matching (e.g. "20??-*-01").
#                     If no file path is specified, "all" is assumed. Otherwise
#                     "last" is used.
#   <path>            The optional file path for listing index content. Use "/"
#                     to show all files. An initial "/" char will be added if
#                     missing.
#
# Options:
#   --long            Prints content files in a longer format
#   --backup-dir=...  Use other root backup dir, instead of /backup
#   --mixtape-dir=... Use other mixtape dir, instead of /backup/<host>/mixtape
#   --help            Prints help information (and quits)
#   --version         Prints version information (and quits)
#

# Import common functions
SCRIPT=$(readlink "$0" || echo -n "$0")
LIBRARY=$(dirname "${SCRIPT}")/mixtape-common.sh
source "${LIBRARY}" || exit 1

# Prints index information
index_info() {
    local FILE="$1"
    echo -n "${COLOR_WARN}$(index_epoch "${FILE}")${COLOR_RESET} ${FILE}"
    xzcat "${FILE}" | wc -l | awk '{printf " (%s entries, ",$1}'
    file_size_human "${FILE}"
    printf ")\n"
}

# Reads index entries from stdin and prints them
index_content_print() {
    local FORMAT=${1:-short} COUNT=0 SIZE EXTRA
    local ACCESS DATETIME SIZEKB FILE LOCATION
    while IFS=$'\t' read -r _ ACCESS _ _ DATETIME SIZEKB FILE _ LOCATION ; do
        SIZE=""
        EXTRA=""
        if [[ ${ACCESS:0:1} == "-" ]] ; then
            SIZE=$(file_size_human "${SIZEKB}")
        elif [[ ${ACCESS:0:1} == "l" ]] ; then
            EXTRA=" -> ${LOCATION}"
        fi
        if [[ ${FORMAT} == "long" ]] ; then
            printf "%s  %s  %6s  %s%s\n" "${ACCESS}" "${DATETIME}" "${SIZE}" "${FILE}" "${EXTRA}"
        else
            printf "%s\n" "${FILE}"
        fi
        COUNT=$((COUNT+1))
    done
    if [[ ${COUNT} -eq 0 ]] ; then
        echo "-- No matched files --"
    else
        echo "-- Total: ${COUNT} files --"
    fi
}

# Program start
main() {
    local FORMAT="short" INDEX="" FILEPATH="" FIRST=true INDEX_FILE
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

# Parse command-line and launch
parseargs "$@"
main
