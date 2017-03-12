.PHONY:	all dist test

all:	test dist

dist:
	./build.sh
	shellcheck dist/*

test:
	shellcheck bin/*
	test/test-common.sh
