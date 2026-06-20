test_that("as_inlines splits a single word into one pandoc_str", {
  out = as_inlines("hello")
  expect_s7_class(out, pandoc_inlines)
  expect_length(out@content, 1L)
  expect_equal(out@content[[1L]]@text, "hello")
})

test_that("as_inlines splits whitespace into str / space / str sequences", {
  out = as_inlines("hello world")
  texts = purrr::map_chr(out@content, function(x) {
    if (S7::S7_inherits(x, pandoc_str)) x@text else "_"
  })
  expect_equal(texts, c("hello", "_", "world"))
  expect_s7_class(out@content[[2L]], pandoc_space)
})

test_that("as_inlines collapses multiple whitespace into a single space", {
  out = as_inlines("a   b\t\tc")
  texts = purrr::map_chr(out@content, function(x) {
    if (S7::S7_inherits(x, pandoc_str)) x@text else "_"
  })
  expect_equal(texts, c("a", "_", "b", "_", "c"))
})

test_that("as_inlines emits soft breaks for newlines", {
  out = as_inlines("first\nsecond")
  classes = purrr::map_chr(out@content, function(x) S7::S7_class(x)@name)
  expect_true("pandoc_soft_break" %in% classes)
})

test_that("as_inlines treats a length-N character vector as N lines", {
  out = as_inlines(c("first", "second"))
  classes = purrr::map_chr(out@content, function(x) S7::S7_class(x)@name)
  expect_true("pandoc_soft_break" %in% classes)
})

test_that("as_inlines on empty string returns an empty wrapper", {
  out = as_inlines("")
  expect_s7_class(out, pandoc_inlines)
  expect_length(out@content, 0L)
})

test_that("as_inlines on a single pandoc_inline wraps it", {
  out = as_inlines(pandoc_emph(content = as_inlines("hi")))
  expect_s7_class(out, pandoc_inlines)
  expect_s7_class(out@content[[1L]], pandoc_emph)
})

test_that("as_inlines on a list of inlines wraps it", {
  out = as_inlines(list(pandoc_str(text = "a"), pandoc_space(), pandoc_str(text = "b")))
  expect_s7_class(out, pandoc_inlines)
  expect_length(out@content, 3L)
})

test_that("as_inlines on an existing pandoc_inlines is a no-op", {
  inp = pandoc_inlines(list(pandoc_str(text = "x")))
  out = as_inlines(inp)
  expect_identical(out, inp)
})

test_that("as_inlines rejects a list with non-inline elements", {
  expect_error(
    as_inlines(list(pandoc_str(text = "a"), pandoc_paragraph(content = pandoc_inlines(list())))),
    "pandoc_inline"
  )
})

test_that("as_blocks of a single string produces one paragraph", {
  out = as_blocks("hello world")
  expect_s7_class(out, pandoc_blocks)
  expect_length(out@content, 1L)
  expect_s7_class(out@content[[1L]], pandoc_paragraph)
})

test_that("as_blocks of a character vector produces one paragraph per element", {
  out = as_blocks(c("first", "second"))
  expect_length(out@content, 2L)
  expect_s7_class(out@content[[1L]], pandoc_paragraph)
  expect_s7_class(out@content[[2L]], pandoc_paragraph)
})

test_that("as_blocks skips empty strings", {
  out = as_blocks(c("first", "", "second"))
  expect_length(out@content, 2L)
})

test_that("as_blocks on a single pandoc_block wraps it", {
  hdr = pandoc_header(level = 1L, content = as_inlines("title"))
  out = as_blocks(hdr)
  expect_s7_class(out, pandoc_blocks)
  expect_s7_class(out@content[[1L]], pandoc_header)
})

test_that("as_blocks on an existing pandoc_blocks is a no-op", {
  inp = pandoc_blocks(list(pandoc_paragraph(content = as_inlines("x"))))
  out = as_blocks(inp)
  expect_identical(out, inp)
})

test_that("as_inlines / as_blocks compose with constructors for terser filter code", {
  # Lua-style: pandoc.Para("hi") via pandoc_paragraph(content = as_inlines("hi"))
  built = pandoc_paragraph(content = as_inlines("hello world"))
  expect_equal(ast_text(built), "hello world")
})

test_that("as_inlines / as_blocks drop NA rather than emitting the string 'NA'", {
  expect_length(as_inlines(NA_character_)@content, 0L)
  expect_length(as_blocks(NA_character_)@content, 0L)
  expect_equal(ast_text(as_inlines(c("a", NA, "b"))), "a b")
})
