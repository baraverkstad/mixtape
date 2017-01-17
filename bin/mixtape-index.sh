#!/usr/bin/env bash
#
# Lists indices in the backup, and optionally their content files.
#
# Syntax: mixtape-index [--long] [<index> [<path>]]
#
# Arguments:
#   <index>          The optional index id (e.g. "@586efbc4"), named search
#                    (e.g. "all", "first", "last") or partial timestamp (e.g.
#                    "2017-01") with optional glob matching (e.g. "20??-*-01")
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
    local INDEX="$1"
    echo -n "${COLOR_WARN}$(index_epoch ${INDEX})${COLOR_RESET}: ${INDEX}"
    xzcat ${INDEX} | wc -l | awk '{printf " (%s entries",$1}'
    du -h ${INDEX} | awk '{printf ", %s)\n",$1}'
}

# Reads index entries from stdin and prints them
index_content_print() {
    local FORMAT=${1:-short} COUNT=0 SIZE SIZEMB EXTRA
    local INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION
    while IFS=$'\t' read INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION ; do
        SIZE=""
        EXTRA=""
        if [[ ${ACCESS:0:1} == "-" ]] ; then
            if [[ ${SIZEKB} -gt 1024 ]] ; then
                SIZEMB=$(echo ${SIZEKB} | awk '{printf "%.1f",$1/1024}')
                SIZE="${SIZEMB}M"
            else
                SIZE="${SIZEKB}K"
            fi
        elif [[ ${ACCESS:0:1} == "l" ]] ; then
            EXTRA=" -> ${LOCATION}"
        fi
        if [[ ${FORMAT} == "long" ]] ; then
            printf "%s  %s  %6s  %s%s\n" ${ACCESS} "${DATETIME}" "${SIZE}" "${FILE}" "${EXTRA}"
        #elif [[ ${FORMAT} == "full" ]] ; then
        #    printf "%s  %s %s  %s  %6s  %s%s\n" ${ACCESS} ${USER} ${GROUP} "${DATETIME}" "${SIZE}" "${FILE}" "${EXTRA}"
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
    local ID="" PREFIX="" FORMAT="short" INDEX FIRST=true
    [[ ${#PROGARGS[@]} -le 2 ]] || usage
    while [[ ${#PROGOPTS[@]} -gt 0 ]] ; do
        case "${PROGOPTS[0]}" in
        --long)
            FORMAT="long"
            ;;
        *)
            usage
            ;;
        esac
        PROGOPTS=("${PROGOPTS[@]:1}")
    done
    if [[ ${#PROGARGS[@]} -ge 1 ]] ; then
        ID="${PROGARGS[0]}"
    fi
    if [[ ${#PROGARGS[@]} -ge 2 ]] ; then
        PREFIX="${PROGARGS[1]}"
        if [[ "${PREFIX:0:1}" != "/" ]] ; then
            PREFIX="/${PREFIX}"
        fi
    fi
    for INDEX in $(index_list "${MIXTAPE_DIR}" "${ID}") ; do
        ${FIRST} || [[ -z "${PREFIX}" ]] || echo
        index_info "${INDEX}"
        if [[ -n "${PREFIX}" ]] ; then
            index_content "${INDEX}" "^${PREFIX}" | index_content_print ${FORMAT}
        fi
        FIRST=false
    done
}

main
