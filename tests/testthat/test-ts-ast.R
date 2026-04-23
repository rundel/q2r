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

test_that("pampa_parse with format = 'cst' yields a structured tree rooted at 'document'", {
  res = pampa_parse("# Heading\n\nHello *world*.\n", format = "cst")
  expect_true(S7::S7_inherits(res@cst, ts_tree))
  expect_identical(res@cst@root@kind, "document")
  expect_true(S7::S7_inherits(res@cst@root@children, ts_nodes))
  expect_gt(length(res@cst@root@children@content), 0L)
})

test_that("leaf nodes carry a text substring from the source", {
  res = pampa_parse("# Hi\n", format = "cst")
  leaves = character()
  walk = function(n) {
    if (length(n@children@content) == 0L) {
      if (!is.null(n@text)) leaves <<- c(leaves, n@text)
    } else {
      for (c in n@children@content) walk(c)
    }
  }
  walk(res@cst@root)
  expect_true(any(grepl("Hi", leaves, fixed = TRUE)))
})

test_that("leaves always carry @text; non-leaf @text is populated only when children leave byte gaps", {
  res = pampa_parse("# Hi\n", format = "cst")
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
  check(res@cst@root)
})

test_that("every node exposes an is_named logical flag", {
  res = pampa_parse("# Hi\n", format = "cst")
  named = logical()
  walk = function(n) {
    named <<- c(named, n@is_named)
    for (c in n@children@content) walk(c)
  }
  walk(res@cst@root)
  expect_true(is.logical(named))
  expect_gt(length(named), 0L)
  expect_false(any(is.na(named)))
})

test_that("ts_tree prints without error and includes root kind", {
  res = pampa_parse("# Hi\n", format = "cst")
  out = utils::capture.output(print(res@cst))
  expect_true(any(grepl("document", out)))
})

cst_ranges_by_kind = function(node, acc = list()) {
  key = node@kind
  rng = c(
    node@range@start_point@row, node@range@start_point@column,
    node@range@end_point@row,   node@range@end_point@column
  )
  acc[[length(acc) + 1L]] = list(kind = key, range = rng)
  for (c in node@children@content) acc = cst_ranges_by_kind(c, acc)
  acc
}

tree_ranges_by_kind = function(tree_lines) {
  rx = "^(\\s*)([a-zA-Z_][a-zA-Z0-9_]*): \\{Node [^ ]+ \\((\\d+), (\\d+)\\) - \\((\\d+), (\\d+)\\)\\}$"
  m = regmatches(tree_lines, regexec(rx, tree_lines))
  keep = vapply(m, function(x) length(x) > 0L, logical(1))
  m = m[keep]
  lapply(m, function(x) {
    list(
      kind  = x[[3L]],
      range = as.integer(c(x[[4L]], x[[5L]], x[[6L]], x[[7L]]))
    )
  })
}

test_that("cst and tree dump agree on ranges when input lacks a trailing newline", {
  res = pampa_parse("# Hello world!", format = "all")
  cst_nodes = cst_ranges_by_kind(res@cst@root)
  tree_nodes = tree_ranges_by_kind(res@tree)

  expect_identical(length(cst_nodes), length(tree_nodes))
  expect_identical(
    vapply(cst_nodes,  function(x) x$kind, character(1)),
    vapply(tree_nodes, function(x) x$kind, character(1))
  )
  for (i in seq_along(cst_nodes)) {
    expect_identical(cst_nodes[[i]]$range, tree_nodes[[i]]$range)
  }
})

test_that("cst and tree dump agree on the document root range with/without trailing newline", {
  for (src in c("# Hello world!", "# Hello world!\n", "hello", "hello\n")) {
    res = pampa_parse(src, format = "all")
    tree_first = res@tree[[1L]]
    m = regmatches(
      tree_first,
      regexec("\\((\\d+), (\\d+)\\) - \\((\\d+), (\\d+)\\)", tree_first)
    )[[1L]]
    tree_range = as.integer(c(m[[2L]], m[[3L]], m[[4L]], m[[5L]]))
    root = res@cst@root
    cst_range = c(
      root@range@start_point@row, root@range@start_point@column,
      root@range@end_point@row,   root@range@end_point@column
    )
    expect_identical(cst_range, tree_range,
      info = sprintf("input = %s", deparse(src)))
  }
})
