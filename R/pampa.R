#' @include from-rust.R to-rust.R diagnostic.R pd-ast-pandoc.R ts-ast.R
NULL

# Read a file's exact bytes, preserving the trailing newline, any trailing
# blank lines, and CRLF that `readLines()` + `paste()` would silently drop.
# Quarto sources are UTF-8; the caller's `validUTF8()` guard rejects anything
# that is not.
read_file_bytes = function(path) {
  raw = readBin(path, what = "raw", n = file.info(path)$size)
  # rawToChar() aborts with an opaque "embedded nul in string" before the
  # friendly UTF-8 guard downstream can fire, so catch the binary/UTF-16 case
  # here with a message that names the likely cause.
  if (any(raw == as.raw(0L))) {
    cli::cli_abort(c(
      "{.path {path}} contains NUL bytes, so it is not UTF-8 text.",
      "i" = "It is likely a binary file or UTF-16/UTF-32 encoded; pampa needs UTF-8."
    ))
  }
  text = rawToChar(raw)
  Encoding(text) = "UTF-8"
  text
}

# Validate and normalize source text to UTF-8 before handing it to pampa,
# which requires UTF-8 input. Shared by the `pampa_read_input()` heuristic
# and by `read_qmd()`, which reads its file itself.
to_utf8_source = function(text) {
  if (Encoding(text) == "bytes") {
    stop(
      "`input` has \"bytes\" encoding, which cannot be translated to UTF-8. ",
      "Declare its source encoding first (e.g. `Encoding(x) <- \"UTF-8\"` or ",
      "\"latin1\"), then retry.",
      call. = FALSE
    )
  }
  # enc2utf8() warns "input string is invalid in this locale" on the same
  # inputs the validUTF8() guard below rejects; one curated error is enough.
  text = suppressWarnings(enc2utf8(text))
  if (!validUTF8(text)) {
    stop(
      "`input` is not valid UTF-8 after translation; pampa requires UTF-8 ",
      "source. Check the encoding of the file or string.",
      call. = FALSE
    )
  }
  text
}

pampa_read_input = function(input) {
  if (!is.character(input) || length(input) != 1L || is.na(input)) {
    msg = "{.arg input} must be a single non-NA string (QMD text or a file path)."
    if (is.character(input) && length(input) > 1L) {
      msg = c(msg,
        "i" = "For a vector of lines (e.g. from {.fn readLines}), collapse it first: {.code parse_qmd(paste(input, collapse = \"\\n\"))}.")
    }
    cli::cli_abort(msg)
  }
  # Route "bytes"-encoded input straight to the curated encoding error:
  # grepl()/file.exists() on such a string throw base R's translation
  # error before to_utf8_source() could explain what to do.
  if (Encoding(input) == "bytes") {
    return(list(text = to_utf8_source(input), filename = "<text>"))
  }
  is_text = grepl("\n", input, fixed = TRUE)
  if (!is_text && file.exists(input) && !dir.exists(input)) {
    list(text = to_utf8_source(read_file_bytes(input)), filename = basename(input))
  } else {
    list(text = to_utf8_source(input), filename = "<text>")
  }
}

pampa_diagnostics_from_raw = function(raw, text, filename) {
  purrr::map(
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
#'   [`to_qmd()`] and feed the result back in. A leading UTF-8 byte-order
#'   mark parses fine but is not represented in either AST, so
#'   [`to_qmd()`] / [`write_qmd()`] output never carries one.
#' @param ast The AST to return: `"pd"` (the default) for the Pandoc AST
#'   as a [`pandoc`] object, or `"ts"` for the tree-sitter AST as a
#'   [`ts_tree`].
#' @param quiet If `FALSE` (the default) any error-kind diagnostics are
#'   raised as a classed error (`q2r_parse_error`) whose condition
#'   carries the structured [`pampa_diagnostic`] records in
#'   `$diagnostics` and the parsed object in `$result` (so
#'   `tryCatch(parse_qmd(x), q2r_parse_error = function(e) e$result)`
#'   recovers the partial AST); warning-kind diagnostics are emitted as
#'   classed warnings (`q2r_parse_warning`, also carrying
#'   `$diagnostics`). `info` and `note` diagnostics are never signalled
#'   regardless of `quiet`. If `TRUE` no signal is raised; diagnostics
#'   of every kind are still attached to the returned object's
#'   `@diagnostics` slot.
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
  parse_qmd_text(
    src$text, src$filename,
    ast = ast, quiet = quiet, prune_errors = prune_errors
  )
}

# Parse already-read, UTF-8-validated source text. Split out from
# `parse_qmd()` so `read_qmd()` can read its file directly and feed the bytes
# in, rather than re-running `pampa_read_input()`'s text-vs-file heuristic on
# a path it has already confirmed exists (a filename containing a newline
# would otherwise be reparsed as literal text).
parse_qmd_text = function(text, filename, ast = c("pd", "ts"),
                          quiet = FALSE, prune_errors = TRUE) {
  ast = match.arg(ast)
  if (ast == "pd") {
    raw = pampa_parse_pd_impl(text, filename, isTRUE(prune_errors))
    diagnostics = pampa_diagnostics_from_raw(raw, text, filename)
    out = if (is.null(raw$pd_ast)) pandoc() else pandoc_from_list(raw$pd_ast)
  } else {
    raw = pampa_parse_ts_impl(text, filename, isTRUE(prune_errors))
    diagnostics = pampa_diagnostics_from_raw(raw, text, filename)
    out = ts_tree_from_list(raw$ts_ast) %||% ts_tree()
  }

  out@diagnostics = diagnostics
  pampa_signal_diagnostics(diagnostics, quiet = quiet, result = out)
  out
}
