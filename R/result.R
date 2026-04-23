#' @include ast-pandoc.R ast-cst.R diagnostic.R
NULL

#' Result of `pampa_parse()`
#'
#' Wrapper carrying any combination of the artifacts the parser can
#' produce. Slots not requested by `format` are `NULL` (or empty for
#' `diagnostics`). The `diagnostics` slot is always populated as a
#' (possibly empty) list of [`pampa_diagnostic`] objects.
#'
#' @export
pampa_result = S7::new_class(
  "pampa_result",
  package = "q2r",
  properties = list(
    ast         = S7::new_property(S7::class_any, default = NULL),
    tree        = S7::new_property(S7::class_any, default = NULL),
    cst         = S7::new_property(S7::class_any, default = NULL),
    native      = S7::new_property(S7::class_any, default = NULL),
    diagnostics = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    if (!is.null(self@ast) && !S7::S7_inherits(self@ast, pandoc)) {
      "@ast must be NULL or a pandoc object"
    } else if (!is.null(self@tree) && !is.character(self@tree)) {
      "@tree must be NULL or a character vector"
    } else if (!is.null(self@cst) && !S7::S7_inherits(self@cst, ts_tree)) {
      "@cst must be NULL or a ts_tree object"
    } else if (!is.null(self@native) && !is.character(self@native)) {
      "@native must be NULL or a character vector"
    } else if (length(self@diagnostics) &&
               !all(vapply(self@diagnostics, S7::S7_inherits, logical(1), pampa_diagnostic))) {
      "@diagnostics must be a list of pampa_diagnostic objects"
    }
  }
)

S7::method(print, pampa_result) = function(x,
                                            color = cli::num_ansi_colors() > 1L,
                                            ...) {
  if (!is.null(x@tree)) {
    cat("-- tree --\n")
    cat(x@tree, sep = "\n")
    cat("\n")
  }
  if (!is.null(x@cst)) {
    cat("\n-- cst --\n")
    print(x@cst)
  }
  if (length(x@diagnostics)) {
    cat("\n-- diagnostics --\n")
    for (d in x@diagnostics) print(d, color = color)
  }
  if (!is.null(x@native)) {
    cat("\n-- native --\n")
    cat(x@native, sep = "\n")
    cat("\n")
  }
  if (!is.null(x@ast)) {
    cat("\n-- ast --\n")
    print(x@ast)
  }
  invisible(x)
}
