ast_struct = function(x) {
  if (is.null(x)) return(NULL)
  if (is.list(x) && !S7::S7_inherits(x, pandoc_node) &&
      !S7::S7_inherits(x, pandoc_blocks) &&
      !S7::S7_inherits(x, pandoc_inlines)) {
    return(lapply(x, ast_struct))
  }
  if (S7::S7_inherits(x, pandoc)) {
    return(list("pandoc", lapply(x@blocks@content, ast_struct)))
  }
  if (S7::S7_inherits(x, pandoc_blocks) || S7::S7_inherits(x, pandoc_inlines)) {
    return(lapply(x@content, ast_struct))
  }
  name = pandoc_class_name(x)
  kids = pandoc_children(x)
  if (length(kids) == 0L) return(name)
  list(name, lapply(kids, ast_struct))
}

expect_ast_roundtrip = function(src, info = NULL) {
  res  = pampa_parse(src, format = "pd_ast")
  out  = to_qmd(res@pd_ast)
  res2 = pampa_parse(out, format = "pd_ast")
  expect_identical(
    ast_struct(res2@pd_ast),
    ast_struct(res@pd_ast),
    info = info %||% deparse(src)
  )
}

test_that("to_qmd dispatches on pandoc and pandoc_blocks/inlines", {
  res = pampa_parse("Hello *world*.\n", format = "pd_ast")
  out = to_qmd(res@pd_ast)
  expect_type(out, "character")
  expect_true(endsWith(out, "\n"))

  expect_identical(to_qmd(pandoc_inlines(list(pandoc_str(text = "hi")))), "hi")
  expect_identical(to_qmd(pandoc_blocks(list())), "")
  expect_identical(to_qmd(pandoc_inlines(list())), "")
})

test_that("to_qmd on an empty pampa_result errors", {
  expect_error(to_qmd(pampa_result()), "neither a ts_ast nor a pd_ast")
})

test_that("to_qmd round-trips paragraphs and inline styling via the AST", {
  expect_ast_roundtrip("Hello *world*.\n")
  expect_ast_roundtrip("**bold** and *italic*.\n")
  expect_ast_roundtrip("some `code span` here.\n")
  expect_ast_roundtrip("plain text with no markup\n")
})

test_that("to_qmd emits atx headers with attrs", {
  expect_identical(
    to_qmd(pandoc_header(level = 2L, content = pandoc_inlines(list(pandoc_str(text = "Hi"))))),
    "## Hi\n"
  )
  expect_identical(
    to_qmd(pandoc_header(
      level = 1L,
      attr = pandoc_attr(id = "sec-intro", classes = "unnumbered"),
      content = pandoc_inlines(list(pandoc_str(text = "Intro")))
    )),
    "# Intro {#sec-intro .unnumbered}\n"
  )
})

test_that("to_qmd emits code blocks and raw blocks", {
  cb = pandoc_code_block(
    attr = pandoc_attr(classes = "r"),
    text = "x <- 1\nplot(x)"
  )
  expect_identical(to_qmd(cb), "```{.r}\nx <- 1\nplot(x)\n```\n")

  rb = pandoc_raw_block(format = "html", text = "<div>hi</div>")
  expect_identical(to_qmd(rb), "```{=html}\n<div>hi</div>\n```\n")
})

test_that("to_qmd emits links and images", {
  lk = pandoc_link(
    content = pandoc_inlines(list(pandoc_str(text = "go"))),
    url = "http://x.com"
  )
  expect_identical(to_qmd(lk), "[go](http://x.com)")

  im = pandoc_image(
    content = pandoc_inlines(list(pandoc_str(text = "alt"))),
    url = "p.png",
    title = "t"
  )
  expect_identical(to_qmd(im), "![alt](p.png \"t\")")
})

test_that("to_qmd emits block quotes, lists, and horizontal rules", {
  bq = pandoc_block_quote(content = pandoc_blocks(list(
    pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "hi"))))
  )))
  expect_identical(to_qmd(bq), "> hi\n")

  bl = pandoc_bullet_list(content = list(
    pandoc_blocks(list(pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "a")))))),
    pandoc_blocks(list(pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "b"))))))
  ))
  expect_identical(to_qmd(bl), "- a\n- b\n")

  ol = pandoc_ordered_list(
    attr = pandoc_list_attributes(start = 1L, style = "Decimal", delim = "Period"),
    content = list(
      pandoc_blocks(list(pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "one")))))),
      pandoc_blocks(list(pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "two"))))))
    )
  )
  expect_identical(to_qmd(ol), "1. one\n2. two\n")

  expect_identical(to_qmd(pandoc_horizontal_rule()), "---\n")
})

test_that("to_qmd emits math inline and display", {
  mi = pandoc_math(math_type = "inline", text = "x^2")
  md = pandoc_math(math_type = "display", text = "y = 1")
  expect_identical(to_qmd(mi), "$x^2$")
  expect_identical(to_qmd(md), "$$y = 1$$")
})

test_that("to_qmd emits divs and spans with attrs", {
  sp = pandoc_span(
    attr = pandoc_attr(classes = "underline"),
    content = pandoc_inlines(list(pandoc_str(text = "hi")))
  )
  expect_identical(to_qmd(sp), "[hi]{.underline}")

  dv = pandoc_div(
    attr = pandoc_attr(classes = "callout-note"),
    content = pandoc_blocks(list(
      pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "note"))))
    ))
  )
  expect_identical(to_qmd(dv), "::: {.callout-note}\nnote\n:::\n")
})

test_that("to_qmd emits footnote definitions and references", {
  nr = pandoc_note_reference(id = "1")
  expect_identical(to_qmd(nr), "[^1]")

  nd = pandoc_note_definition_para(
    id = "1",
    content = pandoc_inlines(list(pandoc_str(text = "footnote")))
  )
  expect_identical(to_qmd(nd), "[^1]: footnote\n")
})

test_that("to_qmd warns on pandoc_table placeholder", {
  expect_warning(out <- to_qmd(pandoc_table()), "pandoc_table")
  expect_true(grepl("table", out))
})

test_that("to_qmd warns on custom_block / custom_inline", {
  expect_warning(to_qmd(pandoc_custom_block(type_name = "foo")), "custom_block")
  expect_warning(to_qmd(pandoc_custom_inline(type_name = "bar")), "custom_inline")
})

test_that("to_qmd AST round-trips a mixed-feature document", {
  src = "# Title

A paragraph with *emph*, **strong**, and `code`.

- item one
- item two

1. first
2. second

> a quote

[link](http://x)

```{.r}
x <- 1
```

Inline math $x^2$ and display $$y = 1$$.
"
  res  = pampa_parse(src, format = "pd_ast")
  out  = to_qmd(res@pd_ast)
  res2 = pampa_parse(out, format = "pd_ast")
  expect_identical(ast_struct(res2@pd_ast), ast_struct(res@pd_ast))
})
