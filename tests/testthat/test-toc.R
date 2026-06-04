test_that("ast_toc builds a nested bullet list of heading links", {
  doc = parse_qmd("# A\n\n## B\n\ntext\n\n# C\n")
  toc = ast_toc(doc)
  expect_s7_class(toc, pandoc_bullet_list)
  qmd = to_qmd(pandoc(blocks = pandoc_blocks(list(toc))))
  expect_true(grepl("[A](#a)", qmd, fixed = TRUE))
  expect_true(grepl("[B](#b)", qmd, fixed = TRUE))
  expect_true(grepl("[C](#c)", qmd, fixed = TRUE))
})

test_that("ast_toc honours explicit ids and respects max_level", {
  doc = parse_qmd("# Alpha\n\n## Beta\n\n### Deep\n\n# Gamma {#sec-g}\n")
  qmd = to_qmd(pandoc(blocks = pandoc_blocks(list(ast_toc(doc, max_level = 2L)))))
  expect_true(grepl("#sec-g", qmd, fixed = TRUE))
  expect_false(grepl("Deep", qmd))
  expect_true(grepl("Beta", qmd))
})

test_that("ast_toc on a headingless document is an empty bullet list", {
  toc = ast_toc(parse_qmd("just text\n"))
  expect_s7_class(toc, pandoc_bullet_list)
  expect_length(toc@content, 0L)
})

test_that("split_sections partitions at the given heading level", {
  doc = parse_qmd("intro\n\n# Alpha\n\na\n\n## Beta\n\nb\n\n# Gamma\n\ng\n")
  parts = split_sections(doc, level = 1L)
  expect_named(parts, c("", "Alpha", "Gamma"))
  expect_true(all(purrr::map_lgl(parts, S7::S7_inherits, pandoc)))
  expect_true(grepl("intro", to_qmd(parts[[1]])))
  expect_true(grepl("Beta", to_qmd(parts[["Alpha"]])))
})

test_that("split_sections without a boundary returns the whole document", {
  doc = parse_qmd("# only h1\n\nbody\n")
  parts = split_sections(doc, level = 2L)
  expect_length(parts, 1L)
  expect_true(grepl("only h1", to_qmd(parts[[1]])))
})

test_that("split_sections with no leading preamble omits the empty group", {
  doc = parse_qmd("# A\n\na\n\n# B\n\nb\n")
  parts = split_sections(doc, level = 1L)
  expect_named(parts, c("A", "B"))
})

test_that("split_sections on an empty document is an empty list", {
  expect_equal(split_sections(parse_qmd("")), stats::setNames(list(), character()))
})
