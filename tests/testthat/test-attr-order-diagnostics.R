# q2 4753b6a2 (6bc0b280b, bd-6hf7nz7i) gives every misordered attribute list a
# coded diagnostic. Only key-value-before-class had one (Q-2-3); class before
# identifier and key-value before identifier fell through to the uncoded
# "Parse error" and are now Q-2-55 and Q-2-56. All three also carry a hint
# built from the author's own text with the whole list reordered (identifier,
# classes, key-value pairs). A list with two identifiers fails in the same
# parser state but is not an ordering problem, so it stays a generic error.

shapes = list(
  list(attr = "{.c #i}",  code = "Q-2-55", fix = "`{#i .c}`"),
  list(attr = "{k=v #i}", code = "Q-2-56", fix = "`{#i k=v}`"),
  list(attr = "{k=v .c}", code = "Q-2-3",  fix = "`{.c k=v}`")
)

constructs = c(
  span    = "[x]ATTR\n",
  image   = "![alt](img.png)ATTR\n",
  heading = "# H ATTR\n",
  div     = "::: ATTR\nx\n:::\n",
  code    = "```ATTR\nx\n```\n"
)

test_that("each attribute inversion has its own code and a reorder hint", {
  for (construct in constructs) {
    for (shape in shapes) {
      pd = parse_qmd(sub("ATTR", shape$attr, construct, fixed = TRUE), quiet = TRUE)
      expect_true(has_error_diagnostics(pd))
      expect_length(pd@diagnostics, 1L)
      d = pd@diagnostics[[1]]
      expect_identical(d@kind, "error")
      expect_identical(d@code, shape$code)
      expect_length(d@hints, 1L)
      expect_match(d@hints, "Reorder the attributes as", fixed = TRUE)
      expect_match(d@hints, shape$fix, fixed = TRUE)
    }
  }
})

test_that("the hint reorders the author's whole list at once", {
  pd = parse_qmd("::: {.callout-tip #tip-alignment}\nx\n:::\n", quiet = TRUE)
  d = pd@diagnostics[[1]]
  expect_identical(d@code, "Q-2-55")
  expect_identical(d@title, "Class Specifier Before Identifier in Attribute")
  expect_match(d@hints, "`{#tip-alignment .callout-tip}`", fixed = TRUE)
  expect_match(format(d, color = FALSE), "`{#tip-alignment .callout-tip}`", fixed = TRUE)

  pd = parse_qmd("[x]{k=v .c #i}\n", quiet = TRUE)
  expect_match(pd@diagnostics[[1]]@hints, "`{#i .c k=v}`", fixed = TRUE)
  expect_error(parse_qmd("[x]{k=v .c #i}\n"), class = "q2r_parse_error")
})

test_that("a second identifier is not reported as an ordering problem", {
  pd = parse_qmd("[x]{#a #b}\n", quiet = TRUE)
  expect_true(has_error_diagnostics(pd))
  expect_length(pd@diagnostics, 1L)
  d = pd@diagnostics[[1]]
  expect_identical(d@code, NA_character_)
  expect_identical(d@title, "Parse error")
  expect_length(d@hints, 0L)
})

test_that("a correctly ordered attribute list is unaffected", {
  pd = parse_qmd("[x]{#i .c k=v}\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  attr = pd@blocks[[1]]@content[[1]]@attr
  expect_identical(attr@id, "i")
  expect_identical(attr@classes, "c")
  expect_identical(attr@attributes, c(k = "v"))
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})
