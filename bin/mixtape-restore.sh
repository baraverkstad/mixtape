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
# Options:
#   --debug           Enables more output (verbose mode)
#   --quiet           Disables normal output (quiet mode)
#   --backup-dir=...  Use other root backup dir, instead of /backup
#   --mixtape-dir=... Use other mixtape dir, instead of /backup/<host>/mixtape
#   --help            Prints help information (and quits)
#   --version         Prints version information (and quits)
#

# Import common functions
SCRIPT=$(readlink "$0" || echo -n "$0")
LIBRARY=$(dirname "${SCRIPT}")/mixtape-common.sh
source "${LIBRARY}" || exit 1

# Restores files from a backup (listed in tar file order)
restore_files() {
    local DIR="$1" TARFILE="" FILES ACCESS FILE LOCATION
    mkdir -p "${DIR}"
    cd "${DIR}" || die "couldn't create ${DIR}"
    FILES=$(tmpfile_create files.txt)
    while IFS=$'\t' read -r _ ACCESS _ _ _ _ FILE _ LOCATION ; do
        if [[ ${ACCESS:0:1} == "d" && ! -e "${FILE:1}" ]] ; then
            mkdir -p "${FILE:1}"
        elif [[ ${ACCESS:0:1} == "l" ]] ; then
            debug "restoring link: ${FILE}"
            ln -s "${LOCATION}" "${FILE:1}"
        elif [[ ${ACCESS:0:1} == "-" ]] ; then
            if [[ ${LOCATION:0:6} != "files/" ]] ; then
                debug "restoring large file: ${FILE}"
                largefile_restore "${MIXTAPE_DIR}/data/${LOCATION}" "${FILE:1}"
            elif [[ "${TARFILE}" != "${LOCATION}" ]] ; then
                if [[ -n "${TARFILE}" ]] ; then
                    debug "restoring from archive: ${TARFILE}"
                    tar -xf "${MIXTAPE_DIR}/data/${TARFILE}" -T "${FILES}"
                fi
                TARFILE="${LOCATION}"
                echo "${FILE:1}" > "${FILES}"
            else
                echo "${FILE:1}" >> "${FILES}"
            fi
        fi
    done
    if [[ -n "${TARFILE}" ]] ; then
        debug "restoring from archive: ${TARFILE}"
        tar -xf "${MIXTAPE_DIR}/data/${TARFILE}" -T "${FILES}"
    fi
}

# Restores file metadata (user, group, permissions) from a backup
restore_meta() {
    local DIR="$1" DST ACCESS USER GROUP DATETIME FILE
    while IFS=$'\t' read -r _ ACCESS USER GROUP DATETIME _ FILE _ _ ; do
        DST="${DIR}/${FILE:1}"
        if [[ -e "${DST}" ]] ; then
            debug "restoring metadata: ${FILE}"
            chmod "$(file_access_octal "${ACCESS}")" "${DST}"
            chown "${USER}:${GROUP}" "${DST}"
            touch --no-dereference --date="${DATETIME}" "${DST}"
        fi
    done
}

# Program start
main() {
    local INDEX FILEGLOB ARR INDEX_FILE DIR
    checkopts --
    [[ ${#ARGS[@]} -eq 2 ]] || usage "incorrect number of arguments"
    INDEX="${ARGS[0]}"
    FILEGLOB="${ARGS[1]}"
    ARR=($(index_files "${MIXTAPE_DIR}" "${INDEX}"))
    if [[ ${#ARR[@]} -eq 0 ]] ; then
        die "no such index found: ${INDEX}"
    elif [[ ${#ARR[@]} -gt 1 ]] ; then
        die "multiple matching indexes found: ${INDEX}"
    fi
    if [[ "${FILEGLOB:0:1}" != "/" ]] ; then
        FILEGLOB="/${FILEGLOB}"
    fi
    INDEX_FILE=${ARR[0]}
    DIR=${MIXTAPE_DIR}/restore-$(index_datetime "${INDEX_FILE}" file)
    info "${COLOR_WARN}Backup dir:${COLOR_RESET}    ${MIXTAPE_DIR}"
    info "${COLOR_WARN}Source index:${COLOR_RESET}  ${INDEX_FILE}"
    info "${COLOR_WARN}Restore dir:${COLOR_RESET}   ${DIR}"
    info "${COLOR_WARN}File path:${COLOR_RESET}     ${FILEGLOB}"
    index_content "${MIXTAPE_DIR}" "${INDEX_FILE}" "${FILEGLOB}" | \
        sort --field-separator=$'\t' --key=9,9 --key=7,7 | \
        restore_files "${DIR}"
    index_content "${MIXTAPE_DIR}" "${INDEX_FILE}" "${FILEGLOB}" | \
        sort --field-separator=$'\t' --key=7,7r | \
        restore_meta "${DIR}"
}

# Install cleanup handler, parse command-line and launch
trap tmpfile_cleanup EXIT
parseargs "$@"
main
