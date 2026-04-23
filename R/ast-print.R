#' @include ast-pandoc.R
NULL

#' Label a pandoc AST node for tree display
#'
#' Generic returning a single-line label for a node. Override per class
#' to include node-specific summary information (level, url, type, ...).
#'
#' @param x An AST node.
#' @export
pandoc_format_label = S7::new_generic("pandoc_format_label", "x")

#' Children of a pandoc AST node for tree display
#'
#' Generic returning a named list of child subtrees. A child may be a
#' `pandoc_node`, a `pandoc_blocks`/`pandoc_inlines` wrapper, or a plain
#' list of either (used for multi-item containers such as bullet lists).
#' `NULL` entries are skipped.
#'
#' @param x An AST node.
#' @export
pandoc_children = S7::new_generic("pandoc_children", "x")

pandoc_strip_prefix = function(name) sub("^pandoc_", "", name)

pandoc_truncate = function(text, n = 40L) {
  if (length(text) == 0L) return("")
  s = paste(text, collapse = " ")
  if (nchar(s) > n) paste0(substr(s, 1L, n - 1L), "…") else s
}

pandoc_quote = function(text) paste0("\"", pandoc_truncate(text), "\"")

pandoc_format_attr = function(attr) {
  if (pandoc_attr_is_empty(attr)) return("")
  parts = character()
  if (nchar(attr@id) > 0L) parts = c(parts, paste0("#", attr@id))
  if (length(attr@classes) > 0L) parts = c(parts, paste0(".", attr@classes))
  if (length(attr@attributes) > 0L) {
    kv = paste0(names(attr@attributes), "=", attr@attributes)
    parts = c(parts, kv)
  }
  paste0(" (", paste(parts, collapse = " "), ")")
}

pandoc_class_name = function(x) {
  cls = S7::S7_class(x)
  if (is.null(cls)) class(x)[[1L]] else cls@name
}

S7::method(pandoc_format_label, pandoc_node) = function(x) {
  pandoc_strip_prefix(pandoc_class_name(x))
}

S7::method(pandoc_children, pandoc_node) = function(x) list()

S7::method(pandoc_format_label, pandoc_str) = function(x) {
  paste0("str ", pandoc_quote(x@text))
}

S7::method(pandoc_format_label, pandoc_code) = function(x) {
  paste0("code ", pandoc_quote(x@text), pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_code_block) = function(x) {
  paste0("code_block ", pandoc_quote(x@text), pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_math) = function(x) {
  paste0("math type=", x@math_type, " ", pandoc_quote(x@text))
}

S7::method(pandoc_format_label, pandoc_raw_block) = function(x) {
  paste0("raw_block format=", x@format, " ", pandoc_quote(x@text))
}

S7::method(pandoc_format_label, pandoc_raw_inline) = function(x) {
  paste0("raw_inline format=", x@format, " ", pandoc_quote(x@text))
}

S7::method(pandoc_format_label, pandoc_header) = function(x) {
  paste0("header level=", x@level, pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_link) = function(x) {
  tail = if (nchar(x@title) > 0L) paste0(" title=", pandoc_quote(x@title)) else ""
  paste0("link url=", pandoc_quote(x@url), tail, pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_image) = function(x) {
  tail = if (nchar(x@title) > 0L) paste0(" title=", pandoc_quote(x@title)) else ""
  paste0("image url=", pandoc_quote(x@url), tail, pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_quoted) = function(x) {
  paste0("quoted type=", x@quote_type)
}

S7::method(pandoc_format_label, pandoc_cite) = function(x) {
  paste0("cite (", length(x@citations), " citations)")
}

S7::method(pandoc_format_label, pandoc_ordered_list) = function(x) {
  paste0(
    "ordered_list start=", x@attr@start,
    " style=", x@attr@style,
    " delim=", x@attr@delim
  )
}

S7::method(pandoc_format_label, pandoc_div) = function(x) {
  paste0("div", pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_span) = function(x) {
  paste0("span", pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_figure) = function(x) {
  paste0("figure", pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_table) = function(x) {
  paste0("table", pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_note_reference) = function(x) {
  paste0("note_reference id=", x@id)
}

S7::method(pandoc_format_label, pandoc_note_definition_para) = function(x) {
  paste0("note_definition_para id=", x@id)
}

S7::method(pandoc_format_label, pandoc_note_definition_fenced_block) = function(x) {
  paste0("note_definition_fenced_block id=", x@id)
}

S7::method(pandoc_format_label, pandoc_custom_block) = function(x) {
  paste0("custom_block type=", x@type_name, pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_custom_inline) = function(x) {
  paste0("custom_inline type=", x@type_name, pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_shortcode) = function(x) {
  paste0("shortcode name=", x@name)
}

S7::method(pandoc_format_label, pandoc_attr_inline) = function(x) {
  paste0("attr_inline", pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_block_metadata) = function(x) "block_metadata"

S7::method(pandoc_format_label, pandoc_citation) = function(x) {
  paste0("citation id=", x@id, " mode=", x@mode)
}

S7::method(pandoc_format_label, pandoc_definition_item) = function(x) "definition_item"

children_content = function(x) list(content = x@content)

S7::method(pandoc_children, pandoc_plain)                        = children_content
S7::method(pandoc_children, pandoc_paragraph)                    = children_content
S7::method(pandoc_children, pandoc_block_quote)                  = children_content
S7::method(pandoc_children, pandoc_header)                       = children_content
S7::method(pandoc_children, pandoc_definition_list)              = children_content
S7::method(pandoc_children, pandoc_div)                          = children_content
S7::method(pandoc_children, pandoc_note_definition_para)         = children_content
S7::method(pandoc_children, pandoc_note_definition_fenced_block) = children_content
S7::method(pandoc_children, pandoc_caption_block)                = children_content

S7::method(pandoc_children, pandoc_emph)         = children_content
S7::method(pandoc_children, pandoc_underline)    = children_content
S7::method(pandoc_children, pandoc_strong)       = children_content
S7::method(pandoc_children, pandoc_strikeout)    = children_content
S7::method(pandoc_children, pandoc_superscript)  = children_content
S7::method(pandoc_children, pandoc_subscript)    = children_content
S7::method(pandoc_children, pandoc_small_caps)   = children_content
S7::method(pandoc_children, pandoc_quoted)       = children_content
S7::method(pandoc_children, pandoc_link)         = children_content
S7::method(pandoc_children, pandoc_image)        = children_content
S7::method(pandoc_children, pandoc_note)         = children_content
S7::method(pandoc_children, pandoc_span)         = children_content
S7::method(pandoc_children, pandoc_insert)       = children_content
S7::method(pandoc_children, pandoc_delete)       = children_content
S7::method(pandoc_children, pandoc_highlight)    = children_content
S7::method(pandoc_children, pandoc_edit_comment) = children_content

S7::method(pandoc_children, pandoc_line_block) = function(x) {
  list(lines = x@content)
}

S7::method(pandoc_children, pandoc_ordered_list) = function(x) {
  list(items = x@content)
}

S7::method(pandoc_children, pandoc_bullet_list) = function(x) {
  list(items = x@content)
}

S7::method(pandoc_children, pandoc_cite) = function(x) {
  list(citations = x@citations, content = x@content)
}

S7::method(pandoc_children, pandoc_figure) = function(x) {
  list(caption = x@caption, content = x@content)
}

S7::method(pandoc_children, pandoc_table) = function(x) {
  list(
    caption = x@caption,
    head    = x@head,
    bodies  = x@bodies,
    foot    = x@foot
  )
}

S7::method(pandoc_children, pandoc_caption) = function(x) {
  list(short = x@short, long = x@long)
}

S7::method(pandoc_children, pandoc_definition_item) = function(x) {
  list(term = x@term, defs = x@defs)
}

S7::method(pandoc_children, pandoc_citation) = function(x) {
  list(prefix = x@prefix, suffix = x@suffix)
}

pandoc_walk_child = function(child, label, depth) {
  if (is.null(child)) return(invisible())

  if (S7::S7_inherits(child, pandoc_blocks) || S7::S7_inherits(child, pandoc_inlines)) {
    if (length(child@content) == 0L) return(invisible())
    if (!is.null(label) && nzchar(label)) {
      cat(strrep("  ", depth), label, ":\n", sep = "")
      for (c2 in child@content) pandoc_tree(c2, depth + 1L)
    } else {
      for (c2 in child@content) pandoc_tree(c2, depth)
    }
    return(invisible())
  }

  if (is.list(child) && !S7::S7_inherits(child, pandoc_node)) {
    if (length(child) == 0L) return(invisible())
    if (!is.null(label) && nzchar(label)) {
      cat(strrep("  ", depth), label, ":\n", sep = "")
      d2 = depth + 1L
    } else {
      d2 = depth
    }
    for (c2 in child) pandoc_walk_child(c2, NULL, d2)
    return(invisible())
  }

  pandoc_tree(child, depth)
}

#' Walk a pandoc AST node and print it as an indented tree
#'
#' @param x An AST node, `pandoc` document, or `pandoc_blocks`/`pandoc_inlines`.
#' @param depth Current indent depth (internal).
#' @export
pandoc_tree = function(x, depth = 0L) {
  if (S7::S7_inherits(x, pandoc_blocks) || S7::S7_inherits(x, pandoc_inlines)) {
    for (child in x@content) pandoc_tree(child, depth)
    return(invisible(x))
  }

  cat(strrep("  ", depth), pandoc_format_label(x), "\n", sep = "")

  kids = pandoc_children(x)
  names_kids = names(kids)
  if (is.null(names_kids)) names_kids = rep("", length(kids))
  single = length(kids) == 1L

  for (i in seq_along(kids)) {
    label = if (single) NULL else names_kids[[i]]
    pandoc_walk_child(kids[[i]], label, depth + 1L)
  }
  invisible(x)
}

S7::method(print, pandoc_node) = function(x, ...) {
  pandoc_tree(x, 0L)
  invisible(x)
}

S7::method(print, pandoc) = function(x, ...) {
  cat("pandoc\n")
  if (!identical(x@meta@kind, "map") || length(x@meta@value) > 0L) {
    cat("  meta: ", x@meta@kind, "\n", sep = "")
  }
  for (child in x@blocks@content) pandoc_tree(child, 1L)
  invisible(x)
}

S7::method(print, pandoc_blocks) = function(x, ...) {
  for (child in x@content) pandoc_tree(child, 0L)
  invisible(x)
}

S7::method(print, pandoc_inlines) = function(x, ...) {
  for (child in x@content) pandoc_tree(child, 0L)
  invisible(x)
}
