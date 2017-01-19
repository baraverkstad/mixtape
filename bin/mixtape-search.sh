#!/usr/bin/env bash
#
# Searches for matching files in the backup.
#
# Syntax: mixtape-search [<options>] <file>
#
# Arguments:
#   <file>           A file name or path search pattern with optional glob
#                    matching (e.g. "/etc/**/*.sh). Avoid shell expansion of
#                    the pattern by using quotes (i.e. "pattern"). A pattern
#                    starting with "/" will match from the beginning of the
#                    file path (i.e. an absolute file path).
#
# Options:
#   --first          Prints meta-data from the first backup of each version of
#                    the files matched (this is the default).
#   --last           Prints meta-data from the last backup of each version of
#                    the files matched.
#   --all            Prints meta-data from all backups of the files matched.
#

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-common.sh
source ${LIBRARY} || exit 1

# Reads sorted index entries from stdin and prints them (grouped by file)
index_print() {
    local CURRENT="" CURRENT_SHA SIZEMB EXTRA
    local INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION
    while IFS=$'\t' read INDEX ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION ; do
        if [[ "${CURRENT}" != "${FILE}" ]] ; then
            [[ -z ${CURRENT} ]] || echo
            CURRENT=${FILE}
            CURRENT_SHA=$(shasum ${FILE} 2>/dev/null | cut -d ' ' -f 1 || true)
            echo -n "${COLOR_WARN}${FILE}"
            if [[ ! -e ${FILE} ]] ; then
                echo -n " ${COLOR_ERR}[deleted]"
            elif [[ ${ACCESS:0:1} == "-" && ${CURRENT_SHA} != ${SHA} ]] ; then
                echo -n " ${COLOR_ERR}[modified]"
            fi
            echo "${COLOR_RESET}"
        fi
        if [[ -z ${SHA} ]] ; then
            EXTRA=""
        elif [[ ${SHA} = "->" ]] ; then
            EXTRA="-> ${LOCATION}"
        elif [[ ${SIZEKB} -gt 1024 ]] ; then
            SIZEMB=$(echo ${SIZEKB} | awk '{printf "%.1f",$1/1024}')
            EXTRA="${SIZEMB}M  ${SHA}"
        else
            EXTRA="${SIZEKB}K  ${SHA}"
        fi
        printf "%s: %s  %s %s  %s  %s\n" ${INDEX} ${ACCESS} ${USER} ${GROUP} "${DATETIME}" "${EXTRA}"
    done
}

# Program start
main() {
    local FILTER="uniq -f 6" SORTKEY="1,1" FILEGLOB
    checkopts --first --last --all
    if parseopt --last ; then
        SORTKEY="1,1r"
    fi
    if parseopt --all ; then
        FILTER="cat"
    fi
    [[ ${#ARGS[@]} -eq 1 ]] || usage
    FILEGLOB="${ARGS[0]}"
    index_all_content "${MIXTAPE_DIR}" "${FILEGLOB}" | \
        sort --field-separator=$'\t' --key=7,7 --key=${SORTKEY} | \
        ${FILTER} | \
        sort --field-separator=$'\t' --key=7,7 --key=1,1r | \
        index_print
}

main
