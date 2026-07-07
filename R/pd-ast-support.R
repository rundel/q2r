#' Pandoc AST support types
#'
#' Helper value types that appear inside concrete block and inline nodes:
#' attributes, ordered-list attributes, citations, captions,
#' definition-list items, and table cells/rows/columns. Each returns a
#' plain S7 object (these are not [pandoc_node] subclasses).
#'
#' @section Notes:
#' For [pandoc_caption], `short` is either `NULL` or a [pandoc_inlines] and
#' `long` is a [pandoc_blocks].
#'
#' @param id Identifier string (`pandoc_attr`, `pandoc_citation`).
#' @param classes Character vector of classes (`pandoc_attr`).
#' @param attributes Named character vector of key = value attributes
#'   (`pandoc_attr`).
#' @param start,style,delim Ordered-list numbering: start index (>= 0),
#'   style (`"Default"`, `"Example"`, `"Decimal"`, `"LowerRoman"`,
#'   `"UpperRoman"`, `"LowerAlpha"`, `"UpperAlpha"`), and delimiter
#'   (`"Default"`, `"Period"`, `"OneParen"`, `"TwoParens"`).
#' @param mode Citation mode: `"NormalCitation"`, `"AuthorInText"`, or
#'   `"SuppressAuthor"`.
#' @param prefix,suffix Citation affixes as [`pandoc_inlines`].
#' @param note_num,hash Citation bookkeeping integers (>= 0).
#' @param short `NULL` or a [`pandoc_inlines`] (`pandoc_caption`).
#' @param long A [`pandoc_blocks`] (`pandoc_caption`).
#' @param term A [`pandoc_inlines`] (`pandoc_definition_item`).
#' @param defs A list of [`pandoc_blocks`] (`pandoc_definition_item`).
#' @param alignment Column/cell alignment: `"Default"`, `"Left"`,
#'   `"Center"`, or `"Right"`.
#' @param width `NULL` or a relative column width (`pandoc_col_spec`).
#' @param attr A [`pandoc_attr`] (`pandoc_cell`, `pandoc_row`).
#' @param row_span,col_span Cell spans (>= 1).
#' @param content Cell content as a [`pandoc_blocks`] (`pandoc_cell`).
#' @param cells A list of [`pandoc_cell`] objects (`pandoc_row`).
#' @return An S7 object of the named support type.
#' @name pandoc_support_types
#' @seealso [pandoc_node], [pandoc_block_constructors], [pandoc_inline_constructors]
NULL

# Shared validator body: returns `msg` unless every element of `x` inherits
# `cls` (an empty list passes). Collated first so every block/inline/support
# class can use it.
validate_list_of = function(x, cls, msg) {
  if (!all(purrr::map_lgl(x, S7::S7_inherits, cls))) msg
}

# Shared slot validators. Each returns NULL when valid, a message otherwise,
# so class validators can combine them with c(). Malformed values that these
# reject would otherwise cross the FFI silently (a negative integer
# sign-extends to ~1.8e19 via `as usize`, an unknown enum string silently
# falls back to the Rust default) or break far away at print/write time.
validate_scalar_string = function(x, what) {
  if (length(x) != 1L || is.na(x)) {
    paste0(what, " must be a single non-NA string")
  }
}

validate_scalar_int = function(x, what, min = NULL, max = NULL) {
  if (length(x) != 1L || is.na(x)) {
    return(paste0(what, " must be a single non-NA integer"))
  }
  if (!is.null(min) && x < min) {
    return(paste0(what, " must be >= ", min, "; got ", x))
  }
  if (!is.null(max) && x > max) {
    paste0(what, " must be <= ", max, "; got ", x)
  }
}

validate_enum = function(x, what, allowed) {
  if (length(x) != 1L || is.na(x) || !x %in% allowed) {
    cli::format_inline("{what} must be one of {.or {allowed}}")
  }
}

#' Virtual parent classes
#'
#' `pandoc_node` is the abstract root of the AST; every block and inline
#' extends it. `pandoc_block` and `pandoc_inline` are abstract too; concrete
#' variants extend one of these.
#'
#' @return These classes are abstract and cannot be instantiated; they
#'   exist for `is()` predicates and S7 method dispatch.
#' @export
pandoc_node = S7::new_class(
  "pandoc_node",
  package = "q2r",
  abstract = TRUE
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

#' @rdname pandoc_support_types
#' @export
pandoc_attr = S7::new_class(
  "pandoc_attr",
  package = "q2r",
  properties = list(
    id         = S7::new_property(S7::class_character, default = ""),
    classes    = S7::new_property(S7::class_character, default = character()),
    attributes = S7::new_property(S7::class_character, default = character())
  ),
  validator = function(self) {
    c(
      validate_scalar_string(self@id, "@id"),
      if (anyNA(self@classes)) "@classes must not contain NA" else NULL,
      if (anyNA(self@attributes)) "@attributes must not contain NA values" else NULL,
      if (length(self@attributes) > 0L) {
        nms = names(self@attributes)
        # The Rust Attr is a key -> value map: unnamed entries are silently
        # dropped at write time and only one value per key survives, so both
        # are rejected here rather than lost later.
        if (is.null(nms) || anyNA(nms) || !all(nzchar(nms))) {
          "@attributes must be a named character vector (key = value pairs)"
        } else if (anyDuplicated(nms) > 0L) {
          "@attributes names must be unique"
        }
      }
    )
  }
)

pandoc_attr_is_empty = function(attr) {
  nchar(attr@id) == 0L && length(attr@classes) == 0L && length(attr@attributes) == 0L
}

#' Typed list wrappers
#'
#' `pandoc_blocks()` and `pandoc_inlines()` validate that every element of
#' the supplied list is of the appropriate kind. The wrappers behave like
#' lists for the common verbs: `length()`, `[[`, `[` (re-wrapped), and
#' `as.list()` all delegate to `@content`.
#'
#' @param content A list of [`pandoc_block`] (for `pandoc_blocks()`) or
#'   [`pandoc_inline`] (for `pandoc_inlines()`) objects.
#' @return A `pandoc_blocks` / `pandoc_inlines` wrapper object.
#' @export
pandoc_blocks = S7::new_class(
  "pandoc_blocks",
  package = "q2r",
  properties = list(content = S7::class_list),
  validator = function(self) {
    validate_list_of(self@content, pandoc_block,
      "all elements of @content must be pandoc_block objects")
  }
)

#' @rdname pandoc_blocks
#' @export
pandoc_inlines = S7::new_class(
  "pandoc_inlines",
  package = "q2r",
  properties = list(content = S7::class_list),
  validator = function(self) {
    validate_list_of(self@content, pandoc_inline,
      "all elements of @content must be pandoc_inline objects")
  }
)

# Base-generic ergonomics for the typed wrappers: length / [[ / [ / as.list
# delegate to @content, so `doc@blocks[[1]]`, `doc@blocks[2:3]`, and
# `lapply(as.list(doc@blocks), ...)` work without reaching into @content.
S7::method(length, pandoc_blocks)  = function(x) length(x@content)
S7::method(length, pandoc_inlines) = function(x) length(x@content)
S7::method(`[[`, pandoc_blocks)  = function(x, i, ...) x@content[[i]]
S7::method(`[[`, pandoc_inlines) = function(x, i, ...) x@content[[i]]
S7::method(`[`, pandoc_blocks)  = function(x, i, ...) pandoc_blocks(x@content[i])
S7::method(`[`, pandoc_inlines) = function(x, i, ...) pandoc_inlines(x@content[i])
S7::method(as.list, pandoc_blocks)  = function(x, ...) x@content
S7::method(as.list, pandoc_inlines) = function(x, ...) x@content

#' Pandoc meta / config value
#'
#' @param kind The value kind, one of `"string"`, `"int"`, `"real"`,
#'   `"bool"`, `"null"`, `"inlines"`, `"blocks"`, `"list"`, `"map"`,
#'   `"path"`, `"glob"`, or `"expr"`.
#' @param value The payload, whose R type depends on `kind` (a scalar for
#'   the scalar kinds, a named list for `"map"`, an unnamed list for
#'   `"list"`, a [pandoc_inlines] / [pandoc_blocks] for those kinds).
#' @return A `pandoc_meta_value` S7 object.
#' @export
pandoc_meta_value = S7::new_class(
  "pandoc_meta_value",
  package = "q2r",
  properties = list(
    kind  = S7::new_property(S7::class_character, default = "map"),
    value = S7::new_property(S7::class_any, default = list())
  ),
  validator = function(self) {
    allowed = c(
      "string", "int", "real", "bool", "null", "inlines", "blocks",
      "list", "map", "path", "glob", "expr"
    )
    if (length(self@kind) != 1L || !self@kind %in% allowed) {
      return(cli::format_inline("@kind must be one of {.or {allowed}}"))
    }
    # Validate @value against @kind at construction: a mismatch otherwise
    # surfaces only at write time as an opaque S7 dispatch error from deep
    # inside meta_to_list().
    v = self@value
    scalar = function(ok) ok && length(v) == 1L && !is.na(v)
    bad = switch(self@kind,
      string = ,
      path   = ,
      glob   = ,
      expr   = !scalar(is.character(v)),
      int    = ,
      real   = !scalar(is.numeric(v)),
      bool   = !scalar(is.logical(v)),
      null   = !is.null(v),
      inlines = !S7::S7_inherits(v, pandoc_inlines),
      blocks  = !S7::S7_inherits(v, pandoc_blocks),
      list = !is.list(v) || S7::S7_inherits(v) ||
        !all(purrr::map_lgl(v, S7::S7_inherits, pandoc_meta_value)),
      map = !is.list(v) || S7::S7_inherits(v) ||
        !all(purrr::map_lgl(v, S7::S7_inherits, pandoc_meta_value)) ||
        (length(v) > 0L && (is.null(names(v)) || !all(nzchar(names(v)))))
    )
    if (isTRUE(bad)) {
      cli::format_inline(
        "@value has the wrong shape for kind {.val {self@kind}} (see ?pandoc_meta_value)"
      )
    }
  }
)

#' @rdname pandoc_meta_value
#' @export
pandoc_config_value = pandoc_meta_value

#' @rdname pandoc_support_types
#' @export
pandoc_list_attributes = S7::new_class(
  "pandoc_list_attributes",
  package = "q2r",
  properties = list(
    start = S7::new_property(S7::class_integer, default = 1L),
    style = S7::new_property(S7::class_character, default = "Decimal"),
    delim = S7::new_property(S7::class_character, default = "Period")
  ),
  validator = function(self) {
    c(
      validate_scalar_int(self@start, "@start", min = 0L),
      validate_enum(self@style, "@style",
        c("Default", "Example", "Decimal", "LowerRoman", "UpperRoman",
          "LowerAlpha", "UpperAlpha")),
      validate_enum(self@delim, "@delim",
        c("Default", "Period", "OneParen", "TwoParens"))
    )
  }
)

#' @rdname pandoc_support_types
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
  ),
  validator = function(self) {
    c(
      validate_scalar_string(self@id, "@id"),
      validate_enum(self@mode, "@mode",
        c("NormalCitation", "AuthorInText", "SuppressAuthor")),
      validate_scalar_int(self@note_num, "@note_num", min = 0L),
      validate_scalar_int(self@hash, "@hash", min = 0L)
    )
  }
)

#' @rdname pandoc_support_types
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

#' @rdname pandoc_support_types
#' @export
pandoc_definition_item = S7::new_class(
  "pandoc_definition_item",
  package = "q2r",
  properties = list(
    term = S7::new_property(pandoc_inlines, default = quote(pandoc_inlines(list()))),
    defs = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    validate_list_of(self@defs, pandoc_blocks,
      "@defs must be a list of pandoc_blocks objects")
  }
)

#' @rdname pandoc_support_types
#' @export
pandoc_col_spec = S7::new_class(
  "pandoc_col_spec",
  package = "q2r",
  properties = list(
    alignment = S7::new_property(S7::class_character, default = "Default"),
    width     = S7::new_property(S7::class_any, default = NULL)
  ),
  validator = function(self) {
    c(
      validate_enum(self@alignment, "@alignment",
        c("Default", "Left", "Center", "Right")),
      if (!is.null(self@width) &&
          (!is.numeric(self@width) || length(self@width) != 1L || is.na(self@width))) {
        "@width must be NULL or a single non-NA number"
      }
    )
  }
)

#' @rdname pandoc_support_types
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
  ),
  validator = function(self) {
    c(
      validate_enum(self@alignment, "@alignment",
        c("Default", "Left", "Center", "Right")),
      validate_scalar_int(self@row_span, "@row_span", min = 1L),
      validate_scalar_int(self@col_span, "@col_span", min = 1L)
    )
  }
)

#' @rdname pandoc_support_types
#' @export
pandoc_row = S7::new_class(
  "pandoc_row",
  package = "q2r",
  properties = list(
    attr  = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    cells = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    validate_list_of(self@cells, pandoc_cell,
      "@cells must be a list of pandoc_cell objects")
  }
)

#' Table head / body / foot
#'
#' @param attr A [`pandoc_attr`].
#' @param rows For the head and foot, a list of [`pandoc_row`] objects.
#' @param row_head_columns For a body, the number of leading row-header
#'   columns.
#' @param head_rows,body_rows For a body, lists of [`pandoc_row`] objects.
#' @return A `pandoc_table_head` / `pandoc_table_body` /
#'   `pandoc_table_foot` S7 object.
#' @export
pandoc_table_head = S7::new_class(
  "pandoc_table_head",
  package = "q2r",
  properties = list(
    attr = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    rows = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    validate_list_of(self@rows, pandoc_row, "@rows must be a list of pandoc_row objects")
  }
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
  ),
  validator = function(self) {
    msg = validate_list_of(self@head_rows, pandoc_row,
                           "@head_rows must be a list of pandoc_row objects")
    if (!is.null(msg)) return(msg)
    validate_list_of(self@body_rows, pandoc_row,
                     "@body_rows must be a list of pandoc_row objects")
  }
)

#' @rdname pandoc_table_head
#' @export
pandoc_table_foot = S7::new_class(
  "pandoc_table_foot",
  package = "q2r",
  properties = list(
    attr = S7::new_property(pandoc_attr, default = quote(pandoc_attr())),
    rows = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    validate_list_of(self@rows, pandoc_row, "@rows must be a list of pandoc_row objects")
  }
)
