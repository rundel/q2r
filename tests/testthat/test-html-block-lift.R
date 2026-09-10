# Block-level raw HTML at the head of a paragraph is lifted to a RawBlock as of
# q2 914f2069 (bdacd112, bd-block-html-wrapped-in-p-w8qebxig). The reader used
# to leave `<div>` as a RawInline inside a Paragraph, which rendered as a `<p>`
# wrapping flow content. The tag set is pandoc's block-tag whitelist plus the
# `<!` / `<?` forms; inline tags at paragraph start stay a paragraph. The qmd
# writer also emits an HTML-comment RawBlock natively instead of a `{=html}`
# fence. Since b7e7c96a the lifted paragraph is split at its prose (see
# test-html-block-split.R); this file pins the lift itself.

raw_html_blocks = function(pd) {
  purrr::keep(pd@blocks@content, function(b) S7::S7_inherits(b, pandoc_raw_block))
}

lift_srcs = list(
  div     = "<div class=\"x\">\n\nText.\n\n</div>\n",
  details = "<details class=\"c\">\n<summary>Sums</summary>\n\nText.\n\n</details>\n",
  comment = "<!-- hello -->\n\nText.\n",
  quoted  = "> <div>\n> <span>x</span>\n"
)

test_that("a paragraph opening with a block-level tag becomes a raw html block", {
  pd = parse_qmd(lift_srcs$div, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  blocks = pd@blocks@content
  expect_length(blocks, 3L)
  expect_true(S7::S7_inherits(blocks[[1]], pandoc_raw_block))
  expect_identical(blocks[[1]]@format, "html")
  expect_identical(blocks[[1]]@text, "<div class=\"x\">")
  expect_identical(ast_text(blocks[[2]]), "Text.")
  expect_identical(blocks[[3]]@text, "</div>")
})

test_that("a run of block-level tags is lifted as one block ahead of its prose", {
  pd = parse_qmd(lift_srcs$details, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(pd@blocks[[1]]@text, "<details class=\"c\">\n<summary>")
  expect_true(S7::S7_inherits(pd@blocks[[2]], pandoc_plain))
  expect_identical(pd@blocks[[3]]@text, "</summary>")

  pd = parse_qmd(lift_srcs$quoted, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(pd@blocks[[1]]@content[[1]]@text, "<div>")
  expect_true(S7::S7_inherits(pd@blocks[[1]]@content[[2]], pandoc_plain))
})

test_that("inline tags and near-miss names at paragraph start are not lifted", {
  for (src in c("<span class=\"x\">hi</span> there\n", "<divider>x\n")) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_no_error_diagnostics(pd)
    expect_length(pd@blocks@content, 1L)
    expect_length(raw_html_blocks(pd), 0L)
  }
})

test_that("a standalone html comment round-trips natively, not as a {=html} fence", {
  pd = parse_qmd(lift_srcs$comment, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(pd@blocks[[1]]@text, "<!-- hello -->")
  out = to_qmd(pd)
  expect_false(grepl("{=html}", out, fixed = TRUE))
  expect_match(out, "<!-- hello -->", fixed = TRUE)
  expect_pd_ast_equal(parse_qmd(out, quiet = TRUE), pd)
})

test_that("lifted blocks round-trip through the pampa qmd writer", {
  # The tight `details` and `quoted` sources split into raw / plain runs and
  # canonicalize on the first write; test-html-block-split.R pins that.
  for (nm in c("div", "comment")) {
    pd = parse_qmd(lift_srcs[[nm]], quiet = TRUE)
    expect_no_error_diagnostics(pd)
    expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
  }
})

test_that("Q-2-9 still fires and describes a lifted tag as a raw html block", {
  pd = parse_qmd("<div>\n\nx\n\n</div>\n", quiet = TRUE)
  codes = purrr::map_chr(pd@diagnostics, function(d) d@code)
  expect_identical(codes, c("Q-2-9", "Q-2-9"))
  expect_match(format(pd@diagnostics[[1]], color = FALSE), "raw HTML block", fixed = TRUE)
})
