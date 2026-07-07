#' @include pd-ast-pandoc.R select.R select-pd.R ast-summary.R pd-ast-print.R pampa.R io.R table.R
NULL

#' A collection of QMD documents
#'
#' `r lifecycle::badge("experimental")`
#'
#' `qmd_collection` is a lightweight container holding several parsed
#' [`pandoc`] documents, modeled on parsermd's document collections. It
#' lets you parse a directory of `.qmd` files once and then run the same
#' selection and rewriting verbs across every document in a single pipe.
#'
#' The selection and mutation verbs from [`select_nodes()`] dispatch on a
#' collection:
#'
#' - Selection verbs (`select_nodes`, `select_descendants`,
#'   `select_children`, `select_first`) map over the documents and return
#'   a named list of per-document results (so you keep track of which
#'   document each match came from).
#' - Mutation verbs (`map_nodes`, `replace_nodes`, `delete_nodes`,
#'   `splice_nodes`, `insert_before`, `insert_after`) rewrite every
#'   document and return a new `qmd_collection`.
#' - `walk_nodes` applies a side effect to every document and returns the
#'   collection invisibly.
#' - [`ast_summary()`] returns a combined `data.frame` with a leading
#'   `doc` column naming the source document, and [`as_df()`] returns a
#'   per-document named list of its tables.
#'
#' The document-level helpers ([`ast_sections()`], [`ast_toc()`],
#' [`select_section()`], [`split_sections()`], [`ast_filter()`]) are
#' *not* collection-aware; map them over `@docs` yourself.
#'
#' @param dir For `parse_qmd_dir()`, the directory to scan. For
#'   `write_qmd_dir()`, the destination directory; `NULL` (the default)
#'   writes each document back to the path it was read from.
#' @param pattern A regular expression selecting files (default
#'   `"\\.qmd$"`).
#' @param recurse Whether to descend into subdirectories.
#' @param quiet Suppress per-file diagnostic signaling (default `TRUE`;
#'   diagnostics are still attached to each document's `@diagnostics`).
#' @param prune_errors Passed to [`parse_qmd()`].
#' @param force For `write_qmd_dir()`, write even when some documents in
#'   the collection carry error-kind parse diagnostics. By default the
#'   write aborts before touching any file, because writing an
#'   error-parsed document replaces whatever pampa could not parse with
#'   the partial AST it recovered.
#' @param x A `qmd_collection`.
#' @param docs For the `qmd_collection()` constructor, a named list of
#'   parsed [`pandoc`] documents.
#' @param paths For the constructor, the source file path of each
#'   document (same length as `docs`).
#' @return `parse_qmd_dir()` returns a `qmd_collection`. `write_qmd_dir()`
#'   returns its input invisibly.
#'
#' @examples
#' \dontrun{
#' coll = parse_qmd_dir("docs", pattern = "\\.qmd$")
#' coll |>
#'   map_nodes(is(pandoc_header), .f = \(h) add_class(h, "tagged")) |>
#'   write_qmd_dir("docs-tagged")
#' ast_summary(coll)
#' }
#'
#' @name qmd_collection
NULL

#' @rdname qmd_collection
#' @export
qmd_collection = S7::new_class(
  "qmd_collection",
  package = "q2r",
  properties = list(
    docs  = S7::new_property(S7::class_list, default = list()),
    paths = S7::new_property(S7::class_character, default = character(0))
  ),
  validator = function(self) {
    msg = validate_list_of(self@docs, pandoc, "@docs must be a list of pandoc objects")
    if (!is.null(msg)) return(msg)
    if (length(self@paths) != length(self@docs)) {
      "@paths must be the same length as @docs"
    }
  }
)

#' @rdname qmd_collection
#' @export
parse_qmd_dir = function(dir = ".", pattern = "\\.qmd$", recurse = TRUE,
                         quiet = TRUE, prune_errors = TRUE) {
  if (!dir.exists(dir)) {
    stop("`parse_qmd_dir()`: directory not found: ", dir, call. = FALSE)
  }
  rel = list.files(dir, pattern = pattern, recursive = recurse, full.names = FALSE)
  # Non-recursive list.files() also returns directories; a directory whose
  # name matches the pattern must not be handed to parse_qmd (its heuristic
  # would parse the directory name as literal text).
  rel = rel[!dir.exists(file.path(dir, rel))]
  abs = file.path(dir, rel)
  docs = purrr::map(abs, parse_qmd, quiet = quiet, prune_errors = prune_errors)
  names(docs) = rel
  qmd_collection(docs = docs, paths = abs)
}

#' @rdname qmd_collection
#' @export
write_qmd_dir = function(x, dir = NULL, force = FALSE) {
  if (!S7::S7_inherits(x, qmd_collection)) {
    stop("`write_qmd_dir()`: `x` must be a qmd_collection.", call. = FALSE)
  }
  if (!isTRUE(force)) {
    bad = purrr::map_lgl(x@docs, has_error_diagnostics)
    if (any(bad)) {
      bad_names = (names(x@docs) %||% basename(x@paths))[bad]
      cli::cli_abort(c(
        "{sum(bad)} document{?s} in the collection had parse errors: {.file {bad_names}}",
        "x" = "Writing would replace the unparseable source content with the partial AST pampa recovered.",
        "i" = "Fix the source and re-parse, or pass {.code force = TRUE} to write anyway."
      ))
    }
  }
  targets = if (is.null(dir)) {
    x@paths
  } else {
    file.path(dir, names(x@docs) %||% basename(x@paths))
  }
  dup = unique(targets[duplicated(targets)])
  if (length(dup)) {
    cli::cli_abort(c(
      "several documents in the collection resolve to the same target file: {.file {dup}}",
      "i" = "Give the collection unique document names before writing to a new directory."
    ))
  }
  purrr::walk2(x@docs, targets, function(d, path) {
    pdir = dirname(path)
    if (!dir.exists(pdir)) dir.create(pdir, recursive = TRUE)
    # The collection-level guard above already vetted (or force-overrode)
    # error-parsed docs; skip write_qmd's per-document re-check.
    write_qmd(d, path, force = TRUE)
  })
  invisible(x)
}


S7::method(print, qmd_collection) = function(x, ...) {
  n = length(x@docs)
  cat(cli::format_inline("<qmd_collection: {n} document{?s}>\n"))
  docs = x@docs
  if (is.null(names(docs))) names(docs) = paste0("[", seq_len(n), "]")
  lines = purrr::imap_chr(docs, function(d, nm) {
    nb = length(d@blocks@content)
    nd = length(d@diagnostics)
    diag = if (nd) cli::format_inline(", {nd} diagnostic{?s}") else ""
    cli::format_inline("  {nm} ({nb} block{?s}{diag})\n")
  })
  cat(lines, sep = "")
  invisible(x)
}


# Map a per-document query (returns a named list) or rewrite (returns a
# new collection). The closures passed in close over the calling verb's
# `...`/`.f`/`.with`/`.what`, so predicate expressions forward unevaluated.
coll_query = function(x, f) purrr::map(x@docs, f)

coll_rewrite = function(x, f) {
  qmd_collection(docs = purrr::map(x@docs, f), paths = x@paths)
}


S7::method(select_nodes, qmd_collection) = function(x, ...) {
  coll_query(x, function(d) select_nodes(d, ...))
}

S7::method(select_descendants, qmd_collection) = function(x, ...) {
  coll_query(x, function(d) select_descendants(d, ...))
}

S7::method(select_children, qmd_collection) = function(x, ...) {
  coll_query(x, function(d) select_children(d, ...))
}

S7::method(select_first, qmd_collection) = function(x, ...) {
  coll_query(x, function(d) select_first(d, ...))
}

S7::method(walk_nodes, qmd_collection) = function(x, ..., .f = NULL) {
  purrr::walk(x@docs, function(d) walk_nodes(d, ..., .f = .f))
  invisible(x)
}

S7::method(map_nodes, qmd_collection) = function(x, ..., .f = NULL) {
  coll_rewrite(x, function(d) map_nodes(d, ..., .f = .f))
}

S7::method(replace_nodes, qmd_collection) = function(x, ..., .with = NULL) {
  coll_rewrite(x, function(d) replace_nodes(d, ..., .with = .with))
}

S7::method(delete_nodes, qmd_collection) = function(x, ...) {
  coll_rewrite(x, function(d) delete_nodes(d, ...))
}

S7::method(splice_nodes, qmd_collection) = function(x, ..., .f = NULL) {
  coll_rewrite(x, function(d) splice_nodes(d, ..., .f = .f))
}

S7::method(insert_before, qmd_collection) = function(x, ..., .what = NULL) {
  coll_rewrite(x, function(d) insert_before(d, ..., .what = .what))
}

S7::method(insert_after, qmd_collection) = function(x, ..., .what = NULL) {
  coll_rewrite(x, function(d) insert_after(d, ..., .what = .what))
}

S7::method(as_df, qmd_collection) = function(x) {
  purrr::map(x@docs, as_df)
}

S7::method(ast_summary, qmd_collection) = function(x, max_text = 40L) {
  parts = purrr::imap(x@docs, function(d, nm) {
    s = ast_summary(d, max_text = max_text)
    if (nrow(s) == 0L) return(NULL)
    s$doc = nm
    s[c("doc", setdiff(names(s), "doc"))]
  })
  parts = purrr::compact(parts)
  if (length(parts) == 0L) {
    base = ast_summary(list(), max_text = max_text)
    base$doc = character(0)
    return(base[c("doc", setdiff(names(base), "doc"))])
  }
  out = do.call(rbind, parts)
  rownames(out) = NULL
  out
}
