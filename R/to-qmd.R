#' @include ts-ast.R pd-ast-pandoc.R to-rust.R
NULL

#' Render an R-side AST back to QMD text
#'
#' `r lifecycle::badge("experimental")`
#'
#' `to_qmd()` is the single entry point for turning an R-held AST back
#' into QMD source text. Two top-level methods are defined:
#'
#' * `to_qmd(pandoc)` rebuilds pampa's `Pandoc` value in Rust from the
#'   tagged-list shape produced by [`pandoc_to_list()`] and runs
#'   `pampa::writers::qmd::write` on it. Pampa is the sole source of
#'   truth for QMD writing.
#' * `to_qmd(ts_tree)` recovers source bytes by walking the tree-sitter
#'   AST and falling back to each node's `@text` slot where children
#'   don't cover all of the parent's bytes (grammar gaps). This is
#'   byte-recovery, not "writing" - a tree-sitter AST already represents
#'   source bytes, and pampa exposes no public `ts_ast -> Pandoc`
#'   conversion that we could invoke independently of its reader.
#'
#' Only top-level dispatch is currently supported. There is no method
#' for individual blocks, inlines, or `ts_node` subtrees (TODO: restore
#' sub-tree dispatch by wrapping a fragment in a minimal `pandoc` and
#' routing through pampa).
#'
#' @param x A [`pandoc`] or [`ts_tree`] object.
#' @return A single string with the rendered QMD.
#' @export
to_qmd = S7::new_generic("to_qmd", "x")

S7::method(to_qmd, pandoc) = function(x) {
  raw = pampa_write_qmd_ast_impl(pandoc_to_list(x))
  if (is.null(raw$text)) {
    msg = if (length(raw$error)) {
      paste0("to_qmd(): pampa's QMD writer failed: ", raw$error)
    } else {
      "to_qmd(): pampa's QMD writer failed; see attached diagnostics"
    }
    diagnostics = pampa_diagnostics_from_raw(raw, "", "<ast>")
    stop(structure(
      class = c("to_qmd_error", "error", "condition"),
      list(
        message     = msg,
        call        = sys.call(-1L),
        diagnostics = diagnostics,
        error       = raw$error
      )
    ))
  }
  result = raw$text
  diagnostics = pampa_diagnostics_from_raw(raw, "", "<ast>")
  if (length(diagnostics)) attr(result, "diagnostics") = diagnostics
  result
}

S7::method(to_qmd, ts_tree) = function(x) to_qmd_ts_node(x@root)

to_qmd_ts_node = function(x) {
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
  vapply(x@children@content, to_qmd_ts_node, character(1L))
}

ts_concat = function(x) paste0(ts_children_qmd(x), collapse = "")

ts_concat_nl = function(x) paste0(ts_concat(x), "\n")

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

  attribute_specifier  = ts_text_or(),
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
