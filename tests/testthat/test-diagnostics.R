bad_qmd = ":::: {"

test_that("parse_qmd(ast = 'pd') raises an error by default on bad input", {
  expect_error(parse_qmd(bad_qmd), "Parse error")
})

test_that("parse_qmd(ast = 'ts') raises an error by default on bad input", {
  expect_error(parse_qmd(bad_qmd, ast = "ts"), "Parse error")
})

test_that("parse_qmd(ast = 'pd', quiet = TRUE) returns silently with diagnostics attached", {
  res = expect_no_condition(parse_qmd(bad_qmd, quiet = TRUE))
  expect_true(S7::S7_inherits(res, pandoc))
  expect_gt(length(res@diagnostics), 0L)
  expect_true(any(vapply(res@diagnostics, function(d) d@kind == "error", logical(1L))))
})

test_that("parse_qmd(ast = 'ts', quiet = TRUE) returns silently with diagnostics attached", {
  res = expect_no_condition(parse_qmd(bad_qmd, quiet = TRUE, ast = "ts"))
  expect_true(S7::S7_inherits(res, ts_tree))
  expect_gt(length(res@diagnostics), 0L)
  expect_true(any(vapply(res@diagnostics, function(d) d@kind == "error", logical(1L))))
})

test_that("clean input does not signal a condition under either default", {
  expect_no_condition(parse_qmd("# hi"))
  expect_no_condition(parse_qmd("# hi", ast = "ts"))
  expect_no_condition(parse_qmd("# hi", quiet = TRUE))
  expect_no_condition(parse_qmd("# hi", quiet = TRUE, ast = "ts"))
})

test_that("parse_qmd error message includes the rendered diagnostic text", {
  err = tryCatch(parse_qmd(bad_qmd), error = identity)
  expect_s3_class(err, "error")
  expect_match(conditionMessage(err), "unexpected character or token", fixed = TRUE)
})

mk_diag = function(kind, title = "x") {
  q2r:::pampa_diagnostic(
    kind            = kind,
    title           = title,
    source_text     = "x",
    source_filename = "<text>"
  )
}

test_that("pampa_signal_diagnostics() is a no-op on empty input", {
  expect_no_condition(q2r:::pampa_signal_diagnostics(list()))
  expect_no_condition(q2r:::pampa_signal_diagnostics(list(), quiet = TRUE))
})

test_that("pampa_signal_diagnostics() raises stop() for error-kind", {
  expect_error(
    q2r:::pampa_signal_diagnostics(list(mk_diag("error", "boom"))),
    "boom"
  )
})

test_that("pampa_signal_diagnostics() raises warning() for warning-kind", {
  expect_warning(
    q2r:::pampa_signal_diagnostics(list(mk_diag("warning", "careful"))),
    "careful"
  )
})

test_that("pampa_signal_diagnostics() raises both warning and error when both present", {
  diags = list(mk_diag("warning", "careful"), mk_diag("error", "boom"))
  expect_warning(
    expect_error(q2r:::pampa_signal_diagnostics(diags), "boom"),
    "careful"
  )
})

test_that("pampa_signal_diagnostics() is silent for info / note kinds", {
  expect_no_condition(
    q2r:::pampa_signal_diagnostics(list(mk_diag("info"), mk_diag("note")))
  )
})

test_that("pampa_signal_diagnostics(quiet = TRUE) suppresses both warnings and errors", {
  diags = list(mk_diag("warning", "careful"), mk_diag("error", "boom"))
  expect_no_condition(q2r:::pampa_signal_diagnostics(diags, quiet = TRUE))
})

catch_signals = function(expr) {
  warns = character()
  err = NULL
  withCallingHandlers(
    tryCatch(expr, error = function(e) { err <<- e; invisible() }),
    warning = function(w) {
      warns <<- c(warns, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(warnings = warns, error = err)
}

test_that("multiple errors are coalesced into a single stop() carrying all messages", {
  diags = list(mk_diag("error", "E1"), mk_diag("error", "E2"), mk_diag("error", "E3"))
  caught = catch_signals(q2r:::pampa_signal_diagnostics(diags))
  expect_length(caught$warnings, 0L)
  expect_s3_class(caught$error, "error")
  msg = conditionMessage(caught$error)
  expect_match(msg, "E1", fixed = TRUE)
  expect_match(msg, "E2", fixed = TRUE)
  expect_match(msg, "E3", fixed = TRUE)
})

test_that("multiple warnings are coalesced into a single warning() carrying all messages", {
  diags = list(mk_diag("warning", "W1"), mk_diag("warning", "W2"), mk_diag("warning", "W3"))
  caught = catch_signals(q2r:::pampa_signal_diagnostics(diags))
  expect_null(caught$error)
  expect_length(caught$warnings, 1L)
  expect_match(caught$warnings, "W1", fixed = TRUE)
  expect_match(caught$warnings, "W2", fixed = TRUE)
  expect_match(caught$warnings, "W3", fixed = TRUE)
})

test_that("mix of warnings + errors: warnings flushed first, then a single combined stop()", {
  diags = list(
    mk_diag("warning", "W1"),
    mk_diag("warning", "W2"),
    mk_diag("error",   "E1"),
    mk_diag("error",   "E2")
  )
  caught = catch_signals(q2r:::pampa_signal_diagnostics(diags))
  expect_length(caught$warnings, 1L)
  expect_match(caught$warnings, "W1", fixed = TRUE)
  expect_match(caught$warnings, "W2", fixed = TRUE)
  expect_s3_class(caught$error, "error")
  err_msg = conditionMessage(caught$error)
  expect_match(err_msg, "E1", fixed = TRUE)
  expect_match(err_msg, "E2", fixed = TRUE)
  expect_false(grepl("W1", err_msg, fixed = TRUE))
  expect_false(grepl("W2", err_msg, fixed = TRUE))
})

test_that("info / note diagnostics next to errors do not appear in the error message", {
  diags = list(
    mk_diag("info",  "I1"),
    mk_diag("note",  "N1"),
    mk_diag("error", "E1")
  )
  caught = catch_signals(q2r:::pampa_signal_diagnostics(diags))
  expect_length(caught$warnings, 0L)
  err_msg = conditionMessage(caught$error)
  expect_match(err_msg, "E1", fixed = TRUE)
  expect_false(grepl("I1", err_msg, fixed = TRUE))
  expect_false(grepl("N1", err_msg, fixed = TRUE))
})

multi_err_qmd = "{< unknown_shortcode >}\n\n{< another_shortcode >}"

test_that("parse_qmd() coalesces distinct parser errors into a single stop()", {
  res = parse_qmd(multi_err_qmd, quiet = TRUE)
  errs = Filter(function(d) d@kind == "error", res@diagnostics)
  titles = unique(vapply(errs, function(d) d@title, character(1L)))
  skip_if(length(titles) < 2L, "fixture no longer yields >=2 distinct error titles")

  caught = catch_signals(parse_qmd(multi_err_qmd))
  expect_s3_class(caught$error, "error")
  msg = conditionMessage(caught$error)
  for (t in titles) expect_match(msg, t, fixed = TRUE)
})

test_that("parse_qmd(quiet = TRUE) preserves all diagnostics when there are several", {
  res1 = parse_qmd(multi_err_qmd, quiet = TRUE)
  res2 = parse_qmd(multi_err_qmd, quiet = TRUE)
  expect_identical(length(res1@diagnostics), length(res2@diagnostics))
  expect_gte(length(res1@diagnostics), 2L)
})

test_that("prune_errors = TRUE (default) deduplicates parser-error diagnostics", {
  pruned   = parse_qmd(bad_qmd, quiet = TRUE)
  unpruned = parse_qmd(bad_qmd, quiet = TRUE, prune_errors = FALSE)
  expect_lt(length(pruned@diagnostics), length(unpruned@diagnostics))
  expect_gte(length(pruned@diagnostics), 1L)
})

test_that("prune_errors = FALSE preserves raw diagnostics for ts parser too", {
  pruned   = parse_qmd(bad_qmd, quiet = TRUE, ast = "ts")
  unpruned = parse_qmd(bad_qmd, quiet = TRUE, prune_errors = FALSE, ast = "ts")
  expect_lt(length(pruned@diagnostics), length(unpruned@diagnostics))
})

test_that("prune_errors keeps distinct errors at separate ERROR nodes", {
  res = parse_qmd(multi_err_qmd, quiet = TRUE, prune_errors = TRUE)
  titles = unique(vapply(res@diagnostics, function(d) d@title, character(1L)))
  expect_gte(length(titles), 2L)
})
