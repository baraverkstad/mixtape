#!/usr/bin/env bash
#
# Prints a backup status summary.
#
# Syntax: mixtape-status
#

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-common.sh
source ${LIBRARY} || exit 1

# Prints command-line usage info and exits
usage() {
    echo "Prints a backup status summary."
    echo
    echo "Syntax: mixtape-status"
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
        *)
            usage
            ;;
        esac
    done
}

# Print mixtape status
print_mixtape_status() {
    echo "--- Statistics for ${MIXTAPE_DIR}: ---"
    cd ${MIXTAPE_INDEX_DIR}
    local INDEX_FILES=(*.xz)
    echo -n "Date range:     "
    index_datetime ${INDEX_FILES[0]}
    echo -n " ("
    index_epoch ${INDEX_FILES[0]}
    echo -n ") -- "
    index_datetime ${INDEX_FILES[-1]}
    echo -n " ("
    index_epoch ${INDEX_FILES[-1]}
    echo ")"
    echo -n "Indices:        "
    du -h --max-depth=0 ${MIXTAPE_INDEX_DIR} | awk '{printf "%s",$1}'
    echo -n ", ${#INDEX_FILES[@]} files, "
    xz --robot --list ${MIXTAPE_INDEX_DIR}/*.xz | tail -1 | \
        awk '{printf  "ratio %.3f, %.2f MB saved\n", $6, ($5-$4)/1048576}'
    echo -n "Small files:    "
    du -h --max-depth=0 ${MIXTAPE_DATA_DIR}/files | awk '{printf "%s, ",$1}'
    find ${MIXTAPE_DATA_DIR}/files -type f | xargs -L 1 tar -t --absolute-names -f | \
        wc -l | awk '{printf "%s files, ",$1}'
    xz --robot --list ${MIXTAPE_DATA_DIR}/files/*/*.xz | tail -1 | \
        awk '{printf  "%d archives, ratio %.3f, %.2f MB saved\n", $2, $6, ($5-$4)/1048576}'
    echo -n "Large files:    "
    du -h --max-depth=0 --exclude 'files/*' ${MIXTAPE_DATA_DIR} | awk '{printf "%s, ",$1}'
    find ${MIXTAPE_DATA_DIR}/???/ -type f | wc -l | awk '{printf "%s files, ",$1}'
    xz --robot --list ${MIXTAPE_DATA_DIR}/???/???/*.xz | tail -1 | \
        awk '{printf  "%d compressed, ratio %.3f, %.2f MB saved\n", $2, $6, ($5-$4)/1048576}'
    echo
}

# Print backup dir and filesystem summary
print_disk_usage() {
    echo "--- Disk Usage: ---"
    du -h --max-depth=1 --time ${BACKUP_DIR}
    echo
    df -h ${BACKUP_DIR}
}

# Program start
main() {
    parseargs "$@"
    print_mixtape_status
    print_disk_usage
}

main "$@"