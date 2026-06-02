section_doc = function() {
  parse_qmd(paste0(
    "# Intro\n\nintro body\n\n",
    "## Setup\n\nsetup body\n\n",
    "### Deep\n\ndeep body\n\n",
    "# Other\n\nother body\n"
  ))
}

test_that("select_section returns the heading plus everything beneath it", {
  doc = section_doc()
  sec = select_section(doc, "Intro")
  # Intro h1 spans until the next h1 (Other): heading + 6 nested blocks
  expect_equal(purrr::map_chr(sec, ast_text),
               c("Intro", "intro body", "Setup", "setup body", "Deep", "deep body"))
})

test_that("include_heading = FALSE drops the matched heading", {
  doc = section_doc()
  sec = select_section(doc, c("Intro", "Setup"), include_heading = FALSE)
  expect_equal(purrr::map_chr(sec, ast_text),
               c("setup body", "Deep", "deep body"))
})

test_that("a nested path matches the inner section", {
  doc = section_doc()
  sec = select_section(doc, c("Intro", "Setup", "Deep"))
  expect_equal(purrr::map_chr(sec, ast_text), c("Deep", "deep body"))
})

test_that("glob patterns match heading titles", {
  doc = section_doc()
  expect_length(select_section(doc, "Int*"), 6L)
  expect_length(select_section(doc, "Oth*"), 2L)
})

test_that("levels restricts which headings anchor a section", {
  doc = section_doc()
  # ignoring h3, 'Setup' under 'Intro' still matches as a 2-deep chain
  sec = select_section(doc, c("Intro", "Setup"), levels = 1:2)
  expect_equal(purrr::map_chr(sec, ast_text),
               c("Setup", "setup body", "Deep", "deep body"))
})

test_that("no match returns an empty list", {
  expect_equal(select_section(section_doc(), "Nope"), list())
})

test_that("a document not starting at h1 still selects by title", {
  doc = parse_qmd("## Sub\n\nbody\n")
  expect_equal(purrr::map_chr(select_section(doc, "Sub"), ast_text),
               c("Sub", "body"))
})

test_that("select_section rejects an empty path", {
  expect_error(select_section(section_doc(), character(0)), "non-empty")
})
