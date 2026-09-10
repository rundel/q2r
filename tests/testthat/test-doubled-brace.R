# Q-2-50 (Quarto 1's doubled-brace fence escape) fires on a top-level opener
# since q2 fdf55e77 and, as of 914f2069 (92002cb8), also on an opener nested
# inside a display fence, located on the nested line. It is a warning, so the
# document still parses.

test_that("a doubled-brace opener nested in a display fence warns with Q-2-50", {
  src = "````markdown\n```{{python}}\n1 + 1\n```\n````\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_length(pd@diagnostics, 1L)
  d = pd@diagnostics[[1]]
  expect_identical(d@kind, "warning")
  expect_identical(d@code, "Q-2-50")
  expect_match(format(d, color = FALSE), "<text>:2:1", fixed = TRUE)
  expect_warning(parse_qmd(src), class = "q2r_parse_warning")
})

test_that("a top-level doubled-brace opener still warns with Q-2-50", {
  pd = parse_qmd("```{{python}}\n1 + 1\n```\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(pd@diagnostics[[1]]@code, "Q-2-50")
})
