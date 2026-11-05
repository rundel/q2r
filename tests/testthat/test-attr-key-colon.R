# q2 f566e3596 (GH #1027, bd-aidsrl7n) makes `:` a word character in the
# scanner loop that lexes attribute keys, language specifiers and naked values,
# matching pandoc's attribute-key grammar. `{html:style="..."}` on a div, span
# or code block used to stop the whole document with a generic parse error; it
# now reads as an ordinary key = value attribute. The same loop means a naked
# value may hold a colon (`k=a:b`) and `{r:foo}` is a single language specifier
# rather than a Q-2-36 knitr-options error. A key still cannot start with `:`,
# and a div still does not take a bare language specifier.

ts_kinds = function(node) purrr::map_chr(node@children@content, \(x) x@kind)

ts_find = function(node, kind) {
  below = purrr::list_flatten(purrr::map(node@children@content, ts_find, kind = kind))
  if (identical(node@kind, kind)) c(list(node), below) else below
}

expect_attr_key_colon_roundtrip = function(src) {
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)

  ts = parse_qmd(src, ast = "ts", quiet = TRUE)
  out = to_qmd(ts)
  expect_identical(out, src)
  expect_ts_ast_equal(parse_qmd(out, ast = "ts", quiet = TRUE), ts)
}

test_that("a div attribute key may contain a colon", {
  src = "::: {html:style=\"color: red;\"}\nText.\n:::\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  div = pd@blocks@content[[1]]
  expect_true(S7::S7_inherits(div, pandoc_div))
  expect_identical(div@attr@attributes, c("html:style" = "color: red;"))
  expect_identical(get_attr(div, "html:style"), "color: red;")
  expect_identical(to_qmd(pd), "::: {html:style=\"color: red;\"}\n\nText.\n\n:::\n")

  ts = parse_qmd(src, ast = "ts", quiet = TRUE)
  expect_length(ts@diagnostics, 0L)
  expect_length(ts_find(ts@root, "ERROR"), 0L)
  spec = ts_find(ts@root, "key_value_specifier")
  expect_length(spec, 1L)
  expect_identical(ts_kinds(spec[[1]]), c("key_value_key", "=", "key_value_value"))
  expect_identical(spec[[1]]@children@content[[1]]@text, "html:style")
  expect_identical(spec[[1]]@children@content[[3]]@text, "\"color: red;\"")
})

test_that("colon keys sit alongside id, class and plain attributes", {
  src = "::: {#d .c html:style=\"a\" latex:style=\"b\" k=v}\nText.\n:::\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  attr = pd@blocks@content[[1]]@attr
  expect_identical(attr@id, "d")
  expect_identical(attr@classes, "c")
  expect_identical(attr@attributes, c("html:style" = "a", "latex:style" = "b", k = "v"))
  expect_identical(
    to_qmd(pd),
    "::: {#d .c html:style=\"a\" latex:style=\"b\" k=\"v\"}\n\nText.\n\n:::\n"
  )

  keys = ts_find(parse_qmd(src, ast = "ts", quiet = TRUE)@root, "key_value_key")
  expect_identical(
    trimws(purrr::map_chr(keys, \(x) x@text)),
    c("html:style", "latex:style", "k")
  )
})

test_that("spans and code blocks accept colon keys", {
  pd = parse_qmd("[x]{html:style=\"v\" k=v}\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  span = pd@blocks@content[[1]]@content@content[[1]]
  expect_true(S7::S7_inherits(span, pandoc_span))
  expect_identical(span@attr@attributes, c("html:style" = "v", k = "v"))
  expect_identical(to_qmd(pd), "[x]{html:style=\"v\" k=\"v\"}\n")

  pd = parse_qmd("```{.python html:style=\"x\"}\nprint(1)\n```\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  cb = pd@blocks@content[[1]]
  expect_true(S7::S7_inherits(cb, pandoc_code_block))
  expect_identical(cb@attr@classes, "python")
  expect_identical(cb@attr@attributes, c("html:style" = "x"))
  expect_identical(cb@text, "print(1)")
  expect_identical(to_qmd(pd), "```{.python html:style=\"x\"}\nprint(1)\n```\n")
})

test_that("a naked attribute value may contain a colon", {
  pd = parse_qmd("[x]{k=a:b}\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  span = pd@blocks@content[[1]]@content@content[[1]]
  expect_identical(span@attr@attributes, c(k = "a:b"))
  expect_identical(to_qmd(pd), "[x]{k=\"a:b\"}\n")

  value = ts_find(parse_qmd("[x]{k=a:b}\n", ast = "ts", quiet = TRUE)@root, "key_value_value")
  expect_length(value, 1L)
  expect_identical(value[[1]]@text, "a:b")
})

test_that("a language specifier with a colon is one token, not Q-2-36", {
  src = "```{r:foo}\n1\n```\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  cb = pd@blocks@content[[1]]
  expect_true(S7::S7_inherits(cb, pandoc_code_block))
  expect_identical(cb@attr@classes, "{r:foo}")
  expect_identical(to_qmd(pd), src)

  lang = ts_find(parse_qmd(src, ast = "ts", quiet = TRUE)@root, "language_specifier")
  expect_length(lang, 1L)
  expect_identical(lang[[1]]@text, "r:foo")

  pd = parse_qmd("```{r, echo=FALSE}\n1\n```\n", quiet = TRUE)
  expect_identical(purrr::map_chr(pd@diagnostics, \(d) d@code), "Q-2-36")
})

test_that("colon attributes round-trip on both ASTs", {
  srcs = c(
    "::: {html:style=\"color: red;\"}\nText.\n:::\n",
    "::: {#d .c html:style=\"a\" latex:style=\"b\" k=v}\nText.\n:::\n",
    "[x]{html:style=\"v\" k=v}\n",
    "```{.python html:style=\"x\"}\nprint(1)\n```\n",
    "[x]{k=a:b}\n",
    "```{r:foo}\n1\n```\n"
  )
  purrr::walk(srcs, expect_attr_key_colon_roundtrip)
})

test_that("shortcode arguments with colons keep their node kind", {
  cases = list(
    "{{< meta a:b >}}\n" = "a:b",
    "{{< kbd mac:x win:y >}}\n" = c("mac:x", "win:y"),
    "{{< video https://example.com/v.mp4 >}}\n" = "https://example.com/v.mp4"
  )
  purrr::iwalk(cases, \(args, src) {
    ts = parse_qmd(src, ast = "ts", quiet = TRUE)
    expect_length(ts@diagnostics, 0L)
    naked = ts_find(ts@root, "shortcode_naked_string")
    expect_identical(purrr::map_chr(naked, \(x) x@text), args)
    expect_attr_key_colon_roundtrip(src)
  })
})

test_that("a leading colon key and a bare specifier on a div are still errors", {
  pd = parse_qmd("[x]{:a=v}\n", quiet = TRUE)
  expect_true(has_error_diagnostics(pd))
  expect_identical(pd@diagnostics[[1]]@title, "Parse error")
  expect_identical(pd@diagnostics[[1]]@location$start_column, 5L)

  pd = parse_qmd("::: {a:b}\nText.\n:::\n", quiet = TRUE)
  expect_true(has_error_diagnostics(pd))
  expect_identical(pd@diagnostics[[1]]@title, "Parse error")

  err = ts_find(parse_qmd("::: {a:b}\nText.\n:::\n", ast = "ts", quiet = TRUE)@root, "ERROR")
  expect_true("a:b" %in% purrr::map_chr(err, \(x) x@text %||% ""))
})
