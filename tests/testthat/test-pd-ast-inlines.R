test_that("pandoc_str carries text and inherits from pandoc_inline", {
  s = pandoc_str(text = "hello")
  expect_identical(s@text, "hello")
  expect_true(S7::S7_inherits(s, pandoc_inline))
  expect_true(S7::S7_inherits(s, pandoc_node))
})

test_that("pandoc_str rejects embedded ASCII whitespace", {
  expect_silent(pandoc_str(text = "word"))
  expect_silent(pandoc_str(text = ""))
  expect_silent(pandoc_str(text = paste0("a", intToUtf8(0x00A0), "b")))  # nbsp is not ASCII whitespace
  expect_error(pandoc_str(text = "a b"), "must not contain spaces")
  expect_error(pandoc_str(text = "line1\nline2"), "must not contain")
  expect_error(pandoc_str(text = "a\tb"), "must not contain")
})

test_that("leaf inlines (space, soft_break, line_break) construct without args", {
  expect_true(S7::S7_inherits(pandoc_space(), pandoc_inline))
  expect_true(S7::S7_inherits(pandoc_soft_break(), pandoc_inline))
  expect_true(S7::S7_inherits(pandoc_line_break(), pandoc_inline))
})

test_that("formatting inlines require pandoc_inlines content", {
  content = pandoc_inlines(list(pandoc_str(text = "x")))
  expect_silent(pandoc_emph(content = content))
  expect_silent(pandoc_strong(content = content))
  expect_silent(pandoc_underline(content = content))
  expect_silent(pandoc_small_caps(content = content))
  expect_error(pandoc_emph(content = list(pandoc_str(text = "x"))))
})

test_that("pandoc_quoted validates quote_type", {
  content = pandoc_inlines(list(pandoc_str(text = "x")))
  expect_silent(pandoc_quoted(content = content, quote_type = "single"))
  expect_silent(pandoc_quoted(content = content, quote_type = "double"))
  expect_error(pandoc_quoted(content = content, quote_type = "curly"))
})

test_that("pandoc_math validates math_type", {
  expect_silent(pandoc_math(math_type = "inline", text = "x"))
  expect_silent(pandoc_math(math_type = "display", text = "E = mc^2"))
  expect_error(pandoc_math(math_type = "block", text = "x"))
})

test_that("pandoc_code stores attr and text", {
  c1 = pandoc_code(text = "x + 1", attr = pandoc_attr(classes = "r"))
  expect_identical(c1@text, "x + 1")
  expect_identical(c1@attr@classes, "r")
})

test_that("pandoc_link and pandoc_image carry url and title", {
  content = pandoc_inlines(list(pandoc_str(text = "click")))
  lk = pandoc_link(content = content, url = "http://x", title = "t")
  expect_identical(lk@url, "http://x")
  expect_identical(lk@title, "t")
  img = pandoc_image(content = content, url = "img.png")
  expect_identical(img@url, "img.png")
})

test_that("pandoc_note wraps blocks content", {
  blocks = pandoc_blocks(list(
    pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "n"))))
  ))
  n = pandoc_note(content = blocks)
  expect_true(S7::S7_inherits(n@content, pandoc_blocks))
  expect_length(n@content@content, 1L)
})

test_that("pandoc_cite validates citations are pandoc_citation", {
  cit = pandoc_citation(id = "knuth1984")
  expect_silent(pandoc_cite(citations = list(cit)))
  expect_error(pandoc_cite(citations = list("not-a-citation")), "pandoc_citation")
})
