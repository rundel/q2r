quarto_web_run = function(label, path_id, fn) {
  skip_if_no_quarto_web()
  files = quarto_web_files()
  res = run_roundtrip(files, path_id, fn)
  roundtrip_report(label, res)
  testthat::expect_equal(length(res$failures) + length(res$errors), 0L)
}

parse_or_skip_ts = function(text) {
  ts = pampa_parse_ts(text)
  if (has_error_diagnostics(ts)) return(NULL)
  ts
}

parse_or_skip_pd = function(text) {
  pd = pampa_parse_pd(text)
  if (has_error_diagnostics(pd)) return(NULL)
  pd
}

test_that("ts round-trip: text -> parse_ts -> to_qmd -> parse_ts matches kind tree", {
  quarto_web_run("ts_rt", "ts_rt", function(text, f) {
    ts = parse_or_skip_ts(text)
    if (is.null(ts)) return(list(skip = TRUE))
    rendered = to_qmd(ts)
    ts2 = pampa_parse_ts(rendered)
    if (has_error_diagnostics(ts2)) {
      return(list(ok = FALSE, reason = "re-parse produced error diagnostics"))
    }
    list(ok = compare_ts_kind(ts, ts2), reason = "ts kind tree mismatch")
  })
})

test_that("pd round-trip: text -> parse_pd -> to_qmd -> parse_pd matches native", {
  quarto_web_run("pd_rt", "pd_rt", function(text, f) {
    pd = parse_or_skip_pd(text)
    if (is.null(pd)) return(list(skip = TRUE))
    rendered = to_qmd(pd)
    pd2 = pampa_parse_pd(rendered)
    if (has_error_diagnostics(pd2)) {
      return(list(ok = FALSE, reason = "re-parse produced error diagnostics"))
    }
    list(ok = compare_pd_native(text, rendered), reason = "pd native mismatch")
  })
})

test_that("pampa-ts round-trip: text -> parse_ts -> pampa_to_qmd(ts) -> parse_pd matches native", {
  quarto_web_run("pampa_ts_rt", "pampa_ts_rt", function(text, f) {
    ts = parse_or_skip_ts(text)
    if (is.null(ts)) return(list(skip = TRUE))
    rendered = pampa_to_qmd(ts)
    pd2 = pampa_parse_pd(rendered)
    if (has_error_diagnostics(pd2)) {
      return(list(ok = FALSE, reason = "re-parse produced error diagnostics"))
    }
    list(ok = compare_pd_native(text, rendered), reason = "pd native mismatch")
  })
})

test_that("pampa-pd round-trip: text -> parse_pd -> pampa_to_qmd(pd) -> parse_pd matches native", {
  quarto_web_run("pampa_pd_rt", "pampa_pd_rt", function(text, f) {
    pd = parse_or_skip_pd(text)
    if (is.null(pd)) return(list(skip = TRUE))
    rendered = pampa_to_qmd(pd)
    pd2 = pampa_parse_pd(rendered)
    if (has_error_diagnostics(pd2)) {
      return(list(ok = FALSE, reason = "re-parse produced error diagnostics"))
    }
    list(ok = compare_pd_native(text, rendered), reason = "pd native mismatch")
  })
})
