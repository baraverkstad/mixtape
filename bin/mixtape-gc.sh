#!/usr/bin/env bash
#
# Removes older indexes and non-referenced storage files.
#
# Syntax: mixtape-gc [--delete-expired] [--keep-<interval>=#]
#
# Options:
#   --delete-expired  Deletes any index not in one of the retention categories
#                     (i.e. yearly, monthly, etc). Each category selects the
#                     oldest index in each available time interval (i.e. one
#                     per year, month, etc), but marks only the N most recent
#                     of these indexes for keeping. All categories have a pre-
#                     defined number of indexes to keep (see below). Set to
#                     zero to ignore all indexes in a category.
#   --keep-yearly=#   Number of yearly indexes to keep, defaults to 10
#   --keep-monthly=#  Number of monthly indexes to keep, defaults to 18
#   --keep-weekly=#   Number of weekly indexes to keep, defaults to 10
#   --keep-daily=#    Number of daily indexes to keep, defaults to 14
#   --keep-latest=#   Number of recent indexes to keep, defaults to 5
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

# Index expiry schedule (latest, yearly, monthly, weekly, daily)
SCHEDULE=(5 10 18 10 14)

# Prints index category date values
index_category_dates() {
    local FILE="$1" DTTM Y M W D
    DTTM=$(index_datetime "${FILE}")
    Y=${DTTM:0:4}
    M="${Y}${DTTM:5:2}"
    W="$(date --date="${DTTM}" +"%G%V" | tr -d "\n")"
    D="${M}${DTTM:8:2}"
    printf "%s %s %s %s %s %s\n" "${FILE}" "${Y}" "${M}" "${W}" "${D}"
}

# Prints all index files, one per line
index_all() {
    local INDEX_FILE
    for INDEX_FILE in $(index_files "${MIXTAPE_DIR}" all) ; do
        printf "%s\n" "${INDEX_FILE}"
    done
}

# Prints all index files to keep
index_keep() {
    local INDEX_FILE IX TMPFILE NEW OLD
    TMPFILE=()
    for IX in "${!SCHEDULE[@]}" ; do
        TMPFILE+=($(tmpfile_create "index-policy-${IX}.txt"))
    done
    OLD=(d u m m y)
    for INDEX_FILE in $(index_files "${MIXTAPE_DIR}" all) ; do
        NEW=($(index_category_dates "${INDEX_FILE}"))
        for IX in "${!SCHEDULE[@]}" ; do
            [[ "${NEW[${IX}]}" == "${OLD[${IX}]}" ]] || printf "%s\n" "${NEW[0]}" >> "${TMPFILE[${IX}]}"
        done
        OLD=("${NEW[@]}")
    done
    for IX in "${!SCHEDULE[@]}" ; do
        tail -n "${SCHEDULE[${IX}]}" "${TMPFILE[${IX}]}"
    done | sort | uniq
}

# Prints all expired index files
index_expired() {
    ALL=$(tmpfile_create index-all.txt)
    KEEP=$(tmpfile_create index-keep.txt)
    index_all > "${ALL}"
    index_keep > "${KEEP}"
    diff --new-line-format="" --unchanged-line-format="" "${ALL}" "${KEEP}" || true
}

# Runs the index expiry check and/or removal
index_check() {
    local DELETE=$1 FILES INDEX
    info "${COLOR_WARN}[1/2]${COLOR_RESET} Checking for expired indexes"
    FILES=$(tmpfile_create index-expired.txt)
    index_expired > "${FILES}"
    for INDEX in $(< "${FILES}") ; do
        debug "expired index: ${INDEX#${MIXTAPE_DIR}/index/}"
        (${DELETE} && rm "${INDEX}") || true
    done
    if ${DELETE} ; then
        info "    - Removed $(wc -l < "${FILES}") expired indexes"
    else
        info "    - Found $(wc -l < "${FILES}") expired indexes (remove with --delete-expired)"
    fi
}

# Runs the storage check and removal
store_check() {
    local FILES LOCATIONS UNREF MISREF FILE
    info "${COLOR_WARN}[2/2]${COLOR_RESET} Checking storage for unreferenced files"
    FILES=$(tmpfile_create store-files.txt)
    LOCATIONS=$(tmpfile_create store-locations.txt)
    find "${MIXTAPE_DIR}/data" -type f -printf "%P\n" | sort > "${FILES}"
    xzgrep ^- "${MIXTAPE_DIR}"/index/*.xz | cut -f 8 | sort | uniq > "${LOCATIONS}"
    UNREF=$(tmpfile_create store-unref.txt)
    MISREF=$(tmpfile_create store-misref.txt)
    diff --new-line-format="" --unchanged-line-format="" "${FILES}" "${LOCATIONS}" > "${UNREF}" || true
    diff --new-line-format="" --unchanged-line-format="" "${LOCATIONS}" "${FILES}" > "${MISREF}" || true
    for FILE in $(< "${UNREF}") ; do
        debug "unreferenced file: ${FILE}"
        rm "${MIXTAPE_DIR}/data/${FILE}"
    done
    info "    - Removed $(wc -l < "${UNREF}") file(s) from storage"
    for FILE in $(< "${MISREF}") ; do
        warn "indexed location not found: ${FILE}"
    done
}

# Program start
main() {
    local DELETE=false
    checkopts --delete-expired --keep-yearly= --keep-monthly= --keep-weekly= \
              --keep-daily= --keep-latest=
    if parseopt --delete-expired ; then
        DELETE=true
    fi
    SCHEDULE[0]=$(parseopt "--keep-latest=${SCHEDULE[0]}")
    SCHEDULE[1]=$(parseopt "--keep-yearly=${SCHEDULE[1]}")
    SCHEDULE[2]=$(parseopt "--keep-monthly=${SCHEDULE[2]}")
    SCHEDULE[3]=$(parseopt "--keep-weekly=${SCHEDULE[3]}")
    SCHEDULE[4]=$(parseopt "--keep-daily=${SCHEDULE[4]}")
    [[ ${#ARGS[@]} -le 0 ]] || usage "too many arguments"
    info "${COLOR_WARN}Dir:${COLOR_RESET}  ${MIXTAPE_DIR}"
    index_check ${DELETE}
    store_check
}

# Install cleanup handler, parse command-line and launch
trap tmpfile_cleanup EXIT
parseargs "$@"
main
