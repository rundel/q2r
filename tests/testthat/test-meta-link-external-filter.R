# q2 3fff87944 (bd-t3n1nghb, v0.36.0): `link-external-filter`, at the top
# level and under `format.*`, is annotated as a plain string in document
# metadata. It is a regular expression, and read as markdown its backslash
# escapes were consumed and `|` / `^` gained escapes of their own on the
# way back to text. Other `link-external-*` keys are not annotated and
# still arrive as inlines.

meta_src = paste0(
  "---\n",
  "title: Hi\n",
  "link-external-filter: \"^(?:http:|https:)\\\\/\\\\/www\\\\.quarto\\\\.org\"\n",
  "link-external-icon: true\n",
  "format:\n",
  "  html:\n",
  "    link-external-filter: \"^a\\\\.b\"\n",
  "---\n",
  "\n",
  "x\n"
)

test_that("link-external-filter is a plain string at the top level and per format", {
  pd = parse_qmd(meta_src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  top = pd@meta@value[["link-external-filter"]]
  expect_identical(top@kind, "string")
  expect_identical(top@value, "^(?:http:|https:)\\/\\/www\\.quarto\\.org")
  per_format = pd@meta@value[["format"]]@value[["html"]]@value[["link-external-filter"]]
  expect_identical(per_format@kind, "string")
  expect_identical(per_format@value, "^a\\.b")

  expect_identical(pd@meta@value[["title"]]@kind, "inlines")
  expect_identical(pd@meta@value[["link-external-icon"]]@kind, "bool")

  out = to_qmd(pd)
  expect_identical(out, meta_src)
  expect_pd_ast_equal(parse_qmd(out, quiet = TRUE), pd)
})

test_that("an unannotated link-external key still reads as inlines", {
  pd = parse_qmd("---\nlink-external-newwindow: \"^a\\\\.b\"\n---\n\nx\n", quiet = TRUE)
  expect_identical(pd@meta@value[["link-external-newwindow"]]@kind, "inlines")
})
