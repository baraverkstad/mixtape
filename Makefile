.PHONY:	all dist test

all:	test dist

dist:
	./build.sh

test:
	shellcheck bin/*
	test/test-common.sh
