#' @include ast-support.R
NULL

#' Plain block
#' @export
pandoc_plain = S7::new_class(
  "pandoc_plain",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list()))
  )
)

#' Paragraph
#' @export
pandoc_paragraph = S7::new_class(
  "pandoc_paragraph",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list()))
  )
)

#' Line block
#' @export
pandoc_line_block = S7::new_class(
  "pandoc_line_block",
  package = "q2r",
  parent = pandoc_block,
  properties = list(content = S7::new_property(S7::class_list, default = list())),
  validator = function(self) {
    ok = vapply(self@content, function(x) S7::S7_inherits(x, pandoc_inlines), logical(1))
    if (!all(ok)) "@content must be a list of pandoc_inlines objects"
  }
)

#' Code block
#' @export
pandoc_code_block = S7::new_class(
  "pandoc_code_block",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    attr = S7::new_property(pandoc_attr, default = pandoc_attr()),
    text = S7::new_property(S7::class_character, default = "")
  )
)

#' Raw block
#' @export
pandoc_raw_block = S7::new_class(
  "pandoc_raw_block",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    format = S7::new_property(S7::class_character, default = ""),
    text   = S7::new_property(S7::class_character, default = "")
  )
)

#' Block quote
#' @export
pandoc_block_quote = S7::new_class(
  "pandoc_block_quote",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    content = S7::new_property(pandoc_blocks, default = pandoc_blocks(list()))
  )
)

#' Ordered list
#' @export
pandoc_ordered_list = S7::new_class(
  "pandoc_ordered_list",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    attr    = S7::new_property(pandoc_list_attributes, default = pandoc_list_attributes()),
    content = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    ok = vapply(self@content, function(x) S7::S7_inherits(x, pandoc_blocks), logical(1))
    if (!all(ok)) "@content must be a list of pandoc_blocks (one per list item)"
  }
)

#' Bullet list
#' @export
pandoc_bullet_list = S7::new_class(
  "pandoc_bullet_list",
  package = "q2r",
  parent = pandoc_block,
  properties = list(content = S7::new_property(S7::class_list, default = list())),
  validator = function(self) {
    ok = vapply(self@content, function(x) S7::S7_inherits(x, pandoc_blocks), logical(1))
    if (!all(ok)) "@content must be a list of pandoc_blocks (one per list item)"
  }
)

#' Definition list
#' @export
pandoc_definition_list = S7::new_class(
  "pandoc_definition_list",
  package = "q2r",
  parent = pandoc_block,
  properties = list(content = S7::new_property(S7::class_list, default = list())),
  validator = function(self) {
    ok = vapply(self@content, function(x) S7::S7_inherits(x, pandoc_definition_item), logical(1))
    if (!all(ok)) "@content must be a list of pandoc_definition_item objects"
  }
)

#' Header
#' @export
pandoc_header = S7::new_class(
  "pandoc_header",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    level   = S7::new_property(S7::class_integer, default = 1L),
    attr    = S7::new_property(pandoc_attr, default = pandoc_attr()),
    content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list()))
  )
)

#' Horizontal rule
#' @export
pandoc_horizontal_rule = S7::new_class(
  "pandoc_horizontal_rule",
  package = "q2r",
  parent = pandoc_block
)

#' Figure
#' @export
pandoc_figure = S7::new_class(
  "pandoc_figure",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = pandoc_attr()),
    caption = S7::new_property(pandoc_caption, default = pandoc_caption()),
    content = S7::new_property(pandoc_blocks, default = pandoc_blocks(list()))
  )
)

#' Div
#' @export
pandoc_div = S7::new_class(
  "pandoc_div",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = pandoc_attr()),
    content = S7::new_property(pandoc_blocks, default = pandoc_blocks(list()))
  )
)

#' Table
#' @export
pandoc_table = S7::new_class(
  "pandoc_table",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = pandoc_attr()),
    caption = S7::new_property(pandoc_caption, default = pandoc_caption()),
    colspec = S7::new_property(S7::class_list, default = list()),
    head    = S7::new_property(pandoc_table_head, default = pandoc_table_head()),
    bodies  = S7::new_property(S7::class_list, default = list()),
    foot    = S7::new_property(pandoc_table_foot, default = pandoc_table_foot())
  )
)

#' Block metadata
#' @export
pandoc_block_metadata = S7::new_class(
  "pandoc_block_metadata",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    meta = S7::new_property(pandoc_meta_value, default = pandoc_meta_value())
  )
)

#' Note definition (paragraph form)
#' @export
pandoc_note_definition_para = S7::new_class(
  "pandoc_note_definition_para",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    id      = S7::new_property(S7::class_character, default = ""),
    content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list()))
  )
)

#' Note definition (fenced block form)
#' @export
pandoc_note_definition_fenced_block = S7::new_class(
  "pandoc_note_definition_fenced_block",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    id      = S7::new_property(S7::class_character, default = ""),
    content = S7::new_property(pandoc_blocks, default = pandoc_blocks(list()))
  )
)

#' Caption block (orphan caption)
#' @export
pandoc_caption_block = S7::new_class(
  "pandoc_caption_block",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list()))
  )
)

#' Custom block node (Quarto extensions: callouts, tabsets, ...)
#' @export
pandoc_custom_block = S7::new_class(
  "pandoc_custom_block",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    type_name = S7::new_property(S7::class_character, default = ""),
    slots     = S7::new_property(S7::class_list, default = list()),
    attr      = S7::new_property(pandoc_attr, default = pandoc_attr())
  )
)
