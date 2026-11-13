# q2 2ec078671 (GH #892, bd-2ydvebkc, v0.45.0): an empty task item, `- [ ] `
# with nothing after the marker, is a task item reading as `Plain [Str "☐"]`
# (no Space, as in Pandoc) instead of a parse error. The grammar gives the
# list_item a task marker leaf and no paragraph, and the qmd writer emits the
# bare marker back.

expect_empty_task = function(src, glyph) {
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  item = pd@blocks[[1]]@content[[1]]
  expect_length(item, 1L)
  expect_s7_class(item[[1]], pandoc_plain)
  inlines = item[[1]]@content
  expect_length(inlines, 1L)
  expect_s7_class(inlines[[1]], pandoc_str)
  expect_identical(inlines[[1]]@text, glyph)
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
  pd
}

expect_ts_roundtrip = function(src) {
  ts = parse_qmd(src, ast = "ts", quiet = TRUE)
  expect_length(ts@diagnostics, 0L)
  out = to_qmd(ts)
  expect_identical(out, src)
  expect_ts_ast_equal(parse_qmd(out, ast = "ts", quiet = TRUE), ts)
  ts
}

test_that("an empty task item is a ballot-box Plain with no Space", {
  expect_empty_task("- [ ] \n", "☐")
  expect_empty_task("- [x] \n", "☒")
  pd = expect_empty_task("1. [ ] \n", "☐")
  expect_s7_class(pd@blocks[[1]], pandoc_ordered_list)
})

test_that("the qmd writer emits the bare marker", {
  expect_identical(to_qmd(parse_qmd("- [ ] \n", quiet = TRUE)), "* [ ] \n")
  expect_identical(to_qmd(parse_qmd("- [x] \n", quiet = TRUE)), "* [x] \n")
  expect_identical(
    to_qmd(parse_qmd("- [ ] \n- [x] done\n", quiet = TRUE)),
    "* [ ] \n* [x] done\n"
  )
})

test_that("an empty task item sits beside a filled one", {
  pd = parse_qmd("- [ ] \n- [x] done\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  items = pd@blocks[[1]]@content
  expect_identical(ast_text(items[[1]][[1]]), "☐")
  expect_identical(ast_text(items[[2]][[1]]), "☒ done")
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})

test_that("the ts list_item holds the marker leaf and no paragraph", {
  ts = expect_ts_roundtrip("- [ ] \n")
  item = select_descendants(ts, kind == "list_item")[[1]]
  kinds = purrr::map_chr(item@children@content, function(n) n@kind)
  expect_identical(kinds, c("list_marker_minus", "task_list_marker_unchecked"))

  expect_ts_roundtrip("- [x] \n")
  expect_ts_roundtrip("1. [ ] \n- [x] done\n")
})

test_that("text glued to the brackets is not a task marker", {
  pd = parse_qmd("- [ ]x\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_false(grepl("☐", ast_text(pd), fixed = TRUE))
  ts = parse_qmd("- [ ]x\n", ast = "ts", quiet = TRUE)
  expect_length(select_descendants(ts, kind == "task_list_marker_unchecked"), 0L)
})
