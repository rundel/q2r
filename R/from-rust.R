#' @include pd-ast-pandoc.R ts-ast.R result.R
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
    Shortcode   = pandoc_shortcode(name = x$name %||% "", args = x$args %||% list()),
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
    Table          = pandoc_table(attr = attr_from_list(x$attr)),  # deep table conversion: TODO
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

ts_node_from_list = function(x) {
  ts_node(
    kind       = x$kind %||% "",
    is_named   = isTRUE(x$is_named),
    field_name = x$field_name,
    range      = ts_range(
      start_byte  = as.integer(x$start_byte),
      end_byte    = as.integer(x$end_byte),
      start_point = ts_point(
        row    = as.integer(x$start_row),
        column = as.integer(x$start_col)
      ),
      end_point   = ts_point(
        row    = as.integer(x$end_row),
        column = as.integer(x$end_col)
      )
    ),
    text     = x$text,
    children = ts_nodes(lapply(x$children %||% list(), ts_node_from_list))
  )
}

ts_tree_from_list = function(x) {
  if (is.null(x)) return(NULL)
  ts_tree(root = ts_node_from_list(x))
}
