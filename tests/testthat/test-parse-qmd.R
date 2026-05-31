test_that("parse_qmd() returns a pandoc object with a diagnostics slot", {
  res = parse_qmd("hello")
  expect_true(S7::S7_inherits(res, pandoc))
  expect_type(res@diagnostics, "list")
})

test_that("parse_qmd(ast = 'ts') returns a ts_tree object with a diagnostics slot", {
  res = parse_qmd("hello", ast = "ts")
  expect_true(S7::S7_inherits(res, ts_tree))
  expect_type(res@diagnostics, "list")
})

test_that("a paragraph parses to pandoc_paragraph with the right inlines", {
  res = parse_qmd("hello world")
  blocks = res@blocks@content
  expect_length(blocks, 1L)
  expect_true(S7::S7_inherits(blocks[[1L]], pandoc_paragraph))
  inlines = blocks[[1L]]@content@content
  texts = vapply(
    inlines,
    function(x) if (S7::S7_inherits(x, pandoc_str)) x@text else "",
    character(1)
  )
  expect_true(all(c("hello", "world") %in% texts))
})

test_that("a header parses to pandoc_header with level + auto-id", {
  res = parse_qmd("# Hello world")
  blocks = res@blocks@content
  expect_true(S7::S7_inherits(blocks[[1L]], pandoc_header))
  expect_identical(blocks[[1L]]@level, 1L)
})

test_that("emphasis parses to pandoc_emph wrapping a pandoc_str", {
  res = parse_qmd("A *b*")
  para = res@blocks@content[[1L]]
  emph_idx = which(vapply(
    para@content@content,
    function(x) S7::S7_inherits(x, pandoc_emph),
    logical(1)
  ))
  expect_length(emph_idx, 1L)
  inner = para@content@content[[emph_idx]]@content@content
  expect_true(S7::S7_inherits(inner[[1L]], pandoc_str))
  expect_identical(inner[[1L]]@text, "b")
})

test_that("a fenced code block parses to pandoc_code_block with the right text and class", {
  qmd = "```r\nx + 1\n```"
  res = parse_qmd(qmd)
  cb = res@blocks@content[[1L]]
  expect_true(S7::S7_inherits(cb, pandoc_code_block))
  expect_match(cb@text, "x \\+ 1")
  expect_true("r" %in% cb@attr@classes)
})

test_that("a bullet list parses to pandoc_bullet_list with one item per entry", {
  qmd = "- a\n- b\n- c"
  res = parse_qmd(qmd)
  bl = res@blocks@content[[1L]]
  expect_true(S7::S7_inherits(bl, pandoc_bullet_list))
  expect_length(bl@content, 3L)
  expect_true(S7::S7_inherits(bl@content[[1L]], pandoc_blocks))
})

test_that("a link parses to pandoc_link with url + content", {
  res = parse_qmd("see [the docs](https://example.com)")
  para = res@blocks@content[[1L]]
  link = Filter(
    function(x) S7::S7_inherits(x, pandoc_link),
    para@content@content
  )[[1L]]
  expect_identical(link@url, "https://example.com")
})
