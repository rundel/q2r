# A backtick run inside a code span is emitted whole as of q2 10e16e0c
# (916d1b345, bd-nycn85a8): the external scanner hands any in-span run whose
# length differs from the opening delimiter to the grammar as one token, so
# CommonMark's exact-length closer rule holds and `` `x``y` `` is one code
# span with text "x``y" rather than a span closed early at the double run.
# The pampa qmd writer picks a fence longer than any run in the text, so the
# written form differs from the source but re-reads to the same AST.

cases = c(
  "a `x``y` b\n"             = "x``y",
  "a ` ```mermaid ` b\n"     = "```mermaid",
  "a ` ````markdown ` b\n"   = "````markdown",
  "a `` ```{r} `` b\n"       = "```{r}",
  "a `` ```` `` b\n"         = "````",
  "a ``` x````y ``` b\n"     = "x````y",
  "a ``` x`y````z`` ``` b\n" = "x`y````z``",
  "a `` `x` `` b\n"          = "`x`",
  "` `` `\n"                 = "``",
  "` foo `` bar `\n"         = "foo `` bar",
  "``foo`bar``\n"            = "foo`bar",
  "a `x\n``y` b\n"           = "x ``y"
)

first_code = function(pd) {
  codes = purrr::keep(pd@blocks[[1]]@content@content, S7::S7_inherits, pandoc_code)
  expect_length(codes, 1L)
  codes[[1]]@text
}

test_that("in-span backtick runs stay inside one code span on the pandoc path", {
  for (src in names(cases)) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_no_error_diagnostics(pd)
    expect_identical(first_code(pd), cases[[src]], info = src)
  }

  pd = parse_qmd("a `x``y` and `z`\n", quiet = TRUE)
  inl = pd@blocks[[1]]@content@content
  expect_identical(purrr::map_chr(purrr::keep(inl, S7::S7_inherits, pandoc_code), function(x) x@text), c("x``y", "z"))
  expect_true(any(purrr::map_lgl(inl, function(x) S7::S7_inherits(x, pandoc_str) && x@text == "and")))
})

test_that("code spans with backtick runs round-trip through the writer", {
  expect_identical(to_qmd(parse_qmd("a `x``y` b\n", quiet = TRUE)), "a ```x``y``` b\n")
  for (src in names(cases)) {
    pd = parse_qmd(src, quiet = TRUE)
    pd2 = parse_qmd(to_qmd(pd), quiet = TRUE)
    expect_no_error_diagnostics(pd2)
    expect_identical(first_code(pd2), cases[[src]], info = src)
    expect_pd_ast_equal(pd2, pd)
  }
})

test_that("code spans with backtick runs byte-recover on the tree-sitter path", {
  for (src in names(cases)) {
    ts = parse_qmd(src, ast = "ts", quiet = TRUE)
    expect_no_error_diagnostics(ts)
    expect_length(as.list(select_nodes(ts, kind == "ERROR")), 0L)
    expect_length(as.list(select_nodes(ts, kind == "pandoc_code_span")), 1L)
    expect_identical(to_qmd(ts), src, info = src)
    expect_ts_ast_equal(parse_qmd(to_qmd(ts), ast = "ts", quiet = TRUE), ts)
  }
})

test_that("plain code spans are unchanged", {
  pd = parse_qmd("a `x` b\n", quiet = TRUE)
  expect_identical(first_code(pd), "x")
  expect_identical(to_qmd(pd), "a `x` b\n")
})
