#' @include diagnostic.R
NULL

#' Tree-sitter AST classes
#'
#' S7 classes representing the tree-sitter (`tree-sitter-qmd`) AST
#' produced by pampa for a QMD document. Unlike the Pandoc AST,
#' tree-sitter node kinds are open-ended grammar-defined strings, so a
#' single `ts_node` class with a `kind` string property is used.
#'
#' @export
ts_point = S7::new_class(
  "ts_point",
  package = "q2r",
  properties = list(
    row    = S7::new_property(S7::class_integer, default = NA_integer_),
    column = S7::new_property(S7::class_integer, default = NA_integer_)
  )
)

#' @rdname ts_point
#' @export
ts_range = S7::new_class(
  "ts_range",
  package = "q2r",
  properties = list(
    start_byte  = S7::new_property(S7::class_integer, default = NA_integer_),
    end_byte    = S7::new_property(S7::class_integer, default = NA_integer_),
    start_point = S7::new_property(ts_point, default = quote(ts_point())),
    end_point   = S7::new_property(ts_point, default = quote(ts_point()))
  )
)

#' @rdname ts_point
#' @export
ts_nodes = S7::new_class(
  "ts_nodes",
  package = "q2r",
  properties = list(content = S7::class_list),
  validator = function(self) {
    ok = vapply(self@content, function(x) S7::S7_inherits(x, ts_node), logical(1))
    if (!all(ok)) "all elements of @content must be ts_node objects"
  }
)

#' @rdname ts_point
#' @export
ts_node = S7::new_class(
  "ts_node",
  package = "q2r",
  properties = list(
    kind       = S7::new_property(S7::class_character, default = ""),
    is_named   = S7::new_property(S7::class_logical, default = TRUE),
    field_name = S7::new_property(S7::class_any, default = NULL),
    range      = S7::new_property(ts_range, default = quote(ts_range())),
    text       = S7::new_property(S7::class_any, default = NULL),
    children   = S7::new_property(ts_nodes, default = quote(ts_nodes(list())))
  ),
  validator = function(self) {
    if (!is.null(self@field_name) &&
        !(is.character(self@field_name) && length(self@field_name) == 1L)) {
      "@field_name must be NULL or a single string"
    } else if (!is.null(self@text) &&
               !(is.character(self@text) && length(self@text) == 1L)) {
      "@text must be NULL or a single string"
    }
  }
)

#' @rdname ts_point
#' @export
ts_tree = S7::new_class(
  "ts_tree",
  package = "q2r",
  properties = list(
    root        = S7::new_property(ts_node, default = quote(ts_node())),
    language    = S7::new_property(S7::class_character, default = "qmd"),
    diagnostics = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    if (length(self@diagnostics) &&
        !all(vapply(self@diagnostics, S7::S7_inherits, logical(1), pampa_diagnostic))) {
      "@diagnostics must be a list of pampa_diagnostic objects"
    }
  }
)

ts_node_to_list = function(node) {
  list(
    kind       = node@kind,
    is_named   = node@is_named,
    field_name = node@field_name,
    text       = node@text,
    children   = lapply(node@children@content, ts_node_to_list)
  )
}

ts_tree_to_list = function(tree) {
  list(
    language = tree@language,
    root     = ts_node_to_list(tree@root)
  )
}

ts_format_position = function(range) {
  sprintf(
    "(%d, %d) - (%d, %d)",
    range@start_point@row, range@start_point@column,
    range@end_point@row,   range@end_point@column
  )
}

ts_format_label = function(x, position = FALSE, text = TRUE) {
  kind = if (x@is_named) {
    pandoc_style_kind(x@kind)
  } else {
    pandoc_style_val(paste0("\"", x@kind, "\""))
  }
  field = if (!is.null(x@field_name)) {
    paste0(pandoc_style_field(paste0(x@field_name, ":")), " ")
  } else ""
  pos = if (position) {
    paste0(" ", pandoc_style_pos(ts_format_position(x@range)))
  } else ""
  is_leaf = length(x@children@content) == 0L
  text_snip = if (text && is_leaf && !is.null(x@text) && nzchar(x@text)) {
    paste0(" ", pandoc_quote(x@text))
  } else ""
  sprintf("%s%s%s%s", field, kind, pos, text_snip)
}

ts_emit_node = function(buf, x, prefix_self, prefix_kids, position, text) {
  pandoc_tree_buf_push(
    buf,
    paste0(prefix_self, ts_format_label(x, position = position, text = text))
  )
  kids = x@children@content
  nk = length(kids)
  if (nk == 0L) return()
  chars = buf$chars
  for (i in seq_len(nk)) {
    last = i == nk
    branch = if (last) chars$ell else chars$tee
    cont   = if (last) chars$blk else chars$vbar
    ts_emit_node(
      buf, kids[[i]],
      prefix_self = paste0(prefix_kids, branch),
      prefix_kids = paste0(prefix_kids, cont),
      position = position, text = text
    )
  }
}

ts_tree_lines = function(x, position = FALSE, text = TRUE) {
  withr::local_options(cli.num_colors = cli::num_ansi_colors())
  buf = pandoc_tree_buf()

  if (S7::S7_inherits(x, ts_tree)) {
    root_label = paste0(
      pandoc_style_kind("ts_tree"), " ",
      pandoc_field("language"), x@language
    )
    pandoc_tree_buf_push(buf, root_label)
    chars = buf$chars
    ts_emit_node(
      buf, x@root,
      prefix_self = chars$ell,
      prefix_kids = chars$blk,
      position = position, text = text
    )
  } else {
    ts_emit_node(
      buf, x,
      prefix_self = "", prefix_kids = "",
      position = position, text = text
    )
  }

  pandoc_tree_buf_lines(buf)
}

#' Print a tree-sitter AST
#'
#' Renders a [`ts_tree`] or [`ts_node`] as an indented tree.
#'
#' @param x A [`ts_tree`] or [`ts_node`].
#' @param position If `TRUE`, include each node's `(row, column)` byte
#'   range in the label. Defaults to `FALSE`.
#' @param text If `TRUE` (the default), include the source-text snippet
#'   for leaf nodes that carry one.
#' @param color For `ts_tree`, whether to use ANSI colour when printing
#'   attached diagnostics. Defaults to whether the terminal supports it.
#' @param ... Unused; present for S3/S7 compatibility.
#' @return `x`, invisibly.
#' @name print.ts_tree
#' @aliases print.ts_node
NULL

S7::method(print, ts_node) = function(x, position = FALSE, text = TRUE, ...) {
  cat(ts_tree_lines(x, position = position, text = text), sep = "\n")
  invisible(x)
}

S7::method(print, ts_tree) = function(x,
                                       position = FALSE,
                                       text = TRUE,
                                       color = cli::num_ansi_colors() > 1L,
                                       ...) {
  cat(ts_tree_lines(x, position = position, text = text), sep = "\n")
  if (length(x@diagnostics)) {
    cat("\n-- diagnostics --\n")
    for (d in x@diagnostics) print(d, color = color)
  }
  invisible(x)
}
