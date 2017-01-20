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
    local IX1="${DIR}/index/index.2017-01-19-0846.txt.xz"
    local IX2="${DIR}/index/index.2017-01-20-1149.txt.xz"
    assert "index_list ${DIR}" "${IX1} ${IX2}"
    assert "index_list ${DIR} @58807cc8" "${IX1}"
    assert "index_list ${DIR} all" "${IX1} ${IX2}"
    assert "index_list ${DIR} first" "${IX1}"
    assert "index_list ${DIR} last" "${IX2}"
    assert "index_list ${DIR} 2017-*" "${IX1} ${IX2}"
    assert "index_list ${DIR} 0?-19" "${IX1}"
    assert "index_list ${DIR} @187f2698" ""
    assert "index_list ${DIR} 2016-*" ""
}

# Tests the index_content function
test_index_content() {
    local DIR=${TEST_DIR}/mixtape
    local IX1="${DIR}/index/index.2017-01-19-0846.txt.xz"
    assert "index_content ${IX1} | wc -l" "7"
    assert "index_content ${IX1} | awk -F'\t' '{print NF; exit}'" "9"
    assert "index_content ${IX1} | awk -F'\t' '{print \$1; exit}'" "@58807cc8"
    assert "index_content ${IX1} / | wc -l" "7"
    assert "index_content ${IX1} README | wc -l" "1"
    assert "index_content ${IX1} 'unsplash*.jpg' | wc -l" "1"
    assert "index_content ${IX1} 'test*.jpg' | wc -l" "0"
    assert "index_content ${IX1} 'test**.jpg' | wc -l" "1"
    assert "index_content ${IX1} '?.file.txt' | wc -l" "1"
    assert "index_content ${IX1} '??.file.txt' | wc -l" "0"
}

# Tests the index_content_regex function
test_index_content_regex() {
    # Assert uses echo -e for results, so extra '\\' needed
    assert "index_content_regex" '\\t/'
    assert "index_content_regex '*'" '\\t/'
    assert "index_content_regex '**'" '\\t/'
    assert "index_content_regex /" '\\t/'
    assert "index_content_regex root" '\\t/[^\\t]*root'
    assert "index_content_regex '*root*'" '\\t/[^\\t]*root'
    assert "index_content_regex '/root**'" '\\t/root'
    assert "index_content_regex 'unsplash*.jpg'" '\\t/[^\\t]*unsplash[^/\\t]*\\.jpg'
    assert "index_content_regex 'test**.jpg'" '\\t/[^\\t]*test[^\\t]*\\.jpg'
    assert "index_content_regex '?.file.txt'" '\\t/[^\\t]*[^/\\t]\\.file\\.txt'
    assert "index_content_regex '??.file.txt'" '\\t/[^\\t]*[^/\\t][^/\\t]\\.file\\.txt'
}

# Tests the largefile_search_sha function
test_largefile_search_sha() {
    DIR=${TEST_DIR}/mixtape
    SHA1="bfff4213a7adcb1c33e76f78484a167fe2848113"
    SHA2="eb7faf0b51528980753879c8e51d1f59e0e9c630"
    SHA3="43cca6b738ba9a1f3d86875a21cdbb419cbdd5f1"
    assert "largefile_search_sha ${DIR} ${SHA1}" "${DIR}/data/bff/f42/unsplash#1015-2048x1536.jpg"
    assert "largefile_search_sha ${DIR} ${SHA2}" "${DIR}/data/eb7/faf/loremipsum.txt.xz"
    assert "largefile_search_sha ${DIR} ${SHA3}" ""
}

# Tests the largefile_store function
test_largefile_store() {
    DIR=${TEST_DIR}/tmp-$$
    SRC1="${TEST_DIR}/mixtape/data/bff/f42/unsplash#1015-2048x1536.jpg"
    SRC2="${DIR}/dummy-copy.jpg"
    SRC3="${DIR}/loremipsum.txt"
    DST1="${DIR}/data/bff/f42/unsplash#1015-2048x1536.jpg"
    DST2="${DIR}/data/eb7/faf/loremipsum.txt.xz"
    SHA1="bfff4213a7adcb1c33e76f78484a167fe2848113"
    mkdir -p ${DIR}
    cp ${SRC1} ${SRC2}
    xzcat "${TEST_DIR}/mixtape/data/eb7/faf/loremipsum.txt.xz" > ${SRC3}
    assert "largefile_store ${DIR} ${SRC1}" "${DST1}"
    assert "largefile_store ${DIR} ${SRC2}" "${DST1}"
    assert "largefile_store ${DIR} ${SRC3}" "${DST2}"
    assert "largefile_store ${DIR} ${SRC3} ${SHA1}" "${DST1}"
    assert "find ${DIR}/data -type f | wc -l" "2"
    assert_raises "cmp --quiet ${SRC1} ${DST1}" 0
    assert_raises "cmp --quiet ${SRC2} ${DST1}" 0
    assert_raises "cmp --quiet ${SRC3} ${DST2}" 1
    rm -rf ${DIR}
}

# Tests the largefile_restore function
test_largefile_restore() {
    DIR=${TEST_DIR}/tmp-$$
    SRC1="${TEST_DIR}/mixtape/data/bff/f42/unsplash#1015-2048x1536.jpg"
    SRC2="${TEST_DIR}/mixtape/data/eb7/faf/loremipsum.txt.xz"
    DST1="${DIR}/sub/dir/unsplash#1015-2048x1536.jpg"
    DST2="${DIR}/sub/dir/loremipsum.txt"
    SHA1="bfff4213a7adcb1c33e76f78484a167fe2848113"
    SHA2="eb7faf0b51528980753879c8e51d1f59e0e9c630"
    mkdir -p ${DIR}
    assert_raises "largefile_restore ${SRC1} ${DST1}" 0
    assert_raises "largefile_restore ${SRC2} ${DST2}" 0
    assert "find ${DIR} -type f | wc -l" "2"
    assert "find ${DIR} -type d | tail -1" "${DIR}/sub/dir"
    assert "shasum ${DST1} | cut -d ' ' -f 1" "${SHA1}"
    assert "shasum ${DST2} | cut -d ' ' -f 1" "${SHA2}"
    rm -rf ${DIR}
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
