test_that("ast_summary returns one row per top-level block with expected columns", {
  doc = parse_qmd("# Title {#sec-a}\n\nbody text\n\n## Sub\n\nmore\n")
  s = ast_summary(doc)
  expect_s3_class(s, "data.frame")
  expect_equal(nrow(s), length(doc@blocks@content))
  expect_equal(names(s), c("type", "level", "id", "section", "text", "node"))
  expect_equal(s$type[1], "pandoc_header")
  expect_equal(s$level[1], 1L)
  expect_true(is.na(s$level[2]))
  expect_equal(s$id[1], "sec-a")
  expect_equal(s$section[3], "Sub")
})

test_that("the node column holds the live S7 objects and pipes back through verbs", {
  doc = parse_qmd("# H\n\ntext\n")
  s = ast_summary(doc)
  expect_true(S7::S7_inherits(s$node[[1]], pandoc_header))
  headers = s$node[s$type == "pandoc_header"]
  expect_length(headers, 1L)
  # a filtered node list can be fed to a downstream verb
  expect_length(select_nodes(headers, is(pandoc_header) & has_text("H")), 1L)
})

test_that("ast_summary prints without error and truncates text", {
  doc = parse_qmd(paste0("para with a very long line of text that exceeds the preview width here\n"))
  s = ast_summary(doc, max_text = 20L)
  expect_true(nchar(s$text[1]) <= 20L)
  expect_output(print(s))
})

test_that("ast_summary on an empty document has zero rows", {
  s = ast_summary(parse_qmd(""))
  expect_equal(nrow(s), 0L)
  expect_equal(names(s), c("type", "level", "id", "section", "text", "node"))
})
