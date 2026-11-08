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
		test_grep "^.gitcleanignore:1:protected.txt	protected.txt$" actual
	)
'

test_expect_success 'check-cleanignore verbose mode with non-matching' '
	(
		cd repo &&
		echo "protected.txt" >.gitcleanignore &&
		git check-cleanignore -v -n other.txt protected.txt >actual &&
		test_grep "^::	other.txt$" actual &&
		test_grep "^.gitcleanignore:1:protected.txt	protected.txt$" actual
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

test_expect_success 'check-cleanignore reports inherited directory protection' '
	(
		cd repo &&
		echo "protected_dir/" >.gitcleanignore &&
		mkdir -p protected_dir/sub &&
		git check-cleanignore -v protected_dir/sub/file >actual &&
		echo ".gitcleanignore:1:protected_dir/	protected_dir/sub/file" >expect &&
		test_cmp expect actual
	)
'

test_expect_success 'check-cleanignore negation inside protected directory' '
	(
		cd repo &&
		cat >.gitcleanignore <<-\EOF &&
		protected_dir/
		!protected_dir/tmp
		EOF
		mkdir -p protected_dir/tmp &&
		test_must_fail git check-cleanignore protected_dir/tmp >actual &&
		test_must_be_empty actual &&
		test_must_fail git check-cleanignore protected_dir/tmp/x &&
		git check-cleanignore -v protected_dir/tmp protected_dir/tmp/x protected_dir/a >actual &&
		cat >expect <<-\EOF &&
		.gitcleanignore:2:!protected_dir/tmp	protected_dir/tmp
		.gitcleanignore:2:!protected_dir/tmp	protected_dir/tmp/x
		.gitcleanignore:1:protected_dir/	protected_dir/a
		EOF
		test_cmp expect actual &&
		printf "protected_dir/a\nprotected_dir/tmp/x\nother\n" |
		git check-cleanignore --stdin >actual &&
		echo "protected_dir/a" >expect &&
		test_cmp expect actual
	)
'

test_expect_success 'check-cleanignore skips tracked paths unless --no-index' '
	(
		cd repo &&
		echo "tracked_file" >.gitcleanignore &&
		test_must_fail git check-cleanignore tracked_file &&
		test_expect_code 1 git check-cleanignore -v -n tracked_file >actual &&
		echo "::	tracked_file" >expect &&
		test_cmp expect actual &&
		git check-cleanignore --no-index tracked_file >actual &&
		echo "tracked_file" >expect &&
		test_cmp expect actual
	)
'

test_expect_success 'check-cleanignore: nested file does not protect ancestors or siblings' '
	(
		cd repo &&
		rm -f .gitcleanignore &&
		mkdir -p sub/inner sub/sibling &&
		echo "keep" >sub/inner/.gitcleanignore &&
		test_must_fail git check-cleanignore sub/keep &&
		test_must_fail git check-cleanignore sub/sibling/keep &&
		git check-cleanignore sub/inner/keep sub/inner/deeper/keep >actual &&
		cat >expect <<-\EOF &&
		sub/inner/keep
		sub/inner/deeper/keep
		EOF
		test_cmp expect actual &&
		printf "sub/inner/keep\nsub/keep\nsub/sibling/keep\nsub/inner/keep\n" |
		git check-cleanignore --stdin >actual &&
		cat >expect <<-\EOF &&
		sub/inner/keep
		sub/inner/keep
		EOF
		test_cmp expect actual
	)
'

test_expect_success 'check-cleanignore -v shows negations without claiming protection' '
	(
		cd repo &&
		cat >.gitcleanignore <<-\EOF &&
		*.tmp
		!important.tmp
		EOF
		test_expect_code 1 git check-cleanignore -v important.tmp >actual &&
		echo ".gitcleanignore:2:!important.tmp	important.tmp" >expect &&
		test_cmp expect actual &&
		test_expect_code 1 git check-cleanignore -v -n important.tmp other >actual &&
		cat >expect <<-\EOF &&
		.gitcleanignore:2:!important.tmp	important.tmp
		::	other
		EOF
		test_cmp expect actual &&
		git check-cleanignore -v important.tmp file.tmp >actual &&
		test_line_count = 2 actual
	)
'

test_expect_success 'check-cleanignore -z --stdin' '
	(
		cd repo &&
		echo "protected.txt" >.gitcleanignore &&
		printf "%s\0%s\0" protected.txt other.txt |
		git check-cleanignore -z --stdin >actual &&
		printf "%s\0" protected.txt >expect &&
		test_cmp expect actual &&
		printf "%s\0" protected.txt |
		git check-cleanignore -z -v --stdin >actual &&
		printf "%s\0%s\0%s\0%s\0" .gitcleanignore 1 protected.txt protected.txt >expect &&
		test_cmp expect actual
	)
'

test_expect_success 'check-cleanignore rejects invalid option combinations' '
	(
		cd repo &&
		test_must_fail git check-cleanignore -q a b &&
		test_must_fail git check-cleanignore -q -v a &&
		test_must_fail git check-cleanignore -n a &&
		test_must_fail git check-cleanignore -z a &&
		test_must_fail git check-cleanignore --stdin a </dev/null &&
		test_must_fail git check-cleanignore
	)
'

test_done
