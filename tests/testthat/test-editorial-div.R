# Block-level editorial marks `::: ++` / `::: --` / `::: >>` / `::: !!` are
# fenced-div sigils as of q2 10e16e0c (5337b87ef, 54824ea1b, bd-an9gkxnp).
# tree-sitter-qmd gives them their own `editorial_div` node whose first child
# is an `insert_delimiter` / `delete_delimiter` / `edit_comment_delimiter` /
# `highlight_delimiter` leaf; pampa lowers that straight to a Div whose first
# class is `quarto-insert` / `quarto-delete` / `quarto-edit-comment` /
# `quarto-highlight`, followed by the user's own attributes (a user-written
# duplicate of the mark class is dropped). The pampa qmd writer inverts this
# for any Div whose first class is one of the four, so `::: {.quarto-delete
# .x}` canonicalizes to `::: -- {.x}`. A bare div info string may no longer
# start with `-`: `::: --foo` raises the new Q-2-53.

marks  = c("++" = "quarto-insert", "--" = "quarto-delete", ">>" = "quarto-edit-comment", "!!" = "quarto-highlight")
delims = c("++" = "insert_delimiter", "--" = "delete_delimiter", ">>" = "edit_comment_delimiter", "!!" = "highlight_delimiter")

div_src = function(mark, attr = "") paste0("::: ", mark, attr, "\n\nBody.\n\n:::\n")

test_that("block editorial marks parse as a div carrying the mark class first", {
  for (mark in names(marks)) {
    pd = parse_qmd(div_src(mark), quiet = TRUE)
    expect_no_error_diagnostics(pd)
    expect_length(pd@blocks@content, 1L)
    div = pd@blocks[[1]]
    expect_true(S7::S7_inherits(div, pandoc_div))
    expect_identical(div@attr@id, "")
    expect_identical(div@attr@classes, marks[[mark]], info = mark)
    expect_length(div@attr@attributes, 0L)
    expect_length(div@content@content, 1L)
    expect_identical(ast_text(div), "Body.")
  }

  pd = parse_qmd("::: >> {#c .extra author=\"cs\"}\n\nWhy?\n\n:::\n", quiet = TRUE)
  expect_identical(pd@blocks[[1]]@attr@id, "c")
  expect_identical(pd@blocks[[1]]@attr@classes, c("quarto-edit-comment", "extra"))
  expect_identical(pd@blocks[[1]]@attr@attributes, c(author = "cs"))

  pd = parse_qmd("::: -- {.quarto-delete .x}\n\nGone.\n\n:::\n", quiet = TRUE)
  expect_identical(pd@blocks[[1]]@attr@classes, c("quarto-delete", "x"))

  pd = parse_qmd("::: ++{.x}\n\nAdded.\n\n:::\n", quiet = TRUE)
  expect_identical(pd@blocks[[1]]@attr@classes, c("quarto-insert", "x"))
})

test_that("the writer emits the block marker for a div whose first class is a mark class", {
  for (src in c("::: -- {#x .a key=\"v\"}\n\nGone.\n\n:::\n", "::: >>\n\nWhy?\n\n:::\n", div_src("!!"))) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_identical(to_qmd(pd), src)
    expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
  }
  expect_identical(to_qmd(parse_qmd("::: ++{.x}\n\nAdded.\n\n:::\n", quiet = TRUE)), "::: ++ {.x}\n\nAdded.\n\n:::\n")
  expect_identical(to_qmd(parse_qmd("::: {.quarto-delete .x}\n\nGone.\n\n:::\n", quiet = TRUE)), "::: -- {.x}\n\nGone.\n\n:::\n")

  doc = pandoc(blocks = pandoc_blocks(list(pandoc_div(
    attr    = pandoc_attr(classes = c("quarto-highlight", "x")),
    content = pandoc_blocks(list(pandoc_paragraph(pandoc_inlines(list(pandoc_str("Bright."))))))
  ))))
  expect_identical(to_qmd(doc), "::: !! {.x}\n\nBright.\n\n:::\n")
})

test_that("a mark class that is not first, inline marks, and plain divs are unchanged", {
  src = "::: {.x .quarto-delete}\n\nGone.\n\n:::\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_identical(pd@blocks[[1]]@attr@classes, c("x", "quarto-delete"))
  expect_identical(to_qmd(pd), src)

  pd = parse_qmd("Text [++ added]{.x key=\"v\"} here.\n", quiet = TRUE)
  span = pd@blocks[[1]]@content@content[[3]]
  expect_true(S7::S7_inherits(span, pandoc_span))
  expect_identical(span@attr@classes, c("quarto-insert", "x"))

  pd = parse_qmd("::: note\n\nText.\n\n:::\n", quiet = TRUE)
  expect_identical(pd@blocks[[1]]@attr@classes, "note")
})

test_that("a div info string starting with - raises Q-2-53 on both paths", {
  for (src in c("::: --foo\n\nText.\n\n:::\n", ":::--foo\n\nText.\n\n:::\n")) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_true(has_error_diagnostics(pd), info = src)
    expect_identical(pd@diagnostics[[1]]@code, "Q-2-53")
    expect_identical(pd@diagnostics[[1]]@title, "Fenced div info string starts with `-`")
    ts = parse_qmd(src, ast = "ts", quiet = TRUE)
    expect_identical(ts@diagnostics[[1]]@code, "Q-2-53")
  }
})

test_that("block editorial marks byte-recover on the tree-sitter path", {
  for (mark in names(marks)) {
    src = div_src(mark, " {.x}")
    ts = parse_qmd(src, ast = "ts", quiet = TRUE)
    expect_no_error_diagnostics(ts)
    divs = as.list(select_nodes(ts, kind == "editorial_div"))
    expect_length(divs, 1L)
    expect_length(as.list(select_nodes(ts, kind == "pandoc_div")), 0L)
    first = divs[[1]]@children@content[[1]]
    expect_identical(first@kind, delims[[mark]])
    expect_identical(first@text, mark)
    expect_identical(to_qmd(ts), src, info = mark)
    expect_ts_ast_equal(parse_qmd(to_qmd(ts), ast = "ts", quiet = TRUE), ts)
  }
})

test_that("a rebuilt editorial div keeps its opener and blank-line boundaries", {
  ts = parse_qmd("::: ++ {.x}\n\nAdded.\n\nMore.\n\n:::\n", ast = "ts", quiet = TRUE)
  paras = as.list(select_nodes(ts, kind == "pandoc_paragraph"))
  new_para = parse_qmd("New.\n", ast = "ts", quiet = TRUE)@root@children@content[[1]]@children@content[[1]]

  out = to_qmd(insert_after(ts, kind == "pandoc_paragraph" & range@start_byte == paras[[1]]@range@start_byte, .what = new_para))
  expect_identical(out, "::: ++ {.x}\n\nAdded.\n\nNew.\n\nMore.\n\n:::\n")

  out = to_qmd(delete_nodes(ts, kind == "pandoc_paragraph" & range@start_byte == paras[[2]]@range@start_byte))
  pd = parse_qmd(out, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(pd@blocks[[1]]@attr@classes, c("quarto-insert", "x"))
  expect_identical(ast_text(pd), "Added.")
})
