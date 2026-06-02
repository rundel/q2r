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
#' * `edit_qmd()` is the in-place one-liner: read, apply `.f`, write back.
#'
#' @param path Path to a `.qmd` file.
#' @param ast Which AST to build, `"pd"` (Pandoc, default) or `"ts"`
#'   (tree-sitter); passed to [`parse_qmd()`].
#' @param x A [`pandoc`] or [`ts_tree`] object to render.
#' @param .f A function (or rlang formula) taking the parsed AST and
#'   returning the edited AST.
#' @param ... Further arguments passed to [`parse_qmd()`].
#' @return `read_qmd()` returns a [`pandoc`] or [`ts_tree`];
#'   `write_qmd()` and `edit_qmd()` return the (edited) AST invisibly.
#'
#' @examples
#' \dontrun{
#' doc = read_qmd("notes.qmd")
#' edit_qmd("notes.qmd", \(d) map_nodes(d, is(pandoc_header), .f = add_class("done")))
#' }
#'
#' @name read_qmd
NULL

#' @rdname read_qmd
#' @export
read_qmd = function(path, ast = c("pd", "ts"), ...) {
  if (length(path) != 1L || !is.character(path)) {
    stop("`read_qmd()`: `path` must be a single file path.", call. = FALSE)
  }
  if (!file.exists(path) || dir.exists(path)) {
    stop("`read_qmd()`: file not found: ", path, call. = FALSE)
  }
  parse_qmd(path, ast = match.arg(ast), ...)
}

#' @rdname read_qmd
#' @export
write_qmd = function(x, path) {
  writeLines(to_qmd(x), path, sep = "")
  invisible(x)
}

#' @rdname read_qmd
#' @export
edit_qmd = function(path, .f, ...) {
  fn = rlang::as_function(.f)
  write_qmd(fn(read_qmd(path, ...)), path)
}
