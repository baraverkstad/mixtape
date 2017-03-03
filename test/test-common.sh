#!/usr/bin/env bash
#
# Runs tests for mixtape-common library.
#

# Imports
TEST_DIR=$(dirname $0)
source ${TEST_DIR}/assert.sh
source ${TEST_DIR}/../bin/mixtape-common.sh

# Global vars
FILE1_LOC="data/33d/847/unsplash#1015-2048x1536.jpg"
FILE1_SHA="33d8471d7671d4ad9bc9cc661753b02b490fffb6c6b17b5db07837080d83d30e"
FILE2_LOC="data/68e/24f/loremipsum.txt.xz"
FILE2_SHA="68e24fba182bb7272ba855b59be46f9fb59fb5e60757d4fd6c6c481e39f0e507"

# Tests the trim function
test_trim() {
    assert "trim" ""
    assert "trim '    '" ""
    assert "trim test" "test"
    assert "trim '    test  '" "test"
    local STR=$(printf "\n\t %s %s \n\t" one "  two  ")
    assert 'trim "${STR}"' "one   two"
}

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

# Tests the index_files function
test_index_files() {
    local DIR=${TEST_DIR}/mixtape
    local IX1="${DIR}/index/index.2017-01-19-0846.txt.xz"
    local IX2="${DIR}/index/index.2017-01-20-1149.txt.xz"
    assert "index_files ${DIR}" "${IX1} ${IX2}"
    assert "index_files ${DIR} @58807cc8" "${IX1}"
    assert "index_files ${DIR} all" "${IX1} ${IX2}"
    assert "index_files ${DIR} first" "${IX1}"
    assert "index_files ${DIR} last" "${IX2}"
    assert "index_files ${DIR} 2017-*" "${IX1} ${IX2}"
    assert "index_files ${DIR} 0?-19" "${IX1}"
    assert "index_files ${DIR} @187f2698" ""
    assert "index_files ${DIR} 2016-*" ""
    assert "index_files ${DIR} ${IX1}" "${IX1}"
    assert "index_files ${DIR} index.2017-01-20-1149.txt.xz" "${IX2}"
}

# Tests the index_content function
test_index_content() {
    local DIR=${TEST_DIR}/mixtape
    local IX1="${DIR}/index/index.2017-01-19-0846.txt.xz"
    assert "index_content ${DIR} ${IX1} | wc -l" "7"
    assert "index_content ${DIR} ${IX1} | awk -F'\t' '{print NF; exit}'" "9"
    assert "index_content ${DIR} ${IX1} | awk -F'\t' '{print \$1; exit}'" "@58807cc8"
    assert "index_content ${DIR} ${IX1} / | wc -l" "7"
    assert "index_content ${DIR} ${IX1} README | wc -l" "1"
    assert "index_content ${DIR} ${IX1} 'unsplash*.jpg' | wc -l" "1"
    assert "index_content ${DIR} ${IX1} 'test*.jpg' | wc -l" "0"
    assert "index_content ${DIR} ${IX1} 'test**.jpg' | wc -l" "1"
    assert "index_content ${DIR} ${IX1} '?.file.txt' | wc -l" "1"
    assert "index_content ${DIR} ${IX1} '??.file.txt' | wc -l" "0"
    assert "index_content ${DIR} all 'a.file.txt' | wc -l" "2"
    assert "index_content ${DIR} all '?.file.txt' | wc -l" "3"
    assert "index_content ${DIR} all '??.file.txt' | wc -l" "0"
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

# Tests the file_size_human function
test_file_size_human() {
    assert "file_size_human 1" "1 K"
    assert "file_size_human 1024" "1.0 M"
    assert "file_size_human 1048576" "1.0 G"
    assert "file_size_human 8888" "8.7 M"
    assert "file_size_human 88888" "87 M"
    assert "file_size_human 888888" "868 M"
    assert "file_size_human 8888888" "8.5 G"
    assert "file_size_human 88888888" "85 G"
    assert "file_size_human ${TEST_DIR}/mixtape/${FILE1_LOC}" "552 K"
}

# Tests the file_access_octal function
test_file_access_octal() {
    # read (4), write (2), and execute (1)
    assert "file_access_octal '----------'" "0000"
    assert "file_access_octal '-r--r--r--'" "0444"
    assert "file_access_octal '--w--w--w-'" "0222"
    assert "file_access_octal '---x--x--x'" "0111"
    assert "file_access_octal '-rw-r--r--'" "0644"
    assert "file_access_octal '-rw-rw-rw-'" "0666"
    assert "file_access_octal 'drwx------'" "0700"
    assert "file_access_octal 'drwxr-xr-x'" "0755"
    assert "file_access_octal 'drwxrwxrwx'" "0777"
    assert "file_access_octal ''" "0000"
    assert "file_access_octal '-r--'" "0400"
}

# Tests the file_sha256 function
test_file_sha256() {
    assert "file_sha256 ${TEST_DIR}/mixtape/${FILE1_LOC}" "${FILE1_SHA}"
    assert "file_sha256 does.not.exist" ""
    assert_raises "file_sha256 does.not.exist" 0
    assert "echo test | file_sha256" "f2ca1bb6c7e907d06dafe4687e579fce76b37e4e93b7605022da52e6ccc26fd2"
}

# Tests the tmpfile_create and tmpfile_cleanup functions
test_tmpfile_create() {
    local FILE
    assert_raises "[[ -d ${TMP_DIR} ]]" 1
    FILE=$(tmpfile_create)
    assert_raises "[[ -d ${TMP_DIR} ]]" 0
    assert_raises "[[ -f ${FILE} ]]" 0
    assert_raises "[[ ${FILE} == ${TMP_DIR}/file.tmp.???? ]]" 0
    FILE=$(tmpfile_create test.bin)
    assert_raises "[[ ${FILE} == ${TMP_DIR}/test.bin.???? ]]" 0
    assert_raises "tmpfile_cleanup" 0
    assert_raises "[[ -d ${TMP_DIR} ]]" 1
}

# Tests the largefile_search_sha function
test_largefile_search_sha() {
    DIR=${TEST_DIR}/mixtape
    TEST_SHA="f2ca1bb6c7e907d06dafe4687e579fce76b37e4e93b7605022da52e6ccc26fd2"
    assert "largefile_search_sha ${DIR} ${FILE1_SHA}" "${DIR}/${FILE1_LOC}"
    assert "largefile_search_sha ${DIR} ${FILE2_SHA}" "${DIR}/${FILE2_LOC}"
    assert "largefile_search_sha ${DIR} ${TEST_SHA}" ""
}

# Tests the largefile_store function
test_largefile_store() {
    DIR=${TEST_DIR}/tmp-$$
    SRC1="${TEST_DIR}/mixtape/${FILE1_LOC}"
    SRC2="${DIR}/dummy-copy.jpg"
    SRC3="${DIR}/loremipsum.txt"
    DST1="${DIR}/${FILE1_LOC}"
    DST2="${DIR}/${FILE2_LOC}"
    mkdir -p ${DIR}
    cp ${SRC1} ${SRC2}
    xzcat "${TEST_DIR}/mixtape/${FILE2_LOC}" > ${SRC3}
    assert "largefile_store ${DIR} ${SRC1}" "${DST1}"
    assert "largefile_store ${DIR} ${SRC2}" "${DST1}"
    assert "largefile_store ${DIR} ${SRC3}" "${DST2}"
    assert "largefile_store ${DIR} ${SRC3} ${FILE1_SHA}" "${DST1}"
    assert "find ${DIR}/data -type f | wc -l" "2"
    assert_raises "cmp --quiet ${SRC1} ${DST1}" 0
    assert_raises "cmp --quiet ${SRC2} ${DST1}" 0
    assert_raises "cmp --quiet ${SRC3} ${DST2}" 1
    rm -rf ${DIR}
}

# Tests the largefile_restore function
test_largefile_restore() {
    DIR=${TEST_DIR}/tmp-$$
    SRC1="${TEST_DIR}/mixtape/${FILE1_LOC}"
    SRC2="${TEST_DIR}/mixtape/${FILE2_LOC}"
    DST1="${DIR}/sub/dir/unsplash#1015-2048x1536.jpg"
    DST2="${DIR}/sub/dir/loremipsum.txt"
    mkdir -p ${DIR}
    assert_raises "largefile_restore ${SRC1} ${DST1}" 0
    assert_raises "largefile_restore ${SRC2} ${DST2}" 0
    assert "find ${DIR} -type f | wc -l" "2"
    assert "find ${DIR} -type d | tail -1" "${DIR}/sub/dir"
    assert "file_sha256 ${DST1}" "${FILE1_SHA}"
    assert "file_sha256 ${DST2}" "${FILE2_SHA}"
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
