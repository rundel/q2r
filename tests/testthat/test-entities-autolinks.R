# Since q2 1ba0f2ec named entities decode in prose (`&copy;` becomes a `©`
# str), with the qmd writer escaping a bare `"` as `\"` so the decoded text
# does not re-read as a smart quote, and CommonMark email autolinks parse as
# mailto links carrying the `email` class, `<mailto:addr>` displaying the bare
# address.

test_that("named entities decode to plain strs and round-trip escaped", {
  pd = parse_qmd("&copy; 2026 &amp; &quot;x&quot; y\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(ast_text(pd), "© 2026 & \"x\" y")
  out = to_qmd(pd)
  expect_identical(out, "© 2026 & \\\"x\\\" y\n")
  expect_pd_ast_equal(parse_qmd(out, quiet = TRUE), pd)
})

test_that("email autolinks become mailto links with the email class", {
  pd = parse_qmd("<user@example.com> and <mailto:user@example.com>\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  links = as.list(select_nodes(pd, is(pandoc_link)))
  expect_length(links, 2L)
  for (l in links) {
    expect_identical(l@url, "mailto:user@example.com")
    expect_identical(l@attr@classes, "email")
    expect_identical(ast_text(l), "user@example.com")
  }
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})
