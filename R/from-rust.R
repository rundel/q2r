#' @include pd-ast-pandoc.R ts-ast.R
NULL

attr_from_list = function(x) {
  if (is.null(x)) return(pandoc_attr())
  attrs = if (length(x$keys)) stats::setNames(x$values, x$keys) else character()
  pandoc_attr(
    id         = x$id %||% "",
    classes    = x$classes %||% character(),
    attributes = attrs
  )
}

`%||%` = function(a, b) if (is.null(a)) b else a

inlines_from_list = function(items) {
  pandoc_inlines(lapply(items %||% list(), inline_from_list))
}

shortcode_arg_from_list = function(x) {
  kind = x$kind %||% "string"
  out = list(kind = kind)
  if (kind == "shortcode") {
    out$value = inline_from_list(x$value)
  } else if (kind == "kv") {
    out$key   = x$key %||% ""
    out$value = shortcode_arg_from_list(x$value)
  } else if (kind == "kv_group") {
    out$value = lapply(x$value %||% list(), shortcode_arg_from_list)
  } else {
    out$value = x$value
  }
  out
}

blocks_from_list = function(items) {
  pandoc_blocks(lapply(items %||% list(), block_from_list))
}

inline_from_list = function(x) {
  switch(x$tag,
    Str         = pandoc_str(text = x$text),
    Space       = pandoc_space(),
    SoftBreak   = pandoc_soft_break(),
    LineBreak   = pandoc_line_break(),
    Emph        = pandoc_emph(content = inlines_from_list(x$content)),
    Underline   = pandoc_underline(content = inlines_from_list(x$content)),
    Strong      = pandoc_strong(content = inlines_from_list(x$content)),
    Strikeout   = pandoc_strikeout(content = inlines_from_list(x$content)),
    Superscript = pandoc_superscript(content = inlines_from_list(x$content)),
    Subscript   = pandoc_subscript(content = inlines_from_list(x$content)),
    SmallCaps   = pandoc_small_caps(content = inlines_from_list(x$content)),
    Code        = pandoc_code(attr = attr_from_list(x$attr), text = x$text),
    Math        = pandoc_math(math_type = x$math_type, text = x$text),
    RawInline   = pandoc_raw_inline(format = x$format, text = x$text),
    Quoted      = pandoc_quoted(quote_type = x$quote_type, content = inlines_from_list(x$content)),
    Link        = pandoc_link(
      attr = attr_from_list(x$attr), content = inlines_from_list(x$content),
      url = x$url, title = x$title
    ),
    Image       = pandoc_image(
      attr = attr_from_list(x$attr), content = inlines_from_list(x$content),
      url = x$url, title = x$title
    ),
    Note        = pandoc_note(content = blocks_from_list(x$content)),
    Span        = pandoc_span(attr = attr_from_list(x$attr), content = inlines_from_list(x$content)),
    NoteReference = pandoc_note_reference(id = x$id),
    AttrInline  = pandoc_attr_inline(attr = attr_from_list(x$attr)),
    Insert      = pandoc_insert(attr = attr_from_list(x$attr), content = inlines_from_list(x$content)),
    Delete      = pandoc_delete(attr = attr_from_list(x$attr), content = inlines_from_list(x$content)),
    Highlight   = pandoc_highlight(attr = attr_from_list(x$attr), content = inlines_from_list(x$content)),
    EditComment = pandoc_edit_comment(attr = attr_from_list(x$attr), content = inlines_from_list(x$content)),
    Cite        = pandoc_cite(
      citations = lapply(x$citations %||% list(), citation_from_list),
      content = inlines_from_list(x$content)
    ),
    Shortcode   = {
      kw_in = x$keyword_args %||% list()
      kw_keys = vapply(kw_in, function(a) a$key %||% "", character(1L))
      kw_in = kw_in[order(kw_keys)]
      pandoc_shortcode(
        name            = x$name %||% "",
        is_escaped      = isTRUE(x$is_escaped),
        positional_args = lapply(x$positional_args %||% list(), shortcode_arg_from_list),
        keyword_args    = lapply(kw_in, shortcode_arg_from_list)
      )
    },
    CustomInline = pandoc_custom_inline(
      type_name = x$type_name %||% "",
      slots = x$slots %||% list(),
      attr = attr_from_list(x$attr)
    ),
    stop("unhandled inline tag: ", x$tag)
  )
}

block_from_list = function(x) {
  switch(x$tag,
    Plain          = pandoc_plain(content = inlines_from_list(x$content)),
    Paragraph      = pandoc_paragraph(content = inlines_from_list(x$content)),
    LineBlock      = pandoc_line_block(
      content = lapply(x$content %||% list(), inlines_from_list)
    ),
    CodeBlock      = pandoc_code_block(attr = attr_from_list(x$attr), text = x$text),
    RawBlock       = pandoc_raw_block(format = x$format, text = x$text),
    BlockQuote     = pandoc_block_quote(content = blocks_from_list(x$content)),
    OrderedList    = pandoc_ordered_list(
      attr = pandoc_list_attributes(start = x$start, style = x$style, delim = x$delim),
      content = lapply(x$items %||% list(), blocks_from_list)
    ),
    BulletList     = pandoc_bullet_list(
      content = lapply(x$items %||% list(), blocks_from_list)
    ),
    DefinitionList = pandoc_definition_list(
      content = lapply(x$items %||% list(), function(item) {
        pandoc_definition_item(
          term = inlines_from_list(item$term),
          defs = lapply(item$defs %||% list(), blocks_from_list)
        )
      })
    ),
    Header         = pandoc_header(
      level = as.integer(x$level), attr = attr_from_list(x$attr),
      content = inlines_from_list(x$content)
    ),
    HorizontalRule = pandoc_horizontal_rule(),
    Figure         = pandoc_figure(
      attr = attr_from_list(x$attr),
      caption = pandoc_caption(long = blocks_from_list(x$caption)),
      content = blocks_from_list(x$content)
    ),
    Div            = pandoc_div(attr = attr_from_list(x$attr), content = blocks_from_list(x$content)),
    Table          = pandoc_table(
      attr    = attr_from_list(x$attr),
      caption = caption_from_list(x$caption),
      colspec = lapply(x$colspec %||% list(), colspec_from_list),
      head    = table_head_from_list(x$head),
      bodies  = lapply(x$bodies %||% list(), table_body_from_list),
      foot    = table_foot_from_list(x$foot)
    ),
    BlockMetadata  = pandoc_block_metadata(meta = pandoc_meta_value()),
    NoteDefinitionPara = pandoc_note_definition_para(id = x$id, content = inlines_from_list(x$content)),
    NoteDefinitionFencedBlock = pandoc_note_definition_fenced_block(
      id = x$id, content = blocks_from_list(x$content)
    ),
    CaptionBlock   = pandoc_caption_block(content = inlines_from_list(x$content)),
    CustomBlock    = pandoc_custom_block(
      type_name = x$type_name %||% "",
      slots = x$slots %||% list(),
      attr = attr_from_list(x$attr)
    ),
    stop("unhandled block tag: ", x$tag)
  )
}

caption_from_list = function(x) {
  if (is.null(x)) return(pandoc_caption())
  short = if (is.null(x$short)) NULL else inlines_from_list(x$short)
  pandoc_caption(short = short, long = blocks_from_list(x$long))
}

colspec_from_list = function(x) {
  pandoc_col_spec(
    alignment = x$alignment %||% "Default",
    width     = x$width
  )
}

cell_from_list = function(x) {
  pandoc_cell(
    attr      = attr_from_list(x$attr),
    alignment = x$alignment %||% "Default",
    row_span  = as.integer(x$row_span %||% 1L),
    col_span  = as.integer(x$col_span %||% 1L),
    content   = blocks_from_list(x$content)
  )
}

row_from_list = function(x) {
  pandoc_row(
    attr  = attr_from_list(x$attr),
    cells = lapply(x$cells %||% list(), cell_from_list)
  )
}

table_head_from_list = function(x) {
  if (is.null(x)) return(pandoc_table_head())
  pandoc_table_head(
    attr = attr_from_list(x$attr),
    rows = lapply(x$rows %||% list(), row_from_list)
  )
}

table_body_from_list = function(x) {
  pandoc_table_body(
    attr             = attr_from_list(x$attr),
    row_head_columns = as.integer(x$row_head_columns %||% 0L),
    head_rows        = lapply(x$head_rows %||% list(), row_from_list),
    body_rows        = lapply(x$body_rows %||% list(), row_from_list)
  )
}

table_foot_from_list = function(x) {
  if (is.null(x)) return(pandoc_table_foot())
  pandoc_table_foot(
    attr = attr_from_list(x$attr),
    rows = lapply(x$rows %||% list(), row_from_list)
  )
}

citation_from_list = function(x) {
  pandoc_citation(
    id = x$id %||% "",
    mode = x$mode %||% "NormalCitation",
    prefix = inlines_from_list(x$prefix),
    suffix = inlines_from_list(x$suffix),
    note_num = as.integer(x$note_num %||% 0L),
    hash = as.integer(x$hash %||% 0L)
  )
}

pandoc_from_list = function(x) {
  if (is.null(x)) return(NULL)
  pandoc(
    meta = pandoc_meta_value(),
    blocks = blocks_from_list(x$blocks)
  )
}

ts_point_class_  = c("q2r::ts_point", "S7_object")
ts_range_class_  = c("q2r::ts_range", "S7_object")
ts_nodes_class_  = c("q2r::ts_nodes", "S7_object")
ts_node_class_   = c("q2r::ts_node",  "S7_object")

ts_point_fast = function(row, column) {
  o = S7::S7_object()
  attr(o, "class")    = ts_point_class_
  attr(o, "S7_class") = ts_point
  attr(o, "row")      = row
  attr(o, "column")   = column
  o
}

ts_range_fast = function(start_byte, end_byte, start_point, end_point) {
  o = S7::S7_object()
  attr(o, "class")       = ts_range_class_
  attr(o, "S7_class")    = ts_range
  attr(o, "start_byte")  = start_byte
  attr(o, "end_byte")    = end_byte
  attr(o, "start_point") = start_point
  attr(o, "end_point")   = end_point
  o
}

ts_nodes_fast = function(content) {
  o = S7::S7_object()
  attr(o, "class")    = ts_nodes_class_
  attr(o, "S7_class") = ts_nodes
  attr(o, "content")  = content
  o
}

ts_node_fast = function(kind, is_named, field_name, range, text, children) {
  o = S7::S7_object()
  attr(o, "class")      = ts_node_class_
  attr(o, "S7_class")   = ts_node
  attr(o, "kind")       = kind
  attr(o, "is_named")   = is_named
  attr(o, "field_name") = field_name
  attr(o, "range")      = range
  attr(o, "text")       = text
  attr(o, "children")   = children
  o
}

ts_node_from_list = function(x) {
  ts_node_fast(
    kind       = x$kind %||% "",
    is_named   = isTRUE(x$is_named),
    field_name = x$field_name,
    range      = ts_range_fast(
      start_byte  = as.integer(x$start_byte),
      end_byte    = as.integer(x$end_byte),
      start_point = ts_point_fast(
        as.integer(x$start_row),
        as.integer(x$start_col)
      ),
      end_point   = ts_point_fast(
        as.integer(x$end_row),
        as.integer(x$end_col)
      )
    ),
    text     = x$text,
    children = ts_nodes_fast(lapply(x$children %||% list(), ts_node_from_list))
  )
}

ts_tree_from_list = function(x) {
  if (is.null(x)) return(NULL)
  ts_tree(root = ts_node_from_list(x))
}
