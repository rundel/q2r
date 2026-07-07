#' @include pd-ast-pandoc.R pd-ast-block.R pd-ast-inline.R pd-ast-support.R
NULL

#' Flatten a pandoc subtree to plain text
#'
#' `r lifecycle::badge("experimental")`
#'
#' Recursively concatenates the textual content of a pandoc AST,
#' dropping all formatting. The output of a [`parse_qmd()`] result
#' fed back through `ast_text()` is roughly what readers would see if
#' the document were rendered as a flat string.
#'
#' Equivalent in spirit to `pandoc.utils.stringify()` from Pandoc Lua
#' filters: handy for matching on document content (titles, captions,
#' link labels) without descending the AST manually.
#'
#' Leaf rules:
#' - [`pandoc_str`], [`pandoc_code`], [`pandoc_math`],
#'   [`pandoc_raw_inline`], [`pandoc_raw_block`],
#'   [`pandoc_code_block`] emit their `@text` slot.
#' - [`pandoc_space`] and [`pandoc_soft_break`] emit a single space.
#' - [`pandoc_line_break`] emits a newline.
#' - [`pandoc_horizontal_rule`] emits a newline.
#'
#' Container rules:
#' - Block containers ([`pandoc`], [`pandoc_div`], [`pandoc_block_quote`],
#'   list types, etc.) join children with two newlines.
#' - Inline containers ([`pandoc_emph`], [`pandoc_strong`],
#'   [`pandoc_link`], etc.) concatenate children without separator.
#' - [`pandoc_quoted`] wraps its content in typographic quote marks,
#'   matching `pandoc.utils.stringify()`.
#' - [`pandoc_note`] emits its block content (joined with newlines)
#'   wrapped in `[^...]` to flag it; rarely useful in match logic.
#'
#' `ast_text(pandoc)` covers the document's block tree only: `@meta`
#' values (e.g. the title) and the args of nested shortcodes are not
#' included.
#'
#' @param x A [`pandoc`], [`pandoc_node`], [`pandoc_blocks`],
#'   [`pandoc_inlines`], or list thereof.
#' @return A single character string.
#'
#' @examples
#' \dontrun{
#' doc = parse_qmd("# Hello *world*\n\nSecond paragraph.\n")
#' ast_text(doc)
#' # "Hello world\n\nSecond paragraph."
#' }
#'
#' @export
ast_text = S7::new_generic("ast_text", "x")


# ---- collection helpers -------------------------------------------------

ast_text_join_inlines = function(items) {
  paste(purrr::map_chr(items, ast_text), collapse = "")
}

ast_text_join_blocks = function(items) {
  paste(purrr::map_chr(items, ast_text), collapse = "\n\n")
}


# ---- root and wrappers --------------------------------------------------

S7::method(ast_text, pandoc) = function(x) {
  ast_text(x@blocks)
}

S7::method(ast_text, pandoc_blocks) = function(x) {
  ast_text_join_blocks(x@content)
}

S7::method(ast_text, pandoc_inlines) = function(x) {
  ast_text_join_inlines(x@content)
}

S7::method(ast_text, S7::class_list) = function(x) {
  if (length(x) == 0L) return("")
  if (all(purrr::map_lgl(x, S7::S7_inherits, pandoc_inline))) {
    return(ast_text_join_inlines(x))
  }
  if (all(purrr::map_lgl(x, S7::S7_inherits, pandoc_block))) {
    return(ast_text_join_blocks(x))
  }
  # Heterogeneous (block + inline) lists are unusual; join with a single
  # newline so adjacent blocks are not run together.
  paste(purrr::map_chr(x, ast_text), collapse = "\n")
}


# ---- inline leaves ------------------------------------------------------

S7::method(ast_text, pandoc_str)         = function(x) x@text
S7::method(ast_text, pandoc_space)       = function(x) " "
S7::method(ast_text, pandoc_soft_break)  = function(x) " "
S7::method(ast_text, pandoc_line_break)  = function(x) "\n"
S7::method(ast_text, pandoc_code)        = function(x) x@text
S7::method(ast_text, pandoc_math)        = function(x) x@text
S7::method(ast_text, pandoc_raw_inline)  = function(x) x@text


# ---- inline containers --------------------------------------------------

S7::method(ast_text, pandoc_emph)        = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_underline)   = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_strong)      = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_strikeout)   = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_superscript) = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_subscript)   = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_small_caps)  = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_quoted)      = function(x) {
  # Include the quote marks, matching pandoc.utils.stringify.
  q = if (identical(x@quote_type, "single")) "‘’" else "“”"
  paste0(substr(q, 1L, 1L), ast_text(x@content), substr(q, 2L, 2L))
}
S7::method(ast_text, pandoc_link)        = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_image)       = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_span)        = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_insert)      = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_delete)      = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_highlight)   = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_edit_comment) = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_note)        = function(x) {
  paste0("[^", ast_text(x@content), "]")
}
S7::method(ast_text, pandoc_cite)        = function(x) {
  content = ast_text(x@content)
  if (nzchar(content)) return(content)
  # A parsed citation keeps its keys in @citations, not @content; flatten
  # prefix / @id / suffix (which carry their own spacing) so the citation is
  # matchable via has_text() / ast_summary() rather than invisible.
  paste(purrr::map_chr(x@citations, function(cit) {
    paste0(ast_text(cit@prefix), "@", cit@id, ast_text(cit@suffix))
  }), collapse = "; ")
}


# ---- inline misc --------------------------------------------------------

S7::method(ast_text, pandoc_note_reference) = function(x) paste0("[^", x@id, "]")
S7::method(ast_text, pandoc_shortcode)      = function(x) ""
S7::method(ast_text, pandoc_attr_inline)    = function(x) ""


# ---- block leaves -------------------------------------------------------

S7::method(ast_text, pandoc_code_block)      = function(x) x@text
S7::method(ast_text, pandoc_raw_block)       = function(x) x@text
S7::method(ast_text, pandoc_horizontal_rule) = function(x) "\n"


# ---- block containers with pandoc_inlines @content ----------------------

S7::method(ast_text, pandoc_plain)               = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_paragraph)           = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_header)              = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_note_definition_para) = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_caption_block)       = function(x) ast_text(x@content)


# ---- block containers with pandoc_blocks @content -----------------------

S7::method(ast_text, pandoc_block_quote)             = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_div)                     = function(x) ast_text(x@content)
S7::method(ast_text, pandoc_note_definition_fenced_block) = function(x) ast_text(x@content)


# ---- list blocks --------------------------------------------------------

S7::method(ast_text, pandoc_ordered_list) = function(x) {
  paste(purrr::map_chr(x@content, ast_text), collapse = "\n")
}

S7::method(ast_text, pandoc_bullet_list) = function(x) {
  paste(purrr::map_chr(x@content, ast_text), collapse = "\n")
}

S7::method(ast_text, pandoc_line_block) = function(x) {
  paste(purrr::map_chr(x@content, ast_text), collapse = "\n")
}

S7::method(ast_text, pandoc_definition_list) = function(x) {
  paste(purrr::map_chr(x@content, ast_text), collapse = "\n\n")
}

S7::method(ast_text, pandoc_definition_item) = function(x) {
  term = ast_text(x@term)
  defs = paste(purrr::map_chr(x@defs, ast_text), collapse = "\n")
  paste0(term, "\n", defs)
}


# ---- figure / table -----------------------------------------------------

S7::method(ast_text, pandoc_figure) = function(x) {
  caption = ast_text(x@caption)
  body = ast_text(x@content)
  if (nzchar(caption)) paste0(body, "\n", caption) else body
}

S7::method(ast_text, pandoc_caption) = function(x) {
  short = if (is.null(x@short)) "" else ast_text(x@short)
  long  = ast_text(x@long)
  if (nzchar(short) && nzchar(long)) paste0(short, "\n", long)
  else if (nzchar(short)) short
  else long
}

S7::method(ast_text, pandoc_table) = function(x) {
  parts = c(
    ast_text(x@caption),
    ast_text(x@head),
    paste(purrr::map_chr(x@bodies, ast_text), collapse = "\n"),
    ast_text(x@foot)
  )
  paste(parts[nzchar(parts)], collapse = "\n")
}

S7::method(ast_text, pandoc_table_head) = function(x) {
  paste(purrr::map_chr(x@rows, ast_text), collapse = "\n")
}

S7::method(ast_text, pandoc_table_body) = function(x) {
  paste(purrr::map_chr(c(x@head_rows, x@body_rows), ast_text), collapse = "\n")
}

S7::method(ast_text, pandoc_table_foot) = function(x) {
  paste(purrr::map_chr(x@rows, ast_text), collapse = "\n")
}

S7::method(ast_text, pandoc_row) = function(x) {
  paste(purrr::map_chr(x@cells, ast_text), collapse = "\t")
}

S7::method(ast_text, pandoc_cell) = function(x) ast_text(x@content)


# ---- default fallback ---------------------------------------------------

S7::method(ast_text, pandoc_node) = function(x) {
  kids = tryCatch(pandoc_children(x), error = function(e) list())
  if (length(kids) == 0L) return("")
  paste(purrr::map_chr(kids, function(k) {
    if (is.null(k)) "" else ast_text(k)
  }), collapse = "")
}
