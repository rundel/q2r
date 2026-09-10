# A lifted block-HTML paragraph is split as of q2 b7e7c96a
# (bd-block-html-adjacent-markdown-unparsed-0qnjuwuy). The 914f2069 lift kept
# the paragraph as one verbatim raw block, which also switched off inline
# parsing inside it. Now runs of block-level tags coalesce into one raw block
# joined by newlines, the prose between them parses as a plain block with full
# inline markup, and the raw-text elements `<pre>` / `<script>` / `<style>` /
# `<textarea>` stay verbatim. The qmd writer emits block-level raw HTML (tag
# runs, raw-text elements, comments) bare rather than inside a `{=html}` fence
# and keeps the fence for anything else. Blocks are always written blank-line
# separated, so a split interior re-reads as a paragraph: the shape is stable
# from the first write on.

block_kinds = function(x) {
  blocks = if (S7::S7_inherits(x, pandoc_blocks)) x@content else x
  purrr::map_chr(blocks, function(b) sub("^q2r::pandoc_", "", class(b)[[1]]))
}

inline_kinds = function(block) {
  purrr::map_chr(block@content@content, function(i) sub("^q2r::pandoc_", "", class(i)[[1]]))
}

split_srcs = list(
  tight   = "<div class=\"case-b\">\nText with a `code span` and *emphasis*.\n</div>\n",
  details = "<details class=\"c\">\n<summary>Sums</summary>\n\nText.\n\n</details>\n",
  comment = "<div>\n<!-- fix: a -> b -->\ntext\n</div>\n",
  quoted  = "> <div>\n> <span>x</span>\n",
  listed  = "1. item\n\n   <div>\n   text `code`\n   </div>\n"
)

test_that("a tight block-html paragraph splits into raw tag runs and parsed prose", {
  pd = parse_qmd(split_srcs$tight, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  blocks = pd@blocks@content
  expect_identical(block_kinds(blocks), c("raw_block", "plain", "raw_block"))
  expect_identical(blocks[[1]]@text, "<div class=\"case-b\">")
  expect_identical(blocks[[3]]@text, "</div>")
  expect_identical(ast_text(blocks[[2]]), "Text with a code span and emphasis.")
  expect_true(all(c("code", "emph") %in% inline_kinds(blocks[[2]])))

  codes = purrr::map_chr(pd@diagnostics, function(d) d@code)
  expect_identical(codes, c("Q-2-9", "Q-2-9"))
})

test_that("consecutive block tags coalesce into one raw block joined by newlines", {
  pd = parse_qmd(split_srcs$details, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  blocks = pd@blocks@content
  expect_identical(
    block_kinds(blocks),
    c("raw_block", "plain", "raw_block", "paragraph", "raw_block")
  )
  expect_identical(blocks[[1]]@text, "<details class=\"c\">\n<summary>")
  expect_identical(ast_text(blocks[[2]]), "Sums")
  expect_identical(blocks[[3]]@text, "</summary>")
  expect_identical(ast_text(blocks[[4]]), "Text.")
  expect_identical(blocks[[5]]@text, "</details>")

  pd = parse_qmd(split_srcs$comment, quiet = TRUE)
  expect_identical(pd@blocks[[1]]@text, "<div>\n<!-- fix: a -> b -->")
})

test_that("tags with only whitespace between them stay one raw block", {
  pd = parse_qmd("<!-- first --> <!-- second --> <!-- third -->\n", quiet = TRUE)
  expect_identical(block_kinds(pd@blocks), "raw_block")
  expect_identical(pd@blocks[[1]]@text, "<!-- first --> <!-- second --> <!-- third -->")

  pd = parse_qmd("<div>   \n</div>\n", quiet = TRUE)
  expect_identical(block_kinds(pd@blocks), "raw_block")
  expect_identical(pd@blocks[[1]]@text, "<div>\n</div>")
})

test_that("an html comment followed by text on the same line splits", {
  pd = parse_qmd("<!-- c --> followed by `x`\n", quiet = TRUE)
  blocks = pd@blocks@content
  expect_identical(block_kinds(blocks), c("raw_block", "plain"))
  expect_identical(blocks[[1]]@text, "<!-- c -->")
  expect_identical(inline_kinds(blocks[[2]]), c("str", "space", "str", "space", "code"))
})

test_that("a hard line break at the tag boundary is not content", {
  pd = parse_qmd("<div class=\"x\">  \ntext with a `code span`\n</div>\n", quiet = TRUE)
  blocks = pd@blocks@content
  expect_identical(block_kinds(blocks), c("raw_block", "plain", "raw_block"))
  expect_false("line_break" %in% inline_kinds(blocks[[2]]))
  expect_true("code" %in% inline_kinds(blocks[[2]]))
})

test_that("raw-text elements keep their content verbatim, a closing tag does not", {
  for (tag in c("pre", "script", "style", "textarea")) {
    src = paste0("<", tag, ">\ntext with a `code span` and *emphasis*.\n</", tag, ">\n")
    pd = parse_qmd(src, quiet = TRUE)
    expect_identical(block_kinds(pd@blocks), "raw_block")
    expect_match(pd@blocks[[1]]@text, "`code span` and *emphasis*", fixed = TRUE)
  }

  pd = parse_qmd("> <pre>\n> raw `code` *em*\n> </pre>\n", quiet = TRUE)
  quoted = pd@blocks[[1]]@content
  expect_identical(block_kinds(quoted), "raw_block")
  expect_identical(quoted[[1]]@text, "<pre>\nraw `code` *em*\n</pre>")

  pd = parse_qmd("</pre>\ntext with a `code span`\n", quiet = TRUE)
  blocks = pd@blocks@content
  expect_identical(block_kinds(blocks), c("raw_block", "plain"))
  expect_true("code" %in% inline_kinds(blocks[[2]]))
})

test_that("the split happens inside block quotes and list items", {
  pd = parse_qmd(split_srcs$quoted, quiet = TRUE)
  quoted = pd@blocks[[1]]@content
  expect_identical(block_kinds(quoted), c("raw_block", "plain"))
  expect_identical(quoted[[1]]@text, "<div>")
  expect_identical(inline_kinds(quoted[[2]]), c("raw_inline", "str", "raw_inline"))

  pd = parse_qmd(split_srcs$listed, quiet = TRUE)
  item = pd@blocks[[1]]@content[[1]]
  expect_identical(block_kinds(item), c("paragraph", "raw_block", "plain", "raw_block"))
  expect_true("code" %in% inline_kinds(item[[3]]))
})

test_that("block-level raw html writes bare and other raw html keeps its fence", {
  for (src in c("<div class=\"a\">\n\nbody\n\n</div>\n", "<pre>\ntext with a `code span`\n</pre>\n")) {
    expect_identical(to_qmd(parse_qmd(src, quiet = TRUE)), src)
  }

  src = "```{=html}\n<div class=\"authored\">\nstill `raw` inside\n\n# not a header\n</div>\n```\n"
  out = to_qmd(parse_qmd(src, quiet = TRUE))
  expect_match(out, "```{=html}", fixed = TRUE)
  pd2 = parse_qmd(out, quiet = TRUE)
  expect_identical(block_kinds(pd2@blocks), "raw_block")
  expect_match(pd2@blocks[[1]]@text, "still `raw` inside", fixed = TRUE)
  expect_match(pd2@blocks[[1]]@text, "# not a header", fixed = TRUE)

  raw_doc = function(text) pandoc(blocks = pandoc_blocks(list(pandoc_raw_block("html", text))))
  expect_identical(to_qmd(raw_doc("<span>x</span>")), "```{=html}\n<span>x</span>\n```\n")
  expect_identical(to_qmd(raw_doc("<div>\n")), "<div>\n")
})

test_that("a split re-reads to a stable shape after one write", {
  for (nm in names(split_srcs)) {
    pd = parse_qmd(split_srcs[[nm]], quiet = TRUE)
    once = to_qmd(pd)
    expect_false(grepl("```{=html}", once, fixed = TRUE), info = nm)
    pd1 = parse_qmd(once, quiet = TRUE)
    expect_no_error_diagnostics(pd1)
    expect_identical(to_qmd(pd1), once, info = nm)
    expect_pd_ast_equal(parse_qmd(to_qmd(pd1), quiet = TRUE), pd1)
  }

  pd1 = parse_qmd(to_qmd(parse_qmd(split_srcs$tight, quiet = TRUE)), quiet = TRUE)
  expect_identical(block_kinds(pd1@blocks), c("raw_block", "paragraph", "raw_block"))
  expect_true(all(c("code", "emph") %in% inline_kinds(pd1@blocks[[2]])))
})

test_that("the writer does not merge unrelated blocks into one html run", {
  doc = pandoc(blocks = pandoc_blocks(list(
    pandoc_plain(as_inlines("alpha")), pandoc_raw_block("html", "<div>"),
    pandoc_plain(as_inlines("beta")), pandoc_raw_block("html", "</div>")
  )))
  pd2 = parse_qmd(to_qmd(doc), quiet = TRUE)
  expect_identical(
    block_kinds(pd2@blocks),
    c("paragraph", "raw_block", "paragraph", "raw_block")
  )

  src = "<div class=\"note\">\nSee below.\n\n<script>\nconst t = `hi`;\n</script>\n"
  pd2 = parse_qmd(to_qmd(parse_qmd(src, quiet = TRUE)), quiet = TRUE)
  expect_identical(block_kinds(pd2@blocks), c("raw_block", "paragraph", "raw_block"))
  expect_match(pd2@blocks[[3]]@text, "const t = `hi`;", fixed = TRUE)
})

test_that("raw html inside a metadata block scalar still parses", {
  pd = parse_qmd(
    "---\ninclude-in-header:\n  - text: |\n      <meta name=\"a\" content=\"1\">\n\n      <meta name=\"b\" content=\"2\">\n---\n\nBody.\n",
    quiet = TRUE
  )
  expect_no_error_diagnostics(pd)
  text = pd@meta@value[["include-in-header"]]@value[[1]]@value[["text"]]
  expect_identical(text@kind, "blocks")
  expect_identical(block_kinds(text@value), c("raw_block", "raw_block"))
})
