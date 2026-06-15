#' @include from-rust.R to-rust.R diagnostic.R pd-ast-pandoc.R ts-ast.R
NULL

# Read a file's exact bytes, preserving the trailing newline, any trailing
# blank lines, and CRLF that `readLines()` + `paste()` would silently drop.
# Quarto sources are UTF-8; the caller's `validUTF8()` guard rejects anything
# that is not.
read_file_bytes = function(path) {
  raw = readBin(path, what = "raw", n = file.info(path)$size)
  text = rawToChar(raw)
  Encoding(text) = "UTF-8"
  text
}

pampa_read_input = function(input) {
  stopifnot(is.character(input), length(input) == 1L, !is.na(input))
  if (Encoding(input) == "bytes") {
    stop(
      "`input` has \"bytes\" encoding, which cannot be translated to UTF-8. ",
      "Declare its source encoding first (e.g. `Encoding(x) <- \"UTF-8\"` or ",
      "\"latin1\"), then retry.",
      call. = FALSE
    )
  }
  is_text = grepl("\n", input, fixed = TRUE)
  res = if (!is_text && file.exists(input) && !dir.exists(input)) {
    list(
      text     = read_file_bytes(input),
      filename = basename(input)
    )
  } else {
    list(text = input, filename = "<text>")
  }
  res$text = enc2utf8(res$text)
  if (!validUTF8(res$text)) {
    stop(
      "`input` is not valid UTF-8 after translation; pampa requires UTF-8 ",
      "source. Check the encoding of the file or string.",
      call. = FALSE
    )
  }
  res
}

pampa_diagnostics_from_raw = function(raw, text, filename) {
  lapply(
    raw$diagnostics %||% list(),
    diagnostic_from_list,
    source_text = text,
    source_filename = filename
  )
}

#' Parse QMD input with pampa
#'
#' `r lifecycle::badge("experimental")`
#'
#' Parses QMD text or a file with pampa and returns the requested AST.
#' With `ast = "pd"` (the default) the Pandoc AST is returned as a
#' [`pandoc`] object; with `ast = "ts"` the tree-sitter concrete syntax
#' tree is returned as a [`ts_tree`]. Either way any parse diagnostics are
#' attached to the returned object's `@diagnostics` slot.
#'
#' @param input A single string. Treated as a file path if it does not
#'   contain newlines and names an existing file (`file.exists()` is
#'   TRUE and it is not a directory); otherwise treated as raw text. To
#'   parse an R-held [`ts_tree`] as Pandoc, render it first with
#'   [`to_qmd()`] and feed the result back in.
#' @param ast The AST to return: `"pd"` (the default) for the Pandoc AST
#'   as a [`pandoc`] object, or `"ts"` for the tree-sitter AST as a
#'   [`ts_tree`].
#' @param quiet If `FALSE` (the default) any error-kind diagnostics are
#'   raised as R errors (after attaching diagnostics to the result),
#'   and warning-kind diagnostics are emitted as R warnings. `info` and
#'   `note` diagnostics are never signalled regardless of `quiet`. If
#'   `TRUE` no signal is raised; diagnostics of every kind are still
#'   attached to the returned object's `@diagnostics` slot.
#' @param prune_errors If `TRUE` (the default, matching the pampa CLI)
#'   parser-error diagnostics are deduplicated by tree-sitter `ERROR`
#'   node, keeping the earliest per node. Set to `FALSE` to see every
#'   raw diagnostic pampa produces (useful for debugging the parser).
#' @return For `ast = "pd"` a [`pandoc`] object, for `ast = "ts"` a
#'   [`ts_tree`] object, with any parse diagnostics attached in the
#'   `@diagnostics` slot. If pampa fails to produce a Pandoc AST the
#'   returned `pandoc` has an empty `@blocks`; the diagnostics explain
#'   why. Tree-sitter parsing itself never fails.
#' @export
parse_qmd = function(input, ast = c("pd", "ts"), quiet = FALSE, prune_errors = TRUE) {
  ast = match.arg(ast)
  src = pampa_read_input(input)

  if (ast == "pd") {
    raw = pampa_parse_pd_impl(src$text, src$filename, isTRUE(prune_errors))
    diagnostics = pampa_diagnostics_from_raw(raw, src$text, src$filename)
    out = if (is.null(raw$pd_ast)) pandoc() else pandoc_from_list(raw$pd_ast)
  } else {
    raw = pampa_parse_ts_impl(src$text, src$filename, isTRUE(prune_errors))
    diagnostics = pampa_diagnostics_from_raw(raw, src$text, src$filename)
    out = ts_tree_from_list(raw$ts_ast)
  }

  out@diagnostics = diagnostics
  pampa_signal_diagnostics(diagnostics, quiet = quiet)
  out
}
