#' @include ts-ast.R
NULL

#' Render a tree-sitter AST back to QMD text
#'
#' `r lifecycle::badge("experimental")`
#'
#' Walks a [`ts_tree`] or [`ts_node`] and emits QMD source text by
#' dispatching on node kind. Aims for functional equivalence: the
#' output must re-parse to a structurally equal `ts_ast`. Where a
#' parent node carries `@text` for grammar gaps (whitespace its
#' children don't model), that text is preserved verbatim, so blank
#' lines and other inter-element whitespace round-trip faithfully.
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

# Handler factory: use @text when set (grammar-gap fallback), otherwise
# delegate to `fallback`. When `fallback = NULL`, @text is required and
# its absence is an error.
ts_text_or = function(fallback = ts_concat) {
  if (is.null(fallback)) {
    function(x) {
      if (!is.null(x@text)) return(x@text)
      stop("to_qmd(): '", x@kind, "' node has no @text fallback")
    }
  } else {
    function(x) {
      if (!is.null(x@text)) return(x@text)
      fallback(x)
    }
  }
}

ts_kind_handlers = list(
  document = function(x) {
    paste(ts_children_qmd(x), collapse = "")
  },
  section = ts_text_or(function(x) {
    paste(ts_children_qmd(x), collapse = "")
  }),
  metadata = ts_concat,

  atx_heading = function(x) {
    parts = ts_children_qmd(x)
    if (length(parts) <= 1L) {
      paste0(parts, "\n", collapse = "")
    } else {
      paste0(parts[1L], " ", paste0(parts[-1L], collapse = ""), "\n")
    }
  },

  pandoc_paragraph = ts_text_or(function(x) {
    ch = x@children@content
    if (length(ch) == 0L) return("")
    kinds = vapply(ch, function(c) c@kind, character(1L))
    parts = ts_children_qmd(x)
    n = length(ch)
    if (kinds[n] == "block_continuation") {
      paste0(paste0(parts[-n], collapse = ""), "\n", parts[n])
    } else {
      paste0(paste0(parts, collapse = ""), "\n")
    }
  }),
  pandoc_block_quote = ts_text_or(),

  pandoc_list = ts_text_or(),
  list_item    = ts_text_or(),

  pandoc_code_block = function(x) {
    ch = x@children@content
    kinds = vapply(ch, function(c) c@kind, character(1L))
    parts = ts_children_qmd(x)
    out = parts[1L]
    i = 2L
    while (i <= length(parts) &&
           kinds[i] %in% c("attribute_specifier", "info_string")) {
      out = paste0(out, parts[i])
      i = i + 1L
    }
    out = paste0(out, "\n")
    while (i <= length(parts) && kinds[i] != "fenced_code_block_delimiter") {
      out = paste0(out, parts[i])
      i = i + 1L
    }
    had_close = i <= length(parts)
    if (had_close) {
      out = paste0(out, parts[i])
      i = i + 1L
    }
    if (i <= length(parts)) {
      out = paste0(out, paste0(parts[i:length(parts)], collapse = ""))
    } else if (had_close || !endsWith(out, "\n")) {
      out = paste0(out, "\n")
    }
    out
  },

  code_fence_content = ts_text_or(NULL),

  pandoc_emph      = ts_concat,
  pandoc_strong    = ts_concat,
  pandoc_code_span = ts_concat,
  content          = ts_concat,

  pandoc_span  = ts_text_or(),
  pandoc_image = ts_text_or(),
  target       = ts_text_or(NULL),

  attribute_specifier  = ts_concat,
  commonmark_specifier = ts_text_or(),
  language_specifier   = ts_text_or(),
  key_value_specifier  = ts_concat,
  key_value_value      = ts_text_or(),

  pandoc_math         = ts_text_or(NULL),
  pandoc_display_math = ts_text_or(NULL),
  pandoc_div          = ts_text_or(NULL),
  pipe_table          = ts_text_or(NULL),
  caption             = ts_text_or(NULL),
  shortcode           = ts_text_or(NULL),
  inline_ref_def      = ts_text_or(NULL)
)
