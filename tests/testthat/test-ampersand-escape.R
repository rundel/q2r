# The pampa qmd writer escapes a literal `&` that would lex as a character
# reference as of q2 890b3755 (b15868ed, bd-i18zoy4n, q2#672). A str holding
# `&copy;` (from `\&copy;` in source, or built in R) used to be written bare
# and re-read as `©`, and a literal `&ZeroWidthSpace;` was indistinguishable
# from the reference the writer now emits for a real U+200B. A named reference
# is any semicolon-terminated WHATWG name; a numeric one is `&#` plus 1-7
# decimal digits or `&#x` plus 1-6 hex digits and `;`. Every other `&` stays
# bare. In block context the writer escapes `#` as well, so a literal numeric
# reference comes back as `\&\#62;`.

test_that("an escaped named entity stays literal text through the round trip", {
  pd = parse_qmd("Literal: \\&copy; and \\&nbsp; and \\&ZeroWidthSpace;.\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(ast_text(pd), "Literal: &copy; and &nbsp; and &ZeroWidthSpace;.")
  out = to_qmd(pd)
  expect_identical(out, "Literal: \\&copy; and \\&nbsp; and \\&ZeroWidthSpace;.\n")
  pd2 = parse_qmd(out, quiet = TRUE)
  expect_no_error_diagnostics(pd2)
  expect_pd_ast_equal(pd2, pd)
})

test_that("an escaped numeric reference stays literal text through the round trip", {
  pd = parse_qmd("Literal: \\&#62; and \\&#x200B;.\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(ast_text(pd), "Literal: &#62; and &#x200B;.")
  out = to_qmd(pd)
  expect_identical(out, "Literal: \\&\\#62; and \\&\\#x200B;.\n")
  pd2 = parse_qmd(out, quiet = TRUE)
  expect_no_error_diagnostics(pd2)
  expect_pd_ast_equal(pd2, pd)
})

test_that("a decoded entity and its literal spelling stay distinct", {
  pd = parse_qmd("&copy; vs \\&copy; and a&ZeroWidthSpace;b vs a\\&ZeroWidthSpace;b\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(ast_text(pd), "\u00A9 vs &copy; and a\u200Bb vs a&ZeroWidthSpace;b")
  out = to_qmd(pd)
  expect_identical(out, "\u00A9 vs \\&copy; and a&ZeroWidthSpace;b vs a\\&ZeroWidthSpace;b\n")
  expect_pd_ast_equal(parse_qmd(out, quiet = TRUE), pd)
})

test_that("a str built in R with a reference-shaped `&` is escaped on write", {
  doc = pandoc(blocks = as_blocks(pandoc_paragraph(as_inlines(list(
    pandoc_str("&copy;"), pandoc_space(), pandoc_str("&#34;"), pandoc_space(), pandoc_str("AT&T")
  )))))
  out = to_qmd(doc)
  expect_identical(out, "\\&copy; \\&\\#34; AT&T\n")
  pd = parse_qmd(out, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(ast_text(pd), "&copy; &#34; AT&T")
})

test_that("ampersands that are not references stay bare", {
  src = "AT&T, a & b, &amp and &AM; and &; and a&\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(ast_text(pd), "AT&T, a & b, &amp and &AM; and &; and a&")
  out = to_qmd(pd)
  expect_identical(out, src)
  expect_pd_ast_equal(parse_qmd(out, quiet = TRUE), pd)

  pd = parse_qmd("&#12345678; and &#x1234567; and &#1a;\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(ast_text(pd), "&#12345678; and &#x1234567; and &#1a;")
  out = to_qmd(pd)
  expect_false(grepl("\\&", out, fixed = TRUE))
  expect_pd_ast_equal(parse_qmd(out, quiet = TRUE), pd)
})
