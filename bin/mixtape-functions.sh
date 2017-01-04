#!/usr/bin/env bash
#
# Library functions used by other scripts
#

# Set caution flags
set -o nounset
set -o errtrace
set -o errexit
set -o pipefail

# Global variables
PROCNAME=$(basename ${SCRIPT} .sh)
PROCID=${PROCNAME}[$$]
VERSION=0.1
VERBOSE=false

# Color variables
if [ -t 0 ]; then
    COLOR_RESET=$(tput sgr0)
    COLOR_OK=$(tput setaf 2)
    COLOR_WARN=$(tput setaf 3)
    COLOR_ERR=$(tput setaf 1; tput bold)
else
    COLOR_RESET=""
    COLOR_OK=""
    COLOR_WARN=""
    COLOR_ERR=""
fi

# Logs an error and exits (code 1)
die() {
    error "$@"
    exit 1
}

# Logs an error to stderr and syslog
error() {
    echo "${COLOR_ERR}ERROR:${COLOR_RESET}" "$@" >&2
    logger -p local0.error -t "${PROCID}" "$@" || true
}

# Logs a warning to stderr and syslog
warn() {
    echo "${COLOR_WARN}WARNING:${COLOR_RESET}" "$@" >&2
    logger -p local0.warning -t "${PROCID}" "$@" || true
}

# Logs a message to stdout and syslog (no stdout if VERBOSE is false)
log() {
    ${VERBOSE} && echo $(date +"%F %T"): "$@" || true
    logger -p local0.info -t "${PROCID}" "$@" || true
}

versioninfo() {
    echo "${PROCNAME}, version ${VERSION}"
    exit 1
}

# End with success
true
