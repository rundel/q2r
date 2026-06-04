cell_of = function(src) select_first(parse_qmd(src), is(pandoc_code_block))

test_that("is_code_cell distinguishes executable cells from plain code blocks", {
  expect_true(is_code_cell(cell_of("```{r}\nx = 1\n```\n")))
  expect_false(is_code_cell(cell_of("```r\nx = 1\n```\n")))
  expect_false(is_code_cell(cell_of("```\nplain\n```\n")))
})

test_that("cell_engine reads the braced engine", {
  expect_equal(cell_engine(cell_of("```{r}\nx=1\n```\n")), "r")
  expect_equal(cell_engine(cell_of("```{python}\n#| echo: true\n1\n```\n")), "python")
  expect_equal(cell_engine(cell_of("```{ojs}\n//| echo: false\n1\n```\n")), "ojs")
  expect_true(is.na(cell_engine(cell_of("```r\nx=1\n```\n"))))
})

test_that("cell_options parses the #| YAML block", {
  cell = cell_of("```{r}\n#| label: fig-x\n#| echo: false\n#| fig-cap: \"A plot\"\nplot(1)\n```\n")
  opts = cell_options(cell)
  expect_equal(opts$label, "fig-x")
  expect_identical(opts$echo, FALSE)
  expect_equal(opts[["fig-cap"]], "A plot")
})

test_that("cell_options is empty for plain blocks and option-free cells", {
  expect_equal(cell_options(cell_of("```r\nx=1\n```\n")), list())
  expect_equal(cell_options(cell_of("```{r}\nx=1\n```\n")), list())
})

test_that("cell_code strips the leading option lines", {
  cell = cell_of("```{r}\n#| echo: false\nplot(1)\nsummary(x)\n```\n")
  expect_equal(cell_code(cell), "plot(1)\nsummary(x)")
  expect_equal(cell_code(cell_of("```r\nx = 1\n```\n")), "x = 1")
})

test_that("cell_label falls back from the label option to the id", {
  expect_equal(cell_label(cell_of("```{r}\n#| label: my-cell\nx=1\n```\n")), "my-cell")
  expect_true(is.na(cell_label(cell_of("```{r}\nx=1\n```\n"))))
})

test_that("set_cell_options sets, overrides, and removes options", {
  cell = cell_of("```{r}\n#| label: a\n#| echo: false\nx=1\n```\n")
  out = set_cell_options(cell, echo = TRUE, eval = FALSE, label = NULL)
  opts = cell_options(out)
  expect_identical(opts$echo, TRUE)
  expect_identical(opts$eval, FALSE)
  expect_null(opts$label)
  expect_equal(cell_code(out), "x=1")
})

test_that("set_cell_options preserves a non-# comment prefix", {
  cell = cell_of("```{ojs}\n//| echo: false\n1\n```\n")
  out = set_cell_options(cell, echo = TRUE)
  expect_true(grepl("^//\\|", out@text))
  expect_identical(cell_options(out)$echo, TRUE)
})

test_that("set_cell_options round-trips through to_qmd", {
  cell = cell_of("```{r}\n#| echo: false\nx=1\n```\n")
  out = set_cell_options(cell, echo = TRUE, eval = FALSE)
  rt = select_first(
    parse_qmd(to_qmd(pandoc(blocks = pandoc_blocks(list(out))))),
    is(pandoc_code_block)
  )
  expect_identical(cell_options(rt)$echo, TRUE)
  expect_identical(cell_options(rt)$eval, FALSE)
})

test_that("set_cell_label sets the label option", {
  cell = cell_of("```{r}\nx=1\n```\n")
  expect_equal(cell_label(set_cell_label(cell, "new")), "new")
})

test_that("set_cell_options errors on a non-cell and on unnamed input", {
  cell = cell_of("```{r}\nx=1\n```\n")
  expect_error(set_cell_options(pandoc_str(text = "x"), a = 1), "pandoc_code_block")
  expect_error(set_cell_options(cell, 1), "named")
})

test_that("collect_code tangles cells, filtering by engine and eval", {
  doc = parse_qmd(paste0(
    "```{r}\n#| label: a\nx = 1\n```\n\n",
    "```{r}\n#| eval: false\ny = 2\n```\n\n",
    "```python\nz = 3\n```\n"
  ))
  cc = collect_code(doc)
  expect_false(grepl("z = 3", cc))
  expect_true(grepl("# a", cc, fixed = TRUE))
  expect_false(grepl("y = 2", collect_code(doc, eval_only = TRUE)))
  expect_false(grepl("y = 2", collect_code(doc, label_comments = FALSE)) &&
                 grepl("# a", collect_code(doc, label_comments = FALSE)))
})

test_that("the mask exposes is_code_cell() and has_option()", {
  doc = parse_qmd(paste0(
    "```{r}\n#| echo: false\nx = 1\n```\n\n",
    "```{r}\n#| echo: true\ny = 2\n```\n\n",
    "```r\nz = 3\n```\n"
  ))
  expect_length(select_nodes(doc, is_code_cell()), 2L)
  expect_length(select_nodes(doc, is_code_cell() & has_option("echo", FALSE)), 1L)
  expect_length(select_nodes(doc, has_option("echo")), 2L)
})
