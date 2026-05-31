#' Source location
#'
#' @export
pandoc_source_info = S7::new_class(
  "pandoc_source_info",
  package = "q2r",
  properties = list(
    file_id      = S7::new_property(S7::class_integer, default = NA_integer_),
    start_offset = S7::new_property(S7::class_integer, default = NA_integer_),
    start_row    = S7::new_property(S7::class_integer, default = NA_integer_),
    start_col    = S7::new_property(S7::class_integer, default = NA_integer_),
    end_offset   = S7::new_property(S7::class_integer, default = NA_integer_),
    end_row      = S7::new_property(S7::class_integer, default = NA_integer_),
    end_col      = S7::new_property(S7::class_integer, default = NA_integer_)
  )
)

#' Virtual parent classes
#'
#' `pandoc_node` is the abstract root of the AST; every block and inline
#' extends it. `pandoc_block` and `pandoc_inline` are abstract too; concrete
#' variants extend one of these.
#'
#' @export
pandoc_node = S7::new_class(
  "pandoc_node",
  package = "q2r",
  abstract = TRUE,
  properties = list(
    source_info = S7::new_property(pandoc_source_info, default = quote(pandoc_source_info()))
  )
)

#' @rdname pandoc_node
#' @export
pandoc_block = S7::new_class(
  "pandoc_block",
  package = "q2r",
  parent = pandoc_node,
  abstract = TRUE
)

#' @rdname pandoc_node
#' @export
pandoc_inline = S7::new_class(
  "pandoc_inline",
  package = "q2r",
  parent = pandoc_node,
  abstract = TRUE
)

#' Pandoc attributes
#'
#' @export
pandoc_attr = S7::new_class(
  "pandoc_attr",
  package = "q2r",
  properties = list(
    id         = S7::new_property(S7::class_character, default = ""),
    classes    = S7::new_property(S7::class_character, default = character()),
    attributes = S7::new_property(S7::class_character, default = character())
  )
)

pandoc_attr_is_empty = function(attr) {
  nchar(attr@id) == 0L && length(attr@classes) == 0L && length(attr@attributes) == 0L
}

#' Typed list wrappers
#'
#' `pandoc_blocks()` and `pandoc_inlines()` validate that every element of
#' the supplied list is of the appropriate kind.
#'
#' @export
pandoc_blocks = S7::new_class(
  "pandoc_blocks",
  package = "q2r",
  properties = list(content = S7::class_list),
  validator = function(self) {
    ok = vapply(self@content, function(x) S7::S7_inherits(x, pandoc_block), logical(1))
    if (!all(ok)) "all elements of @content must be pandoc_block objects"
  }
)

#' @rdname pandoc_blocks
#' @export
pandoc_inlines = S7::new_class(
  "pandoc_inlines",
  package = "q2r",
  properties = list(content = S7::class_list),
  validator = function(self) {
    ok = vapply(self@content, function(x) S7::S7_inherits(x, pandoc_inline), logical(1))
    if (!all(ok)) "all elements of @content must be pandoc_inline objects"
  }
)

#' Pandoc meta / config value
#'
#' @export
pandoc_meta_value = S7::new_class(
  "pandoc_meta_value",
  package = "q2r",
  properties = list(
    kind  = S7::new_property(S7::class_character, default = "map"),
    value = S7::new_property(S7::class_any, default = list())
  ),
  validator = function(self) {
    allowed = c("string", "bool", "inlines", "blocks", "list", "map")
    if (length(self@kind) != 1L || !self@kind %in% allowed) {
      sprintf("@kind must be one of %s", paste(allowed, collapse = "/"))
    }
  }
)

#' @rdname pandoc_meta_value
#' @export
pandoc_config_value = pandoc_meta_value

#' Ordered list attributes
#'
#' @export
pandoc_list_attributes = S7::new_class(
  "pandoc_list_attributes",
  package = "q2r",
  properties = list(
    start = S7::new_property(S7::class_integer, default = 1L),
    style = S7::new_property(S7::class_character, default = "Decimal"),
    delim = S7::new_property(S7::class_character, default = "Period")
  )
)

#' Citation
#'
#' @export
pandoc_citation = S7::new_class(
  "pandoc_citation",
  package = "q2r",
  properties = list(
    id       = S7::new_property(S7::class_character, default = ""),
    mode     = S7::new_property(S7::class_character, default = "NormalCitation"),
    prefix   = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list()))),
    suffix   = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list()))),
    note_num = S7::new_property(S7::class_integer, default = 0L),
    hash     = S7::new_property(S7::class_integer, default = 0L)
  )
)

#' Caption (short + long)
#'
#' `short` is either `NULL` or a `pandoc_inlines`; `long` is a `pandoc_blocks`.
#'
#' @export
pandoc_caption = S7::new_class(
  "pandoc_caption",
  package = "q2r",
  properties = list(
    short = S7::new_property(S7::class_any, default = NULL),
    long  = S7::new_property(pandoc_blocks, default = quote(pandoc_blocks(list())))
  ),
  validator = function(self) {
    if (!is.null(self@short) && !S7::S7_inherits(self@short, pandoc_inlines)) {
      "@short must be NULL or a pandoc_inlines"
    }
  }
)

#' Definition-list item
#'
#' @export
pandoc_definition_item = S7::new_class(
  "pandoc_definition_item",
  package = "q2r",
  properties = list(
    term = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list()))),
    defs = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    ok = vapply(self@defs, function(x) S7::S7_inherits(x, pandoc_blocks), logical(1))
    if (!all(ok)) "@defs must be a list of pandoc_blocks objects"
  }
)

#' Table column alignment and width
#'
#' @export
pandoc_col_spec = S7::new_class(
  "pandoc_col_spec",
  package = "q2r",
  properties = list(
    alignment = S7::new_property(S7::class_character, default = "Default"),
    width     = S7::new_property(S7::class_any, default = NULL)
  )
)

#' Table cell
#'
#' @export
pandoc_cell = S7::new_class(
  "pandoc_cell",
  package = "q2r",
  properties = list(
    attr      = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    alignment = S7::new_property(S7::class_character, default = "Default"),
    row_span  = S7::new_property(S7::class_integer, default = 1L),
    col_span  = S7::new_property(S7::class_integer, default = 1L),
    content   = S7::new_property(pandoc_blocks, default = quote(pandoc_blocks(list())))
  )
)

#' Table row
#'
#' @export
pandoc_row = S7::new_class(
  "pandoc_row",
  package = "q2r",
  properties = list(
    attr  = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    cells = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    ok = vapply(self@cells, function(x) S7::S7_inherits(x, pandoc_cell), logical(1))
    if (!all(ok)) "@cells must be a list of pandoc_cell objects"
  }
)

#' Table head / body / foot
#'
#' @export
pandoc_table_head = S7::new_class(
  "pandoc_table_head",
  package = "q2r",
  properties = list(
    attr = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    rows = S7::new_property(S7::class_list, default = list())
  )
)

#' @rdname pandoc_table_head
#' @export
pandoc_table_body = S7::new_class(
  "pandoc_table_body",
  package = "q2r",
  properties = list(
    attr             = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    row_head_columns = S7::new_property(S7::class_integer, default = 0L),
    head_rows        = S7::new_property(S7::class_list, default = list()),
    body_rows        = S7::new_property(S7::class_list, default = list())
  )
)

#' @rdname pandoc_table_head
#' @export
pandoc_table_foot = S7::new_class(
  "pandoc_table_foot",
  package = "q2r",
  properties = list(
    attr = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    rows = S7::new_property(S7::class_list, default = list())
  )
)
