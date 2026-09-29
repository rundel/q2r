# Whitespace-adjacent `*` `_` `~` `^` runs are literal text as of q2 10e16e0c
# (206826fd6, bd-star-as-str-qigl02pz, q2#731). A `*` or `_` run followed by
# whitespace cannot open and one preceded by whitespace or a line start cannot
# close (CommonMark's flanking rules), and a `~` or `^` only opens a subscript
# or superscript when its closer appears before the next unescaped whitespace
# (Pandoc's rule). Such a delimiter used to raise an unclosed-emphasis parse
# error. The pampa qmd writer escapes the literal delimiter (`a \* b`) and,
# because `~a b~` no longer reads back as a subscript, writes every space or
# soft break inside a subscript / superscript as `\ `, which re-reads as a
# no-break space.

shape = function(inl) {
  purrr::map_chr(inl, function(x) {
    if (S7::S7_inherits(x, pandoc_str)) x@text
    else if (S7::S7_inherits(x, pandoc_space)) "<sp>"
    else if (S7::S7_inherits(x, pandoc_soft_break)) "<sb>"
    else sub("q2r::", "", class(x)[1])
  })
}

para_shape = function(pd) shape(pd@blocks[[1]]@content@content)

literal = list(
  "a * b\n"           = c("a", "<sp>", "*", "<sp>", "b"),
  "foo *\n"           = c("foo", "<sp>", "*"),
  "first *\nsecond\n" = c("first", "<sp>", "*", "<sb>", "second"),
  "a ** b\n"          = c("a", "<sp>", "**", "<sp>", "b"),
  "*x* * y\n"         = c("pandoc_emph", "<sp>", "*", "<sp>", "y"),
  "a _ b\n"           = c("a", "<sp>", "_", "<sp>", "b"),
  "_\n"               = "_",
  "_ a and b _\n"     = c("_", "<sp>", "a", "<sp>", "and", "<sp>", "b", "<sp>", "_"),
  "a ~ b\n"           = c("a", "<sp>", "~", "<sp>", "b"),
  "a ~5 and ~10 b\n"  = c("a", "<sp>", "~5", "<sp>", "and", "<sp>", "~10", "<sp>", "b"),
  "~a and b~\n"       = c("~a", "<sp>", "and", "<sp>", "b~"),
  "x ^2 and y ^3 z\n" = c("x", "<sp>", "^2", "<sp>", "and", "<sp>", "y", "<sp>", "^3", "<sp>", "z"),
  "2^10 and 3^4\n"    = c("2^10", "<sp>", "and", "<sp>", "3^4")
)

test_that("whitespace-adjacent delimiters parse as literal str on the pandoc path", {
  for (src in names(literal)) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_no_error_diagnostics(pd)
    expect_identical(para_shape(pd), literal[[src]], info = src)
  }

  pd = parse_qmd("**a * b**\n", quiet = TRUE)
  expect_identical(shape(pd@blocks[[1]]@content[[1]]@content@content), c("a", "<sp>", "*", "<sp>", "b"))
})

test_that("literal delimiters are escaped by the writer and round-trip", {
  expect_identical(to_qmd(parse_qmd("a * b\n", quiet = TRUE)), "a \\* b\n")
  expect_identical(to_qmd(parse_qmd("a _ b\n", quiet = TRUE)), "a \\_ b\n")
  expect_identical(to_qmd(parse_qmd("2^10 and 3^4\n", quiet = TRUE)), "2\\^10 and 3\\^4\n")
  for (src in names(literal)) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
  }
})

test_that("literal delimiters byte-recover on the tree-sitter path", {
  for (src in names(literal)) {
    ts = parse_qmd(src, ast = "ts", quiet = TRUE)
    expect_no_error_diagnostics(ts)
    expect_length(as.list(select_nodes(ts, kind == "ERROR")), 0L)
    expect_identical(to_qmd(ts), src, info = src)
    expect_ts_ast_equal(parse_qmd(to_qmd(ts), ast = "ts", quiet = TRUE), ts)
  }

  # The scanner folds the whitespace in front of a literal token into the
  # pandoc_str leaf; the reader splits it back out into a Space inline.
  ts = parse_qmd("a * b\n", ast = "ts", quiet = TRUE)
  strs = purrr::map_chr(as.list(select_nodes(ts, kind == "pandoc_str")), function(n) n@text)
  expect_identical(strs, c("a", " *", "b"))
})

test_that("spaces inside a subscript or superscript are written escaped", {
  doc = pandoc(blocks = pandoc_blocks(list(pandoc_paragraph(pandoc_inlines(list(
    pandoc_subscript(pandoc_inlines(list(pandoc_str("a"), pandoc_space(), pandoc_str("b")))),
    pandoc_space(),
    pandoc_str("x"),
    pandoc_superscript(pandoc_inlines(list(pandoc_str("c"), pandoc_soft_break(), pandoc_str("d"))))
  ))))))
  out = to_qmd(doc)
  expect_identical(out, "~a\\ b~ x^c\\ d^\n")

  pd = parse_qmd(out, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  inl = pd@blocks[[1]]@content@content
  expect_true(S7::S7_inherits(inl[[1]], pandoc_subscript))
  expect_identical(inl[[1]]@content[[1]]@text, "a b")
  expect_true(S7::S7_inherits(inl[[4]], pandoc_superscript))
  expect_identical(inl[[4]]@content[[1]]@text, "c d")
})

test_that("properly flanked delimiters still open markup", {
  expect_identical(para_shape(parse_qmd("H~2~O\n", quiet = TRUE)), c("H", "pandoc_subscript", "O"))
  expect_identical(para_shape(parse_qmd("x^2^\n", quiet = TRUE)), c("x", "pandoc_superscript"))
  expect_identical(para_shape(parse_qmd("~~gone~~ here\n", quiet = TRUE)), c("pandoc_strikeout", "<sp>", "here"))
  expect_identical(para_shape(parse_qmd("foo*bar*baz\n", quiet = TRUE)), c("foo", "pandoc_emph", "baz"))
  expect_identical(para_shape(parse_qmd("_a and b_\n", quiet = TRUE)), "pandoc_emph")
  expect_identical(para_shape(parse_qmd("a \\* b\n", quiet = TRUE)), c("a", "<sp>", "*", "<sp>", "b"))
})

test_that("an opened but unclosed delimiter is still a parse error", {
  unclosed = c("a *b c\n" = "Q-2-12", "**bold **\n" = "Q-2-13", "_quarto.yml and _metadata.yml\n" = "Q-2-5", "_a\n" = "Q-2-5")
  for (src in names(unclosed)) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_true(has_error_diagnostics(pd), info = src)
    expect_identical(pd@diagnostics[[1]]@code, unclosed[[src]], info = src)
  }
})
