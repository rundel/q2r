# Malformed YAML front matter is reported as a located Q-1-1 "YAML Syntax
# Error" since q2 da14a347 / 1fff1145 (bd-x30aq7ae, quarto-yaml 0.4.0+). It
# used to be an uncoded "Failed to parse YAML frontmatter: ..." error spanning
# the whole YAML block; now it points at the character where the scanner gave
# up, with end-of-input errors pulled back onto the last YAML content.

yaml_error = function(text) {
  pd = parse_qmd(text, quiet = TRUE)
  q11 = purrr::keep(pd@diagnostics, function(d) identical(d@code, "Q-1-1"))
  expect_length(q11, 1L)
  q11[[1]]
}

byte_offset = function(text, pattern) {
  as.integer(regexpr(pattern, text, fixed = TRUE, useBytes = TRUE)) - 1L
}

test_that("a scanner error is Q-1-1 located at the offending character", {
  text = "---\ntitle: \"Hello\"\nauthor: [a, b\nformat: html\n---\n\nBody text.\n"
  d = yaml_error(text)
  expect_identical(d@kind, "error")
  expect_identical(d@title, "YAML Syntax Error")
  expect_identical(d@problem$text, "illegal placement of ':' indicator")
  expect_identical(d@hints, "The YAML front matter at the top of this document could not be parsed")
  expect_identical(d@location$start_offset, byte_offset(text, ": html"))
  expect_identical(d@location$start_row, 4L)
  expect_identical(d@location$start_column, 7L)

  rendered = format(d, color = FALSE)
  expect_match(rendered, "Error: [Q-1-1] YAML Syntax Error", fixed = TRUE)
  expect_match(rendered, "<text>:4:7", fixed = TRUE)
  expect_no_match(rendered, "Failed to parse YAML frontmatter", fixed = TRUE)
  expect_no_match(rendered, ".rs:", fixed = TRUE)
})

test_that("the location is a byte offset after non-ASCII content", {
  text = "---\ntitle: \"héllo ✓\"\nauthor: [a, b\nformat: html\n---\n"
  d = yaml_error(text)
  expect_identical(d@location$start_offset, byte_offset(text, ": html"))
  expect_identical(d@location$start_row, 4L)
  expect_identical(d@location$start_column, 7L)
})

test_that("an end-of-input error lands on the last YAML line", {
  text = "---\ntitle: x\nauthor: [a, b\n---\n"
  d = yaml_error(text)
  expect_identical(d@problem$text, "while parsing a flow sequence, expected ',' or ']'")
  expect_identical(d@location$start_offset, byte_offset(text, "\n---\n"))
  expect_identical(d@location$start_row, 3L)
  expect_identical(d@location$start_column, 14L)
})

test_that("the ts path carries the same Q-1-1 diagnostic", {
  ts = parse_qmd("---\ntitle: x\nauthor: [a, b\n---\n", ast = "ts", quiet = TRUE)
  expect_identical(purrr::map_chr(ts@diagnostics, function(d) d@code), "Q-1-1")
})

test_that("valid front matter raises no Q-1-1 and round-trips", {
  pd = parse_qmd("---\ntitle: \"Hello\"\nauthor: [a, b]\nformat: html\n---\n\nBody text.\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_identical(pd@meta@value$author@kind, "list")
  expect_identical(pd@meta@value$format@kind, "inlines")
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})
