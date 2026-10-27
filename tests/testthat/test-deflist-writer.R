# q2 175af57b5 (bd-byr1oonq, v0.36.0): the qmd writer now spells a
# DefinitionList as the `::: {.definition-list}` div the qmd reader desugars
# (one `*` item per term holding a `-` bullet list of its definitions)
# instead of Pandoc's `Term` / `:   Def.` syntax, which the reader never
# parsed back. An empty term is written as the `* []` placeholder, and a
# term with no definitions has no div spelling, so it re-reads as a plain
# `.definition-list` div. The reader already produced DefinitionList from
# the div form, so parsed documents round-tripped through the old writer
# only by accident of never containing one; no quarto-web fixture does.

doc_of = function(...) pandoc(blocks = pandoc_blocks(list(...)))
plain = function(x) pandoc_plain(content = as_inlines(x))
para = function(x) pandoc_paragraph(content = as_inlines(x))
def_of = function(x) {
  if (is.character(x)) pandoc_blocks(list(plain(x))) else as_blocks(x)
}
item = function(term, ...) {
  pandoc_definition_item(term = as_inlines(term), defs = purrr::map(list(...), def_of))
}
deflist = function(...) pandoc_definition_list(content = list(...))

test_that("a definition list is written as a definition-list div", {
  d = doc_of(deflist(item("Term one", "Def one."), item("Term two", "Def two.")))
  out = to_qmd(d)
  expect_identical(
    out,
    "::: {.definition-list}\n\n* Term one\n  - Def one.\n* Term two\n  - Def two.\n\n:::\n"
  )

  pd = parse_qmd(out, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_length(pd@blocks, 1L)
  expect_s3_class(pd@blocks[[1]], "q2r::pandoc_definition_list")
  expect_identical(
    purrr::map_chr(pd@blocks[[1]]@content, function(i) ast_text(i@term)),
    c("Term one", "Term two")
  )
  expect_identical(to_qmd(pd), out)
})

test_that("definition list shapes round-trip through the div spelling", {
  cases = list(
    several_definitions = deflist(item("T", "a", "b")),
    multi_block_definition = deflist(item("T", list(para("One."), para("Two.")))),
    formatted_term = pandoc_definition_list(content = list(pandoc_definition_item(
      term = pandoc_inlines(list(
        pandoc_strong(content = as_inlines("Bold")),
        pandoc_space(),
        pandoc_emph(content = as_inlines("term"))
      )),
      defs = list(def_of("d"))
    ))),
    code_block_definition = deflist(item("T", list(pandoc_code_block(text = "1 + 1")))),
    paragraph_then_code = deflist(item("T", list(para("Text."), pandoc_code_block(text = "1 + 1")))),
    nested_definition_list = deflist(item("Outer", list(deflist(item("Inner", "Inner def."))))),
    inside_block_quote = pandoc_block_quote(content = as_blocks(list(deflist(item("T", "d"))))),
    inside_bullet_item = pandoc_bullet_list(content = list(as_blocks(list(
      para("item"), deflist(item("T", "d"))
    ))))
  )
  for (nm in names(cases)) {
    d = doc_of(cases[[nm]])
    pd = parse_qmd(to_qmd(d), quiet = TRUE)
    expect_identical(length(pd@diagnostics), 0L, info = nm)
    expect_pd_ast_equal(pd, d)
  }
})

test_that("single-paragraph definitions settle into tight plain ones after one trip", {
  loose = doc_of(deflist(item("T", list(para("a")), list(para("b")))))
  tight = doc_of(deflist(item("T", "a", "b")))
  first = to_qmd(loose)
  pd = parse_qmd(first, quiet = TRUE)
  expect_pd_ast_equal(pd, tight)
  second = to_qmd(pd)
  expect_false(identical(first, second))
  expect_identical(to_qmd(parse_qmd(second, quiet = TRUE)), second)
})

test_that("an empty term is written as the [] placeholder and reads back empty", {
  d = doc_of(deflist(item(list(), "d")))
  out = to_qmd(d)
  expect_identical(out, "::: {.definition-list}\n\n* []\n  - d\n\n:::\n")
  pd = parse_qmd(out, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_s3_class(pd@blocks[[1]], "q2r::pandoc_definition_list")
  expect_length(pd@blocks[[1]]@content[[1]]@term, 0L)
  expect_pd_ast_equal(pd, d)
})

test_that("a term without definitions falls back to a plain definition-list div", {
  d = doc_of(pandoc_definition_list(content = list(
    pandoc_definition_item(term = as_inlines("T"), defs = list())
  )))
  out = to_qmd(d)
  expect_identical(out, "::: {.definition-list}\n\n* T\n\n:::\n")
  pd = parse_qmd(out, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  div = pd@blocks[[1]]
  expect_s3_class(div, "q2r::pandoc_div")
  expect_true(has_class(div, "definition-list"))
  expect_s3_class(div@content[[1]], "q2r::pandoc_bullet_list")
  expect_identical(to_qmd(pd), out)
})

test_that("a parsed definition-list div is written back in the same spelling", {
  src = "::: {.definition-list}\n\n* term one\n  - definition one\n* term two\n  - definition two\n\n:::\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_s3_class(pd@blocks[[1]], "q2r::pandoc_definition_list")
  expect_identical(to_qmd(pd), src)
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})
