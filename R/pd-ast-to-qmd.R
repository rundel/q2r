#' @include ts-ast-to-qmd.R pd-ast-pandoc.R pd-ast-block.R pd-ast-inline.R pd-ast-support.R
NULL

pandoc_attr_qmd = function(attr) {
  if (pandoc_attr_is_empty(attr)) return("")
  brace_idx = if (length(attr@classes) > 0L) {
    which(startsWith(attr@classes, "{") & endsWith(attr@classes, "}"))[1L]
  } else NA_integer_
  if (!is.na(brace_idx) &&
      length(attr@classes) == 1L &&
      nchar(attr@id) == 0L &&
      length(attr@attributes) == 0L) {
    return(attr@classes)
  }
  parts = character()
  if (!is.na(brace_idx)) {
    bare = sub("^\\{(.*)\\}$", "\\1", attr@classes[brace_idx])
    parts = c(parts, bare)
  }
  if (nchar(attr@id) > 0L) parts = c(parts, paste0("#", attr@id))
  if (length(attr@classes) > 0L) {
    keep = if (is.na(brace_idx)) seq_along(attr@classes) else seq_along(attr@classes)[-brace_idx]
    if (length(keep)) parts = c(parts, paste0(".", attr@classes[keep]))
  }
  if (length(attr@attributes) > 0L) {
    nm = names(attr@attributes) %||% rep("", length(attr@attributes))
    vals = gsub("\"", "\\\"", attr@attributes, fixed = TRUE)
    kv = paste0(nm, "=\"", vals, "\"")
    parts = c(parts, kv)
  }
  paste0("{", paste(parts, collapse = " "), "}")
}

pandoc_indent_lines = function(text, first, rest = first, empty_blanks = FALSE) {
  text = sub("\n+$", "", text)
  lines = strsplit(text, "\n", fixed = TRUE)[[1L]]
  if (length(lines) == 0L) lines = ""
  lines[1L] = paste0(first, lines[1L])
  if (length(lines) > 1L) {
    if (empty_blanks) {
      nonblank = nzchar(lines[-1L])
      lines[-1L][nonblank] = paste0(rest, lines[-1L][nonblank])
    } else {
      lines[-1L] = paste0(rest, lines[-1L])
    }
  }
  paste(lines, collapse = "\n")
}

pandoc_fence_for = function(text, char = "`", min = 3L) {
  n = min
  pattern = strrep(char, n)
  while (grepl(pattern, text, fixed = TRUE)) {
    n = n + 1L
    pattern = strrep(char, n)
  }
  strrep(char, n)
}

S7::method(to_qmd, pandoc) = function(x) {
  if (!identical(x@meta@kind, "map") || length(x@meta@value) > 0L) {
    warning("to_qmd(): pandoc document metadata is not yet serialized, skipping")
  }
  out = to_qmd(x@blocks)
  if (!endsWith(out, "\n")) out = paste0(out, "\n")
  out
}

S7::method(to_qmd, pandoc_blocks) = function(x) {
  if (length(x@content) == 0L) return("")
  parts = vapply(x@content, to_qmd, character(1L))
  paste(parts, collapse = "\n")
}

S7::method(to_qmd, pandoc_inlines) = function(x) {
  if (length(x@content) == 0L) return("")
  paste0(vapply(x@content, to_qmd, character(1L)), collapse = "")
}

S7::method(to_qmd, pandoc_block) = function(x) {
  warning(
    "to_qmd(): no rule for block class '",
    pandoc_class_name(x), "' - emitting empty"
  )
  "\n"
}

S7::method(to_qmd, pandoc_inline) = function(x) {
  warning(
    "to_qmd(): no rule for inline class '",
    pandoc_class_name(x), "' - emitting empty"
  )
  ""
}

S7::method(to_qmd, pandoc_str)        = function(x) {
  text = x@text
  text = gsub("(?<!\\w)_(?!\\w)", "\\\\_", text, perl = TRUE)
  text = gsub("(?<!\\w)_(?=\\w)", "\\\\_", text, perl = TRUE)
  text = gsub("(?<=\\w)_(?!\\w)", "\\\\_", text, perl = TRUE)
  text = gsub("(?<!\\w)~(?=\\w)", "\\\\~", text, perl = TRUE)
  text = gsub("@", "\\\\@", text, perl = TRUE)
  text = gsub("`", "\\\\`", text, perl = TRUE)
  text = gsub("(\\[|\\])", "\\\\\\1", text, perl = TRUE)
  text = gsub("\\^", "\\\\^", text, perl = TRUE)
  text = gsub("<", "\\\\<", text, perl = TRUE)
  text = gsub("\\$", "\\\\$", text, perl = TRUE)
  text
}
S7::method(to_qmd, pandoc_space)      = function(x) " "
S7::method(to_qmd, pandoc_soft_break) = function(x) "\n"
S7::method(to_qmd, pandoc_line_break) = function(x) "  \n"

S7::method(to_qmd, pandoc_emph)        = function(x) paste0("*", to_qmd(x@content), "*")
S7::method(to_qmd, pandoc_strong)      = function(x) paste0("**", to_qmd(x@content), "**")
S7::method(to_qmd, pandoc_strikeout)   = function(x) paste0("~~", to_qmd(x@content), "~~")
S7::method(to_qmd, pandoc_superscript) = function(x) paste0("^", to_qmd(x@content), "^")
S7::method(to_qmd, pandoc_subscript)   = function(x) paste0("~", to_qmd(x@content), "~")

S7::method(to_qmd, pandoc_underline) = function(x) {
  paste0("[", to_qmd(x@content), "]{.underline}")
}

S7::method(to_qmd, pandoc_small_caps) = function(x) {
  paste0("[", to_qmd(x@content), "]{.smallcaps}")
}

S7::method(to_qmd, pandoc_quoted) = function(x) {
  q = if (x@quote_type == "single") "'" else "\""
  paste0(q, to_qmd(x@content), q)
}

S7::method(to_qmd, pandoc_code) = function(x) {
  fence = pandoc_fence_for(x@text, "`", 1L)
  pad = if (startsWith(x@text, "`") || endsWith(x@text, "`")) " " else ""
  paste0(fence, pad, x@text, pad, fence, pandoc_attr_qmd(x@attr))
}

S7::method(to_qmd, pandoc_math) = function(x) {
  if (identical(x@math_type, "display")) paste0("$$", x@text, "$$")
  else paste0("$", x@text, "$")
}

S7::method(to_qmd, pandoc_raw_inline) = function(x) {
  if (identical(x@format, "html") &&
      grepl("^\\s?</?[A-Za-z][^<>]*>\\s?$|^\\s?<!--.*-->\\s?$", x@text, perl = TRUE)) {
    return(x@text)
  }
  fence = pandoc_fence_for(x@text, "`", 1L)
  paste0(fence, x@text, fence, "{=", x@format, "}")
}

S7::method(to_qmd, pandoc_link) = function(x) {
  title = if (nchar(x@title) > 0L) paste0(" \"", x@title, "\"") else ""
  paste0("[", to_qmd(x@content), "](", x@url, title, ")", pandoc_attr_qmd(x@attr))
}

S7::method(to_qmd, pandoc_image) = function(x) {
  title = if (nchar(x@title) > 0L) paste0(" \"", x@title, "\"") else ""
  paste0("![", to_qmd(x@content), "](", x@url, title, ")", pandoc_attr_qmd(x@attr))
}

S7::method(to_qmd, pandoc_note) = function(x) {
  inner = to_qmd(x@content)
  inner = sub("\n+$", "", inner)
  paste0("^[", inner, "]")
}

S7::method(to_qmd, pandoc_span) = function(x) {
  if ("quarto-math-with-attribute" %in% x@attr@classes &&
      length(x@content@content) == 1L &&
      S7::S7_inherits(x@content@content[[1L]], pandoc_math) &&
      identical(x@content@content[[1L]]@math_type, "display")) {
    math = x@content@content[[1L]]
    bare_classes = setdiff(x@attr@classes, "quarto-math-with-attribute")
    bare_attr = pandoc_attr(
      id         = x@attr@id,
      classes    = bare_classes,
      attributes = x@attr@attributes
    )
    attr_str = pandoc_attr_qmd(bare_attr)
    sep = if (nchar(attr_str)) " " else ""
    return(paste0("$$", math@text, "$$", sep, attr_str))
  }
  paste0("[", to_qmd(x@content), "]", pandoc_attr_qmd(x@attr))
}

S7::method(to_qmd, pandoc_attr_inline) = function(x) pandoc_attr_qmd(x@attr)

S7::method(to_qmd, pandoc_note_reference) = function(x) paste0("[^", x@id, "]")

S7::method(to_qmd, pandoc_cite) = function(x) {
  if (length(x@citations) == 0L) return(to_qmd(x@content))

  cite_token = function(c) {
    pre = to_qmd(c@prefix)
    suf = to_qmd(c@suffix)
    marker = switch(c@mode,
      AuthorInText   = "@",
      SuppressAuthor = "-@",
      "@"
    )
    paste0(if (nchar(pre)) paste0(pre, " ") else "", marker, c@id, suf)
  }

  if (length(x@citations) == 1L) {
    c1 = x@citations[[1L]]
    pre = to_qmd(c1@prefix)
    suf = to_qmd(c1@suffix)
    if (identical(c1@mode, "AuthorInText") && !nchar(pre)) {
      if (!nchar(suf)) return(paste0("@", c1@id))
      return(paste0("@", c1@id, " [", suf, "]"))
    }
  }
  paste0("[", paste(vapply(x@citations, cite_token, character(1L)), collapse = "; "), "]")
}

pandoc_shortcode_arg_qmd = function(arg) {
  switch(arg$kind,
    string    = arg$value,
    number    = format(arg$value, scientific = FALSE),
    boolean   = if (isTRUE(arg$value)) "true" else "false",
    shortcode = to_qmd(arg$value),
    kv        = paste0(arg$key, "=", pandoc_shortcode_arg_qmd(arg$value)),
    kv_group  = paste(vapply(arg$value, pandoc_shortcode_arg_qmd, character(1L)), collapse = " "),
    stop("unknown shortcode arg kind: ", arg$kind)
  )
}

S7::method(to_qmd, pandoc_shortcode) = function(x) {
  parts = c(
    x@name,
    vapply(x@positional_args, pandoc_shortcode_arg_qmd, character(1L)),
    vapply(x@keyword_args,    pandoc_shortcode_arg_qmd, character(1L))
  )
  body = paste(parts[nzchar(parts)], collapse = " ")
  open  = if (isTRUE(x@is_escaped)) "{{{< " else "{{< "
  close = if (isTRUE(x@is_escaped)) " >}}}" else " >}}"
  paste0(open, body, close)
}

S7::method(to_qmd, pandoc_insert)       = function(x) paste0("{++", to_qmd(x@content), "++}")
S7::method(to_qmd, pandoc_delete)       = function(x) paste0("{--", to_qmd(x@content), "--}")
S7::method(to_qmd, pandoc_highlight)    = function(x) paste0("{==", to_qmd(x@content), "==}")
S7::method(to_qmd, pandoc_edit_comment) = function(x) paste0("{>>", to_qmd(x@content), "<<}")

S7::method(to_qmd, pandoc_custom_inline) = function(x) {
  warning(
    "to_qmd(): no rule for custom_inline '", x@type_name,
    "' - emitting empty"
  )
  ""
}

pandoc_escape_block_lead = function(text) {
  if (!nchar(text)) return(text)
  pat = "^(#{1,6}\\s|[-*+]\\s|>\\s?|=+\\s*$|-+\\s*$|\\d+[.)]\\s|:::|`{3,}|~{3,}|\\|\\s|\\[\\^|\\+[-=])"
  if (grepl(pat, text)) return(paste0("\\", text))
  text
}

S7::method(to_qmd, pandoc_plain)     = function(x) paste0(to_qmd(x@content), "\n")
S7::method(to_qmd, pandoc_paragraph) = function(x) {
  body = to_qmd(x@content)
  lines = strsplit(body, "\n", fixed = TRUE)[[1L]]
  if (length(lines)) {
    escaped_first = pandoc_escape_block_lead(lines[[1L]])
    if (!identical(escaped_first, lines[[1L]])) {
      lines = vapply(lines, pandoc_escape_block_lead, character(1L), USE.NAMES = FALSE)
    } else {
      lines[[1L]] = escaped_first
    }
  }
  paste0(paste(lines, collapse = "\n"), "\n")
}

S7::method(to_qmd, pandoc_header) = function(x) {
  attr = pandoc_attr_qmd(x@attr)
  if (nchar(attr) > 0L) attr = paste0(" ", attr)
  paste0(strrep("#", x@level), " ", to_qmd(x@content), attr, "\n")
}

S7::method(to_qmd, pandoc_horizontal_rule) = function(x) "---\n"

S7::method(to_qmd, pandoc_code_block) = function(x) {
  fence = pandoc_fence_for(x@text, "`", 3L)
  body = paste0(x@text, "\n")
  paste0(fence, pandoc_attr_qmd(x@attr), "\n", body, fence, "\n")
}

S7::method(to_qmd, pandoc_raw_block) = function(x) {
  fence = pandoc_fence_for(x@text, "`", 3L)
  body = paste0(x@text, "\n")
  paste0(fence, "{=", x@format, "}\n", body, fence, "\n")
}

S7::method(to_qmd, pandoc_block_quote) = function(x) {
  inner = to_qmd(x@content)
  lines = strsplit(sub("\n+$", "", inner), "\n", fixed = TRUE)[[1L]]
  if (length(lines) == 0L) lines = ""
  out = paste0("> ", lines)
  in_math = FALSE
  for (i in seq_along(out)) {
    has_fence = grepl("\\$\\$", out[[i]])
    if (in_math && startsWith(out[[i]], "> > ")) {
      out[[i]] = sub("^> ", "", out[[i]])
    }
    if (has_fence) in_math = !in_math
  }
  paste0(paste(out, collapse = "\n"), "\n")
}

S7::method(to_qmd, pandoc_line_block) = function(x) {
  lines = vapply(x@content, function(inlines) paste0("| ", to_qmd(inlines)), character(1L))
  paste0(paste(lines, collapse = "\n"), "\n")
}

pandoc_list_is_loose = function(items) {
  any(vapply(items, function(blocks) {
    any(vapply(blocks@content, function(b) S7::S7_inherits(b, pandoc_paragraph), logical(1L)))
  }, logical(1L)))
}

S7::method(to_qmd, pandoc_bullet_list) = function(x) {
  loose = pandoc_list_is_loose(x@content)
  sep = if (loose) "\n\n" else "\n"
  items = vapply(x@content, function(blocks) {
    pandoc_indent_lines(to_qmd(blocks), "- ", "  ", empty_blanks = loose)
  }, character(1L))
  paste0(paste(items, collapse = sep), "\n")
}

pandoc_ordered_list_label = function(n, style) {
  to_roman_lower = function(n) tolower(as.character(utils::as.roman(n)))
  to_roman_upper = function(n) as.character(utils::as.roman(n))
  to_alpha = function(n, upper) {
    chars = if (upper) LETTERS else letters
    out = character()
    repeat {
      out = c(chars[((n - 1L) %% 26L) + 1L], out)
      n = (n - 1L) %/% 26L
      if (n == 0L) break
    }
    paste(out, collapse = "")
  }
  switch(style,
    Example     = "@",
    LowerRoman  = to_roman_lower(n),
    UpperRoman  = to_roman_upper(n),
    LowerAlpha  = to_alpha(n, upper = FALSE),
    UpperAlpha  = to_alpha(n, upper = TRUE),
    as.character(n)
  )
}

S7::method(to_qmd, pandoc_ordered_list) = function(x) {
  start = x@attr@start
  style = x@attr@style
  delim = x@attr@delim
  loose = pandoc_list_is_loose(x@content)
  sep = if (loose) "\n\n" else "\n"
  items = character(length(x@content))
  for (i in seq_along(x@content)) {
    label = pandoc_ordered_list_label(start + i - 1L, style)
    marker = switch(delim,
      OneParen  = paste0(label, ") "),
      TwoParens = paste0("(", label, ") "),
      paste0(label, ". ")
    )
    pad = strrep(" ", nchar(marker))
    items[i] = pandoc_indent_lines(to_qmd(x@content[[i]]), marker, pad, empty_blanks = loose)
  }
  paste0(paste(items, collapse = sep), "\n")
}

S7::method(to_qmd, pandoc_definition_list) = function(x) {
  items = vapply(x@content, function(item) {
    term = to_qmd(item@term)
    defs = vapply(item@defs, function(blocks) {
      pandoc_indent_lines(to_qmd(blocks), ":   ", "    ")
    }, character(1L))
    paste0(term, "\n\n", paste(defs, collapse = "\n\n"))
  }, character(1L))
  paste0(paste(items, collapse = "\n\n"), "\n")
}

S7::method(to_qmd, pandoc_div) = function(x) {
  inner = to_qmd(x@content)
  if (nchar(inner) > 0L && !endsWith(inner, "\n")) inner = paste0(inner, "\n")
  attr = pandoc_attr_qmd(x@attr)
  if (nchar(attr) == 0L) attr = "{}"
  paste0("::: ", attr, "\n", inner, ":::\n")
}

S7::method(to_qmd, pandoc_note_definition_para) = function(x) {
  paste0("[^", x@id, "]: ", to_qmd(x@content), "\n")
}

S7::method(to_qmd, pandoc_note_definition_fenced_block) = function(x) {
  inner = to_qmd(x@content)
  paste0(pandoc_indent_lines(inner, paste0("[^", x@id, "]: "), "    "), "\n")
}

pandoc_figure_single_image = function(x) {
  if (length(x@content@content) != 1L) return(NULL)
  block = x@content@content[[1L]]
  if (!S7::S7_inherits(block, pandoc_plain)) return(NULL)
  inlines = block@content@content
  if (length(inlines) != 1L) return(NULL)
  img = inlines[[1L]]
  if (!S7::S7_inherits(img, pandoc_image)) return(NULL)
  img
}

S7::method(to_qmd, pandoc_figure) = function(x) {
  img = pandoc_figure_single_image(x)
  if (!is.null(img)) {
    fig_id = x@attr@id
    img_id = img@attr@id
    if (!nchar(img_id) || identical(fig_id, img_id) || !nchar(fig_id)) {
      merged = pandoc_attr(
        id         = if (nchar(img_id)) img_id else fig_id,
        classes    = unique(c(x@attr@classes, img@attr@classes)),
        attributes = c(x@attr@attributes, img@attr@attributes)
      )
      merged_img = pandoc_image(
        attr    = merged,
        content = img@content,
        url     = img@url,
        title   = img@title
      )
      return(paste0(to_qmd(merged_img), "\n"))
    }
  }
  warning("to_qmd(): pandoc_figure rendering is approximate - emitting as a fenced div")
  inner = to_qmd(x@content)
  if (nchar(inner) > 0L && !endsWith(inner, "\n")) inner = paste0(inner, "\n")
  attr = pandoc_attr_qmd(x@attr)
  if (nchar(attr) == 0L) attr = "{}"
  paste0("::: ", attr, "\n", inner, ":::\n")
}

pandoc_table_cell_is_pipe_eligible = function(cell) {
  if (cell@row_span != 1L || cell@col_span != 1L) return(FALSE)
  blocks = cell@content@content
  if (length(blocks) > 1L) return(FALSE)
  if (length(blocks) == 0L) return(TRUE)
  b = blocks[[1L]]
  if (!S7::S7_inherits(b, pandoc_plain) && !S7::S7_inherits(b, pandoc_paragraph)) return(FALSE)
  for (i in b@content@content) {
    if (S7::S7_inherits(i, pandoc_soft_break) || S7::S7_inherits(i, pandoc_line_break)) {
      return(FALSE)
    }
  }
  TRUE
}

pandoc_table_is_pipe_eligible = function(x) {
  if (length(x@bodies) != 1L) return(FALSE)
  body = x@bodies[[1L]]
  if (length(body@head_rows) > 0L) return(FALSE)
  if (body@row_head_columns > 0L) return(FALSE)
  if (length(x@head@rows) > 1L) return(FALSE)
  if (length(x@foot@rows) > 0L) return(FALSE)
  rows = c(x@head@rows, body@body_rows)
  for (r in rows) for (c in r@cells) {
    if (!pandoc_table_cell_is_pipe_eligible(c)) return(FALSE)
  }
  TRUE
}

pandoc_table_cell_text = function(cell) {
  blocks = cell@content@content
  if (length(blocks) == 0L) return("")
  body = to_qmd(blocks[[1L]]@content)
  body = gsub("|", "\\|", body, fixed = TRUE)
  body = gsub("\n", " ", body, fixed = TRUE)
  body
}

pandoc_table_alignment_sep = function(alignment) {
  switch(alignment,
    Left    = ":---",
    Right   = "---:",
    Center  = ":---:",
    Default = "----",
    "----"
  )
}

pandoc_table_caption_line = function(x) {
  cap_blocks = x@caption@long@content
  cap_text = ""
  if (length(cap_blocks) > 0L) {
    b = cap_blocks[[1L]]
    if (S7::S7_inherits(b, pandoc_plain) || S7::S7_inherits(b, pandoc_paragraph)) {
      cap_text = to_qmd(b@content)
      cap_text = sub("\n+$", "", cap_text)
    }
  }
  attr = pandoc_attr_qmd(x@attr)
  if (!nchar(cap_text) && !nchar(attr)) return("")
  pieces = c(": ", cap_text)
  if (nchar(attr)) pieces = c(pieces, if (nchar(cap_text)) " " else "", attr)
  paste0(paste0(pieces, collapse = ""), "\n")
}

pandoc_table_pipe = function(x) {
  ncols = if (length(x@colspec) > 0L) length(x@colspec)
          else if (length(x@head@rows) > 0L) length(x@head@rows[[1L]]@cells)
          else if (length(x@bodies[[1L]]@body_rows) > 0L) length(x@bodies[[1L]]@body_rows[[1L]]@cells)
          else 0L

  if (ncols == 0L) return("\n")

  alignments = if (length(x@colspec) == ncols) {
    vapply(x@colspec, function(cs) cs@alignment, character(1L))
  } else rep("Default", ncols)

  render_row = function(cells) {
    texts = vapply(cells, pandoc_table_cell_text, character(1L))
    if (length(texts) < ncols) texts = c(texts, rep("", ncols - length(texts)))
    paste0("| ", paste(texts, collapse = " | "), " |")
  }

  head_line = if (length(x@head@rows) == 1L) {
    render_row(x@head@rows[[1L]]@cells)
  } else {
    paste0("| ", paste(rep("", ncols), collapse = " | "), " |")
  }

  sep_line = paste0("|", paste(vapply(alignments, pandoc_table_alignment_sep, character(1L)),
                                collapse = "|"), "|")

  body_rows = x@bodies[[1L]]@body_rows
  body_lines = vapply(body_rows, function(r) render_row(r@cells), character(1L))

  caption = pandoc_table_caption_line(x)
  table_block = paste(c(head_line, sep_line, body_lines), collapse = "\n")
  if (nchar(caption)) {
    paste0(table_block, "\n\n", caption)
  } else {
    paste0(table_block, "\n")
  }
}

pandoc_table_list = function(x) {
  rows = c(x@head@rows, if (length(x@bodies) > 0L) x@bodies[[1L]]@body_rows else list())
  if (length(rows) == 0L) return("\n")

  attr_for_emit = pandoc_attr(
    id         = x@attr@id,
    classes    = unique(c(x@attr@classes, "list-table")),
    attributes = x@attr@attributes
  )
  attr_str = pandoc_attr_qmd(attr_for_emit)

  row_strs = vapply(rows, function(r) {
    cell_strs = vapply(seq_along(r@cells), function(j) {
      cell_text = sub("\n+$", "", to_qmd(r@cells[[j]]@content))
      first_marker = if (j == 1L) "- - " else "  - "
      pandoc_indent_lines(cell_text, first_marker, "    ", empty_blanks = TRUE)
    }, character(1L))
    paste(cell_strs, collapse = "\n")
  }, character(1L))

  body = paste(row_strs, collapse = "\n\n")
  paste0("::: ", attr_str, "\n", body, "\n:::\n")
}

S7::method(to_qmd, pandoc_table) = function(x) {
  if (pandoc_table_is_pipe_eligible(x)) pandoc_table_pipe(x) else pandoc_table_list(x)
}

S7::method(to_qmd, pandoc_block_metadata) = function(x) {
  warning("to_qmd(): no rule for pandoc_block_metadata - skipping")
  ""
}

S7::method(to_qmd, pandoc_caption_block) = function(x) {
  warning("to_qmd(): no rule for pandoc_caption_block - emitting content only")
  paste0(to_qmd(x@content), "\n")
}

S7::method(to_qmd, pandoc_custom_block) = function(x) {
  warning(
    "to_qmd(): no rule for custom_block '", x@type_name,
    "' - emitting empty"
  )
  ""
}
