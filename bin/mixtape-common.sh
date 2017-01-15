#!/usr/bin/env bash
#
# Common variables and functions used by other scripts
#

# Set caution flags
set -o nounset
set -o errtrace
set -o errexit
set -o pipefail

# Process & version variables
PROGNAME=$(basename $0 .sh)
PROGSRC=$0
PROGID=${PROGNAME}[$$]
VERSION=0.2

# Command-line parsing result variables
PROGARGS=()
PROGOPTS=()
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
    logger -p local0.error -t "${PROGID}" -- "$@" || true
}

# Logs a warning to stderr and syslog
warn() {
    echo "${COLOR_WARN}WARNING:${COLOR_RESET}" "$@" >&2
    logger -p local0.warning -t "${PROGID}" -- "$@" || true
}

# Logs a message to stdout and syslog (no stdout if VERBOSE is false)
log() {
    ${VERBOSE} && echo $(date +"%F %T"): "$@" || true
    logger -p local0.info -t "${PROGID}" -- "$@" || true
}

# Prints command-line usage info and exits
usage() {
    local LINE
    while read LINE ; do
        if [[ ${LINE:0:1} = "#" ]] ; then
            echo "${LINE:2}"
        else
            break
        fi
    done < <(tail -n +3 $PROGSRC)
    exit 1
}

# Prints program name and version, then exits
versioninfo() {
    echo "${PROGNAME}, version ${VERSION}"
    exit 1
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

# Prints datetime of an index file
index_datetime() {
    local INDEX=$1 NAME
    NAME=${INDEX##*/}
    echo -n "${NAME:6:10} ${NAME:17:2}:${NAME:19:2}"
}

# Prints hex epoch of an index file
index_epoch() {
    local INDEX=$1 DATETIME
    DATETIME=$(index_datetime ${INDEX})
    printf "@%x" $(date --date="${DATETIME}" +"%s")
}

# Prints matching (and existing) index files for a backup dir
index_list() {
    local DIR="$1" MATCH="${2:-}" GLOB FILES POS
    if [[ ${MATCH:0:1} = "@" ]] ; then
        GLOB=$(date --date=@$((16#${MATCH:1})) +'%Y-%m-%d-%H%M')
    elif [[ ${MATCH} = "first" ]] ; then
        GLOB="*"
        POS=0
    elif [[ ${MATCH} = "last" ]] ; then
        GLOB="*"
        POS=-1
    elif [[ -n ${MATCH} ]] ; then
        GLOB=$(echo -n \*${MATCH}\* | tr ' ' '-' | tr -d ':')
    else
        GLOB="*"
    fi
    FILES=(${DIR}/index/index.${GLOB}.txt.xz)
    if [[ -z ${POS:-} && -e ${FILES[0]} ]] ; then
        echo -n ${FILES[@]}
    elif [[ -n ${POS:-} && -e ${FILES[${POS}]} ]] ; then
        echo -n ${FILES[${POS}]}
    fi
}

# Prints contents of an index (optionally filtered by a file regex)
index_content() {
    local INDEX="$1" MATCH="${2:-}" PREFIX
    PREFIX=$(index_epoch ${INDEX})$'\t'
    if [[ -z ${MATCH} ]] ; then
        xzcat ${INDEX} | \
            awk -v prefix="${PREFIX}" '$0 = prefix$0' || \
            true
    else
        xzcat ${INDEX} | \
            awk -F $'\t' -v IGNORECASE=1 \
                -v regex="${MATCH}" -v prefix="${PREFIX}" \
                "\$6 ~ regex { print prefix \$0 }" || \
            true
    fi
}

# Prints contents for all indices (optionally filtered by a grep regex)
index_all_content() {
    local DIR="$1" MATCH="${2:-}" INDEX
    for INDEX in ${DIR}/index/*.xz ; do
        index_content ${INDEX} "${MATCH}"
    done
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
    --backup-dir=*)
        OPT=${1:13}
        BACKUP_DIR=$(realpath ${OPT} 2>/dev/null)
        MIXTAPE_DIR=${BACKUP_DIR}/$(hostname)/mixtape
        if [[ ! -e ${BACKUP_DIR} ]] ; then
            die "backup dir doesn't exist: ${OPT}"
        elif [[ ! -d ${BACKUP_DIR} ]] ; then
            die "backup dir isn't a directory: ${BACKUP_DIR}"
        elif [[ ${BACKUP_DIR} == "/" ]] ; then
            die "backup dir cannot be /"
        fi
        shift
        ;;
    --mixtape-dir=*)
        OPT=${1:14}
        MIXTAPE_DIR=$(realpath ${OPT} 2>/dev/null)
        if [[ ! -e ${MIXTAPE_DIR} ]] ; then
            die "mixtape dir doesn't exist: ${OPT}"
        elif [[ ! -d ${MIXTAPE_DIR} ]] ; then
            die "mixtape dir isn't a directory: ${MIXTAPE_DIR}"
        elif [[ ${MIXTAPE_DIR} == "/" ]] ; then
            die "mixtape dir cannot be /"
        fi
        shift
        ;;
    --)
        shift
        PROGARGS+=("$@")
        break
        ;;
    -*)
        PROGOPTS+=("$1")
        shift
        ;;
    *)
        PROGARGS+=("$1")
        shift
        ;;
    esac
done

# End with success
true
