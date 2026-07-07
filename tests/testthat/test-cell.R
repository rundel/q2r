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
  # the //| prefix survives a full to_qmd + re-parse round trip, not just @text
  rt = select_first(
    parse_qmd(to_qmd(pandoc(blocks = pandoc_blocks(list(out))))),
    is(pandoc_code_block)
  )
  expect_true(grepl("//|", rt@text, fixed = TRUE))
  expect_identical(cell_options(rt)$echo, TRUE)
})

test_that("a vector-valued cell option serializes as a multi-line block and round-trips", {
  cell = cell_of("```{r}\nx=1\n```\n")
  out = set_cell_options(cell, "fig-cap" = c("one", "two"))
  expect_match(out@text, "#| fig-cap:\n#| - one\n#| - two", fixed = TRUE)
  expect_equal(cell_options(out)[["fig-cap"]], c("one", "two"))
  rt = select_first(
    parse_qmd(to_qmd(pandoc(blocks = pandoc_blocks(list(out))))),
    is(pandoc_code_block)
  )
  expect_equal(cell_options(rt)[["fig-cap"]], c("one", "two"))
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

test_that("cell option values serialize at full precision and re-parse to the same value", {
  # Full precision: every digit is kept where the default format() rounded to
  # "1.234568e+14" and silently lost precision.
  expect_identical(q2r:::cell_yaml_scalar(123456789012345), "123456789012345")
  # Numbers within yaml's parse range re-parse to the same value (no "2e+09").
  for (x in list(2000000000, 6.5, 42, 1e-5)) {
    expect_equal(yaml::yaml.load(q2r:::cell_yaml_scalar(x)), x)
  }
  # YAML-reserved words and leading indicators are quoted so they re-parse as
  # strings rather than booleans / null / sequence items.
  expect_identical(q2r:::cell_yaml_scalar("yes"), "\"yes\"")
  expect_identical(q2r:::cell_yaml_scalar("null"), "\"null\"")
  expect_identical(q2r:::cell_yaml_scalar("- dash"), "\"- dash\"")
  expect_identical(yaml::yaml.load(q2r:::cell_yaml_scalar("yes")), "yes")
})

test_that("NA cell-option values serialize as YAML null, not 'false' or 'NA'", {
  expect_identical(q2r:::cell_yaml_scalar(NA), "null")
  expect_identical(q2r:::cell_yaml_scalar(NA_character_), "null")
  expect_identical(q2r:::cell_yaml_scalar(NA_real_), "null")
  # null round-trips to R NULL, not the strings "false" / "NA"
  expect_null(yaml::yaml.load(q2r:::cell_yaml_scalar(NA)))
})

test_that("set_cell_options requires an executable cell, not a plain fence", {
  plain = cell_of("```r\nx = 1\n```\n")
  expect_false(is_code_cell(plain))
  expect_error(set_cell_options(plain, echo = TRUE), "executable cell")
})

test_that("integral-valued numeric vectors serialize without a .0 suffix", {
  cell = cell_of("```{r}\nx=1\n```\n")
  out = set_cell_options(cell, "fig-width" = c(4, 6))
  expect_match(out@text, "#| fig-width:\n#| - 4\n#| - 6", fixed = TRUE)
  expect_equal(cell_options(out)[["fig-width"]], c(4L, 6L))
})

test_that("a YAML-reserved string option round-trips as a string, not a boolean", {
  cell = cell_of("```{r}\nx=1\n```\n")
  out = set_cell_options(cell, mode = "yes")
  rt = select_first(
    parse_qmd(to_qmd(pandoc(blocks = pandoc_blocks(list(out))))),
    is(pandoc_code_block)
  )
  expect_identical(cell_options(rt)$mode, "yes")
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
  no_labels = collect_code(doc, label_comments = FALSE)
  expect_false(grepl("# a", no_labels, fixed = TRUE))
  expect_true(grepl("y = 2", no_labels, fixed = TRUE))
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

test_that("set_cell_options serializes embedded newlines as block scalars", {
  cell = parse_qmd("```{r}\nx = 1\n```\n", quiet = TRUE)@blocks@content[[1]]
  out = set_cell_options(cell, cap = "line1\nline2", echo = TRUE)
  expect_identical(cell_options(out)$cap, "line1\nline2")
  expect_true(isTRUE(cell_options(out)$echo))
  expect_identical(cell_code(out), "x = 1")
})

test_that("set_cell_options escapes backslashes and quotes numeric-looking strings", {
  cell = parse_qmd("```{r}\nx = 1\n```\n", quiet = TRUE)@blocks@content[[1]]
  out = set_cell_options(cell, path = "C:\\dir\\file", version = "1.10", tag = "+5")
  opts = cell_options(out)
  expect_identical(opts$path, "C:\\dir\\file")
  expect_identical(opts$version, "1.10")
  expect_identical(opts$tag, "+5")
})

test_that("set_cell_options aborts on an unreadable option block", {
  bad = parse_qmd("```{r}\n#| fig-cap: 'unclosed\n#| echo: false\nx\n```\n", quiet = TRUE)@blocks@content[[1]]
  expect_error(set_cell_options(bad, eval = TRUE), "not valid YAML")
  expect_identical(cell_options(bad), list())
})

test_that("!expr option values keep their tag and never warn", {
  ex = parse_qmd("```{r}\n#| eval: !expr nrow(df) > 0\nx\n```\n", quiet = TRUE)@blocks@content[[1]]
  expect_no_warning(o <- cell_options(ex))
  expect_s3_class(o$eval, "q2r_yaml_expr")
  out = set_cell_options(ex, echo = FALSE)
  expect_match(out@text, "#\\| eval: !expr nrow\\(df\\) > 0", fixed = FALSE)
})

test_that("verbatim {{r}} cells are not code cells", {
  vb = parse_qmd("```{{r}}\nx = 1\n```\n", quiet = TRUE)@blocks@content[[1]]
  expect_false(is_code_cell(vb))
  expect_identical(cell_engine(vb), NA_character_)
  expect_error(set_cell_options(vb, echo = TRUE), "executable cell")
})

test_that("has_option compares numerics across integer/double", {
  doc = parse_qmd("```{r}\n#| fig-width: 5\nplot(1)\n```\n", quiet = TRUE)
  expect_length(select_nodes(doc, has_option("fig-width", 5)), 1L)
  expect_length(select_nodes(doc, has_option("fig-width", 5L)), 1L)
  expect_length(select_nodes(doc, has_option("fig-width", 6)), 0L)
})

test_that("only line-start '#| ' lines are option lines (knitr parity)", {
  cell = parse_qmd("```{r}\n#| echo: false\n  #| eval: true\n#|label: x\ny = 1\n```\n", quiet = TRUE)@blocks@content[[1]]
  expect_named(cell_options(cell), "echo")
  expect_identical(cell_code(cell), "  #| eval: true\n#|label: x\ny = 1")
})

test_that("set_cell_options keeps CRLF cells CRLF", {
  crlf = pandoc_code_block(attr = pandoc_attr(classes = "{r}"),
                           text = "#| echo: false\r\nx = 1\r\ny = 2")
  out = set_cell_options(crlf, eval = TRUE)
  expect_false(grepl("[^\r]\n", out@text))
  expect_identical(cell_code(out), "x = 1\ny = 2")
})

test_that("set_cell_engine swaps the engine and keeps other classes", {
  cell = parse_qmd("```{r}\n#| echo: false\nx = 1\n```\n", quiet = TRUE)@blocks@content[[1]]
  out = set_cell_engine(cell, "python")
  expect_identical(cell_engine(out), "python")
  expect_identical(cell_options(out)$echo, FALSE)
  expect_error(set_cell_engine(cell, "two words"), "single engine name")
})

test_that("set_cell_code replaces the body and keeps the option block", {
  cell = parse_qmd("```{r}\n#| echo: false\nx = 1\n```\n", quiet = TRUE)@blocks@content[[1]]
  out = set_cell_code(cell, c("a = 1", "b = 2"))
  expect_identical(cell_code(out), "a = 1\nb = 2")
  expect_identical(cell_options(out)$echo, FALSE)
  out2 = set_cell_code(cell, "single\nstring")
  expect_identical(cell_code(out2), "single\nstring")
})
