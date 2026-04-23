test_that("pandoc_source_info defaults are all NA", {
  si = pandoc_source_info()
  expect_s7_class = function(x, cls) expect_true(S7::S7_inherits(x, cls))
  expect_s7_class(si, pandoc_source_info)
  expect_identical(si@file_id, NA_integer_)
  expect_identical(si@start_row, NA_integer_)
  expect_identical(si@end_col, NA_integer_)
})

test_that("pandoc_attr defaults are empty", {
  a = pandoc_attr()
  expect_identical(a@id, "")
  expect_identical(a@classes, character())
  expect_identical(a@attributes, character())
})

test_that("pandoc_attr accepts id, classes, and attributes", {
  a = pandoc_attr(
    id = "foo",
    classes = c("a", "b"),
    attributes = c(key = "value")
  )
  expect_identical(a@id, "foo")
  expect_identical(a@classes, c("a", "b"))
  expect_identical(a@attributes, c(key = "value"))
})

test_that("pandoc_meta_value rejects unknown kinds", {
  expect_error(pandoc_meta_value(kind = "wat"), "kind")
  expect_silent(pandoc_meta_value(kind = "string", value = "hi"))
  expect_silent(pandoc_meta_value(kind = "bool", value = TRUE))
})

test_that("pandoc_inlines validates that content is all pandoc_inline", {
  expect_silent(pandoc_inlines(list(pandoc_str(text = "a"), pandoc_space())))
  expect_error(
    pandoc_inlines(list(pandoc_str(text = "a"), pandoc_paragraph())),
    "pandoc_inline"
  )
  expect_error(pandoc_inlines(list("not-a-node")), "pandoc_inline")
})

test_that("pandoc_blocks validates that content is all pandoc_block", {
  p = pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "x"))))
  expect_silent(pandoc_blocks(list(p)))
  expect_error(
    pandoc_blocks(list(pandoc_str(text = "x"))),
    "pandoc_block"
  )
})

test_that("pandoc_inlines and pandoc_blocks allow empty content", {
  expect_silent(pandoc_inlines(list()))
  expect_silent(pandoc_blocks(list()))
})

test_that("virtual parent classes cannot be instantiated directly", {
  expect_error(pandoc_node(), "abstract")
  expect_error(pandoc_block(), "abstract")
  expect_error(pandoc_inline(), "abstract")
})

test_that("pandoc_caption accepts NULL short caption", {
  cap = pandoc_caption()
  expect_null(cap@short)
  expect_true(S7::S7_inherits(cap@long, pandoc_blocks))
})

test_that("pandoc_caption rejects non-inlines short caption", {
  expect_error(pandoc_caption(short = "a string"), "pandoc_inlines")
})

test_that("pandoc_definition_item rejects non-pandoc_blocks defs", {
  expect_error(
    pandoc_definition_item(defs = list("not-blocks")),
    "pandoc_blocks"
  )
})

test_that("pandoc_list_attributes has sensible defaults", {
  la = pandoc_list_attributes()
  expect_identical(la@start, 1L)
  expect_identical(la@style, "Decimal")
  expect_identical(la@delim, "Period")
})
