# q2 ecae1e1c1 (bd-25ezfgs8 / bd-byr1oonq, v0.36.0): a blank line inside a
# bullet or ordered list item is written empty rather than as an
# indentation-only line. The qmd reader took the whitespace-only line as
# making the list tight, so a loose item holding a paragraph and a code
# block came back with a different shape. The writer previously indented
# every continuation line, blank ones included.

doc_of = function(...) pandoc(blocks = pandoc_blocks(list(...)))
para = function(x) pandoc_paragraph(content = as_inlines(x))
loose_item = function() as_blocks(list(para("Text."), pandoc_code_block(text = "1 + 1")))

whitespace_only_lines = function(out) {
  lines = strsplit(out, "\n", fixed = TRUE)[[1]]
  lines[nzchar(lines) & !nzchar(trimws(lines))]
}

test_that("a blank line inside a bullet item is written empty", {
  d = doc_of(pandoc_bullet_list(content = list(loose_item())))
  out = to_qmd(d)
  expect_identical(out, "* Text.\n\n  ```\n  1 + 1\n  ```\n")
  expect_length(whitespace_only_lines(out), 0L)
  pd = parse_qmd(out, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_pd_ast_equal(pd, d)
})

test_that("a blank line inside an ordered item is written empty", {
  d = doc_of(pandoc_ordered_list(content = list(loose_item())))
  out = to_qmd(d)
  expect_identical(out, "1.  Text.\n\n    ```\n    1 + 1\n    ```\n")
  expect_length(whitespace_only_lines(out), 0L)
  pd = parse_qmd(out, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_pd_ast_equal(pd, d)
})

test_that("a multi-paragraph item keeps every blank line empty", {
  d = doc_of(pandoc_bullet_list(content = list(
    as_blocks(list(para("One."), para("Two."), para("Three."))),
    as_blocks(list(para("Four.")))
  )))
  out = to_qmd(d)
  expect_length(whitespace_only_lines(out), 0L)
  pd = parse_qmd(out, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_pd_ast_equal(pd, d)
})

test_that("a tight list has no blank lines to begin with", {
  d = doc_of(pandoc_bullet_list(content = list(
    as_blocks(list(pandoc_plain(content = as_inlines("a")))),
    as_blocks(list(pandoc_plain(content = as_inlines("b"))))
  )))
  out = to_qmd(d)
  expect_identical(out, "* a\n* b\n")
  expect_pd_ast_equal(parse_qmd(out, quiet = TRUE), d)
})
