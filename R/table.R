#' @include pd-ast-pandoc.R pd-ast-block.R pd-ast-support.R ast-text.R ast-construct.R select.R
NULL

#' Convert between pandoc tables and data frames
#'
#' `r lifecycle::badge("experimental")`
#'
#' Bridge the [`pandoc_table`] node and the data structure R users work
#' in. `as_df()` flattens a parsed table into a `data.frame` (the
#' header row becomes column names, each cell is rendered to plain text
#' with [`ast_text()`]); `as_table()` builds a [`pandoc_table`] from a
#' `data.frame` so it can be spliced into a document and written back with
#' [`to_qmd()`]. Together they are the q2r analog of mq's `table::` module.
#'
#' Column alignments, the table caption, and the table identifier ride
#' along on the returned `data.frame` as the attributes `"q2r_align"`,
#' `"q2r_caption"`, and `"q2r_id"`, and `as_table()` reads them back when
#' its own `align` / `caption` / `id` arguments are left at their
#' defaults. A `as_df()` then `as_table()` round trip therefore
#' preserves alignment and caption without extra bookkeeping.
#'
#' Cells are reduced to plain text, so inline formatting (emphasis, links,
#' code) inside a cell is dropped. Cell row and column spans are not
#' modelled: each cell maps to exactly one column.
#'
#' Only the first header row becomes the column names; any further header
#' rows and any body group-header rows are flattened into ordinary data
#' rows.
#'
#' @param x A [`pandoc_table`] (returns one `data.frame`), or a
#'   [`pandoc`] / [`pandoc_blocks`] / list of blocks (returns a list of
#'   `data.frame`s, one per table found in document order).
#' @param df A `data.frame` (or object coercible to one).
#' @param caption Table caption as a string, or `NULL` for none. Defaults
#'   to the `"q2r_caption"` attribute of `df` if present.
#' @param align Column alignments, one of `"left"`, `"right"`,
#'   `"center"`, or `"default"` per column (recycled to the number of
#'   columns). Defaults to the `"q2r_align"` attribute of `df`, else
#'   `"default"`.
#' @param id Table identifier (the Quarto `#tbl-` label). Defaults to the
#'   `"q2r_id"` attribute of `df`, else `""`.
#' @return `as_df()` returns a `data.frame` (or list thereof);
#'   `as_table()` returns a [`pandoc_table`].
#'
#' @examples
#' \dontrun{
#' doc = parse_qmd("| a | b |\n|--:|:--|\n| 1 | x |\n")
#' df = as_df(doc)[[1]]
#' as_table(df, caption = "demo")
#' }
#'
#' @name table_df
NULL


# ---- alignment maps -----------------------------------------------------

pd_align_to_r = function(a) {
  switch(a, Left = "left", Right = "right", Center = "center", "default")
}

r_align_to_pd = function(a) {
  switch(tolower(a),
         left = "Left", right = "Right",
         center = "Center", centre = "Center", "Default")
}


# ---- as_df --------------------------------------------------------

#' @rdname table_df
#' @export
as_df = S7::new_generic("as_df", "x")

S7::method(as_df, pandoc_table) = function(x) {
  aligns = purrr::map_chr(x@colspec, function(cs) pd_align_to_r(cs@alignment))
  header_cells = if (length(x@head@rows)) x@head@rows[[1L]]@cells else list()
  body_rows = unlist(
    purrr::map(x@bodies, function(b) c(b@head_rows, b@body_rows)),
    recursive = FALSE
  )
  if (is.null(body_rows)) body_rows = list()

  ncol = length(aligns)
  if (ncol == 0L) {
    ncol = max(c(length(header_cells),
                 purrr::map_int(body_rows, function(r) length(r@cells)), 0L))
    aligns = rep("default", ncol)
  }
  if (ncol == 0L) {
    out = data.frame()
    attr(out, "q2r_align") = character()
    attr(out, "q2r_caption") = table_caption_text(x)
    attr(out, "q2r_id") = x@attr@id
    return(out)
  }

  nms = if (length(header_cells)) purrr::map_chr(header_cells, ast_text) else character()
  if (length(nms) < ncol) nms = c(nms, paste0("V", (length(nms) + 1L):ncol))
  nms = nms[seq_len(ncol)]

  cols = purrr::map(seq_len(ncol), function(j) {
    purrr::map_chr(body_rows, function(r) {
      if (j <= length(r@cells)) ast_text(r@cells[[j]]) else ""
    })
  })
  if (length(body_rows) == 0L) cols = purrr::map(seq_len(ncol), function(j) character())

  out = as.data.frame(stats::setNames(cols, nms),
                      stringsAsFactors = FALSE, check.names = FALSE)
  attr(out, "q2r_align") = stats::setNames(aligns, nms)
  attr(out, "q2r_caption") = table_caption_text(x)
  attr(out, "q2r_id") = x@attr@id
  out
}

S7::method(as_df, pd_block_source) = function(x) {
  purrr::map(select_nodes(x, is(pandoc_table)), as_df)
}

table_caption_text = function(x) {
  cap = ast_text(x@caption)
  if (nzchar(cap)) cap else NA_character_
}


# ---- as_table -----------------------------------------------------------

#' @rdname table_df
#' @export
as_table = function(df, caption = NULL, align = NULL, id = "") {
  if (!is.data.frame(df)) df = as.data.frame(df, stringsAsFactors = FALSE)
  nms = names(df)
  ncol = ncol(df)

  if (is.null(align)) align = attr(df, "q2r_align", exact = TRUE)
  if (is.null(align)) align = rep("default", ncol)
  align = rep(as.character(align), length.out = max(ncol, 1L))
  colspec = purrr::map(seq_len(ncol), function(j) {
    pandoc_col_spec(alignment = r_align_to_pd(align[[j]]), width = NULL)
  })

  if (is.null(caption)) {
    cap = attr(df, "q2r_caption", exact = TRUE)
    if (!is.null(cap) && length(cap) == 1L && !is.na(cap)) caption = cap
  }
  if (identical(id, "")) {
    aid = attr(df, "q2r_id", exact = TRUE)
    if (!is.null(aid) && length(aid) == 1L && nzchar(aid)) id = aid
  }

  header_cells = purrr::map(nms, table_cell_from_text)
  head = pandoc_table_head(rows = list(pandoc_row(cells = header_cells)))

  body_rows = purrr::map(seq_len(nrow(df)), function(i) {
    cells = purrr::map(seq_len(ncol), function(j) {
      v = df[[j]][[i]]
      table_cell_from_text(if (length(v) != 1L || is.na(v)) "" else as.character(v))
    })
    pandoc_row(cells = cells)
  })
  bodies = list(pandoc_table_body(
    row_head_columns = 0L, head_rows = list(), body_rows = body_rows
  ))

  caption_obj = if (is.null(caption)) {
    pandoc_caption()
  } else {
    pandoc_caption(short = NULL, long = as_blocks(as.character(caption)))
  }

  pandoc_table(
    attr    = pandoc_attr(id = id),
    caption = caption_obj,
    colspec = colspec,
    head    = head,
    bodies  = bodies,
    foot    = pandoc_table_foot()
  )
}

table_cell_from_text = function(text) {
  pandoc_cell(content = pandoc_blocks(list(
    pandoc_plain(content = as_inlines(text))
  )))
}
