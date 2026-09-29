# pampa folds its concrete-tree depth guard into the tree-sitter conversion
# walk as of q2 c406ce5c (40eadc50, bd-t7i6oanu; the separate pre-pass and
# `utils/concrete_tree_depth.rs` are gone). The accepted set of documents is
# unchanged: a tree deeper than `MAX_CONCRETE_TREE_DEPTH = 99` nodes (root
# counted as 1) is rejected with a generic Q-0-99 error, but the diagnostic
# text moved from `max depth: N > 100` to `more than 99 levels`. For nested
# block quotes the concrete depth is the nesting count plus 4, so 96 levels
# is the first rejected document.

nested_quotes = function(n) paste0(paste(rep(">", n), collapse = " "), " x\n")

innermost = function(pd, n) {
  node = pd@blocks[[1]]
  for (i in seq_len(n - 1L)) {
    expect_true(S7::S7_inherits(node, pandoc_block_quote))
    expect_length(node@content@content, 1L)
    node = node@content@content[[1]]
  }
  node
}

test_that("a document nested past the depth limit fails with Q-0-99", {
  pd = parse_qmd(nested_quotes(96), quiet = TRUE)
  expect_true(has_error_diagnostics(pd))
  expect_length(pd@blocks, 0L)
  expect_length(pd@diagnostics, 1L)

  d = pd@diagnostics[[1]]
  expect_true(S7::S7_inherits(d, pampa_diagnostic))
  expect_identical(d@kind, "error")
  expect_identical(d@code, "Q-0-99")
  expect_match(d@title, "too deeply nested \\(more than 99 levels\\)")
  expect_match(format(d, color = FALSE), "^Error \\[Q-0-99\\]: The input document is too deeply nested")

  expect_error(parse_qmd(nested_quotes(96)), "too deeply nested")

  pd = parse_qmd(nested_quotes(150), quiet = TRUE)
  expect_true(has_error_diagnostics(pd))
  expect_match(pd@diagnostics[[1]]@title, "more than 99 levels")
})

test_that("the tree-sitter path still builds the tree and carries the same diagnostic", {
  ts = parse_qmd(nested_quotes(96), ast = "ts", quiet = TRUE)
  expect_true(S7::S7_inherits(ts, ts_tree))
  expect_identical(ts@root@kind, "document")
  expect_true(has_error_diagnostics(ts))
  expect_identical(ts@diagnostics[[1]]@code, "Q-0-99")
  expect_match(ts@diagnostics[[1]]@title, "more than 99 levels")
  expect_identical(to_qmd(ts), nested_quotes(96))
})

test_that("moderately nested block quotes parse and round-trip without a diagnostic", {
  src = nested_quotes(20)
  pd = parse_qmd(src, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_length(pd@diagnostics, 0L)
  expect_length(pd@blocks, 1L)

  leaf = innermost(pd, 20)
  expect_true(S7::S7_inherits(leaf, pandoc_block_quote))
  para = leaf@content@content[[1]]
  expect_true(S7::S7_inherits(para, pandoc_paragraph))
  expect_identical(ast_text(para), "x")

  pd2 = parse_qmd(to_qmd(pd), quiet = TRUE)
  expect_no_error_diagnostics(pd2)
  expect_pd_ast_equal(pd2, pd)

  ts = parse_qmd(src, ast = "ts", quiet = TRUE)
  expect_length(ts@diagnostics, 0L)
  expect_identical(to_qmd(ts), src)
  expect_ts_ast_equal(parse_qmd(to_qmd(ts), ast = "ts", quiet = TRUE), ts)
})

test_that("the limit is on depth, not on document size", {
  wide = paste0(rep("> x\n\n", 300), collapse = "")
  pd = parse_qmd(wide, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_length(pd@diagnostics, 0L)
  expect_length(pd@blocks, 300L)
  expect_true(all(purrr::map_lgl(pd@blocks@content, S7::S7_inherits, pandoc_block_quote)))

  long = paste0(rep("para\n\n", 300), collapse = "")
  pd = parse_qmd(long, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_length(pd@blocks, 300L)
})
