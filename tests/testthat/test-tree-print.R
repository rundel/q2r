snapshot_doc = paste(
  "---",
  "title: Demo",
  "author: A",
  "---",
  "",
  "# Heading 1 {#sec-intro .intro}",
  "",
  "Plain text with *emphasis*, **strong**, and `inline code`.",
  "See [a link](https://example.com \"tip\").",
  "",
  "## Heading 2",
  "",
  "> A block quote.",
  "> Second line.",
  "",
  "- bullet one",
  "- bullet two",
  "  - nested",
  "",
  "1. ordered",
  "2. second",
  "",
  "```{r}",
  "x = 1",
  "```",
  "",
  "Inline math $a + b$ and display math:",
  "",
  "$$",
  "\\sum_i x_i",
  "$$",
  "",
  "::: {.callout-note}",
  "A note div.",
  ":::",
  "",
  "![alt text](img.png){#fig-img}",
  sep = "\n"
)

test_that("print.pandoc renders a representative document (unicode)", {
  testthat::local_reproducible_output(width = 200, unicode = TRUE)
  pd = pampa_parse_pd(snapshot_doc, quiet = TRUE)
  expect_snapshot(print(pd))
})

test_that("print.pandoc renders a representative document (ascii)", {
  testthat::local_reproducible_output(width = 200, unicode = FALSE)
  pd = pampa_parse_pd(snapshot_doc, quiet = TRUE)
  expect_snapshot(print(pd))
})

test_that("print.ts_tree renders a representative document (unicode)", {
  testthat::local_reproducible_output(width = 200, unicode = TRUE)
  ts = pampa_parse_ts(snapshot_doc, quiet = TRUE)
  expect_snapshot(print(ts))
})

test_that("print.ts_tree renders a representative document (ascii)", {
  testthat::local_reproducible_output(width = 200, unicode = FALSE)
  ts = pampa_parse_ts(snapshot_doc, quiet = TRUE)
  expect_snapshot(print(ts))
})
