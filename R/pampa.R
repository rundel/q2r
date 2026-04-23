#' @include from-rust.R diagnostic.R pd-ast-pandoc.R ts-ast.R
NULL

pampa_read_input = function(input) {
  stopifnot(is.character(input), length(input) == 1L, !is.na(input))
  is_text = grepl("\n", input, fixed = TRUE)
  if (!is_text && file.exists(input) && !dir.exists(input)) {
    list(
      text     = paste(readLines(input, warn = FALSE), collapse = "\n"),
      filename = basename(input)
    )
  } else {
    list(text = input, filename = "<text>")
  }
}

pampa_diagnostics_from_raw = function(raw, text, filename) {
  lapply(
    raw$diagnostics %||% list(),
    diagnostic_from_list,
    source_text = text,
    source_filename = filename
  )
}

#' Parse QMD input with pampa and return the Pandoc AST
#'
#' @param input A single string. Treated as a file path if it does not
#'   contain newlines and `file.exists()` returns TRUE; otherwise
#'   treated as raw text.
#' @return A [`pandoc`] object with any parse diagnostics attached in
#'   its `@diagnostics` slot. If pampa fails to produce a Pandoc AST the
#'   returned object has an empty `@blocks`; the diagnostics explain why.
#' @export
pampa_parse_pd = function(input) {
  src = pampa_read_input(input)
  raw = pampa_parse_pd_impl(src$text, src$filename)
  diagnostics = pampa_diagnostics_from_raw(raw, src$text, src$filename)

  doc = if (is.null(raw$pd_ast)) pandoc() else pandoc_from_list(raw$pd_ast)
  doc@diagnostics = diagnostics
  doc
}

#' Parse QMD input with tree-sitter and return the tree-sitter AST
#'
#' @param input A single string. Treated as a file path if it does not
#'   contain newlines and `file.exists()` returns TRUE; otherwise
#'   treated as raw text.
#' @return A [`ts_tree`] object with any parse diagnostics attached in
#'   its `@diagnostics` slot. Tree-sitter parsing itself never fails;
#'   the diagnostics surface higher-level pampa errors.
#' @export
pampa_parse_ts = function(input) {
  src = pampa_read_input(input)
  raw = pampa_parse_ts_impl(src$text, src$filename)
  diagnostics = pampa_diagnostics_from_raw(raw, src$text, src$filename)

  tree = ts_tree_from_list(raw$ts_ast)
  tree@diagnostics = diagnostics
  tree
}

#' Dump pampa's raw tree-sitter tree for QMD input
#'
#' Test helper that returns the `print_whole_tree` lines pampa emits
#' when run with `-v`. Use [`pampa_parse_ts()`] for a structured AST.
#'
#' @param input A single string, handled like [`pampa_parse_pd()`].
#' @return A character vector of lines.
#' @export
pampa_tree = function(input) {
  src = pampa_read_input(input)
  pampa_tree_impl(src$text, src$filename)
}

#' Render QMD input to Pandoc native AST text
#'
#' Test helper that returns pampa's native-format rendering of the
#' parsed document.
#'
#' @param input A single string, handled like [`pampa_parse_pd()`].
#' @return A character vector of lines (empty if parsing failed).
#' @export
pampa_native = function(input) {
  src = pampa_read_input(input)
  pampa_native_impl(src$text, src$filename)
}
