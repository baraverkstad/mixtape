#!/usr/bin/env bash
#
# Stores copies of files to a backup.
#
# Syntax: mixtape-backup
#
# Config:
#   /etc/mixtape-backup.conf
#       Lists directories to backup, one per line
#

# Import common functions
SCRIPT=$(readlink $0 || echo -n $0)
LIBRARY=$(dirname ${SCRIPT})/mixtape-common.sh
source ${LIBRARY} || exit 1

# Unset caution flags
# TODO: revert this once script converted
set +o nounset
set +o errtrace
set +o errexit
set +o pipefail

# Global vars
CONFIG=mixtape-backup.conf
DATA_DIR=${MIXTAPE_DIR}/data
INDEX_DIR=${MIXTAPE_DIR}/index

DATE_MONTH=$(date '+%Y-%m')
DATE_MINUTE=$(date '+%Y-%m-%d-%H%M')
INPUT_INDEX=$(ls ${INDEX_DIR}/index.????-??-??-????.txt.xz 2> /dev/null | tail -1)
INPUT_FILES=${TMP_DIR}/input-files.txt
INPUT_IGNORE=${TMP_DIR}/input-ignore.txt
INPUT_INCLUDE=${TMP_DIR}/input-include.txt
INPUT_EXCLUDE=${TMP_DIR}/input-exclude.txt
MATCH_INPUT=${TMP_DIR}/match-input.txt
MATCH_SHASUM=${TMP_DIR}/match-shasum.txt
MATCH_UPTODATE=${TMP_DIR}/match-uptodate.txt
MATCH_LOCATION=${TMP_DIR}/match-location.txt
MATCH_FILES=${TMP_DIR}/match-files.txt
STORE_SMALL=${TMP_DIR}/store-small.txt
STORE_LARGE=${TMP_DIR}/store-large.txt
STORE_SHASUM=${TMP_DIR}/store-shasum.txt
STORE_UNSORTED=${TMP_DIR}/store-unsorted.txt
STORE_SORTED=${TMP_DIR}/store-sorted.txt
OUTPUT_TARFILE=${DATA_DIR}/files/${DATE_MONTH}/files.${DATE_MINUTE}.tar.xz
OUTPUT_INDEX=${INDEX_DIR}/index.${DATE_MINUTE}.txt

rm -rf ${TMP_DIR}
mkdir -p ${TMP_DIR} ${INDEX_DIR} ${DATA_DIR}

# List input files
echo '.git .hg .svn' > ${INPUT_IGNORE}
touch ${INPUT_INCLUDE} ${INPUT_EXCLUDE}
while read RULE ; do
    [[ "${RULE}" != "" && "${RULE:0:1}" != "#" ]] || continue
    if [[ "${RULE:0:1}" == "-" ]] ; then
        echo ${RULE:1} >> ${INPUT_EXCLUDE}
    elif [[ "${SRC:0:1}" == "+" ]] ; then
        echo ${RULE:1} >> ${INPUT_INCLUDE}
    else
        echo ${RULE} >> ${INPUT_INCLUDE}
    fi
done < /etc/$CONFIG
find $(<${INPUT_INCLUDE}) \
     $(xargs -L 1 printf '-not ( -path %s -prune ) ' <${INPUT_EXCLUDE}) \
     $(xargs -L 1 printf '-not ( -name %s -prune ) ' <${INPUT_IGNORE}) \
     -printf '%M\t%u\t%g\t%TF %.8TT\t%k\t%p\t%l\n' | \
     sort --field-separator=$'\t' --key=6,6 > ${INPUT_FILES}

# Match to existing index
if [[ -e "${INPUT_INDEX}" ]] ; then
    xzcat ${INPUT_INDEX} | grep ^- > ${MATCH_INPUT}
    awk -F $'\t' '{print $7 "  " $6}' < ${MATCH_INPUT} > ${MATCH_SHASUM}
    shasum --check ${MATCH_SHASUM} 2> /dev/null | grep 'OK$' | cut -d ':' -f 1 > ${MATCH_UPTODATE}
    join -t $'\t' -1 6 -2 1 -o $'1.6\t1.7\t1.8' ${MATCH_INPUT} ${MATCH_UPTODATE} >> ${MATCH_LOCATION}
    join -t $'\t' -a 1 -1 6 -2 1 -o $'1.1\t1.2\t1.3\t1.4\t1.5\t1.6\t2.2\t2.3' \
         ${INPUT_FILES} ${MATCH_LOCATION} > ${MATCH_FILES}
else
    cd $(dirname ${INPUT_FILES}) ; ln -s $(basename ${INPUT_FILES}) $(basename ${MATCH_FILES})
fi

# Find new/modified files to store
while IFS=$'\t' read ACCESS USER GROUP DATETIME SIZEKB FILE SHA LOCATION ; do
    TYPE=${ACCESS:0:1}
    if [[ ${TYPE} == "-" ]] ; then
        if [[ "${LOCATION}" != "" ]] ; then
            printf "%s\t%s\t%s\n" "${FILE}" "${SHA}" "${LOCATION}" >> ${STORE_UNSORTED}
        elif [[ ${SIZEKB} -lt 256 ]] ; then
            echo ${FILE} >> ${STORE_SMALL}
        else
            echo ${FILE} >> ${STORE_LARGE}
        fi
    fi
done < ${MATCH_FILES}

# Store small files
if [[ -s ${STORE_SMALL} ]] ; then
    echo "Storing $(wc -l < ${STORE_SMALL}) smaller files..."
    mkdir -p $(dirname ${OUTPUT_TARFILE})
    tar -caf ${OUTPUT_TARFILE} -T ${STORE_SMALL} 2> /dev/null
    xargs -L 100 shasum < ${STORE_SMALL} >> ${STORE_SHASUM}
    while read SHA FILE ; do
        printf "%s\t%s\t%s\n" "${FILE}" "${SHA}" "${OUTPUT_TARFILE#${DATA_DIR}/}" >> ${STORE_UNSORTED}
    done < ${STORE_SHASUM}
fi

# Store large files
if [[ -s ${STORE_LARGE} ]] ; then
    while read INFILE ; do
        echo "Storing ${INFILE}..."
        SHA=$(file_shasum "${INFILE}")
        OUTFILE=$(largefile_store "${MIXTAPE_DIR}" "${INFILE}" "${SHA}")
        printf "%s\t%s\t%s\n" "${INFILE}" "${SHA}" "${OUTFILE#${DATA_DIR}/}" >> ${STORE_UNSORTED}
    done < ${STORE_LARGE}
fi

# Add symlinks to store
grep ^l ${INPUT_FILES} | awk -F $'\t' '{print $6 "\t->\t" $7}' >> ${STORE_UNSORTED}

# Build output index
if [[ -s ${STORE_UNSORTED} ]] ; then
    sort --field-separator=$'\t' --key=6,6 ${STORE_UNSORTED} > ${STORE_SORTED}
    join -t $'\t' -a 1 -1 6 -2 1 -o $'1.1\t1.2\t1.3\t1.4\t1.5\t1.6\t2.2\t2.3' \
         ${MATCH_FILES} ${STORE_SORTED} > ${OUTPUT_INDEX}
else
    cp ${MATCH_FILES} ${OUTPUT_INDEX}
fi
xz ${OUTPUT_INDEX}

# Cleanup
rm -rf ${TMP_DIR}
