# Unicode format characters (category Cf) parse raw in prose as of q2
# 890b3755 (caa29d6c, bd-wuiu1of7, q2#672): tree-sitter-qmd widened its
# combining-mark class from `\p{M}` plus ZWNJ / ZWJ to `\p{M}\p{Cf}`, so a raw
# zero width space, soft hyphen, bidi mark or control, word joiner, MathML
# invisible operator, or mid-text U+FEFF folds into the surrounding str instead
# of raising a parse error. The pampa qmd writer spells every Cf character
# except ZWNJ / ZWJ as a character reference, the preferred WHATWG name where
# one exists and `&#xXXXX;` otherwise, so `to_qmd()` output stays readable.
# Source spelling is not preserved: `&af;`, `&ApplyFunction;` and a raw U+2061
# all come back as `&ApplyFunction;`.

named = c(
  "\u00AD" = "&shy;",
  "\u200B" = "&ZeroWidthSpace;",
  "\u200E" = "&lrm;",
  "\u200F" = "&rlm;",
  "\u2060" = "&NoBreak;",
  "\u2061" = "&ApplyFunction;",
  "\u2062" = "&InvisibleTimes;",
  "\u2063" = "&InvisibleComma;"
)

numeric = c(
  "\u2064"     = "&#x2064;",
  "\uFEFF"     = "&#xFEFF;",
  "\u202A"     = "&#x202A;",
  "\u202C"     = "&#x202C;",
  "\u2066"     = "&#x2066;",
  "\u061C"     = "&#x61C;",
  "\U000E0001" = "&#xE0001;"
)

refs = c(named, numeric)

para_inlines = function(pd) pd@blocks[[1]]@content@content

test_that("raw format characters parse as str content on the pandoc path", {
  for (ch in names(refs)) {
    src = paste0("a", ch, "b\n")
    pd = parse_qmd(src, quiet = TRUE)
    expect_no_error_diagnostics(pd)
    inl = para_inlines(pd)
    expect_true(all(purrr::map_lgl(inl, S7::S7_inherits, pandoc_str)), info = refs[[ch]])
    expect_identical(ast_text(pd), paste0("a", ch, "b"), info = refs[[ch]])
  }

  pd = parse_qmd("a\u200Bb hy\u00ADphen\n", quiet = TRUE)
  inl = para_inlines(pd)
  expect_length(inl, 3L)
  expect_identical(inl[[1]]@text, "a\u200Bb")
  expect_identical(inl[[3]]@text, "hy\u00ADphen")
})

test_that("raw format characters parse as pandoc_str leaves on the ts path", {
  for (ch in c("\u200B", "\u00AD", "\u2060", "\uFEFF")) {
    src = paste0("a", ch, "b\n")
    ts = parse_qmd(src, ast = "ts", quiet = TRUE)
    expect_no_error_diagnostics(ts)
    expect_length(as.list(select_nodes(ts, kind == "ERROR")), 0L)
    strs = as.list(select_nodes(ts, kind == "pandoc_str"))
    expect_length(strs, 1L)
    expect_identical(strs[[1]]@text, paste0("a", ch, "b"))
    expect_identical(to_qmd(ts), src)
    expect_ts_ast_equal(parse_qmd(to_qmd(ts), ast = "ts", quiet = TRUE), ts)
  }
})

test_that("to_qmd() spells format characters as character references", {
  for (ch in names(refs)) {
    pd = parse_qmd(paste0("a", ch, "b\n"), quiet = TRUE)
    out = to_qmd(pd)
    expect_identical(out, paste0("a", refs[[ch]], "b\n"))
    pd2 = parse_qmd(out, quiet = TRUE)
    expect_no_error_diagnostics(pd2)
    expect_pd_ast_equal(pd2, pd)
  }
})

test_that("entity, numeric, and raw spellings collapse to the preferred name", {
  pd = parse_qmd("f&af;x g&ApplyFunction;y h\u2061z a&#x200B;b c&#8203;d\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  expect_identical(ast_text(pd), "f\u2061x g\u2061y h\u2061z a\u200Bb c\u200Bd")
  out = to_qmd(pd)
  expect_identical(
    out,
    "f&ApplyFunction;x g&ApplyFunction;y h&ApplyFunction;z a&ZeroWidthSpace;b c&ZeroWidthSpace;d\n"
  )
  expect_pd_ast_equal(parse_qmd(out, quiet = TRUE), pd)
})

test_that("a zero width space inside a heading superscript no longer cascades", {
  pd = parse_qmd("# Title^a\u200Bb^\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  h = pd@blocks[[1]]
  expect_true(S7::S7_inherits(h, pandoc_header))
  inl = h@content@content
  expect_true(S7::S7_inherits(inl[[length(inl)]], pandoc_superscript))
  sup = inl[[length(inl)]]@content@content
  expect_length(sup, 1L)
  expect_identical(sup[[1]]@text, "a\u200Bb")
  out = to_qmd(pd)
  expect_identical(out, "# Title^a&ZeroWidthSpace;b^\n")
  expect_pd_ast_equal(parse_qmd(out, quiet = TRUE), pd)

  src = "# Welcome^&ZeroWidthSpace;[R]{.tm}^ {.mt-1}\n"
  pd = parse_qmd(src, quiet = TRUE)
  expect_no_error_diagnostics(pd)
  out = to_qmd(pd)
  expect_identical(out, src)
  pd2 = parse_qmd(out, quiet = TRUE)
  expect_no_error_diagnostics(pd2)
  expect_pd_ast_equal(pd2, pd)
})

test_that("join controls, combining marks, and unicode spaces stay raw", {
  srcs = c(
    zwnj  = "ab\u200Ccd\n",
    zwj   = "ab\u200Dcd\n",
    emoji = "\U0001F468\u200D\U0001F469\u200D\U0001F467\n",
    mark  = "cafe\u0301 \u0915\u093E\n",
    nbsp  = "a\u00A0b\n",
    thin  = "a\u2009b\n"
  )
  for (nm in names(srcs)) {
    pd = parse_qmd(srcs[[nm]], quiet = TRUE)
    expect_no_error_diagnostics(pd)
    out = to_qmd(pd)
    expect_identical(out, srcs[[nm]], info = nm)
    expect_false(grepl("&", out, fixed = TRUE), info = nm)
    expect_pd_ast_equal(parse_qmd(out, quiet = TRUE), pd)
  }
})
