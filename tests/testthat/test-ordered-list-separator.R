# q2 41d8cbd9a (bd-2bcre8cr, v0.44.0): the qmd writer separates two adjacent
# ordered lists with `<!-- -->` only when their written markers collide
# (Default and Period both write `.`, OneParen and TwoParens both `)`); a
# delimiter change already starts a new list. In a tight list item, a bare
# html RawBlock directly after a sublist is written as a ```{=html} fence so
# it cannot be read as a lazy continuation of the sublist's last line.

doc = function(...) pandoc(blocks = as_blocks(list(...)))
plain = function(x) pandoc_plain(content = as_inlines(x))
ol = function(delim, ...) {
  pandoc_ordered_list(
    attr = pandoc_list_attributes(delim = delim),
    content = purrr::map(list(...), function(x) pandoc_blocks(list(plain(x))))
  )
}
html = function(x) pandoc_raw_block(format = "html", text = x)

test_that("a delimiter change needs no separator", {
  d = doc(ol("Period", "a"), ol("OneParen", "b"))
  expect_identical(to_qmd(d), "1.  a\n\n1)  b\n")
  expect_pd_ast_equal(parse_qmd(to_qmd(d), quiet = TRUE), d)
})

test_that("colliding written markers are separated", {
  for (delims in list(c("Default", "Period"), c("OneParen", "TwoParens"))) {
    d = doc(ol(delims[1], "a"), ol(delims[2], "b"))
    out = to_qmd(d)
    expect_match(out, "\n\n<!-- -->\n\n", fixed = TRUE)
    pd = parse_qmd(out, quiet = TRUE)
    expect_length(pd@blocks, 3L)
    expect_s7_class(pd@blocks[[1]], pandoc_ordered_list)
    expect_s7_class(pd@blocks[[2]], pandoc_raw_block)
    expect_s7_class(pd@blocks[[3]], pandoc_ordered_list)
    expect_identical(ast_text(pd@blocks[[3]]), "b")
  }
})

test_that("an html block after a sublist in a tight item is fenced", {
  d = doc(pandoc_bullet_list(content = list(
    pandoc_blocks(list(plain("item"), ol("Period", "x"), html("<!-- c -->")))
  )))
  out = to_qmd(d)
  expect_identical(out, "* item\n  1.  x\n  ```{=html}\n  <!-- c -->\n  ```\n")
  pd = parse_qmd(out, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_pd_ast_equal(pd, d)
  expect_identical(to_qmd(pd), out)
})

test_that("a top-level html block after a list keeps the bare form", {
  d = doc(ol("Period", "x"), html("<!-- c -->"))
  out = to_qmd(d)
  expect_false(grepl("{=html}", out, fixed = TRUE))
  expect_pd_ast_equal(parse_qmd(out, quiet = TRUE), d)
})
