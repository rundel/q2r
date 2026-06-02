#' @include pd-ast-pandoc.R pd-ast-block.R ast-text.R
NULL

#' Heading-section path for each top-level block
#'
#' `r lifecycle::badge("experimental")`
#'
#' Walks the top-level block stream of a [`pandoc`] document and, for
#' each block, reports the chain of enclosing [`pandoc_header`] titles.
#' Because the Pandoc block list is flat (headings are siblings of the
#' content they introduce, not parents of it), this is the piece of
#' structure that q2r does not otherwise expose. It is the analog of
#' parsermd's `rmd_node_sections()` and the basis for
#' [`select_section()`].
#'
#' Each block is assigned a length-6 named character vector
#' (`h1`..`h6`). A header is considered part of the section it opens, so
#' a level-2 header `## Methods` carries `h2 = "Methods"` itself and
#' resets any deeper (`h3`..`h6`) entries. Heading titles are the
#' flattened text of the header ([`ast_text()`]).
#'
#' @param x A [`pandoc`] document, a [`pandoc_blocks`] wrapper, or a
#'   plain `list` of top-level blocks.
#' @return A `list` with one element per top-level block, each a named
#'   character vector `c(h1, h2, h3, h4, h5, h6)` with `NA` where no
#'   heading at that level is in scope.
#'
#' @examples
#' \dontrun{
#' doc = parse_qmd("# A\n\nintro\n\n## B\n\nbody\n")
#' ast_sections(doc)
#' }
#'
#' @export
ast_sections = S7::new_generic("ast_sections", "x")

S7::method(ast_sections, pandoc) = function(x) {
  ast_sections_of_blocks(x@blocks@content)
}

S7::method(ast_sections, pandoc_blocks) = function(x) {
  ast_sections_of_blocks(x@content)
}

S7::method(ast_sections, S7::class_list) = function(x) {
  ast_sections_of_blocks(x)
}


ast_section_levels = paste0("h", 1:6)

ast_sections_of_blocks = function(blocks) {
  if (length(blocks) == 0L) return(list())
  init = stats::setNames(rep(NA_character_, 6L), ast_section_levels)
  step = function(stack, b) {
    if (!S7::S7_inherits(b, pandoc_header)) return(stack)
    lvl = b@level
    if (length(lvl) != 1L || is.na(lvl) || lvl < 1L || lvl > 6L) return(stack)
    stack[lvl] = ast_text(b)
    if (lvl < 6L) stack[(lvl + 1L):6L] = NA_character_
    stack
  }
  purrr::accumulate(blocks, step, .init = init)[-1L]
}
