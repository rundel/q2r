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

test_that("integer slots reject negatives and non-scalars", {
  expect_error(pandoc_list_attributes(start = -3L), ">= 0")
  expect_error(pandoc_cell(row_span = -1L), ">= 1")
  expect_error(pandoc_cell(col_span = 0L), ">= 1")
  expect_error(pandoc_citation(note_num = -1L), ">= 0")
  expect_error(pandoc_citation(hash = -5L), ">= 0")
  expect_error(pandoc_list_attributes(start = NA_integer_), "non-NA")
  expect_no_error(pandoc_list_attributes(start = 0L))
  expect_no_error(pandoc_cell(row_span = 3L))
})

test_that("enum slots reject unknown values instead of silently defaulting", {
  expect_error(pandoc_citation(mode = "SupressAuthor"), "must be one of")
  expect_error(pandoc_cell(alignment = "Middle"), "must be one of")
  expect_error(pandoc_col_spec(alignment = "wat"), "must be one of")
  expect_error(pandoc_col_spec(width = "wide"), "single non-NA number")
  expect_error(pandoc_list_attributes(style = "Fancy"), "must be one of")
  expect_error(pandoc_list_attributes(delim = "Dash"), "must be one of")
  expect_no_error(pandoc_citation(mode = "SuppressAuthor"))
  expect_no_error(pandoc_col_spec(width = 0.5))
})

test_that("pandoc_attr enforces scalar id and well-formed attributes", {
  expect_error(pandoc_attr(id = NA_character_), "non-NA")
  expect_error(pandoc_attr(id = character()), "single")
  expect_error(pandoc_attr(id = c("a", "b")), "single")
  expect_error(pandoc_attr(classes = c("a", NA)), "must not contain NA")
  expect_error(pandoc_attr(attributes = c("noname", "x")), "named")
  expect_error(pandoc_attr(attributes = c(k = NA_character_)), "NA values")
  expect_error(pandoc_attr(attributes = c(k = "1", k = "2")), "unique")
  expect_no_error(pandoc_attr(id = "ok", classes = "c1", attributes = c(k = "v")))
})

test_that("pandoc_meta_value validates value shape against kind", {
  expect_error(pandoc_meta_value(kind = "map", value = list(pandoc_meta_value(kind = "null", value = NULL))), "wrong shape")
  expect_error(pandoc_meta_value(kind = "inlines", value = list("x")), "wrong shape")
  expect_error(pandoc_meta_value(kind = "int", value = "5"), "wrong shape")
  expect_error(pandoc_meta_value(kind = "bool", value = 1), "wrong shape")
  expect_no_error(pandoc_meta_value(kind = "string", value = "x"))
  expect_no_error(pandoc_meta_value(kind = "inlines", value = as_inlines("x")))
  expect_no_error(pandoc_meta_value(kind = "map", value = list(a = pandoc_meta_value(kind = "null", value = NULL))))
  expect_no_error(pandoc_meta_value(kind = "list", value = list(pandoc_meta_value(kind = "int", value = 1L))))
})

test_that("typed wrappers behave like lists", {
  doc = parse_qmd("a\n\nb\n")
  b = doc@blocks
  expect_identical(length(b), 2L)
  expect_s7_class(b[[1]], pandoc_paragraph)
  expect_s7_class(b[1], pandoc_blocks)
  expect_identical(length(b[1]), 1L)
  expect_identical(as.list(b), b@content)
  expect_length(lapply(b, class), 2L)
})

test_that("wrapper [ rejects out-of-range subscripts clearly", {
  doc = parse_qmd("a\n\nb\n")
  expect_error(doc@blocks[5], "out of bounds")
  expect_error(doc@blocks[c(1, 4)], "out of bounds")
  expect_no_error(doc@blocks[2:1])
})
