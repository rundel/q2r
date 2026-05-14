#' @include pd-ast-pandoc.R pd-ast-block.R pd-ast-inline.R pd-ast-support.R select.R
NULL

# Internal generic: rewrite the direct "selectable" children of a pandoc
# node by applying `.f` to each one and reassembling. Selectable children
# are pandoc_node descendants and any support type that lives in a list
# slot (pandoc_citation, pandoc_definition_item, pandoc_table_body,
# pandoc_row, pandoc_cell, pandoc_col_spec). Singular support-type
# slots (pandoc_caption, pandoc_table_head, pandoc_table_foot, the
# pandoc_blocks/inlines wrappers themselves) are not exposed to `.f`;
# the walker descends through them but their contents are what .f sees.
#
# `.f` may return a single node (replace), a list of nodes (splice),
# or NULL (delete). The flattened result must satisfy the parent slot's
# S7 validator; mismatched types or empty results in singular slots will
# raise.
#
# Single-level operation: callers wire recursion via a `.f` that calls
# back into the walker.
pandoc_modify_children = S7::new_generic("pandoc_modify_children", "x")

pd_flatten_results = function(results) {
  purrr::list_flatten(purrr::map(results, ast_to_node_list))
}

pd_rewrite_inlines_content = function(wrapper, .f) {
  pandoc_inlines(pd_flatten_results(purrr::map(wrapper@content, .f)))
}

pd_rewrite_blocks_content = function(wrapper, .f) {
  pandoc_blocks(pd_flatten_results(purrr::map(wrapper@content, .f)))
}

pd_rewrite_list_of_blocks = function(items, .f) {
  purrr::map(items, function(w) pd_rewrite_blocks_content(w, .f))
}

pd_rewrite_list_of_inlines = function(items, .f) {
  purrr::map(items, function(w) pd_rewrite_inlines_content(w, .f))
}


# ---- leaves and abstract default ----------------------------------------

S7::method(pandoc_modify_children, pandoc_node) = function(x, .f) x

S7::method(pandoc_modify_children, pandoc) = function(x, .f) {
  pandoc(
    meta        = x@meta,
    blocks      = pd_rewrite_blocks_content(x@blocks, .f),
    diagnostics = x@diagnostics
  )
}


# ---- blocks with pandoc_inlines @content --------------------------------

S7::method(pandoc_modify_children, pandoc_plain) = function(x, .f) {
  pandoc_plain(content = pd_rewrite_inlines_content(x@content, .f))
}

S7::method(pandoc_modify_children, pandoc_paragraph) = function(x, .f) {
  pandoc_paragraph(content = pd_rewrite_inlines_content(x@content, .f))
}

S7::method(pandoc_modify_children, pandoc_header) = function(x, .f) {
  pandoc_header(
    level   = x@level,
    attr    = x@attr,
    content = pd_rewrite_inlines_content(x@content, .f)
  )
}

S7::method(pandoc_modify_children, pandoc_note_definition_para) = function(x, .f) {
  pandoc_note_definition_para(
    id      = x@id,
    content = pd_rewrite_inlines_content(x@content, .f)
  )
}

S7::method(pandoc_modify_children, pandoc_caption_block) = function(x, .f) {
  pandoc_caption_block(content = pd_rewrite_inlines_content(x@content, .f))
}


# ---- blocks with pandoc_blocks @content ---------------------------------

S7::method(pandoc_modify_children, pandoc_block_quote) = function(x, .f) {
  pandoc_block_quote(content = pd_rewrite_blocks_content(x@content, .f))
}

S7::method(pandoc_modify_children, pandoc_div) = function(x, .f) {
  pandoc_div(
    attr    = x@attr,
    content = pd_rewrite_blocks_content(x@content, .f)
  )
}

S7::method(pandoc_modify_children, pandoc_note_definition_fenced_block) = function(x, .f) {
  pandoc_note_definition_fenced_block(
    id      = x@id,
    content = pd_rewrite_blocks_content(x@content, .f)
  )
}


# ---- blocks with list-of-pandoc_blocks @content -------------------------

S7::method(pandoc_modify_children, pandoc_ordered_list) = function(x, .f) {
  pandoc_ordered_list(
    attr    = x@attr,
    content = pd_rewrite_list_of_blocks(x@content, .f)
  )
}

S7::method(pandoc_modify_children, pandoc_bullet_list) = function(x, .f) {
  pandoc_bullet_list(content = pd_rewrite_list_of_blocks(x@content, .f))
}


# ---- pandoc_line_block: list of pandoc_inlines --------------------------

S7::method(pandoc_modify_children, pandoc_line_block) = function(x, .f) {
  pandoc_line_block(content = pd_rewrite_list_of_inlines(x@content, .f))
}


# ---- pandoc_figure ------------------------------------------------------

S7::method(pandoc_modify_children, pandoc_figure) = function(x, .f) {
  pandoc_figure(
    attr    = x@attr,
    caption = pandoc_modify_children(x@caption, .f),
    content = pd_rewrite_blocks_content(x@content, .f)
  )
}


# ---- pandoc_table -------------------------------------------------------
# Bodies are a list slot, so .f IS invoked on each pandoc_table_body.
# Head, foot, and caption are singular and pass through pandoc_modify_children.

S7::method(pandoc_modify_children, pandoc_table) = function(x, .f) {
  pandoc_table(
    attr    = x@attr,
    caption = pandoc_modify_children(x@caption, .f),
    colspec = x@colspec,
    head    = pandoc_modify_children(x@head, .f),
    bodies  = pd_flatten_results(purrr::map(x@bodies, .f)),
    foot    = pandoc_modify_children(x@foot, .f)
  )
}

S7::method(pandoc_modify_children, pandoc_table_head) = function(x, .f) {
  pandoc_table_head(
    attr = x@attr,
    rows = pd_flatten_results(purrr::map(x@rows, .f))
  )
}

S7::method(pandoc_modify_children, pandoc_table_body) = function(x, .f) {
  pandoc_table_body(
    attr             = x@attr,
    row_head_columns = x@row_head_columns,
    head_rows        = pd_flatten_results(purrr::map(x@head_rows, .f)),
    body_rows        = pd_flatten_results(purrr::map(x@body_rows, .f))
  )
}

S7::method(pandoc_modify_children, pandoc_table_foot) = function(x, .f) {
  pandoc_table_foot(
    attr = x@attr,
    rows = pd_flatten_results(purrr::map(x@rows, .f))
  )
}

S7::method(pandoc_modify_children, pandoc_row) = function(x, .f) {
  pandoc_row(
    attr  = x@attr,
    cells = pd_flatten_results(purrr::map(x@cells, .f))
  )
}

S7::method(pandoc_modify_children, pandoc_cell) = function(x, .f) {
  pandoc_cell(
    attr      = x@attr,
    alignment = x@alignment,
    row_span  = x@row_span,
    col_span  = x@col_span,
    content   = pd_rewrite_blocks_content(x@content, .f)
  )
}

S7::method(pandoc_modify_children, pandoc_caption) = function(x, .f) {
  short = if (is.null(x@short)) NULL else pd_rewrite_inlines_content(x@short, .f)
  pandoc_caption(
    short = short,
    long  = pd_rewrite_blocks_content(x@long, .f)
  )
}


# ---- pandoc_definition_list / item ---------------------------------------

S7::method(pandoc_modify_children, pandoc_definition_list) = function(x, .f) {
  pandoc_definition_list(
    content = pd_flatten_results(purrr::map(x@content, .f))
  )
}

S7::method(pandoc_modify_children, pandoc_definition_item) = function(x, .f) {
  pandoc_definition_item(
    term = pd_rewrite_inlines_content(x@term, .f),
    defs = pd_rewrite_list_of_blocks(x@defs, .f)
  )
}


# ---- inlines with pandoc_inlines @content -------------------------------

pd_modify_inline_wrap = function(cls) {
  function(x, .f) {
    cls(content = pd_rewrite_inlines_content(x@content, .f))
  }
}

S7::method(pandoc_modify_children, pandoc_emph)         = pd_modify_inline_wrap(pandoc_emph)
S7::method(pandoc_modify_children, pandoc_underline)    = pd_modify_inline_wrap(pandoc_underline)
S7::method(pandoc_modify_children, pandoc_strong)       = pd_modify_inline_wrap(pandoc_strong)
S7::method(pandoc_modify_children, pandoc_strikeout)    = pd_modify_inline_wrap(pandoc_strikeout)
S7::method(pandoc_modify_children, pandoc_superscript)  = pd_modify_inline_wrap(pandoc_superscript)
S7::method(pandoc_modify_children, pandoc_subscript)    = pd_modify_inline_wrap(pandoc_subscript)
S7::method(pandoc_modify_children, pandoc_small_caps)   = pd_modify_inline_wrap(pandoc_small_caps)

S7::method(pandoc_modify_children, pandoc_quoted) = function(x, .f) {
  pandoc_quoted(
    quote_type = x@quote_type,
    content    = pd_rewrite_inlines_content(x@content, .f)
  )
}

S7::method(pandoc_modify_children, pandoc_link) = function(x, .f) {
  pandoc_link(
    attr    = x@attr,
    content = pd_rewrite_inlines_content(x@content, .f),
    url     = x@url,
    title   = x@title
  )
}

S7::method(pandoc_modify_children, pandoc_image) = function(x, .f) {
  pandoc_image(
    attr    = x@attr,
    content = pd_rewrite_inlines_content(x@content, .f),
    url     = x@url,
    title   = x@title
  )
}

S7::method(pandoc_modify_children, pandoc_span) = function(x, .f) {
  pandoc_span(
    attr    = x@attr,
    content = pd_rewrite_inlines_content(x@content, .f)
  )
}

pd_modify_critic_wrap = function(cls) {
  function(x, .f) {
    cls(
      attr    = x@attr,
      content = pd_rewrite_inlines_content(x@content, .f)
    )
  }
}

S7::method(pandoc_modify_children, pandoc_insert)       = pd_modify_critic_wrap(pandoc_insert)
S7::method(pandoc_modify_children, pandoc_delete)       = pd_modify_critic_wrap(pandoc_delete)
S7::method(pandoc_modify_children, pandoc_highlight)    = pd_modify_critic_wrap(pandoc_highlight)
S7::method(pandoc_modify_children, pandoc_edit_comment) = pd_modify_critic_wrap(pandoc_edit_comment)


# ---- inline with pandoc_blocks @content ---------------------------------

S7::method(pandoc_modify_children, pandoc_note) = function(x, .f) {
  pandoc_note(content = pd_rewrite_blocks_content(x@content, .f))
}


# ---- pandoc_cite: listy @citations + pandoc_inlines @content ------------

S7::method(pandoc_modify_children, pandoc_cite) = function(x, .f) {
  pandoc_cite(
    citations = pd_flatten_results(purrr::map(x@citations, .f)),
    content   = pd_rewrite_inlines_content(x@content, .f)
  )
}

S7::method(pandoc_modify_children, pandoc_citation) = function(x, .f) {
  pandoc_citation(
    id       = x@id,
    mode     = x@mode,
    prefix   = pd_rewrite_inlines_content(x@prefix, .f),
    suffix   = pd_rewrite_inlines_content(x@suffix, .f),
    note_num = x@note_num,
    hash     = x@hash
  )
}
