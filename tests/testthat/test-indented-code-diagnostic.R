# q2 72c8cae43 (v0.42.0) renumbers the "Indented code blocks are not
# supported" parse error from Q-2-35 to Q-2-59. Q-2-35 was shared with the
# desugar-time "Invalid List-Table Structure" warning, which keeps the code.

test_that("a 4-space indented block is Q-2-59", {
  for (src in c("Before.\n\n    foo\n\nAfter.\n", "Before.\n\n\tfoo\n\nAfter.\n")) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_true(has_error_diagnostics(pd))
    expect_length(pd@diagnostics, 1L)
    d = pd@diagnostics[[1]]
    expect_identical(d@code, "Q-2-59")
    expect_identical(d@kind, "error")
    expect_identical(d@title, "Indented code blocks are not supported")
    expect_identical(d@location$start_row, 3L)
    expect_identical(d@location$start_column, 1L)
    expect_match(format(d, color = FALSE), "[Q-2-59]", fixed = TRUE)
  }
})

test_that("a 3-space indent is still a paragraph", {
  pd = parse_qmd("Before.\n\n   foo\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_length(pd@blocks@content, 2L)
  expect_true(S7::S7_inherits(pd@blocks@content[[2]], pandoc_paragraph))
})

test_that("an invalid list-table structure keeps Q-2-35", {
  pd = parse_qmd("::: {.list-table}\n\n* * a\n  * b\n\ntrailing\n\n:::\n", quiet = TRUE)
  codes = purrr::map_chr(pd@diagnostics, \(d) d@code)
  expect_identical(codes, "Q-2-35")
  expect_identical(pd@diagnostics[[1]]@kind, "warning")
  expect_identical(pd@diagnostics[[1]]@title, "Invalid List-Table Structure")
})
