# q2 3d3360ab (c26b3e832) keeps sibling lists apart in the qmd writer and
# adds an AST pre-pass (writers/qmd_prepass.rs): two adjacent bullet lists
# alternate their marker (`*` then `-`), two adjacent ordered lists get a
# `<!-- -->` raw block between them, a note holding more than one block is
# written as a `[^nK]` reference plus a `::: ^nK` fenced definition after the
# enclosing top-level block, and a list nested in each item of an outer list
# keeps `*` throughout. The qmd reader never yields adjacent lists or a
# multi-block inline note, so this reaches R-constructed ASTs only.

doc = function(...) pandoc(blocks = as_blocks(list(...)))
para = function(x) pandoc_paragraph(content = as_inlines(x))
items = function(...) purrr::map(list(...), function(x) pandoc_blocks(list(pandoc_plain(content = as_inlines(x)))))
bullets = function(...) pandoc_bullet_list(content = items(...))
numbered = function(...) pandoc_ordered_list(content = items(...))

test_that("adjacent bullet lists alternate their marker and round-trip", {
  d = doc(bullets("A"), bullets("B"))
  expect_identical(to_qmd(d), "* A\n\n- B\n")
  expect_pd_ast_equal(parse_qmd(to_qmd(d), quiet = TRUE), d)

  d = doc(bullets("A"), bullets("B"), bullets("C"))
  expect_identical(to_qmd(d), "* A\n\n- B\n\n* C\n")
  expect_pd_ast_equal(parse_qmd(to_qmd(d), quiet = TRUE), d)
})

test_that("a paragraph between two bullet lists keeps the star, as do nested per-item lists", {
  d = doc(bullets("A"), para("mid"), bullets("B"))
  expect_identical(to_qmd(d), "* A\n\nmid\n\n* B\n")

  rows = pandoc_bullet_list(content = list(
    pandoc_blocks(list(bullets("h1", "h2"))),
    pandoc_blocks(list(bullets("a", "b")))
  ))
  d = doc(rows)
  expect_identical(to_qmd(d), "* * h1\n  * h2\n\n* * a\n  * b\n")
  expect_pd_ast_equal(parse_qmd(to_qmd(d), quiet = TRUE), d)
})

test_that("adjacent ordered lists are separated by a raw html comment block", {
  d = doc(numbered("a", "b"), numbered("c"))
  expect_identical(to_qmd(d), "1.  a\n2.  b\n\n<!-- -->\n\n1.  c\n")
  pd = parse_qmd(to_qmd(d), quiet = TRUE)
  expect_length(pd@blocks, 3L)
  expect_s7_class(pd@blocks[[2]], pandoc_raw_block)
  expect_identical(pd@blocks[[2]]@format, "html")
  expect_identical(pd@blocks[[2]]@text, "<!-- -->")
  expect_pd_ast_equal(doc(pd@blocks[[1]], pd@blocks[[3]]), d)
  expect_identical(to_qmd(pd), to_qmd(d))
})

test_that("an ordered list next to a bullet list needs no separator", {
  d = doc(numbered("a"), bullets("b"))
  expect_false(grepl("<!--", to_qmd(d), fixed = TRUE))
  expect_pd_ast_equal(parse_qmd(to_qmd(d), quiet = TRUE), d)
})

test_that("a multi-block note becomes a reference plus a fenced definition", {
  d = doc(pandoc_paragraph(content = as_inlines(list(
    pandoc_str(text = "Text"),
    pandoc_note(content = as_blocks(c("first", "second")))
  ))))
  expect_identical(to_qmd(d), "Text[^n1]\n\n::: ^n1\nfirst\n\nsecond\n:::\n")
  pd = parse_qmd(to_qmd(d), quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_length(pd@blocks, 2L)
  expect_s7_class(pd@blocks[[2]], pandoc_note_definition_fenced_block)
  expect_identical(pd@blocks[[2]]@id, "n1")
  expect_length(pd@blocks[[2]]@content, 2L)
  ref = pd@blocks[[1]]@content@content[[2]]
  expect_s7_class(ref, pandoc_span)
  expect_true(has_class(ref, "quarto-note-reference"))
  expect_identical(get_attr(ref, "reference-id"), "n1")
})

test_that("a single-paragraph note stays inline", {
  d = doc(pandoc_paragraph(content = as_inlines(list(
    pandoc_str(text = "a"),
    pandoc_note(content = as_blocks("single paragraph")),
    pandoc_str(text = "b")
  ))))
  expect_identical(to_qmd(d), "a^[single paragraph]b\n")
  expect_pd_ast_equal(parse_qmd(to_qmd(d), quiet = TRUE), d)
})
