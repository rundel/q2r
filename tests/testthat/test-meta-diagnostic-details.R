# Q-1-20 (a metadata value that fails to parse as markdown) folds the child
# parse's diagnostics in as located details since q2 596ceb57 (bd-mxa44voa
# provenance series), rerooted through the parent span. It is the one
# diagnostic shape with per-detail locations that reaches diag_to_r, so this
# pins both the structured @details records and the ariadne render through
# pampa_diag_format_impl (see Known risks in CLAUDE.md).

test_that("Q-1-20 carries the child diagnostic as a located detail", {
  pd = parse_qmd("---\ntitle: _brand.yml\n---\n\nx\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_length(pd@diagnostics, 1L)
  d = pd@diagnostics[[1]]
  expect_identical(d@kind, "warning")
  expect_identical(d@code, "Q-1-20")
  located = purrr::keep(d@details, function(x) !is.null(x$location))
  expect_gte(length(located), 1L)
  expect_true(all(purrr::map_int(located, function(x) x$location$start_row) == 2L))
  expect_true(all(purrr::map_chr(d@details, function(x) x$kind) == "info"))

  text = format(d, color = FALSE)
  expect_match(text, "Could not parse '_brand.yml' as markdown", fixed = TRUE)
  expect_match(text, "closing '_'", fixed = TRUE)
  expect_match(text, "Q-2-5", fixed = TRUE)
  expect_match(text, "<text>:2:", fixed = TRUE)
})

test_that("the document still parses and keeps the unparsed value", {
  pd = parse_qmd("---\ntitle: \"a {b\"\n---\n\nx\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(pd@diagnostics[[1]]@code, "Q-1-20")
  expect_identical(pd@meta@value$title@kind, "inlines")
  expect_identical(ast_text(pd@meta@value$title@value), "a {b")
  expect_identical(ast_text(pd), "x")
})
