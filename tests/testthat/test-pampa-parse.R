test_that("pampa_parse returns a pampa_result regardless of format", {
  for (fmt in c("pd_ast", "tree", "ts_ast", "native", "all")) {
    res = pampa_parse("hello", format = fmt)
    expect_true(S7::S7_inherits(res, pampa_result))
  }
})

test_that("format = 'pd_ast' populates only @pd_ast (and diagnostics)", {
  res = pampa_parse("hello", format = "pd_ast")
  expect_true(S7::S7_inherits(res@pd_ast, pandoc))
  expect_null(res@tree)
  expect_null(res@ts_ast)
  expect_null(res@native)
})

test_that("format = 'tree' populates only @tree", {
  res = pampa_parse("hello", format = "tree")
  expect_null(res@pd_ast)
  expect_type(res@tree, "character")
  expect_gt(length(res@tree), 0L)
  expect_null(res@ts_ast)
  expect_null(res@native)
})

test_that("format = 'ts_ast' populates only @ts_ast", {
  res = pampa_parse("hello", format = "ts_ast")
  expect_null(res@pd_ast)
  expect_null(res@tree)
  expect_true(S7::S7_inherits(res@ts_ast, ts_tree))
  expect_null(res@native)
})

test_that("format = 'native' populates only @native", {
  res = pampa_parse("hello", format = "native")
  expect_null(res@pd_ast)
  expect_null(res@tree)
  expect_null(res@ts_ast)
  expect_type(res@native, "character")
  expect_gt(length(res@native), 0L)
})

test_that("format = 'all' populates every slot", {
  res = pampa_parse("hello", format = "all")
  expect_true(S7::S7_inherits(res@pd_ast, pandoc))
  expect_type(res@tree, "character")
  expect_true(S7::S7_inherits(res@ts_ast, ts_tree))
  expect_type(res@native, "character")
})

test_that("a paragraph parses to pandoc_paragraph with the right inlines", {
  res = pampa_parse("hello world", format = "pd_ast")
  blocks = res@pd_ast@blocks@content
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
  res = pampa_parse("# Hello world", format = "pd_ast")
  blocks = res@pd_ast@blocks@content
  expect_true(S7::S7_inherits(blocks[[1L]], pandoc_header))
  expect_identical(blocks[[1L]]@level, 1L)
})

test_that("emphasis parses to pandoc_emph wrapping a pandoc_str", {
  res = pampa_parse("A *b*", format = "pd_ast")
  para = res@pd_ast@blocks@content[[1L]]
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
  res = pampa_parse(qmd, format = "pd_ast")
  cb = res@pd_ast@blocks@content[[1L]]
  expect_true(S7::S7_inherits(cb, pandoc_code_block))
  expect_match(cb@text, "x \\+ 1")
  expect_true("r" %in% cb@attr@classes)
})

test_that("a bullet list parses to pandoc_bullet_list with one item per entry", {
  qmd = "- a\n- b\n- c"
  res = pampa_parse(qmd, format = "pd_ast")
  bl = res@pd_ast@blocks@content[[1L]]
  expect_true(S7::S7_inherits(bl, pandoc_bullet_list))
  expect_length(bl@content, 3L)
  expect_true(S7::S7_inherits(bl@content[[1L]], pandoc_blocks))
})

test_that("a link parses to pandoc_link with url + content", {
  res = pampa_parse("see [the docs](https://example.com)", format = "pd_ast")
  para = res@pd_ast@blocks@content[[1L]]
  link = Filter(
    function(x) S7::S7_inherits(x, pandoc_link),
    para@content@content
  )[[1L]]
  expect_identical(link@url, "https://example.com")
})
