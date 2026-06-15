test_that("simple frontmatter round-trips through to_qmd", {
  src = "---\ntitle: My Doc\nauthor: Jane\n---\n\nHello world.\n"
  expect_identical(to_qmd(parse_qmd(src)), src)
})

test_that("frontmatter value types round-trip at the AST level", {
  src = paste(
    "---", "toc-depth: 3", "fig-width: 6.5", "draft: true",
    "tags:", "  - a", "  - b",
    "format:", "  html:", "    toc: true",
    "---", "", "Body.", "",
    sep = "\n"
  )
  pd1 = parse_qmd(src)
  pd2 = parse_qmd(to_qmd(pd1))
  expect_identical(q2r:::pandoc_to_list(pd1), q2r:::pandoc_to_list(pd2))
})

test_that("meta is exposed as an inspectable pandoc_meta_value tree", {
  pd = parse_qmd("---\ntitle: My Doc\ncount: 5\nratio: 1.5\nflag: true\n---\n\nx\n")
  expect_equal(pd@meta@kind, "map")
  expect_equal(names(pd@meta@value), c("title", "count", "ratio", "flag"))
  # The reader parses string-valued metadata fields as markdown inlines.
  expect_equal(pd@meta@value$title@kind, "inlines")
  expect_equal(ast_text(pd@meta@value$title@value), "My Doc")
  expect_equal(pd@meta@value$count@kind, "int")
  expect_equal(pd@meta@value$count@value, 5)
  expect_equal(pd@meta@value$ratio@kind, "real")
  expect_equal(pd@meta@value$ratio@value, 1.5)
  expect_equal(pd@meta@value$flag@kind, "bool")
  expect_true(pd@meta@value$flag@value)
})

test_that("nested map and sequence meta round-trip", {
  src = "---\nformat:\n  html:\n    toc: true\n    number-sections: false\n---\n\nx\n"
  pd1 = parse_qmd(src)
  fmt = pd1@meta@value$format
  expect_equal(fmt@kind, "map")
  expect_true(fmt@value$html@value$toc@value)
  pd2 = parse_qmd(to_qmd(pd1))
  expect_identical(q2r:::pandoc_to_list(pd1), q2r:::pandoc_to_list(pd2))
})

test_that("a document without frontmatter has empty-map meta", {
  pd = parse_qmd("Just a paragraph.\n")
  expect_equal(pd@meta@kind, "map")
  expect_length(pd@meta@value, 0L)
  expect_identical(to_qmd(pd), "Just a paragraph.\n")
})

test_that("whole-number YAML reals re-parse as integers (known limitation)", {
  # A real written with an explicit `.0` and no fractional part (e.g. 1.0)
  # is reconstructed as Yaml::Real("1") and re-parses as an integer: the
  # value survives but the int/real distinction does not. See CLAUDE.md.
  pd1 = parse_qmd("---\nversion: 1.0\n---\n\nx\n")
  expect_equal(pd1@meta@value$version@kind, "real")
  pd2 = parse_qmd(to_qmd(pd1))
  expect_equal(pd2@meta@value$version@kind, "int")
})
