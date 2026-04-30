QUARTO_WEB_SKIP = list(
  ts_rt        = list(),
  pd_rt        = list(),
  pampa_ts_rt  = list(),
  pampa_pd_rt  = list()
)

gen_test_block = function(rel, skip_map, body_lines) {
  reason = skip_map[[rel]]
  quoted = deparse(rel, width.cutoff = 500L)

  if (!is.null(reason)) {
    return(c(
      paste0("test_that(", quoted, ", {"),
      paste0("  skip(", deparse(paste0("Known failure: ", reason), width.cutoff = 500L), ")"),
      "})"
    ))
  }

  c(
    paste0("test_that(", quoted, ", {"),
    body_lines,
    "})"
  )
}

gen_ts_rt_test = function(rel, skip_map = list()) {
  gen_test_block(rel, skip_map, c(
    "  skip_if_no_quarto_web()",
    paste0("  text = quarto_web_read(", deparse(rel, width.cutoff = 500L), ")"),
    "  ts = pampa_parse_ts(text)",
    "  if (has_error_diagnostics(ts)) skip(\"initial parse produced error diagnostics\")",
    "  rendered = to_qmd(ts)",
    "  ts2 = pampa_parse_ts(rendered)",
    "  expect_no_error_diagnostics(ts2)",
    "  expect_ts_kind_equal(ts2, ts)"
  ))
}

gen_pd_rt_test = function(rel, skip_map = list()) {
  gen_test_block(rel, skip_map, c(
    "  skip_if_no_quarto_web()",
    paste0("  text = quarto_web_read(", deparse(rel, width.cutoff = 500L), ")"),
    "  pd = pampa_parse_pd(text)",
    "  if (has_error_diagnostics(pd)) skip(\"initial parse produced error diagnostics\")",
    "  rendered = to_qmd(pd)",
    "  pd2 = pampa_parse_pd(rendered)",
    "  expect_no_error_diagnostics(pd2)",
    "  expect_pd_ast_equal(pd2, pd)"
  ))
}

gen_pampa_ts_rt_test = function(rel, skip_map = list()) {
  gen_test_block(rel, skip_map, c(
    "  skip_if_no_quarto_web()",
    paste0("  text = quarto_web_read(", deparse(rel, width.cutoff = 500L), ")"),
    "  ts = pampa_parse_ts(text)",
    "  if (has_error_diagnostics(ts)) skip(\"initial parse produced error diagnostics\")",
    "  rendered = pampa_to_qmd(ts)",
    "  ts2 = pampa_parse_ts(rendered)",
    "  expect_no_error_diagnostics(ts2)",
    "  expect_ts_kind_equal(ts2, ts)"
  ))
}

gen_pampa_pd_rt_test = function(rel, skip_map = list()) {
  gen_test_block(rel, skip_map, c(
    "  skip_if_no_quarto_web()",
    paste0("  text = quarto_web_read(", deparse(rel, width.cutoff = 500L), ")"),
    "  pd = pampa_parse_pd(text)",
    "  if (has_error_diagnostics(pd)) skip(\"initial parse produced error diagnostics\")",
    "  rendered = pampa_to_qmd(pd)",
    "  pd2 = pampa_parse_pd(rendered)",
    "  expect_no_error_diagnostics(pd2)",
    "  expect_pd_ast_equal(pd2, pd)"
  ))
}
