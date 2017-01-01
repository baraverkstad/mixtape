#!/usr/bin/env bash
#
# Performs a MySQL dump of one or more databases
#
# Syntax: mixtape-mysql-dump [mysql-options] <database(s)>
#

# Config
OPTIONS="--opt --quote-names --skip-add-locks --skip-lock-tables"

# Set caution flags
set -o nounset
set -o errtrace
set -o errexit
set -o pipefail

# Function for printing command-line usage info
usage() {
    echo "Performs a MySQL dump of one or more databases."
    echo
    echo "Syntax: mixtape-mysql-dump [mysql-options] <database(s)>"
    exit 1
}

# Parse command-line arguments
EXTRAS=""
while [ $# -gt 0 ] ; do
    case "$1" in
    "-?"|"-h"|"--help")
        usage
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
[ $# -gt 0 ] || usage

# Special Debian/Ubuntu default file location
if [ -r /etc/mysql/debian.cnf ] ; then
    OPTIONS="--defaults-extra-file=/etc/mysql/debian.cnf ${OPTIONS}"
fi

# Perform MySQL backup
exec mysqldump ${OPTIONS} ${EXTRAS} --databases $@
