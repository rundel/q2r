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
  n = max(1L, n)  # str_trunc() aborts when width < the ellipsis width
  side = match.arg(side, c("right", "left", "center"))
  s = encodeString(if (length(text) > 1L) paste(text, collapse = " ") else text)
  if (nchar(s) <= n) return(s)
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

format_link_like = function(x, kind) {
  tail = if (nchar(x@title) > 0L) {
    paste0(" ", pandoc_field("title"), pandoc_quote(x@title))
  } else ""
  paste0(
    pandoc_style_kind(kind), " ",
    pandoc_field("url"), pandoc_quote(x@url),
    tail, pandoc_format_attr(x@attr)
  )
}

S7::method(pandoc_format_label, pandoc_link) = function(x) format_link_like(x, "link")

S7::method(pandoc_format_label, pandoc_image) = function(x) format_link_like(x, "image")

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

format_kind_id = function(x, kind) {
  paste0(pandoc_style_kind(kind), " ", pandoc_field("id"), x@id)
}

S7::method(pandoc_format_label, pandoc_note_reference) = function(x) {
  format_kind_id(x, "note_reference")
}

S7::method(pandoc_format_label, pandoc_note_definition_para) = function(x) {
  format_kind_id(x, "note_definition_para")
}

S7::method(pandoc_format_label, pandoc_note_definition_fenced_block) = function(x) {
  format_kind_id(x, "note_definition_fenced_block")
}

format_custom_node = function(x, kind) {
  paste0(
    pandoc_style_kind(kind), " ",
    pandoc_field("type"), x@type_name,
    pandoc_format_attr(x@attr)
  )
}

S7::method(pandoc_format_label, pandoc_custom_block) = function(x) {
  format_custom_node(x, "custom_block")
}

S7::method(pandoc_format_label, pandoc_custom_inline) = function(x) {
  format_custom_node(x, "custom_inline")
}

S7::method(pandoc_format_label, pandoc_shortcode) = function(x) {
  paste0(pandoc_style_kind("shortcode"), " ", pandoc_field("name"), x@name)
}

S7::method(pandoc_format_label, pandoc_attr_inline) = function(x) {
  paste0(pandoc_style_kind("attr_inline"), pandoc_format_attr(x@attr))
}

S7::method(pandoc_format_label, pandoc_citation) = function(x) {
  paste0(
    pandoc_style_kind("citation"), " ",
    pandoc_field("id"), x@id, " ",
    pandoc_field("mode"), x@mode
  )
}

# definition_item and caption are support types that do not inherit
# pandoc_node, so the pandoc_node default does not cover them.
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

pandoc_tree_chars = function() {
  if (isTRUE(cli::is_utf8_output())) {
    list(tee = "├─", ell = "└─", vbar = "│ ", blk = "  ")
  } else {
    list(tee = "+-", ell = "\\-", vbar = "| ", blk = "  ")
  }
}

pandoc_tree_buf = function() {
  e = new.env(parent = emptyenv())
  e$v = vector("list", 256L)
  e$n = 0L
  e$chars = pandoc_tree_chars()
  e
}

pandoc_tree_buf_push = function(buf, line) {
  buf$n = buf$n + 1L
  if (buf$n > length(buf$v)) length(buf$v) = length(buf$v) * 2L
  buf$v[[buf$n]] = line
  invisible()
}

pandoc_tree_buf_lines = function(buf) {
  if (buf$n == 0L) character(0L) else unlist(buf$v[seq_len(buf$n)], use.names = FALSE)
}

pandoc_flatten_child = function(child, label) {
  if (is.null(child)) return(list())

  if (S7::S7_inherits(child, pandoc_blocks) || S7::S7_inherits(child, pandoc_inlines)) {
    content = child@content
    if (length(content) == 0L) return(list())
    if (nzchar(label)) {
      return(list(list(kind = "group", label = label, items = content)))
    }
    return(lapply(content, function(n) list(kind = "node", node = n)))
  }

  if (is.list(child) && !S7::S7_inherits(child, pandoc_node)) {
    if (length(child) == 0L) return(list())
    inner = list()
    for (sub in child) {
      sub_entries = pandoc_flatten_child(sub, "")
      if (length(sub_entries)) inner = c(inner, sub_entries)
    }
    if (nzchar(label)) {
      items = lapply(inner, function(e) e$node)
      return(list(list(kind = "group", label = label, items = items)))
    }
    return(inner)
  }

  list(list(kind = "node", node = child))
}

pandoc_child_entries = function(node) {
  kids = pandoc_children(node)
  nk = length(kids)
  if (nk == 0L) return(list())
  nlist = names(kids)
  if (is.null(nlist)) nlist = rep("", nk)
  single = nk == 1L
  out = list()
  for (i in seq_len(nk)) {
    label_i = if (single) "" else nlist[[i]]
    sub = pandoc_flatten_child(kids[[i]], label_i)
    if (length(sub)) out = c(out, sub)
  }
  out
}

pandoc_emit_node = function(buf, x, prefix_self, prefix_kids) {
  pandoc_tree_buf_push(buf, paste0(prefix_self, pandoc_format_label(x)))
  entries = pandoc_child_entries(x)
  if (length(entries)) pandoc_emit_entries(buf, entries, prefix_kids)
}

pandoc_emit_entries = function(buf, entries, prefix_kids) {
  ne = length(entries)
  if (ne == 0L) return()
  chars = buf$chars
  for (i in seq_len(ne)) {
    e = entries[[i]]
    last = i == ne
    branch = if (last) chars$ell else chars$tee
    cont   = if (last) chars$blk else chars$vbar
    if (e$kind == "node") {
      pandoc_emit_node(
        buf, e$node,
        prefix_self = paste0(prefix_kids, branch),
        prefix_kids = paste0(prefix_kids, cont)
      )
    } else if (e$kind == "leaf") {
      pandoc_tree_buf_push(buf, paste0(prefix_kids, branch, e$label))
    } else {
      pandoc_tree_buf_push(
        buf,
        paste0(prefix_kids, branch, pandoc_style_field(paste0(e$label, ":")))
      )
      sub_prefix = paste0(prefix_kids, cont)
      items = e$items
      m = length(items)
      for (j in seq_len(m)) {
        lst = j == m
        br = if (lst) chars$ell else chars$tee
        co = if (lst) chars$blk else chars$vbar
        pandoc_emit_node(
          buf, items[[j]],
          prefix_self = paste0(sub_prefix, br),
          prefix_kids = paste0(sub_prefix, co)
        )
      }
    }
  }
}

pandoc_tree_lines = function(x) {
  withr::local_options(cli.num_colors = cli::num_ansi_colors())
  buf = pandoc_tree_buf()

  if (S7::S7_inherits(x, pandoc)) {
    pandoc_tree_buf_push(buf, pandoc_style_kind("pandoc"))
    entries = list()
    if (!identical(x@meta@kind, "map") || length(x@meta@value) > 0L) {
      entries[[length(entries) + 1L]] = list(
        kind = "leaf",
        label = paste0(pandoc_style_kind("meta"), ": ", x@meta@kind)
      )
    }
    for (block in x@blocks@content) {
      entries[[length(entries) + 1L]] = list(kind = "node", node = block)
    }
    if (length(entries)) pandoc_emit_entries(buf, entries, "")
  } else {
    pandoc_emit_node(buf, x, prefix_self = "", prefix_kids = "")
  }

  pandoc_tree_buf_lines(buf)
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

# A compact one-line representation (distinct from print()'s full tree),
# so a list-column of nodes - e.g. ast_summary()'s `node` column -
# formats as `<pandoc_header>` rather than erroring. Deliberately scoped to
# pandoc_node: the support types (caption, row, cell, citation, ...) are never
# put in a list-column, so they keep base format() and are labeled via
# pandoc_format_label() inside the tree printer instead.
S7::method(format, pandoc_node) = function(x, ...) {
  paste0("<", pandoc_class_name(x), ">")
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

pandoc_print_forest = function(content) {
  withr::local_options(cli.num_colors = cli::num_ansi_colors())
  for (node in content) {
    buf = pandoc_tree_buf()
    pandoc_emit_node(buf, node, prefix_self = "", prefix_kids = "")
    cat(pandoc_tree_buf_lines(buf), sep = "\n")
  }
}

S7::method(print, pandoc_blocks) = function(x, ...) {
  pandoc_print_forest(x@content)
  invisible(x)
}

S7::method(print, pandoc_inlines) = function(x, ...) {
  pandoc_print_forest(x@content)
  invisible(x)
}
