cst_kind_tree = function(n) {
  if (length(n@children@content) == 0L) return(n@kind)
  list(n@kind, lapply(n@children@content, cst_kind_tree))
}

expect_roundtrip = function(src, info = NULL) {
  res  = pampa_parse(src, format = "cst")
  out  = to_qmd(res@cst)
  res2 = pampa_parse(out, format = "cst")
  expect_identical(
    cst_kind_tree(res2@cst@root),
    cst_kind_tree(res@cst@root),
    info = info %||% deparse(src)
  )
}

test_that("to_qmd dispatches on ts_tree, ts_node, and pampa_result", {
  res = pampa_parse("# Hi\n", format = "cst")
  expect_identical(to_qmd(res),          "# Hi\n")
  expect_identical(to_qmd(res@cst),      "# Hi\n")
  expect_identical(to_qmd(res@cst@root), "# Hi\n")
})

test_that("to_qmd on a pampa_result falls back to the AST when CST is absent", {
  res = pampa_parse("# Hi\n", format = "ast")
  expect_identical(to_qmd(res), "# Hi {#hi}\n")
})

test_that("to_qmd on an empty pampa_result errors", {
  expect_error(to_qmd(pampa_result()), "neither a CST nor an AST")
})

test_that("to_qmd round-trips headings and paragraphs", {
  expect_roundtrip("# Hello world!\n")
  expect_roundtrip("# Heading\n\nHello *world*.\n")
  expect_roundtrip("## H2\n\n### H3\n")
  expect_roundtrip("text\n\nmore text\n")
})

test_that("to_qmd appends a trailing newline when source lacks one", {
  res = pampa_parse("# no trailing", format = "cst")
  expect_identical(to_qmd(res@cst), "# no trailing\n")
})

test_that("to_qmd canonicalizes blank-line runs and trailing whitespace", {
  res = pampa_parse("# h\n\n\n\ntext\n\n", format = "cst")
  out = to_qmd(res@cst)
  expect_identical(out, "# h\n\ntext\n")
  expect_roundtrip("# h\n\n\n\ntext\n\n")
})

test_that("to_qmd round-trips inline styling", {
  expect_roundtrip("Hello *world*.\n")
  expect_roundtrip("**bold** and _italic_.\n")
  expect_roundtrip("`code span` here.\n")
})

test_that("to_qmd round-trips links and images", {
  expect_roundtrip("[link](http://x.com)\n")
  expect_roundtrip("![img](p.png)\n")
})

test_that("to_qmd round-trips ordered and unordered lists", {
  expect_roundtrip("- one\n- two\n- three\n")
  expect_roundtrip("1. one\n2. two\n")
})

test_that("to_qmd round-trips blockquotes", {
  expect_roundtrip("> quoted\n> more\n")
})

test_that("to_qmd reconstructs grammar-gap kinds via @text", {
  expect_roundtrip("Inline $x^2$ done.\n")
  expect_roundtrip("Block $$y = 1$$ done.\n")
  expect_roundtrip("```{r}\nx <- 1\nplot(x)\n```\n")
})

test_that("to_qmd warns on unknown kinds and concatenates children", {
  fake = ts_node(
    kind = "__not_a_real_kind__",
    children = ts_nodes(list(
      ts_node(kind = "leaf", text = "a",
              children = ts_nodes(list())),
      ts_node(kind = "leaf", text = "b",
              children = ts_nodes(list()))
    ))
  )
  expect_warning(out <- to_qmd(fake), "__not_a_real_kind__")
  expect_identical(out, "ab")
})
