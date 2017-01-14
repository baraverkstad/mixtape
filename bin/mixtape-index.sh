#!/usr/bin/env bash
#
# Searches for matching indices in the backup.
#
# Syntax: mixtape-index [<id> | <pattern>]
#
# Arguments:
#   <none>           Prints all available indices
#   <id>             The unique index id (e.g. "@586efbc4") or the special
#                    keywords "first" or "last"
#   <pattern>        A partial timestamp (e.g. "2017-01") to search for
#                    (accepts glob matches, i.e. ? and * chars)
#

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-common.sh
source ${LIBRARY} || exit 1

# Program start
main() {
    local SEARCH="" INDEX
    [[ ${#PROGARGS[@]} -le 1 ]] || usage
    if [[ ${#PROGARGS[@]} -eq 1 ]] ; then
        SEARCH="${PROGARGS[@]}"
    fi
    [[ ${#PROGOPTS[@]} -eq 0 ]] || usage
    for INDEX in $(index_list "${MIXTAPE_DIR}" "${SEARCH}") ; do
        echo -n "${COLOR_WARN}$(index_epoch ${INDEX})${COLOR_RESET}: ${INDEX}"
        xzcat ${INDEX} | wc -l | awk '{printf " (%s entries",$1}'
        du -h ${INDEX} | awk '{printf ", %s)\n",$1}'
    done
}

main
