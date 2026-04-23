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
    start_point = S7::new_property(ts_point, default = ts_point()),
    end_point   = S7::new_property(ts_point, default = ts_point())
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
    range      = S7::new_property(ts_range, default = ts_range()),
    text       = S7::new_property(S7::class_any, default = NULL),
    children   = S7::new_property(ts_nodes, default = ts_nodes(list()))
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
    root        = S7::new_property(ts_node, default = ts_node()),
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

ts_format_position = function(range) {
  sprintf(
    "(%d, %d) - (%d, %d)",
    range@start_point@row, range@start_point@column,
    range@end_point@row,   range@end_point@column
  )
}

ts_format_label = function(x) {
  pos = ts_format_position(x@range)
  kind = if (x@is_named) x@kind else paste0("\"", x@kind, "\"")
  field = if (!is.null(x@field_name)) paste0(x@field_name, ": ") else ""
  is_leaf = length(x@children@content) == 0L
  text_snip = if (is_leaf && !is.null(x@text) && nzchar(x@text)) {
    paste0(" ", pandoc_quote(x@text))
  } else ""
  sprintf("%s%s %s%s", field, kind, pos, text_snip)
}

ts_collect_node = function(x, env) {
  child_ids = vapply(x@children@content, ts_collect_node, character(1L), env = env)
  pandoc_tree_add(env, ts_format_label(x), child_ids)
}

S7::method(print, ts_node) = function(x, ...) {
  env = pandoc_tree_env()
  root = ts_collect_node(x, env)
  pandoc_render_tree(root, env)
  invisible(x)
}

S7::method(print, ts_tree) = function(x,
                                       color = cli::num_ansi_colors() > 1L,
                                       ...) {
  env = pandoc_tree_env()
  root_child = ts_collect_node(x@root, env)
  root = pandoc_tree_add(
    env,
    paste0("ts_tree language=", x@language),
    root_child
  )
  pandoc_render_tree(root, env)
  if (length(x@diagnostics)) {
    cat("\n-- diagnostics --\n")
    for (d in x@diagnostics) print(d, color = color)
  }
  invisible(x)
}
