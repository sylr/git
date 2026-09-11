#!/bin/sh
#
# Copyright (c) 2007 Michael Spang
#

test_description='git clean basic tests'

. ./test-lib.sh

git config clean.requireForce no

test_expect_success 'setup' '

	mkdir -p src &&
	touch src/part1.c Makefile &&
	echo build >.gitignore &&
	echo \*.o >>.gitignore &&
	git add . &&
	git commit -m setup &&
	touch src/part2.c README &&
	git add .

'

test_expect_success 'git clean with skip-worktree .gitignore' '
	git update-index --skip-worktree .gitignore &&
	rm .gitignore &&
	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	git clean &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_missing a.out &&
	test_path_is_missing src/part3.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_file obj.o &&
	test_path_is_file build/lib.so &&
	git update-index --no-skip-worktree .gitignore &&
	git checkout .gitignore
'

test_expect_success 'git clean' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	git clean &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_missing a.out &&
	test_path_is_missing src/part3.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_file obj.o &&
	test_path_is_file build/lib.so

'

test_expect_success 'git clean src/' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	git clean src/ &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_file a.out &&
	test_path_is_missing src/part3.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_file obj.o &&
	test_path_is_file build/lib.so

'

test_expect_success 'git clean src/ src/' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	git clean src/ src/ &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_file a.out &&
	test_path_is_missing src/part3.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_file obj.o &&
	test_path_is_file build/lib.so

'

test_expect_success 'git clean with prefix' '

	mkdir -p build docs src/test &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so src/test/1.c &&
	(cd src/ && git clean) &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_file a.out &&
	test_path_is_missing src/part3.c &&
	test_path_is_file src/test/1.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_file obj.o &&
	test_path_is_file build/lib.so

'

test_expect_success 'git clean with relative prefix' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	would_clean=$(
		cd docs &&
		git clean -n ../src |
		grep part3 |
		sed -n -e "s|^Would remove ||p"
	) &&
	test "$would_clean" = ../src/part3.c
'

test_expect_success 'git clean with absolute path' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	would_clean=$(
		cd docs &&
		git clean -n "$(pwd)/../src" |
		grep part3 |
		sed -n -e "s|^Would remove ||p"
	) &&
	test "$would_clean" = ../src/part3.c
'

test_expect_success 'git clean with out of work tree relative path' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	(
		cd docs &&
		test_must_fail git clean -n ../..
	)
'

test_expect_success 'git clean with out of work tree absolute path' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	dd=$(cd .. && pwd) &&
	(
		cd docs &&
		test_must_fail git clean -n $dd
	)
'

test_expect_success 'git clean -d with prefix and path' '

	mkdir -p build docs src/feature &&
	touch a.out src/part3.c src/feature/file.c docs/manual.txt obj.o build/lib.so &&
	(cd src/ && git clean -d feature/) &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_file a.out &&
	test_path_is_file src/part3.c &&
	test_path_is_missing src/feature/file.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_file obj.o &&
	test_path_is_file build/lib.so

'

test_expect_success SYMLINKS 'git clean symbolic link' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	ln -s docs/manual.txt src/part4.c &&
	git clean &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_missing a.out &&
	test_path_is_missing src/part3.c &&
	test_path_is_missing src/part4.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_file obj.o &&
	test_path_is_file build/lib.so

'

test_expect_success 'git clean with wildcard' '

	touch a.clean b.clean other.c &&
	git clean "*.clean" &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_missing a.clean &&
	test_path_is_missing b.clean &&
	test_path_is_file other.c

'

test_expect_success 'git clean -n' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	git clean -n &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_file a.out &&
	test_path_is_file src/part3.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_file obj.o &&
	test_path_is_file build/lib.so

'

test_expect_success 'git clean -d' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	git clean -d &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_missing a.out &&
	test_path_is_missing src/part3.c &&
	test_path_is_missing docs &&
	test_path_is_file obj.o &&
	test_path_is_file build/lib.so

'

test_expect_success 'git clean -d src/ examples/' '

	mkdir -p build docs examples &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so examples/1.c &&
	git clean -d src/ examples/ &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_file a.out &&
	test_path_is_missing src/part3.c &&
	test_path_is_missing examples/1.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_file obj.o &&
	test_path_is_file build/lib.so

'

test_expect_success 'git clean -x' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	git clean -x &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_missing a.out &&
	test_path_is_missing src/part3.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_missing obj.o &&
	test_path_is_file build/lib.so

'

test_expect_success 'git clean -d -x' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	git clean -d -x &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_missing a.out &&
	test_path_is_missing src/part3.c &&
	test_path_is_missing docs &&
	test_path_is_missing obj.o &&
	test_path_is_missing build

'

test_expect_success 'git clean -d -x with ignored tracked directory' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	git clean -d -x -e src &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_missing a.out &&
	test_path_is_file src/part3.c &&
	test_path_is_missing docs &&
	test_path_is_missing obj.o &&
	test_path_is_missing build

'

test_expect_success 'git clean -X' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	git clean -X &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_file a.out &&
	test_path_is_file src/part3.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_missing obj.o &&
	test_path_is_file build/lib.so

'

test_expect_success 'git clean -d -X' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	git clean -d -X &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_file a.out &&
	test_path_is_file src/part3.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_missing obj.o &&
	test_path_is_missing build

'

test_expect_success 'git clean -d -X with ignored tracked directory' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	git clean -d -X -e src &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_file a.out &&
	test_path_is_missing src/part3.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_missing obj.o &&
	test_path_is_missing build

'

test_expect_success 'clean.requireForce defaults to true' '

	git config --unset clean.requireForce &&
	test_must_fail git clean

'

test_expect_success 'clean.requireForce' '

	git config clean.requireForce true &&
	test_must_fail git clean

'

test_expect_success 'clean.requireForce and -n' '

	mkdir -p build docs &&
	touch a.out src/part3.c docs/manual.txt obj.o build/lib.so &&
	git clean -n &&
	test_path_is_file Makefile &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_file a.out &&
	test_path_is_file src/part3.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_file obj.o &&
	test_path_is_file build/lib.so

'

test_expect_success 'clean.requireForce and -f' '

	git clean -f &&
	test_path_is_file README &&
	test_path_is_file src/part1.c &&
	test_path_is_file src/part2.c &&
	test_path_is_missing a.out &&
	test_path_is_missing src/part3.c &&
	test_path_is_file docs/manual.txt &&
	test_path_is_file obj.o &&
	test_path_is_file build/lib.so

'

test_expect_success 'clean.requireForce and --interactive' '
	git clean --interactive </dev/null >output 2>error &&
	test_grep ! "requireForce is true and" error &&
	test_grep "\*\*\* Commands \*\*\*" output
'

test_expect_success 'core.excludesfile' '

	echo excludes >excludes &&
	echo included >included &&
	git config core.excludesfile excludes &&
	output=$(git clean -n excludes included 2>&1) &&
	expr "$output" : ".*included" >/dev/null &&
	! expr "$output" : ".*excludes" >/dev/null

'

test_expect_success SANITY 'removal failure' '

	mkdir foo &&
	touch foo/bar &&
	test_when_finished "chmod 755 foo" &&
	(exec <foo/bar &&
	 chmod 0 foo &&
	 test_must_fail git clean -f -d)
'

test_expect_success 'nested git work tree' '
	rm -fr foo bar baz &&
	mkdir -p foo bar baz/boo &&
	(
		cd foo &&
		git init &&
		test_commit nested hello.world
	) &&
	(
		cd bar &&
		>goodbye.people
	) &&
	(
		cd baz/boo &&
		git init &&
		test_commit deeply.nested deeper.world
	) &&
	git clean -f -d &&
	test_path_is_file foo/.git/index &&
	test_path_is_file foo/hello.world &&
	test_path_is_file baz/boo/.git/index &&
	test_path_is_file baz/boo/deeper.world &&
	test_path_is_missing bar
'

test_expect_success 'should clean things that almost look like git but are not' '
	rm -fr almost_git almost_bare_git almost_submodule &&
	mkdir -p almost_git/.git/objects &&
	mkdir -p almost_git/.git/refs &&
	cat >almost_git/.git/HEAD <<-\EOF &&
	garbage
	EOF
	cp -r almost_git/.git/ almost_bare_git &&
	mkdir almost_submodule/ &&
	cat >almost_submodule/.git <<-\EOF &&
	garbage
	EOF
	test_when_finished "rm -rf almost_*" &&
	git clean -f -d &&
	test_path_is_missing almost_git &&
	test_path_is_missing almost_bare_git &&
	test_path_is_missing almost_submodule
'

test_expect_success 'should not clean submodules' '
	rm -fr repo to_clean sub1 sub2 &&
	mkdir repo to_clean &&
	(
		cd repo &&
		git init &&
		test_commit msg hello.world
	) &&
	test_config_global protocol.file.allow always &&
	git submodule add ./repo/.git sub1 &&
	git commit -m "sub1" &&
	git branch before_sub2 &&
	git submodule add ./repo/.git sub2 &&
	git commit -m "sub2" &&
	git checkout before_sub2 &&
	>to_clean/should_clean.this &&
	git clean -f -d &&
	test_path_is_file repo/.git/index &&
	test_path_is_file repo/hello.world &&
	test_path_is_file sub1/.git &&
	test_path_is_file sub1/hello.world &&
	test_path_is_file sub2/.git &&
	test_path_is_file sub2/hello.world &&
	test_path_is_missing to_clean
'

test_expect_success POSIXPERM,SANITY 'should avoid cleaning possible submodules' '
	rm -fr to_clean possible_sub1 &&
	mkdir to_clean possible_sub1 &&
	test_when_finished "rm -rf possible_sub*" &&
	echo "gitdir: foo" >possible_sub1/.git &&
	>possible_sub1/hello.world &&
	chmod 0 possible_sub1/.git &&
	>to_clean/should_clean.this &&
	git clean -f -d &&
	test_path_is_file possible_sub1/.git &&
	test_path_is_file possible_sub1/hello.world &&
	test_path_is_missing to_clean
'

test_expect_success 'nested (empty) git should be kept' '
	rm -fr empty_repo to_clean &&
	git init empty_repo &&
	mkdir to_clean &&
	>to_clean/should_clean.this &&
	# Note that we put the expect file in the .git directory so that it
	# does not get cleaned.
	find empty_repo | sort >.git/expect &&
	git clean -f -d &&
	find empty_repo | sort >actual &&
	test_cmp .git/expect actual &&
	test_path_is_missing to_clean
'

test_expect_success 'nested bare repositories should be cleaned' '
	rm -fr bare1 bare2 subdir &&
	git init --bare bare1 &&
	git clone --local --bare . bare2 &&
	mkdir subdir &&
	cp -r bare2 subdir/bare3 &&
	git clean -f -d &&
	test_path_is_missing bare1 &&
	test_path_is_missing bare2 &&
	test_path_is_missing subdir
'

test_expect_failure 'nested (empty) bare repositories should be cleaned even when in .git' '
	rm -fr strange_bare &&
	mkdir strange_bare &&
	git init --bare strange_bare/.git &&
	git clean -f -d &&
	test_path_is_missing strange_bare
'

test_expect_failure 'nested (non-empty) bare repositories should be cleaned even when in .git' '
	rm -fr strange_bare &&
	mkdir strange_bare &&
	git clone --local --bare . strange_bare/.git &&
	git clean -f -d &&
	test_path_is_missing strange_bare
'

test_expect_success 'giving path in nested git work tree will NOT remove it' '
	rm -fr repo &&
	mkdir repo &&
	(
		cd repo &&
		git init &&
		mkdir -p bar/baz &&
		test_commit msg bar/baz/hello.world
	) &&
	find repo | sort >expect &&
	git clean -f -d repo/bar/baz &&
	find repo | sort >actual &&
	test_cmp expect actual
'

test_expect_success 'giving path to nested .git will not remove it' '
	rm -fr repo &&
	mkdir repo untracked &&
	(
		cd repo &&
		git init &&
		test_commit msg hello.world
	) &&
	find repo | sort >expect &&
	git clean -f -d repo/.git &&
	find repo | sort >actual &&
	test_cmp expect actual &&
	test_path_is_dir untracked/
'

test_expect_success 'giving path to nested .git/ will NOT remove contents' '
	rm -fr repo untracked &&
	mkdir repo untracked &&
	(
		cd repo &&
		git init &&
		test_commit msg hello.world
	) &&
	find repo | sort >expect &&
	git clean -f -d repo/.git/ &&
	find repo | sort >actual &&
	test_cmp expect actual &&
	test_path_is_dir untracked/
'

test_expect_success 'force removal of nested git work tree' '
	rm -fr foo bar baz &&
	mkdir -p foo bar baz/boo &&
	(
		cd foo &&
		git init &&
		test_commit nested hello.world
	) &&
	(
		cd bar &&
		>goodbye.people
	) &&
	(
		cd baz/boo &&
		git init &&
		test_commit deeply.nested deeper.world
	) &&
	git clean -f -f -d &&
	test_path_is_missing foo &&
	test_path_is_missing bar &&
	test_path_is_missing baz
'

test_expect_success 'git clean -e' '
	rm -fr repo &&
	mkdir repo &&
	(
		cd repo &&
		git init &&
		touch known 1 2 3 &&
		git add known &&
		git clean -f -e 1 -e 2 &&
		test_path_exists 1 &&
		test_path_exists 2 &&
		test_path_is_missing 3 &&
		test_path_exists known
	)
'

test_expect_success SANITY 'git clean -d with an unreadable empty directory' '
	mkdir foo &&
	chmod a= foo &&
	git clean -dfx foo &&
	test_path_is_missing foo
'

test_expect_success 'git clean -d respects pathspecs (dir is prefix of pathspec)' '
	mkdir -p foo &&
	mkdir -p foobar &&
	git clean -df foobar &&
	test_path_is_dir foo &&
	test_path_is_missing foobar
'

test_expect_success 'git clean -d respects pathspecs (pathspec is prefix of dir)' '
	mkdir -p foo &&
	mkdir -p foobar &&
	git clean -df foo &&
	test_path_is_missing foo &&
	test_path_is_dir foobar
'

test_expect_success 'git clean -d skips untracked dirs containing ignored files' '
	echo /foo/bar >.gitignore &&
	echo ignoreme >>.gitignore &&
	rm -rf foo &&
	mkdir -p foo/a/aa/aaa foo/b/bb/bbb &&
	touch foo/bar foo/baz foo/a/aa/ignoreme foo/b/ignoreme foo/b/bb/1 foo/b/bb/2 &&
	git clean -df &&
	test_path_is_dir foo &&
	test_path_is_file foo/bar &&
	test_path_is_missing foo/baz &&
	test_path_is_file foo/a/aa/ignoreme &&
	test_path_is_missing foo/a/aa/aaa &&
	test_path_is_file foo/b/ignoreme &&
	test_path_is_missing foo/b/bb
'

test_expect_success 'git clean -d skips nested repo containing ignored files' '
	test_when_finished "rm -rf nested-repo-with-ignored-file" &&

	git init nested-repo-with-ignored-file &&
	(
		cd nested-repo-with-ignored-file &&
		>file &&
		git add file &&
		git commit -m Initial &&

		# This file is ignored by a .gitignore rule in the outer repo
		# added in the previous test.
		>ignoreme
	) &&

	git clean -fd &&

	test_path_is_file nested-repo-with-ignored-file/.git/index &&
	test_path_is_file nested-repo-with-ignored-file/ignoreme &&
	test_path_is_file nested-repo-with-ignored-file/file
'

test_expect_success 'git clean handles being told what to clean' '
	mkdir -p d1 d2 &&
	touch d1/ut d2/ut &&
	git clean -f */ut &&
	test_path_is_missing d1/ut &&
	test_path_is_missing d2/ut
'

test_expect_success 'git clean handles being told what to clean, with -d' '
	mkdir -p d1 d2 &&
	touch d1/ut d2/ut &&
	git clean -ffd */ut &&
	test_path_is_missing d1/ut &&
	test_path_is_missing d2/ut
'

test_expect_success 'git clean works if a glob is passed without -d' '
	mkdir -p d1 d2 &&
	touch d1/ut d2/ut &&
	git clean -f "*ut" &&
	test_path_is_missing d1/ut &&
	test_path_is_missing d2/ut
'

test_expect_success 'git clean works if a glob is passed with -d' '
	mkdir -p d1 d2 &&
	touch d1/ut d2/ut &&
	git clean -ffd "*ut" &&
	test_path_is_missing d1/ut &&
	test_path_is_missing d2/ut
'

test_expect_success MINGW 'handle clean & core.longpaths = false nicely' '
	test_config core.longpaths false &&
	a50=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa &&
	mkdir -p $a50$a50/$a50$a50/$a50$a50 &&
	: >"$a50$a50/test.txt" 2>"$a50$a50/$a50$a50/$a50$a50/test.txt" &&
	# create a temporary outside the working tree to hide from "git clean"
	test_must_fail git clean -xdf 2>.git/err &&
	# grepping for a strerror string is unportable but it is OK here with
	# MINGW prereq
	test_grep -e "too long" -e "No such file or directory" .git/err
'

test_expect_success 'clean untracked paths by pathspec' '
	git init untracked &&
	mkdir untracked/dir &&
	echo >untracked/dir/file.txt &&
	git -C untracked clean -f dir/file.txt &&
	ls untracked/dir >actual &&
	test_must_be_empty actual
'

test_expect_success 'avoid traversing into ignored directories' '
	test_when_finished rm -f output error trace.* &&
	test_create_repo avoid-traversing-deep-hierarchy &&
	(
		cd avoid-traversing-deep-hierarchy &&

		mkdir -p untracked/subdir/with/a &&
		>untracked/subdir/with/a/random-file.txt &&

		GIT_TRACE2_PERF="$TRASH_DIRECTORY/trace.output" \
		git clean -ffdxn -e untracked
	) &&

	# Make sure we only visited into the top-level directory, and did
	# not traverse into the "untracked" subdirectory since it was excluded
	grep data.*read_directo.*directories-visited trace.output |
		cut -d "|" -f 9 >trace.relevant &&
	cat >trace.expect <<-EOF &&
	 ..directories-visited:1
	EOF
	test_cmp trace.expect trace.relevant
'

test_expect_success 'traverse into directories that may have ignored entries' '
	test_when_finished rm -f output &&
	test_create_repo need-to-traverse-into-hierarchy &&
	(
		cd need-to-traverse-into-hierarchy &&
		mkdir -p modules/foobar/src/generated &&
		> modules/foobar/src/generated/code.c &&
		> modules/foobar/Makefile &&
		echo "/modules/**/src/generated/" >.gitignore &&

		git clean -fX modules/foobar >../output &&

		grep Removing ../output &&

		test_path_is_missing modules/foobar/src/generated/code.c &&
		test_path_is_file modules/foobar/Makefile
	)
'

#
# Tests for .gitcleanignore
#

test_expect_success 'setup for cleanignore tests' '
	test_create_repo cleanignore-tests &&
	(
		cd cleanignore-tests &&
		>tracked_file &&
		git add tracked_file &&
		git commit -m "initial commit"
	)
'

test_expect_success '.gitcleanignore protects untracked files' '
	(
		cd cleanignore-tests &&
		>untracked_file &&
		>protected_file &&
		echo "protected_file" >.gitcleanignore &&
		git clean -f &&
		test_path_is_missing untracked_file &&
		test_path_is_file protected_file &&
		rm -f protected_file .gitcleanignore
	)
'

test_expect_success '.gitcleanignore protects files even with -x flag' '
	(
		cd cleanignore-tests &&
		>untracked_file &&
		>protected_file &&
		echo "*.ignored" >.gitignore &&
		>file.ignored &&
		echo "protected_file" >.gitcleanignore &&
		git clean -fx &&
		test_path_is_missing untracked_file &&
		test_path_is_missing file.ignored &&
		test_path_is_file protected_file &&
		rm -f protected_file .gitcleanignore .gitignore
	)
'

test_expect_success '.gitcleanignore protects files with -X flag' '
	(
		cd cleanignore-tests &&
		echo "*.ignored" >.gitignore &&
		>file.ignored &&
		>protected.ignored &&
		echo "protected.ignored" >.gitcleanignore &&
		git clean -fX &&
		test_path_is_missing file.ignored &&
		test_path_is_file protected.ignored &&
		rm -f protected.ignored .gitcleanignore .gitignore
	)
'

test_expect_success 'nested per-directory .gitcleanignore works' '
	(
		cd cleanignore-tests &&
		mkdir -p subdir &&
		>subdir/untracked_file &&
		>subdir/protected_file &&
		echo "subdir/" >.gitcleanignore &&
		git clean -fd &&
		test_path_is_dir subdir &&
		test_path_is_file subdir/protected_file &&
		rm -rf subdir .gitcleanignore
	)
'

test_expect_success '.gitcleanignore pattern matching with wildcards' '
	(
		cd cleanignore-tests &&
		>file1.keep &&
		>file2.keep &&
		>file.delete &&
		echo "*.keep" >.gitcleanignore &&
		git clean -f &&
		test_path_is_file file1.keep &&
		test_path_is_file file2.keep &&
		test_path_is_missing file.delete &&
		rm -f file1.keep file2.keep .gitcleanignore
	)
'

test_expect_success '.git/info/cleanignore works' '
	(
		cd cleanignore-tests &&
		mkdir -p .git/info &&
		>untracked_file &&
		>repo_protected_file &&
		echo "repo_protected_file" >.git/info/cleanignore &&
		git clean -f &&
		test_path_is_missing untracked_file &&
		test_path_is_file repo_protected_file &&
		rm -f repo_protected_file .git/info/cleanignore
	)
'

test_expect_success 'core.cleanExcludesFile works' '
	(
		cd cleanignore-tests &&
		>untracked_file &&
		>global_protected_file &&
		echo "global_protected_file" >"$TRASH_DIRECTORY/global_cleanignore" &&
		git -c core.cleanExcludesFile="$TRASH_DIRECTORY/global_cleanignore" clean -f &&
		test_path_is_missing untracked_file &&
		test_path_is_file global_protected_file &&
		rm -f global_protected_file "$TRASH_DIRECTORY/global_cleanignore"
	)
'

test_expect_success '.gitcleanignore negation patterns work' '
	(
		cd cleanignore-tests &&
		>file1.tmp &&
		>file2.tmp &&
		>important.tmp &&
		cat >.gitcleanignore <<-\EOF &&
		*.tmp
		!important.tmp
		EOF
		git clean -f &&
		test_path_is_file file1.tmp &&
		test_path_is_file file2.tmp &&
		test_path_is_missing important.tmp &&
		rm -f file1.tmp file2.tmp .gitcleanignore
	)
'

test_expect_success '.gitcleanignore directory patterns work' '
	(
		cd cleanignore-tests &&
		mkdir -p protected_dir unprotected_dir &&
		>protected_dir/file &&
		>unprotected_dir/file &&
		echo "protected_dir/" >.gitcleanignore &&
		git clean -fd &&
		test_path_is_dir protected_dir &&
		test_path_is_file protected_dir/file &&
		test_path_is_missing unprotected_dir &&
		rm -rf protected_dir .gitcleanignore
	)
'

test_expect_success 'cleanignore protects descendant inside untracked dir with -fd' '
	(
		cd cleanignore-tests &&
		mkdir -p sub &&
		>sub/keep &&
		>sub/drop &&
		echo "sub/keep" >.gitcleanignore &&
		git clean -fd &&
		test_path_is_dir sub &&
		test_path_is_file sub/keep &&
		test_path_is_missing sub/drop &&
		rm -rf sub .gitcleanignore
	)
'

test_expect_success 'nested .gitcleanignore protects child with -fdx' '
	(
		cd cleanignore-tests &&
		mkdir -p sub &&
		>sub/keep &&
		>sub/drop &&
		echo "keep" >sub/.gitcleanignore &&
		git clean -fdx &&
		test_path_is_dir sub &&
		test_path_is_file sub/keep &&
		test_path_is_missing sub/drop &&
		test_path_is_file sub/.gitcleanignore &&
		rm -rf sub
	)
'

test_expect_success 'glob cleanignore pattern protects nested file with -fd' '
	(
		cd cleanignore-tests &&
		mkdir -p sub &&
		>sub/keep &&
		>sub/drop &&
		echo "sub/**/keep" >.gitcleanignore &&
		git clean -fd &&
		test_path_is_dir sub &&
		test_path_is_file sub/keep &&
		test_path_is_missing sub/drop &&
		rm -rf sub .gitcleanignore
	)
'

test_expect_success 'core.cleanExcludesFile protects descendant inside dir with -fd' '
	(
		cd cleanignore-tests &&
		mkdir -p sub &&
		>sub/keep &&
		>sub/drop &&
		echo "sub/keep" >"$TRASH_DIRECTORY/global_cleanignore" &&
		git -c core.cleanExcludesFile="$TRASH_DIRECTORY/global_cleanignore" clean -fd &&
		test_path_is_dir sub &&
		test_path_is_file sub/keep &&
		test_path_is_missing sub/drop &&
		rm -rf sub "$TRASH_DIRECTORY/global_cleanignore"
	)
'

test_expect_success 'cleanignore priority: per-directory overrides global' '
	(
		cd cleanignore-tests &&
		mkdir -p subdir &&
		>subdir/file.protect &&
		echo "file.protect" >"$TRASH_DIRECTORY/global_cleanignore" &&
		echo "!file.protect" >subdir/.gitcleanignore &&
		git -c core.cleanExcludesFile="$TRASH_DIRECTORY/global_cleanignore" clean -fd &&
		test_path_is_missing subdir/file.protect &&
		rm -rf subdir "$TRASH_DIRECTORY/global_cleanignore"
	)
'

test_expect_success 'top-level .gitcleanignore is never removed' '
	(
		cd cleanignore-tests &&
		>untracked_file &&
		echo "unrelated" >.gitcleanignore &&
		git clean -fdx &&
		test_path_is_missing untracked_file &&
		test_path_is_file .gitcleanignore &&
		rm -f .gitcleanignore
	)
'

test_expect_success 'negated cleanignore pattern re-exposes dir inside protected dir' '
	(
		cd cleanignore-tests &&
		mkdir -p protected_dir/tmp protected_dir/sub &&
		>protected_dir/file &&
		>protected_dir/sub/file &&
		>protected_dir/tmp/scratch &&
		cat >.gitcleanignore <<-\EOF &&
		protected_dir/
		!protected_dir/tmp/
		EOF
		git clean -fd &&
		test_path_is_missing protected_dir/tmp &&
		test_path_is_file protected_dir/file &&
		test_path_is_file protected_dir/sub/file &&
		rm -rf protected_dir .gitcleanignore
	)
'

test_expect_success 'global !**/node_modules removes node_modules under protected dir' '
	(
		cd cleanignore-tests &&
		mkdir -p wt/a/node_modules/pkg wt/b/node_modules &&
		>wt/a/node_modules/pkg/x.js &&
		>wt/a/src.js &&
		>wt/b/node_modules/y &&
		cat >"$TRASH_DIRECTORY/global_cleanignore" <<-\EOF &&
		wt/
		!**/node_modules
		EOF
		git -c core.cleanExcludesFile="$TRASH_DIRECTORY/global_cleanignore" clean -fdx >"$TRASH_DIRECTORY/out" &&
		test_path_is_missing wt/a/node_modules &&
		test_path_is_missing wt/b/node_modules &&
		test_path_is_file wt/a/src.js &&
		test_path_is_dir wt/b &&
		cat >"$TRASH_DIRECTORY/expect" <<-\EOF &&
		Removing wt/a/node_modules
		Removing wt/b/node_modules
		EOF
		test_cmp "$TRASH_DIRECTORY/expect" "$TRASH_DIRECTORY/out" &&
		rm -rf wt "$TRASH_DIRECTORY/global_cleanignore"
	)
'

test_expect_success 'protected dir emptied by negation is kept' '
	(
		cd cleanignore-tests &&
		mkdir -p keep/tmp &&
		>keep/tmp/f &&
		cat >.gitcleanignore <<-\EOF &&
		keep/
		!keep/tmp
		EOF
		git clean -fd &&
		test_path_is_dir keep &&
		test_path_is_missing keep/tmp &&
		rm -rf keep .gitcleanignore
	)
'

test_expect_success 'per-directory negation inside protected tree' '
	(
		cd cleanignore-tests &&
		mkdir -p wt/a/node_modules &&
		>wt/a/node_modules/x &&
		>wt/a/keep &&
		echo "wt/" >.gitcleanignore &&
		echo "!node_modules" >wt/a/.gitcleanignore &&
		git clean -fdx &&
		test_path_is_missing wt/a/node_modules &&
		test_path_is_file wt/a/keep &&
		test_path_is_file wt/a/.gitcleanignore &&
		rm -rf wt .gitcleanignore
	)
'

test_expect_success 'directory pattern protects descendants of partially tracked dir' '
	(
		cd cleanignore-tests &&
		mkdir -p a/b &&
		>a/tracked &&
		git add a/tracked &&
		>a/b/file &&
		>a/loose &&
		echo "a/" >.gitcleanignore &&
		git clean -fd &&
		test_path_is_file a/b/file &&
		test_path_is_file a/loose &&
		git rm -q --cached a/tracked &&
		rm -rf a .gitcleanignore
	)
'

test_expect_success 'negation inside nested repository needs -ff' '
	(
		cd cleanignore-tests &&
		mkdir -p wt &&
		git init -q wt/repo &&
		mkdir -p wt/repo/node_modules &&
		>wt/repo/node_modules/x &&
		>wt/repo/src &&
		cat >.gitcleanignore <<-\EOF &&
		wt/
		!**/node_modules
		EOF
		git clean -fdx &&
		test_path_is_file .gitcleanignore &&
		test_path_is_file wt/repo/node_modules/x &&
		git clean -ffdx &&
		test_path_is_missing wt/repo/node_modules &&
		test_path_is_file wt/repo/src &&
		test_path_is_dir wt/repo/.git &&
		rm -rf wt .gitcleanignore
	)
'

test_expect_success 'interactive clean skips protected candidates but applies nested negations' '
	(
		cd cleanignore-tests &&
		mkdir -p outer/keep/tmp prot &&
		>outer/keep/tmp/f &&
		>outer/keep/x &&
		>outer/y &&
		>prot/f &&
		cat >.gitcleanignore <<-\EOF &&
		outer/keep/
		!outer/keep/tmp/
		prot/
		EOF
		echo c | git clean -id &&
		test_path_is_file prot/f &&
		test_path_is_missing outer/y &&
		test_path_is_missing outer/keep/tmp &&
		test_path_is_file outer/keep/x &&
		rm -rf outer prot .gitcleanignore
	)
'

test_expect_success 'alternating protect/negate/protect along a path' '
	(
		cd cleanignore-tests &&
		mkdir -p a/b/c &&
		>a/other &&
		>a/b/x &&
		>a/b/c/y &&
		cat >.gitcleanignore <<-\EOF &&
		a/
		!a/b/
		a/b/c/
		EOF
		git clean -fd &&
		test_path_is_file a/other &&
		test_path_is_missing a/b/x &&
		test_path_is_file a/b/c/y &&
		rm -rf a .gitcleanignore
	)
'

test_expect_success 'direct match from lower-priority source beats inherited protection' '
	(
		cd cleanignore-tests &&
		mkdir -p wt/x &&
		>wt/x/foo.log &&
		>wt/x/bar &&
		echo "wt/" >.gitcleanignore &&
		echo "!wt/x/foo.log" >"$TRASH_DIRECTORY/global_cleanignore" &&
		git -c core.cleanExcludesFile="$TRASH_DIRECTORY/global_cleanignore" clean -fd &&
		test_path_is_missing wt/x/foo.log &&
		test_path_is_file wt/x/bar &&
		rm -rf wt .gitcleanignore "$TRASH_DIRECTORY/global_cleanignore"
	)
'

test_expect_success 'nested .gitcleanignore does not protect its ancestors or siblings' '
	(
		cd cleanignore-tests &&
		mkdir -p sub/inner sub/sibling &&
		>sub/keep &&
		>sub/sibling/keep &&
		>sub/inner/keep &&
		>sub/inner/drop &&
		echo "keep" >sub/inner/.gitcleanignore &&
		git clean -fd &&
		test_path_is_missing sub/keep &&
		test_path_is_missing sub/sibling &&
		test_path_is_file sub/inner/keep &&
		test_path_is_missing sub/inner/drop &&
		rm -rf sub
	)
'

test_expect_success SANITY 'protected unreadable empty directory is kept' '
	mkdir cleanignore-tests/foo &&
	chmod a= cleanignore-tests/foo &&
	echo "foo/" >cleanignore-tests/.gitcleanignore &&
	test_when_finished "chmod 755 cleanignore-tests/foo &&
			    rm -rf cleanignore-tests/foo cleanignore-tests/.gitcleanignore" &&
	git -C cleanignore-tests clean -ndfx >out &&
	! grep foo out &&
	git -C cleanignore-tests clean -dfx &&
	test_path_is_dir cleanignore-tests/foo
'

test_expect_success 'deeply nested negation with many per-directory frames' '
	(
		cd cleanignore-tests &&
		dir=deep &&
		for i in $(test_seq 1 30)
		do
			dir="$dir/level_$i" || exit 1
		done &&
		mkdir -p "$dir" &&
		>"$dir/drop" &&
		>"$dir/keep" &&
		echo "!drop" >"$dir/.gitcleanignore" &&
		echo "deep/" >.gitcleanignore &&
		git check-cleanignore -v "$dir/keep" >actual &&
		grep "^.gitcleanignore:1:deep/	" actual &&
		git clean -fd &&
		test_path_is_missing "$dir/drop" &&
		test_path_is_file "$dir/keep" &&
		rm -rf deep .gitcleanignore actual
	)
'

test_expect_success 'inherited protection with -X and negated subdirectory' '
	(
		cd cleanignore-tests &&
		mkdir -p logs/tmp &&
		>logs/a.log &&
		>logs/tmp/b.log &&
		>logs/keep.txt &&
		echo "*.log" >.gitignore &&
		cat >.gitcleanignore <<-\EOF &&
		logs/
		!logs/tmp/
		EOF
		git clean -fdX &&
		test_path_is_file logs/a.log &&
		test_path_is_missing logs/tmp/b.log &&
		test_path_is_file logs/keep.txt &&
		rm -rf logs .gitignore .gitcleanignore
	)
'

test_expect_success 'pathspec-limited clean from subdirectory honours negation' '
	(
		cd cleanignore-tests &&
		mkdir -p wt/a/node_modules wt/b/node_modules &&
		>wt/a/node_modules/x &&
		>wt/a/src &&
		>wt/b/node_modules/y &&
		cat >"$TRASH_DIRECTORY/global_cleanignore" <<-\EOF &&
		wt/
		!**/node_modules
		EOF
		(
			cd wt &&
			git -c core.cleanExcludesFile="$TRASH_DIRECTORY/global_cleanignore" clean -fdx a
		) &&
		test_path_is_missing wt/a/node_modules &&
		test_path_is_file wt/a/src &&
		test_path_is_file wt/b/node_modules/y &&
		rm -rf wt "$TRASH_DIRECTORY/global_cleanignore"
	)
'

test_expect_success 'anchored cleanignore rules apply to ../ pathspecs from a subdirectory' '
	(
		cd cleanignore-tests &&
		mkdir -p sub other &&
		>sub/tracked2 &&
		git add sub/tracked2 &&
		>other/keep &&
		>other/drop &&
		echo "/other/keep" >.git/info/cleanignore &&
		(
			cd sub &&
			git clean -fdx ../other
		) &&
		test_path_is_file other/keep &&
		test_path_is_missing other/drop &&
		git rm -q --cached sub/tracked2 &&
		rm -rf sub other .git/info/cleanignore
	)
'

test_expect_success SYMLINKS 'negated symlink is unlinked without touching its target' '
	(
		cd cleanignore-tests &&
		mkdir -p wt/a target &&
		>target/f &&
		ln -s ../../target wt/a/node_modules &&
		cat >.gitcleanignore <<-\EOF &&
		wt/
		target/
		!**/node_modules
		EOF
		git clean -fdx &&
		test_path_is_missing wt/a/node_modules &&
		test_path_is_file target/f &&
		test_path_is_dir wt/a &&
		rm -rf wt target .gitcleanignore
	)
'

test_done
