# q2 914f2069 (f1c659f2) diagnoses a shortcode delimiter written without its
# separating space as Q-2-52 and marks the code as desynchronizing: the parse
# error table now carries per-case regex guards plus a per-code flag that drops
# every diagnostic after the first such error and appends a "not reported" hint
# to the last one kept. q2r passes the resulting DiagnosticMessage through
# unchanged, so this pins the shape that reaches @diagnostics.

tight = c(
  open  = "Click the {{<fa plus >}} icon.\n",
  close = "Click the {{< fa plus>}} icon.\n",
  both  = "Click the {{<fa plus>}} icon.\n"
)

test_that("a tight shortcode delimiter is a single Q-2-52 error", {
  for (nm in names(tight)) {
    pd = parse_qmd(tight[[nm]], quiet = TRUE)
    expect_true(has_error_diagnostics(pd))
    expect_length(pd@diagnostics, 1L)
    expect_identical(pd@diagnostics[[1]]@code, "Q-2-52")
  }
  expect_error(parse_qmd(tight[["both"]]), class = "q2r_parse_error")
})

test_that("diagnostics after a desynchronizing error are dropped with a hint", {
  pd = parse_qmd(paste0(tight[["both"]], "\n::: {.foo}\nx\n:::\n"), quiet = TRUE)
  expect_length(pd@diagnostics, 1L)
  d = pd@diagnostics[[1]]
  expect_identical(d@code, "Q-2-52")
  expect_match(d@hints[length(d@hints)], "not reported", fixed = TRUE)
  expect_match(format(d, color = FALSE), "not reported", fixed = TRUE)
})

test_that("a correctly spaced shortcode is unaffected", {
  pd = parse_qmd("Click the {{< fa plus >}} icon.\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_length(pd@diagnostics, 0L)
})
