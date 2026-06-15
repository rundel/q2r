#' @include pd-ast-pandoc.R ts-ast.R
NULL

# Returns the `class()` vector for an S7 class, e.g. for `pandoc_str`:
#   c("q2r::pandoc_str", "q2r::pandoc_inline", "q2r::pandoc_node", "S7_object")
# `pd_fast` skips the S7 constructor (which would stamp this chain itself), so
# we have to set it manually - otherwise `S7::S7_inherits()` and method dispatch
# on parent classes break. The chain is walked once per class via `@parent` and
# memoized in `cache` (keyed by `@name`); subsequent calls are an env lookup.
pd_chain = local({
  cache = new.env(parent = emptyenv(), hash = TRUE)
  function(cls) {
    key = cls@name
    hit = cache[[key]]
    if (!is.null(hit)) return(hit)
    out = character()
    cur = cls
    repeat {
      if (!inherits(cur, "S7_class")) break
      if (identical(cur@name, "S7_object")) {
        out = c(out, "S7_object")
        break
      }
      out = c(out, paste0(cur@package, "::", cur@name))
      par = cur@parent
      if (is.null(par)) break
      cur = par
    }
    cache[[key]] = out
    out
  }
})

pd_fast = function(cls, ...) {
  o = S7::S7_object()
  attributes(o) = c(list(class = pd_chain(cls), S7_class = cls), list(...))
  o
}

attr_from_list = function(x) {
  if (is.null(x)) {
    return(pd_fast(pandoc_attr,
      id         = "",
      classes    = character(),
      attributes = character()
    ))
  }
  attrs = if (length(x$keys)) stats::setNames(x$values, x$keys) else character()
  pd_fast(
    pandoc_attr,
    id         = x$id %||% "",
    classes    = x$classes %||% character(),
    attributes = attrs
  )
}

`%||%` = function(a, b) if (is.null(a)) b else a

inlines_from_list = function(items) {
  pd_fast(
    pandoc_inlines, 
    content = lapply(items %||% list(), inline_from_list)
  )
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
  pd_fast(
    pandoc_blocks, 
    content = lapply(items %||% list(), block_from_list)
  )
}

inline_from_list = function(x) {
  switch(x$tag,
    Str         = pd_fast(pandoc_str, text = x$text),
    Space       = pd_fast(pandoc_space),
    SoftBreak   = pd_fast(pandoc_soft_break),
    LineBreak   = pd_fast(pandoc_line_break),
    Emph        = pd_fast(pandoc_emph, content = inlines_from_list(x$content)),
    Underline   = pd_fast(pandoc_underline, content = inlines_from_list(x$content)),
    Strong      = pd_fast(pandoc_strong, content = inlines_from_list(x$content)),
    Strikeout   = pd_fast(pandoc_strikeout, content = inlines_from_list(x$content)),
    Superscript = pd_fast(pandoc_superscript, content = inlines_from_list(x$content)),
    Subscript   = pd_fast(pandoc_subscript, content = inlines_from_list(x$content)),
    SmallCaps   = pd_fast(pandoc_small_caps, content = inlines_from_list(x$content)),
    Code        = pd_fast(pandoc_code, attr = attr_from_list(x$attr), text = x$text),
    Math        = pd_fast(pandoc_math, math_type = x$math_type, text = x$text),
    RawInline   = pd_fast(pandoc_raw_inline, format = x$format, text = x$text),
    Quoted      = pd_fast(pandoc_quoted, quote_type = x$quote_type, content = inlines_from_list(x$content)),
    Link        = pd_fast(pandoc_link,
      attr = attr_from_list(x$attr), content = inlines_from_list(x$content),
      url = x$url, title = x$title
    ),
    Image       = pd_fast(pandoc_image,
      attr = attr_from_list(x$attr), content = inlines_from_list(x$content),
      url = x$url, title = x$title
    ),
    Note        = pd_fast(pandoc_note, content = blocks_from_list(x$content)),
    Span        = pd_fast(pandoc_span, attr = attr_from_list(x$attr), content = inlines_from_list(x$content)),
    NoteReference = pd_fast(pandoc_note_reference, id = x$id),
    AttrInline  = pd_fast(pandoc_attr_inline, attr = attr_from_list(x$attr)),
    Insert      = pd_fast(pandoc_insert, attr = attr_from_list(x$attr), content = inlines_from_list(x$content)),
    Delete      = pd_fast(pandoc_delete, attr = attr_from_list(x$attr), content = inlines_from_list(x$content)),
    Highlight   = pd_fast(pandoc_highlight, attr = attr_from_list(x$attr), content = inlines_from_list(x$content)),
    EditComment = pd_fast(pandoc_edit_comment, attr = attr_from_list(x$attr), content = inlines_from_list(x$content)),
    Cite        = pd_fast(pandoc_cite,
      citations = lapply(x$citations %||% list(), citation_from_list),
      content = inlines_from_list(x$content)
    ),
    Shortcode   = {
      kw_in = x$keyword_args %||% list()
      kw_keys = vapply(kw_in, function(a) a$key %||% "", character(1L))
      kw_in = kw_in[order(kw_keys)]
      pd_fast(pandoc_shortcode,
        name            = x$name %||% "",
        is_escaped      = isTRUE(x$is_escaped),
        positional_args = lapply(x$positional_args %||% list(), shortcode_arg_from_list),
        keyword_args    = lapply(kw_in, shortcode_arg_from_list)
      )
    },
    CustomInline = pd_fast(pandoc_custom_inline,
      type_name = x$type_name %||% "",
      slots = x$slots %||% list(),
      attr = attr_from_list(x$attr)
    ),
    stop("unhandled inline tag: ", x$tag)
  )
}

block_from_list = function(x) {
  switch(x$tag,
    Plain          = pd_fast(pandoc_plain, content = inlines_from_list(x$content)),
    Paragraph      = pd_fast(pandoc_paragraph, content = inlines_from_list(x$content)),
    LineBlock      = pd_fast(pandoc_line_block,
      content = lapply(x$content %||% list(), inlines_from_list)
    ),
    CodeBlock      = pd_fast(pandoc_code_block, attr = attr_from_list(x$attr), text = x$text),
    RawBlock       = pd_fast(pandoc_raw_block, format = x$format, text = x$text),
    BlockQuote     = pd_fast(pandoc_block_quote, content = blocks_from_list(x$content)),
    OrderedList    = pd_fast(pandoc_ordered_list,
      attr = pd_fast(pandoc_list_attributes, start = x$start, style = x$style, delim = x$delim),
      content = lapply(x$items %||% list(), blocks_from_list)
    ),
    BulletList     = pd_fast(pandoc_bullet_list,
      content = lapply(x$items %||% list(), blocks_from_list)
    ),
    DefinitionList = pd_fast(pandoc_definition_list,
      content = lapply(x$items %||% list(), function(item) {
        pd_fast(pandoc_definition_item,
          term = inlines_from_list(item$term),
          defs = lapply(item$defs %||% list(), blocks_from_list)
        )
      })
    ),
    Header         = pd_fast(pandoc_header,
      level = as.integer(x$level), attr = attr_from_list(x$attr),
      content = inlines_from_list(x$content)
    ),
    HorizontalRule = pd_fast(pandoc_horizontal_rule),
    Figure         = pd_fast(pandoc_figure,
      attr = attr_from_list(x$attr),
      caption = pd_fast(pandoc_caption, long = blocks_from_list(x$caption)),
      content = blocks_from_list(x$content)
    ),
    Div            = pd_fast(pandoc_div, attr = attr_from_list(x$attr), content = blocks_from_list(x$content)),
    Table          = pd_fast(pandoc_table,
      attr    = attr_from_list(x$attr),
      caption = caption_from_list(x$caption),
      colspec = lapply(x$colspec %||% list(), colspec_from_list),
      head    = table_head_from_list(x$head),
      bodies  = lapply(x$bodies %||% list(), table_body_from_list),
      foot    = table_foot_from_list(x$foot)
    ),
    BlockMetadata  = pd_fast(pandoc_block_metadata, meta = pandoc_meta_value()),
    NoteDefinitionPara = pd_fast(pandoc_note_definition_para, id = x$id, content = inlines_from_list(x$content)),
    NoteDefinitionFencedBlock = pd_fast(pandoc_note_definition_fenced_block,
      id = x$id, content = blocks_from_list(x$content)
    ),
    CaptionBlock   = pd_fast(pandoc_caption_block, content = inlines_from_list(x$content)),
    CustomBlock    = pd_fast(pandoc_custom_block,
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
  pd_fast(pandoc_caption, short = short, long = blocks_from_list(x$long))
}

colspec_from_list = function(x) {
  pd_fast(pandoc_col_spec,
    alignment = x$alignment %||% "Default",
    width     = x$width
  )
}

cell_from_list = function(x) {
  pd_fast(pandoc_cell,
    attr      = attr_from_list(x$attr),
    alignment = x$alignment %||% "Default",
    row_span  = as.integer(x$row_span %||% 1L),
    col_span  = as.integer(x$col_span %||% 1L),
    content   = blocks_from_list(x$content)
  )
}

row_from_list = function(x) {
  pd_fast(pandoc_row,
    attr  = attr_from_list(x$attr),
    cells = lapply(x$cells %||% list(), cell_from_list)
  )
}

table_head_from_list = function(x) {
  if (is.null(x)) return(pandoc_table_head())
  pd_fast(pandoc_table_head,
    attr = attr_from_list(x$attr),
    rows = lapply(x$rows %||% list(), row_from_list)
  )
}

table_body_from_list = function(x) {
  pd_fast(pandoc_table_body,
    attr             = attr_from_list(x$attr),
    row_head_columns = as.integer(x$row_head_columns %||% 0L),
    head_rows        = lapply(x$head_rows %||% list(), row_from_list),
    body_rows        = lapply(x$body_rows %||% list(), row_from_list)
  )
}

table_foot_from_list = function(x) {
  if (is.null(x)) return(pandoc_table_foot())
  pd_fast(pandoc_table_foot,
    attr = attr_from_list(x$attr),
    rows = lapply(x$rows %||% list(), row_from_list)
  )
}

citation_from_list = function(x) {
  pd_fast(pandoc_citation,
    id = x$id %||% "",
    mode = x$mode %||% "NormalCitation",
    prefix = inlines_from_list(x$prefix),
    suffix = inlines_from_list(x$suffix),
    note_num = as.integer(x$note_num %||% 0L),
    hash = as.integer(x$hash %||% 0L)
  )
}

meta_from_list = function(x) {
  if (is.null(x)) return(pandoc_meta_value(kind = "map", value = list()))
  kind = x$kind
  value = switch(kind,
    map = purrr::set_names(
      purrr::map(x$values %||% list(), meta_from_list),
      x$keys %||% character()
    ),
    list    = purrr::map(x$value %||% list(), meta_from_list),
    inlines = inlines_from_list(x$value),
    blocks  = blocks_from_list(x$value),
    null    = NULL,
    x$value
  )
  pandoc_meta_value(kind = kind, value = value)
}

pandoc_from_list = function(x) {
  if (is.null(x)) return(NULL)
  pandoc(
    meta = meta_from_list(x$meta),
    blocks = blocks_from_list(x$blocks)
  )
}

ts_point_class_  = c("q2r::ts_point", "S7_object")
ts_range_class_  = c("q2r::ts_range", "S7_object")
ts_nodes_class_  = c("q2r::ts_nodes", "S7_object")
ts_node_class_   = c("q2r::ts_node",  "S7_object")

ts_point_fast = function(row, column) {
  o = S7::S7_object()
  attributes(o) = list(class = ts_point_class_, S7_class = ts_point,
                       row = row, column = column)
  o
}

ts_range_fast = function(start_byte, end_byte, start_point, end_point) {
  o = S7::S7_object()
  attributes(o) = list(class = ts_range_class_, S7_class = ts_range,
                       start_byte = start_byte, end_byte = end_byte,
                       start_point = start_point, end_point = end_point)
  o
}

ts_nodes_fast = function(content) {
  o = S7::S7_object()
  attributes(o) = list(class = ts_nodes_class_, S7_class = ts_nodes,
                       content = content)
  o
}

ts_node_fast = function(kind, is_named, field_name, range, text, children) {
  o = S7::S7_object()
  attributes(o) = list(class = ts_node_class_, S7_class = ts_node,
                       kind = kind, is_named = is_named, field_name = field_name,
                       range = range, text = text, children = children)
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
