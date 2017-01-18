#!/usr/bin/env bash
#
# Runs tests for mixtape-common library.
#

# Global vars & imports
TEST_DIR=$(dirname $0)
source ${TEST_DIR}/assert.sh
source ${TEST_DIR}/../bin/mixtape-common.sh

# Tests the parseargs, checkopts & parseopt functions
test_parseargs() {
    ARGS=()
    OPTS=()
    parseargs --flag one --opt=value two -- --three
    assert "echo -n ${#ARGS[*]}" "3"
    assert "echo -n ${ARGS[*]}" "one two --three"
    assert "echo -n ${#OPTS[*]}" "2"
    assert "echo -n ${OPTS[*]}" "--flag --opt=value"
    assert_raises "checkopts --flag --opt=" 0
    assert_raises "checkopts --dummy --flag --test= --opt=" 0
    assert_raises "checkopts --flag" 1
    assert_raises "checkopts --flag --opt" 1
    assert_raises "checkopts --flag= --opt=" 1
    assert "parseopt --opt=defval" "value"
    assert "parseopt --unset=defval" "defval"
    assert "parseopt --unset=" ""
    assert_raises "parseopt --opt" 1
    assert_raises "parseopt --opt=" 0
    assert_raises "parseopt --flag" 0
    assert_raises "parseopt --flag=" 1
    assert_raises "parseopt --unset" 1
}

# Tests the is_mixtape_dir function
test_is_mixtape_dir() {
    assert "is_mixtape_dir ${TEST_DIR}/mixtape" ""
    assert_raises "is_mixtape_dir ${TEST_DIR}/mixtape" 0
    assert "is_mixtape_dir ${TEST_DIR}/does-not-exist" ""
    assert_raises "is_mixtape_dir ${TEST_DIR}/does-not-exist" 1
    assert "is_mixtape_dir /tmp/does-not-exist/neither-this" ""
    assert_raises "is_mixtape_dir /tmp/does-not-exist/neither-this" 1
}

# Tests the index_datetime function
test_index_datetime() {
    local ID="@587c2ac4"
    local FILE="index.2017-01-16-0207.txt.xz"
    local INDEX="/backup/host/mixtape/index/${FILE}"
    assert "index_datetime ${ID}" "2017-01-16 02:07"
    assert "index_datetime ${ID} iso" "2017-01-16 02:07"
    assert "index_datetime ${ID} file" "2017-01-16-0207"
    assert "index_datetime ${ID} %F" "2017-01-16"
    assert "index_datetime ${FILE}" "2017-01-16 02:07"
    assert "index_datetime ${FILE} iso" "2017-01-16 02:07"
    assert "index_datetime ${FILE} file" "2017-01-16-0207"
    assert "index_datetime ${FILE} %F" "2017-01-16"
    assert "index_datetime ${INDEX}" "2017-01-16 02:07"
    assert "index_datetime ${INDEX} iso" "2017-01-16 02:07"
    assert "index_datetime ${INDEX} file" "2017-01-16-0207"
    assert "index_datetime ${INDEX} %F" "2017-01-16"
}

# Tests the index_epoch function
test_index_epoch() {
    local FILE="index.2017-01-16-0207.txt.xz"
    local INDEX="/backup/host/mixtape/index/${FILE}"
    assert "index_epoch ${FILE}" "@587c2ac4"
    assert "index_epoch ${INDEX}" "@587c2ac4"
    assert "index_epoch '2017-01-16 02:07'" "@587c2ac4"
}

# Tests the index_list function
test_index_list() {
    local DIR=${TEST_DIR}/mixtape
    local IX1="${DIR}/index/index.2017-01-18-0826.txt.xz"
    assert "index_list ${DIR}" "${IX1}"
    assert "index_list ${DIR} @587f2698" "${IX1}"
    assert "index_list ${DIR} all" "${IX1}"
    assert "index_list ${DIR} first" "${IX1}"
    assert "index_list ${DIR} last" "${IX1}"
    assert "index_list ${DIR} 2017-*" "${IX1}"
    assert "index_list ${DIR} 0?-18" "${IX1}"
    assert "index_list ${DIR} @187f2698" ""
    assert "index_list ${DIR} 2016-*" ""
}

# Program start
main() {
    local FUNC
    for FUNC in $(declare -F | cut -d ' ' -f 3 | grep ^test_) ; do
        ${FUNC}
    done
    assert_end "mixtape-common"
}

main
