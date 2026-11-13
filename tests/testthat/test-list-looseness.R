# q2 370123a8a (bd-az53ojvo, v0.42.0) moves the reader to CommonMark's
# loose/tight rule, decided on source rows: a list is loose when two items, or
# two direct blocks of one item, have a blank line between them. In a tight
# list every direct Paragraph of an item becomes Plain (it was only the first),
# and blank lines inside a fenced code block or a sublist no longer loosen the
# enclosing list. The writer follows: a list is spelled tight unless some item
# directly holds a Paragraph, so items made only of code blocks or sublists no
# longer force blank lines, and a blank line is kept between a block quote or
# sublist and the text that would otherwise continue it lazily.

doc = function(...) pandoc(blocks = as_blocks(list(...)))
para = function(x) pandoc_paragraph(content = as_inlines(x))
plain = function(x) pandoc_plain(content = as_inlines(x))
item = function(...) pandoc_blocks(list(...))
bullets = function(...) pandoc_bullet_list(content = list(...))

item_shapes = function(src) {
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  purrr::map(pd@blocks@content[[1]]@content, function(blocks) {
    purrr::map_chr(blocks@content, \(b) sub("^q2r::pandoc_", "", class(b)[1]))
  })
}

expect_list_roundtrip = function(src) {
  pd = parse_qmd(src, quiet = TRUE)
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
}

test_that("every direct paragraph of a tight item is plain", {
  src = "- a\n  # h\n  b\n"
  expect_identical(item_shapes(src), list(c("plain", "header", "plain")))
  expect_identical(to_qmd(parse_qmd(src, quiet = TRUE)), "* a\n  # h\n  b\n")
  expect_list_roundtrip(src)

  src = "- a\n  ```\n  x\n  ```\n- b\n"
  expect_identical(item_shapes(src), list(c("plain", "code_block"), "plain"))
  expect_identical(to_qmd(parse_qmd(src, quiet = TRUE)), "* a\n  ```\n  x\n  ```\n* b\n")
  expect_list_roundtrip(src)
})

test_that("a blank line between items or between an item's blocks makes the list loose", {
  expect_identical(item_shapes("- a\n\n- b\n"), list("paragraph", "paragraph"))
  expect_identical(item_shapes("1. a\n\n2. b\n"), list("paragraph", "paragraph"))
  expect_identical(item_shapes("- a\n\n  b\n- c\n"), list(c("paragraph", "paragraph"), "paragraph"))
  expect_list_roundtrip("- a\n\n- b\n")
  expect_list_roundtrip("1. a\n\n2. b\n")
  expect_list_roundtrip("- a\n\n  b\n- c\n")
})

test_that("a blank line inside a code block or a sublist does not loosen the outer list", {
  src = "- a\n  ```\n  x\n\n  y\n  ```\n- b\n"
  expect_identical(item_shapes(src), list(c("plain", "code_block"), "plain"))
  expect_list_roundtrip(src)

  src = "- a\n  - b\n\n  - c\n- d\n"
  expect_identical(item_shapes(src), list(c("plain", "bullet_list"), "plain"))
  pd = parse_qmd(src, quiet = TRUE)
  inner = pd@blocks@content[[1]]@content[[1]]@content[[2]]
  expect_true(all(purrr::map_lgl(inner@content, \(b) S7::S7_inherits(b@content[[1]], pandoc_paragraph))))
  expect_identical(to_qmd(pd), "* a\n  * b\n\n  * c\n* d\n")
  expect_list_roundtrip(src)
})

test_that("a quote marker alone on a line is a blank line between quoted items", {
  src = "> - a\n>\n> - b\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  items = pd@blocks@content[[1]]@content@content[[1]]@content
  expect_true(all(purrr::map_lgl(items, \(b) S7::S7_inherits(b@content[[1]], pandoc_paragraph))))
  expect_list_roundtrip(src)
})

test_that("the writer spells a list tight unless an item directly holds a paragraph", {
  d = doc(bullets(item(bullets(item(plain("x")))), item(plain("y"))))
  expect_identical(to_qmd(d), "* * x\n* y\n")
  expect_pd_ast_equal(parse_qmd(to_qmd(d), quiet = TRUE), d)

  d = doc(bullets(item(pandoc_code_block(text = "x")), item(pandoc_code_block(text = "y"))))
  expect_identical(to_qmd(d), "* ```\n  x\n  ```\n* ```\n  y\n  ```\n")
  expect_pd_ast_equal(parse_qmd(to_qmd(d), quiet = TRUE), d)

  d = doc(bullets(item(pandoc_code_block(text = "x")), item(para("y"))))
  expect_identical(to_qmd(d), "* ```\n  x\n  ```\n\n* y\n")
  expect_pd_ast_equal(parse_qmd(to_qmd(d), quiet = TRUE), d)
})

test_that("a tight item keeps a blank line where two blocks would otherwise merge", {
  quote = function(x) pandoc_block_quote(content = as_blocks(list(para(x))))
  d = doc(bullets(item(quote("q1"), quote("q2"))))
  expect_identical(to_qmd(d), "* > q1\n\n  > q2\n")

  d = doc(bullets(item(plain("a"), bullets(item(plain("b"))), plain("c"))))
  expect_identical(to_qmd(d), "* a\n  * b\n\n  c\n")
})
