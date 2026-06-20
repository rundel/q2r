test_that("ts_query captures atx_heading nodes", {
  ts = parse_qmd("# H1\n\n## H2\n\nbody\n", ast = "ts")
  out = ts_query(ts, "(atx_heading) @h")
  expect_type(out, "list")
  expect_length(out, 2L)
  expect_s7_class(out[[1L]]$h, ts_node)
  expect_equal(out[[1L]]$h@kind, "atx_heading")
})

test_that("ts_query returns every capture of a multi-capture match", {
  out = ts_query("# Hi\n", "(atx_heading (atx_h1_marker) @marker) @whole")
  expect_length(out, 1L)
  expect_setequal(names(out[[1L]]), c("whole", "marker"))
  expect_equal(out[[1L]]$whole@kind, "atx_heading")
  expect_equal(out[[1L]]$marker@kind, "atx_h1_marker")
})

test_that("ts_query reads a file path as input", {
  path = withr::local_tempfile(fileext = ".qmd")
  writeLines("# FromFile\n", path)
  out = ts_query(path, "(atx_heading) @h")
  expect_length(out, 1L)
  expect_equal(out[[1L]]$h@kind, "atx_heading")
})

test_that("ts_query returns an empty list on no matches", {
  ts = parse_qmd("plain text\n", ast = "ts")
  out = ts_query(ts, "(atx_heading) @h")
  expect_length(out, 0L)
})

test_that("ts_query errors on a malformed query", {
  expect_error(
    ts_query("plain\n", "((not a valid scm"),
    "query compilation failed"
  )
})

test_that("ts_query accepts a raw string as input", {
  out = ts_query("# Hello\n", "(atx_heading) @h")
  expect_length(out, 1L)
})

test_that("ts_query returns empty matches when the input cannot be parsed to a tree", {
  expect_length(ts_query("", "(atx_heading) @h"), 0L)
})
