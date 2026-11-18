# q2 834eb8d17 (bd-shortcode-empty-string-arg-4m36n6ur, #1242, v0.47.0): an
# empty quoted shortcode argument (`x=""`, `''`) is an empty string, as in
# Quarto 1, instead of a fatal parse error. The grammar adds anonymous `""` /
# `''` alternatives under `shortcode_string`; the qmd writer writes both back
# as `""`.

first_shortcode = function(src) {
  pd = parse_qmd(src, quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  sc = pd@blocks[[1]]@content[[1]]
  expect_s7_class(sc, pandoc_shortcode)
  sc
}

test_that("an empty quoted keyword argument is an empty string", {
  for (src in c("{{< kbd x=\"\" >}}\n", "{{< kbd x='' >}}\n")) {
    sc = first_shortcode(src)
    expect_identical(sc@name, "kbd")
    expect_length(sc@positional_args, 0L)
    kw = sc@keyword_args[[1]]
    expect_identical(kw$key, "x")
    expect_identical(kw$value$kind, "string")
    expect_identical(kw$value$value, "")
  }
})

test_that("empty quoted positional arguments are empty strings", {
  sc = first_shortcode("{{< meta \"\" '' key >}}\n")
  vals = purrr::map_chr(sc@positional_args, function(a) a$value)
  expect_identical(vals, c("", "", "key"))
})

test_that("the qmd writer round-trips empty arguments, normalizing '' to \"\"", {
  src = "{{< kbd \"\" x=\"\" >}}\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_identical(to_qmd(pd), src)
  pd2 = parse_qmd("{{< meta \"\" '' key >}}\n", quiet = TRUE)
  expect_identical(to_qmd(pd2), "{{< meta \"\" \"\" key >}}\n")
  expect_pd_ast_equal(parse_qmd(to_qmd(pd2), quiet = TRUE), pd2)
})

test_that("the ts shortcode_string holds the anonymous empty-quote token", {
  for (src in c("{{< kbd x=\"\" >}}\n", "{{< meta \"\" '' key >}}\n")) {
    ts = parse_qmd(src, ast = "ts", quiet = TRUE)
    expect_length(ts@diagnostics, 0L)
    out = to_qmd(ts)
    expect_identical(out, src)
    expect_ts_ast_equal(parse_qmd(out, ast = "ts", quiet = TRUE), ts)
  }
  ts = parse_qmd("{{< kbd x=\"\" >}}\n", ast = "ts", quiet = TRUE)
  str_node = select_descendants(ts, kind == "shortcode_string")[[1]]
  expect_identical(purrr::map_chr(str_node@children@content, function(n) n@kind), "\"\"")
})

test_that("a non-empty quoted argument is unaffected", {
  sc = first_shortcode("{{< kbd x=\"a\" >}}\n")
  expect_identical(sc@keyword_args[[1]]$value$value, "a")
})
