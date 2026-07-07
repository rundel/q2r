#' @include pampa.R to-qmd.R
NULL

#' Read, write, and edit QMD files
#'
#' `r lifecycle::badge("experimental")`
#'
#' Thin file-oriented conveniences around [`parse_qmd()`] and
#' [`to_qmd()`] that close the parse-edit-write loop (parsermd's
#' `as_document()` role):
#'
#' * `read_qmd()` parses a file path (and, unlike [`parse_qmd()`], errors
#'   if the path does not exist rather than treating it as inline text).
#' * `write_qmd()` renders an AST with [`to_qmd()`] and writes it
#'   verbatim, with no added trailing newline so the round trip stays
#'   byte-faithful. Returns its input invisibly so it can end a pipe.
#'   When the AST carries error-kind parse diagnostics
#'   ([`has_error_diagnostics()`]) it aborts instead of writing, because
#'   rendering an error-parsed document replaces whatever the parser
#'   could not read with the partial AST it recovered; pass
#'   `force = TRUE` to write anyway.
#' * `edit_qmd()` is the in-place one-liner: read, apply `.f`, write back.
#'
#' @param path Path to a `.qmd` file.
#' @param ast Which AST to build, `"pd"` (Pandoc, default) or `"ts"`
#'   (tree-sitter); passed to [`parse_qmd()`].
#' @param x A [`pandoc`] or [`ts_tree`] object to render.
#' @param .f A function (or rlang formula) taking the parsed AST and
#'   returning the edited AST.
#' @param force Write even when the AST carries error-kind parse
#'   diagnostics.
#' @param ... Further arguments passed to [`parse_qmd()`].
#' @return `read_qmd()` returns a [`pandoc`] or [`ts_tree`];
#'   `write_qmd()` and `edit_qmd()` return the (edited) AST invisibly.
#'
#' @examples
#' path = tempfile(fileext = ".qmd")
#' writeLines("# Title\n\nSome text.\n", path)
#'
#' read_qmd(path)
#'
#' edit_qmd(path, \(d) map_nodes(d, is(pandoc_header),
#'                               .f = \(h) add_class(h, "done")))
#' cat(readLines(path), sep = "\n")
#'
#' @name read_qmd
NULL

#' @rdname read_qmd
#' @export
read_qmd = function(path, ast = c("pd", "ts"), ...) {
  if (length(path) != 1L || !is.character(path)) {
    stop("`read_qmd()`: `path` must be a single file path.", call. = FALSE)
  }
  if (dir.exists(path)) {
    stop("`read_qmd()`: `path` is a directory, not a file: ", path,
         " (see `parse_qmd_dir()`)", call. = FALSE)
  }
  if (!file.exists(path)) {
    stop("`read_qmd()`: file not found: ", path, call. = FALSE)
  }
  parse_qmd_text(
    to_utf8_source(read_file_bytes(path)), basename(path),
    ast = match.arg(ast), ...
  )
}

#' @rdname read_qmd
#' @export
write_qmd = function(x, path, force = FALSE) {
  if (!isTRUE(force) && has_error_diagnostics(x)) {
    cli::cli_abort(c(
      "{.arg x} carries error-kind parse diagnostics; writing would replace the unparseable source content with the partial AST the parser recovered.",
      "i" = "Inspect {.code x@diagnostics}, fix the source and re-parse, or pass {.code force = TRUE} to write anyway."
    ))
  }
  # Write the exact UTF-8 bytes; writeLines() would re-encode through the
  # session locale on a non-UTF-8 platform, breaking the byte-fidelity promise.
  writeBin(charToRaw(enc2utf8(to_qmd(x))), path)
  invisible(x)
}

#' @rdname read_qmd
#' @export
edit_qmd = function(path, .f, ..., force = FALSE) {
  fn = rlang::as_function(.f)
  write_qmd(fn(read_qmd(path, ...)), path, force = force)
}
