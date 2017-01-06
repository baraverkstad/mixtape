#!/usr/bin/env bash
#
# Searches for matching indices in the backup.
#
# Syntax: mixtape-index [<id> | <pattern>]
#
# Arguments:
#   <none>           Prints all available indices
#   <id>             The unique index id (e.g. "@586efbc4")
#   <pattern>        A partial timestamp (e.g. "2017-01") to search for

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-common.sh
source ${LIBRARY} || exit 1

# Global vars
SEARCH=""

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
    [[ $# -le 1 ]] || usage
    SEARCH="$*"
}

# Program start
main() {
    local INDEX
    parseargs "$@"
    for INDEX in $(index_list "${SEARCH}") ; do
        echo -n "${COLOR_WARN}$(index_epoch ${INDEX})${COLOR_RESET}: ${INDEX}"
        xzcat ${INDEX} | wc -l | awk '{printf " (%s entries",$1}'
        du -h ${INDEX} | awk '{printf ", %s)\n",$1}'
    done
}

main "$@"
