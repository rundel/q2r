#' @include result.R from-rust.R diagnostic.R
NULL

#' Parse QMD input with pampa
#'
#' @param input A single string. Treated as a file path if it does not
#'   contain newlines and `file.exists()` returns TRUE; otherwise treated
#'   as raw text.
#' @param format Which artifacts to populate on the returned
#'   [`pampa_result`]. One of `"pd_ast"` (S7 Pandoc AST, default),
#'   `"tree"` (tree-sitter AST text), `"ts_ast"` (structured tree-sitter
#'   AST as an S7 `ts_tree`), `"native"` (Pandoc native AST text), or
#'   `"all"` (all of the above). Diagnostics are always included.
#' @return A [`pampa_result`] with the requested slots populated.
#'   Pretty-printed diagnostic output is produced on demand by the
#'   `print()` / `format()` methods on [`pampa_diagnostic`].
#' @export
pampa_parse = function(input, format = c("pd_ast", "tree", "ts_ast", "native", "all")) {
  stopifnot(is.character(input), length(input) == 1L, !is.na(input))
  format = match.arg(format)

  is_text = grepl("\n", input, fixed = TRUE)
  if (!is_text && file.exists(input) && !dir.exists(input)) {
    text = paste(readLines(input, warn = FALSE), collapse = "\n")
    filename = basename(input)
  } else {
    text = input
    filename = "<text>"
  }

  raw = pampa_parse_impl(text, filename)

  diagnostics = lapply(
    raw$diagnostics %||% list(),
    diagnostic_from_list,
    source_text = text,
    source_filename = filename
  )

  pampa_result(
    pd_ast      = if (format %in% c("pd_ast", "all")) pandoc_from_list(raw$pd_ast),
    tree        = if (format %in% c("tree", "all")) raw$tree,
    ts_ast      = if (format %in% c("ts_ast", "all")) ts_tree_from_list(raw$ts_ast),
    native      = if (format %in% c("native", "all")) raw$native,
    diagnostics = diagnostics
  )
}
