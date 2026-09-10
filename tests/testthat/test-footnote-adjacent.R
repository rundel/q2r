# Adjacent footnote definitions no longer merge since q2 f8df9521: `[^id]:` is
# recognized as a block opener at both SOFT_LINE_ENDING gates, so a definition
# on the line right after another starts its own note. pampa represents a
# reference as a span carrying the `quarto-note-reference` class and a
# definition as a `pandoc_note_definition_para`.

test_that("back-to-back footnote definitions stay separate notes", {
  pd = parse_qmd("A[^1] B[^2]\n\n[^1]: one\n[^2]: two\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  defs = purrr::keep(
    pd@blocks@content,
    function(b) S7::S7_inherits(b, pandoc_note_definition_para)
  )
  expect_length(defs, 2L)
  expect_identical(purrr::map_chr(defs, function(d) d@id), c("1", "2"))
  expect_identical(purrr::map_chr(defs, ast_text), c("one", "two"))
  refs = select_nodes(pd, has_class("quarto-note-reference"))
  expect_length(refs, 2L)
  expect_identical(
    purrr::map_chr(as.list(refs), function(r) get_attr(r, "reference-id")),
    c("1", "2")
  )
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})
