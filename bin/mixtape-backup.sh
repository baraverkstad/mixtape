#!/usr/bin/env bash
#
# Stores copies of files in a backup.
#
# Syntax: mixtape-backup [<path> ...]
#
# Arguments:
#   <path>           A file or directory to backup (recursively). Required
#                    for the first backup. Subsequent runs will reuse the same
#                    paths as the first. Specific file names or subdirs may be
#                    excluded by prefixing with a '-' char.
#

# Import common functions
SCRIPT=$(readlink "$0" || echo -n "$0")
LIBRARY=$(dirname "${SCRIPT}")/mixtape-common.sh
source "${LIBRARY}" || exit 1

# Prints the default backup configuration
config_default() {
    echo "# Configuration of backup includes and excludes."
    echo "#"
    echo "# /dir             includes '/dir' into backup"
    echo "# - /dir/subdir    excludes '/dir/subdir' from backup"
    echo "# - name           excludes all 'name' files and dirs"
    echo
    echo "- .git"
    echo "- .hg"
    echo "- .svn"
}

# Adds a pattern to the backup configuration (created if needed)
config_add() {
    local PATTERN=$1
    mkdir -p "${MIXTAPE_DIR}"
    if [[ ! -f "${MIXTAPE_DIR}/config" ]] ; then
        config_default > "${MIXTAPE_DIR}/config"
    fi
    if [[ "${PATTERN}" == "-"* ]] ; then
        printf -- "- %s\n" "$(trim "${PATTERN:1}")" >> "${MIXTAPE_DIR}/config"
    elif [[ "${PATTERN}" == "+"* ]] ; then
        realpath -ms "${PATTERN:1}" >> "${MIXTAPE_DIR}/config"
    elif [[ -n "${PATTERN}" ]] ; then
        realpath -ms "${PATTERN}" >> "${MIXTAPE_DIR}/config"
    fi
}

# Prints an index-like list of all source files to backup
source_files_list() {
    local INCLUDE EXCLUDE IGNORE LINE
    INCLUDE=$(tmpfile_create src-filelist-include.txt)
    EXCLUDE=$(tmpfile_create src-filelist-exclude.txt)
    IGNORE=$(tmpfile_create src-filelist-ignore.txt)
    touch "${INCLUDE}" "${EXCLUDE}" "${IGNORE}"
    while IFS= read -r LINE ; do
        [[ "${LINE}" != "" && "${LINE:0:1}" != "#" ]] || continue
        if [[ "${LINE}" == "-"*/* ]] ; then
            printf "%s\n" "$(trim "${LINE:1}")" >> "${EXCLUDE}"
        elif [[ "${LINE}" == "-"* ]] ; then
            printf "%s\n" "$(trim "${LINE:1}")" >> "${IGNORE}"
        elif [[ "${LINE}" == "+"* ]] ; then
            printf "%s\n" "$(trim "${LINE:1}")" >> "${INCLUDE}"
        else
            printf "%s\n" "$(trim "${LINE}")" >> "${INCLUDE}"
        fi
    done < "${MIXTAPE_DIR}/config"
    if [[ ! -s ${INCLUDE} ]] ; then
        die "no files included in backup"
    fi
    # shellcheck disable=SC2046
    find $(< "${INCLUDE}") \
         $(xargs -L 1 printf '-not ( -path %s -prune ) ' < "${EXCLUDE}") \
         $(xargs -L 1 printf '-not ( -name %s -prune ) ' < "${IGNORE}") \
         -printf '%M\t%u\t%g\t%TF %.8TT\t%k\t%p\t->\t%l\n' | \
         sort --field-separator=$'\t' --key=6,6
}

# Prints the shasum-matching locations from an index
source_index_locations() {
    local INDEX=$1 CONTENT SHASUMS VERIFIED
    CONTENT=$(tmpfile_create src-index-content.txt)
    SHASUMS=$(tmpfile_create src-index-shasums.txt)
    VERIFIED=$(tmpfile_create src-index-verified.txt)
    xzcat "${INDEX}" | grep ^- > "${CONTENT}"
    awk -F $'\t' '{print $7 "  " $6}' < "${CONTENT}" > "${SHASUMS}"
    (sha256sum --check "${SHASUMS}" | grep 'OK$' | cut -d ':' -f 1) 2> /dev/null || true > "${VERIFIED}"
    join -t $'\t' -1 6 -2 1 -o $'1.6\t1.7\t1.8' "${CONTENT}" "${VERIFIED}"
    # TODO: Remove legacy sha1 -> sha256 conversion
    (sha1sum --check "${SHASUMS}" | grep 'OK$' | cut -d ':' -f 1) 2> /dev/null || true > "${VERIFIED}"
    if [[ -s "${VERIFIED}" ]] ; then
        SHASUMS=$(tmpfile_create src-sha256-sums.txt)
        xargs -L 100 sha256sum < "${VERIFIED}" > "${SHASUMS}"
        VERIFIED=$(tmpfile_create src-sha256-store.txt)
        while read -r SHA FILE ; do
            printf "%s\t%s\n" "${FILE}" "${SHA}"
        done < "${SHASUMS}" > "${VERIFIED}"
        join -t $'\t' -1 6 -2 1 -o $'1.6\t2.2\t1.8' "${CONTENT}" "${VERIFIED}"
    fi
}

# Prints an index-like list of all source files to backup
source_files() {
    local INDEX FILELIST UNSORTED SORTED
    INDEX=$(index_files "${MIXTAPE_DIR}" last)
    if [[ -e "${INDEX}" ]] ; then
        FILELIST=$(tmpfile_create src-filelist.txt)
        UNSORTED=$(tmpfile_create src-store-unsorted.txt)
        SORTED=$(tmpfile_create src-store-sorted.txt)
        source_files_list > "${FILELIST}"
        source_index_locations "${INDEX}" > "${UNSORTED}"
        grep ^l "${FILELIST}" | awk -F $'\t' '{print $6 "\t->\t" $8}' >> "${UNSORTED}"
        sort --field-separator=$'\t' --key=1,1 "${UNSORTED}" > "${SORTED}"
        join -t $'\t' -a 1 -1 6 -2 1 -o $'1.1\t1.2\t1.3\t1.4\t1.5\t1.6\t2.2\t2.3' \
             "${FILELIST}" "${SORTED}"
    else
        source_files_list
    fi
}

# Store small files
store_small_files() {
    local DATETIME=$1 FILES=$2 SHASUMS TARFILE SHA FILE
    SHASUMS=$(tmpfile_create store-shasums.txt)
    TARFILE=${MIXTAPE_DIR}/data/files/${DATETIME:0:7}/files.${DATETIME}.tar.xz
    mkdir -p "$(dirname "${TARFILE}")"
    echo "Storing $(wc -l < "${FILES}") smaller files..." >&2
    tar -caf "${TARFILE}" -T "${FILES}" 2> /dev/null
    xargs -L 100 sha256sum < "${FILES}" > "${SHASUMS}"
    while read -r SHA FILE ; do
        printf "%s\t%s\t%s\n" "${FILE}" "${SHA}" "${TARFILE#${MIXTAPE_DIR}/data/}"
    done < "${SHASUMS}"
}

# Store large files
store_large_files() {
    local FILES=$1 INFILE OUTFILE SHA
    while IFS= read -r INFILE ; do
        echo "Storing ${INFILE}..." >&2
        SHA=$(file_sha256 "${INFILE}")
        OUTFILE=$(largefile_store "${MIXTAPE_DIR}" "${INFILE}" "${SHA}")
        printf "%s\t%s\t%s\n" "${INFILE}" "${SHA}" "${OUTFILE#${MIXTAPE_DIR}/data/}"
    done < "${FILES}"
}

# Adds files without storage location, but outputs all file locations
store_files() {
    local DATETIME=$1 SOURCE_FILES=$2 SMALL LARGE ACCESS SIZEKB FILE SHA LOCATION
    SMALL=$(tmpfile_create store-small.txt)
    LARGE=$(tmpfile_create store-large.txt)
    while IFS=$'\t' read ACCESS _ _ _ SIZEKB FILE SHA LOCATION ; do
        if [[ ${ACCESS:0:1} == "-" ]] ; then
            if [[ "${LOCATION}" != "" ]] ; then
                printf "%s\t%s\t%s\n" "${FILE}" "${SHA}" "${LOCATION}"
            elif [[ ${SIZEKB} -lt 256 ]] ; then
                echo "${FILE}" >> "${SMALL}"
            else
                echo "${FILE}" >> "${LARGE}"
            fi
        elif [[ ${ACCESS:0:1} == "l" ]] ; then
            printf "%s\t->\t%s\n" "${FILE}" "${LOCATION}"
        fi
    done < "${SOURCE_FILES}"
    if [[ -s "${SMALL}" ]] ; then
        store_small_files "${DATETIME}" "${SMALL}"
    fi
    if [[ -s "${LARGE}" ]] ; then
        store_large_files "${LARGE}"
    fi
}

# Creates the output index
create_index() {
    local DATETIME=$1 SOURCE_FILES=$2 LOCATIONS=$3 INDEX SORTED
    mkdir -p "${MIXTAPE_DIR}/index"
    INDEX="${MIXTAPE_DIR}/index/index.${DATETIME}.txt"
    SORTED=$(tmpfile_create store-sorted.txt)
    sort --field-separator=$'\t' --key=1,1 "${LOCATIONS}" > "${SORTED}"
    join -t $'\t' -a 1 -1 6 -2 1 -o $'1.1\t1.2\t1.3\t1.4\t1.5\t1.6\t2.2\t2.3' \
         "${SOURCE_FILES}" "${SORTED}" > "${INDEX}"
    xz "${INDEX}"
}

# Program start
main() {
    local ARG DATETIME SOURCE_FILES LOCATIONS
    checkopts
    if [[ ${#ARGS[@]} -gt 0 ]] ; then
        for ARG in "${ARGS[@]}" ; do
            config_add "${ARG}"
        done
    elif [[ ! -f "${MIXTAPE_DIR}/config" && -f /etc/mixtape-backup.conf ]] ; then
        # TODO: Remove this legacy config copying
        while IFS= read -r LINE ; do
            [[ "${LINE}" != "" && "${LINE:0:1}" != "#" ]] || continue
            config_add "${LINE}"
        done < /etc/mixtape-backup.conf
    fi
    [[ -f "${MIXTAPE_DIR}/config" ]] || usage "no backup files selected"
    DATETIME=$(index_datetime now file)
    SOURCE_FILES=$(tmpfile_create src-files.txt)
    LOCATIONS=$(tmpfile_create store-unsorted.txt)
    source_files > "${SOURCE_FILES}"
    store_files "${DATETIME}" "${SOURCE_FILES}" > "${LOCATIONS}"
    create_index "${DATETIME}" "${SOURCE_FILES}" "${LOCATIONS}"
}

# Install cleanup handler, parse command-line and launch
trap tmpfile_cleanup EXIT
parseargs "$@"
main
