# An html_element scan is bounded as of q2 10e16e0c (e6dcd101e,
# bd-html-element-runaway-k1eo50h8): a `<` only starts a tag candidate when
# followed by a letter, `/`, `?` or `#`, and a candidate still open at a blank
# line is abandoned, since an inline token cannot span a paragraph boundary.
# A `<` that fails either test is a literal str, so `<6.1`, `<-`, `<=b` and
# `<5>` parse as text with no diagnostic (`<5>` used to be a RawInline plus a
# Q-2-9 warning), and `x <foo` followed by a blank line and `bar> y` is two
# paragraphs, where Pandoc gives a RawInline. The pampa qmd writer escapes the
# literal `<` and `>`.

shape = function(inl) {
  purrr::map_chr(inl, function(x) {
    if (S7::S7_inherits(x, pandoc_str)) x@text
    else if (S7::S7_inherits(x, pandoc_space)) "<sp>"
    else if (S7::S7_inherits(x, pandoc_raw_inline)) paste0("raw:", x@text)
    else if (S7::S7_inherits(x, pandoc_link)) paste0("link:", x@url)
    else sub("q2r::", "", class(x)[1])
  })
}

para_shape = function(pd, i = 1L) shape(pd@blocks[[i]]@content@content)

literal = list(
  "supports <6.1 and x > y\n" = c("supports", "<sp>", "<6.1", "<sp>", "and", "<sp>", "x", "<sp>", ">", "<sp>", "y"),
  "x <- 5 and y -> 6\n"       = c("x", "<sp>", "<-", "<sp>", "5", "<sp>", "and", "<sp>", "y", "<sp>", "->", "<sp>", "6"),
  "a <=b and c >= d\n"        = c("a", "<sp>", "<=b", "<sp>", "and", "<sp>", "c", "<sp>", ">=", "<sp>", "d"),
  "a <5> b\n"                 = c("a", "<sp>", "<5>", "<sp>", "b")
)

test_that("a < that cannot start a tag parses as str with no diagnostic", {
  for (src in names(literal)) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_length(pd@diagnostics, 0L)
    expect_identical(para_shape(pd), literal[[src]], info = src)
  }
})

test_that("a tag candidate does not cross a blank line", {
  pd = parse_qmd("x <foo\n\nbar> y\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_length(pd@blocks@content, 2L)
  expect_identical(para_shape(pd, 1L), c("x", "<sp>", "<foo"))
  expect_identical(para_shape(pd, 2L), c("bar>", "<sp>", "y"))
})

test_that("a literal < is escaped by the writer and round-trips", {
  expect_identical(to_qmd(parse_qmd("a <5> b\n", quiet = TRUE)), "a \\<5\\> b\n")
  for (src in c(names(literal), "x <foo\n\nbar> y\n")) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
  }
})

test_that("a literal < byte-recovers on the tree-sitter path", {
  for (src in c(names(literal), "x <foo\n\nbar> y\n")) {
    ts = parse_qmd(src, ast = "ts", quiet = TRUE)
    expect_length(ts@diagnostics, 0L)
    expect_length(as.list(select_nodes(ts, kind == "ERROR")), 0L)
    expect_length(as.list(select_nodes(ts, kind == "html_element")), 0L)
    expect_identical(to_qmd(ts), src, info = src)
    expect_ts_ast_equal(parse_qmd(to_qmd(ts), ast = "ts", quiet = TRUE), ts)
  }
})

test_that("real tags, anchors and autolinks are unchanged", {
  pd = parse_qmd("a </b> c\n", quiet = TRUE)
  expect_identical(para_shape(pd), c("a", "<sp>", "raw:</b>", "<sp>", "c"))

  pd = parse_qmd("a <span\n class=\"x\"> b\n", quiet = TRUE)
  expect_identical(para_shape(pd), c("a", "<sp>", "raw:<span\n class=\"x\">", "<sp>", "b"))

  pd = parse_qmd("see <#sec-intro> here\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(para_shape(pd), c("see", "<sp>", "link:#sec-intro", "<sp>", "here"))
})
