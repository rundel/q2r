test_that("ast_text on a plain paragraph returns the text", {
  doc = parse_qmd("Hello world.\n")
  expect_equal(ast_text(doc), "Hello world.")
})

test_that("ast_text drops inline formatting", {
  doc = parse_qmd("a *b* **c** d\n")
  expect_equal(ast_text(doc), "a b c d")
})

test_that("ast_text emits @text for code and math", {
  doc = parse_qmd("a `code` b $x^2$ c\n")
  expect_equal(ast_text(doc), "a code b x^2 c")
})

test_that("ast_text uses two newlines between blocks", {
  doc = parse_qmd("Para one.\n\nPara two.\n")
  expect_equal(ast_text(doc), "Para one.\n\nPara two.")
})

test_that("ast_text walks header content", {
  doc = parse_qmd("# Hello *world*\n")
  expect_equal(ast_text(doc), "Hello world")
})

test_that("ast_text works on a single inline node", {
  doc = parse_qmd("**bold text**\n")
  strong = select_first(doc, is(pandoc_strong))
  expect_equal(ast_text(strong), "bold text")
})

test_that("ast_text works on a pandoc_inlines wrapper", {
  doc = parse_qmd("a *b* c\n")
  para = select_first(doc, is(pandoc_paragraph))
  expect_equal(ast_text(para@content), "a b c")
})

test_that("ast_text on a list of inline nodes joins without separator", {
  nodes = list(pandoc_str(text = "a"), pandoc_space(), pandoc_str(text = "b"))
  expect_equal(ast_text(nodes), "a b")
})

test_that("ast_text on a code block returns its @text", {
  doc = parse_qmd("```\nfoo bar\n```\n")
  expect_equal(ast_text(doc), "foo bar")
})

test_that("ast_text on a link emits the label, not the url", {
  doc = parse_qmd("see [the docs](https://example.com)\n")
  expect_equal(ast_text(doc), "see the docs")
})

test_that("ast_text on a bullet list joins items with newlines", {
  doc = parse_qmd("- one\n- two\n- three\n")
  txt = ast_text(doc)
  expect_match(txt, "one")
  expect_match(txt, "two")
  expect_match(txt, "three")
})
