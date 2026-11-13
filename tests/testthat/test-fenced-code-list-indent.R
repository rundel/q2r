# q2 79e175029 (bd-fenced-code-list-indent-wsirymk4, v0.42.0): the body of a
# fenced code block loses up to as many columns of indentation as its opening
# fence carries past the container's content column (CommonMark 4.5), and a
# blank line inside a fence nested in a list item is kept. Before, a fence
# over-indented inside a list item kept the excess indentation on every body
# line and dropped blank body lines swallowed by the list continuation.

code_text = function(src) {
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  blocks = select_nodes(pd, is(pandoc_code_block))
  expect_length(blocks, 1L)
  blocks[[1]]@text
}

expect_code_roundtrip = function(src) {
  pd = parse_qmd(src, quiet = TRUE)
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)

  ts = parse_qmd(src, ast = "ts", quiet = TRUE)
  out = to_qmd(ts)
  expect_identical(out, src)
  expect_ts_ast_equal(parse_qmd(out, ast = "ts", quiet = TRUE), ts)
}

test_that("a blank line inside a fence in a list item is kept", {
  src = "1. a\n\n   ```\n   x\n\n   y\n   ```\n"
  expect_identical(code_text(src), "x\n\ny")
  expect_identical(to_qmd(parse_qmd(src, quiet = TRUE)), "1.  a\n\n    ```\n    x\n\n    y\n    ```\n")
  expect_code_roundtrip(src)

  src = "- a\n  ```\n  x\n\n  y\n  ```\n- b\n"
  expect_identical(code_text(src), "x\n\ny")
  expect_code_roundtrip(src)
})

test_that("an over-indented fence in a list item strips its own indentation from the body", {
  src = "- item\n\n    ```r\n    x = 1\n\n      y = 2\n    ```\n"
  expect_identical(code_text(src), "x = 1\n\n  y = 2")
  expect_identical(to_qmd(parse_qmd(src, quiet = TRUE)), "* item\n\n  ```r\n  x = 1\n\n    y = 2\n  ```\n")
  expect_code_roundtrip(src)
})

test_that("an indented top-level fence strips only the fence's indentation", {
  src = "  ```r\n  x = 1\n   y\n  ```\n"
  expect_identical(code_text(src), "x = 1\n y")
  expect_identical(to_qmd(parse_qmd(src, quiet = TRUE)), "```r\nx = 1\n y\n```\n")
  expect_code_roundtrip(src)
})

test_that("an unindented fence keeps the indentation of its body lines", {
  src = "```\n  x\n    y\n```\n"
  expect_identical(code_text(src), "  x\n    y")
  expect_code_roundtrip(src)
})
