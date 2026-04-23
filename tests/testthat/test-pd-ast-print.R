capture_tree = function(x) {
  withr::with_options(
    list(cli.unicode = TRUE),
    paste(utils::capture.output(print(x)), collapse = "\n")
  )
}

test_that("pandoc_str prints as quoted text", {
  out = capture_tree(pandoc_str(text = "Hello"))
  expect_identical(out, "str \"Hello\"")
})

test_that("pandoc_space prints as just its name", {
  out = capture_tree(pandoc_space())
  expect_identical(out, "space")
})

test_that("pandoc_emph nests its content under a tree branch", {
  e = pandoc_emph(content = pandoc_inlines(list(pandoc_str(text = "x"))))
  out = capture_tree(e)
  expect_identical(out, "emph\n└─str \"x\"")
})

test_that("pandoc_header label includes level", {
  h = pandoc_header(
    level = 2L,
    content = pandoc_inlines(list(pandoc_str(text = "Hi")))
  )
  out = capture_tree(h)
  expect_match(out, "^header level=2")
  expect_match(out, "str \"Hi\"")
})

test_that("attr is rendered inline when non-empty", {
  h = pandoc_header(
    level = 1L,
    attr = pandoc_attr(id = "sec", classes = c("x", "y"), attributes = c(k = "v")),
    content = pandoc_inlines(list(pandoc_str(text = "T")))
  )
  out = capture_tree(h)
  expect_match(out, "#sec")
  expect_match(out, "\\.x")
  expect_match(out, "\\.y")
  expect_match(out, "k=v")
})

test_that("empty attr is not rendered", {
  h = pandoc_header(level = 1L, content = pandoc_inlines(list(pandoc_str(text = "T"))))
  out = capture_tree(h)
  expect_false(grepl("\\(", out))
})

test_that("pandoc_link includes url and title", {
  content = pandoc_inlines(list(pandoc_str(text = "click")))
  lk = pandoc_link(content = content, url = "http://example.com", title = "t")
  out = capture_tree(lk)
  expect_match(out, "url=\"http://example.com\"")
  expect_match(out, "title=\"t\"")
})

test_that("pandoc_code_block includes truncated text and format attr", {
  cb = pandoc_code_block(text = "x = 1", attr = pandoc_attr(classes = "r"))
  out = capture_tree(cb)
  expect_match(out, "^code_block \"x = 1\"")
  expect_match(out, "\\.r")
})

test_that("pandoc_ordered_list label includes start/style/delim", {
  p = pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "a"))))
  ol = pandoc_ordered_list(
    attr = pandoc_list_attributes(start = 2L, style = "UpperAlpha", delim = "TwoParens"),
    content = list(pandoc_blocks(list(p)))
  )
  out = capture_tree(ol)
  expect_match(out, "ordered_list start=2 style=UpperAlpha delim=TwoParens")
})

test_that("full document prints as hierarchical tree matching spec", {
  doc = pandoc(
    blocks = pandoc_blocks(list(
      pandoc_header(
        level = 1L,
        content = pandoc_inlines(list(
          pandoc_str(text = "Hello"), pandoc_space(), pandoc_str(text = "world")
        ))
      ),
      pandoc_paragraph(content = pandoc_inlines(list(
        pandoc_str(text = "A"), pandoc_space(),
        pandoc_emph(content = pandoc_inlines(list(pandoc_str(text = "b"))))
      )))
    ))
  )
  out = capture_tree(doc)
  expected = paste(
    "pandoc",
    "├─header level=1",
    "│ ├─str \"Hello\"",
    "│ ├─space",
    "│ └─str \"world\"",
    "└─paragraph",
    "  ├─str \"A\"",
    "  ├─space",
    "  └─emph",
    "    └─str \"b\"",
    sep = "\n"
  )
  expect_identical(out, expected)
})

test_that("pandoc_blocks and pandoc_inlines print without a collection label", {
  bs = pandoc_blocks(list(
    pandoc_paragraph(content = pandoc_inlines(list(pandoc_str(text = "a"))))
  ))
  out = capture_tree(bs)
  expect_match(out, "^paragraph")

  is = pandoc_inlines(list(pandoc_str(text = "a"), pandoc_space()))
  out2 = capture_tree(is)
  expect_identical(out2, "str \"a\"\nspace")
})

test_that("long text is truncated in labels", {
  long = paste(rep("x", 100), collapse = "")
  s = pandoc_str(text = long)
  out = capture_tree(s)
  expect_true(grepl("…\"$", out))
  expect_lt(nchar(out), 60L)
})

test_that("q2r.print_max_width controls label width", {
  long = paste(rep("x", 100), collapse = "")
  s = pandoc_str(text = long)
  withr::with_options(list(q2r.print_max_width = 10L), {
    out = capture_tree(s)
    expect_identical(out, paste0("str \"", strrep("x", 9L), "…\""))
  })
  withr::with_options(list(q2r.print_max_width = 20L), {
    out = capture_tree(s)
    expect_identical(out, paste0("str \"", strrep("x", 19L), "…\""))
  })
})

test_that("q2r.print_trunc_side selects the ellipsis position", {
  src = "abcdefghijklmnopqrstuvwxyz"
  s = pandoc_str(text = src)
  withr::with_options(list(q2r.print_max_width = 10L, q2r.print_trunc_side = "right"), {
    expect_identical(capture_tree(s), "str \"abcdefghi…\"")
  })
  withr::with_options(list(q2r.print_max_width = 10L, q2r.print_trunc_side = "left"), {
    expect_identical(capture_tree(s), "str \"…rstuvwxyz\"")
  })
  withr::with_options(list(q2r.print_max_width = 10L, q2r.print_trunc_side = "center"), {
    expect_identical(capture_tree(s), "str \"abcde…wxyz\"")
  })
})

test_that("q2r.print_trunc_side rejects unknown sides", {
  s = pandoc_str(text = "hello world")
  withr::with_options(list(q2r.print_trunc_side = "bogus"), {
    expect_error(capture_tree(s), "should be one of")
  })
})

test_that("meta characters in text are escaped the way print() shows them", {
  cb = pandoc_code_block(text = "x <- 1\nplot(x)")
  out = capture_tree(cb)
  expect_identical(out, "code_block \"x <- 1\\nplot(x)\"")
})

test_that("tree labels apply cli semantic styling under color", {
  withr::with_options(list(cli.num_colors = 256L, cli.unicode = TRUE), {
    h = pandoc_header(
      level = 2L,
      attr = pandoc_attr(id = "sec-intro"),
      content = pandoc_inlines(list(pandoc_str(text = "Hello")))
    )
    out_raw = paste(utils::capture.output(print(h)), collapse = "\n")

    expect_match(out_raw, cli::col_cyan("header"), fixed = TRUE)
    expect_match(out_raw, cli::col_silver("level="), fixed = TRUE)
    expect_match(out_raw, cli::col_yellow(" (#sec-intro)"), fixed = TRUE)
    expect_match(out_raw, cli::col_green("\"Hello\""), fixed = TRUE)
    expect_match(out_raw, cli::col_cyan("str"), fixed = TRUE)

    expect_identical(
      cli::ansi_strip(out_raw),
      "header level=2 (#sec-intro)\n└─str \"Hello\""
    )
  })
})
