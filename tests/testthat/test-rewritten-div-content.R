# q2 c8f14143a (GH #895, v0.36.0): the reader rewrites a `.definition-list`
# or `.list-table` div into a DefinitionList / Table before visiting the
# div's content, and that content now still gets the whole postprocess
# pass. Nested definition-list and list-table divs are desugared, an image
# paragraph in a loose definition becomes a figure, a header in a
# definition gets its auto id, and the doubled-brace fence warning fires
# inside. Previously the rewritten block's content was skipped, so nested
# divs stayed divs. Reparse of the writer's output is covered by
# test-deflist-writer.R; this file pins the reader side.

deflist_of = function(pd) {
  expect_length(pd@blocks, 1L)
  expect_s3_class(pd@blocks[[1]], "q2r::pandoc_definition_list")
  pd@blocks[[1]]
}

only_definition = function(dl, i = 1L) {
  defs = dl@content[[i]]@defs
  expect_length(defs, 1L)
  defs[[1]]
}

test_that("nested definition-list and list-table divs in a definition are rewritten", {
  src = paste0(
    "::: {.definition-list}\n",
    "* Outer term\n",
    "  - ::: {.definition-list}\n",
    "    * Inner term\n",
    "      - Inner definition.\n",
    "    :::\n",
    "* Table term\n",
    "  - ::: {.list-table}\n",
    "    * - a\n",
    "      - b\n",
    "    * - 1\n",
    "      - 2\n",
    "    :::\n",
    ":::\n"
  )
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  dl = deflist_of(pd)
  expect_length(dl@content, 2L)
  inner = only_definition(dl, 1L)
  expect_length(inner, 1L)
  expect_s3_class(inner[[1]], "q2r::pandoc_definition_list")
  expect_identical(ast_text(inner[[1]]@content[[1]]@term), "Inner term")
  tbl = only_definition(dl, 2L)
  expect_length(tbl, 1L)
  expect_s3_class(tbl[[1]], "q2r::pandoc_table")
  expect_length(tbl[[1]]@bodies[[1]]@body_rows, 1L)

  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})

test_that("a definition-list div in a list-table cell is rewritten", {
  src = paste0(
    "::: {.list-table}\n",
    "* - ::: {.definition-list}\n",
    "    * Cell term\n",
    "      - Cell definition.\n",
    "    :::\n",
    "  - Plain cell\n",
    ":::\n"
  )
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  tbl = pd@blocks[[1]]
  expect_s3_class(tbl, "q2r::pandoc_table")
  cell = tbl@head@rows[[1]]@cells[[1]]
  expect_length(cell@content, 1L)
  expect_s3_class(cell@content[[1]], "q2r::pandoc_definition_list")
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})

test_that("an image paragraph in a loose definition becomes a figure", {
  src = "::: {.definition-list}\n* Figure term\n\n  - Some text.\n\n    ![An alt text](img.png)\n\n:::\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  def = only_definition(deflist_of(pd))
  expect_length(def, 2L)
  expect_s3_class(def[[1]], "q2r::pandoc_paragraph")
  expect_s3_class(def[[2]], "q2r::pandoc_figure")
  expect_identical(ast_text(def[[2]]@caption@long), "An alt text")
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})

test_that("a header in a definition gets an auto id", {
  pd = parse_qmd("::: {.definition-list}\n* Term\n  - ## A Header\n:::\n", quiet = TRUE)
  def = only_definition(deflist_of(pd))
  expect_length(def, 1L)
  expect_s3_class(def[[1]], "q2r::pandoc_header")
  expect_identical(def[[1]]@attr@id, "a-header")
})

test_that("a doubled-brace fence inside a definition warns Q-2-50", {
  pd = parse_qmd("::: {.definition-list}\n* Term\n  - ```{{python}}\n    1 + 1\n    ```\n:::\n", quiet = TRUE)
  expect_s3_class(pd@blocks[[1]], "q2r::pandoc_definition_list")
  expect_identical(purrr::map_chr(pd@diagnostics, function(d) d@code), "Q-2-50")
})

test_that("a list table is not subject to the pipe-table caption heuristic", {
  pd = parse_qmd("::: {.list-table}\n* - a\n* - \\: b\n:::\n", quiet = TRUE)
  tbl = pd@blocks[[1]]
  expect_s3_class(tbl, "q2r::pandoc_table")
  expect_length(tbl@caption@long, 0L)
  expect_length(tbl@bodies[[1]]@body_rows, 1L)
  expect_identical(ast_text(tbl@bodies[[1]]@body_rows[[1]]@cells[[1]]@content), ": b")
})

test_that("an ordinary div inside a definition stays a div", {
  pd = parse_qmd("::: {.definition-list}\n* Term\n  - ::: {.note}\n    Inside.\n    :::\n:::\n", quiet = TRUE)
  def = only_definition(deflist_of(pd))
  expect_length(def, 1L)
  expect_s3_class(def[[1]], "q2r::pandoc_div")
  expect_true(has_class(def[[1]], "note"))
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})
