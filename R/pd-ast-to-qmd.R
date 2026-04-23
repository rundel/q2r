#' @include ts-ast-to-qmd.R pd-ast-pandoc.R pd-ast-block.R pd-ast-inline.R pd-ast-support.R
NULL

pandoc_attr_qmd = function(attr) {
  if (pandoc_attr_is_empty(attr)) return("")
  parts = character()
  if (nchar(attr@id) > 0L) parts = c(parts, paste0("#", attr@id))
  if (length(attr@classes) > 0L) parts = c(parts, paste0(".", attr@classes))
  if (length(attr@attributes) > 0L) {
    nm = names(attr@attributes) %||% rep("", length(attr@attributes))
    kv = paste0(nm, "=\"", attr@attributes, "\"")
    parts = c(parts, kv)
  }
  paste0("{", paste(parts, collapse = " "), "}")
}

pandoc_indent_lines = function(text, first, rest = first) {
  text = sub("\n+$", "", text)
  lines = strsplit(text, "\n", fixed = TRUE)[[1L]]
  if (length(lines) == 0L) lines = ""
  lines[1L] = paste0(first, lines[1L])
  if (length(lines) > 1L) lines[-1L] = paste0(rest, lines[-1L])
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

S7::method(to_qmd, pandoc_str)        = function(x) x@text
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
  paste0("[", to_qmd(x@content), "]", pandoc_attr_qmd(x@attr))
}

S7::method(to_qmd, pandoc_attr_inline) = function(x) pandoc_attr_qmd(x@attr)

S7::method(to_qmd, pandoc_note_reference) = function(x) paste0("[^", x@id, "]")

S7::method(to_qmd, pandoc_cite) = function(x) {
  if (length(x@citations) == 0L) return(to_qmd(x@content))
  keys = vapply(x@citations, function(c) {
    prefix = switch(c@mode,
      AuthorInText    = "@",
      SuppressAuthor  = "-@",
      "@"
    )
    paste0(prefix, c@id)
  }, character(1L))
  paste0("[", paste(keys, collapse = "; "), "]")
}

S7::method(to_qmd, pandoc_shortcode) = function(x) {
  args = if (length(x@args)) paste0(" ", paste(unlist(x@args), collapse = " ")) else ""
  paste0("{{< ", x@name, args, " >}}")
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

S7::method(to_qmd, pandoc_plain)     = function(x) paste0(to_qmd(x@content), "\n")
S7::method(to_qmd, pandoc_paragraph) = function(x) paste0(to_qmd(x@content), "\n")

S7::method(to_qmd, pandoc_header) = function(x) {
  attr = pandoc_attr_qmd(x@attr)
  if (nchar(attr) > 0L) attr = paste0(" ", attr)
  paste0(strrep("#", x@level), " ", to_qmd(x@content), attr, "\n")
}

S7::method(to_qmd, pandoc_horizontal_rule) = function(x) "---\n"

S7::method(to_qmd, pandoc_code_block) = function(x) {
  fence = pandoc_fence_for(x@text, "`", 3L)
  body = x@text
  if (nchar(body) > 0L && !endsWith(body, "\n")) body = paste0(body, "\n")
  paste0(fence, pandoc_attr_qmd(x@attr), "\n", body, fence, "\n")
}

S7::method(to_qmd, pandoc_raw_block) = function(x) {
  fence = pandoc_fence_for(x@text, "`", 3L)
  body = x@text
  if (nchar(body) > 0L && !endsWith(body, "\n")) body = paste0(body, "\n")
  paste0(fence, "{=", x@format, "}\n", body, fence, "\n")
}

S7::method(to_qmd, pandoc_block_quote) = function(x) {
  inner = to_qmd(x@content)
  lines = strsplit(sub("\n+$", "", inner), "\n", fixed = TRUE)[[1L]]
  if (length(lines) == 0L) lines = ""
  paste0(paste0("> ", lines, collapse = "\n"), "\n")
}

S7::method(to_qmd, pandoc_line_block) = function(x) {
  lines = vapply(x@content, function(inlines) paste0("| ", to_qmd(inlines)), character(1L))
  paste0(paste(lines, collapse = "\n"), "\n")
}

S7::method(to_qmd, pandoc_bullet_list) = function(x) {
  items = vapply(x@content, function(blocks) {
    pandoc_indent_lines(to_qmd(blocks), "- ", "  ")
  }, character(1L))
  paste0(paste(items, collapse = "\n"), "\n")
}

S7::method(to_qmd, pandoc_ordered_list) = function(x) {
  start = x@attr@start
  delim_tail = switch(x@attr@delim, OneParen = ")", TwoParens = ")", ".")
  items = character(length(x@content))
  for (i in seq_along(x@content)) {
    marker = paste0(start + i - 1L, delim_tail, " ")
    pad = strrep(" ", nchar(marker))
    items[i] = pandoc_indent_lines(to_qmd(x@content[[i]]), marker, pad)
  }
  paste0(paste(items, collapse = "\n"), "\n")
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

S7::method(to_qmd, pandoc_figure) = function(x) {
  warning("to_qmd(): pandoc_figure rendering is approximate - emitting as a fenced div")
  inner = to_qmd(x@content)
  if (nchar(inner) > 0L && !endsWith(inner, "\n")) inner = paste0(inner, "\n")
  attr = pandoc_attr_qmd(x@attr)
  if (nchar(attr) == 0L) attr = "{}"
  paste0("::: ", attr, "\n", inner, ":::\n")
}

S7::method(to_qmd, pandoc_table) = function(x) {
  warning("to_qmd(): no rule for pandoc_table - emitting placeholder")
  "<!-- table (not yet serialized) -->\n"
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
