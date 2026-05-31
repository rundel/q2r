ast_mismatch_message = function(expr) {
  tryCatch(
    expr,
    expectation_failure = function(e) conditionMessage(e)
  )
}

test_that("expect_pd_ast_equal passes on identical ASTs", {
  pd = pampa_parse("# Hi\n\nWorld.", quiet = TRUE)
  expect_pd_ast_equal(pd, pd)
})

test_that("expect_pd_ast_equal reports a side-by-side tree diff on mismatch", {
  testthat::local_reproducible_output(width = 200)
  a = pampa_parse("# Hi\n\nplain text here.", quiet = TRUE)
  b = pampa_parse("# Hi\n\nplain *emphasised* text here.", quiet = TRUE)
  msg = ast_mismatch_message(expect_pd_ast_equal(a, b))
  expect_snapshot(cat(msg))
})

test_that("expect_ts_ast_equal passes on identical ASTs", {
  ts = pampa_parse("# Hi\n\nWorld.", quiet = TRUE, ast = "ts")
  expect_ts_ast_equal(ts, ts)
})

test_that("expect_ts_ast_equal reports a side-by-side tree diff on mismatch", {
  testthat::local_reproducible_output(width = 200)
  a = pampa_parse("# Hi\n\nplain text here.", quiet = TRUE, ast = "ts")
  b = pampa_parse("# Hi\n\nplain *emphasised* text here.", quiet = TRUE, ast = "ts")
  msg = ast_mismatch_message(expect_ts_ast_equal(a, b))
  expect_snapshot(cat(msg))
})

test_that("expect_pd_ast_equal truncates very large diffs", {
  testthat::local_reproducible_output(width = 200)
  a_text = paste(c("# H", "", paste(rep("alpha.", 80), collapse = " ")), collapse = "\n")
  b_text = paste(c("# H", "", paste(rep("beta.",  80), collapse = " ")), collapse = "\n")
  a = pampa_parse(a_text, quiet = TRUE)
  b = pampa_parse(b_text, quiet = TRUE)
  msg = ast_mismatch_message(expect_pd_ast_equal(a, b))
  expect_snapshot(cat(msg))
})
