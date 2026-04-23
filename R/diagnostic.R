#' Parse diagnostic produced by `pampa_parse()`
#'
#' Structured representation of a single diagnostic message returned
#' by the Quarto parser. Pretty-printed output is generated on demand
#' by the `format()`/`print()` methods (which hand the structured
#' fields back to the Rust renderer).
#'
#' @slot kind One of `"error"`, `"warning"`, `"info"`, `"note"`.
#' @slot code Optional error code (e.g. `"Q-1-1"`), or `NA`.
#' @slot title Brief title.
#' @slot problem Optional problem statement as a list
#'   `list(format = "plain" | "markdown", text = <chr>)`, or `NULL`.
#' @slot details List of detail records, each a list with `kind`,
#'   `content` (same shape as `problem`), and optional `location`.
#' @slot hints Character vector of hint strings.
#' @slot location Optional source location, a named list with
#'   `file`, `start_offset`, `start_row`, `start_column`, `end_offset`,
#'   `end_row`, `end_column`. `NULL` if no location is attached.
#' @slot source_text Original input text the parser saw. Carried so
#'   the diagnostic can be re-rendered against its source.
#' @slot source_filename Filename shown in the rendered output.
#' @export
pampa_diagnostic = S7::new_class(
  "pampa_diagnostic",
  package = "q2r",
  properties = list(
    kind            = S7::new_property(S7::class_character, default = "error"),
    code            = S7::new_property(S7::class_any, default = NA_character_),
    title           = S7::new_property(S7::class_character, default = ""),
    problem         = S7::new_property(S7::class_any, default = NULL),
    details         = S7::new_property(S7::class_list, default = list()),
    hints           = S7::new_property(S7::class_character, default = character()),
    location        = S7::new_property(S7::class_any, default = NULL),
    source_text     = S7::new_property(S7::class_character, default = ""),
    source_filename = S7::new_property(S7::class_character, default = "<text>")
  ),
  validator = function(self) {
    if (length(self@kind) != 1L || !self@kind %in% c("error", "warning", "info", "note")) {
      "@kind must be one of 'error', 'warning', 'info', 'note'"
    } else if (length(self@title) != 1L) {
      "@title must be a scalar string"
    }
  }
)

diagnostic_from_list = function(x, source_text, source_filename) {
  pampa_diagnostic(
    kind            = x$kind %||% "error",
    code            = x$code %||% NA_character_,
    title           = x$title %||% "",
    problem         = x$problem,
    details         = x$details %||% list(),
    hints           = as.character(x$hints %||% character()),
    location        = x$location,
    source_text     = source_text,
    source_filename = source_filename
  )
}

format_pampa_diagnostic = function(x, color = cli::num_ansi_colors() > 1L) {
  code = if (is.na(x@code)) NULL else x@code
  txt = pampa_diag_format_impl(
    kind            = x@kind,
    code            = code,
    title           = x@title,
    problem         = x@problem,
    details         = x@details,
    hints           = x@hints,
    location        = x@location,
    source_text     = x@source_text,
    source_filename = x@source_filename,
    hyperlinks      = isTRUE(color)
  )
  if (!isTRUE(color)) txt = cli::ansi_strip(txt)
  txt
}

S7::method(format, pampa_diagnostic) = format_pampa_diagnostic

S7::method(print, pampa_diagnostic) = function(x,
                                               color = cli::num_ansi_colors() > 1L,
                                               ...) {
  txt = format_pampa_diagnostic(x, color = color)
  cat(txt)
  if (!endsWith(txt, "\n")) cat("\n")
  invisible(x)
}
