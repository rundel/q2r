#' @include from-rust.R to-rust.R diagnostic.R pd-ast-pandoc.R ts-ast.R
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
#' @param input Either a single string (treated as a file path if it
#'   does not contain newlines and `file.exists()` returns TRUE, else as
#'   raw text) or a [`ts_tree`] object. For a `ts_tree`, the tree is
#'   rendered to QMD via [`to_qmd()`] and re-parsed; this exercises the
#'   full ts -> Pandoc pipeline on an R-held AST.
#' @return A [`pandoc`] object with any parse diagnostics attached in
#'   its `@diagnostics` slot. If pampa fails to produce a Pandoc AST the
#'   returned object has an empty `@blocks`; the diagnostics explain why.
#' @export
pampa_parse_pd = function(input) {
  if (S7::S7_inherits(input, ts_tree)) input = to_qmd(input)
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

#' Render QMD through pampa's own QMD writer
#'
#' Testing helper that invokes `pampa::writers::qmd::write` and returns
#' the resulting QMD text. Accepts:
#' * a single string (text or file path, handled like
#'   [`pampa_parse_pd()`]) - parsed with pampa (ts -> Pandoc), then written;
#' * a [`ts_tree`] - rendered to QMD via [`to_qmd()`] and fed through
#'   the text path. This is the full
#'   R -> ts_ast -> text -> Pandoc -> qmd pipeline;
#' * a [`pandoc`] object or tagged-list AST - reconstructed directly into
#'   pampa's `Pandoc` value and written out (skips the ts -> Pandoc step).
#'
#' Intended for comparing against the R-side `to_qmd()` implementations.
#'
#' @param input A single string, a [`ts_tree`], a [`pandoc`] object, or
#'   a tagged list.
#' @return A single string with the rendered QMD. Diagnostics (if any)
#'   are attached as `attr(result, "diagnostics")`.
#' @export
pampa_to_qmd = function(input) {
  if (S7::S7_inherits(input, ts_tree)) input = to_qmd(input)

  raw = if (is.character(input) && length(input) == 1L && !is.na(input)) {
    src = pampa_read_input(input)
    r = pampa_write_qmd_text_impl(src$text, src$filename)
    list(
      text = r$text,
      diagnostics = pampa_diagnostics_from_raw(r, src$text, src$filename)
    )
  } else {
    ast_list = if (S7::S7_inherits(input, pandoc)) {
      pandoc_to_list(input)
    } else if (is.list(input) && identical(input$tag, "Pandoc")) {
      input
    } else {
      stop("pampa_to_qmd(): unsupported input - expected text, file path, ",
           "a ts_tree, a pandoc object, or a tagged-list AST")
    }
    r = pampa_write_qmd_ast_impl(ast_list)
    list(text = r$text, diagnostics = list())
  }

  if (is.null(raw$text)) {
    stop("pampa_to_qmd(): pampa's QMD writer failed; see attached diagnostics")
  }
  result = raw$text
  if (length(raw$diagnostics)) attr(result, "diagnostics") = raw$diagnostics
  result
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
