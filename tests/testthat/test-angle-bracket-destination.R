# q2 832de666d (bd-angle-link-dest-qkqkegqo, v0.42.0) adds CommonMark's
# angle-bracket link destination, `[x](<a b.png>)`, which used to stop the
# parse with Q-2-33. tree-sitter-qmd lexes `<...>` as one `url` token marked
# by an `angle_bracket_url` field on `target`; pampa drops the brackets,
# resolves backslash escapes and percent-encodes the result, so the qmd writer
# emits the encoded bare form. Q-2-33 now suggests the brackets, and Q-2-60 is
# new for text between the closing `>` and the `)`.

ts_find = function(node, kind) {
  below = purrr::list_flatten(purrr::map(node@children@content, ts_find, kind = kind))
  if (identical(node@kind, kind)) c(list(node), below) else below
}

first_inline = function(pd) pd@blocks@content[[1]]@content@content[[1]]

expect_ts_bytes = function(src) {
  ts = parse_qmd(src, ast = "ts", quiet = TRUE)
  expect_length(ts@diagnostics, 0L)
  expect_length(ts_find(ts@root, "ERROR"), 0L)
  out = to_qmd(ts)
  expect_identical(out, src)
  expect_ts_ast_equal(parse_qmd(out, ast = "ts", quiet = TRUE), ts)
  ts
}

test_that("an angle-bracket image destination may hold spaces", {
  src = "![](<a path with spaces.png>)\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  img = first_inline(pd)
  expect_true(S7::S7_inherits(img, pandoc_image))
  expect_identical(img@url, "a%20path%20with%20spaces.png")
  expect_identical(to_qmd(pd), "![](a%20path%20with%20spaces.png)\n")
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)

  ts = expect_ts_bytes(src)
  url = ts_find(ts@root, "url")
  expect_length(url, 1L)
  expect_identical(url[[1]]@field_name, "angle_bracket_url")
  expect_identical(url[[1]]@text, "<a path with spaces.png>")
})

test_that("an angle-bracket link destination takes a title and attributes", {
  src = "[link](<foo bar.html> \"a title\"){.c}\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  link = first_inline(pd)
  expect_true(S7::S7_inherits(link, pandoc_link))
  expect_identical(link@url, "foo%20bar.html")
  expect_identical(link@title, "a title")
  expect_true(has_class(link, "c"))
  expect_identical(to_qmd(pd), "[link](foo%20bar.html \"a title\"){.c}\n")
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
  expect_ts_bytes(src)
})

test_that("empty and escaped angle-bracket destinations are decoded", {
  src = "[y](<>) [z](<a\\>b>)\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  inlines = pd@blocks@content[[1]]@content@content
  expect_identical(inlines[[1]]@url, "")
  expect_identical(inlines[[3]]@url, "a%3Eb")
  expect_identical(to_qmd(pd), "[y]() [z](a%3Eb)\n")
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
  expect_ts_bytes(src)
})

test_that("an unclosed angle bracket stays a bare destination", {
  src = "[x](<foo)\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_identical(first_inline(pd)@url, "<foo")
  expect_identical(to_qmd(pd), src)

  ts = expect_ts_bytes(src)
  url = ts_find(ts@root, "url")
  expect_length(url, 1L)
  expect_false(identical(url[[1]]@field_name, "angle_bracket_url"))
})

test_that("a bare destination with a space is still Q-2-33, now suggesting the brackets", {
  pd = parse_qmd("[x](a b.png)\n", quiet = TRUE)
  expect_true(has_error_diagnostics(pd))
  d = pd@diagnostics[[1]]
  expect_identical(d@code, "Q-2-33")
  expect_identical(d@kind, "error")
  expect_match(d@problem$text, "wrap the target in angle brackets", fixed = TRUE)
})

test_that("text after the closing angle bracket is Q-2-60", {
  for (src in c("![](<my file>.png)\n", "[text](<my file.html> title)\n")) {
    pd = parse_qmd(src, quiet = TRUE)
    expect_true(has_error_diagnostics(pd))
    d = pd@diagnostics[[1]]
    expect_identical(d@code, "Q-2-60")
    expect_identical(d@kind, "error")
    expect_identical(d@title, "Text after angle-bracket link destination")
    expect_match(d@hints, "Move the text inside the brackets", fixed = TRUE)
  }
})

test_that("an angle-bracket destination cannot span lines", {
  pd = parse_qmd("[x](<a\nb>)\n", quiet = TRUE)
  expect_true(has_error_diagnostics(pd))
  expect_identical(pd@diagnostics[[1]]@code, "Q-2-37")
})
