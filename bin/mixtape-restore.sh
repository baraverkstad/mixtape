#!/usr/bin/env bash
#
# Restores files from the backup.
#
# Syntax: mixtape-restore <index> <path>
#
# Arguments:
#   <index>          The index id (e.g. "@586efbc4"), named search (e.g.
#                    "first", "last") or unique timestamp (e.g. "2017-01-01")
#   <path>           The absolute file path for files to restore (e.g. "/etc")
#                    Use "/" to restore all files. An initial "/" char will be
#                    added if missing.
#

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-common.sh
source ${LIBRARY} || exit 1

# Restores files from a backup (listed in tar file order)
restore_files() {
    local DIR="$1" TARFILE="" FILES
    local INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION
    mkdir -p ${DIR} ${TMP_DIR}
    cd ${DIR}
    FILES=${TMP_DIR}/files.txt
    while IFS=$'\t' read INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION ; do
        if [[ ${ACCESS:0:1} == "d" && ! -e "${FILE:1}" ]] ; then
            mkdir -p "${FILE:1}"
        elif [[ ${ACCESS:0:1} == "l" ]] ; then
            ln -s "${LOCATION}" "${FILE:1}"
        elif [[ ${ACCESS:0:1} == "-" ]] ; then
            if [[ ${LOCATION:0:6} != "files/" ]] ; then
                largefile_restore "${MIXTAPE_DIR}/data/${LOCATION}" "${FILE:1}"
            elif [[ "${TARFILE}" != "${LOCATION}" ]] ; then
                if [[ -n "${TARFILE}" ]] ; then
                    tar -xf "${MIXTAPE_DIR}/data/${TARFILE}" -T ${FILES}
                fi
                TARFILE="${LOCATION}"
                echo "${FILE:1}" > ${FILES}
            else
                echo "${FILE:1}" >> ${FILES}
            fi
        fi
    done
    if [[ -n "${TARFILE}" ]] ; then
        tar -xf "${MIXTAPE_DIR}/data/${TARFILE}" -T "${FILES}"
    fi
    rm -rf ${TMP_DIR}
}

# Restores file metadata (user, group, permissions) from a backup
restore_meta() {
    local DIR="$1" DST
    local INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION
    while IFS=$'\t' read INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION ; do
        DST="${DIR}/${FILE:1}"
        if [[ -e "${DST}" ]] ; then
            chmod "$(file_access_octal ${ACCESS})" "${DST}"
            chown "${USER}:${GROUP}" "${DST}"
            touch --no-dereference --date="${DATETIME}" "${DST}"
        fi
    done
}

# Program start
main() {
    local INDEX FILEGLOB INDEX_FILE DIR
    checkopts
    [[ ${#ARGS[@]} -eq 2 ]] || usage "incorrect number of arguments"
    INDEX="${ARGS[0]}"
    FILEGLOB="${ARGS[1]}"
    INDEX_FILE=($(index_list "${MIXTAPE_DIR}" "${INDEX}"))
    if [[ ${#INDEX_FILE[@]} -eq 0 ]] ; then
        die "no such index found: ${INDEX}"
    elif [[ ${#INDEX_FILE[@]} -gt 1 ]] ; then
        die "multiple matching indexes found: ${INDEX}"
    fi
    if [[ "${FILEGLOB:0:1}" != "/" ]] ; then
        FILEGLOB="/${FILEGLOB}"
    fi
    DIR=${MIXTAPE_DIR}/restore-$(index_datetime ${INDEX_FILE} file)
    echo -n "${COLOR_WARN}"
    echo "Restoring ${FILEGLOB}"
    echo "     from ${INDEX_FILE}"
    echo "       to ${DIR}${COLOR_RESET}"
    index_content "${INDEX_FILE}" "${FILEGLOB}" | \
        sort --field-separator=$'\t' --key=9,9 --key=7,7 | \
        restore_files "${DIR}"
    index_content "${INDEX_FILE}" "${FILEGLOB}" | \
        sort --field-separator=$'\t' --key=7,7r | \
        restore_meta "${DIR}"
}

main
