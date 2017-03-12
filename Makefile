.PHONY:	all dist test

all:	test dist

dist:
	./build-dist.sh
	shellcheck dist/bin/*

test:
	test/test-common.sh
	shellcheck bin/*
