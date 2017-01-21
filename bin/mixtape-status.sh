#!/usr/bin/env bash
#
# Prints a backup status summary or a summary for a specified index.
#
# Syntax: mixtape-status [index]
#
# Arguments:
#   <index>          The optional index id (e.g. "@586efbc4"), named search
#                    (e.g. "first", "last") or partial timestamp (e.g.
#                    "2017-01") with optional glob matching (e.g. "20??-*-01").
#

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-common.sh
source ${LIBRARY} || exit 1

# Print mixtape directory stats summary
print_mixtape_status() {
    local DIR=$1 FILES
    echo "${COLOR_WARN}--- Statistics for ${DIR}: ---${COLOR_RESET}"
    FILES=(${DIR}/index/*.xz)
    if [[ ! -e ${FILES[0]} ]] ; then
        echo "No index files in ${DIR}/index/"
        echo
        return
    fi
    echo -n "Date range:     "
    index_datetime ${FILES[0]}
    echo -n " ("
    index_epoch ${FILES[0]}
    echo -n ") -- "
    index_datetime ${FILES[-1]}
    echo -n " ("
    index_epoch ${FILES[-1]}
    echo ")"
    echo -n "Indices:        "
    du -h --max-depth=0 ${DIR}/index | awk '{printf "%s",$1}'
    echo -n ", ${#FILES[@]} files, "
    xz --robot --list ${DIR}/index/*.xz | tail -1 | \
        awk '{printf  "ratio %.3f, %.2f MB saved\n", $6, ($5-$4)/1048576}'
    echo -n "Small files:    "
    FILES=(${DIR}/data/files/*/*.xz)
    if [[ -e ${FILES[0]} ]] ; then
        du -h --max-depth=0 ${DIR}/data/files | awk '{printf "%s, ",$1}'
        find ${DIR}/data/files -type f | xargs -n 1 tar -t --absolute-names -f | \
            wc -l | awk '{printf "%s files, ",$1}'
        xz --robot --list ${DIR}/data/files/*/*.xz | tail -1 | \
            awk '{printf  "%d archives, ratio %.3f, %.2f MB saved\n", $2, $6, ($5-$4)/1048576}'
    else
        printf "0K, 0 files\n"
    fi
    echo -n "Large files:    "
    FILES=(${DIR}/data/???/???/*)
    if [[ -e ${FILES[0]} ]] ; then
        du -h --max-depth=0 --exclude 'files/*' ${DIR}/data | awk '{printf "%s, ",$1}'
        find ${DIR}/data/???/ -type f | wc -l | awk '{printf "%s files, ",$1}'
        FILES=(${DIR}/data/???/???/*.xz)
        if [[ -e ${FILES[0]} ]] ; then
            xz --robot --list ${DIR}/data/???/???/*.xz | tail -1 | \
                awk '{printf  "%d compressed, ratio %.3f, %.2f MB saved\n", $2, $6, ($5-$4)/1048576}'
        else
            printf "0 compressed\n"
        fi
    else
        printf "0K, 0 files\n"
    fi
    echo
}

# Print backup dir and filesystem summary
print_disk_usage() {
    local DIR=$1
    echo "${COLOR_WARN}--- Disk Usage: ---${COLOR_RESET}"
    du -h --max-depth=1 --time ${DIR}
    echo
    df -h ${DIR}
}

# Prints index content summary
print_index_status() {
    local INDEX_FILE=$1
    echo "${COLOR_WARN}--- ${INDEX_FILE}: ---${COLOR_RESET}"
    echo -n "Date:     "
    index_datetime ${INDEX_FILE}
    echo -n " ("
    index_epoch ${INDEX_FILE}
    echo ")"
    echo -n "Size:     "
    xz --robot --list ${INDEX_FILE} | tail -1 | \
        awk '{printf  "%.1f KB compressed, ratio %.3f, %.1f KB saved\n", $4/1024, $6, ($5-$4)/1024}'
    echo -n "Files:    "
    xzcat ${INDEX_FILE} | wc -l | awk '{printf "%s total, ",$1}'
    xzcat ${INDEX_FILE} | grep '^d' | wc -l | awk '{printf "%s dirs, ",$1}'
    xzcat ${INDEX_FILE} | grep '^l' | wc -l | awk '{printf "%s symlinks, ",$1}'
    xzcat ${INDEX_FILE} | grep '^-' | wc -l | awk '{printf "%s regular\n",$1}'
    echo -n "Storage:  "
    xzcat ${INDEX_FILE} | grep '^-' | cut -f 8 | grep ^files/ | wc -l | awk '{printf "%s smaller files (in ",$1}'
    xzcat ${INDEX_FILE} | grep '^-' | cut -f 8 | grep ^files/ | sort | uniq | wc -l | awk '{printf "%s tar files), ",$1}'
    xzcat ${INDEX_FILE} | grep '^-' | cut -f 8 | grep -v ^files/ | wc -l | awk '{printf "%s larger files\n",$1}'
}

# Program start
main() {
    local INDEX_FILE
    checkopts
    [[ ${#ARGS[@]} -le 1 ]] || usage "too many arguments"
    if [[ ${#ARGS[@]} -eq 1 ]] ; then
        for INDEX_FILE in $(index_files "${MIXTAPE_DIR}" "${ARGS[0]}") ; do
            print_index_status ${INDEX_FILE}
        done
    elif [[ ${MIXTAPE_DIR} != ${DEFAULT_MIXTAPE_DIR} ]] ; then
        print_mixtape_status ${MIXTAPE_DIR}
        print_disk_usage ${BACKUP_DIR}
    else
        for DIR in ${BACKUP_DIR}/*/mixtape ; do
            if is_mixtape_dir ${DIR} ; then
                print_mixtape_status ${DIR}
            fi
        done
        print_disk_usage ${BACKUP_DIR}
    fi
}

main
