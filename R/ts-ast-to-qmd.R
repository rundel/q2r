#' @include ast-cst.R result.R
NULL

#' Render a tree-sitter CST back to QMD text
#'
#' Walks a [`ts_tree`] or [`ts_node`] and emits QMD source text by
#' dispatching on node kind. Output is canonical: blank-line counts,
#' trailing whitespace, and indentation variants are normalized.
#'
#' @param x A [`ts_tree`] or [`ts_node`].
#' @return A single string.
#' @export
to_qmd = S7::new_generic("to_qmd", "x")

S7::method(to_qmd, ts_tree) = function(x) to_qmd(x@root)

S7::method(to_qmd, ts_node) = function(x) {
  if (length(x@children@content) == 0L) {
    return(if (is.null(x@text)) "" else x@text)
  }
  handler = ts_kind_handlers[[x@kind]]
  if (is.null(handler)) {
    warning(
      "to_qmd(): no rule for ts_node kind '", x@kind,
      "' - falling back to plain concatenation"
    )
    handler = ts_concat
  }
  handler(x)
}

ts_children_qmd = function(x) {
  vapply(x@children@content, to_qmd, character(1L))
}

ts_concat = function(x) paste0(ts_children_qmd(x), collapse = "")

ts_concat_nl = function(x) paste0(ts_concat(x), "\n")

ts_kind_handlers = list(
  document = ts_concat,
  section = function(x) {
    parts = ts_children_qmd(x)
    paste0(paste(parts, collapse = "\n"), "")
  },
  metadata = ts_concat,

  atx_heading = function(x) {
    parts = ts_children_qmd(x)
    if (length(parts) <= 1L) {
      paste0(parts, "\n", collapse = "")
    } else {
      paste0(parts[1L], " ", paste0(parts[-1L], collapse = ""), "\n")
    }
  },

  pandoc_paragraph = ts_concat_nl,
  pandoc_block_quote = ts_concat,

  pandoc_list = ts_concat,
  list_item = ts_concat,

  pandoc_code_block = function(x) {
    ch = x@children@content
    kinds = vapply(ch, function(c) c@kind, character(1L))
    parts = ts_children_qmd(x)
    out = parts[1L]
    i = 2L
    if (i <= length(parts) && kinds[i] == "attribute_specifier") {
      out = paste0(out, parts[i])
      i = i + 1L
    }
    out = paste0(out, "\n")
    while (i <= length(parts) && kinds[i] != "fenced_code_block_delimiter") {
      out = paste0(out, parts[i])
      i = i + 1L
    }
    if (i <= length(parts)) {
      out = paste0(out, parts[i])
      i = i + 1L
    }
    paste0(out, "\n")
  },

  code_fence_content = function(x) {
    if (!is.null(x@text)) return(x@text)
    stop("to_qmd(): 'code_fence_content' node has no @text fallback")
  },

  pandoc_emph = ts_concat,
  pandoc_strong = ts_concat,
  pandoc_code_span = ts_concat,
  content = ts_concat,

  pandoc_span = ts_concat,
  pandoc_image = ts_concat,
  target = function(x) paste0("](", ts_concat(x)),

  attribute_specifier = ts_concat,
  commonmark_specifier = function(x) {
    paste(ts_children_qmd(x), collapse = " ")
  },

  pandoc_math = function(x) {
    if (!is.null(x@text)) return(x@text)
    stop("to_qmd(): 'pandoc_math' node has no @text fallback")
  },
  pandoc_display_math = function(x) {
    if (!is.null(x@text)) return(x@text)
    stop("to_qmd(): 'pandoc_display_math' node has no @text fallback")
  }
)
