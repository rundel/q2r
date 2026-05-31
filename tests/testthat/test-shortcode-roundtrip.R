# Regression test for nested-shortcode arguments. A shortcode used as the
# argument of another shortcode (e.g. `{{< video {{< meta url >}} >}}`) parses
# into a nested `pandoc_shortcode` S7 object; to_qmd() must re-serialize that
# nested object rather than handing it to the Rust writer verbatim (which
# previously failed with "expected a list").

shortcode_srcs = list(
  plain_positional = "{{< video foo.mp4 >}}\n",
  nested_positional = "{{< video {{< meta url >}} >}}\n",
  include          = "{{< include file.qmd >}}\n",
  keyword_args     = "{{< foo bar=baz >}}\n",
  nested_in_keyword = "{{< foo key={{< meta b >}} >}}\n"
)

test_that("to_qmd() reconstructs shortcodes identically to pampa's own writer", {
  for (nm in names(shortcode_srcs)) {
    src = shortcode_srcs[[nm]]
    pd = parse_qmd(src, quiet = TRUE)
    expect_false(has_error_diagnostics(pd), info = nm)
    q2r_out = to_qmd(pd)
    pampa_out = q2r:::pampa_write_qmd_text_impl(src, "<text>")$text
    expect_identical(q2r_out, pampa_out, info = nm)
  }
})

test_that("nested shortcode round-trips without error", {
  src = "{{< video {{< meta url >}} >}}\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_no_error(out <- to_qmd(pd))
  expect_identical(out, src)
})
