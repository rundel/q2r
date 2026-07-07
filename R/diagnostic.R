#' Parse diagnostic produced by the pampa parser
#'
#' Structured representation of a single diagnostic message returned
#' by the Quarto parser. Pretty-printed output is generated on demand
#' by the `format()`/`print()` methods (which hand the structured
#' fields back to the Rust renderer).
#'
#' @param kind One of `"error"`, `"warning"`, `"info"`, `"note"`.
#' @param code Optional error code (e.g. `"Q-1-1"`), or `NA`.
#' @param title Brief title.
#' @param problem Optional problem statement as a list
#'   `list(format = "plain" | "markdown", text = <chr>)`, or `NULL`.
#' @param details List of detail records, each a list with `kind`,
#'   `content` (same shape as `problem`), and optional `location`.
#' @param hints Character vector of hint strings.
#' @param location Optional source location, a named list with
#'   `file`, `start_offset`, `start_row`, `start_column`, `end_offset`,
#'   `end_row`, `end_column`. `NULL` if no location is attached.
#' @param source_text Original input text the parser saw. Carried so
#'   the diagnostic can be re-rendered against its source.
#' @param source_filename Filename shown in the rendered output.
#' @return A `pampa_diagnostic` S7 object.
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

# Whether a parsed object (pandoc / ts_tree) carries any error-kind
# diagnostics. Used by write_qmd_dir() to refuse writing documents whose
# source failed to parse.
pampa_has_error_diagnostics = function(x) {
  any(purrr::map_lgl(x@diagnostics, function(d) identical(d@kind, "error")))
}

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

format_pampa_diagnostic = function(x, color = cli::num_ansi_colors() > 1L, ...) {
  code = if (length(x@code) != 1L || is.na(x@code)) NULL else x@code
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

pampa_signal_diagnostics = function(diagnostics, quiet = FALSE) {
  if (isTRUE(quiet) || !length(diagnostics)) return(invisible())

  color = cli::num_ansi_colors() > 1L

  render = function(kind) {
    matched = purrr::keep(diagnostics, function(d) identical(d@kind, kind))
    if (!length(matched)) return(NULL)
    paste(purrr::map_chr(matched, format_pampa_diagnostic, color = color), collapse = "\n")
  }

  # Flush warnings before raising the error, so a single call surfaces both.
  w = render("warning")
  if (!is.null(w)) warning(w, call. = FALSE)
  e = render("error")
  if (!is.null(e)) stop(e, call. = FALSE)

  invisible()
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
