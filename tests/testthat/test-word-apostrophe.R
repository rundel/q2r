# q2 9c4f3b3f2 (GH #943) treats a `'` directly after a word and before a
# non-alphanumeric as an apostrophe (pandoc's notAfterString rule) instead of a
# closing quote, so plural possessives such as `Dogs' toys` and `d'` before a
# code span no longer raise Q-2-10. The scanner emits `word'` as one literal
# str token (a mid-line one carries its leading space, with no separate
# pandoc_space), the pd reader smartens it to a right single quote, and the
# writer still escapes it as `\'`. A `'` with whitespace on both sides is
# still Q-2-10, and a `'` after a word inside an open single quote closes it.

rsquo = intToUtf8(0x2019)

str_texts = function(block) {
  purrr::map_chr(
    purrr::keep(block@content@content, \(x) S7::S7_inherits(x, pandoc_str)),
    \(x) x@text
  )
}

ts_child_kinds = function(node) purrr::map_chr(node@children@content, \(x) x@kind)

ts_paragraph = function(ts) ts@root@children@content[[1]]@children@content[[1]]

expect_word_apostrophe_roundtrip = function(src) {
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)

  ts = parse_qmd(src, ast = "ts", quiet = TRUE)
  out = to_qmd(ts)
  expect_identical(out, src)
  expect_ts_ast_equal(parse_qmd(out, ast = "ts", quiet = TRUE), ts)
}

test_that("a plural possessive is an apostrophe, not a Q-2-10 quote", {
  src = "Dogs' toys and cats' toys.\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  para = pd@blocks@content[[1]]
  expect_true(S7::S7_inherits(para, pandoc_paragraph))
  expect_identical(
    str_texts(para),
    c(paste0("Dogs", rsquo), "toys", "and", paste0("cats", rsquo), "toys.")
  )
  expect_identical(to_qmd(pd), "Dogs\\' toys and cats\\' toys.\n")

  p = ts_paragraph(parse_qmd(src, ast = "ts"))
  expect_identical(p@kind, "pandoc_paragraph")
  expect_identical(
    ts_child_kinds(p),
    c("pandoc_str", "pandoc_space", "pandoc_str", "pandoc_space", "pandoc_str",
      "pandoc_str", "pandoc_space", "pandoc_str")
  )
  expect_identical(p@children@content[[1]]@text, "Dogs'")
  expect_identical(p@children@content[[6]]@text, " cats'")
})

test_that("apostrophes before punctuation, a code span, and end of block", {
  pd = parse_qmd("the cats'. Yes\n", quiet = TRUE)
  expect_identical(str_texts(pd@blocks@content[[1]]), c("the", paste0("cats", rsquo, "."), "Yes"))

  pd = parse_qmd("d'`Arrow`\n", quiet = TRUE)
  inl = pd@blocks@content[[1]]@content@content
  expect_identical(inl[[1]]@text, paste0("d", rsquo))
  expect_true(S7::S7_inherits(inl[[2]], pandoc_code))

  pd = parse_qmd("Cats'\n", quiet = TRUE)
  expect_identical(str_texts(pd@blocks@content[[1]]), paste0("Cats", rsquo))
})

test_that("a leading apostrophe word works in list items, headings, and table cells", {
  pd = parse_qmd("- Dogs' toys.\n\n## Dogs' toys\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_true(S7::S7_inherits(pd@blocks@content[[1]], pandoc_bullet_list))
  expect_true(S7::S7_inherits(pd@blocks@content[[2]], pandoc_header))
  expect_identical(str_texts(pd@blocks@content[[2]]), c(paste0("Dogs", rsquo), "toys"))

  pd = parse_qmd("| Dogs' | b |\n|---|---|\n| x | y |\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_true(S7::S7_inherits(pd@blocks@content[[1]], pandoc_table))
})

test_that("apostrophe words round-trip on both ASTs", {
  srcs = c(
    "Dogs' toys and cats' toys.\n",
    "the cats'. Yes\n",
    "d'`Arrow`\n",
    "Cats'\n",
    "'Dogs' toys'\n",
    "- Dogs' toys.\n\n## Dogs' toys\n",
    "| Dogs' | b |\n|---|---|\n| x | y |\n"
  )
  for (src in srcs) expect_word_apostrophe_roundtrip(src)
})

test_that("a word-final apostrophe inside an open single quote closes it", {
  pd = parse_qmd("'Dogs' toys'\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  inl = pd@blocks@content[[1]]@content@content
  expect_true(S7::S7_inherits(inl[[1]], pandoc_quoted))
  expect_identical(inl[[3]]@text, paste0("toys", rsquo))
})

test_that("a quote mark with whitespace on both sides is still Q-2-10", {
  pd = parse_qmd("a ' b.\n", quiet = TRUE)
  expect_length(pd@diagnostics, 1L)
  expect_identical(pd@diagnostics[[1]]@code, "Q-2-10")

  pd = parse_qmd("a 'more\n", quiet = TRUE)
  expect_identical(pd@diagnostics[[1]]@code, "Q-2-7")
})
