#' @include pd-ast-support.R
NULL

#' Block constructors
#'
#' Constructors for the concrete Pandoc block-level node classes. Each returns
#' an S7 object extending [pandoc_block]. See [pandoc_node] for the abstract
#' hierarchy and [pandoc_inline_constructors] for the inline nodes.
#'
#' @section Notes:
#' `pandoc_block_metadata()` carries a mid-document metadata block (e.g. a
#' `---` fenced `_scope:` block) as a [`pandoc_meta_value`] tree in
#' `@meta`, and round-trips through [`to_qmd()`] via pampa's metadata
#' writer.
#'
#' `pandoc_custom_block()` (and `pandoc_custom_inline()`) `@slots` and
#' `@attr` are never populated from a parse: the Rust exporter emits only
#' the node's `type_name`, so custom-node content is currently invisible
#' to the R side, and [`to_qmd()`] cannot write custom nodes back.
#'
#' @param content The node's children: a [`pandoc_inlines`] or
#'   [`pandoc_blocks`] wrapper, or a list of wrappers for the multi-item
#'   containers (lists, line blocks, definition lists).
#' @param attr A [`pandoc_attr`] (a [`pandoc_list_attributes`] for
#'   `pandoc_ordered_list()`).
#' @param text Verbatim text content (code blocks, raw blocks).
#' @param format Output format name of a raw block (e.g. `"html"`).
#' @param level Heading level, 1-6.
#' @param caption A [`pandoc_caption`].
#' @param colspec A list of [`pandoc_col_spec`] objects, one per column.
#' @param head,foot A [`pandoc_table_head`] / [`pandoc_table_foot`].
#' @param bodies A list of [`pandoc_table_body`] objects.
#' @param meta A [`pandoc_meta_value`] (parse-only, see Notes).
#' @param id Note-definition identifier.
#' @param type_name Custom node type name (parse-only, see Notes).
#' @param slots Custom node payload (never populated, see Notes).
#' @return An S7 object of the named block class.
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
    validate_list_of(self@content, pandoc_inlines,
      "@content must be a list of pandoc_inlines objects")
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
  ),
  validator = function(self) {
    c(
      validate_scalar_string(self@text, "@text")
    )
  }
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
  ),
  validator = function(self) {
    c(
      validate_scalar_string(self@format, "@format"),
      validate_scalar_string(self@text, "@text")
    )
  }
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
    validate_list_of(self@content, pandoc_blocks,
      "@content must be a list of pandoc_blocks (one per list item)")
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
    validate_list_of(self@content, pandoc_blocks,
      "@content must be a list of pandoc_blocks (one per list item)")
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
    validate_list_of(self@content, pandoc_definition_item,
      "@content must be a list of pandoc_definition_item objects")
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
  ),
  validator = function(self) {
    # Markdown headings are 1-6; outside that range the written `#` run
    # silently reparses as a paragraph (and a negative level would make
    # pampa's writer loop ~2^64 times).
    validate_scalar_int(self@level, "@level", min = 1L, max = 6L)
  }
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
  ),
  validator = function(self) {
    msg = validate_list_of(self@colspec, pandoc_col_spec,
                           "@colspec must be a list of pandoc_col_spec objects")
    if (!is.null(msg)) return(msg)
    validate_list_of(self@bodies, pandoc_table_body,
                     "@bodies must be a list of pandoc_table_body objects")
  }
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
  ),
  validator = function(self) {
    c(
      validate_scalar_string(self@id, "@id")
    )
  }
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
  ),
  validator = function(self) {
    c(
      validate_scalar_string(self@id, "@id")
    )
  }
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
  ),
  validator = function(self) {
    c(
      validate_scalar_string(self@type_name, "@type_name")
    )
  }
)
