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

test_that("splice_nodes accepts a wrapper (pandoc_inlines) return", {
  doc = parse_qmd("**bold**\n")
  out = splice_nodes(doc, is(pandoc_strong), .f = function(s) s@content)
  expect_length(select_nodes(out, is(pandoc_strong)), 0L)
  expect_length(select_nodes(out, is(pandoc_str)), 1L)
})

test_that("ts map_nodes round-trip preserves the document on identity", {
  src = "# Hello\n\nworld\n"
  ts = parse_qmd(src, ast = "ts")
  out = map_nodes(ts, .f = ~ .x)
  expect_s7_class(out, ts_tree)
  expect_equal(to_qmd(out), to_qmd(ts))
})

test_that("mutation verbs accept a list of nodes from a prior selection", {
  doc = parse_qmd("# A\n\n# B\n\nbody\n")
  hs = select_nodes(doc, is(pandoc_header))
  expect_length(hs, 2L)

  mapped = map_nodes(hs, is(pandoc_header), .f = function(h) add_class(h, "x"))
  expect_length(mapped, 2L)
  expect_true(all(purrr::map_lgl(mapped, has_class, "x")))

  seen = 0L
  walked = walk_nodes(hs, is(pandoc_header), .f = function(h) seen <<- seen + 1L)
  expect_identical(seen, 2L)
  expect_identical(walked, hs)

  expect_length(delete_nodes(hs, is(pandoc_header)), 0L)
})

test_that("insert/splice on a node list return a flattened, longer list", {
  doc = parse_qmd("# A\n\n# B\n")
  hs = select_nodes(doc, is(pandoc_header))
  out = insert_before(hs, is(pandoc_header), .what = pandoc_horizontal_rule())
  expect_length(out, 4L)
  expect_s7_class(out[[1L]], pandoc_horizontal_rule)
  expect_s7_class(out[[2L]], pandoc_header)
})

test_that("mutation verbs work on a list of ts nodes too", {
  ts = parse_qmd("# A\n\n# B\n", ast = "ts")
  hs = select_nodes(ts, kind == "atx_heading")
  expect_length(hs, 2L)
  mapped = map_nodes(hs, .f = ~ .x)
  expect_length(mapped, 2L)
  expect_true(all(purrr::map_lgl(mapped, S7::S7_inherits, ts_node)))
})

test_that("chained ts mutations preserve inter-block whitespace", {
  ts = parse_qmd("# A\n\nfirst para\n\nsecond para\n", ast = "ts")
  one = delete_nodes(ts, kind == "pandoc_space")
  out = to_qmd(delete_nodes(one, kind == "atx_heading"))
  expect_equal(out, "\nfirstpara\n\nsecondpara\n")
})

test_that("ts mutation verbs return a reparse-consistent tree", {
  ts = parse_qmd("# A\n\nbody text\n", ast = "ts")
  m = delete_nodes(ts, kind == "pandoc_space")
  expect_ts_ast_equal(parse_qmd(to_qmd(m), ast = "ts"), m)
})

test_that("ts insert_after separates inserted blocks from their anchors", {
  ts = parse_qmd("first para\n\nsecond para\n", ast = "ts")
  new_para = select_first(parse_qmd("NEW\n", ast = "ts"), kind == "pandoc_paragraph")
  out = to_qmd(insert_after(ts, kind == "pandoc_paragraph", .what = new_para))
  expect_equal(out, "first para\n\nNEW\n\nsecond para\n\nNEW\n")
  reparsed = parse_qmd(out, ast = "ts")
  expect_length(select_nodes(reparsed, kind == "pandoc_paragraph"), 4L)
})

test_that("ts insert_after keeps list items separate", {
  lst = parse_qmd("- a\n- b\n", ast = "ts")
  item = select_first(parse_qmd("- c\n", ast = "ts"), kind == "list_item")
  out = to_qmd(insert_after(lst, kind == "list_item", .what = item))
  expect_equal(out, "- a\n- c\n- b\n- c\n")
  expect_length(select_nodes(parse_qmd(out, ast = "ts"), kind == "list_item"), 4L)
})

test_that("ts splice_nodes separates duplicated blocks", {
  ts = parse_qmd("aaa\n\nbbb\n", ast = "ts")
  out = to_qmd(splice_nodes(ts, kind == "pandoc_paragraph", .f = function(n) list(n, n)))
  expect_equal(out, "aaa\n\naaa\n\nbbb\n\nbbb\n")
  expect_length(select_nodes(parse_qmd(out, ast = "ts"), kind == "pandoc_paragraph"), 4L)
})

test_that("mutating inside a pipe table emits no handler warnings", {
  tbl = parse_qmd("| a b | c |\n|---|---|\n| d e | f |\n", ast = "ts")
  expect_no_warning(out <- to_qmd(delete_nodes(tbl, kind == "pandoc_space")))
  expect_equal(out, "| ab | c |\n|---|---|\n| de | f |\n")
})

test_that("mutation verbs reach figure/table captions and table head/foot", {
  tbl_doc = parse_qmd("| a | b |\n|---|---|\n| 1 | 2 |\n\n: My caption\n")
  hits = 0L
  map_nodes(tbl_doc, is(pandoc_caption), .f = function(n) { hits <<- hits + 1L; n })
  expect_identical(hits, 1L)

  cleared = map_nodes(tbl_doc, is(pandoc_caption), .f = function(n) NULL)
  expect_length(cleared@blocks@content[[1]]@caption@long@content, 0L)

  replaced = map_nodes(tbl_doc, is(pandoc_caption),
                       .f = function(n) pandoc_caption(long = as_blocks("New caption")))
  expect_match(to_qmd(replaced), "New caption", fixed = TRUE)

  head_hits = 0L
  map_nodes(tbl_doc, is(pandoc_table_head), .f = function(n) { head_hits <<- head_hits + 1L; n })
  expect_identical(head_hits, 1L)

  expect_error(
    map_nodes(tbl_doc, is(pandoc_table_head), .f = function(n) list(n, n)),
    "cannot be spliced"
  )
})

test_that("mutation verbs hint when the payload argument is passed positionally", {
  doc = parse_qmd("body\n")
  expect_error(map_nodes(doc, is(pandoc_str), function(n) n), "Pass it by name")
  expect_error(walk_nodes(doc, function(n) n), "Pass it by name")
  expect_error(splice_nodes(doc, is(pandoc_str)), "Pass it by name")
  expect_error(replace_nodes(doc, is(pandoc_str)), "Pass it by name")
  expect_error(insert_before(doc, is(pandoc_paragraph)), "Pass it by name")
  expect_error(insert_after(doc, is(pandoc_paragraph)), "Pass it by name")
})
