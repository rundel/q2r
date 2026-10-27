# q2 5de19e9be (bd-hfghrqvh, v0.36.0): a pipe-table caption written
# directly under the table with no blank line and no space after the colon
# (`:Caption {#id .cls key=v}`) keeps its attribute block, which the
# caption-as-last-row fixup now lifts onto the table exactly as the
# blank-line `: Caption {...}` form always did. Previously the pipe-table
# cell processor dropped every `{...}` in a cell, so the id and classes
# were lost. An attribute in an ordinary cell is still dropped.

test_that("an adjacent no-space caption's attribute lands on the table", {
  src = "| Header |\n|--------|\n| Data   |\n:Caption {#tbl-1 .striped .hover key=v}\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  tbl = pd@blocks[[1]]
  expect_s3_class(tbl, "q2r::pandoc_table")
  expect_identical(tbl@attr@id, "tbl-1")
  expect_identical(tbl@attr@classes, c("striped", "hover"))
  expect_identical(tbl@attr@attributes[["key"]], "v")
  expect_length(tbl@bodies[[1]]@body_rows, 1L)
  expect_identical(ast_text(tbl@caption@long), "Caption")

  out = to_qmd(pd)
  expect_identical(
    out,
    "| Header |\n| ------ |\n| Data   |\n\n: Caption {#tbl-1 .striped .hover key=\"v\"}\n"
  )
  expect_pd_ast_equal(parse_qmd(out, quiet = TRUE), pd)
})

test_that("the adjacent and blank-line caption forms parse to the same table", {
  adjacent = parse_qmd("| a |\n|---|\n| 1 |\n:Cap {.striped}\n", quiet = TRUE)
  spaced = parse_qmd("| a |\n|---|\n| 1 |\n\n: Cap {.striped}\n", quiet = TRUE)
  expect_pd_ast_equal(adjacent, spaced)
  expect_identical(adjacent@blocks[[1]]@attr@classes, "striped")
})

test_that("an attribute in an ordinary table cell is still dropped", {
  pd = parse_qmd("| a | b |\n|---|---|\n| x {.foo} | y |\n", quiet = TRUE)
  tbl = pd@blocks[[1]]
  expect_s3_class(tbl, "q2r::pandoc_table")
  expect_length(tbl@attr@classes, 0L)
  expect_identical(ast_text(tbl@bodies[[1]]@body_rows[[1]]@cells[[1]]@content), "x")
  expect_length(tbl@caption@long, 0L)
})
