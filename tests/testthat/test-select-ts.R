test_that("select_nodes on a ts_tree finds matches by kind", {
  ts = parse_qmd("# Hello\n\nbody **bold** more\n", ast = "ts")
  headings = select_nodes(ts, kind == "atx_heading")
  expect_length(headings, 1L)
  expect_s7_class(headings[[1L]], ts_node)
  expect_equal(headings[[1L]]@kind, "atx_heading")
})

test_that("select_descendants excludes the root node", {
  ts = parse_qmd("# Hello\n", ast = "ts")
  all = select_nodes(ts, kind == "document")
  desc = select_descendants(ts, kind == "document")
  expect_length(all, 1L)
  expect_length(desc, 0L)
})

test_that("select_children inspects only direct kids", {
  ts = parse_qmd("# H1\n\nfoo\n", ast = "ts")
  root = ts@root
  kids = select_children(root)
  expect_gt(length(kids), 0L)
  expect_true(all(purrr::map_lgl(kids, ~ S7::S7_inherits(.x, ts_node))))
})

test_that("select_first returns NULL on no match", {
  ts = parse_qmd("plain text\n", ast = "ts")
  none = select_first(ts, kind == "atx_heading")
  expect_null(none)
})

test_that("is_named slot accessor works", {
  ts = parse_qmd("# H\n", ast = "ts")
  named = select_nodes(ts, isTRUE(is_named))
  expect_gt(length(named), 0L)
  expect_true(all(purrr::map_lgl(named, ~ isTRUE(.x@is_named))))
})

test_that("starts_with helper on a slot value", {
  ts = parse_qmd("# Heading\n\nfoo\n", ast = "ts")
  matches = select_nodes(ts, !is.null(text) & starts_with("Heading", text))
  expect_gt(length(matches), 0L)
})

test_that("map_nodes returning the input is a no-op", {
  ts = parse_qmd("# H1\n\nbody\n", ast = "ts")
  out = map_nodes(ts, kind == "atx_heading", .f = ~ .x)
  expect_s7_class(out, ts_tree)
  expect_equal(to_qmd(out), to_qmd(ts))
})

test_that("delete_nodes drops matching nodes from the tree", {
  ts = parse_qmd("first\n\n# Heading\n\nlast\n", ast = "ts")
  out = delete_nodes(ts, kind == "atx_heading")
  qmd = to_qmd(out)
  expect_false(grepl("# Heading", qmd))
  expect_true(grepl("first", qmd))
  expect_true(grepl("last", qmd))
})

test_that("multiple predicates are combined with AND", {
  ts = parse_qmd("# H1\n\n## H2\n\nbody\n", ast = "ts")
  m = select_nodes(ts, kind == "atx_heading", isTRUE(is_named))
  expect_length(m, 2L)
})

test_that("mutating a ts node preserves inter-block blank lines", {
  # Deleting the spaces rebuilds the enclosing section; the blank lines between
  # the heading and the two paragraphs (gap whitespace the named children do not
  # cover) must survive the rebuild, not collapse away.
  ts = parse_qmd("# A\n\nfirst para\n\nsecond para\n", ast = "ts")
  out = to_qmd(delete_nodes(ts, kind == "pandoc_space"))
  expect_equal(out, "# A\n\nfirstpara\n\nsecondpara\n")
})

test_that("ts blank-line preservation is correct across multibyte source", {
  # Gap bytes are sliced from @text by byte offset; a multibyte char before the
  # gap would break a character-indexed slice but not a byte-indexed one.
  ts = parse_qmd("# ééé\n\nbody text\n\nmore\n", ast = "ts")
  out = to_qmd(delete_nodes(ts, kind == "pandoc_space"))
  expect_equal(out, "# ééé\n\nbodytext\n\nmore\n")
})

test_that("attr/text mask helpers silently no-match on the ts AST (pandoc only)", {
  # has_text / has_id / has_label / has_class / has_attr rely on ast_text() /
  # ast_attr(), which do not resolve on ts_node, so they are a silent no-match
  # rather than an error or a once-per-session warning.
  ts = parse_qmd("# Heading {#sec-a .cls}\n", ast = "ts")
  expect_silent(expect_length(select_nodes(ts, has_text("Heading")), 0L))
  expect_silent(expect_length(select_nodes(ts, has_id("sec-a")), 0L))
  expect_silent(expect_length(select_nodes(ts, has_label("sec-*")), 0L))
  expect_silent(expect_length(select_nodes(ts, has_class("cls")), 0L))
})

test_that("list-of-nodes dispatch supports chained selection", {
  ts = parse_qmd("# H1\n\n## H2\n\nbody\n", ast = "ts")
  step1 = select_nodes(ts, kind == "atx_heading")
  expect_length(step1, 2L)
  step2 = select_descendants(step1, kind == "atx_h1_marker" | kind == "atx_h2_marker")
  expect_gt(length(step2), 0L)
})

test_that("ts_nodes wrapper supports select_first and the mutators", {
  ts = parse_qmd("# A\n\n# B\n", ast = "ts")
  headings = q2r::ts_nodes(select_nodes(ts, kind == "atx_heading"))
  expect_s7_class(select_first(headings, kind == "atx_heading"), ts_node)
  out = delete_nodes(headings, kind == "atx_h1_marker")
  expect_s7_class(out, ts_nodes)
  expect_length(out@content, 2L)
})
