#' @include pd-ast-pandoc.R pd-ast-block.R ast-text.R ast-sections.R select.R
NULL

#' Select the blocks belonging to a heading section
#'
#' `r lifecycle::badge("experimental")`
#'
#' Slices the contiguous run of top-level blocks introduced by a
#' heading whose title (and ancestor titles) match `path`. This is the
#' Pandoc analog of parsermd's `by_section()`: where `select_nodes()`
#' can find the [`pandoc_header`] node, `select_section()` returns the
#' header together with everything beneath it, up to the next heading of
#' equal or higher level.
#'
#' `path` is a character vector of glob patterns, outermost heading
#' first, matched against the enclosing-heading chain from
#' [`ast_sections()`] (collapsed to the non-`NA` levels selected by
#' `levels`). A section anchor matches when its collapsed heading chain
#' has the same length as `path` and each element glob-matches, so
#' `path = c("Results", "Model *")` selects each `Model *` subsection
#' nested directly under a `Results` heading. Headings whose level is
#' not in `levels` are treated as ordinary content.
#'
#' Section membership depends on document order, which a per-node
#' predicate (evaluated on one node in isolation) cannot see; that is
#' why this is a dedicated verb rather than a `has_*()` mask helper.
#'
#' @param x A [`pandoc`] document, a [`pandoc_blocks`] wrapper, or a
#'   plain `list` of top-level blocks.
#' @param path Character vector of glob patterns naming the heading
#'   chain to match, outermost first.
#' @param levels Integer vector of heading levels (1-6) that count as
#'   section boundaries. Defaults to all levels.
#' @param include_heading Whether to include the matched heading block
#'   itself in the result (default `TRUE`).
#' @return A `list` of blocks (consistent with [`select_nodes()`]).
#'   Wrap it in `pandoc(blocks = pandoc_blocks(result))` to render it
#'   with [`to_qmd()`].
#'
#' @examples
#' \dontrun{
#' doc = parse_qmd("# Intro\n\na\n\n## Setup\n\nb\n\n# Other\n\nc\n")
#' select_section(doc, "Intro")
#' select_section(doc, c("Intro", "Setup"), include_heading = FALSE)
#' }
#'
#' @export
select_section = S7::new_generic(
  "select_section", "x",
  function(x, path, levels = 1:6, include_heading = TRUE) S7::S7_dispatch()
)

S7::method(select_section, pd_block_source) = function(x, path, levels = 1:6, include_heading = TRUE) {
  select_section_on_blocks(as_block_list(x), path, levels, include_heading)
}


section_anchor_matches = function(stack, path, levels) {
  collapsed = stack[levels]
  collapsed = collapsed[!is.na(collapsed)]
  if (length(collapsed) != length(path)) return(FALSE)
  all(purrr::map2_lgl(path, collapsed, function(pat, val) {
    grepl(utils::glob2rx(pat), val)
  }))
}

select_section_on_blocks = function(blocks, path, levels, include_heading) {
  if (!is.character(path) || length(path) == 0L) {
    stop("`select_section()`: `path` must be a non-empty character vector.",
         call. = FALSE)
  }
  if (length(blocks) == 0L) return(list())
  secs = ast_sections_of_blocks(blocks)
  is_boundary = function(b) {
    S7::S7_inherits(b, pandoc_header) && length(b@level) == 1L &&
      !is.na(b@level) && b@level %in% levels
  }
  n = length(blocks)
  keep = logical(n)
  for (i in seq_len(n)) {
    b = blocks[[i]]
    if (!is_boundary(b)) next
    if (!section_anchor_matches(secs[[i]], path, levels)) next
    end = n
    if (i < n) {
      for (j in (i + 1L):n) {
        if (is_boundary(blocks[[j]]) && blocks[[j]]@level <= b@level) {
          end = j - 1L
          break
        }
      }
    }
    rng = if (include_heading) {
      i:end
    } else if (end > i) {
      (i + 1L):end
    } else {
      integer(0)
    }
    keep[rng] = TRUE
  }
  blocks[which(keep)]
}
