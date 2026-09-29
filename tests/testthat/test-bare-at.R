# A bare `@` that cannot be a citation is literal text as of q2 10e16e0c
# (1ff710a6e, f9aff1a60, bbb2689f4, bd-bare-at-literal-w3ytmu8e). A standalone
# `@` (surrounded by whitespace, at a line start or end, or after a block
# prefix) and an `@` directly after a letter or digit (`user@example.com`,
# `mermaid@11`, `a@`) parse as str; they used to be parse errors or, for
# `Hi@cite`, a citation glued to a word. The pampa qmd writer escapes every
# `@` in a str (`a \@ b`). `f9aff1a60` also strips the leading space from ATX
# heading content, so `# @ b`, `# < b` and `# * b` no longer start with a
# Space inline. `Smith@{key}` now raises Q-2-41 instead of reading as a str
# plus a braced citation.

shape = function(inl) {
  purrr::map_chr(inl, function(x) {
    if (S7::S7_inherits(x, pandoc_str)) x@text
    else if (S7::S7_inherits(x, pandoc_space)) "<sp>"
    else if (S7::S7_inherits(x, pandoc_soft_break)) "<sb>"
    else if (S7::S7_inherits(x, pandoc_cite)) paste0("cite:", x@citations[[1]]@id, ":", x@citations[[1]]@mode)
    else sub("q2r::", "", class(x)[1])
  })
}

first_shape = function(pd) shape(pd@blocks[[1]]@content@content)

literal = list(
  "a @ b\n"                       = c("a", "<sp>", "@", "<sp>", "b"),
  "@\n"                           = "@",
  "a @\n"                         = c("a", "<sp>", "@"),
  "first @\nsecond\n"             = c("first", "<sp>", "@", "<sb>", "second"),
  "text\n@ more\n"                = c("text", "<sb>", "@", "<sp>", "more"),
  "Q&A @ 3pm\n"                   = c("Q&A", "<sp>", "@", "<sp>", "3pm"),
  "user@example.com\n"            = "user@example.com",
  "mermaid@11 and std@0.224.0\n"  = c("mermaid@11", "<sp>", "and", "<sp>", "std@0.224.0"),
  "a@ b\n"                        = c("a@", "<sp>", "b"),
  "a@. and b@, c\n"               = c("a@.", "<sp>", "and", "<sp>", "b@,", "<sp>", "c")
)

test_that("a bare or word-internal @ parses as str on the pandoc path", {
  for (src in names(literal)) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_no_error_diagnostics(pd)
    expect_identical(first_shape(pd), literal[[src]], info = src)
  }

  pd = parse_qmd("> @ b\n", quiet = TRUE)
  expect_identical(shape(pd@blocks[[1]]@content[[1]]@content@content), c("@", "<sp>", "b"))
})

test_that("a literal @ is escaped by the writer and round-trips", {
  expect_identical(to_qmd(parse_qmd("a @ b\n", quiet = TRUE)), "a \\@ b\n")
  expect_identical(to_qmd(parse_qmd("user@example.com\n", quiet = TRUE)), "user\\@example.com\n")
  expect_identical(to_qmd(parse_qmd("a@ b\n", quiet = TRUE)), "a\\@ b\n")
  for (src in names(literal)) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
  }
})

test_that("a literal @ byte-recovers on the tree-sitter path", {
  for (src in names(literal)) {
    ts = parse_qmd(src, ast = "ts", quiet = TRUE)
    expect_no_error_diagnostics(ts)
    expect_length(as.list(select_nodes(ts, kind == "ERROR")), 0L)
    expect_identical(to_qmd(ts), src, info = src)
    expect_ts_ast_equal(parse_qmd(to_qmd(ts), ast = "ts", quiet = TRUE), ts)
  }
})

test_that("a literal token at the start of an ATX heading leaves no leading space", {
  for (src in c("# @ b\n", "# < b\n", "# * b\n")) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_no_error_diagnostics(pd)
    expect_true(S7::S7_inherits(pd@blocks[[1]], pandoc_header))
    expect_identical(first_shape(pd), c(substr(src, 3L, 3L), "<sp>", "b"), info = src)
    expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
  }
  pd = parse_qmd("## @\n", quiet = TRUE)
  expect_identical(first_shape(pd), "@")
  expect_identical(pd@blocks[[1]]@level, 2L)
})

test_that("citations are unchanged", {
  cites = list(
    "see @ref for details\n" = c("see", "<sp>", "cite:ref:AuthorInText", "<sp>", "for", "<sp>", "details"),
    "@123\n"                 = "cite:123:AuthorInText",
    "a -@ref b\n"            = c("a", "<sp>", "cite:ref:SuppressAuthor", "<sp>", "b"),
    "see (@foo) here\n"      = c("see", "<sp>", "(", "cite:foo:AuthorInText", ")", "<sp>", "here"),
    "Hi(@cite)\n"            = c("Hi(", "cite:cite:AuthorInText", ")"),
    "\\@ b\n"                = c("@", "<sp>", "b")
  )
  for (src in names(cites)) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_no_error_diagnostics(pd)
    expect_identical(first_shape(pd), cites[[src]], info = src)
  }
  # A bare `-@ref` writes as `[-@ref]`, whose citation carries no content
  # inlines where the bare form keeps its source text, so that one is not
  # AST-identical after a round trip (pre-existing, unrelated to this change).
  for (src in setdiff(names(cites), "a -@ref b\n")) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
  }
})

test_that("an @ that looks like a citation typo is still a parse error", {
  pd = parse_qmd("see Smith@{key} here\n", quiet = TRUE)
  expect_true(has_error_diagnostics(pd))
  expect_identical(pd@diagnostics[[1]]@code, "Q-2-41")

  for (src in c("a @- b\n", "@-foo\n", "a @@ b\n", "(@ b\n")) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_true(has_error_diagnostics(pd), info = src)
  }
})
