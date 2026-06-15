#' @include pd-ast-pandoc.R pd-ast-block.R ast-text.R select.R
NULL

#' Quarto code-cell helpers
#'
#' `r lifecycle::badge("experimental")`
#'
#' A Quarto executable cell parses to a [`pandoc_code_block`] whose engine
#' is carried as a braced class (`{r}`, `{python}`, `{ojs}`, ...) and whose
#' cell options live in leading `#|` (or `//|` / `--|`) comment lines
#' inside `@text`. None of that is surfaced by the raw node, so these
#' helpers read and edit it: they are the q2r analog of mq's `.code(lang)`
#' selector and of parsermd's `rmd_node_engine()` / `rmd_node_label()` /
#' `rmd_node_options()` family.
#'
#' A plain fenced code block (` ```r `, class `r` with no braces) is *not*
#' a cell: `is_code_cell()` is `FALSE`, `cell_engine()` is `NA`, and
#' `cell_options()` is empty.
#'
#' @section Helpers:
#' - `is_code_cell(x)` `TRUE` when `x` is an executable cell (a
#'   [`pandoc_code_block`] with a braced engine class).
#' - `cell_engine(x)` the engine name (`"r"`, `"python"`, ...) or `NA`.
#' - `cell_label(x)` the `label` option, falling back to `@attr@id`, or
#'   `NA`.
#' - `cell_code(x)` the cell body with the leading option lines stripped.
#' - `cell_options(x)` the `#|` options parsed from YAML into a named
#'   list.
#' - `set_cell_options(x, ...)` returns a new cell with options set from
#'   named `key = value` pairs (a `NULL` value removes that option,
#'   mirroring [`set_attr()`]).
#' - `set_cell_label(x, value)` convenience for `set_cell_options(x,
#'   label = value)`.
#' - `collect_code(x, ...)` tangles the code of every cell under `x` into
#'   one string.
#'
#' Inside a [`select_nodes()`] / [`map_nodes()`] predicate the mask also
#' exposes `is_code_cell()` (zero-argument, tests the current node) and
#' `has_option(key)` / `has_option(key, value)`, so
#' `select_nodes(doc, is_code_cell() & has_option("eval", FALSE))` works.
#'
#' @param x A [`pandoc_code_block`] (for the accessors / setters) or any
#'   node or document (for `collect_code()`).
#' @param value For `set_cell_label()`, the new label string.
#' @param engine For `collect_code()`, keep only cells with this engine.
#' @param eval_only For `collect_code()`, drop cells whose `eval` option
#'   is `FALSE`.
#' @param label_comments For `collect_code()`, prefix each cell's code
#'   with a `# <label>` comment when it has a label.
#' @param ... For `set_cell_options()`, named `key = value` option pairs.
#' @return Accessors return a scalar (or named list, for
#'   `cell_options()`); setters return a new [`pandoc_code_block`];
#'   `collect_code()` returns a single string.
#'
#' @examples
#' \dontrun{
#' doc = parse_qmd("```{r}\n#| label: fig-1\n#| echo: false\nplot(1)\n```\n")
#' cell = select_first(doc, is(pandoc_code_block))
#' cell_engine(cell)
#' cell_options(cell)
#' set_cell_options(cell, echo = TRUE, eval = NULL)
#' }
#'
#' @name code_cell
NULL


# ---- option-line parsing ------------------------------------------------

# A Quarto cell-option directive: the engine comment chars followed by a
# pipe, at the start of a line. Covers #| (r/python/julia/...), //| (ojs,
# js, c, ...) and --| (sql, haskell, ...).
cell_directive_re = "^[[:space:]]*(#\\||//\\||--\\|)[[:space:]]?"

# Split a code-block @text into the leading run of option lines and the
# remaining code lines, returning the detected comment prefix too.
cell_split_text = function(text) {
  if (length(text) != 1L) text = paste(text, collapse = "\n")
  lines = strsplit(text, "\n", fixed = TRUE)[[1L]]
  if (length(lines) == 0L) {
    return(list(prefix = NA_character_, opts = character(), code = character()))
  }
  is_opt = grepl(cell_directive_re, lines)
  first_code = match(FALSE, is_opt)
  k = if (is.na(first_code)) length(lines) else first_code - 1L
  opt_lines = if (k >= 1L) lines[seq_len(k)] else character()
  code_lines = if (k < length(lines)) lines[(k + 1L):length(lines)] else character()
  prefix = if (length(opt_lines)) {
    sub("^[[:space:]]*(#\\||//\\||--\\|).*$", "\\1", opt_lines[[1L]])
  } else {
    NA_character_
  }
  list(prefix = prefix, opts = sub(cell_directive_re, "", opt_lines), code = code_lines)
}

# Map an engine to its option-comment prefix when a cell has no existing
# option line to copy the prefix from.
cell_comment_prefix = function(engine) {
  if (length(engine) != 1L || is.na(engine)) return("#|")
  e = tolower(engine)
  dbl = c("ojs", "js", "javascript", "ts", "typescript", "d3", "c", "cpp",
          "rust", "go", "java", "scala", "kotlin", "groovy", "dot", "mermaid")
  dash = c("sql", "haskell", "lua", "ada", "elm")
  if (e %in% dbl) "//|" else if (e %in% dash) "--|" else "#|"
}

cell_yaml_scalar = function(v) {
  if (length(v) != 1L) return(NULL)
  if (is.logical(v)) return(if (isTRUE(v)) "true" else "false")
  # scientific = FALSE avoids forms like "2e+09" that YAML 1.1 will not parse
  # as numbers, and digits = 15 keeps full double precision where the default
  # 7-digit format() silently rounds (e.g. 1.234568e+14).
  if (is.numeric(v)) return(format(v, trim = TRUE, scientific = FALSE, digits = 15))
  if (is.character(v)) {
    reserved = c("yes", "no", "true", "false", "on", "off", "null", "~")
    indicators = c("-", "?", ":", ",", "[", "]", "{", "}", "#", "&",
                   "*", "!", "|", ">", "'", "\"", "%", "@", "`")
    needs_quote = !nzchar(v) ||
      grepl("[:#]", v) ||
      grepl("^[[:space:]]|[[:space:]]$", v) ||
      tolower(v) %in% reserved ||
      substr(v, 1L, 1L) %in% indicators
    if (needs_quote) return(paste0("\"", gsub("\"", "\\\\\"", v), "\""))
    return(v)
  }
  NULL
}

cell_serialize_options = function(opts, prefix) {
  if (length(opts) == 0L) return(character())
  unlist(purrr::imap(opts, function(v, k) {
    sc = cell_yaml_scalar(v)
    if (!is.null(sc)) {
      paste0(prefix, " ", k, ": ", sc)
    } else {
      y = yaml::as.yaml(stats::setNames(list(v), k))
      ylines = strsplit(sub("\n+$", "", y), "\n", fixed = TRUE)[[1L]]
      paste0(prefix, " ", ylines)
    }
  }), use.names = FALSE)
}


# ---- accessors ----------------------------------------------------------

cell_braced_class = function(x) {
  if (!S7::S7_inherits(x, pandoc_code_block)) return(NA_character_)
  m = x@attr@classes[grepl("^\\{.*\\}$", x@attr@classes)]
  if (length(m)) m[[1L]] else NA_character_
}

#' @rdname code_cell
#' @export
is_code_cell = function(x) {
  !is.na(cell_braced_class(x))
}

#' @rdname code_cell
#' @export
cell_engine = function(x) {
  bc = cell_braced_class(x)
  if (is.na(bc)) return(NA_character_)
  inside = trimws(sub("\\}$", "", sub("^\\{", "", bc)))
  strsplit(inside, "[[:space:],]+")[[1L]][[1L]]
}

#' @rdname code_cell
#' @export
cell_options = function(x) {
  if (!is_code_cell(x)) return(list())
  sp = cell_split_text(x@text)
  if (length(sp$opts) == 0L) return(list())
  parsed = tryCatch(yaml::yaml.load(paste(sp$opts, collapse = "\n")),
                    error = function(e) NULL)
  if (!is.list(parsed)) return(list())
  parsed
}

#' @rdname code_cell
#' @export
cell_code = function(x) {
  if (!S7::S7_inherits(x, pandoc_code_block)) {
    stop("`cell_code()`: `x` must be a pandoc_code_block.", call. = FALSE)
  }
  if (!is_code_cell(x)) return(x@text)
  paste(cell_split_text(x@text)$code, collapse = "\n")
}

#' @rdname code_cell
#' @export
cell_label = function(x) {
  lab = cell_options(x)$label
  if (!is.null(lab) && length(lab) == 1L && nzchar(as.character(lab))) {
    return(as.character(lab))
  }
  id = if (S7::S7_inherits(x, pandoc_code_block)) x@attr@id else ""
  if (nzchar(id)) id else NA_character_
}


# ---- setters ------------------------------------------------------------

#' @rdname code_cell
#' @export
set_cell_options = function(x, ...) {
  if (!S7::S7_inherits(x, pandoc_code_block)) {
    stop("`set_cell_options()`: `x` must be a pandoc_code_block.", call. = FALSE)
  }
  pairs = rlang::list2(...)
  nms = names(pairs)
  if (length(pairs) && (is.null(nms) || !all(nzchar(nms)))) {
    stop("`set_cell_options()`: options must be supplied as named `key = value` pairs.",
         call. = FALSE)
  }
  sp = cell_split_text(x@text)
  opts = cell_options(x)
  for (i in seq_along(pairs)) {
    if (is.null(pairs[[i]])) opts[[nms[[i]]]] = NULL else opts[[nms[[i]]]] = pairs[[i]]
  }
  prefix = if (!is.na(sp$prefix)) sp$prefix else cell_comment_prefix(cell_engine(x))
  opt_lines = cell_serialize_options(opts, prefix)
  S7::prop(x, "text") = paste(c(opt_lines, sp$code), collapse = "\n")
  x
}

#' @rdname code_cell
#' @export
set_cell_label = function(x, value) {
  if (length(value) != 1L || !is.character(value)) {
    stop("`set_cell_label()`: `value` must be a single string.", call. = FALSE)
  }
  set_cell_options(x, label = value)
}


# ---- collect_code -------------------------------------------------------

#' @rdname code_cell
#' @export
collect_code = function(x, engine = NULL, eval_only = FALSE, label_comments = TRUE) {
  cells = purrr::keep(select_nodes(x, is(pandoc_code_block)), is_code_cell)
  if (!is.null(engine)) {
    cells = purrr::keep(cells, function(c) isTRUE(cell_engine(c) == engine))
  }
  if (eval_only) {
    cells = purrr::keep(cells, function(c) {
      ev = cell_options(c)$eval
      is.null(ev) || isTRUE(ev)
    })
  }
  chunks = purrr::map_chr(cells, function(c) {
    code = cell_code(c)
    if (label_comments) {
      lab = cell_label(c)
      if (!is.na(lab)) {
        cc = sub("\\|$", "", cell_comment_prefix(cell_engine(c)))
        code = paste0(cc, " ", lab, "\n", code)
      }
    }
    code
  })
  paste(chunks, collapse = "\n\n")
}
