test_that("ast_sections reports the enclosing heading chain per block", {
  doc = parse_qmd("# A\n\nintro\n\n## B\n\nbody\n\n# C\n\ntail\n")
  secs = ast_sections(doc)
  expect_length(secs, length(doc@blocks@content))
  expect_equal(unname(secs[[1]]["h1"]), "A")          # the `# A` heading
  expect_equal(unname(secs[[2]]["h1"]), "A")          # intro paragraph
  expect_equal(unname(secs[[3]][c("h1", "h2")]), c("A", "B"))  # `## B`
  expect_equal(unname(secs[[4]][c("h1", "h2")]), c("A", "B"))  # body
  expect_equal(unname(secs[[5]]["h1"]), "C")          # `# C`
  expect_true(is.na(secs[[5]]["h2"]))                 # h2 reset under new h1
})

test_that("a header belongs to the section it opens", {
  doc = parse_qmd("## Sub\n\nbody\n")
  secs = ast_sections(doc)
  expect_true(is.na(secs[[1]]["h1"]))
  expect_equal(unname(secs[[1]]["h2"]), "Sub")
})

test_that("ast_sections on an empty document is an empty list", {
  expect_equal(ast_sections(parse_qmd("")), list())
})
