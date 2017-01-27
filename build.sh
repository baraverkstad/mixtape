#!/usr/bin/env bash
#
# Builds release version of mixtape.
#

# Global vars & imports
DIR=$(dirname $0)
COMMON=${DIR}/bin/mixtape-common.sh
source ${COMMON}

# Checks if a function is used by a script
func_in_use() {
    local FUNC=$1 SCRIPT=$2 COUNT
    case ${FUNC} in
    versioninfo|usage)
        FUNC=parseargs
        ;;
    index_epoch|index_datetime|index_files)
        grep -q index_ "${SCRIPT}"
        return $?
        ;;
    index_content_regex)
        FUNC=index_content
        ;;
    largefile_search_sha)
        FUNC=largefile_store
        ;;
    esac
    if grep -q -P "${FUNC}( |\$)" "${SCRIPT}" ; then
        return 0
    fi
    COUNT=$(grep -P "${FUNC}( |\$)" "${COMMON}" | wc -l)
    if [[ ${COUNT} -gt 0 ]] ; then
        return 0
    fi
    return 1
}

# Prints the used code from mixtape-common.sh
print_common_inlined() {
    local SCRIPT=$1 ECHO=false LINE= COMMENT= FUNC=
    while IFS= read -r LINE ; do
        case ${LINE} in
        *"() {")
            FUNC=${LINE%%()*}
            if func_in_use "${FUNC}" "${SCRIPT}" ; then
    	        [[ -n ${COMMENT} ]] && echo "${COMMENT}" || true
    	        echo "${LINE}"
	        ECHO=true
                COMMENT=
            else
                ECHO=false
                COMMENT=
            fi
            ;;
        "}")
    	    ${ECHO} && echo "${LINE}" || true
            ;;
        "#"*)
            COMMENT="${LINE}"
            ;;
        "")
    	    ${ECHO} && echo || true
	    ECHO=true
            COMMENT=
            ;;
        *)
    	    ${ECHO} && [[ -n ${COMMENT} ]] && echo "${COMMENT}" || true
    	    ${ECHO} && echo "${LINE}" || true
            COMMENT=
            ;;
	esac
    done < ${COMMON}
}

# Prints a script with mixtape-common.sh inlined
print_inlined_script() {
    local SCRIPT=$1 ECHO=true LINE=
    while IFS= read -r LINE ; do
        case ${LINE} in
        '# Import common'*)
            ECHO=false
            ;;
        'source ${LIBRARY}'*)
            ECHO=true
            print_common_inlined "${SCRIPT}"
            continue
            ;;
        esac
        ${ECHO} && echo "${LINE}" || true
    done < ${SCRIPT}
}

build_dist() {
    local FILE= NAME= DIST="${DIR}/dist"
    rm -rf ${DIST}
    mkdir -p ${DIST}
    for FILE in ${DIR}/bin/*.sh ; do
        NAME=${FILE##*/}
        if [[ ${NAME} != "mixtape-common.sh" ]] ; then
            print_inlined_script ${FILE} > ${DIST}/${NAME%%.sh}
        fi
    done
    chmod +x ${DIST}/*
}

build_dist
