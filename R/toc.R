#' @include pd-ast-pandoc.R pd-ast-block.R pd-ast-inline.R ast-text.R ast-construct.R ast-sections.R select.R
NULL

#' Build a table of contents from a document's headings
#'
#' `r lifecycle::badge("experimental")`
#'
#' Walks the headings of a [`pandoc`] document in order and returns a
#' nested [`pandoc_bullet_list`] linking to each one, the q2r analog of
#' mq's `section::toc()`. The result is an ordinary block, so it can be
#' spliced into the document with [`insert_after()`] or wrapped in a
#' [`pandoc`] and rendered with [`to_qmd()`].
#'
#' Each entry links to the heading's explicit identifier (`@attr@id`) when
#' it has one; otherwise an approximate Pandoc-style slug of the heading
#' text is used. Headings deeper than `max_level` are omitted.
#'
#' @param x A [`pandoc`] document, a [`pandoc_blocks`] wrapper, or a list
#'   of blocks.
#' @param max_level Deepest heading level to include (default `3`).
#' @param ... Unused; for future extension.
#' @return A [`pandoc_bullet_list`] block (empty when there are no
#'   qualifying headings).
#'
#' @examples
#' \dontrun{
#' doc = parse_qmd("# A\n\n## B\n\ntext\n\n# C\n")
#' toc = ast_toc(doc)
#' doc |> insert_before(is(pandoc_header), .what = toc)
#' }
#'
#' @export
ast_toc = S7::new_generic("ast_toc", "x", function(x, max_level = 3L, ...) {
  S7::S7_dispatch()
})

S7::method(ast_toc, pandoc) = function(x, max_level = 3L, ...) {
  ast_toc_of_headers(select_nodes(x, is(pandoc_header)), max_level)
}

S7::method(ast_toc, pandoc_blocks) = function(x, max_level = 3L, ...) {
  ast_toc_of_headers(select_nodes(x, is(pandoc_header)), max_level)
}

S7::method(ast_toc, S7::class_list) = function(x, max_level = 3L, ...) {
  ast_toc_of_headers(select_nodes(x, is(pandoc_header)), max_level)
}

ast_toc_of_headers = function(headers, max_level) {
  items = purrr::map(headers, function(h) {
    list(level = h@level, text = ast_text(h), id = h@attr@id)
  })
  items = purrr::keep(items, function(it) {
    length(it$level) == 1L && !is.na(it$level) && it$level <= max_level
  })
  if (length(items) == 0L) return(pandoc_bullet_list(content = list()))
  toc_build(items)
}

# Group a flat, document-order item sequence into a nested bullet list:
# items deeper than the first item of a run become its nested children.
toc_build = function(items) {
  result = list()
  i = 1L
  n = length(items)
  while (i <= n) {
    it = items[[i]]
    j = i + 1L
    while (j <= n && items[[j]]$level > it$level) j = j + 1L
    children = if (j > i + 1L) items[(i + 1L):(j - 1L)] else list()
    item_blocks = list(pandoc_plain(content = pandoc_inlines(list(toc_link(it)))))
    if (length(children)) item_blocks = c(item_blocks, list(toc_build(children)))
    result[[length(result) + 1L]] = pandoc_blocks(item_blocks)
    i = j
  }
  pandoc_bullet_list(content = result)
}

toc_link = function(it) {
  target = if (nzchar(it$id)) it$id else pandoc_slug(it$text)
  pandoc_link(content = as_inlines(it$text), url = paste0("#", target), title = "")
}

# Approximate Pandoc's auto-identifier algorithm: lower-case, drop
# punctuation other than space/hyphen/underscore, collapse separators to
# single hyphens, strip a leading run of hyphens.
pandoc_slug = function(text) {
  s = tolower(text)
  s = gsub("[^a-z0-9 _-]", "", s)
  s = gsub("[ _]+", "-", trimws(s))
  s = gsub("-+", "-", s)
  sub("^-+", "", s)
}


#' Split a document into per-section sub-documents
#'
#' `r lifecycle::badge("experimental")`
#'
#' Partitions the top-level block stream of a [`pandoc`] document at every
#' heading of a given `level`, returning a named list of [`pandoc`]
#' documents (one per section, named by the heading text), the q2r analog
#' of mq's `section::split()`. Any blocks before the first boundary
#' heading become a leading preamble document named `""`.
#'
#' Each returned document can be rendered with [`to_qmd()`],
#' [`render_qmd()`], or written out; wrap the list in a
#' [`qmd_collection`] if you want to run the batch verbs over it.
#'
#' @param x A [`pandoc`] document, a [`pandoc_blocks`] wrapper, or a list
#'   of blocks.
#' @param level Heading level at which to split (default `1`). Headings at
#'   other levels stay inside their enclosing section.
#' @param ... Unused; for future extension.
#' @return A named `list` of [`pandoc`] documents.
#'
#' @examples
#' \dontrun{
#' doc = parse_qmd("intro\n\n# A\n\na\n\n# B\n\nb\n")
#' parts = split_sections(doc, level = 1)
#' names(parts)
#' }
#'
#' @export
split_sections = S7::new_generic("split_sections", "x", function(x, level = 1L, ...) {
  S7::S7_dispatch()
})

S7::method(split_sections, pandoc) = function(x, level = 1L, ...) {
  split_sections_of_blocks(x@blocks@content, level)
}

S7::method(split_sections, pandoc_blocks) = function(x, level = 1L, ...) {
  split_sections_of_blocks(x@content, level)
}

S7::method(split_sections, S7::class_list) = function(x, level = 1L, ...) {
  split_sections_of_blocks(x, level)
}

split_sections_of_blocks = function(blocks, level) {
  level = as.integer(level)
  is_boundary = function(b) {
    S7::S7_inherits(b, pandoc_header) && length(b@level) == 1L &&
      !is.na(b@level) && b@level == level
  }
  if (length(blocks) == 0L) return(stats::setNames(list(), character()))

  bnd = which(purrr::map_lgl(blocks, is_boundary))
  if (length(bnd) == 0L) {
    return(stats::setNames(list(pandoc(blocks = pandoc_blocks(blocks))), ""))
  }

  out = list()
  nms = character()
  if (bnd[[1L]] > 1L) {
    out = c(out, list(pandoc(blocks = pandoc_blocks(blocks[seq_len(bnd[[1L]] - 1L)]))))
    nms = c(nms, "")
  }
  ends = c(bnd[-1L] - 1L, length(blocks))
  for (k in seq_along(bnd)) {
    grp = blocks[bnd[[k]]:ends[[k]]]
    out = c(out, list(pandoc(blocks = pandoc_blocks(grp))))
    nms = c(nms, ast_text(blocks[[bnd[[k]]]]))
  }
  stats::setNames(out, nms)
}
