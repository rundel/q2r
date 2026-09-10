# Q-2-41 (literal braces are reserved for attribute syntax) fires inside
# emphasis, strong, quotes, superscript, and pipe-table cells since q2
# eda49bc4, instead of the generic uncoded parse error those inline containers
# used to produce (one LR state per container).

brace_srcs = c(
  bare   = "{foo}\n",
  prose  = "a {foo} b\n",
  emph   = "*{foo}*\n",
  strong = "**{foo}**\n",
  quoted = "\"{foo}\"\n",
  sup    = "x^{foo}^\n",
  cell   = "| a |\n|---|\n| {foo} |\n"
)

test_that("literal braces are Q-2-41 in every inline context", {
  for (nm in names(brace_srcs)) {
    pd = parse_qmd(brace_srcs[[nm]], quiet = TRUE)
    expect_true(has_error_diagnostics(pd), info = nm)
    expect_identical(
      purrr::map_chr(pd@diagnostics, function(d) d@code), "Q-2-41",
      info = nm
    )
  }
})

test_that("escaped braces are plain text", {
  pd = parse_qmd("a \\{foo\\} b\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(ast_text(pd), "a {foo} b")
})
