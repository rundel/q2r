test_that("as_df flattens a pipe table to a data frame", {
  doc = parse_qmd("| Name | Age |\n|:-----|----:|\n| Alice | 30 |\n| Bob | 25 |\n")
  dfs = as_df(doc)
  expect_length(dfs, 1L)
  df = dfs[[1]]
  expect_s3_class(df, "data.frame")
  expect_equal(names(df), c("Name", "Age"))
  expect_equal(nrow(df), 2L)
  expect_equal(df[["Name"]], c("Alice", "Bob"))
  expect_equal(df[["Age"]], c("30", "25"))
})

test_that("as_df carries alignment, caption, and id as attributes", {
  doc = parse_qmd("| a | b |\n|:--|--:|\n| 1 | 2 |\n\n: Cap {#tbl-x}\n")
  df = as_df(doc)[[1]]
  expect_equal(unname(attr(df, "q2r_align")), c("left", "right"))
  expect_equal(attr(df, "q2r_caption"), "Cap")
  expect_equal(attr(df, "q2r_id"), "tbl-x")
})

test_that("as_df dispatches on a single pandoc_table too", {
  doc = parse_qmd("| a |\n|---|\n| 1 |\n")
  tbl = select_first(doc, is(pandoc_table))
  df = as_df(tbl)
  expect_s3_class(df, "data.frame")
  expect_equal(names(df), "a")
})

test_that("a document without tables yields an empty list", {
  expect_equal(as_df(parse_qmd("just text\n")), list())
})

test_that("as_table builds a renderable pandoc_table from a data frame", {
  tbl = as_table(data.frame(x = 1:2, y = c("a", "b")), caption = "demo")
  expect_s7_class(tbl, pandoc_table)
  qmd = to_qmd(pandoc(blocks = pandoc_blocks(list(tbl))))
  expect_true(grepl("demo", qmd))
  back = as_df(parse_qmd(qmd))[[1]]
  expect_equal(names(back), c("x", "y"))
  expect_equal(back[["x"]], c("1", "2"))
  expect_equal(back[["y"]], c("a", "b"))
})

test_that("as_table maps alignment to the pandoc colspec", {
  tbl = as_table(data.frame(a = 1, b = 2), align = c("right", "center"))
  expect_equal(tbl@colspec[[1]]@alignment, "Right")
  expect_equal(tbl@colspec[[2]]@alignment, "Center")
})

test_that("as_df then as_table round-trips alignment and caption", {
  doc = parse_qmd("| Name | Age |\n|:-----|----:|\n| Alice | 30 |\n\n: People {#tbl-p}\n")
  df = as_df(doc)[[1]]
  df2 = as_df(parse_qmd(
    to_qmd(pandoc(blocks = pandoc_blocks(list(as_table(df)))))
  ))[[1]]
  expect_equal(names(df2), names(df))
  expect_equal(unname(attr(df2, "q2r_align")), c("left", "right"))
  expect_equal(attr(df2, "q2r_caption"), "People")
  expect_equal(attr(df2, "q2r_id"), "tbl-p")
})

test_that("as_table handles a zero-row data frame", {
  tbl = as_table(data.frame(x = character(), y = character()))
  expect_s7_class(tbl, pandoc_table)
  expect_length(tbl@bodies[[1]]@body_rows, 0L)
})

test_that("as_df flattens a multi-row body", {
  df = as_df(parse_qmd("| a |\n|---|\n| 1 |\n| 2 |\n| 3 |\n"))[[1]]
  expect_equal(nrow(df), 3L)
  expect_equal(df[["a"]], c("1", "2", "3"))
})

test_that("as_df falls back to V1/V2 names when the header row is missing", {
  tbl = pandoc_table(
    head = pandoc_table_head(rows = list()),
    bodies = list(pandoc_table_body(body_rows = list(
      pandoc_row(cells = list(
        q2r:::table_cell_from_text("p"),
        q2r:::table_cell_from_text("q")
      ))
    ))),
    colspec = list()
  )
  df = as_df(tbl)
  expect_equal(names(df), c("V1", "V2"))
  expect_equal(df[["V1"]], "p")
})

test_that("as_df on a column- and cell-less table is an empty data frame", {
  df = as_df(pandoc_table())
  expect_s3_class(df, "data.frame")
  expect_equal(dim(df), c(0L, 0L))
})

test_that("as_table recycles a single alignment across all columns", {
  tbl = as_table(data.frame(a = 1, b = 2, c = 3), align = "right")
  expect_equal(purrr::map_chr(tbl@colspec, function(cs) cs@alignment),
               rep("Right", 3L))
})

test_that("as_table renders NA scalars as '' and joins multi-length cells", {
  df = data.frame(x = c(NA, "ok"), stringsAsFactors = FALSE)
  df$lst = list(c(1, 2), 3)
  tbl = as_table(df)
  cell = function(row, col) ast_text(tbl@bodies[[1]]@body_rows[[row]]@cells[[col]])
  expect_equal(cell(1L, 1L), "")       # NA scalar -> ""
  expect_equal(cell(2L, 1L), "ok")
  expect_equal(cell(1L, 2L), "1, 2")   # length-2 list element -> joined
  expect_equal(cell(2L, 2L), "3")      # length-1 list element -> "3"
})

test_that("as_table rejects a zero-column data frame and invalid alignment", {
  expect_error(as_table(data.frame()), "at least one column")
  expect_error(as_table(data.frame(a = 1), align = "middle"), "align")
  expect_error(as_table(data.frame(a = 1), align = NA_character_), "align")
})

test_that("as_df falls back to V-names for empty header cells", {
  df = as_df(parse_qmd("|  | b |\n|---|---|\n| 1 | 2 |\n| 3 | 4 |\n"))[[1]]
  expect_identical(names(df), c("V1", "b"))
  expect_identical(df$V1, c("1", "3"))
})

test_that("as_table formats numerics without scientific notation", {
  t = as_table(data.frame(x = c(1e6, 1e-5)))
  df = as_df(t)
  expect_identical(df$x, c("1000000", "0.00001"))
})
