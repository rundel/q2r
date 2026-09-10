# Smart typography canonicalizes on read and write: q2 3cae6150 (#290) turns
# `--` / `---` / straight quotes into an en dash / em dash / `pandoc_quoted`,
# and f8df9521 (bd-ellipsis-not-smart-48bv2pe6) makes `...` an ellipsis at
# every position rather than only mid-line. The qmd writer emits the ASCII
# forms back, so the source spelling survives a round trip.

typo_src = "the ... menu\n\na -- b --- c\n\n\"hi\" and 'yo'\n\n...start\n"

test_that("ellipsis, dashes, and quotes are read as smart typography", {
  pd = parse_qmd(typo_src, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  strs = purrr::map_chr(as.list(select_nodes(pd, is(pandoc_str))), function(s) s@text)
  expect_true(all(c("…", "–", "—") %in% strs))
  expect_identical(ast_text(pd@blocks[[4]]), "…start")
  quoted = select_nodes(pd, is(pandoc_quoted))
  expect_length(quoted, 2L)
  expect_identical(
    purrr::map_chr(as.list(quoted), function(q) q@quote_type),
    c("double", "single")
  )
})

test_that("smart typography writes back as its ASCII source form", {
  pd = parse_qmd(typo_src, quiet = TRUE)
  expect_identical(to_qmd(pd), typo_src)
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})
