test_that("select_nodes on a ts_tree finds matches by kind", {
  ts = pampa_parse("# Hello\n\nbody **bold** more\n", ast = "ts")
  headings = select_nodes(ts, kind == "atx_heading")
  expect_length(headings, 1L)
  expect_s7_class(headings[[1L]], ts_node)
  expect_equal(headings[[1L]]@kind, "atx_heading")
})

test_that("select_descendants excludes the root node", {
  ts = pampa_parse("# Hello\n", ast = "ts")
  all = select_nodes(ts, kind == "document")
  desc = select_descendants(ts, kind == "document")
  expect_length(all, 1L)
  expect_length(desc, 0L)
})

test_that("select_children inspects only direct kids", {
  ts = pampa_parse("# H1\n\nfoo\n", ast = "ts")
  root = ts@root
  kids = select_children(root)
  expect_gt(length(kids), 0L)
  expect_true(all(purrr::map_lgl(kids, ~ S7::S7_inherits(.x, ts_node))))
})

test_that("select_first returns NULL on no match", {
  ts = pampa_parse("plain text\n", ast = "ts")
  none = select_first(ts, kind == "atx_heading")
  expect_null(none)
})

test_that("is_named slot accessor works", {
  ts = pampa_parse("# H\n", ast = "ts")
  named = select_nodes(ts, isTRUE(is_named))
  expect_gt(length(named), 0L)
  expect_true(all(purrr::map_lgl(named, ~ isTRUE(.x@is_named))))
})

test_that("starts_with helper on a slot value", {
  ts = pampa_parse("# Heading\n\nfoo\n", ast = "ts")
  matches = select_nodes(ts, !is.null(text) & starts_with("Heading", text))
  expect_gt(length(matches), 0L)
})

test_that("map_nodes returning the input is a no-op", {
  ts = pampa_parse("# H1\n\nbody\n", ast = "ts")
  out = map_nodes(ts, kind == "atx_heading", .f = ~ .x)
  expect_s7_class(out, ts_tree)
  expect_equal(to_qmd(out), to_qmd(ts))
})

test_that("delete_nodes drops matching nodes from the tree", {
  ts = pampa_parse("first\n\n# Heading\n\nlast\n", ast = "ts")
  out = delete_nodes(ts, kind == "atx_heading")
  qmd = to_qmd(out)
  expect_false(grepl("# Heading", qmd))
  expect_true(grepl("first", qmd))
  expect_true(grepl("last", qmd))
})

test_that("multiple predicates are combined with AND", {
  ts = pampa_parse("# H1\n\n## H2\n\nbody\n", ast = "ts")
  m = select_nodes(ts, kind == "atx_heading", isTRUE(is_named))
  expect_length(m, 2L)
})

test_that("list-of-nodes dispatch supports chained selection", {
  ts = pampa_parse("# H1\n\n## H2\n\nbody\n", ast = "ts")
  step1 = select_nodes(ts, kind == "atx_heading")
  expect_length(step1, 2L)
  step2 = select_descendants(step1, kind == "atx_h1_marker" | kind == "atx_h2_marker")
  expect_gt(length(step2), 0L)
})
