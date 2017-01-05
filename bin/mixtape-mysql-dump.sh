#!/usr/bin/env bash
#
# Performs a MySQL dump of one or more databases
#
# Syntax: mixtape-mysql-dump [mysql-options] <database(s)>
#

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-functions.sh
source ${LIBRARY} || exit 1

# Global vars
OPTIONS="--opt --quote-names --skip-add-locks --skip-lock-tables"
EXTRAS=""

# Prints command-line usage info and exits
usage() {
    echo "Performs a MySQL dump of one or more databases."
    echo
    echo "Syntax: mixtape-mysql-dump [mysql-options] <database(s)>"
    exit 1
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
    -*)
        EXTRAS="${EXTRAS} $1"
        shift
        ;;
    *)
        break
        ;;
    esac
done
[[ $# -gt 0 ]] || usage

# Special Debian/Ubuntu default file location
if [[ -r /etc/mysql/debian.cnf ]] ; then
    OPTIONS="--defaults-extra-file=/etc/mysql/debian.cnf ${OPTIONS}"
fi

# Perform MySQL backup
exec mysqldump ${OPTIONS} ${EXTRAS} --databases $@
