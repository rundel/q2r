test_that("pandoc_inlines handler receives whole inline sequences", {
  doc = parse_qmd("a *b* c\n")
  seen_count = 0L
  ast_filter(doc, pandoc_inlines = function(xs) {
    seen_count <<- seen_count + 1L
    xs
  })
  expect_gt(seen_count, 0L)
})

test_that("pandoc_inlines handler can rewrite content", {
  doc = parse_qmd("hello world\n")
  out = ast_filter(doc, pandoc_inlines = function(xs) {
    pandoc_inlines(c(list(pandoc_str(text = "PREFIX:")), xs@content))
  })
  para = select_first(out, is(pandoc_paragraph))
  first = para@content@content[[1L]]
  expect_s7_class(first, pandoc_str)
  expect_equal(first@text, "PREFIX:")
})

test_that("pandoc_inlines handler can drop elements (returning a smaller wrapper)", {
  doc = parse_qmd("a *italic* b\n")
  out = ast_filter(doc, pandoc_inlines = function(xs) {
    keep = !purrr::map_lgl(xs@content, S7::S7_inherits, pandoc_emph)
    pandoc_inlines(xs@content[keep])
  })
  expect_length(select_nodes(out, is(pandoc_emph)), 0L)
})

test_that("pandoc_blocks handler receives the top-level block sequence", {
  doc = parse_qmd("para 1\n\npara 2\n")
  seen_blocks = NULL
  ast_filter(doc, pandoc_blocks = function(xs) {
    if (is.null(seen_blocks)) seen_blocks <<- length(xs@content)
    xs
  })
  expect_equal(seen_blocks, 2L)
})

test_that("pandoc_blocks handler can drop blocks", {
  doc = parse_qmd("keep me\n\ndrop me\n\nkeep too\n")
  out = ast_filter(doc, pandoc_blocks = function(xs) {
    keep = !purrr::map_lgl(xs@content, function(b) {
      if (!S7::S7_inherits(b, pandoc_paragraph)) return(FALSE)
      grepl("drop", ast_text(b), fixed = TRUE)
    })
    pandoc_blocks(xs@content[keep])
  })
  paras = select_nodes(out, is(pandoc_paragraph))
  expect_length(paras, 2L)
  expect_false(any(purrr::map_lgl(paras, function(p) grepl("drop", ast_text(p), fixed = TRUE))))
})

test_that("pandoc_inlines handler accepts NULL (empty) and list (autowrap)", {
  doc = parse_qmd("hi\n")
  out_null = ast_filter(doc, pandoc_inlines = function(xs) NULL)
  expect_equal(length(select_first(out_null, is(pandoc_paragraph))@content@content), 0L)

  doc2 = parse_qmd("hi\n")
  out_list = ast_filter(doc2, pandoc_inlines = function(xs) {
    list(pandoc_str(text = "X"))
  })
  para = select_first(out_list, is(pandoc_paragraph))
  expect_length(para@content@content, 1L)
  expect_equal(para@content@content[[1L]]@text, "X")
})

test_that("pandoc_blocks handler rejects non-pandoc_blocks return that is not list/NULL", {
  doc = parse_qmd("hi\n")
  expect_error(
    ast_filter(doc, pandoc_blocks = function(xs) "not a wrapper"),
    "pandoc_blocks"
  )
})

test_that("list-level dispatch composes with element-level dispatch in one pass", {
  doc = parse_qmd("a *b* c\n")
  out = ast_filter(doc,
    pandoc_emph = function(el) pandoc_strong(content = el@content),
    pandoc_inlines = function(xs) {
      # by the time we see the wrapper, emph has already become strong
      strongs = purrr::keep(xs@content, S7::S7_inherits, pandoc_strong)
      if (length(strongs) > 0L) {
        xs@content[[length(xs@content) + 1L]] = pandoc_str(text = "[STRONG-SEEN]")
      }
      xs
    }
  )
  para = select_first(out, is(pandoc_paragraph))
  last = para@content@content[[length(para@content@content)]]
  expect_equal(last@text, "[STRONG-SEEN]")
})

test_that("pandoc_blocks handler also fires inside containers like bullet lists", {
  doc = parse_qmd("- one\n- two\n")
  invocations = 0L
  ast_filter(doc, pandoc_blocks = function(xs) {
    invocations <<- invocations + 1L
    xs
  })
  # one invocation for the top-level blocks, one per bullet item's blocks
  expect_gte(invocations, 3L)
})
