#' @include pd-ast-support.R
NULL

#' Literal string
#' @export
pandoc_str = S7::new_class(
  "pandoc_str",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(text = S7::new_property(S7::class_character, default = ""))
)

#' Emphasized text
#' @export
pandoc_emph = S7::new_class(
  "pandoc_emph",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list())))
)

#' Underlined text
#' @export
pandoc_underline = S7::new_class(
  "pandoc_underline",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list())))
)

#' Strong text
#' @export
pandoc_strong = S7::new_class(
  "pandoc_strong",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list())))
)

#' Struck-through text
#' @export
pandoc_strikeout = S7::new_class(
  "pandoc_strikeout",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list())))
)

#' Superscript
#' @export
pandoc_superscript = S7::new_class(
  "pandoc_superscript",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list())))
)

#' Subscript
#' @export
pandoc_subscript = S7::new_class(
  "pandoc_subscript",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list())))
)

#' Small caps
#' @export
pandoc_small_caps = S7::new_class(
  "pandoc_small_caps",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list())))
)

#' Quoted text
#' @export
pandoc_quoted = S7::new_class(
  "pandoc_quoted",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    quote_type = S7::new_property(S7::class_character, default = "double"),
    content    = S7::new_property(pandoc_inlines, default = pandoc_inlines(list()))
  ),
  validator = function(self) {
    if (!self@quote_type %in% c("single", "double")) {
      "@quote_type must be \"single\" or \"double\""
    }
  }
)

#' Citation reference
#' @export
pandoc_cite = S7::new_class(
  "pandoc_cite",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    citations = S7::new_property(S7::class_list, default = list()),
    content   = S7::new_property(pandoc_inlines, default = pandoc_inlines(list()))
  ),
  validator = function(self) {
    ok = vapply(self@citations, function(x) S7::S7_inherits(x, pandoc_citation), logical(1))
    if (!all(ok)) "@citations must be a list of pandoc_citation objects"
  }
)

#' Inline code
#' @export
pandoc_code = S7::new_class(
  "pandoc_code",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr = S7::new_property(pandoc_attr, default = pandoc_attr()),
    text = S7::new_property(S7::class_character, default = "")
  )
)

#' Space
#' @export
pandoc_space = S7::new_class("pandoc_space", package = "q2r", parent = pandoc_inline)

#' Soft line break
#' @export
pandoc_soft_break = S7::new_class("pandoc_soft_break", package = "q2r", parent = pandoc_inline)

#' Hard line break
#' @export
pandoc_line_break = S7::new_class("pandoc_line_break", package = "q2r", parent = pandoc_inline)

#' Math
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
    if (!self@math_type %in% c("inline", "display")) {
      "@math_type must be \"inline\" or \"display\""
    }
  }
)

#' Raw inline
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

#' Link
#' @export
pandoc_link = S7::new_class(
  "pandoc_link",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = pandoc_attr()),
    content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list())),
    url     = S7::new_property(S7::class_character, default = ""),
    title   = S7::new_property(S7::class_character, default = "")
  )
)

#' Image
#' @export
pandoc_image = S7::new_class(
  "pandoc_image",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = pandoc_attr()),
    content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list())),
    url     = S7::new_property(S7::class_character, default = ""),
    title   = S7::new_property(S7::class_character, default = "")
  )
)

#' Footnote
#' @export
pandoc_note = S7::new_class(
  "pandoc_note",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(content = S7::new_property(pandoc_blocks, default = pandoc_blocks(list())))
)

#' Inline span
#' @export
pandoc_span = S7::new_class(
  "pandoc_span",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = pandoc_attr()),
    content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list()))
  )
)

#' Shortcode
#' @export
pandoc_shortcode = S7::new_class(
  "pandoc_shortcode",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    name = S7::new_property(S7::class_character, default = ""),
    args = S7::new_property(S7::class_list, default = list())
  )
)

#' Note reference
#' @export
pandoc_note_reference = S7::new_class(
  "pandoc_note_reference",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(id = S7::new_property(S7::class_character, default = ""))
)

#' Standalone attribute inline
#' @export
pandoc_attr_inline = S7::new_class(
  "pandoc_attr_inline",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(attr = S7::new_property(pandoc_attr, default = pandoc_attr()))
)

#' CriticMarkup: insertion
#' @export
pandoc_insert = S7::new_class(
  "pandoc_insert",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = pandoc_attr()),
    content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list()))
  )
)

#' CriticMarkup: deletion
#' @export
pandoc_delete = S7::new_class(
  "pandoc_delete",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = pandoc_attr()),
    content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list()))
  )
)

#' CriticMarkup: highlight
#' @export
pandoc_highlight = S7::new_class(
  "pandoc_highlight",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = pandoc_attr()),
    content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list()))
  )
)

#' CriticMarkup: comment
#' @export
pandoc_edit_comment = S7::new_class(
  "pandoc_edit_comment",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    attr    = S7::new_property(pandoc_attr, default = pandoc_attr()),
    content = S7::new_property(pandoc_inlines, default = pandoc_inlines(list()))
  )
)

#' Custom inline node (Quarto extensions)
#' @export
pandoc_custom_inline = S7::new_class(
  "pandoc_custom_inline",
  package = "q2r",
  parent = pandoc_inline,
  properties = list(
    type_name = S7::new_property(S7::class_character, default = ""),
    slots     = S7::new_property(S7::class_list, default = list()),
    attr      = S7::new_property(pandoc_attr, default = pandoc_attr())
  )
)
