# q2 08a1d37d / f4c4ec18 (bd-ykjwiqcc, GH #877): the qmd writer now spells an
# image's alt text as `fig-alt` wherever the bracket text cannot carry it. A
# lone image in a paragraph with alt inlines is written `![](src){fig-alt=..}`
# (as `![alt](src)` it would re-read as a figure captioned by its alt), and a
# figure whose image alt differs from its caption (an empty alt included) is
# written `![Caption](src){fig-alt=..}` instead of the fenced-div fallback.
# The reader never produces these shapes, so only R-constructed or
# filter-modified ASTs reach them and no quarto-web fixture covers them.

para_of = function(...) pandoc_paragraph(content = pandoc_inlines(list(...)))

doc_of = function(...) pandoc(blocks = pandoc_blocks(list(...)))

figure_of = function(caption, image) {
  pandoc_figure(
    caption = pandoc_caption(
      long = pandoc_blocks(list(pandoc_plain(content = as_inlines(caption))))
    ),
    content = pandoc_blocks(list(pandoc_plain(content = pandoc_inlines(list(image)))))
  )
}

alt_img = pandoc_image(
  content = as_inlines("Alt A"),
  url = "a.png",
  attr = pandoc_attr(classes = "wide", attributes = c(width = "50%"))
)

test_that("a lone image with alt text is written with fig-alt", {
  out = to_qmd(doc_of(para_of(alt_img)))
  expect_identical(out, "![](a.png){.wide width=\"50%\" fig-alt=\"Alt A\"}\n")

  pd = parse_qmd(out, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_s3_class(pd@blocks[[1]], "q2r::pandoc_paragraph")
  img = pd@blocks[[1]]@content[[1]]
  expect_s3_class(img, "q2r::pandoc_image")
  expect_length(img@content, 0L)
  expect_identical(img@attr@attributes[["fig-alt"]], "Alt A")
  expect_identical(to_qmd(pd), out)
})

test_that("a lone image alt containing quotes is escaped", {
  img = pandoc_image(content = as_inlines("say \"hi\""), url = "a.png")
  expect_identical(
    to_qmd(doc_of(para_of(img))),
    "![](a.png){fig-alt=\"say \\\"hi\\\"\"}\n"
  )
})

test_that("an existing fig-alt key beats the alt inlines", {
  img = pandoc_image(
    content = as_inlines("inlines"),
    url = "a.png",
    attr = pandoc_attr(attributes = c("fig-alt" = "Key"))
  )
  expect_identical(to_qmd(doc_of(para_of(img))), "![](a.png){fig-alt=\"Key\"}\n")
})

test_that("an inline image that is not alone keeps its alt inlines", {
  doc = doc_of(para_of(pandoc_str(text = "Text"), pandoc_space(), alt_img))
  out = to_qmd(doc)
  expect_identical(out, "Text ![Alt A](a.png){.wide width=\"50%\"}\n")
  expect_pd_ast_equal(parse_qmd(out, quiet = TRUE), doc)
})

test_that("a figure whose alt is not its caption is written with fig-alt", {
  fig = figure_of("Caption B", pandoc_image(content = as_inlines("Alt B"), url = "b.png"))
  out = to_qmd(doc_of(fig))
  expect_identical(out, "![Caption B](b.png){fig-alt=\"Alt B\"}\n")

  pd = parse_qmd(out, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_s3_class(pd@blocks[[1]], "q2r::pandoc_figure")
  img = pd@blocks[[1]]@content[[1]]@content[[1]]
  expect_identical(ast_text(img), "Caption B")
  expect_identical(img@attr@attributes[["fig-alt"]], "Alt B")
  expect_identical(to_qmd(pd), out)
})

test_that("a figure with an empty alt is written with an empty fig-alt", {
  fig = figure_of("Cap I", pandoc_image(url = "i.png"))
  expect_identical(to_qmd(doc_of(fig)), "![Cap I](i.png){fig-alt=\"\"}\n")
})

test_that("a parsed implicit figure still round-trips as a bare image", {
  src = "![cap](b.png){#fig-b fig-alt=\"Alt B\"}\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_s3_class(pd@blocks[[1]], "q2r::pandoc_figure")
  expect_identical(to_qmd(pd), src)
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})
