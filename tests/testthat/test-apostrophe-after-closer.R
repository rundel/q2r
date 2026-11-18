# q2 aeaa691b3 (bd-apostrophe-after-span-6l9c8c26, #1249, v0.47.0): a `'`
# directly after the end of an inline construct is an apostrophe, read as the
# construct followed by `Str "’s"` (as in Pandoc), instead of a quote opener
# that never closes (Q-2-7). The grammar emits it as a sibling `pandoc_str`
# leaf via the new SPAN_APOSTROPHE scanner token; the qmd writer still emits
# the backslash-escaped `\'s`.

rsquo = "’"

expect_apostrophe_after = function(src, cls) {
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  inl = pd@blocks[[1]]@content
  expect_s7_class(inl[[1]], cls)
  expect_s7_class(inl[[2]], pandoc_str)
  expect_identical(inl[[2]]@text, paste0(rsquo, "s"))
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

closers = list(
  "_book_'s\n"            = pandoc_emph,
  "*book*'s\n"            = pandoc_emph,
  "**book**'s\n"          = pandoc_strong,
  "`a.rs`'s\n"            = pandoc_code,
  "[book](https://x)'s\n" = pandoc_link,
  "[book]{.x}'s\n"        = pandoc_span,
  "![alt](a.png)'s\n"     = pandoc_image,
  "$x$'s\n"               = pandoc_math,
  "~~gone~~'s\n"          = pandoc_strikeout
)

test_that("a quote mark right after an inline closer is an apostrophe", {
  for (src in names(closers)) expect_apostrophe_after(src, closers[[src]])
})

test_that("the apostrophe sits mid-sentence without breaking the paragraph", {
  pd = parse_qmd("The _book_'s premise\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_identical(ast_text(pd), paste0("The book", rsquo, "s premise"))
})

test_that("the qmd writer emits a backslash-escaped apostrophe", {
  expect_identical(to_qmd(parse_qmd("_book_'s\n", quiet = TRUE)), "*book*\\'s\n")
  expect_identical(to_qmd(parse_qmd("`a.rs`'s file\n", quiet = TRUE)), "`a.rs`\\'s file\n")
})

test_that("the ts tree carries the apostrophe as its own pandoc_str leaf", {
  ts = expect_ts_roundtrip("_book_'s\n")
  para = select_descendants(ts, kind == "pandoc_paragraph")[[1]]
  kids = para@children@content
  expect_identical(purrr::map_chr(kids, function(n) n@kind), c("pandoc_emph", "pandoc_str", "pandoc_str"))
  expect_identical(kids[[2]]@text, "'")
  for (src in names(closers)) expect_ts_roundtrip(src)
})

test_that("a quote mark that is not glued to a closer keeps its old reading", {
  pd = parse_qmd("'_book_'\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_s7_class(pd@blocks[[1]]@content[[1]], pandoc_quoted)

  pd = parse_qmd("a ' b.\n", quiet = TRUE)
  expect_identical(pd@diagnostics[[1]]@code, "Q-2-10")

  pd = parse_qmd("_a_ 'more\n", quiet = TRUE)
  expect_true(has_error_diagnostics(pd))
})
