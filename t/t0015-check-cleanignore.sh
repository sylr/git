#!/bin/sh

test_description='git check-cleanignore tests'

. ./test-lib.sh

test_expect_success 'setup' '
	git init repo &&
	(
		cd repo &&
		>tracked_file &&
		git add tracked_file &&
		git commit -m "initial commit"
	)
'

test_expect_success 'check-cleanignore with no cleanignore files' '
	(
		cd repo &&
		test_must_fail git check-cleanignore untracked_file
	)
'

test_expect_success 'check-cleanignore with matching pattern' '
	(
		cd repo &&
		echo "protected.txt" >.gitcleanignore &&
		git check-cleanignore protected.txt >actual &&
		echo "protected.txt" >expect &&
		test_cmp expect actual
	)
'

test_expect_success 'check-cleanignore with non-matching pattern' '
	(
		cd repo &&
		echo "protected.txt" >.gitcleanignore &&
		test_must_fail git check-cleanignore other.txt
	)
'

test_expect_success 'check-cleanignore with wildcard pattern' '
	(
		cd repo &&
		echo "*.keep" >.gitcleanignore &&
		git check-cleanignore file.keep other.keep >actual &&
		cat >expect <<-\EOF &&
		file.keep
		other.keep
		EOF
		test_cmp expect actual
	)
'

test_expect_success 'check-cleanignore verbose mode' '
	(
		cd repo &&
		echo "protected.txt" >.gitcleanignore &&
		git check-cleanignore -v protected.txt >actual &&
		grep "^.gitcleanignore:1:protected.txt	protected.txt$" actual
	)
'

test_expect_success 'check-cleanignore verbose mode with non-matching' '
	(
		cd repo &&
		echo "protected.txt" >.gitcleanignore &&
		git check-cleanignore -v -n other.txt protected.txt >actual &&
		grep "^::	other.txt$" actual &&
		grep "^.gitcleanignore:1:protected.txt	protected.txt$" actual
	)
'

test_expect_success 'check-cleanignore with directory pattern' '
	(
		cd repo &&
		echo "protected_dir/" >.gitcleanignore &&
		mkdir -p protected_dir &&
		git check-cleanignore protected_dir/ >actual &&
		echo "protected_dir/" >expect &&
		test_cmp expect actual
	)
'

test_expect_success 'check-cleanignore with negation pattern' '
	(
		cd repo &&
		cat >.gitcleanignore <<-\EOF &&
		*.tmp
		!important.tmp
		EOF
		git check-cleanignore file.tmp >actual &&
		echo "file.tmp" >expect &&
		test_cmp expect actual &&
		test_must_fail git check-cleanignore important.tmp
	)
'

test_expect_success 'check-cleanignore with stdin' '
	(
		cd repo &&
		echo "protected.txt" >.gitcleanignore &&
		echo "protected.txt" | git check-cleanignore --stdin >actual &&
		echo "protected.txt" >expect &&
		test_cmp expect actual
	)
'

test_expect_success 'check-cleanignore quiet mode with match' '
	(
		cd repo &&
		echo "protected.txt" >.gitcleanignore &&
		git check-cleanignore -q protected.txt >actual &&
		test_must_be_empty actual
	)
'

test_expect_success 'check-cleanignore quiet mode without match' '
	(
		cd repo &&
		echo "protected.txt" >.gitcleanignore &&
		test_must_fail git check-cleanignore -q other.txt
	)
'

test_expect_success 'check-cleanignore with .git/info/cleanignore' '
	(
		cd repo &&
		rm -f .gitcleanignore &&
		mkdir -p .git/info &&
		echo "repo_protected.txt" >.git/info/cleanignore &&
		git check-cleanignore repo_protected.txt >actual &&
		echo "repo_protected.txt" >expect &&
		test_cmp expect actual &&
		rm -f .git/info/cleanignore
	)
'

test_expect_success 'check-cleanignore multiple files' '
	(
		cd repo &&
		cat >.gitcleanignore <<-\EOF &&
		file1.txt
		file2.txt
		EOF
		git check-cleanignore file1.txt file2.txt file3.txt >actual &&
		cat >expect <<-\EOF &&
		file1.txt
		file2.txt
		EOF
		test_cmp expect actual
	)
'

test_done
