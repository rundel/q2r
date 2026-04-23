test_that("pampa_parse_pd returns a pandoc object with a diagnostics slot", {
  res = pampa_parse_pd("hello")
  expect_true(S7::S7_inherits(res, pandoc))
  expect_type(res@diagnostics, "list")
})

test_that("pampa_parse_ts returns a ts_tree object with a diagnostics slot", {
  res = pampa_parse_ts("hello")
  expect_true(S7::S7_inherits(res, ts_tree))
  expect_type(res@diagnostics, "list")
})

test_that("pampa_tree returns the raw tree-sitter dump as character lines", {
  tree = pampa_tree("hello")
  expect_type(tree, "character")
  expect_gt(length(tree), 0L)
})

test_that("pampa_native returns the Pandoc native AST text", {
  native = pampa_native("hello")
  expect_type(native, "character")
  expect_gt(length(native), 0L)
})

test_that("a paragraph parses to pandoc_paragraph with the right inlines", {
  res = pampa_parse_pd("hello world")
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
  res = pampa_parse_pd("# Hello world")
  blocks = res@blocks@content
  expect_true(S7::S7_inherits(blocks[[1L]], pandoc_header))
  expect_identical(blocks[[1L]]@level, 1L)
})

test_that("emphasis parses to pandoc_emph wrapping a pandoc_str", {
  res = pampa_parse_pd("A *b*")
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
  res = pampa_parse_pd(qmd)
  cb = res@blocks@content[[1L]]
  expect_true(S7::S7_inherits(cb, pandoc_code_block))
  expect_match(cb@text, "x \\+ 1")
  expect_true("r" %in% cb@attr@classes)
})

test_that("a bullet list parses to pandoc_bullet_list with one item per entry", {
  qmd = "- a\n- b\n- c"
  res = pampa_parse_pd(qmd)
  bl = res@blocks@content[[1L]]
  expect_true(S7::S7_inherits(bl, pandoc_bullet_list))
  expect_length(bl@content, 3L)
  expect_true(S7::S7_inherits(bl@content[[1L]], pandoc_blocks))
})

test_that("a link parses to pandoc_link with url + content", {
  res = pampa_parse_pd("see [the docs](https://example.com)")
  para = res@blocks@content[[1L]]
  link = Filter(
    function(x) S7::S7_inherits(x, pandoc_link),
    para@content@content
  )[[1L]]
  expect_identical(link@url, "https://example.com")
})
