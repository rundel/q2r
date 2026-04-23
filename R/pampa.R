#' @include result.R from-rust.R
NULL

#' Parse QMD input with pampa
#'
#' @param input A single string. Treated as a file path if it does not
#'   contain newlines and `file.exists()` returns TRUE; otherwise treated
#'   as raw text.
#' @param format Which artifacts to populate on the returned
#'   [`pampa_result`]. One of `"ast"` (S7 Pandoc AST, default), `"tree"`
#'   (tree-sitter concrete syntax tree text), `"cst"` (structured
#'   tree-sitter CST as an S7 `ts_tree`), `"native"` (Pandoc native
#'   AST text), or `"all"` (all of the above). Diagnostics are always
#'   included.
#' @return A [`pampa_result`] with the requested slots populated.
#' @export
pampa_parse = function(input, format = c("ast", "tree", "cst", "native", "all")) {
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

  pampa_result(
    ast         = if (format %in% c("ast", "all")) pandoc_from_list(raw$ast),
    tree        = if (format %in% c("tree", "all")) raw$tree,
    cst         = if (format %in% c("cst", "all")) ts_tree_from_list(raw$cst),
    native      = if (format %in% c("native", "all")) raw$native,
    diagnostics = raw$diagnostics %||% character()
  )
}
