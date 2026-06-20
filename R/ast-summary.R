#' @include pd-ast-pandoc.R pd-ast-block.R ast-text.R ast-attr.R ast-sections.R
NULL

#' Tabular overview of a document's top-level blocks
#'
#' `r lifecycle::badge("experimental")`
#'
#' Returns a one-row-per-top-level-block `data.frame` summarising a
#' [`pandoc`] document, the analog of parsermd's `as_tibble.rmd_ast()`.
#' It makes a document graspable at a glance and bridges to base/dplyr
#' filtering: the `node` list-column holds the live S7 objects, so a
#' filtered frame can be fed straight back through the selection and
#' mutation verbs.
#'
#' The view is deliberately shallow (top-level blocks only) to mirror
#' parsermd's flat model; reach for [`select_descendants()`] to inspect
#' nested content.
#'
#' @param x A [`pandoc`] document, a [`pandoc_blocks`] wrapper, or a
#'   plain `list` of top-level blocks.
#' @param max_text Maximum width of the truncated `text` preview.
#' @return A `data.frame` with columns `type` (S7 class name), `level`
#'   (header level or `NA`), `id` (`@attr@id` or `NA`), `section`
#'   (deepest enclosing heading title, from [`ast_sections()`]), `text`
#'   (truncated [`ast_text()`] preview), and `node` (a list-column of the
#'   block objects). The `node` column displays as compact `<type>`
#'   placeholders but holds the live S7 objects for piping back through
#'   the verbs.
#'
#' @examples
#' \dontrun{
#' doc = parse_qmd("# A\n\nsome text\n\n## B\n\nmore\n")
#' ast_summary(doc)
#' }
#'
#' @export
ast_summary = S7::new_generic(
  "ast_summary", "x",
  function(x, max_text = 40L) S7::S7_dispatch()
)

S7::method(ast_summary, pd_block_source) = function(x, max_text = 40L) {
  ast_summary_of_blocks(as_block_list(x), max_text)
}


ast_summary_text = function(node, max_text) {
  txt = tryCatch(ast_text(node), error = function(e) "")
  txt = gsub("[[:space:]]+", " ", trimws(txt))
  if (nchar(txt) > max_text) {
    paste0(substr(txt, 1L, max_text - 1L), "…")
  } else {
    txt
  }
}

ast_summary_of_blocks = function(blocks, max_text = 40L) {
  secs = ast_sections_of_blocks(blocks)
  out = data.frame(
    type    = purrr::map_chr(blocks, pandoc_class_name),
    level   = purrr::map_int(blocks, function(b) {
      if (S7::S7_inherits(b, pandoc_header)) b@level else NA_integer_
    }),
    id      = purrr::map_chr(blocks, function(b) {
      id = attr_get_id(ast_attr_maybe_get(b))
      if (!nzchar(id)) NA_character_ else id
    }),
    section = purrr::map_chr(secs, function(s) {
      named = s[!is.na(s)]
      if (length(named) == 0L) NA_character_ else named[[length(named)]]
    }),
    text    = purrr::map_chr(blocks, ast_summary_text, max_text = max_text),
    stringsAsFactors = FALSE
  )
  # A plain list-column of the live S7 nodes; it displays as compact
  # `<type>` placeholders via the format() method on pandoc_node (see
  # pd-ast-print.R) and subsets correctly under base `[.data.frame`.
  out$node = blocks
  out
}
