#' @include pd-ast-pandoc.R pd-ast-block.R pd-ast-inline.R pd-ast-support.R
NULL


#' Coerce flexible input into pandoc_inlines or pandoc_blocks
#'
#' `r lifecycle::badge("experimental")`
#'
#' Smooth over the verbosity of pandoc constructors by accepting plain
#' strings, single nodes, lists of nodes, or already-wrapped sequences,
#' and producing the canonical wrapper type. Inspired by Pandoc Lua
#' filters, where constructors like `pandoc.Para("hi")` coerce strings
#' to inline sequences automatically.
#'
#' For `as_inlines()`:
#' - A character vector is split on whitespace, producing
#'   [`pandoc_str`] runs joined by [`pandoc_space()`]; embedded
#'   newlines (or multi-element character vectors) become
#'   [`pandoc_soft_break()`].
#' - A single [`pandoc_inline`] is wrapped in [`pandoc_inlines`].
#' - A list is validated and wrapped.
#' - An existing [`pandoc_inlines`] is returned as-is.
#'
#' For `as_blocks()`:
#' - A character vector becomes one [`pandoc_paragraph`] per non-empty
#'   element (each paragraph's content is `as_inlines(line)`).
#' - A single [`pandoc_block`] is wrapped in [`pandoc_blocks`].
#' - A list is validated and wrapped.
#' - An existing [`pandoc_blocks`] is returned as-is.
#'
#' These exist as ergonomic shortcuts for use inside [`ast_filter()`]
#' handlers and ad-hoc AST construction; the strict-typed constructors
#' ([`pandoc_inlines`], [`pandoc_blocks`], [`pandoc_str`], ...) remain
#' the canonical way to build nodes.
#'
#' @param x A character vector, a single inline/block node, a list of
#'   nodes, or a `pandoc_inlines`/`pandoc_blocks` wrapper.
#' @return A [`pandoc_inlines`] or [`pandoc_blocks`] wrapper.
#'
#' @examples
#' \dontrun{
#' pandoc_emph(content = as_inlines("hello world"))
#' as_blocks(c("first paragraph", "second paragraph"))
#' }
#'
#' @name ast_construct
NULL


# ---- as_inlines ---------------------------------------------------------

#' @rdname ast_construct
#' @export
as_inlines = function(x) {
  if (S7::S7_inherits(x, pandoc_inlines)) return(x)
  if (S7::S7_inherits(x, pandoc_inline)) return(pandoc_inlines(list(x)))
  if (is.character(x)) return(pandoc_inlines(chars_to_inline_items(x)))
  if (is.null(x)) return(pandoc_inlines(list()))
  if (is.list(x)) {
    if (length(x) == 0L) return(pandoc_inlines(list()))
    ok = purrr::map_lgl(x, function(e) S7::S7_inherits(e, pandoc_inline))
    if (!all(ok)) {
      stop("`as_inlines()`: every list element must inherit from pandoc_inline.",
           call. = FALSE)
    }
    return(pandoc_inlines(x))
  }
  stop("`as_inlines()`: cannot coerce <",
       paste(class(x), collapse = "/"), "> to pandoc_inlines.",
       call. = FALSE)
}


# ---- as_blocks ----------------------------------------------------------

#' @rdname ast_construct
#' @export
as_blocks = function(x) {
  if (S7::S7_inherits(x, pandoc_blocks)) return(x)
  if (S7::S7_inherits(x, pandoc_block)) return(pandoc_blocks(list(x)))
  if (is.character(x)) {
    if (length(x) == 0L) return(pandoc_blocks(list()))
    paras = purrr::keep(x, nzchar)
    if (length(paras) == 0L) return(pandoc_blocks(list()))
    return(pandoc_blocks(purrr::map(paras, function(line) {
      pandoc_paragraph(content = as_inlines(line))
    })))
  }
  if (is.null(x)) return(pandoc_blocks(list()))
  if (is.list(x)) {
    if (length(x) == 0L) return(pandoc_blocks(list()))
    ok = purrr::map_lgl(x, function(e) S7::S7_inherits(e, pandoc_block))
    if (!all(ok)) {
      stop("`as_blocks()`: every list element must inherit from pandoc_block.",
           call. = FALSE)
    }
    return(pandoc_blocks(x))
  }
  stop("`as_blocks()`: cannot coerce <",
       paste(class(x), collapse = "/"), "> to pandoc_blocks.",
       call. = FALSE)
}


# ---- helpers ------------------------------------------------------------

# Split a (possibly multi-line / multi-element) character vector into a
# list of pandoc inline nodes:
#   - whitespace within a "line" => pandoc_space()
#   - newlines / vector elements => pandoc_soft_break()
chars_to_inline_items = function(x) {
  if (length(x) == 0L) return(list())
  flat = paste(x, collapse = "\n")
  if (!nzchar(flat)) return(list())
  lines = strsplit(flat, "\n", fixed = TRUE)[[1L]]
  per_line = purrr::map(lines, line_to_inline_items)
  if (length(per_line) == 1L) return(per_line[[1L]])
  out = per_line[[1L]]
  for (extra in per_line[-1L]) {
    out[[length(out) + 1L]] = pandoc_soft_break()
    out = c(out, extra)
  }
  out
}

line_to_inline_items = function(s) {
  if (!nzchar(s)) return(list())
  words = strsplit(s, "\\s+", perl = TRUE)[[1L]]
  words = words[nzchar(words)]
  if (length(words) == 0L) return(list())
  out = list(pandoc_str(text = words[[1L]]))
  for (w in words[-1L]) {
    out[[length(out) + 1L]] = pandoc_space()
    out[[length(out) + 1L]] = pandoc_str(text = w)
  }
  out
}
