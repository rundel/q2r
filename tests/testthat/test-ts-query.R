test_that("ts_query captures atx_heading nodes", {
  ts = pampa_parse_ts("# H1\n\n## H2\n\nbody\n")
  out = ts_query(ts, "(atx_heading) @h")
  expect_type(out, "list")
  expect_length(out, 2L)
  expect_s7_class(out[[1L]]$h, ts_node)
  expect_equal(out[[1L]]$h@kind, "atx_heading")
})

test_that("ts_query handles multiple captures per match", {
  ts = pampa_parse_ts("# Hello\n")
  out = ts_query(ts, "(atx_heading) @whole")
  expect_length(out, 1L)
  expect_named(out[[1L]], "whole")
})

test_that("ts_query returns an empty list on no matches", {
  ts = pampa_parse_ts("plain text\n")
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
