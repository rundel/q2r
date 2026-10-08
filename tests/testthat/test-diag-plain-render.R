# quarto-error-reporting 0.4.0 (q2 3d3360ab, 874b9ac66, bd-ckbqmupi) lets the
# caller turn ariadne's colour off at render time via
# `TextRenderOptions::default().color(false)`. `format(x, color = FALSE)` now
# passes that flag through `pampa_diag_format_impl` instead of rendering in
# colour and stripping with `cli::ansi_strip()` afterwards, so the plain text
# comes out of Rust with no escape sequences of any kind.

plain_diag = function(src) {
  pd = parse_qmd(src, quiet = TRUE)
  expect_true(length(pd@diagnostics) >= 1L)
  pd@diagnostics[[1]]
}

test_that("color = FALSE renders with no escape sequences straight from Rust", {
  d = plain_diag("# a {.c #i}\n")
  plain = format(d, color = FALSE)
  expect_false(grepl("\033", plain, fixed = TRUE))
  expect_identical(plain, cli::ansi_strip(plain))
  expect_match(plain, "[Q-2-55]", fixed = TRUE)
  expect_match(plain, "<text>:1:9", fixed = TRUE)
  expect_match(plain, "cannot appear before the identifier", fixed = TRUE)
})

test_that("color = TRUE still carries ANSI colour and strips to the plain text", {
  d = plain_diag("# a {.c #i}\n")
  colored = format(d, color = TRUE)
  expect_true(grepl("\033[", colored, fixed = TRUE))
  expect_identical(cli::ansi_strip(colored), format(d, color = FALSE))
})

test_that("the plain switch covers warnings, multi-label details and print()", {
  for (src in c("Term\n\n: a definition\n", "[x](\n", "```{{python}}\n1\n```\n")) {
    d = plain_diag(src)
    plain = format(d, color = FALSE)
    expect_false(grepl("\033", plain, fixed = TRUE), info = src)
    expect_identical(cli::ansi_strip(format(d, color = TRUE)), plain, info = src)
    out = paste(capture.output(print(d, color = FALSE)), collapse = "\n")
    expect_false(grepl("\033", out, fixed = TRUE), info = src)
  }
})
