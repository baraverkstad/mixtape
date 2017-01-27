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

# Prints file count and sizes for XZ archives
file_size_xz() {
    local GLOB="$1" FILETYPE="${2:-}" TOTAL
    TOTAL=($(xz --robot --list ${GLOB} | tail -1 | \
             awk '{ printf "%s %.0f %.3f", $2, ($5-$4)/1024, $6 }'))
    SIZE=$(file_size_human "${TOTAL[1]}")
    if [[ ! -z "${FILETYPE}" ]] ; then
        printf "%s %s, " "${TOTAL[0]}" "${FILETYPE}"
    fi
    printf "%s ratio, %s saved\n" "${TOTAL[2]}" "${SIZE}"
}

# Print mixtape directory stats summary
print_mixtape_status() {
    local DIR=$1 FILES SIZEKB
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
    file_size_human ${DIR}/index
    echo -n ", "
    file_size_xz "${DIR}/index/*.xz" "files"
    echo -n "Small files:    "
    FILES=(${DIR}/data/files/*/*.xz)
    if [[ -e ${FILES[0]} ]] ; then
        file_size_human ${DIR}/data/files
        find ${DIR}/data/files -type f | xargs -n 1 tar -t --absolute-names -f | \
            wc -l | awk '{printf ", %s files, ",$1}'
        file_size_xz "${DIR}/data/files/*/*.xz" "tarfiles"
    else
        printf "0 K, 0 files\n"
    fi
    echo -n "Large files:    "
    FILES=(${DIR}/data/???/???/*)
    if [[ -e ${FILES[0]} ]] ; then
        SIZEKB=($(du -k --summarize --exclude 'files/*' ${DIR}/data))
        file_size_human ${SIZEKB[0]}
        find ${DIR}/data/???/ -type f | wc -l | awk '{printf ", %s files, ",$1}'
        FILES=(${DIR}/data/???/???/*.xz)
        if [[ -e ${FILES[0]} ]] ; then
            file_size_xz "${DIR}/data/???/???/*.xz" "compressed"
        else
            printf "0 compressed\n"
        fi
    else
        printf "0 K, 0 files\n"
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
    local INDEX_FILE=$1 FILES REGULAR EXTSIZE COUNT SIZEKB FMT EXT
    echo "${COLOR_WARN}--- ${INDEX_FILE} ---${COLOR_RESET}"
    echo -n "Date:        "
    index_datetime ${INDEX_FILE}
    echo -n " ("
    index_epoch ${INDEX_FILE}
    echo ")"
    echo -n "Size:        "
    file_size_human ${INDEX_FILE}
    echo -n " compressed, "
    file_size_xz ${INDEX_FILE}
    FILES=$(tmpfile_create all.txt)
    REGULAR=$(tmpfile_create regular.txt)
    xzcat ${INDEX_FILE} > ${FILES}
    grep '^-' ${FILES} > ${REGULAR}
    echo -n "Storage:     "
    cut -f 8 ${REGULAR} | grep ^files/ | wc -l | awk '{printf "%s small files",$1}'
    cut -f 8 ${REGULAR} | grep ^files/ | sort | uniq | wc -l | awk '{printf " (%s tarfiles)",$1}'
    cut -f 8 ${REGULAR} | grep -v ^files/ | wc -l | awk '{printf ", %s large files\n",$1}'
    echo -n "Files:       "
    COUNT=($(wc -l ${FILES}))
    SIZEKB=$(awk -F'\t' '{ sizekb+=$5 } END { printf "%s",sizekb }' ${REGULAR})
    FMT="%${#COUNT}s files, %5s"
    printf "${FMT}" "${COUNT}" "$(file_size_human ${SIZEKB})"
    grep '^d' ${FILES} | wc -l | awk '{printf ", %s dirs",$1}'
    grep '^l' ${FILES} | wc -l | awk '{printf ", %s symlinks",$1}'
    wc -l ${REGULAR} | awk '{printf ", %s regular\n",$1}'
    EXTSIZE=$(tmpfile_create exts.txt)
    awk -F'\t' 'match($6, /[^/]\.([^./]+)$/, ext) { count[ext[1]]++; sizekb[ext[1]]+=$5 }
                END { for (c in count) print sizekb[c], count[c], c }' ${REGULAR} | \
        sort -n -r > ${EXTSIZE}
    while read SIZEKB COUNT EXT ; do
        printf "  %-11s" ".${EXT}"
        printf "${FMT}\n" "${COUNT}" "$(file_size_human ${SIZEKB})"
    done < <(head -n 10 ${EXTSIZE})
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
        [[ -n "${INDEX_FILE:-}" ]] || warn "no matching index was found: ${ARGS[0]}"
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

# Install cleanup handler, parse command-line and launch
trap tmpfile_cleanup EXIT
parseargs "$@"
main
