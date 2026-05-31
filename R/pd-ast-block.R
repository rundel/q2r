#' @include pd-ast-support.R
NULL

#' Block constructors
#'
#' Constructors for the concrete Pandoc block-level node classes. Each returns
#' an S7 object extending [pandoc_block]. See [pandoc_node] for the abstract
#' hierarchy and [pandoc_inline_constructors] for the inline nodes.
#'
#' @name pandoc_block_constructors
#' @seealso [pandoc_inline_constructors], [pandoc_node], [pandoc_support_types]
NULL

#' @rdname pandoc_block_constructors
#' @export
pandoc_plain = S7::new_class(
  "pandoc_plain",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list())))
  )
)

#' @rdname pandoc_block_constructors
#' @export
pandoc_paragraph = S7::new_class(
  "pandoc_paragraph",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list())))
  )
)

#' @rdname pandoc_block_constructors
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

#' @rdname pandoc_block_constructors
#' @export
pandoc_code_block = S7::new_class(
  "pandoc_code_block",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    attr = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    text = S7::new_property(S7::class_character, default = "")
  )
)

#' @rdname pandoc_block_constructors
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

#' @rdname pandoc_block_constructors
#' @export
pandoc_block_quote = S7::new_class(
  "pandoc_block_quote",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    content = S7::new_property(pandoc_blocks, default = quote(pandoc_blocks(list())))
  )
)

#' @rdname pandoc_block_constructors
#' @export
pandoc_ordered_list = S7::new_class(
  "pandoc_ordered_list",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    attr    = S7::new_property(pandoc_list_attributes, default = quote(pandoc_list_attributes())),
    content = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    ok = vapply(self@content, function(x) S7::S7_inherits(x, pandoc_blocks), logical(1))
    if (!all(ok)) "@content must be a list of pandoc_blocks (one per list item)"
  }
)

#' @rdname pandoc_block_constructors
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

#' @rdname pandoc_block_constructors
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

#' @rdname pandoc_block_constructors
#' @export
pandoc_header = S7::new_class(
  "pandoc_header",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    level   = S7::new_property(S7::class_integer, default = 1L),
    attr    = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list())))
  )
)

#' @rdname pandoc_block_constructors
#' @export
pandoc_horizontal_rule = S7::new_class(
  "pandoc_horizontal_rule",
  package = "q2r",
  parent = pandoc_block
)

#' @rdname pandoc_block_constructors
#' @export
pandoc_figure = S7::new_class(
  "pandoc_figure",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    caption = S7::new_property(pandoc_caption, default = quote(pandoc_caption())),
    content = S7::new_property(pandoc_blocks, default = quote(pandoc_blocks(list())))
  )
)

#' @rdname pandoc_block_constructors
#' @export
pandoc_div = S7::new_class(
  "pandoc_div",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    content = S7::new_property(pandoc_blocks, default = quote(pandoc_blocks(list())))
  )
)

#' @rdname pandoc_block_constructors
#' @export
pandoc_table = S7::new_class(
  "pandoc_table",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    caption = S7::new_property(pandoc_caption, default = quote(pandoc_caption())),
    colspec = S7::new_property(S7::class_list, default = list()),
    head    = S7::new_property(pandoc_table_head, default = quote(pandoc_table_head())),
    bodies  = S7::new_property(S7::class_list, default = list()),
    foot    = S7::new_property(pandoc_table_foot, default = quote(pandoc_table_foot()))
  )
)

#' @rdname pandoc_block_constructors
#' @export
pandoc_block_metadata = S7::new_class(
  "pandoc_block_metadata",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    meta = S7::new_property(pandoc_meta_value, default = quote(pandoc_meta_value()))
  )
)

#' @rdname pandoc_block_constructors
#' @export
pandoc_note_definition_para = S7::new_class(
  "pandoc_note_definition_para",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    id      = S7::new_property(S7::class_character, default = ""),
    content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list())))
  )
)

#' @rdname pandoc_block_constructors
#' @export
pandoc_note_definition_fenced_block = S7::new_class(
  "pandoc_note_definition_fenced_block",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    id      = S7::new_property(S7::class_character, default = ""),
    content = S7::new_property(pandoc_blocks, default = quote(pandoc_blocks(list())))
  )
)

#' @rdname pandoc_block_constructors
#' @export
pandoc_caption_block = S7::new_class(
  "pandoc_caption_block",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list())))
  )
)

#' @rdname pandoc_block_constructors
#' @export
pandoc_custom_block = S7::new_class(
  "pandoc_custom_block",
  package = "q2r",
  parent = pandoc_block,
  properties = list(
    type_name = S7::new_property(S7::class_character, default = ""),
    slots     = S7::new_property(S7::class_list, default = list()),
    attr      = S7::new_property(pandoc_attr, default = quote(pandoc_attr()))
  )
)
