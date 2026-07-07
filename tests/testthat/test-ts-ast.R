test_that("ts_nodes validates its content is all ts_node objects", {
  n = ts_node(kind = "x")
  expect_silent(ts_nodes(list(n, n)))
  expect_error(ts_nodes(list(n, "bad")), "ts_node")
})

test_that("ts_node constructor accepts expected defaults", {
  n = ts_node()
  expect_identical(n@kind, "")
  expect_identical(n@is_named, TRUE)
  expect_null(n@field_name)
  expect_null(n@text)
  expect_true(S7::S7_inherits(n@range, ts_range))
  expect_true(S7::S7_inherits(n@children, ts_nodes))
})

test_that("ts_node validates field_name and text scalar-string invariant", {
  expect_error(ts_node(field_name = c("a", "b")), "field_name")
  expect_error(ts_node(text = c("a", "b")), "text")
})

test_that("parse_qmd(ast = 'ts') yields a structured tree rooted at 'document'", {
  res = parse_qmd("# Heading\n\nHello *world*.\n", ast = "ts")
  expect_true(S7::S7_inherits(res, ts_tree))
  expect_identical(res@root@kind, "document")
  expect_true(S7::S7_inherits(res@root@children, ts_nodes))
  expect_gt(length(res@root@children@content), 0L)
})

test_that("leaf nodes carry a text substring from the source", {
  res = parse_qmd("# Hi\n", ast = "ts")
  leaves = character()
  walk = function(n) {
    if (length(n@children@content) == 0L) {
      if (!is.null(n@text)) leaves <<- c(leaves, n@text)
    } else {
      for (c in n@children@content) walk(c)
    }
  }
  walk(res@root)
  expect_true(any(grepl("Hi", leaves, fixed = TRUE)))
})

test_that("leaves always carry @text; non-leaf @text is populated only when children leave byte gaps", {
  res = parse_qmd("# Hi\n", ast = "ts")
  check = function(n) {
    if (length(n@children@content) == 0L) {
      expect_false(is.null(n@text))
    } else {
      kids = n@children@content
      starts = vapply(kids, function(c) c@range@start_byte, integer(1))
      ends   = vapply(kids, function(c) c@range@end_byte,   integer(1))
      covered_to = n@range@start_byte
      has_gap = FALSE
      for (i in seq_along(kids)) {
        if (starts[i] > covered_to) { has_gap = TRUE; break }
        if (ends[i] > covered_to) covered_to = ends[i]
      }
      if (!has_gap && covered_to < n@range@end_byte) has_gap = TRUE
      if (has_gap) expect_false(is.null(n@text)) else expect_null(n@text)
      for (c in kids) check(c)
    }
  }
  check(res@root)
})

test_that("every node exposes an is_named logical flag", {
  res = parse_qmd("# Hi\n", ast = "ts")
  named = logical()
  walk = function(n) {
    named <<- c(named, n@is_named)
    for (c in n@children@content) walk(c)
  }
  walk(res@root)
  expect_true(is.logical(named))
  expect_gt(length(named), 0L)
  expect_false(any(is.na(named)))
})

test_that("ts_tree prints without error and includes root kind", {
  res = parse_qmd("# Hi\n", ast = "ts")
  out = utils::capture.output(print(res))
  expect_true(any(grepl("document", out)))
})

test_that("ts_nodes behaves like a list", {
  ts = parse_qmd("a b\n", ast = "ts")
  tn = ts_nodes(select_nodes(ts, kind == "pandoc_str"))
  expect_identical(length(tn), 2L)
  expect_s7_class(tn[[1]], ts_node)
  expect_s7_class(tn[1], ts_nodes)
  expect_identical(as.list(tn), tn@content)
})

test_that("pandoc-only verbs give a friendly error on a ts_tree", {
  ts = parse_qmd("# A\n\nbody\n", ast = "ts")
  for (call in list(
    function() ast_text(ts), function() ast_summary(ts),
    function() ast_sections(ts), function() select_section(ts, "A"),
    function() split_sections(ts), function() ast_toc(ts),
    function() ast_filter(ts), function() as_df(ts)
  )) {
    expect_error(call(), "works on the pandoc AST")
  }
})
