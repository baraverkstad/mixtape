#!/usr/bin/env bash
#
# Performs a MySQL dump of one or more databases
#
# Syntax: mixtape-mysql-dump [mysql-options] <database(s)>
#
# Arguments:
#   <database(s)>    The name of one or more MySQL databases
#
# Options:
#   Additional options are passed directly to mysqldump
#

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-common.sh
source ${LIBRARY} || exit 1

# Global vars
OPTIONS="--opt --quote-names --skip-add-locks --skip-lock-tables"
EXTRAS=""

# Handle command-line arguments
[[ ${#PROGARGS[@]} -gt 0 ]] || usage
if [[ ${#PROGOPTS[@]} -gt 0 ]] ; then
    EXTRAS="${PROGOPTS[@]}"
fi

# Special Debian/Ubuntu default file location
if [[ -r /etc/mysql/debian.cnf ]] ; then
    OPTIONS="--defaults-extra-file=/etc/mysql/debian.cnf ${OPTIONS}"
fi

# Perform MySQL backup
exec mysqldump ${OPTIONS} ${EXTRAS} --databases "${PROGARGS[@]}"
