make_collection_dir = function() {
  d = withr::local_tempdir(.local_envir = parent.frame())
  dir.create(file.path(d, "sub"))
  writeLines("# Doc A\n\nalpha\n\n## Sub A\n\nmore\n", file.path(d, "a.qmd"))
  writeLines("# Doc B\n\nbeta\n", file.path(d, "sub", "b.qmd"))
  writeLines("not a qmd\n", file.path(d, "ignore.md"))
  d
}

test_that("parse_qmd_dir builds a qmd_collection from matching files", {
  d = make_collection_dir()
  coll = parse_qmd_dir(d)
  expect_s7_class(coll, qmd_collection)
  expect_length(coll@docs, 2L)
  expect_setequal(names(coll@docs), c("a.qmd", "sub/b.qmd"))
  expect_true(all(purrr::map_lgl(coll@docs, S7::S7_inherits, pandoc)))
})

test_that("parse_qmd_dir errors on a missing directory", {
  expect_error(parse_qmd_dir("/no/such/dir"), "directory not found")
})

test_that("an empty directory yields an empty collection", {
  d = withr::local_tempdir()
  coll = parse_qmd_dir(d)
  expect_length(coll@docs, 0L)
  expect_equal(nrow(ast_summary(coll)), 0L)
})

test_that("print summarises the documents", {
  coll = parse_qmd_dir(make_collection_dir())
  expect_output(print(coll), "qmd_collection: 2 documents")
  expect_output(print(coll), "a\\.qmd")
})

test_that("selection verbs return a per-document named list", {
  coll = parse_qmd_dir(make_collection_dir())
  res = select_nodes(coll, is(pandoc_header))
  expect_named(res, c("a.qmd", "sub/b.qmd"))
  expect_equal(purrr::map_int(res, length), c("a.qmd" = 2L, "sub/b.qmd" = 1L))
  first = select_first(coll, is(pandoc_header))
  expect_named(first, c("a.qmd", "sub/b.qmd"))
  expect_true(S7::S7_inherits(first[["a.qmd"]], pandoc_header))
})

test_that("mutation verbs return a new collection", {
  coll = parse_qmd_dir(make_collection_dir())
  out = map_nodes(coll, is(pandoc_header), .f = function(h) add_class(h, "tagged"))
  expect_s7_class(out, qmd_collection)
  expect_named(out@docs, names(coll@docs))
  h = select_first(out, is(pandoc_header))[["a.qmd"]]
  expect_true(has_class(h, "tagged"))
  # original is untouched
  h0 = select_first(coll, is(pandoc_header))[["a.qmd"]]
  expect_false(has_class(h0, "tagged"))
})

test_that("select_descendants / select_children return per-document named lists", {
  coll = parse_qmd_dir(make_collection_dir())
  desc = select_descendants(coll, is(pandoc_str))
  expect_named(desc, c("a.qmd", "sub/b.qmd"))
  expect_true(all(purrr::map_int(desc, length) > 0L))
  kids = select_children(coll, is(pandoc_header))
  expect_named(kids, c("a.qmd", "sub/b.qmd"))
})

test_that("replace_nodes returns a new collection with matches replaced", {
  coll = parse_qmd_dir(make_collection_dir())
  out = replace_nodes(coll, is(pandoc_header),
                      .with = function(h) pandoc_header(level = 6L, content = h@content))
  expect_s7_class(out, qmd_collection)
  levels = purrr::map_int(select_nodes(out, is(pandoc_header))[["a.qmd"]],
                          function(h) h@level)
  expect_true(length(levels) > 0L && all(levels == 6L))
})

test_that("splice_nodes returns a new collection with inserted content", {
  coll = parse_qmd_dir(make_collection_dir())
  out = splice_nodes(coll, is(pandoc_header),
                     .f = function(h) list(h, pandoc_paragraph(content = as_inlines("added"))))
  expect_s7_class(out, qmd_collection)
  expect_gt(length(select_nodes(out, has_text("added"))[["a.qmd"]]), 0L)
})

test_that("insert_before / insert_after return new collections", {
  coll = parse_qmd_dir(make_collection_dir())
  hr = pandoc_horizontal_rule()
  before = insert_before(coll, is(pandoc_header), .what = hr)
  after  = insert_after(coll, is(pandoc_header), .what = hr)
  expect_s7_class(before, qmd_collection)
  expect_s7_class(after, qmd_collection)
  expect_gt(length(select_nodes(before, is(pandoc_horizontal_rule))[["a.qmd"]]), 0L)
})

test_that("delete_nodes drops matches across all documents", {
  coll = parse_qmd_dir(make_collection_dir())
  out = delete_nodes(coll, is(pandoc_header))
  expect_equal(purrr::map_int(select_nodes(out, is(pandoc_header)), length),
               c("a.qmd" = 0L, "sub/b.qmd" = 0L))
})

test_that("walk_nodes runs a side effect and returns the collection invisibly", {
  coll = parse_qmd_dir(make_collection_dir())
  n = 0L
  res = withVisible(walk_nodes(coll, is(pandoc_header), .f = function(h) n <<- n + 1L))
  expect_false(res$visible)
  expect_s7_class(res$value, qmd_collection)
  expect_equal(n, 3L)
})

test_that("ast_summary binds documents with a leading doc column", {
  coll = parse_qmd_dir(make_collection_dir())
  s = ast_summary(coll)
  expect_equal(names(s)[1], "doc")
  expect_setequal(unique(s$doc), c("a.qmd", "sub/b.qmd"))
  expect_equal(nrow(s), 6L)
  expect_true(S7::S7_inherits(s$node[[1]], pandoc_node))
})

test_that("write_qmd_dir round-trips a collection to a new directory", {
  coll = parse_qmd_dir(make_collection_dir())
  out = map_nodes(coll, is(pandoc_header), .f = function(h) add_class(h, "tagged"))
  dest = withr::local_tempdir()
  write_qmd_dir(out, dest)
  back = parse_qmd_dir(dest)
  expect_setequal(names(back@docs), c("a.qmd", "sub/b.qmd"))
  expect_true(has_class(select_first(back, is(pandoc_header))[["a.qmd"]], "tagged"))
})

test_that("write_qmd_dir writes back in place when dir is NULL", {
  coll = parse_qmd_dir(make_collection_dir())
  out = map_nodes(coll, is(pandoc_header), .f = function(h) add_class(h, "tagged"))
  write_qmd_dir(out)
  back = parse_qmd_dir(dirname(coll@paths[[1]]))
  expect_true(has_class(select_first(back, is(pandoc_header))[["a.qmd"]], "tagged"))
})

test_that("write_qmd_dir rejects a non-collection", {
  expect_error(write_qmd_dir(parse_qmd("# x\n")), "must be a qmd_collection")
})

test_that("write_qmd_dir falls back to basename(@paths) when @docs is unnamed", {
  coll = parse_qmd_dir(make_collection_dir())
  unnamed = q2r:::qmd_collection(docs = unname(coll@docs), paths = coll@paths)
  dest = withr::local_tempdir()
  write_qmd_dir(unnamed, dest)
  written = list.files(dest, recursive = TRUE)
  expect_true(all(basename(coll@paths) %in% basename(written)))
})

test_that("as_df dispatches on a collection, returning per-document tables", {
  d = withr::local_tempdir()
  writeLines("| a | b |\n|---|---|\n| 1 | 2 |\n", file.path(d, "t.qmd"))
  writeLines("no tables here\n", file.path(d, "n.qmd"))
  coll = parse_qmd_dir(d)
  res = as_df(coll)
  expect_named(res, c("n.qmd", "t.qmd"))
  expect_length(res[["n.qmd"]], 0L)
  expect_equal(names(res[["t.qmd"]][[1]]), c("a", "b"))
})
