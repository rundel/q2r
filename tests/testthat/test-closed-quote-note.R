# q2 4753b6a2 (5ad29d43e, bd-hsb5fext) rewords the note on Q-2-10 (closing
# quote without a matching open quote). It used to say "This is the opening
# quote" even for a stray closing mark such as a plural possessive; it now says
# no opening quote was found. Q-2-7 (a genuinely unclosed quote) keeps the old
# wording. The note reaches R as the diagnostic's first `@details` entry.

detail_text = function(d) d@details[[1]]$content$text

test_that("the Q-2-10 note says no opening quote was found", {
  pd = parse_qmd("the users' guide\n", quiet = TRUE)
  expect_length(pd@diagnostics, 1L)
  d = pd@diagnostics[[1]]
  expect_identical(d@code, "Q-2-10")
  expect_identical(
    detail_text(d),
    "No opening quote was found before this mark. If you meant an apostrophe, escape it with a backslash."
  )
  expect_match(format(d, color = FALSE), "No opening quote was found before this mark", fixed = TRUE)
})

test_that("the Q-2-7 note keeps its opening-quote wording", {
  pd = parse_qmd("a 'more\n", quiet = TRUE)
  expect_length(pd@diagnostics, 1L)
  d = pd@diagnostics[[1]]
  expect_identical(d@code, "Q-2-7")
  expect_identical(
    detail_text(d),
    "This is the opening quote. If you need an apostrophe, escape it with a backslash."
  )
})

test_that("an escaped apostrophe raises nothing", {
  pd = parse_qmd("the users\\' guide\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
})
