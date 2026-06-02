test_that("has_text matches a node's flattened text (regex)", {
  doc = parse_qmd("# Exercise 1\n\nsome body\n\n# Solution\n\nmore\n")
  hits = select_nodes(doc, is(pandoc_header) & has_text("Exercise"))
  expect_length(hits, 1L)
  expect_equal(ast_text(hits[[1]]), "Exercise 1")
})

test_that("has_text supports fixed matching and multiple patterns", {
  doc = parse_qmd("# A.b\n\ntext\n\n# Other\n\nx\n")
  expect_length(select_nodes(doc, is(pandoc_header) & has_text("A.b", fixed = TRUE)), 1L)
  expect_length(select_nodes(doc, is(pandoc_header) & has_text(c("A\\.b", "Other"))), 2L)
})

test_that("has_text is a no-match (not an error) on textless nodes", {
  doc = parse_qmd("# H\n\ntext\n")
  expect_silent(res <- select_nodes(doc, has_text("zzz")))
  expect_length(res, 0L)
})

test_that("has_label glob-matches the node id", {
  doc = parse_qmd("# Intro {#sec-intro}\n\n![](a.png){#fig-one}\n\n## Other {#sec-two}\n")
  expect_length(select_nodes(doc, has_label("sec-*")), 2L)
  expect_length(select_nodes(doc, has_label("fig-one")), 1L)
  expect_length(select_nodes(doc, has_label("nope-*")), 0L)
})

test_that("has_label is a no-match on nodes without an id", {
  doc = parse_qmd("plain paragraph\n")
  expect_length(select_nodes(doc, has_label("*")), 0L)
})
