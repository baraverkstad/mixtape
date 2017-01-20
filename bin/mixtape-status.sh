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

# Print mixtape status
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

# Program start
main() {
    [[ ${#ARGS[@]} -eq 0 ]] || usage
    [[ ${#OPTS[@]} -eq 0 ]] || usage
    if [[ ${MIXTAPE_DIR} != ${DEFAULT_MIXTAPE_DIR} ]] ; then
        print_mixtape_status ${MIXTAPE_DIR}
    else
        for DIR in ${BACKUP_DIR}/*/mixtape ; do
            if is_mixtape_dir ${DIR} ; then
                print_mixtape_status ${DIR}
            fi
        done
    fi
    print_disk_usage ${BACKUP_DIR}
}

main
