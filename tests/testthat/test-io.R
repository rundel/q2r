test_that("read_qmd parses a file path into a pandoc by default", {
  tmp = withr::local_tempfile(fileext = ".qmd")
  writeLines("# Heading\n\nbody\n", tmp)
  doc = read_qmd(tmp)
  expect_s7_class(doc, pandoc)
  expect_length(select_nodes(doc, is(pandoc_header)), 1L)
})

test_that("read_qmd honours ast = 'ts'", {
  tmp = withr::local_tempfile(fileext = ".qmd")
  writeLines("# Heading\n\nbody\n", tmp)
  expect_s7_class(read_qmd(tmp, ast = "ts"), ts_tree)
})

test_that("read_qmd errors on a missing file rather than treating it as text", {
  expect_error(read_qmd("/no/such/file.qmd"), "file not found")
})

test_that("read_qmd reads from disk even when the filename contains a newline", {
  dir = withr::local_tempdir()
  path = file.path(dir, "wei\nrd.qmd")
  writeLines("# Inside heading\n\nbody\n", path)
  doc = read_qmd(path)
  h = select_first(doc, is(pandoc_header))
  expect_true(S7::S7_inherits(h, pandoc_header))
  expect_equal(ast_text(h), "Inside heading")
})

test_that("write_qmd writes exactly what to_qmd produces and returns input invisibly", {
  doc = parse_qmd("# H\n\nsome body text\n")
  out = withr::local_tempfile(fileext = ".qmd")
  res = withVisible(write_qmd(doc, out))
  expect_false(res$visible)
  expect_identical(res$value, doc)
  expect_identical(readChar(out, file.info(out)$size, useBytes = TRUE), to_qmd(doc))
})

test_that("edit_qmd applies a function in place", {
  tmp = withr::local_tempfile(fileext = ".qmd")
  writeLines("# Heading\n\nbody\n", tmp)
  edit_qmd(tmp, function(d) map_nodes(d, is(pandoc_header), .f = function(h) add_class(h, "done")))
  edited = read_qmd(tmp)
  h = select_first(edited, is(pandoc_header))
  expect_true(has_class(h, "done"))
})

test_that("edit_qmd accepts a formula", {
  tmp = withr::local_tempfile(fileext = ".qmd")
  writeLines("# Heading\n\nbody\n", tmp)
  expect_silent(edit_qmd(tmp, ~ .x))
})
