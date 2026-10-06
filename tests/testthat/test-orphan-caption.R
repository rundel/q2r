# q2 4753b6a2 (c90ee9202) keeps a caption line that has no table to attach to.
# postprocess.rs used to drop the CaptionBlock with a warning; it now emits a
# paragraph holding the verbatim source line as a single Str. Directly after a
# paragraph (the shape of a Pandoc definition list, which q2 does not support)
# the warning is the new Q-2-54 with three hints; after any other block it
# stays the uncoded "Caption found without a preceding table" (Q-0-99). q2r
# passes both the AST and the DiagnosticMessage through unchanged.

literal_line = function(block) {
  expect_s7_class(block, pandoc_paragraph)
  expect_length(block@content, 1L)
  expect_s7_class(block@content[[1]], pandoc_str)
  block@content[[1]]@text
}

diag_codes = function(pd) purrr::map_chr(pd@diagnostics, function(d) d@code)

test_that("a definition line after a term is a literal paragraph with Q-2-54", {
  src = "time\n\n: A timestamp.\n\n: Type: string\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_length(pd@blocks, 3L)
  expect_identical(literal_line(pd@blocks[[2]]), ": A timestamp.")
  expect_identical(literal_line(pd@blocks[[3]]), ": Type: string")

  expect_identical(diag_codes(pd), c("Q-2-54", "Q-2-54"))
  expect_identical(
    purrr::map_int(pd@diagnostics, function(d) d@location$start_row),
    c(3L, 5L)
  )
  d = pd@diagnostics[[1]]
  expect_identical(d@kind, "warning")
  expect_identical(d@title, "Pandoc definition lists are not supported")
  expect_length(d@hints, 3L)
  expect_match(d@hints[1], "::: {.definition-list}", fixed = TRUE)
  expect_match(d@hints[2], "\\:", fixed = TRUE)
  expect_match(d@hints[3], "qmd-syntax-helper convert -r definition-lists", fixed = TRUE)
  expect_match(format(d, color = FALSE), "literal text instead of a definition", fixed = TRUE)
  expect_warning(parse_qmd(src), class = "q2r_parse_warning")

  expect_identical(to_qmd(pd), src)
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})

test_that("the literal line keeps its spacing and trailing attribute", {
  pd = parse_qmd("Term\n:   A tight definition {#tbl-x}\n", quiet = TRUE)
  expect_length(pd@blocks, 2L)
  expect_identical(literal_line(pd@blocks[[2]]), ":   A tight definition {#tbl-x}")
  expect_identical(diag_codes(pd), "Q-2-54")
})

test_that("a list split off a definition body stays literal", {
  pd = parse_qmd(
    "`type`\n\n: Set to one of the following\n: - `current` - A current.\n  - `archived` - An archived.\n",
    quiet = TRUE
  )
  expect_length(pd@blocks, 4L)
  expect_identical(literal_line(pd@blocks[[2]]), ": Set to one of the following")
  expect_identical(literal_line(pd@blocks[[3]]), ": - `current` - A current.")
  expect_identical(literal_line(pd@blocks[[4]]), "  - `archived` - An archived.")
  expect_identical(diag_codes(pd), c("Q-2-54", "Q-2-54"))
})

test_that("a caption after a non-paragraph block keeps the generic warning", {
  srcs = c(
    div     = "::: {.my-div}\nSome content\n:::\n\n: This caption has no table\n",
    heading = "# Head\n\n: This caption has no table\n"
  )
  for (nm in names(srcs)) {
    pd = parse_qmd(srcs[[nm]], quiet = TRUE)
    expect_no_error_diagnostics(pd)
    expect_length(pd@blocks, 2L)
    expect_identical(literal_line(pd@blocks[[2]]), ": This caption has no table")
    expect_identical(diag_codes(pd), "Q-0-99")
    expect_match(
      pd@diagnostics[[1]]@title, "Caption found without a preceding table", fixed = TRUE
    )
    expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
  }
})

test_that("a caption under a table still attaches", {
  pd = parse_qmd("| a |\n|---|\n| 1 |\n\n: A real caption\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_length(pd@blocks, 1L)
  expect_s7_class(pd@blocks[[1]], pandoc_table)
  expect_identical(ast_text(pd@blocks[[1]]@caption), "A real caption")
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})

test_that("an escaped colon is ordinary paragraph text", {
  pd = parse_qmd("Term\n\n\\: not a definition\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_length(pd@blocks, 2L)
  expect_length(pd@blocks[[2]]@content, 7L)
  expect_identical(pd@blocks[[2]]@content[[1]]@text, ":")
})
