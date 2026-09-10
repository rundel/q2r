# `write_code_attr` (q2 fdf55e77) writes a bracket-wrapped language pseudo-class
# alongside other attributes as `{python .marimo}` rather than the
# `{.{python} .marimo}` form the previous writer produced, which the reader
# does not accept. q2r's cell helpers carry the engine as that braced class, so
# `set_cell_engine()` on a multi-class cell depends on it.

test_that("a braced language with extra classes writes back in fence form", {
  src = "```{python .marimo}\nx = 1\n```\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  cell = pd@blocks[[1]]
  expect_identical(cell@attr@classes, c("{python}", "marimo"))
  expect_true(is_code_cell(cell))
  expect_identical(cell_engine(cell), "python")
  expect_identical(to_qmd(pd), src)
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})

test_that("set_cell_engine on a multi-class cell writes the swapped engine", {
  cell = parse_qmd("```{python .marimo}\nx = 1\n```\n", quiet = TRUE)@blocks[[1]]
  swapped = set_cell_engine(cell, "r")
  expect_identical(swapped@attr@classes, c("{r}", "marimo"))
  expect_identical(
    to_qmd(pandoc(blocks = pandoc_blocks(list(swapped)))),
    "```{r .marimo}\nx = 1\n```\n"
  )
})
