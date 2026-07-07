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

test_that("ast_toc nests subheadings under their parent and keeps siblings flat", {
  toc = ast_toc(parse_qmd("# A\n\n## B\n\ntext\n\n# C\n"))
  expect_length(toc@content, 2L)
  # A's item carries a nested bullet list (holding B) as its second block
  expect_s7_class(toc@content[[1]]@content[[2]], pandoc_bullet_list)
  # C is a flat sibling: a link only, with no nested list
  expect_length(toc@content[[2]]@content, 1L)
})

test_that("ast_toc on a headingless document is an empty bullet list", {
  toc = ast_toc(parse_qmd("just text\n"))
  expect_s7_class(toc, pandoc_bullet_list)
  expect_length(toc@content, 0L)
})

test_that("pandoc_slug approximates Pandoc's auto-identifier algorithm", {
  slug = q2r:::pandoc_slug
  expect_equal(slug("123 Leading Number"), "leading-number")  # drop leading digits
  expect_equal(slug("Section 2.1"), "section-2.1")            # keep the dot
  expect_equal(slug("Hello, World!"), "hello-world")          # comma + ! dropped
  expect_equal(slug("Trailing -"), "trailing")               # drop trailing hyphen
  expect_equal(slug("!!!"), "section")                       # empty -> fallback
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

test_that("split_sections names follow heading text and may repeat", {
  parts = split_sections(parse_qmd("# A\n\nx\n\n# A\n\ny\n"), level = 1L)
  expect_named(parts, c("A", "A"))
  expect_length(parts, 2L)
  # `parts[["A"]]` silently picks the first; index by position to disambiguate
  expect_true(grepl("x", to_qmd(parts[[1]])))
  expect_true(grepl("y", to_qmd(parts[[2]])))
})

test_that("split_sections carries the document meta into every part", {
  doc = parse_qmd("---\ntitle: My Doc\n---\n\nintro\n\n# A\n\na\n")
  parts = split_sections(doc, level = 1)
  expect_length(parts, 2L)
  for (p in parts) {
    expect_match(to_qmd(p), "title:", fixed = TRUE)
  }
})

test_that("split_sections validates level", {
  doc = parse_qmd("# A\n\na\n")
  expect_error(split_sections(doc, level = c(1, 2)), "single heading level")
  expect_error(split_sections(doc, level = "x"), "single heading level")
})

test_that("pandoc_slug keeps unicode letters", {
  expect_identical(q2r:::pandoc_slug("Résumé"), "résumé")
  expect_identical(q2r:::pandoc_slug("日本語 heading"), "日本語-heading")
  expect_identical(q2r:::pandoc_slug("123!!"), "section")
})
