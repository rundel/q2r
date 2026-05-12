#' @include pd-ast-pandoc.R
NULL

#' Label a pandoc AST node for tree display
#'
#' Generic returning a single-line label for a node. Override per class
#' to include node-specific summary information (level, url, type, ...).
#'
#' @param x An AST node.
#' @export
pandoc_format_label = S7::new_generic("pandoc_format_label", "x")

#' Children of a pandoc AST node for tree display
#'
#' Generic returning a named list of child subtrees. A child may be a
#' `pandoc_node`, a `pandoc_blocks`/`pandoc_inlines` wrapper, or a plain
#' list of either (used for multi-item containers such as bullet lists).
#' `NULL` entries are skipped.
#'
#' @param x An AST node.
#' @export
pandoc_children = S7::new_generic("pandoc_children", "x")

pandoc_strip_prefix = function(name) sub("^pandoc_", "", name)

pandoc_style_kind  = function(x) cli::col_cyan(x)
pandoc_style_val   = function(x) cli::col_green(x)
pandoc_style_field = function(x) cli::col_silver(x)
pandoc_style_attr  = function(x) cli::col_yellow(x)
pandoc_style_pos   = function(x) cli::col_silver(x)

pandoc_field = function(key) pandoc_style_field(paste0(key, "="))

pandoc_truncate = function(text,
                           n = getOption("q2r.print_max_width", 40L),
                           side = getOption("q2r.print_trunc_side", "right")) {
  if (length(text) == 0L) return("")
  side = match.arg(side, c("right", "left", "center"))
  s = encodeString(paste(text, collapse = " "))
  stringr::str_trunc(s, width = n, side = side, ellipsis = "…")
}

pandoc_quote = function(text) {
  pandoc_style_val(paste0("\"", pandoc_truncate(text), "\""))
}

pandoc_format_attr = function(attr) {
  if (pandoc_attr_is_empty(attr)) return("")
  parts = character()
  if (nchar(attr@id) > 0L) parts = c(parts, paste0("#", attr@id))
  if (length(attr@classes) > 0L) parts = c(parts, paste0(".", attr@classes))
  if (length(attr@attributes) > 0L) {
    kv = paste0(names(attr@attributes), "=", attr@attributes)
    parts = c(parts, kv)
  }
  pandoc_style_attr(paste0(" (", paste(parts, collapse = " "), ")"))
}

pandoc_class_name = function(x) {
  cls = S7::S7_class(x)
  if (is.null(cls)) class(x)[[1L]] else cls@name
}

S7::method(pandoc_format_label, pandoc_node) = function(x) {
  pandoc_style_kind(pandoc_strip_prefix(pandoc_class_name(x)))
}

S7::method(pandoc_children, pandoc_node) = function(x) list()

S7::method(pandoc_format_label, pandoc_str) = function(x) {
  paste0(pandoc_style_kind("str"), " ", pandoc_quote(x@text))
}

S7::method(pandoc_format_label, pandoc_code) = function(x) {
  paste0(pandoc_style_kind("code"), " ", pandoc_quote(x@text), pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_code_block) = function(x) {
  paste0(pandoc_style_kind("code_block"), " ", pandoc_quote(x@text), pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_math) = function(x) {
  paste0(
    pandoc_style_kind("math"), " ",
    pandoc_field("type"), x@math_type, " ",
    pandoc_quote(x@text)
  )
}

S7::method(pandoc_format_label, pandoc_raw_block) = function(x) {
  paste0(
    pandoc_style_kind("raw_block"), " ",
    pandoc_field("format"), x@format, " ",
    pandoc_quote(x@text)
  )
}

S7::method(pandoc_format_label, pandoc_raw_inline) = function(x) {
  paste0(
    pandoc_style_kind("raw_inline"), " ",
    pandoc_field("format"), x@format, " ",
    pandoc_quote(x@text)
  )
}

S7::method(pandoc_format_label, pandoc_header) = function(x) {
  paste0(
    pandoc_style_kind("header"), " ",
    pandoc_field("level"), x@level,
    pandoc_format_attr(x@attr)
  )
}

S7::method(pandoc_format_label, pandoc_link) = function(x) {
  tail = if (nchar(x@title) > 0L) {
    paste0(" ", pandoc_field("title"), pandoc_quote(x@title))
  } else ""
  paste0(
    pandoc_style_kind("link"), " ",
    pandoc_field("url"), pandoc_quote(x@url),
    tail, pandoc_format_attr(x@attr)
  )
}

S7::method(pandoc_format_label, pandoc_image) = function(x) {
  tail = if (nchar(x@title) > 0L) {
    paste0(" ", pandoc_field("title"), pandoc_quote(x@title))
  } else ""
  paste0(
    pandoc_style_kind("image"), " ",
    pandoc_field("url"), pandoc_quote(x@url),
    tail, pandoc_format_attr(x@attr)
  )
}

S7::method(pandoc_format_label, pandoc_quoted) = function(x) {
  paste0(pandoc_style_kind("quoted"), " ", pandoc_field("type"), x@quote_type)
}

S7::method(pandoc_format_label, pandoc_cite) = function(x) {
  paste0(pandoc_style_kind("cite"), " (", length(x@citations), " citations)")
}

S7::method(pandoc_format_label, pandoc_ordered_list) = function(x) {
  paste0(
    pandoc_style_kind("ordered_list"), " ",
    pandoc_field("start"), x@attr@start, " ",
    pandoc_field("style"), x@attr@style, " ",
    pandoc_field("delim"), x@attr@delim
  )
}

S7::method(pandoc_format_label, pandoc_div) = function(x) {
  paste0(pandoc_style_kind("div"), pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_span) = function(x) {
  paste0(pandoc_style_kind("span"), pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_figure) = function(x) {
  paste0(pandoc_style_kind("figure"), pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_table) = function(x) {
  paste0(pandoc_style_kind("table"), pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_note_reference) = function(x) {
  paste0(pandoc_style_kind("note_reference"), " ", pandoc_field("id"), x@id)
}

S7::method(pandoc_format_label, pandoc_note_definition_para) = function(x) {
  paste0(pandoc_style_kind("note_definition_para"), " ", pandoc_field("id"), x@id)
}

S7::method(pandoc_format_label, pandoc_note_definition_fenced_block) = function(x) {
  paste0(pandoc_style_kind("note_definition_fenced_block"), " ", pandoc_field("id"), x@id)
}

S7::method(pandoc_format_label, pandoc_custom_block) = function(x) {
  paste0(
    pandoc_style_kind("custom_block"), " ",
    pandoc_field("type"), x@type_name,
    pandoc_format_attr(x@attr)
  )
}

S7::method(pandoc_format_label, pandoc_custom_inline) = function(x) {
  paste0(
    pandoc_style_kind("custom_inline"), " ",
    pandoc_field("type"), x@type_name,
    pandoc_format_attr(x@attr)
  )
}

S7::method(pandoc_format_label, pandoc_shortcode) = function(x) {
  paste0(pandoc_style_kind("shortcode"), " ", pandoc_field("name"), x@name)
}

S7::method(pandoc_format_label, pandoc_attr_inline) = function(x) {
  paste0(pandoc_style_kind("attr_inline"), pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_block_metadata) = function(x) {
  pandoc_style_kind("block_metadata")
}

S7::method(pandoc_format_label, pandoc_citation) = function(x) {
  paste0(
    pandoc_style_kind("citation"), " ",
    pandoc_field("id"), x@id, " ",
    pandoc_field("mode"), x@mode
  )
}

S7::method(pandoc_format_label, pandoc_definition_item) = function(x) {
  pandoc_style_kind("definition_item")
}

S7::method(pandoc_format_label, pandoc_caption) = function(x) {
  pandoc_style_kind("caption")
}

S7::method(pandoc_format_label, pandoc_table_head) = function(x) {
  paste0(pandoc_style_kind("table_head"), pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_table_body) = function(x) {
  rhc = if (x@row_head_columns != 0L) {
    paste0(" ", pandoc_field("row_head_columns"), x@row_head_columns)
  } else ""
  paste0(pandoc_style_kind("table_body"), rhc, pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_table_foot) = function(x) {
  paste0(pandoc_style_kind("table_foot"), pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_row) = function(x) {
  paste0(pandoc_style_kind("row"), pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_cell) = function(x) {
  span = if (x@row_span != 1L || x@col_span != 1L) {
    paste0(" ", pandoc_field("row_span"), x@row_span,
           " ", pandoc_field("col_span"), x@col_span)
  } else ""
  align = if (!identical(x@alignment, "Default")) {
    paste0(" ", pandoc_field("alignment"), x@alignment)
  } else ""
  paste0(pandoc_style_kind("cell"), align, span, pandoc_format_attr(x@attr))
}

children_content = function(x) list(content = x@content)

S7::method(pandoc_children, pandoc_plain)                        = children_content
S7::method(pandoc_children, pandoc_paragraph)                    = children_content
S7::method(pandoc_children, pandoc_block_quote)                  = children_content
S7::method(pandoc_children, pandoc_header)                       = children_content
S7::method(pandoc_children, pandoc_definition_list)              = children_content
S7::method(pandoc_children, pandoc_div)                          = children_content
S7::method(pandoc_children, pandoc_note_definition_para)         = children_content
S7::method(pandoc_children, pandoc_note_definition_fenced_block) = children_content
S7::method(pandoc_children, pandoc_caption_block)                = children_content

S7::method(pandoc_children, pandoc_emph)         = children_content
S7::method(pandoc_children, pandoc_underline)    = children_content
S7::method(pandoc_children, pandoc_strong)       = children_content
S7::method(pandoc_children, pandoc_strikeout)    = children_content
S7::method(pandoc_children, pandoc_superscript)  = children_content
S7::method(pandoc_children, pandoc_subscript)    = children_content
S7::method(pandoc_children, pandoc_small_caps)   = children_content
S7::method(pandoc_children, pandoc_quoted)       = children_content
S7::method(pandoc_children, pandoc_link)         = children_content
S7::method(pandoc_children, pandoc_image)        = children_content
S7::method(pandoc_children, pandoc_note)         = children_content
S7::method(pandoc_children, pandoc_span)         = children_content
S7::method(pandoc_children, pandoc_insert)       = children_content
S7::method(pandoc_children, pandoc_delete)       = children_content
S7::method(pandoc_children, pandoc_highlight)    = children_content
S7::method(pandoc_children, pandoc_edit_comment) = children_content

S7::method(pandoc_children, pandoc_line_block) = function(x) {
  list(lines = x@content)
}

S7::method(pandoc_children, pandoc_ordered_list) = function(x) {
  list(items = x@content)
}

S7::method(pandoc_children, pandoc_bullet_list) = function(x) {
  list(items = x@content)
}

S7::method(pandoc_children, pandoc_cite) = function(x) {
  list(citations = x@citations, content = x@content)
}

S7::method(pandoc_children, pandoc_figure) = function(x) {
  list(caption = x@caption, content = x@content)
}

S7::method(pandoc_children, pandoc_table) = function(x) {
  list(
    caption = x@caption,
    head    = x@head,
    bodies  = x@bodies,
    foot    = x@foot
  )
}

S7::method(pandoc_children, pandoc_caption) = function(x) {
  list(short = x@short, long = x@long)
}

S7::method(pandoc_children, pandoc_definition_item) = function(x) {
  list(term = x@term, defs = x@defs)
}

S7::method(pandoc_children, pandoc_citation) = function(x) {
  list(prefix = x@prefix, suffix = x@suffix)
}

S7::method(pandoc_children, pandoc_table_head) = function(x) {
  list(rows = x@rows)
}

S7::method(pandoc_children, pandoc_table_body) = function(x) {
  list(head_rows = x@head_rows, body_rows = x@body_rows)
}

S7::method(pandoc_children, pandoc_table_foot) = function(x) {
  list(rows = x@rows)
}

S7::method(pandoc_children, pandoc_row) = function(x) {
  list(cells = x@cells)
}

S7::method(pandoc_children, pandoc_cell) = children_content

pandoc_tree_env = function() {
  env = new.env(parent = emptyenv())
  env$counter = 0L
  env$ids = character()
  env$labels = character()
  env$children = list()
  env
}

pandoc_tree_add = function(env, label, children = character()) {
  env$counter = env$counter + 1L
  id = paste0("n", env$counter)
  env$ids = c(env$ids, id)
  env$labels = c(env$labels, label)
  env$children[[length(env$children) + 1L]] = children
  id
}

pandoc_tree_df = function(env) {
  data.frame(
    id = env$ids,
    children = I(env$children),
    label = env$labels,
    stringsAsFactors = FALSE
  )
}

pandoc_collect_node = function(x, env) {
  kids = pandoc_children(x)
  names_kids = names(kids)
  if (is.null(names_kids)) names_kids = rep("", length(kids))
  single = length(kids) == 1L

  child_ids = character()
  for (i in seq_along(kids)) {
    label_i = if (single) "" else names_kids[[i]]
    child_ids = c(child_ids, pandoc_collect_child(kids[[i]], label_i, env))
  }

  pandoc_tree_add(env, pandoc_format_label(x), child_ids)
}

pandoc_collect_child = function(child, label, env) {
  if (is.null(child)) return(character())

  if (S7::S7_inherits(child, pandoc_blocks) || S7::S7_inherits(child, pandoc_inlines)) {
    if (length(child@content) == 0L) return(character())
    item_ids = unlist(lapply(child@content, pandoc_collect_node, env = env))
    if (nzchar(label)) {
      return(pandoc_tree_add(env, pandoc_style_field(paste0(label, ":")), item_ids))
    }
    return(item_ids)
  }

  if (is.list(child) && !S7::S7_inherits(child, pandoc_node)) {
    if (length(child) == 0L) return(character())
    item_ids = unlist(lapply(child, pandoc_collect_child, label = "", env = env))
    if (nzchar(label)) {
      return(pandoc_tree_add(env, pandoc_style_field(paste0(label, ":")), item_ids))
    }
    return(item_ids)
  }

  pandoc_collect_node(child, env)
}

pandoc_render_tree = function(root_id, env) {
  cat(cli::tree(pandoc_tree_df(env), root = root_id), sep = "\n")
}

pandoc_render_forest = function(child_ids, env) {
  for (id in child_ids) pandoc_render_tree(id, env)
}

pandoc_tree_lines = function(x) {
  env = pandoc_tree_env()
  root = if (S7::S7_inherits(x, pandoc)) {
    child_ids = character()
    if (!identical(x@meta@kind, "map") || length(x@meta@value) > 0L) {
      child_ids = c(child_ids, pandoc_tree_add(
        env,
        paste0(pandoc_style_kind("meta"), ": ", x@meta@kind)
      ))
    }
    for (block in x@blocks@content) {
      child_ids = c(child_ids, pandoc_collect_node(block, env))
    }
    pandoc_tree_add(env, pandoc_style_kind("pandoc"), child_ids)
  } else {
    pandoc_collect_node(x, env)
  }
  as.character(cli::tree(pandoc_tree_df(env), root = root))
}

#' Print a Pandoc AST
#'
#' Renders a [`pandoc`] document or any individual [`pandoc_node`]
#' (block or inline) as an indented tree.
#'
#' @param x A [`pandoc`], [`pandoc_node`], [`pandoc_blocks`], or
#'   [`pandoc_inlines`] object.
#' @param color For `pandoc`, whether to use ANSI colour when printing
#'   attached diagnostics. Defaults to whether the terminal supports it.
#' @param ... Unused; present for S3/S7 compatibility.
#' @return `x`, invisibly.
#' @name print.pandoc
#' @aliases print.pandoc_node print.pandoc_blocks print.pandoc_inlines
NULL

S7::method(print, pandoc_node) = function(x, ...) {
  cat(pandoc_tree_lines(x), sep = "\n")
  invisible(x)
}

S7::method(print, pandoc) = function(x,
                                      color = cli::num_ansi_colors() > 1L,
                                      ...) {
  cat(pandoc_tree_lines(x), sep = "\n")
  if (length(x@diagnostics)) {
    cat("\n-- diagnostics --\n")
    for (d in x@diagnostics) print(d, color = color)
  }
  invisible(x)
}

S7::method(print, pandoc_blocks) = function(x, ...) {
  env = pandoc_tree_env()
  ids = vapply(x@content, pandoc_collect_node, character(1L), env = env)
  pandoc_render_forest(ids, env)
  invisible(x)
}

S7::method(print, pandoc_inlines) = function(x, ...) {
  env = pandoc_tree_env()
  ids = vapply(x@content, pandoc_collect_node, character(1L), env = env)
  pandoc_render_forest(ids, env)
  invisible(x)
}
