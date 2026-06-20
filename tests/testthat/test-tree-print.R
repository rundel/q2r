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
  pd = parse_qmd(snapshot_doc, quiet = TRUE)
  expect_snapshot(print(pd))
})

test_that("print.pandoc renders a representative document (ascii)", {
  testthat::local_reproducible_output(width = 200, unicode = FALSE)
  pd = parse_qmd(snapshot_doc, quiet = TRUE)
  expect_snapshot(print(pd))
})

test_that("print.ts_tree renders a representative document (unicode)", {
  testthat::local_reproducible_output(width = 200, unicode = TRUE)
  ts = parse_qmd(snapshot_doc, quiet = TRUE, ast = "ts")
  expect_snapshot(print(ts))
})

test_that("print.ts_tree renders a representative document (ascii)", {
  testthat::local_reproducible_output(width = 200, unicode = FALSE)
  ts = parse_qmd(snapshot_doc, quiet = TRUE, ast = "ts")
  expect_snapshot(print(ts))
})

test_that("ts print honours position = TRUE and text = FALSE, and prints a bare node", {
  ts = parse_qmd("# Hi\n", ast = "ts")
  with_pos = paste(capture.output(print(ts@root, position = TRUE)), collapse = "\n")
  expect_match(with_pos, "(0, 0)", fixed = TRUE)
  no_text = paste(capture.output(print(ts@root, text = FALSE)), collapse = "\n")
  expect_false(grepl('"Hi"', no_text, fixed = TRUE))
  expect_true(grepl('"Hi"', paste(capture.output(print(ts@root)), collapse = "\n"),
                    fixed = TRUE))
  # a bare ts_node prints its own subtree
  expect_output(print(ts@root), "document")
})

test_that("pandoc_format_label kind token matches the stripped class name (drift guard)", {
  nodes = list(
    pandoc_header(level = 1L), pandoc_paragraph(), pandoc_plain(), pandoc_emph(),
    pandoc_strong(), pandoc_strikeout(), pandoc_superscript(), pandoc_subscript(),
    pandoc_small_caps(), pandoc_str(text = "x"), pandoc_code(), pandoc_code_block(),
    pandoc_raw_block(), pandoc_block_quote(), pandoc_div(), pandoc_bullet_list(),
    pandoc_ordered_list(), pandoc_link(), pandoc_image(), pandoc_span(),
    pandoc_horizontal_rule()
  )
  for (nd in nodes) {
    lbl = cli::ansi_strip(q2r:::pandoc_format_label(nd))
    token = sub("[^a-z_].*$", "", sub("^[^a-z]*", "", lbl))
    expect_equal(token, q2r:::pandoc_strip_prefix(q2r:::pandoc_class_name(nd)),
                 info = q2r:::pandoc_class_name(nd))
  }
})
