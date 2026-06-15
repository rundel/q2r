# Pins the R-side tagged-list <-> S7 converters (from-rust.R / to-rust.R) as
# structural inverses, independent of pampa's writer. This catches a desync
# between pandoc_from_list and pandoc_to_list directly, where the slow
# writer-dependent quarto-web sweep would only surface it indirectly.

test_that("pandoc_to_list / pandoc_from_list are structural inverses (rich doc)", {
  src = paste(
    "---", "title: Demo", "draft: false", "n: 3", "tags:", "  - a", "  - b",
    "---", "",
    "# Heading {#h .cls key=val}", "",
    "A paragraph with *emph*, **strong**, ~~strike~~, `code`, H~2~O, x^2^,",
    "[a link](u.html), and an ![image](i.png){#fig width=2}.", "",
    "> A block quote.", "",
    "- bullet one", "- bullet two", "",
    "1. ordered one", "2. ordered two", "",
    "```{r}", "#| label: chunk", "1 + 1", "```", "",
    "$$x^2$$", "",
    "::: {.note}", "Fenced div content.", ":::", "",
    "A footnote.[^1]", "", "[^1]: Note text.", "",
    sep = "\n"
  )
  pd = parse_qmd(src)
  expect_false(has_error_diagnostics(pd))
  l = q2r:::pandoc_to_list(pd)
  expect_identical(q2r:::pandoc_to_list(pandoc_from_list(l)), l)
})

test_that("pandoc_to_list / pandoc_from_list invert across quarto-web fixtures", {
  skip_if_no_quarto_web()
  for (rel in utils::head(quarto_web_files(), 40L)) {
    pd = parse_qmd(quarto_web_read(rel), quiet = TRUE)
    if (has_error_diagnostics(pd)) next
    l = q2r:::pandoc_to_list(pd)
    expect_identical(q2r:::pandoc_to_list(pandoc_from_list(l)), l)
  }
})
