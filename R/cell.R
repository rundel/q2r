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
#'   mirroring [`set_attr()`]). The option block is reserialized as a
#'   whole, so `#|` comment lines inside it are not preserved; `!expr`
#'   values keep their tag. If the existing block is not valid YAML the
#'   setter aborts rather than silently dropping the unreadable options.
#' - `set_cell_label(x, value)` convenience for `set_cell_options(x,
#'   label = value)`.
#' - `set_cell_engine(x, engine)` swaps the braced engine class (e.g.
#'   `{r}` to `{python}`), keeping any other classes and options.
#' - `set_cell_code(x, code)` replaces the cell body, keeping the option
#'   block; `code` is a single string or a character vector of lines.
#' - `collect_code(x, engine = NULL, eval_only = FALSE, label_comments =
#'   TRUE)` tangles the code of every cell under `x` into one string.
#'
#' Inside a [`select_nodes()`] / [`map_nodes()`] predicate the mask also
#' exposes `is_code_cell()` (zero-argument, tests the current node) and
#' `has_option(key)` / `has_option(key, value)`, so
#' `select_nodes(doc, is_code_cell() & has_option("eval", FALSE))` works.
#'
#' @param x For the accessors and setters, a [`pandoc_code_block`]: the
#'   accessors return empty / `NA` on a non-cell, and the setters require
#'   an executable cell (braced engine). For `collect_code()`, any node or
#'   document to gather cells from.
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
# pipe and one space, at the very start of a line (matching knitr, which
# treats indented or space-less `#|` lines as code). Covers #|
# (r/python/julia/...), //| (ojs, js, c, ...) and --| (sql, haskell, ...).
cell_directive_re = "^(#\\||//\\||--\\|) "

# Split a code-block @text into the leading run of option lines and the
# remaining code lines, returning the detected comment prefix, the raw
# (unstripped) option lines, and the cell's line ending so setters can
# rebuild without mixing endings.
cell_split_text = function(text) {
  if (length(text) != 1L) text = paste(text, collapse = "\n")
  eol = if (grepl("\r\n", text, fixed = TRUE)) "\r\n" else "\n"
  if (eol == "\r\n") text = gsub("\r\n", "\n", text, fixed = TRUE)
  lines = strsplit(text, "\n", fixed = TRUE)[[1L]]
  if (length(lines) == 0L) {
    return(list(prefix = NA_character_, opts = character(),
                opt_lines = character(), code = character(), eol = eol))
  }
  is_opt = grepl(cell_directive_re, lines)
  first_code = match(FALSE, is_opt)
  k = if (is.na(first_code)) length(lines) else first_code - 1L
  opt_lines = if (k >= 1L) lines[seq_len(k)] else character()
  code_lines = if (k < length(lines)) lines[(k + 1L):length(lines)] else character()
  prefix = if (length(opt_lines)) {
    sub("^(#\\||//\\||--\\|).*$", "\\1", opt_lines[[1L]])
  } else {
    NA_character_
  }
  list(prefix = prefix, opts = sub(cell_directive_re, "", opt_lines),
       opt_lines = opt_lines, code = code_lines, eol = eol)
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
  # A `!expr` value captured by cell_options() re-emits with its tag so the
  # expression survives a set_cell_options() round trip.
  if (inherits(v, "q2r_yaml_expr")) return(paste0("!expr ", unclass(v)))
  if (length(v) != 1L) return(NULL)
  # NA of any type serializes as YAML null (round-trips to R NULL); without this
  # a logical NA became "false" and a character NA the bare token "NA".
  if (is.atomic(v) && is.na(v)) return("null")
  if (is.logical(v)) return(if (isTRUE(v)) "true" else "false")
  # scientific = FALSE avoids forms like "2e+09" that YAML 1.1 will not parse
  # as numbers, and digits = 15 keeps full double precision where the default
  # 7-digit format() silently rounds (e.g. 1.234568e+14).
  if (is.numeric(v)) return(format(v, trim = TRUE, scientific = FALSE, digits = 15))
  if (is.character(v)) {
    # An embedded newline cannot survive as a single-line scalar (everything
    # after it would be injected into the cell as code); fall through to the
    # yaml::as.yaml block-scalar path.
    if (grepl("\n", v, fixed = TRUE)) return(NULL)
    reserved = c("yes", "no", "true", "false", "on", "off", "null", "~")
    indicators = c("-", "?", ":", ",", "[", "]", "{", "}", "#", "&",
                   "*", "!", "|", ">", "'", "\"", "%", "@", "`")
    # Numeric-looking strings (YAML 1.1 int/float grammar, incl. underscores,
    # hex/octal, and .inf/.nan) must be quoted or they re-parse as numbers.
    numberish =
      grepl("^[+-]?([0-9_]+\\.?[0-9_]*|\\.[0-9_]+)([eE][+-]?[0-9]+)?$", v) ||
      grepl("^[+-]?0[xo]?[0-9a-fA-F_]+$", v) ||
      tolower(v) %in% c(".inf", "-.inf", "+.inf", ".nan")
    needs_quote = !nzchar(v) ||
      grepl("[:#]", v) ||
      grepl("^[[:space:]]|[[:space:]]$", v) ||
      tolower(v) %in% reserved ||
      numberish ||
      substr(v, 1L, 1L) %in% indicators
    if (needs_quote) {
      # Backslashes must be escaped before quotes: inside a YAML double-quoted
      # scalar a bare backslash starts an escape sequence, and an invalid one
      # makes the whole option block unparseable.
      esc = gsub("\"", "\\\\\"", gsub("\\\\", "\\\\\\\\", v))
      return(paste0("\"", esc, "\""))
    }
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
      # Coerce integral-valued doubles to integer so the multi-line yaml path
      # emits `1` / `2` rather than the noisy `1.0` / `2.0`.
      if (is.double(v) && length(v) && all(is.finite(v)) &&
          all(v == trunc(v)) && all(abs(v) < .Machine$integer.max)) {
        v = as.integer(v)
      }
      y = yaml::as.yaml(stats::setNames(list(v), k))
      ylines = strsplit(sub("\n+$", "", y), "\n", fixed = TRUE)[[1L]]
      paste0(prefix, " ", ylines)
    }
  }), use.names = FALSE)
}


# ---- accessors ----------------------------------------------------------

cell_braced_class = function(x) {
  if (!S7::S7_inherits(x, pandoc_code_block)) return(NA_character_)
  # `{{r}}` is Quarto's verbatim-echo syntax (display, don't execute): not a
  # cell, so it must not be tangled by collect_code() or edited by the setters.
  m = x@attr@classes[grepl("^\\{[^{].*\\}$", x@attr@classes)]
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

# Parse the `#|` option block. Returns a named list, or NULL when the block
# exists but is not readable as a YAML map (callers that rebuild the block
# must abort rather than silently dropping the unreadable options). `!expr`
# values are captured verbatim with a `q2r_yaml_expr` class instead of being
# evaluated, so they round-trip through set_cell_options() with their tag
# (and the yaml package's eval.expr warning never fires).
cell_parse_options = function(x) {
  sp = cell_split_text(x@text)
  if (length(sp$opts) == 0L) return(list())
  parsed = tryCatch(
    yaml::yaml.load(
      paste(sp$opts, collapse = "\n"),
      handlers = list(expr = function(v) structure(v, class = "q2r_yaml_expr"))
    ),
    error = function(e) NULL
  )
  if (!is.list(parsed)) return(NULL)
  parsed
}

#' @rdname code_cell
#' @export
cell_options = function(x) {
  if (!is_code_cell(x)) return(list())
  cell_parse_options(x) %||% list()
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
  if (!is_code_cell(x)) {
    stop("`set_cell_options()`: `x` must be an executable cell ",
         "(a pandoc_code_block with a braced engine class such as `{r}`); ",
         "a plain fenced block has no option block to write into.",
         call. = FALSE)
  }
  pairs = rlang::list2(...)
  nms = names(pairs)
  if (length(pairs) && (is.null(nms) || !all(nzchar(nms)))) {
    stop("`set_cell_options()`: options must be supplied as named `key = value` pairs.",
         call. = FALSE)
  }
  sp = cell_split_text(x@text)
  opts = cell_parse_options(x)
  if (is.null(opts)) {
    cli::cli_abort(c(
      "The cell's existing `#|` option block is not valid YAML, so editing it would silently drop the unreadable options.",
      "i" = "Fix the option lines first (inspect them with {.code x@text})."
    ))
  }
  for (i in seq_along(pairs)) {
    if (is.null(pairs[[i]])) opts[[nms[[i]]]] = NULL else opts[[nms[[i]]]] = pairs[[i]]
  }
  prefix = if (!is.na(sp$prefix)) sp$prefix else cell_comment_prefix(cell_engine(x))
  opt_lines = cell_serialize_options(opts, prefix)
  S7::prop(x, "text") = paste(c(opt_lines, sp$code), collapse = sp$eol)
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

#' @rdname code_cell
#' @export
set_cell_engine = function(x, engine) {
  if (!is_code_cell(x)) {
    stop("`set_cell_engine()`: `x` must be an executable cell ",
         "(a pandoc_code_block with a braced engine class such as `{r}`).",
         call. = FALSE)
  }
  if (length(engine) != 1L || !is.character(engine) || is.na(engine) ||
      !nzchar(engine) || grepl("[[:space:],{}]", engine)) {
    stop("`set_cell_engine()`: `engine` must be a single engine name ",
         "such as \"r\" or \"python\".", call. = FALSE)
  }
  bc = cell_braced_class(x)
  inside = sub("\\}$", "", sub("^\\{", "", bc))
  new_inside = sub("^([[:space:]]*)[^[:space:],]+", paste0("\\1", engine), inside)
  attr = x@attr
  attr@classes[match(bc, attr@classes)] = paste0("{", new_inside, "}")
  S7::prop(x, "attr") = attr
  x
}

#' @rdname code_cell
#' @export
set_cell_code = function(x, code) {
  if (!is_code_cell(x)) {
    stop("`set_cell_code()`: `x` must be an executable cell ",
         "(a pandoc_code_block with a braced engine class such as `{r}`).",
         call. = FALSE)
  }
  if (!is.character(code) || anyNA(code)) {
    stop("`set_cell_code()`: `code` must be a character vector without NAs.",
         call. = FALSE)
  }
  if (length(code) == 1L && grepl("\n", code, fixed = TRUE)) {
    code = strsplit(code, "\n", fixed = TRUE)[[1L]]
  }
  sp = cell_split_text(x@text)
  S7::prop(x, "text") = paste(c(sp$opt_lines, code), collapse = sp$eol)
  x
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
