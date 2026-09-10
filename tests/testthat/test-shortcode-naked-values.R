# Naked (unquoted) shortcode values decode backslash escapes and accept
# non-ASCII, `*`, `^`, `|` since q2 eda49bc4 (cf9c45cc,
# bd-shortcode-escaped-gt-fatal-2u79bqp1 / bd-shortcode-naked-value-nonascii-
# 47fzbmow): the `shortcode_naked_string` token became a blocklist and the
# writer's naked-char set widened to match, re-emitting a value it cannot
# write naked (a decoded `>`) as a quoted string.

naked_srcs = c(
  escaped_gt = "{{< kbd \\> >}}\n",
  arrow      = "{{< kbd → >}}\n",
  apostrophe = "{{< kbd don't >}}\n",
  star       = "{{< kbd a*b >}}\n",
  kv_escaped = "{{< kbd mac=\\> win=→ >}}\n"
)

shortcode_of = function(pd) select_nodes(pd, is(pandoc_shortcode))[[1]]

test_that("escaped and non-ASCII naked values parse and decode", {
  sc = shortcode_of(parse_qmd(naked_srcs[["escaped_gt"]], quiet = TRUE))
  expect_identical(sc@name, "kbd")
  expect_identical(sc@positional_args[[1]]$value, ">")
  sc = shortcode_of(parse_qmd(naked_srcs[["apostrophe"]], quiet = TRUE))
  expect_identical(sc@positional_args[[1]]$value, "don't")
  sc = shortcode_of(parse_qmd(naked_srcs[["kv_escaped"]], quiet = TRUE))
  expect_identical(purrr::map_chr(sc@keyword_args, function(a) a$key), c("mac", "win"))
  expect_identical(
    purrr::map_chr(sc@keyword_args, function(a) a$value$value),
    c(">", "→")
  )
})

test_that("naked values round-trip, re-quoting a decoded >", {
  for (nm in names(naked_srcs)) {
    pd = parse_qmd(naked_srcs[[nm]], quiet = TRUE)
    expect_length(pd@diagnostics, 0L)
    expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
  }
  expect_identical(
    to_qmd(parse_qmd(naked_srcs[["escaped_gt"]], quiet = TRUE)),
    "{{< kbd \">\" >}}\n"
  )
  expect_identical(
    to_qmd(parse_qmd(naked_srcs[["arrow"]], quiet = TRUE)),
    naked_srcs[["arrow"]]
  )
})
