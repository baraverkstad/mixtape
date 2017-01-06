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
PROGID=${PROGNAME}[$$]
VERSION=0.1

# Flag variables
VERBOSE=false

# Directory variables
BACKUP_DIR=/backup
MIXTAPE_DIR=${BACKUP_DIR}/$(hostname)/mixtape
MIXTAPE_DATA_DIR=${MIXTAPE_DIR}/data
MIXTAPE_INDEX_DIR=${MIXTAPE_DIR}/index
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
    logger -p local0.error -t "${PROGID}" "$@" || true
}

# Logs a warning to stderr and syslog
warn() {
    echo "${COLOR_WARN}WARNING:${COLOR_RESET}" "$@" >&2
    logger -p local0.warning -t "${PROGID}" "$@" || true
}

# Logs a message to stdout and syslog (no stdout if VERBOSE is false)
log() {
    ${VERBOSE} && echo $(date +"%F %T"): "$@" || true
    logger -p local0.info -t "${PROGID}" "$@" || true
}

# Prints program name and version, then exits
versioninfo() {
    echo "${PROGNAME}, version ${VERSION}"
    exit 1
}

# Prints datetime of an index file
index_datetime() {
    local FILE=$1
    local NAME=${FILE##*/}
    echo -n "${NAME:6:10} ${NAME:17:2}:${NAME:19:2}"
}

# Prints hex epoch of an index file
index_epoch() {
    local FILE=$1
    local DATETIME=$(index_datetime ${FILE})
    printf "@%x" $(date --date="${DATETIME}" +"%s")
}

# End with success
true
