#!/usr/bin/env bash
#
# Prints a backup status summary.
#
# Syntax: mixtape-status
#

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-functions.sh
source ${LIBRARY} || exit 1

# Prints command-line usage info and exits
usage() {
    echo "Prints a backup status summary."
    echo
    echo "Syntax: mixtape-status"
    exit 1
}

# Parse command-line arguments
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

# Print mixtape status
cd ${MIXTAPE_INDEX_DIR}
INDEX_FILES=(*.xz)
INDEX_FIRST=${INDEX_FILES[0]}
INDEX_LAST=${INDEX_FILES[-1]}
INDEX_SIZE=$(du -h --max-depth=0 ${MIXTAPE_INDEX_DIR} | awk '{print $1}')
INDEX_COUNT=$(find ${MIXTAPE_INDEX_DIR} -type f | wc -l)
INDEX_STAT=$(xz --robot --list ${MIXTAPE_INDEX_DIR}/*.xz | tail -1 | \
             awk '{printf  "ratio %.3f, %.2f MB saved\n", $6, ($5-$4)/1048576}')
SMALL_SIZE=$(du -h --max-depth=0 ${MIXTAPE_DATA_DIR}/files | awk '{print $1}')
SMALL_COUNT=$(find ${MIXTAPE_DATA_DIR}/files -type f | xargs -L 1 tar -t --absolute-names -f | wc -l)
SMALL_STAT=$(xz --robot --list ${MIXTAPE_DATA_DIR}/files/*/*.xz | tail -1 | \
             awk '{printf  "%d archives, ratio %.3f, %.2f MB saved\n", $2, $6, ($5-$4)/1048576}')
LARGE_SIZE=$(du -h --max-depth=0 --exclude 'files/*' ${MIXTAPE_DATA_DIR} | awk '{print $1}')
LARGE_COUNT=$(find ${MIXTAPE_DATA_DIR}/???/ -type f | wc -l)
LARGE_STAT=$(xz --robot --list ${MIXTAPE_DATA_DIR}/???/???/*.xz | tail -1 | \
             awk '{printf  "%d compressed, ratio %.3f, %.2f MB saved\n", $2, $6, ($5-$4)/1048576}')
echo "### Statistics for ${MIXTAPE_DIR}:"
echo "Date range:     ${INDEX_FIRST:6:10} to ${INDEX_LAST:6:10}"
echo "Indices:        ${INDEX_SIZE}, ${INDEX_COUNT} files, ${INDEX_STAT}"
echo "Small files:    ${SMALL_SIZE}, ${SMALL_COUNT} files, ${SMALL_STAT}"
echo "Large files:    ${LARGE_SIZE}, ${LARGE_COUNT} files, ${LARGE_STAT}"
echo

# Print backup dir summary:
echo "### Disk Usage:"
du -h --max-depth=1 --time ${BACKUP_DIR}
echo

# Print backup fs summary:
df -h ${BACKUP_DIR}
