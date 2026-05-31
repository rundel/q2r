#' @include ts-ast.R pampa.R from-rust.R
NULL

#' Run a tree-sitter `.scm` query against QMD source
#'
#' `r lifecycle::badge("experimental")`
#'
#' Power-user escape hatch alongside [`select_nodes()`]. Compiles
#' `query_text` against the tree-sitter-qmd grammar and returns one
#' entry per match, with captures keyed by name.
#'
#' This bypasses the tidyselect-style mask entirely; use [`select_nodes()`]
#' if a CSS/predicate query is enough. `ts_query()` is the right tool when
#' you need full structural pattern matching, captures, or predicates
#' (`#eq?`, `#match?`, ...) from the tree-sitter query language.
#'
#' @param input Either a [`ts_tree`] (re-renders to QMD via [`to_qmd()`]
#'   then re-parses), a single string treated as text/file path (per
#'   [`pampa_parse()`]'s rules), or raw text.
#' @param query_text A tree-sitter query string (S-expression form).
#'   See <https://github.com/quarto-dev/q2/tree/main/crates/tree-sitter-qmd/tree-sitter-markdown/queries/>
#'   for live examples.
#' @return A list with one element per match. Each match is itself a
#'   named list whose names are the capture identifiers in `query_text`
#'   and whose values are [`ts_node`] objects. Returns `list()` when no
#'   matches are found.
#' @examples
#' \dontrun{
#' ts = pampa_parse("# Heading\n\nbody\n", ast = "ts")
#' ts_query(ts, "(atx_heading) @h")
#' }
#' @export
ts_query = function(input, query_text) {
  stopifnot(is.character(query_text), length(query_text) == 1L, !is.na(query_text))

  text = if (S7::S7_inherits(input, ts_tree)) {
    to_qmd(input)
  } else if (is.character(input) && length(input) == 1L && !is.na(input)) {
    pampa_read_input(input)$text
  } else {
    stop("ts_query(): input must be a ts_tree, a string, or a file path",
         call. = FALSE)
  }

  raw = ts_query_impl(text, query_text)
  if (!is.null(raw$error)) {
    stop("ts_query(): query compilation failed: ", raw$error, call. = FALSE)
  }

  purrr::map(raw$matches %||% list(), function(m) {
    purrr::map(m, ts_node_from_list)
  })
}
