# tree-sitter-qmd accepts fenced-div colons with no whitespace after them as of
# q2 914f2069 (e76c2c72, bd-div-attr-no-space-ne0fudkw). A tight `:::{.foo}` or
# `:::foo` following a paragraph used to be swallowed into the soft line break,
# erasing the opening line and failing at the closing fence; this was the real
# cause behind the retired q2#TBD-fenced-div-close-after-block skips.

tight_srcs = list(
  attr   = "Before.\n\n:::{.myclass}\nInside.\n:::\n",
  bare   = "Before.\n\n:::foo\nInside.\n:::\n",
  nested = "::: {.outer}\n\n## A\n\n:::{layout=\"2\"}\n:::\n\n:::\n"
)

test_that("tight fenced-div openers parse as divs on the pandoc path", {
  pd = parse_qmd(tight_srcs$attr, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_true(S7::S7_inherits(pd@blocks[[2]], pandoc_div))
  expect_identical(pd@blocks[[2]]@attr@classes, "myclass")
  expect_identical(ast_text(pd@blocks[[2]]), "Inside.")

  pd = parse_qmd(tight_srcs$bare, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(pd@blocks[[2]]@attr@classes, "foo")

  pd = parse_qmd(tight_srcs$nested, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_length(select_nodes(pd, is(pandoc_div)), 2L)
})

test_that("tight fenced-div openers round-trip through the pampa qmd writer", {
  for (nm in names(tight_srcs)) {
    pd = parse_qmd(tight_srcs[[nm]], quiet = TRUE)
    expect_no_error_diagnostics(pd)
    expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
  }
})

test_that("tight fenced-div openers byte-recover on the tree-sitter path", {
  for (nm in names(tight_srcs)) {
    ts = parse_qmd(tight_srcs[[nm]], ast = "ts", quiet = TRUE)
    expect_no_error_diagnostics(ts)
    expect_gte(length(select_descendants(ts, kind == "pandoc_div")), 1L)
    out = to_qmd(ts)
    expect_identical(out, tight_srcs[[nm]])
    expect_ts_ast_equal(parse_qmd(out, ast = "ts", quiet = TRUE), ts)
  }
})

test_that("a colon run that opens no block stays inside the paragraph", {
  pd = parse_qmd("Before.\n\n:hello\n::world\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_length(pd@blocks@content, 2L)
  expect_length(select_nodes(pd, is(pandoc_div)), 0L)
})
