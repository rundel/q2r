#' @include pd-ast-block.R pd-ast-inline.R diagnostic.R
NULL

#' Top-level Pandoc document
#'
#' @param meta Document metadata as a [`pandoc_meta_value`] tree (the
#'   parsed YAML frontmatter).
#' @param blocks The document's top-level blocks as a [`pandoc_blocks`].
#' @param diagnostics List of [`pampa_diagnostic`] records attached by
#'   [`parse_qmd()`].
#' @return A `pandoc` S7 object.
#' @export
pandoc = S7::new_class(
  "pandoc",
  package = "q2r",
  properties = list(
    meta        = S7::new_property(pandoc_meta_value, default = quote(pandoc_meta_value())),
    blocks      = S7::new_property(pandoc_blocks, default = quote(pandoc_blocks(list()))),
    diagnostics = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    validate_list_of(self@diagnostics, pampa_diagnostic,
      "@diagnostics must be a list of pampa_diagnostic objects")
  }
)
