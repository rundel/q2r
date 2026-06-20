#' @include pd-ast-pandoc.R pd-ast-block.R pd-ast-inline.R pd-ast-support.R
NULL

attr_to_list = function(attr) {
  keys = names(attr@attributes) %||% character()
  values = unname(attr@attributes) %||% character()
  list(
    id      = attr@id,
    classes = as.character(attr@classes),
    keys    = as.character(keys),
    values  = as.character(values)
  )
}

inlines_to_list = function(x) {
  lapply(x@content, inline_to_list)
}

blocks_to_list = function(x) {
  lapply(x@content, block_to_list)
}

citation_to_list = function(x) {
  list(
    id       = x@id,
    mode     = x@mode,
    prefix   = inlines_to_list(x@prefix),
    suffix   = inlines_to_list(x@suffix),
    note_num = as.integer(x@note_num),
    hash     = as.integer(x@hash)
  )
}

inline_to_list = function(x) {
  if (S7::S7_inherits(x, pandoc_str))         return(list(tag = "Str", text = x@text))
  if (S7::S7_inherits(x, pandoc_space))       return(list(tag = "Space"))
  if (S7::S7_inherits(x, pandoc_soft_break))  return(list(tag = "SoftBreak"))
  if (S7::S7_inherits(x, pandoc_line_break))  return(list(tag = "LineBreak"))
  if (S7::S7_inherits(x, pandoc_emph))        return(list(tag = "Emph",        content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_underline))   return(list(tag = "Underline",   content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_strong))      return(list(tag = "Strong",      content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_strikeout))   return(list(tag = "Strikeout",   content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_superscript)) return(list(tag = "Superscript", content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_subscript))   return(list(tag = "Subscript",   content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_small_caps))  return(list(tag = "SmallCaps",   content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_code))        return(list(tag = "Code", attr = attr_to_list(x@attr), text = x@text))
  if (S7::S7_inherits(x, pandoc_math))        return(list(tag = "Math", math_type = x@math_type, text = x@text))
  if (S7::S7_inherits(x, pandoc_raw_inline))  return(list(tag = "RawInline", format = x@format, text = x@text))
  if (S7::S7_inherits(x, pandoc_quoted))      return(list(tag = "Quoted", quote_type = x@quote_type, content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_link))        return(list(
    tag = "Link", attr = attr_to_list(x@attr), content = inlines_to_list(x@content),
    url = x@url, title = x@title
  ))
  if (S7::S7_inherits(x, pandoc_image))       return(list(
    tag = "Image", attr = attr_to_list(x@attr), content = inlines_to_list(x@content),
    url = x@url, title = x@title
  ))
  if (S7::S7_inherits(x, pandoc_note))        return(list(tag = "Note",  content = blocks_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_span))        return(list(tag = "Span",  attr = attr_to_list(x@attr), content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_cite))        return(list(
    tag = "Cite", citations = lapply(x@citations, citation_to_list),
    content = inlines_to_list(x@content)
  ))
  if (S7::S7_inherits(x, pandoc_note_reference)) return(list(tag = "NoteReference", id = x@id))
  if (S7::S7_inherits(x, pandoc_attr_inline))    return(list(tag = "AttrInline", attr = attr_to_list(x@attr)))
  if (S7::S7_inherits(x, pandoc_insert))         return(list(tag = "Insert",      attr = attr_to_list(x@attr), content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_delete))         return(list(tag = "Delete",      attr = attr_to_list(x@attr), content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_highlight))      return(list(tag = "Highlight",   attr = attr_to_list(x@attr), content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_edit_comment))   return(list(tag = "EditComment", attr = attr_to_list(x@attr), content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_shortcode))      return(list(
    tag             = "Shortcode",
    name            = x@name,
    is_escaped      = isTRUE(x@is_escaped),
    positional_args = lapply(x@positional_args, shortcode_arg_to_list),
    keyword_args    = lapply(x@keyword_args, shortcode_arg_to_list)
  ))
  if (S7::S7_inherits(x, pandoc_custom_inline)) {
    stop("to_qmd(): pandoc_custom_inline is not yet supported by the QMD ",
         "writer (pampa cannot render CustomInline back to QMD)", call. = FALSE)
  }
  stop("to-rust: unhandled inline class '", pandoc_class_name(x), "'")
}

# Inverse of `shortcode_arg_from_list` (from-rust.R): re-serialize a stored
# shortcode-argument record into the tagged-list wire shape Rust's
# `shortcode_arg_from_r` expects. A nested `shortcode` arg holds an S7
# `pandoc_shortcode` that must be re-emitted as a tagged `Shortcode` inline,
# and `kv` / `kv_group` recurse; without this the nested S7 object reaches
# Rust verbatim and the writer fails.
shortcode_arg_to_list = function(a) {
  kind = a$kind %||% "string"
  if (kind == "shortcode") {
    list(kind = "shortcode", value = inline_to_list(a$value))
  } else if (kind == "kv") {
    list(kind = "kv", key = a$key %||% "", value = shortcode_arg_to_list(a$value))
  } else if (kind == "kv_group") {
    list(kind = "kv_group", value = lapply(a$value %||% list(), shortcode_arg_to_list))
  } else {
    list(kind = kind, value = a$value)
  }
}

block_to_list = function(x) {
  if (S7::S7_inherits(x, pandoc_plain))      return(list(tag = "Plain",     content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_paragraph))  return(list(tag = "Paragraph", content = inlines_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_line_block)) return(list(
    tag = "LineBlock",
    content = lapply(x@content, inlines_to_list)
  ))
  if (S7::S7_inherits(x, pandoc_code_block)) return(list(tag = "CodeBlock", attr = attr_to_list(x@attr), text = x@text))
  if (S7::S7_inherits(x, pandoc_raw_block))  return(list(tag = "RawBlock",  format = x@format, text = x@text))
  if (S7::S7_inherits(x, pandoc_block_quote)) return(list(tag = "BlockQuote", content = blocks_to_list(x@content)))
  if (S7::S7_inherits(x, pandoc_ordered_list)) return(list(
    tag   = "OrderedList",
    start = as.integer(x@attr@start),
    style = x@attr@style,
    delim = x@attr@delim,
    items = lapply(x@content, blocks_to_list)
  ))
  if (S7::S7_inherits(x, pandoc_bullet_list)) return(list(
    tag   = "BulletList",
    items = lapply(x@content, blocks_to_list)
  ))
  if (S7::S7_inherits(x, pandoc_definition_list)) return(list(
    tag   = "DefinitionList",
    items = lapply(x@content, function(item) list(
      term = inlines_to_list(item@term),
      defs = lapply(item@defs, blocks_to_list)
    ))
  ))
  if (S7::S7_inherits(x, pandoc_header))         return(list(
    tag = "Header", level = as.integer(x@level),
    attr = attr_to_list(x@attr), content = inlines_to_list(x@content)
  ))
  if (S7::S7_inherits(x, pandoc_horizontal_rule)) return(list(tag = "HorizontalRule"))
  if (S7::S7_inherits(x, pandoc_figure))         return(list(
    tag = "Figure", attr = attr_to_list(x@attr),
    caption = caption_to_list(x@caption),
    content = blocks_to_list(x@content)
  ))
  if (S7::S7_inherits(x, pandoc_div))            return(list(
    tag = "Div", attr = attr_to_list(x@attr), content = blocks_to_list(x@content)
  ))
  if (S7::S7_inherits(x, pandoc_note_definition_para)) return(list(
    tag = "NoteDefinitionPara", id = x@id, content = inlines_to_list(x@content)
  ))
  if (S7::S7_inherits(x, pandoc_note_definition_fenced_block)) return(list(
    tag = "NoteDefinitionFencedBlock", id = x@id, content = blocks_to_list(x@content)
  ))
  if (S7::S7_inherits(x, pandoc_caption_block)) return(list(
    tag = "CaptionBlock", content = inlines_to_list(x@content)
  ))
  if (S7::S7_inherits(x, pandoc_table)) return(table_to_list(x))
  if (S7::S7_inherits(x, pandoc_block_metadata)) {
    stop("to_qmd(): pandoc_block_metadata is not yet supported by the QMD ",
         "writer (pampa cannot render BlockMetadata back to QMD)", call. = FALSE)
  }
  if (S7::S7_inherits(x, pandoc_custom_block)) {
    stop("to_qmd(): pandoc_custom_block is not yet supported by the QMD ",
         "writer (pampa cannot render CustomBlock back to QMD)", call. = FALSE)
  }
  stop("to-rust: unhandled block class '", pandoc_class_name(x), "'")
}

caption_to_list = function(x) {
  list(
    short = if (is.null(x@short)) NULL else inlines_to_list(x@short),
    long  = blocks_to_list(x@long)
  )
}

colspec_to_list = function(x) {
  list(alignment = x@alignment, width = x@width)
}

cell_to_list = function(x) {
  list(
    attr      = attr_to_list(x@attr),
    alignment = x@alignment,
    row_span  = as.integer(x@row_span),
    col_span  = as.integer(x@col_span),
    content   = blocks_to_list(x@content)
  )
}

row_to_list = function(x) {
  list(attr = attr_to_list(x@attr), cells = lapply(x@cells, cell_to_list))
}

table_head_to_list = function(x) {
  list(attr = attr_to_list(x@attr), rows = lapply(x@rows, row_to_list))
}

table_body_to_list = function(x) {
  list(
    attr             = attr_to_list(x@attr),
    row_head_columns = as.integer(x@row_head_columns),
    head_rows        = lapply(x@head_rows, row_to_list),
    body_rows        = lapply(x@body_rows, row_to_list)
  )
}

table_foot_to_list = function(x) {
  list(attr = attr_to_list(x@attr), rows = lapply(x@rows, row_to_list))
}

table_to_list = function(x) {
  list(
    tag     = "Table",
    attr    = attr_to_list(x@attr),
    caption = caption_to_list(x@caption),
    colspec = lapply(x@colspec, colspec_to_list),
    head    = table_head_to_list(x@head),
    bodies  = lapply(x@bodies, table_body_to_list),
    foot    = table_foot_to_list(x@foot)
  )
}

meta_to_list = function(m) {
  kind = m@kind
  v = m@value
  switch(kind,
    map = list(
      kind = "map",
      keys = names(v) %||% character(),
      values = unname(purrr::map(v, meta_to_list))
    ),
    list    = list(kind = "list", value = unname(purrr::map(v, meta_to_list))),
    inlines = list(kind = "inlines", value = inlines_to_list(v)),
    blocks  = list(kind = "blocks", value = blocks_to_list(v)),
    null    = list(kind = "null"),
    list(kind = kind, value = v)
  )
}

pandoc_to_list = function(x) {
  list(tag = "Pandoc", meta = meta_to_list(x@meta), blocks = blocks_to_list(x@blocks))
}
