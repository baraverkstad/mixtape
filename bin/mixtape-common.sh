#!/usr/bin/env bash
#
# Common variables and functions used by other scripts
#

# Set caution flags
set -o nounset
set -o errtrace
set -o errexit
set -o pipefail

# Program & version variables
PROGRAM=$0
PROGRAM_NAME=${PROGRAM%.sh}
PROGRAM_ID=${PROGRAM_NAME}[$$]
VERSION=0.3

# Command-line parsing result variables
ARGS=()
OPTS=()
VERBOSE=false

# Directory variables
DEFAULT_BACKUP_DIR=/backup
DEFAULT_MIXTAPE_DIR=${DEFAULT_BACKUP_DIR}/$(hostname)/mixtape
BACKUP_DIR=${DEFAULT_BACKUP_DIR}
MIXTAPE_DIR=${DEFAULT_MIXTAPE_DIR}
TMP_DIR=/tmp/mixtape-$$

# Color variables
if [[ -t 0 ]]; then
    COLOR_OK=$(tput setaf 2)
    COLOR_WARN=$(tput setaf 3)
    COLOR_ERR=$(tput setaf 1; tput bold)
    COLOR_RESET=$(tput sgr0)
else
    COLOR_OK=""
    COLOR_WARN=""
    COLOR_ERR=""
    COLOR_RESET=""
fi

# Logs an error and exits (code 1)
die() {
    error "$@"
    exit 1
}

# Logs an error to stderr and syslog
error() {
    echo "${COLOR_ERR}ERROR:${COLOR_RESET}" "$@" >&2
    logger -p local0.error -t "${PROGRAM_ID}" -- "$@" || true
}

# Logs a warning to stderr and syslog
warn() {
    echo "${COLOR_WARN}WARNING:${COLOR_RESET}" "$@" >&2
    logger -p local0.warning -t "${PROGRAM_ID}" -- "$@" || true
}

# Logs a message to stdout and syslog (if VERBOSE is true)
log() {
    ${VERBOSE} && echo $(date +"%F %T"): "$@" || true
    ${VERBOSE} && logger -p local0.info -t "${PROGRAM_ID}" -- "$@" || true
}

# Prints command-line usage info and exits
usage() {
    local ERROR="$@" LINE
    while read LINE ; do
        if [[ ${LINE:0:1} = "#" ]] ; then
            echo "${LINE:2}" >&2
        else
            break
        fi
    done < <(tail -n +3 $PROGRAM)
    if [[ ! -z "${ERROR}" ]] ; then
        [[ -z "${LINE:2}" ]] || echo >&2
        error "${ERROR}"
    fi
    exit 1
}

# Prints program name and version, then exits
versioninfo() {
    echo "${PROGRAM_NAME}, version ${VERSION}"
    exit 1
}

# Parse command-line arguments to ARGS and OPTS vars
parseargs() {
    while [[ $# -gt 0 ]] ; do
        case "$1" in
        -\?|-h|--help)
            usage
            ;;
        --version)
            versioninfo
            ;;
        --backup-dir=*)
            BACKUP_DIR=$(realpath ${1#*=} 2>/dev/null)
            MIXTAPE_DIR=${BACKUP_DIR}/$(hostname)/mixtape
            if [[ ! -e ${BACKUP_DIR} ]] ; then
                die "backup dir doesn't exist: ${1#*=}"
            elif [[ ! -d ${BACKUP_DIR} ]] ; then
                die "backup dir isn't a directory: ${BACKUP_DIR}"
            elif [[ ${BACKUP_DIR} == "/" ]] ; then
                die "backup dir cannot be /"
            fi
            ;;
        --mixtape-dir=*)
            MIXTAPE_DIR=$(realpath ${1#*=} 2>/dev/null)
            if [[ ! -e ${MIXTAPE_DIR} ]] ; then
                die "mixtape dir doesn't exist: ${1#*=}"
            elif [[ ! -d ${MIXTAPE_DIR} ]] ; then
                die "mixtape dir isn't a directory: ${MIXTAPE_DIR}"
            elif [[ ${MIXTAPE_DIR} == "/" ]] ; then
                die "mixtape dir cannot be /"
            fi
            ;;
        --)
            shift
            ARGS+=("$@")
            break
            ;;
        -*)
            OPTS+=("$1")
            ;;
        *)
            ARGS+=("$1")
            ;;
        esac
        shift
    done
}

# Checks OPTS content against the function arguments
checkopts() {
    local OPTIONS=" $* " OPT MATCH MISMATCH
    for OPT in ${OPTS+"${OPTS[@]}"} ; do
        if [[ "${OPT}" == *=* ]] ; then
            MATCH=" ${OPT%%=*}="
            MISMATCH=" ${OPT%%=*} "
        else
            MATCH=" ${OPT} "
            MISMATCH=" ${OPT}="
        fi
        if [[ ${OPTIONS} == *${MISMATCH}* ]] ; then
            usage "option value incorrect: ${OPT}"
        elif [[ ${OPTIONS} != *${MATCH}* ]] ; then
            usage "unknown option: ${OPT}"
        fi
    done
}

# Reads an option from OPTS, or returns a default value
parseopt() {
    local DEF=$1 OPT NAME MATCH
    for OPT in ${OPTS+"${OPTS[@]}"} ; do
        if [[ "${OPT}" == *=* ]] ; then
            NAME="${OPT%%=*}"
            if [[ ${DEF} == ${NAME}=* ]] ; then
                echo -n "${OPT#*=}"
                return 0
            elif [[ ${DEF} == ${NAME} ]] ; then
                usage "option cannot have value: ${OPT}"
            fi
        else
            if [[ ${DEF} == ${OPT} ]] ; then
                return 0
            elif [[ ${DEF} == ${OPT}=* ]] ; then
                usage "option requires value: ${OPT}"
            fi
        fi
    done
    if [[ "${DEF}" == *=* ]] ; then
        echo -n "${DEF#*=}"
        return 0
    else
        return 1
    fi
}

# Checks if a directory looks like a valid backup dir
is_mixtape_dir() {
    local DIR=$1
    if [[ -d ${DIR} && -d ${DIR}/index || -d ${DIR}/data ]] ; then
        return 0 # true
    else
        return 1 # false
    fi
}

# Prints a datetime of an index file or id (in optional format)
index_datetime() {
    local INDEX=${1:-now} FORMAT=${2:-iso} DATETIME
    if [[ -z "${FORMAT}" || "${FORMAT}" == "iso" ]] ; then
        FORMAT="%Y-%m-%d %H:%M"
    elif [[ "${FORMAT}" == "file" ]] ; then
        FORMAT="%Y-%m-%d-%H%M"
    fi
    case "${INDEX}" in
    *index.????-??-??-????.txt.xz)
        DATETIME=${INDEX##*index.}
        DATETIME="${DATETIME:0:10} ${DATETIME:11:2}:${DATETIME:13:2}"
        ;;
    @*)
        DATETIME="@$((16#${INDEX:1}))"
        ;;
    *)
        DATETIME="${INDEX}"
        ;;
    esac
    echo -n $(date --date="${DATETIME}" +"${FORMAT}")
}

# Prints hex epoch of an index file
index_epoch() {
    local INDEX=${1:-now} DATETIME
    case "${INDEX}" in
    *index.????-??-??-????.txt.xz)
        DATETIME=$(index_datetime ${INDEX})
        ;;
    *)
        DATETIME="${INDEX}"
        ;;
    esac
    printf "@%x" $(date --date="${DATETIME}" +"%s")
}

# Finds (existing) index files for a backup dir and index id/glob/etc
index_files() {
    local DIR="$1" INDEX="${2:-}" GLOB="" FILES POS
    if [[ ${INDEX:0:1} = "@" ]] ; then
        GLOB=$(index_datetime ${INDEX} file)
    elif [[ ${INDEX} = "all" || ${INDEX} = "*" ]] ; then
        GLOB="*"
    elif [[ ${INDEX} = "first" ]] ; then
        GLOB="*"
        POS=0
    elif [[ ${INDEX} = "last" ]] ; then
        GLOB="*"
        POS=-1
    elif [[ "${INDEX}" == index.*.txt.xz ]] ; then
        FILES=(${DIR}/index/${INDEX})
    elif [[ "${INDEX}" == */index.*.txt.xz ]] ; then
        FILES=(${INDEX})
    elif [[ -n ${INDEX} ]] ; then
        GLOB=$(echo -n \*${INDEX}\* | tr ' ' '-' | tr -d ':')
    else
        GLOB="*"
    fi
    if [[ -n "${GLOB}" ]] ; then
        FILES=(${DIR}/index/index.${GLOB}.txt.xz)
    fi
    if [[ -z ${POS:-} && -e ${FILES[0]} ]] ; then
        echo -n ${FILES[@]}
    elif [[ -n ${POS:-} && -e ${FILES[${POS}]} ]] ; then
        echo -n ${FILES[${POS}]}
    fi
}

# Prints contents of one of more indices (optionally filtered by a file glob)
index_content() {
    local DIR="$1" INDEX="$2" GLOB="${3:-}" PREFIX FILTER="cat" REGEX
    if [[ -n "${GLOB}" ]] ; then
        REGEX=$(index_content_regex "${GLOB}")
        FILTER="grep -i -P ${REGEX}"
    fi
    for INDEX_FILE in $(index_files "${DIR}" "${INDEX}") ; do
        PREFIX=$(index_epoch ${INDEX_FILE})$'\t'
        xzcat ${INDEX_FILE} | ${FILTER} | awk -v prefix="${PREFIX}" '$0 = prefix$0' || true
    done
}

# Converts a file glob pattern to a regex for matching index content
index_content_regex() {
    local GLOB="${1:-}" RE=('\t') ANY='[^\t]' DOT='[^/\t]' HASANY=false POS CHR
    if [[ "${GLOB:0:1}" != "/" ]] ; then
        RE+=("/" "${ANY}*")
        HASANY=true
    fi
    for POS in $(seq 1 ${#GLOB}) ; do
        CHR="${GLOB:POS-1:1}"
        if [[ "${GLOB:POS-1:2}" == "**" ]] ; then
            RE+=("${ANY}*")
            HASANY=true
        elif [[ "${CHR}" == "*" ]] ; then
            if ! ${HASANY} ; then
                RE+=("${DOT}*")
            fi
        elif [[ "${CHR}" == "?" ]] ; then
            RE+=("${DOT}")
            HASANY=false
        else
            if [[ '.+[]{}' == *"${CHR}"* ]] ; then
                RE+=("\\")
            fi
            RE+=("${CHR}")
            HASANY=false
        fi
    done
    while [[ "${RE[-1]}" == "${ANY}*" || "${RE[-1]}" == "${DOT}*"  ]] ; do
        unset 'RE[-1]'
    done
    (IFS=; echo -n "${RE[*]}")
}

# Prints file bits as the corresponding octal code
file_access_octal() {
    local ACCESS=$1 PERM="0" POS SUBSTR DIGIT
    for POS in $(seq 1 3 7) ; do
        DIGIT=0
        SUBSTR="${ACCESS:POS:3}"
        if [[ "${SUBSTR}" == r?? ]] ; then
            ((DIGIT+=4))
        fi
        if [[ "${SUBSTR}" == ?w? ]] ; then
            ((DIGIT+=2))
        fi
        if [[ "${SUBSTR}" == ??x ]] ; then
            ((DIGIT+=1))
        fi
        PERM+="${DIGIT}"
    done
    echo -n "${PERM}"
}

# Searches for a file by SHA in the large file store
largefile_search_sha() {
    local DIR=$1 SHA=$2 FILE FILESHA SUBSTR
    SUBSTR=" ${SHA} "
    for FILE in ${DIR}/data/${SHA:0:3}/${SHA:3:3}/* ; do
        if [[ -e ${FILE} ]] ; then
            FILESHA=" $(shasum ${FILE} | cut -d ' ' -f 1) "
            if [[ ${FILE} == *.xz ]] ; then
                FILESHA+="$(xzcat ${FILE} | shasum | cut -d ' ' -f 1) "
            fi
            if [[ ${FILESHA} == *"${SUBSTR}"* ]] ; then
                echo -n "${FILE}"
                break
            fi
        fi
    done
}

# Stores a file into the large file store (if not already present)
largefile_store() {
    local DIR=$1 FILE=$2 SHA=${3:-} OUTFILE
    if [[ -z "${SHA}" ]] ; then
        SHA=$(shasum ${FILE} | cut -d ' ' -f 1)
    fi
    OUTFILE=$(largefile_search_sha "${DIR}" "${SHA}")
    if [[ ! -e "${OUTFILE}" ]] ; then
        OUTFILE=${DIR}/data/${SHA:0:3}/${SHA:3:3}/${FILE##*/}
        mkdir -p "${OUTFILE%/*}"
        case "${FILE}" in
        *.7z | *.bz2 | *.gz | *.?ar | *.lz* | *.lha | *.tgz | *.xz | *.z | *.zip | *.zoo | \
        *.dmg | *.gif | *.jpg | *.mp4 | *.web* | *.wmv )
            cp -a "${FILE}" "${OUTFILE}"
            ;;
        *)
            OUTFILE="${OUTFILE}.xz"
            xz --stdout "${FILE}" > "${OUTFILE}"
            touch --reference="${FILE}" "${OUTFILE}"
        esac
    fi
    echo -n "${OUTFILE}"
}

# Restores a file from the large file store
largefile_restore() {
    local SRC=$1 DST=$2 DIR
    DIR="${DST%/*}"
    if [[ ! -d "${DIR}" ]] ; then
        mkdir -p "${DIR}"
    fi
    if [[ "${SRC}" == *.xz && "${SRC: -3}" != "${DST: -3}" ]] ; then
        cp -a "${SRC}" "${DST}.xz"
        unxz "${DST}.xz"
    else
        cp -a "${SRC}" "${DST}"
    fi
}

# Parse command-line and end with success
parseargs "$@"
true
