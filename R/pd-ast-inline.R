#' @include pd-ast-support.R
NULL

#' Inline constructors
#'
#' Constructors for the concrete Pandoc inline node classes. Each returns an
#' S7 object extending [pandoc_inline]. See [pandoc_node] for the abstract
#' hierarchy and [pandoc_block_constructors] for the block-level nodes.
#'
#' @section Notes:
#' `pandoc_str()` holds a maximal run of non-whitespace characters: Pandoc
#' represents spaces as [pandoc_space] and line breaks as [pandoc_soft_break]
#' / [pandoc_line_break]. Embedding ASCII whitespace in `@text` would emit
#' literal whitespace that re-parses into separate inlines, so it is rejected.
#'
#' `pandoc_shortcode()` carries `positional_args` and `keyword_args` as lists
#' of arg records. Each arg record is a list with `kind` ∈ `"string"`,
#' `"number"`, `"boolean"`, `"shortcode"`, `"kv"`, `"kv_group"`.
#' `string`/`number`/`boolean` carry a `value`; `shortcode` carries a nested
#' `pandoc_shortcode` in `value`; `kv` carries `key` (character) and `value`
#' (another arg record); `kv_group` carries `value` as a list of `kv` records
#' (used for positional KeyValue bundles).
#'
#' @name pandoc_inline_constructors
#' @seealso [pandoc_block_constructors], [pandoc_node], [pandoc_support_types]
NULL

#' @rdname pandoc_inline_constructors
#' @export
pandoc_str = S7::new_class(
  "pandoc_str",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(text = S7::new_property(S7::class_character, default = "")),
  validator = function(self) {
    if (length(self@text) == 1L && grepl("[ \t\r\n]", self@text)) {
      paste0(
        "@text must not contain spaces, tabs, or line breaks (use ",
        "pandoc_space / pandoc_soft_break between words); got ",
        encodeString(self@text, quote = "\"")
      )
    }
  }
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_emph = S7::new_class(
  "pandoc_emph",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list()))))
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_underline = S7::new_class(
  "pandoc_underline",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list()))))
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_strong = S7::new_class(
  "pandoc_strong",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list()))))
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_strikeout = S7::new_class(
  "pandoc_strikeout",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list()))))
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_superscript = S7::new_class(
  "pandoc_superscript",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list()))))
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_subscript = S7::new_class(
  "pandoc_subscript",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list()))))
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_small_caps = S7::new_class(
  "pandoc_small_caps",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list()))))
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_quoted = S7::new_class(
  "pandoc_quoted",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    quote_type = S7::new_property(S7::class_character, default = "double"),
    content    = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list())))
  ),
  validator = function(self) {
    if (length(self@quote_type) != 1L || !self@quote_type %in% c("single", "double")) {
      "@quote_type must be a single \"single\" or \"double\""
    }
  }
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_cite = S7::new_class(
  "pandoc_cite",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    citations = S7::new_property(S7::class_list, default = list()),
    content   = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list())))
  ),
  validator = function(self) {
    validate_list_of(self@citations, pandoc_citation,
      "@citations must be a list of pandoc_citation objects")
  }
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_code = S7::new_class(
  "pandoc_code",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    text = S7::new_property(S7::class_character, default = "")
  )
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_space = S7::new_class("pandoc_space", package = "q2r", parent = pandoc_inline)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_soft_break = S7::new_class("pandoc_soft_break", package = "q2r", parent = pandoc_inline)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_line_break = S7::new_class("pandoc_line_break", package = "q2r", parent = pandoc_inline)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_math = S7::new_class(
  "pandoc_math",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    math_type = S7::new_property(S7::class_character, default = "inline"),
    text      = S7::new_property(S7::class_character, default = "")
  ),
  validator = function(self) {
    if (length(self@math_type) != 1L || !self@math_type %in% c("inline", "display")) {
      "@math_type must be a single \"inline\" or \"display\""
    }
  }
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_raw_inline = S7::new_class(
  "pandoc_raw_inline",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    format = S7::new_property(S7::class_character, default = ""),
    text   = S7::new_property(S7::class_character, default = "")
  )
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_link = S7::new_class(
  "pandoc_link",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list()))),
    url     = S7::new_property(S7::class_character, default = ""),
    title   = S7::new_property(S7::class_character, default = "")
  )
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_image = S7::new_class(
  "pandoc_image",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list()))),
    url     = S7::new_property(S7::class_character, default = ""),
    title   = S7::new_property(S7::class_character, default = "")
  )
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_note = S7::new_class(
  "pandoc_note",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_blocks, default = quote(pandoc_blocks(list()))))
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_span = S7::new_class(
  "pandoc_span",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list())))
  )
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_shortcode = S7::new_class(
  "pandoc_shortcode",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    name            = S7::new_property(S7::class_character, default = ""),
    is_escaped      = S7::new_property(S7::class_logical,   default = FALSE),
    positional_args = S7::new_property(S7::class_list,      default = list()),
    keyword_args    = S7::new_property(S7::class_list,      default = list())
  )
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_note_reference = S7::new_class(
  "pandoc_note_reference",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(id = S7::new_property(S7::class_character, default = ""))
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_attr_inline = S7::new_class(
  "pandoc_attr_inline",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(attr = S7::new_property(pandoc_attr, default = quote(pandoc_attr())))
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_insert = S7::new_class(
  "pandoc_insert",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list())))
  )
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_delete = S7::new_class(
  "pandoc_delete",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list())))
  )
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_highlight = S7::new_class(
  "pandoc_highlight",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list())))
  )
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_edit_comment = S7::new_class(
  "pandoc_edit_comment",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    content = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list())))
  )
)

#' @rdname pandoc_inline_constructors
#' @export
pandoc_custom_inline = S7::new_class(
  "pandoc_custom_inline",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    type_name = S7::new_property(S7::class_character, default = ""),
    slots     = S7::new_property(S7::class_list, default = list()),
    attr      = S7::new_property(pandoc_attr, default = quote(pandoc_attr()))
  )
)
