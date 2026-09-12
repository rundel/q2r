# tree-sitter-qmd exposes the YAML frontmatter body as a `yaml` child (field
# `body`) of `metadata` as of q2 c1d23393 (a2a0dcc1, bd-mjo6ao32, q2#671), and
# the pampa reader takes the YAML text and range from that child instead of
# splitting the node text on `---`. A `---` inside a value used to end the
# block there: a plain scalar silently dropped every later key and a quoted
# scalar failed with Q-0-99, which also broke the round trip of any em dash in
# a frontmatter string since the writer spells it `---`. The delimiter lines
# stay hidden tokens, so `metadata` keeps its verbatim `@text` on the ts side.

em = "—"

fm_srcs = list(
  quoted = "---\ndescription: \"a --- b\"\nauthor: Z\n---\n\nx\n",
  plain  = "---\ndescription: Hello --- world\nauthor: Z\n---\n\nx\n",
  block  = "---\ndescription: |\n  a\n\n  ---\n\n  b\nauthor: Z\n---\n\nx\n",
  spaced = "---\ntitle: T\nauthor: Z\n---   \n\nx\n",
  empty  = "---\n---\n\nx\n",
  div    = "::: hello\n\n---\nnested: \"a --- b\"\nother: Z\n---\n\n:::\n"
)

fm_bodies = list(
  quoted = "description: \"a --- b\"\nauthor: Z\n",
  spaced = "title: T\nauthor: Z\n",
  empty  = "",
  div    = "nested: \"a --- b\"\nother: Z\n"
)

meta_text = function(pd, key) ast_text(pd@meta@value[[key]]@value)

test_that("a `---` inside a frontmatter value keeps every later key on the pandoc path", {
  pd = parse_qmd(fm_srcs$quoted, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(names(pd@meta@value), c("description", "author"))
  expect_identical(meta_text(pd, "description"), paste0("a ", em, " b"))
  expect_identical(meta_text(pd, "author"), "Z")

  pd = parse_qmd(fm_srcs$plain, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(names(pd@meta@value), c("description", "author"))
  expect_identical(meta_text(pd, "description"), paste0("Hello ", em, " world"))

  pd = parse_qmd(fm_srcs$block, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(names(pd@meta@value), c("description", "author"))
  desc = pd@meta@value$description
  expect_identical(desc@kind, "blocks")
  expect_true(S7::S7_inherits(desc@value[[1]], pandoc_paragraph))
  expect_true(S7::S7_inherits(desc@value[[2]], pandoc_horizontal_rule))
  expect_true(S7::S7_inherits(desc@value[[3]], pandoc_paragraph))
  expect_identical(meta_text(pd, "author"), "Z")
})

test_that("a metadata block nested in a fenced div gets the same treatment", {
  pd = parse_qmd(fm_srcs$div, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(names(pd@meta@value), c("nested", "other"))
  expect_identical(meta_text(pd, "nested"), paste0("a ", em, " b"))
  expect_length(pd@blocks[[1]]@content@content, 0L)
})

test_that("frontmatter with a `---` in a value round-trips through the pampa qmd writer", {
  for (nm in c("quoted", "plain", "block", "spaced")) {
    pd = parse_qmd(fm_srcs[[nm]], quiet = TRUE)
    out = to_qmd(pd)
    pd2 = parse_qmd(out, quiet = TRUE)
    expect_no_error_diagnostics(pd2)
    expect_equal(pd2@meta, pd@meta, info = nm)
    expect_pd_ast_equal(pd2, pd)
  }
})

test_that("an em dash in a frontmatter string survives the writer's `---` spelling", {
  for (src in c(
    paste0("---\ndescription: \"Hello ", em, " world\"\nauthor: Z\n---\n\nx\n"),
    paste0("---\ndescription: |\n  Hello ", em, "\n  world.\nauthor: Z\n---\n\nx\n")
  )) {
    pd = parse_qmd(src, quiet = TRUE)
    out = to_qmd(pd)
    expect_match(out, "Hello ---", fixed = TRUE)
    pd2 = parse_qmd(out, quiet = TRUE)
    expect_no_error_diagnostics(pd2)
    expect_identical(names(pd2@meta@value), c("description", "author"))
    expect_equal(pd2@meta, pd@meta)
  }
})

test_that("the ts metadata node carries the YAML body as a `yaml` child and keeps its verbatim text", {
  for (nm in names(fm_bodies)) {
    ts = parse_qmd(fm_srcs[[nm]], ast = "ts", quiet = TRUE)
    md = select_first(ts, kind == "metadata")
    expect_false(is.null(md), info = nm)
    body = md@children@content[[1]]
    expect_identical(body@kind, "yaml", info = nm)
    expect_identical(body@field_name, "body", info = nm)
    expect_identical(body@text, fm_bodies[[nm]], info = nm)
    expect_length(body@children@content, 0L)
    expect_true(startsWith(md@text, "---\n"), info = nm)
    expect_true(grepl("\n---[ \t]*\n$", md@text), info = nm)

    out = to_qmd(ts)
    expect_identical(out, fm_srcs[[nm]])
    expect_ts_ast_equal(parse_qmd(out, ast = "ts", quiet = TRUE), ts)
  }
})

test_that("editing the yaml leaf rewrites the frontmatter between the delimiters", {
  ts = parse_qmd(fm_srcs$quoted, ast = "ts", quiet = TRUE)
  ts2 = map_nodes(ts, kind == "yaml", .f = function(n) { n@text = "title: New\n"; n })
  expect_identical(to_qmd(ts2), "---\ntitle: New\n---\n\nx\n")
  expect_ts_ast_equal(parse_qmd(to_qmd(ts2), ast = "ts", quiet = TRUE), ts2)

  md = select_first(ts, kind == "metadata")
  md2 = map_nodes(md, kind == "yaml", .f = function(n) { n@text = "title: New\n"; n })
  expect_identical(to_qmd(md2), "---\ntitle: New\n---\n")

  ts3 = delete_nodes(ts, kind == "yaml")
  expect_identical(to_qmd(ts3), "---\n---\n\nx\n")

  md@text = NULL
  expect_identical(to_qmd(md), "---\ndescription: \"a --- b\"\nauthor: Z\n---\n")
})

test_that("ts_query() can capture the frontmatter body", {
  q = ts_query(fm_srcs$quoted, "(metadata body: (yaml) @body)")
  expect_length(q, 1L)
  expect_identical(q[[1]]$body@kind, "yaml")
  expect_identical(q[[1]]$body@text, fm_bodies$quoted)
})

test_that("a `---` that opens no metadata block is still a thematic break", {
  ts = parse_qmd("---\n\nx\n", ast = "ts", quiet = TRUE)
  expect_length(select_nodes(ts, kind == "metadata"), 0L)
  expect_length(select_nodes(ts, kind == "pandoc_horizontal_rule"), 1L)
  expect_identical(to_qmd(ts), "---\n\nx\n")

  pd = parse_qmd("a\n\n---\n\nx\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_length(pd@meta@value, 0L)
  expect_true(S7::S7_inherits(pd@blocks[[2]], pandoc_horizontal_rule))
})
