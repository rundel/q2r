# The `_quarto.tests.**` front-matter subtree is annotated PlainString upstream
# since q2 c79cadf91 (bd-quarto-tests-metadata-markdown-3wsdzq4c): the smoke-test
# harness's assertion strings (regex patterns such as `"<fig-cars>"`) arrive as
# `string` scalars instead of markdown `inlines`, so a bracket-label pattern no
# longer reads as an HTML tag and an underscore-bearing pattern no longer trips
# Q-1-20. A sibling `_quarto` key and a nested `my._quarto.tests` still parse as
# markdown.

test_that("_quarto.tests assertion strings are plain and raise no diagnostics", {
  src = paste(
    "---", "_quarto:", "  tests:", "    html:",
    "      ensureFileRegexMatches:", "        - \"<fig-cars>\"", "        - _x",
    "    typst:", "      ensureTypstFileRegexMatches: \"#figure\\\\(\"",
    "---", "", "x", "",
    sep = "\n"
  )
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  tests = pd@meta@value$`_quarto`@value$tests
  expect_identical(tests@kind, "map")
  html = tests@value$html@value$ensureFileRegexMatches
  expect_identical(html@kind, "list")
  expect_identical(purrr::map_chr(html@value, function(v) v@kind), c("string", "string"))
  expect_identical(purrr::map_chr(html@value, function(v) v@value), c("<fig-cars>", "_x"))
  typst = tests@value$typst@value$ensureTypstFileRegexMatches
  expect_identical(typst@kind, "string")
  expect_identical(typst@value, "#figure\\(")
  expect_identical(parse_qmd(to_qmd(pd), quiet = TRUE)@meta, pd@meta)
})

test_that("a sibling _quarto key and a nested my._quarto.tests still parse as markdown", {
  src = paste(
    "---", "_quarto:", "  render-project: _p", "  tests:", "    html: _t",
    "my:", "  _quarto:", "    tests: _m",
    "---", "", "x", "",
    sep = "\n"
  )
  pd = parse_qmd(src, quiet = TRUE)
  q = pd@meta@value$`_quarto`
  expect_identical(q@value$`render-project`@kind, "inlines")
  expect_identical(q@value$tests@value$html@kind, "string")
  expect_identical(q@value$tests@value$html@value, "_t")
  expect_identical(pd@meta@value$my@value$`_quarto`@value$tests@kind, "inlines")
  expect_identical(purrr::map_chr(pd@diagnostics, function(d) d@code), c("Q-1-20", "Q-1-20"))
  expect_identical(parse_qmd(to_qmd(pd), quiet = TRUE)@meta, pd@meta)
})
