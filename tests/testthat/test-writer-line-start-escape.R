# q2 3d3360ab (c26b3e832) teaches the qmd writer to escape a `Str` that begins
# a line and would re-read as block syntax: a bullet `-` / `+`, an ordered
# marker (`1.`, `12)`), the definition colon, and the `:::` fence. The escape
# only fires when a word boundary follows (`1.5` and `-5` stay), and a `Str`
# starting with `(` directly after a `]` is escaped so `[span](see)` does not
# become a link. The qmd reader never produces these shapes, so only
# R-constructed ASTs (and the orphan-caption literal line) see the change.

doc = function(...) pandoc(blocks = as_blocks(list(...)))
para = function(x) pandoc_paragraph(content = as_inlines(x))
plain_item = function(x) pandoc_blocks(list(pandoc_plain(content = as_inlines(x))))

expect_roundtrip = function(d) {
  expect_pd_ast_equal(parse_qmd(to_qmd(d), quiet = TRUE), d)
}

test_that("a line-start marker word is escaped and round-trips", {
  cases = c(
    "- x"   = "\\- x\n",
    "+ x"   = "\\+ x\n",
    "1. x"  = "1\\. x\n",
    "1) x"  = "1\\) x\n",
    "12. x" = "12\\. x\n",
    ": x"   = "\\: x\n",
    "::: x" = "\\::: x\n"
  )
  for (src in names(cases)) {
    d = doc(para(src))
    expect_identical(to_qmd(d), cases[[src]], info = src)
    expect_roundtrip(d)
  }
})

test_that("a marker that only begins a word is left alone", {
  for (src in c("1.5 x", "-5 x", "+1 x", "a - b + c 1. d : e")) {
    d = doc(para(src))
    expect_identical(to_qmd(d), paste0(src, "\n"), info = src)
    expect_roundtrip(d)
  }
})

test_that("the escape fires after a soft break and at a list-item start", {
  d = doc(pandoc_paragraph(content = as_inlines(list(
    pandoc_str(text = "a"), pandoc_soft_break(),
    pandoc_str(text = "-"), pandoc_space(), pandoc_str(text = "x")
  ))))
  expect_identical(to_qmd(d), "a\n\\- x\n")
  expect_roundtrip(d)

  d = doc(pandoc_bullet_list(content = list(plain_item("1. x"))))
  expect_identical(to_qmd(d), "* 1\\. x\n")
  expect_roundtrip(d)
})

test_that("a span followed by an opening paren does not become a link", {
  d = doc(pandoc_paragraph(content = as_inlines(list(
    pandoc_span(content = as_inlines("range")), pandoc_str(text = "(see)")
  ))))
  expect_identical(to_qmd(d), "[range]\\(see)\n")
  expect_roundtrip(d)
})
