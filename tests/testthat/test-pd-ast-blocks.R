test_that("pandoc_paragraph and pandoc_plain take pandoc_inlines content", {
  content = pandoc_inlines(list(pandoc_str(text = "x")))
  expect_true(S7::S7_inherits(pandoc_paragraph(content = content), pandoc_block))
  expect_true(S7::S7_inherits(pandoc_plain(content = content), pandoc_block))
  expect_error(pandoc_paragraph(content = "bad"))
})

test_that("pandoc_header validates level + content types", {
  content = pandoc_inlines(list(pandoc_str(text = "H")))
  h = pandoc_header(level = 2L, content = content)
  expect_identical(h@level, 2L)
  expect_true(S7::S7_inherits(h@content, pandoc_inlines))
})

test_that("pandoc_code_block and pandoc_raw_block store text/format", {
  cb = pandoc_code_block(text = "1+1", attr = pandoc_attr(classes = "r"))
  expect_identical(cb@text, "1+1")
  expect_identical(cb@attr@classes, "r")
  rb = pandoc_raw_block(format = "html", text = "<p>x</p>")
  expect_identical(rb@format, "html")
})

test_that("pandoc_block_quote takes pandoc_blocks content", {
  blocks = pandoc_blocks(list(
    pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "q"))))
  ))
  bq = pandoc_block_quote(content = blocks)
  expect_true(S7::S7_inherits(bq@content, pandoc_blocks))
})

test_that("pandoc_bullet_list validates items are pandoc_blocks", {
  p = pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "a"))))
  item = pandoc_blocks(list(p))
  expect_silent(pandoc_bullet_list(content = list(item, item)))
  expect_error(pandoc_bullet_list(content = list(p)), "pandoc_blocks")
})

test_that("pandoc_ordered_list takes list_attributes and items", {
  p = pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "a"))))
  ol = pandoc_ordered_list(
    attr = pandoc_list_attributes(start = 3L, style = "LowerAlpha", delim = "OneParen"),
    content = list(pandoc_blocks(list(p)))
  )
  expect_identical(ol@attr@start, 3L)
  expect_identical(ol@attr@style, "LowerAlpha")
})

test_that("pandoc_definition_list requires pandoc_definition_item entries", {
  term = pandoc_inlines(list(pandoc_str(text = "t")))
  defn = pandoc_blocks(list(
    pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "d"))))
  ))
  item = pandoc_definition_item(term = term, defs = list(defn))
  expect_silent(pandoc_definition_list(content = list(item)))
  expect_error(pandoc_definition_list(content = list("x")), "pandoc_definition_item")
})

test_that("pandoc_div and pandoc_figure carry attr + blocks", {
  blocks = pandoc_blocks(list(
    pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "d"))))
  ))
  d = pandoc_div(attr = pandoc_attr(id = "a"), content = blocks)
  expect_identical(d@attr@id, "a")
  f = pandoc_figure(content = blocks)
  expect_true(S7::S7_inherits(f@caption, pandoc_caption))
})

test_that("pandoc_horizontal_rule constructs empty and inherits pandoc_block", {
  hr = pandoc_horizontal_rule()
  expect_true(S7::S7_inherits(hr, pandoc_block))
})
