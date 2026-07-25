# GFM task lists arrived in q2 65a888b0 (q2#407): tree-sitter-qmd gained the
# named leaf kinds `task_list_marker_checked` / `task_list_marker_unchecked`,
# the reader prepends a ballot-box `Str` + `Space` to the item's first
# Plain/Paragraph, and the qmd writer rewrites that back to `[ ]` / `[x]`.
# No quarto-web fixture contains a task list, so the sweep does not cover it.

task_srcs = list(
  bullet    = "- [ ] alpha\n- [x] beta\n",
  bullet_up = "- [X] alpha\n",
  ordered   = "1. [ ] alpha\n2. [x] beta\n",
  multi     = "- [x] alpha\n\n  more\n"
)

test_that("task-list markers parse to ballot-box inlines", {
  pd = parse_qmd(task_srcs$bullet, quiet = TRUE)
  expect_false(has_error_diagnostics(pd))

  items = select_children(pd@blocks[[1]])
  expect_length(items, 2L)
  expect_identical(ast_text(items[[1]]), "\u2610 alpha")
  expect_identical(ast_text(items[[2]]), "\u2612 beta")
})

test_that("task lists round-trip through the pampa qmd writer", {
  for (nm in names(task_srcs)) {
    pd = parse_qmd(task_srcs[[nm]], quiet = TRUE)
    expect_no_error_diagnostics(pd)
    pd2 = parse_qmd(to_qmd(pd), quiet = TRUE)
    expect_pd_ast_equal(pd2, pd)
  }
})

test_that("a bracketed link at the head of a list item is not a task marker", {
  pd = parse_qmd("- [x](url) alpha\n", quiet = TRUE)
  expect_false(has_error_diagnostics(pd))
  expect_identical(ast_text(pd), "x alpha")
})

test_that("ts markers are named leaves that byte-recover without a handler", {
  ts = parse_qmd(task_srcs$bullet, ast = "ts", quiet = TRUE)
  markers = select_descendants(
    ts,
    kind %in% c("task_list_marker_unchecked", "task_list_marker_checked")
  )
  expect_length(markers, 2L)
  expect_identical(
    purrr::map_chr(as.list(markers), function(n) n@text),
    c("[ ] ", "[x] ")
  )

  # Leaves render from @text before ts_kind_handlers is consulted, so the new
  # kinds must not trip the unknown-kind warning.
  expect_no_warning(out <- to_qmd(ts))
  expect_identical(out, task_srcs$bullet)
  expect_ts_ast_equal(parse_qmd(out, ast = "ts", quiet = TRUE), ts)
})
