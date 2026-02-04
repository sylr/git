/*
 * "git check-cleanignore" builtin command
 *
 * Based on builtin/check-ignore.c
 */
#define USE_THE_REPOSITORY_VARIABLE
#include "builtin.h"
#include "config.h"
#include "dir.h"
#include "environment.h"
#include "gettext.h"
#include "quote.h"
#include "pathspec.h"
#include "parse-options.h"
#include "submodule.h"
#include "write-or-die.h"

static int quiet, verbose, stdin_paths, show_non_matching, no_index;
static const char * const check_cleanignore_usage[] = {
	N_("git check-cleanignore [<options>] <pathname>..."),
	N_("git check-cleanignore [<options>] --stdin"),
	NULL
};

static int nul_term_line;

static const struct option check_cleanignore_options[] = {
	OPT__QUIET(&quiet, N_("suppress progress reporting")),
	OPT__VERBOSE(&verbose, N_("be verbose")),
	OPT_GROUP(""),
	OPT_BOOL(0, "stdin", &stdin_paths,
		 N_("read file names from stdin")),
	OPT_BOOL('z', NULL, &nul_term_line,
		 N_("terminate input and output records by a NUL character")),
	OPT_BOOL('n', "non-matching", &show_non_matching,
		 N_("show non-matching input paths")),
	OPT_BOOL(0, "no-index", &no_index,
		 N_("ignore index when checking")),
	OPT_END()
};

static void output_pattern(const char *path, struct path_pattern *pattern)
{
	const char *bang = (pattern && pattern->flags & PATTERN_FLAG_NEGATIVE) ? "!" : "";
	const char *slash = (pattern && pattern->flags & PATTERN_FLAG_MUSTBEDIR) ? "/" : "";

	if (!nul_term_line) {
		if (!verbose) {
			write_name_quoted(path, stdout, '\n');
		} else {
			if (pattern) {
				quote_c_style(pattern->pl->src, NULL, stdout, 0);
				printf(":%d:%s%s%s\t",
				       pattern->srcpos,
				       bang, pattern->pattern, slash);
			} else {
				printf("::\t");
			}
			quote_c_style(path, NULL, stdout, 0);
			fputc('\n', stdout);
		}
	} else {
		if (!verbose) {
			printf("%s%c", path, '\0');
		} else {
			if (pattern)
				printf("%s%c%d%c%s%s%s%c%s%c",
				       pattern->pl->src, '\0',
				       pattern->srcpos, '\0',
				       bang, pattern->pattern, slash, '\0',
				       path, '\0');
			else
				printf("%c%c%c%s%c", '\0', '\0', '\0', path, '\0');
		}
	}
}

/*
 * Return the matching cleanignore pattern for a path, or NULL if not protected.
 * This is similar to last_matching_pattern() but for cleanignore.
 */
static struct path_pattern *last_matching_cleanignore_pattern_for_path(
		struct cleanignore_struct *ci,
		struct index_state *istate,
		const char *pathname,
		int *dtype)
{
	struct path_pattern *pattern;
	int pathlen = strlen(pathname);
	const char *basename;
	const char *p;

	/* Strip trailing slash for matching (directories come with trailing /) */
	if (pathlen > 0 && pathname[pathlen - 1] == '/')
		pathlen--;

	/* Find the last slash before pathlen */
	basename = NULL;
	for (p = pathname; p < pathname + pathlen; p++) {
		if (*p == '/')
			basename = p;
	}
	basename = basename ? basename + 1 : pathname;

	prep_cleanignore(ci, istate, pathname, basename - pathname);

	pattern = last_matching_cleanignore_pattern(ci, istate,
						    pathname, pathlen,
						    basename, dtype);
	return pattern;
}

static int check_cleanignore(struct cleanignore_struct *ci,
			     const char *prefix, int argc, const char **argv)
{
	const char *full_path;
	char *seen;
	int num_protected = 0, i;
	struct path_pattern *pattern;
	struct pathspec pathspec;

	if (!argc) {
		if (!quiet)
			fprintf(stderr, "no pathspec given.\n");
		return 0;
	}

	/*
	 * check-cleanignore just needs paths. Magic beyond :/ is really
	 * irrelevant.
	 */
	parse_pathspec(&pathspec,
		       PATHSPEC_ALL_MAGIC & ~PATHSPEC_FROMTOP,
		       PATHSPEC_SYMLINK_LEADING_PATH |
		       PATHSPEC_KEEP_ORDER,
		       prefix, argv);

	die_path_inside_submodule(the_repository->index, &pathspec);

	/*
	 * Unlike check-ignore, we don't skip paths that are in the index
	 * because cleanignore is specifically about protecting untracked files.
	 * However, we still use the index to check for submodules.
	 */
	seen = find_pathspecs_matching_against_index(&pathspec, the_repository->index,
						     PS_HEED_SKIP_WORKTREE);
	for (i = 0; i < pathspec.nr; i++) {
		int dtype = DT_UNKNOWN;
		full_path = pathspec.items[i].match;
		pattern = last_matching_cleanignore_pattern_for_path(ci,
				the_repository->index, full_path, &dtype);
		if (!verbose && pattern &&
		    pattern->flags & PATTERN_FLAG_NEGATIVE)
			pattern = NULL;
		if (!quiet && (pattern || show_non_matching))
			output_pattern(pathspec.items[i].original, pattern);
		if (pattern)
			num_protected++;
	}
	free(seen);
	clear_pathspec(&pathspec);

	return num_protected;
}

static int check_cleanignore_stdin_paths(struct cleanignore_struct *ci,
					 const char *prefix)
{
	struct strbuf buf = STRBUF_INIT;
	struct strbuf unquoted = STRBUF_INIT;
	char *pathspec[2] = { NULL, NULL };
	strbuf_getline_fn getline_fn;
	int num_protected = 0;

	getline_fn = nul_term_line ? strbuf_getline_nul : strbuf_getline_lf;
	while (getline_fn(&buf, stdin) != EOF) {
		if (!nul_term_line && buf.buf[0] == '"') {
			strbuf_reset(&unquoted);
			if (unquote_c_style(&unquoted, buf.buf, NULL))
				die("line is badly quoted");
			strbuf_swap(&buf, &unquoted);
		}
		pathspec[0] = buf.buf;
		num_protected += check_cleanignore(ci, prefix,
						   1, (const char **)pathspec);
		maybe_flush_or_die(stdout, "check-cleanignore to stdout");
	}
	strbuf_release(&buf);
	strbuf_release(&unquoted);
	return num_protected;
}

int cmd_check_cleanignore(int argc,
			  const char **argv,
			  const char *prefix,
			  struct repository *repo UNUSED)
{
	int num_protected;
	struct cleanignore_struct cleanignore = CLEANIGNORE_INIT;

	repo_config(the_repository, git_default_config, NULL);

	argc = parse_options(argc, argv, prefix, check_cleanignore_options,
			     check_cleanignore_usage, 0);

	if (stdin_paths) {
		if (argc > 0)
			die(_("cannot specify pathnames with --stdin"));
	} else {
		if (nul_term_line)
			die(_("-z only makes sense with --stdin"));
		if (argc == 0)
			die(_("no path specified"));
	}
	if (quiet) {
		if (argc > 1)
			die(_("--quiet is only valid with a single pathname"));
		if (verbose)
			die(_("cannot have both --quiet and --verbose"));
	}
	if (show_non_matching && !verbose)
		die(_("--non-matching is only valid with --verbose"));

	/* read_cache() is only necessary so we can watch out for submodules. */
	if (!no_index && repo_read_index(the_repository) < 0)
		die(_("index file corrupt"));

	setup_cleanignore(&cleanignore);

	if (stdin_paths) {
		num_protected = check_cleanignore_stdin_paths(&cleanignore,
							      prefix);
	} else {
		num_protected = check_cleanignore(&cleanignore, prefix,
						  argc, argv);
		maybe_flush_or_die(stdout, "check-cleanignore to stdout");
	}

	cleanignore_clear(&cleanignore);

	return !num_protected;
}
