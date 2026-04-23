#' @include ast-block.R ast-inline.R
NULL

#' Top-level Pandoc document
#'
#' @export
pandoc = S7::new_class(
  "pandoc",
  package = "q2r",
  properties = list(
    meta   = S7::new_property(pandoc_meta_value, default = pandoc_meta_value()),
    blocks = S7::new_property(pandoc_blocks, default = pandoc_blocks(list()))
  )
)
