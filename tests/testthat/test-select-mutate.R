test_that("map_nodes identity round-trips a pandoc document", {
  src = "# Hello\n\nworld\n"
  doc = parse_qmd(src)
  out = map_nodes(doc, is(pandoc_str), .f = ~ .x)
  expect_s7_class(out, pandoc)
  expect_equal(length(out@blocks@content), length(doc@blocks@content))
})

test_that("map_nodes can promote H2 to H1", {
  doc = parse_qmd("## H2\n")
  out = map_nodes(
    doc,
    is(pandoc_header) & level == 2L,
    .f = function(h) pandoc_header(level = 1L, attr = h@attr, content = h@content)
  )
  levels = purrr::map_int(select_nodes(out, is(pandoc_header)), function(h) h@level)
  expect_equal(levels, 1L)
})

test_that("map_nodes returning a list splices into the parent", {
  doc = parse_qmd("**bold**\n")
  out = map_nodes(doc, is(pandoc_strong), .f = ~ .x@content@content)
  strongs = select_nodes(out, is(pandoc_strong))
  expect_length(strongs, 0L)
})

test_that("delete_nodes removes matched headers", {
  doc = parse_qmd("# H1\n\nbody\n")
  out = delete_nodes(doc, is(pandoc_header))
  expect_length(select_nodes(out, is(pandoc_header)), 0L)
})

test_that("insert_before injects a sibling before each match", {
  doc = parse_qmd("# H1\n\nfoo\n")
  banner = pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "banner"))))
  out = insert_before(doc, is(pandoc_header) & level == 1L, .what = banner)
  blocks = out@blocks@content
  hi = purrr::detect_index(blocks, function(b) S7::S7_inherits(b, pandoc_header))
  expect_gt(hi, 1L)
  expect_s7_class(blocks[[hi - 1L]], pandoc_paragraph)
})

test_that("insert_after injects a sibling after each match", {
  doc = parse_qmd("# H1\n\nbody\n")
  banner = pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "banner"))))
  out = insert_after(doc, is(pandoc_header) & level == 1L, .what = banner)
  blocks = out@blocks@content
  hi = purrr::detect_index(blocks, function(b) S7::S7_inherits(b, pandoc_header))
  expect_gt(length(blocks), hi)
  expect_s7_class(blocks[[hi + 1L]], pandoc_paragraph)
})

test_that("replace_nodes with a constant works", {
  doc = parse_qmd("# old\n")
  replacement = pandoc_header(
    level = 1L,
    attr = pandoc_attr(),
    content = pandoc_inlines(list(pandoc_str(text = "new")))
  )
  out = replace_nodes(doc, is(pandoc_header), .with = replacement)
  hs = select_nodes(out, is(pandoc_header))
  expect_length(hs, 1L)
  expect_equal(hs[[1L]]@content@content[[1L]]@text, "new")
})

test_that("splice_nodes errors when .f returns a single node", {
  doc = parse_qmd("**bold**\n")
  expect_error(
    splice_nodes(doc, is(pandoc_strong),
                 .f = function(x) pandoc_str(text = "x")),
    "list of nodes"
  )
})

test_that("ts map_nodes round-trip preserves the document on identity", {
  src = "# Hello\n\nworld\n"
  ts = parse_qmd(src, ast = "ts")
  out = map_nodes(ts, .f = ~ .x)
  expect_s7_class(out, ts_tree)
  expect_equal(to_qmd(out), to_qmd(ts))
})
